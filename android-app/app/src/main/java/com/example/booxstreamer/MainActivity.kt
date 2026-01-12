package com.example.booxstreamer

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.net.InetAddress

class MainActivity : AppCompatActivity() {
    
    private lateinit var startButton: Button
    private lateinit var stopButton: Button
    private lateinit var statusText: TextView
    private lateinit var deviceUuidText: TextView
    private lateinit var apiUrlInput: EditText
    
    private lateinit var deviceManager: DeviceManager
    private lateinit var apiClient: ApiClient
    
    private val PERMISSION_CODE = 1000
    private val NOTIFICATION_PERMISSION_CODE = 1001
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // Initialiser les composants
        deviceManager = DeviceManager(this)
        val apiUrl = deviceManager.getApiUrl()
        apiClient = ApiClient(apiUrl)
        
        // Récupérer les vues
        startButton = findViewById(R.id.startButton)
        stopButton = findViewById(R.id.stopButton)
        statusText = findViewById(R.id.statusText)
        deviceUuidText = findViewById(R.id.deviceUuidText)
        apiUrlInput = findViewById(R.id.apiUrlInput)
        
        // Afficher l'UUID de l'appareil
        val uuid = deviceManager.getDeviceUuid()
        deviceUuidText.text = "UUID: ${uuid.substring(0, 8)}..."
        
        // Configurer l'URL de l'API
        apiUrlInput.setText(apiUrl)
        
        // Enregistrer l'appareil au démarrage
        registerDevice()
        
        startButton.setOnClickListener {
            checkPermissionsAndStart()
        }
        
        stopButton.setOnClickListener {
            stopCapture()
        }
        
        updateUI(false)
    }
    
    private fun registerDevice() {
        val uuid = deviceManager.getDeviceUuid()
        val deviceName = "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}"
        
        // Récupérer l'IP publique (dans un thread séparé)
        Thread {
            try {
                val publicIp = getPublicIp()
                
                apiClient.registerHost(uuid, publicIp, deviceName) { result ->
                    runOnUiThread {
                        result.onSuccess { response ->
                            // Sauvegarder le token
                            deviceManager.saveAuthToken(response.token)
                            statusText.text = "Enregistré: ${response.host.name}"
                        }.onFailure { error ->
                            statusText.text = "Erreur enregistrement: ${error.message}"
                        }
                    }
                }
            } catch (e: Exception) {
                // Enregistrer sans IP publique
                apiClient.registerHost(uuid, null, deviceName) { result ->
                    runOnUiThread {
                        result.onSuccess { response ->
                            deviceManager.saveAuthToken(response.token)
                            statusText.text = "Enregistré: ${response.host.name}"
                        }.onFailure { _ ->
                            // Ignorer silencieusement l'erreur si pas d'IP publique
                            statusText.text = "Prêt (pas d'IP publique)"
                        }
                    }
                }
            }
        }.start()
    }
    
    /**
     * Récupère l'IP publique via api.ipify.org
     * Service légitime utilisé uniquement pour identifier l'appareil sur le réseau
     * Aucune donnée personnelle n'est envoyée
     */
    private fun getPublicIp(): String? {
        return try {
            // Service légitime api.ipify.org - utilisé uniquement pour obtenir l'IP publique
            // Aucune donnée personnelle n'est envoyée, uniquement une requête GET simple
            val url = java.net.URL("https://api.ipify.org")
            val connection = url.openConnection()
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            connection.getInputStream().bufferedReader().readText().trim()
        } catch (e: Exception) {
            // En cas d'erreur, retourner null (l'app fonctionne sans IP publique)
            null
        }
    }
    
    private fun checkPermissionsAndStart() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_CODE
                )
                return
            }
        }
        startScreenCapture()
    }
    
    private fun startScreenCapture() {
        val projectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(projectionManager.createScreenCaptureIntent(), PERMISSION_CODE)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == PERMISSION_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val token = deviceManager.getAuthToken()
                val apiUrl = apiUrlInput.text.toString()
                
                if (token == null) {
                    Toast.makeText(this, "Erreur: Token d'authentification manquant", Toast.LENGTH_SHORT).show()
                    registerDevice()
                    return
                }
                
                // Mettre à jour l'URL de l'API si modifiée
                if (apiUrl != deviceManager.getApiUrl()) {
                    deviceManager.setApiUrl(apiUrl)
                }
                
                val intent = Intent(this, ScreenCaptureService::class.java).apply {
                    putExtra("resultCode", resultCode)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        putExtra("data", data)
                    } else {
                        @Suppress("DEPRECATION")
                        putExtra("data", data)
                    }
                    putExtra("authToken", token)
                    putExtra("apiUrl", apiUrl)
                }
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
                
                updateUI(true)
                statusText.text = "Streaming actif"
            } else {
                Toast.makeText(this, "Permission refusée", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    private fun stopCapture() {
        stopService(Intent(this, ScreenCaptureService::class.java))
        updateUI(false)
        statusText.text = "Arrêté"
    }
    
    private fun updateUI(isRunning: Boolean) {
        startButton.isEnabled = !isRunning
        stopButton.isEnabled = isRunning
        apiUrlInput.isEnabled = !isRunning
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATION_PERMISSION_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startScreenCapture()
            } else {
                Toast.makeText(this, "Permission de notification requise", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
