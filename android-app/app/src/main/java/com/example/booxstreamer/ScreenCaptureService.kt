package com.example.booxstreamer

/**
 * Service de capture d'écran et streaming WebSocket
 * 
 * Implémentation basée sur la documentation officielle Android MediaProjection:
 * https://developer.android.com/media/grow/media-projection?hl=fr#kotlin
 * 
 * Fonctionnalités:
 * - Capture d'écran via MediaProjection API
 * - Streaming en temps réel via WebSocket
 * - Gestion automatique de l'arrêt (callback MediaProjection)
 * - Service en avant-plan avec notification
 */

import android.app.*
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import org.java_websocket.client.WebSocketClient
import org.java_websocket.handshake.ServerHandshake
import java.io.ByteArrayOutputStream
import java.net.URI
import java.nio.ByteBuffer

class ScreenCaptureService : Service() {
    
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var webSocketClient: WebSocketClient? = null
    private val handler = Handler(Looper.getMainLooper())
    
    private var screenWidth = 0
    private var screenHeight = 0
    private var screenDensity = 0
    
    companion object {
        private const val TAG = "ScreenCaptureService"
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "screen_capture_channel"
        private const val FPS = 10 // Images par seconde
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        getScreenMetrics()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification("Démarrage...")
        startForeground(NOTIFICATION_ID, notification)
        
        intent?.let {
            val resultCode = it.getIntExtra("resultCode", Activity.RESULT_CANCELED)
            val data = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                it.getParcelableExtra("data", Intent::class.java)
            } else {
                @Suppress("DEPRECATION")
                it.getParcelableExtra<Intent>("data")
            }
            val authToken = it.getStringExtra("authToken") ?: return START_NOT_STICKY
            val apiUrl = it.getStringExtra("apiUrl") ?: return START_NOT_STICKY
            
            startCapture(resultCode, data, authToken, apiUrl)
        }
        
        return START_NOT_STICKY
    }
    
    private fun getScreenMetrics() {
        val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val metrics = DisplayMetrics()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bounds = windowManager.currentWindowMetrics.bounds
            screenWidth = bounds.width()
            screenHeight = bounds.height()
            // Récupérer aussi les métriques pour la densité
            windowManager.defaultDisplay.getMetrics(metrics)
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getMetrics(metrics)
            screenWidth = metrics.widthPixels
            screenHeight = metrics.heightPixels
        }
        
        // Fix pour tablettes e-ink (ONYX Boox) : densité invalide
        screenDensity = when {
            metrics.densityDpi > 0 -> metrics.densityDpi
            metrics.densityDpi <= 0 -> {
                Log.w(TAG, "Densité invalide détectée: ${metrics.densityDpi}, utilisation du fallback")
                // Calculer densité basée sur xdpi/ydpi
                val xdpi = if (metrics.xdpi > 0) metrics.xdpi else 160f
                val ydpi = if (metrics.ydpi > 0) metrics.ydpi else 160f
                ((xdpi + ydpi) / 2).toInt().coerceAtLeast(160)
            }
            else -> 160 // Fallback par défaut (mdpi)
        }
        
        Log.d(TAG, "Métriques écran: ${screenWidth}x${screenHeight} @ ${screenDensity}dpi (original: ${metrics.densityDpi})")
        
        // Réduire la résolution pour le streaming (divisé par 2)
        screenWidth /= 2
        screenHeight /= 2
        
        Log.d(TAG, "Résolution streaming: ${screenWidth}x${screenHeight}")
    }
    
    private fun startCapture(resultCode: Int, data: Intent?, authToken: String, apiUrl: String) {
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = projectionManager.getMediaProjection(resultCode, data!!)
        
        // Enregistrer le callback pour gérer l'arrêt automatique (Android 15+)
        // Référence: https://developer.android.com/media/grow/media-projection?hl=fr#kotlin
        mediaProjection?.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                Log.d(TAG, "MediaProjection arrêté (écran verrouillé ou chip barre d'état)")
                // Libérer les ressources et arrêter le streaming
                cleanup()
                updateNotification("Streaming arrêté")
            }
        }, handler)
        
        imageReader = ImageReader.newInstance(
            screenWidth, screenHeight, PixelFormat.RGBA_8888, 2
        )
        
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            screenWidth, screenHeight, screenDensity,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface, null, null
        )
        
        // Construire l'URL WebSocket depuis l'API URL
        // Option 1 : Utiliser le chemin /android-ws sur le même port (compatible Cloudflare Tunnel)
        // Option 2 : Utiliser le port 8080 directement (si IP publique disponible)
        
        var wsUrl = apiUrl.trim()
        
        // Remplacer le protocole
        wsUrl = wsUrl.replace("https://", "wss://").replace("http://", "ws://")
        
        // Extraire le host et le port
        val uri = java.net.URI(wsUrl)
        val host = uri.host ?: ""
        val port = if (uri.port != -1) uri.port else {
            // Port par défaut selon le protocole
            if (wsUrl.startsWith("wss://")) 443 else 80
        }
        
        // Déterminer si on utilise un domaine ou une IP locale
        val isLocalIp = host.matches(Regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$"))
        
        // Si c'est une IP locale (ex: 192.168.x.x), utiliser le port 8080 directement
        // Sinon (domaine), utiliser le chemin /android-ws sur le même port (Cloudflare Tunnel)
        wsUrl = if (isLocalIp) {
            // IP locale : utiliser le port 8080 directement
            if (wsUrl.startsWith("wss://")) {
                "wss://$host:8080"
            } else {
                "ws://$host:8080"
            }
        } else {
            // Domaine : utiliser le chemin /android-ws (compatible Cloudflare Tunnel)
            val baseUrl = if (port != 443 && port != 80) {
                if (wsUrl.startsWith("wss://")) {
                    "wss://$host:$port"
                } else {
                    "ws://$host:$port"
                }
            } else {
                wsUrl // Garder wss:// ou ws:// sans port explicite
            }
            "$baseUrl/android-ws"
        }
        
        Log.d(TAG, "URL WebSocket construite: $wsUrl (depuis API: $apiUrl)")
        
        connectWebSocket(wsUrl, authToken)
        startFrameCapture()
        
        updateNotification("Streaming actif")
    }
    
    private fun cleanup() {
        handler.removeCallbacksAndMessages(null)
        webSocketClient?.close()
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        virtualDisplay = null
        imageReader = null
        webSocketClient = null
    }
    
    private fun connectWebSocket(serverUrl: String, authToken: String) {
        try {
            webSocketClient = object : WebSocketClient(URI(serverUrl)) {
                override fun onOpen(handshakedata: ServerHandshake?) {
                    Log.d(TAG, "WebSocket connecté, authentification...")
                    // Envoyer le token d'authentification
                    send(org.json.JSONObject().apply {
                        put("type", "auth")
                        put("token", authToken)
                    }.toString())
                }
                
                override fun onMessage(message: String?) {
                    try {
                        val json = org.json.JSONObject(message ?: return)
                        when (json.getString("type")) {
                            "authenticated" -> {
                                Log.d(TAG, "Authentifié avec succès")
                                updateNotification("Connecté et authentifié")
                            }
                            "error" -> {
                                Log.e(TAG, "Erreur authentification: ${json.getString("message")}")
                                updateNotification("Erreur d'authentification")
                                cleanup()
                            }
                        }
                    } catch (e: Exception) {
                        Log.d(TAG, "Message reçu: $message")
                    }
                }
                
                override fun onClose(code: Int, reason: String?, remote: Boolean) {
                    Log.d(TAG, "WebSocket fermé: $reason")
                    updateNotification("Déconnecté")
                }
                
                override fun onError(ex: Exception?) {
                    Log.e(TAG, "Erreur WebSocket: ${ex?.message}", ex)
                    Log.e(TAG, "URL WebSocket: $serverUrl", ex)
                    updateNotification("Erreur: ${ex?.message ?: "Connexion impossible"}")
                    // Nettoyer les ressources en cas d'erreur
                    handler.post {
                        cleanup()
                    }
                }
            }
            Log.d(TAG, "Tentative de connexion WebSocket à: $serverUrl")
            webSocketClient?.connect()
        } catch (e: Exception) {
            Log.e(TAG, "Erreur création WebSocket: ${e.message}", e)
            Log.e(TAG, "URL: $serverUrl", e)
            updateNotification("Erreur: ${e.message ?: "Impossible de créer la connexion"}")
            handler.post {
                cleanup()
            }
        }
    }
    
    private fun startFrameCapture() {
        val captureRunnable = object : Runnable {
            override fun run() {
                captureFrame()
                handler.postDelayed(this, (1000 / FPS).toLong())
            }
        }
        handler.post(captureRunnable)
    }
    
    private fun captureFrame() {
        try {
            val image = imageReader?.acquireLatestImage() ?: return
            
            val bitmap = imageToBitmap(image)
            image.close()
            
            if (bitmap != null && webSocketClient?.isOpen == true) {
                val jpegData = bitmapToJpeg(bitmap, 60) // 60% qualité
                val base64 = android.util.Base64.encodeToString(jpegData, android.util.Base64.NO_WRAP)
                
                // Envoyer en JSON avec le type frame et timestamp pour la synchronisation
                val message = org.json.JSONObject().apply {
                    put("type", "frame")
                    put("data", base64)
                    put("timestamp", System.currentTimeMillis()) // Timestamp pour calcul de latence
                }.toString()
                
                webSocketClient?.send(message)
                bitmap.recycle()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Erreur capture frame", e)
        }
    }
    
    private fun imageToBitmap(image: Image): Bitmap? {
        val planes = image.planes
        val buffer: ByteBuffer = planes[0].buffer
        val pixelStride = planes[0].pixelStride
        val rowStride = planes[0].rowStride
        val rowPadding = rowStride - pixelStride * screenWidth
        
        val bitmap = Bitmap.createBitmap(
            screenWidth + rowPadding / pixelStride,
            screenHeight,
            Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)
        
        return if (rowPadding == 0) {
            bitmap
        } else {
            Bitmap.createBitmap(bitmap, 0, 0, screenWidth, screenHeight)
        }
    }
    
    private fun bitmapToJpeg(bitmap: Bitmap, quality: Int): ByteArray {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream)
        return stream.toByteArray()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screen Capture",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(status: String): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BooxStream")
            .setContentText(status)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentIntent(pendingIntent)
            .build()
    }
    
    private fun updateNotification(status: String) {
        val notification = createNotification(status)
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        cleanup()
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
}

