# BooxStream ProGuard Rules
# Configuration pour la sécurité et l'optimisation

# Garder les attributs de ligne pour les stack traces lisibles
-keepattributes SourceFile,LineNumberTable

# Renommer les fichiers sources pour masquer la structure
-renamesourcefileattribute SourceFile

# Optimisation agressive pour réduire la taille et améliorer la sécurité
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Obfuscation agressive (activée automatiquement par R8 quand minifyEnabled=true)
# Renommer les classes pour masquer la structure
-repackageclasses 'a'

# Garder toutes les classes de l'application (nécessaires pour le fonctionnement)
-keep class com.example.booxstreamer.** { *; }

# Garder les classes spécifiques utilisées par Android
-keep class com.example.booxstreamer.MainActivity { *; }
-keep class com.example.booxstreamer.ScreenCaptureService { *; }
-keep class com.example.booxstreamer.DeviceManager { *; }
-keep class com.example.booxstreamer.ApiClient { *; }

# Garder les classes de données utilisées par Gson
-keep class com.example.booxstreamer.** {
    <fields>;
    <methods>;
}

# WebSocket (Java-WebSocket library)
-keep class org.java_websocket.** { *; }
-keepclassmembers class * extends org.java_websocket.client.WebSocketClient {
    public *;
    protected *;
}

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Garder les classes de données utilisées par Gson dans l'application
-keep class com.example.booxstreamer.HostRegistrationResponse { *; }
-keep class com.example.booxstreamer.HostInfo { *; }
-keepclassmembers class com.example.booxstreamer.** {
    <fields>;
}

# Android components
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Supprimer les logs en production (réduit la taille et masque les informations)
# DÉSACTIVÉ TEMPORAIREMENT pour le débogage - réactiver après vérification
# -assumenosideeffects class android.util.Log {
#     public static *** d(...);
#     public static *** v(...);
#     public static *** i(...);
#     public static *** w(...);
#     public static *** e(...);
# }

# Masquer les noms de classes dans les stack traces (déjà défini plus haut)

