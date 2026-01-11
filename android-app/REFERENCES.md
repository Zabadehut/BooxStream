# Références et Documentation

## Documentation Android MediaProjection

**Source officielle** : [Android Developers - MediaProjection](https://developer.android.com/media/grow/media-projection?hl=fr#kotlin)

### Points clés implémentés

1. **MediaProjection.Callback** : Gestion de l'arrêt automatique
   - L'écran se verrouille
   - L'utilisateur appuie sur le chip de la barre d'état (Android 15+)
   - Une autre session de projection démarre
   - Le processus de l'application est arrêté

2. **Application redimensionnable** : `resizeableActivity="true"`
   - Compatible avec les modifications de configuration
   - Compatible avec le mode multifenêtre

3. **Foreground Service** : Service en avant-plan avec type `mediaProjection`
   - Notification persistante requise
   - Permet la capture d'écran en arrière-plan

### Implémentation dans BooxStream

- **ScreenCaptureService.kt** : Service de capture avec callback MediaProjection
- **MainActivity.kt** : Interface utilisateur pour démarrer/arrêter
- **AndroidManifest.xml** : Configuration des permissions et services

### Notes importantes

- Le callback `onStop()` libère automatiquement les ressources
- La résolution est réduite de moitié pour optimiser la bande passante
- Compression JPEG à 60% pour réduire la taille des données
- FPS configurable (10 par défaut)

