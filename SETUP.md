# Guide de configuration BooxStream

## Architecture complète

Système avec site web centralisé (booxstream.kevinvdb.dev) pour gérer les hôtes et les sessions.

## Installation

### 1. Site Web (booxstream.kevinvdb.dev)

```bash
cd web
npm install

# Créer le fichier .env
cat > .env << EOF
PORT=3001
JWT_SECRET=votre-secret-jwt-tres-securise-aleatoire
DB_PATH=./booxstream.db
DOMAIN=booxstream.kevinvdb.dev
EOF

npm start
```

### 2. Application Android

1. Ouvrir `android-app/` dans Android Studio
2. Synchroniser Gradle
3. Compiler et installer sur la tablette
4. L'app génère automatiquement un UUID au premier lancement
5. S'enregistre automatiquement sur le site web

### 3. Configuration DNS

Point `booxstream.kevinvdb.dev` vers votre serveur (IP publique).

### 4. Configuration SSL (HTTPS/WSS)

Pour utiliser WSS (WebSocket sécurisé), configurez un reverse proxy (nginx) avec SSL :

```nginx
server {
    listen 443 ssl;
    server_name booxstream.kevinvdb.dev;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Utilisation

### Côté Android (Hôte)

1. Ouvrir l'app BooxStream
2. Vérifier que l'UUID est affiché
3. Vérifier que l'URL de l'API est correcte (https://booxstream.kevinvdb.dev)
4. Cliquer "Démarrer le streaming"
5. Autoriser la capture d'écran
6. Le streaming démarre automatiquement

### Côté Web (Viewer)

1. Ouvrir https://booxstream.kevinvdb.dev
2. Voir la liste des hôtes disponibles
3. Cliquer "Voir le stream" sur un hôte
4. Le stream s'affiche en temps réel

## Flux d'authentification

1. **App Android** → POST `/api/hosts/register` → Reçoit token JWT
2. **App Android** → WebSocket port 8080 → Envoie `{"type": "auth", "token": "..."}`
3. **Viewer Web** → POST `/api/sessions/create` → Reçoit viewer_token
4. **Viewer Web** → WebSocket port 3001 → Envoie `{"type": "auth", "token": "viewer_token"}`
5. **Serveur** → Relaye les frames entre Android et viewers authentifiés

## Base de données

SQLite créée automatiquement dans `web/booxstream.db`.

Tables :
- `hosts` : Hôtes enregistrés
- `sessions` : Sessions de streaming actives
- `auth_tokens` : Tokens d'authentification

## Dépannage

### L'app ne s'enregistre pas
- Vérifier la connexion internet
- Vérifier l'URL de l'API dans les paramètres
- Vérifier les logs Android (logcat)

### Le streaming ne démarre pas
- Vérifier que le token JWT est valide
- Vérifier la connexion WebSocket (port 8080)
- Vérifier les logs du serveur web

### Les viewers ne voient rien
- Vérifier que l'hôte est actif
- Vérifier que la session est créée
- Vérifier la connexion WebSocket (port 3001)

