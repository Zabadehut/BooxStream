package com.example.booxstreamer

import android.util.Log
import com.google.gson.Gson
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * Client API pour communiquer avec le serveur web BooxStream
 */
class ApiClient(private val apiUrl: String) {
    
    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()
    
    private val gson = Gson()
    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()
    
    companion object {
        private const val TAG = "ApiClient"
    }
    
    /**
     * Enregistre l'appareil comme hôte
     */
    fun registerHost(
        uuid: String,
        publicIp: String?,
        name: String?,
        callback: (Result<HostRegistrationResponse>) -> Unit
    ) {
        val requestBody = gson.toJson(mapOf(
            "uuid" to uuid,
            "public_ip" to publicIp,
            "name" to name
        )).toRequestBody(jsonMediaType)
        
        val request = Request.Builder()
            .url("$apiUrl/api/hosts/register")
            .post(requestBody)
            .build()
        
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e(TAG, "Erreur enregistrement hôte", e)
                callback(Result.failure(e))
            }
            
            override fun onResponse(call: Call, response: Response) {
                try {
                    val body = response.body?.string()
                    if (response.isSuccessful && body != null) {
                        val registration = gson.fromJson(body, HostRegistrationResponse::class.java)
                        callback(Result.success(registration))
                    } else {
                        callback(Result.failure(Exception("Erreur HTTP ${response.code}: $body")))
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Erreur parsing réponse", e)
                    callback(Result.failure(e))
                } finally {
                    response.close()
                }
            }
        })
    }
    
    /**
     * Met à jour l'IP publique de l'hôte
     */
    fun updatePublicIp(
        token: String,
        publicIp: String,
        callback: (Result<Boolean>) -> Unit
    ) {
        val requestBody = gson.toJson(mapOf(
            "public_ip" to publicIp
        )).toRequestBody(jsonMediaType)
        
        val request = Request.Builder()
            .url("$apiUrl/api/hosts/update-ip")
            .post(requestBody)
            .addHeader("Authorization", "Bearer $token")
            .build()
        
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e(TAG, "Erreur mise à jour IP", e)
                callback(Result.failure(e))
            }
            
            override fun onResponse(call: Call, response: Response) {
                try {
                    val success = response.isSuccessful
                    callback(Result.success(success))
                } catch (e: Exception) {
                    callback(Result.failure(e))
                } finally {
                    response.close()
                }
            }
        })
    }
}

data class HostRegistrationResponse(
    val success: Boolean,
    val token: String,
    val host: HostInfo
)

data class HostInfo(
    val uuid: String,
    val public_ip: String?,
    val name: String
)

