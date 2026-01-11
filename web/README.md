# BooxStream Web - Site web et API

Site web et API pour gérer les hôtes BooxStream et permettre la sélection/visualisation des streams.

## Fonctionnalités

- **Enregistrement des hôtes** : Les applications Android s'enregistrent avec leur UUID
- **Gestion des IP publiques** : Les hôtes mettent à jour leur IP publique
- **Création de sessions** : Les viewers créent des sessions pour voir un stream
- **Authentification JWT** : Sécurisation des connexions
- **Interface web** : Sélection et visualisation des streams

## Installation

```bash
cd web
npm install
cp .env.example .env
# Éditer .env avec vos paramètres
npm start
```

## Configuration

Éditez `.env` :
```
PORT=3001
JWT_SECRET=votre-secret-jwt-tres-securise
DB_PATH=./booxstream.db
DOMAIN=booxstream.kevinvdb.dev
```

## API Endpoints

### POST /api/hosts/register
Enregistre un nouvel hôte (depuis l'app Android)
```json
{
  "uuid": "device-uuid",
  "public_ip": "123.45.67.89",
  "name": "Mon appareil"
}
```

### POST /api/hosts/update-ip
Met à jour l'IP publique (authentification requise)
```json
{
  "public_ip": "123.45.67.89"
}
```

### GET /api/hosts
Liste tous les hôtes actifs

### POST /api/sessions/create
Crée une session de streaming
```json
{
  "host_uuid": "device-uuid"
}
```

### POST /api/sessions/verify
Vérifie un token de session
```json
{
  "token": "jwt-token"
}
```

## WebSocket

- **Port 8080** : Connexions Android (authentification par token JWT)
- **Port 3001** : Connexions viewers (authentification par token de session)

## Base de données

SQLite avec 3 tables :
- `hosts` : Hôtes enregistrés
- `sessions` : Sessions de streaming actives
- `auth_tokens` : Tokens d'authentification

