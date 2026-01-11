package com.example.booxstreamer

import android.content.Context
import android.content.SharedPreferences
import java.util.UUID

/**
 * Gestionnaire d'identité de l'appareil
 * Génère et stocke un UUID unique pour l'appareil
 */
class DeviceManager(private val context: Context) {
    
    private val prefs: SharedPreferences = context.getSharedPreferences(
        "booxstream_prefs", Context.MODE_PRIVATE
    )
    
    private val UUID_KEY = "device_uuid"
    
    /**
     * Récupère ou génère l'UUID de l'appareil
     */
    fun getDeviceUuid(): String {
        var uuid = prefs.getString(UUID_KEY, null)
        
        if (uuid == null) {
            uuid = UUID.randomUUID().toString()
            prefs.edit().putString(UUID_KEY, uuid).apply()
        }
        
        return uuid
    }
    
    /**
     * Récupère le token d'authentification stocké
     */
    fun getAuthToken(): String? {
        return prefs.getString("auth_token", null)
    }
    
    /**
     * Stocke le token d'authentification
     */
    fun saveAuthToken(token: String) {
        prefs.edit().putString("auth_token", token).apply()
    }
    
    /**
     * Récupère l'URL de l'API web
     */
    fun getApiUrl(): String {
        return prefs.getString("api_url", "https://booxstream.kevinvdb.dev") ?: "https://booxstream.kevinvdb.dev"
    }
    
    /**
     * Définit l'URL de l'API web
     */
    fun setApiUrl(url: String) {
        prefs.edit().putString("api_url", url).apply()
    }
}

