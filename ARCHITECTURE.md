# Architecture BooxStream - Système complet

## Vue d'ensemble

Système de streaming d'écran avec authentification et gestion centralisée via un site web.

## Composants

### 1. Site Web (booxstream.kevinvdb.dev)
- **Backend API** : Node.js/Express avec SQLite
- **Interface web** : HTML/CSS/JS pour gérer les hôtes
- **Authentification** : JWT pour sécuriser les connexions
- **WebSocket** : Relais entre Android et viewers

### 2. Application Android
- **UUID unique** : Identifiant unique par appareil
- **Enregistrement automatique** : S'enregistre sur le site web au démarrage
- **Authentification JWT** : Token pour se connecter au WebSocket
- **Capture d'écran** : MediaProjection API

### 3. Serveur de streaming
- **WebSocket Android** : Port 8080 (connexions authentifiées)
- **WebSocket Viewers** : Port 3001 (sessions authentifiées)
- **Relais** : Transmet les frames entre Android et viewers

## Flux de données

### Enregistrement d'un hôte
1. App Android démarre
2. Génère/récupère UUID unique
3. Récupère IP publique
4. POST `/api/hosts/register` avec UUID, IP, nom
5. Reçoit token JWT
6. Stocke le token localement

### Démarrage du streaming
1. Utilisateur clique "Démarrer"
2. Permission MediaProjection demandée
3. Service démarre avec token JWT
4. Connexion WebSocket au port 8080
5. Envoie message `{"type": "auth", "token": "..."}`
6. Serveur vérifie le token
7. Streaming commence

### Visualisation depuis le web
1. Utilisateur ouvre booxstream.kevinvdb.dev
2. Voit la liste des hôtes disponibles
3. Clique "Voir le stream"
4. POST `/api/sessions/create` avec host_uuid
5. Reçoit viewer_token
6. Connexion WebSocket au port 3001
7. Envoie message `{"type": "auth", "token": "viewer_token"}`
8. Reçoit les frames en temps réel

## Base de données

### Table `hosts`
- `id` : Identifiant unique
- `uuid` : UUID de l'appareil Android
- `public_ip` : IP publique de l'hôte
- `name` : Nom de l'appareil
- `created_at` : Date de création
- `last_seen` : Dernière activité
- `is_active` : Statut actif/inactif

### Table `sessions`
- `id` : Identifiant unique
- `host_uuid` : UUID de l'hôte
- `viewer_token` : Token JWT pour le viewer
- `created_at` : Date de création
- `expires_at` : Date d'expiration
- `is_active` : Session active

### Table `auth_tokens`
- `id` : Identifiant unique
- `device_uuid` : UUID de l'appareil
- `token_hash` : Hash du token
- `created_at` : Date de création
- `last_used` : Dernière utilisation

## Sécurité

- **JWT** : Tokens signés avec secret
- **Expiration** : Tokens viewers expirent après 24h
- **Authentification** : Toutes les connexions WebSocket sont authentifiées
- **Validation** : Vérification des tokens avant relais des frames

## URLs et ports

- **Site web** : https://booxstream.kevinvdb.dev (port 3001)
- **WebSocket Android** : wss://booxstream.kevinvdb.dev:8080
- **WebSocket Viewers** : wss://booxstream.kevinvdb.dev:3001

## Déploiement

### Site web
```bash
cd web
npm install
cp .env.example .env
# Configurer .env
npm start
```

### Application Android
- Compiler dans Android Studio
- Installer sur la tablette
- L'app s'enregistre automatiquement

