# 🔄 SCHÉMA DE FLUX COMPLET - BooxStream Server

## 📊 Architecture Réseau

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           INTERNET                                       │
│                              🌐                                          │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               │ HTTPS chiffré
                               │
                    ┌──────────▼──────────┐
                    │  CLOUDFLARE EDGE    │
                    │   (CDN + WAF)       │
                    └──────────┬──────────┘
                               │
                               │ Cloudflare Tunnel
                               │ (QUIC encrypted)
                               │
┌──────────────────────────────▼─────────────────────────────────────────┐
│                    🖥️  GATEWAY VM (192.168.1.200)                      │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │  📦 cloudflared (container)                                   │    │
│  │  Network: proxy                                               │    │
│  │  IP: 172.18.0.4                                               │    │
│  └─────────────────────────┬────────────────────────────────────┘    │
│                            │                                           │
│                            │ HTTP (internal)                           │
│                            │ booxstream.kevinvdb.dev                   │
│                            │                                           │
│  ┌─────────────────────────▼────────────────────────────────────┐    │
│  │  🚦 TRAEFIK (container)                                       │    │
│  │  Network: proxy                                               │    │
│  │  IP: 172.18.0.2                                               │    │
│  │  Ports: 80, 443, 8080                                         │    │
│  │                                                               │    │
│  │  Router: booxstream                                           │    │
│  │  ├─ Rule: Host(`booxstream.kevinvdb.dev`)                    │    │
│  │  ├─ Entrypoint: web (port 80)                                │    │
│  │  ├─ Middlewares: authentik-forward-auth                      │    │
│  │  └─ Service: booxstream-backend                              │    │
│  └─────────────────────────┬────────────────────────────────────┘    │
│                            │                                           │
│                            │ (1) Forward Auth Check                    │
│                            │ GET /outpost.goauthentik.io/auth/traefik  │
│                            │                                           │
│  ┌─────────────────────────▼────────────────────────────────────┐    │
│  │  🔐 AUTHENTIK SERVER (container)                              │    │
│  │  Network: proxy + authentik_default                          │    │
│  │  IP proxy: 172.18.0.3                                         │    │
│  │  Port: 9000                                                   │    │
│  │                                                               │    │
│  │  Vérifie:                                                     │    │
│  │  ✅ Session utilisateur valide ?                             │    │
│  │  ✅ Permissions OK ?                                          │    │
│  │                                                               │    │
│  │  Si NON authentifié:                                          │    │
│  │  ↳ HTTP 302 → https://auth.kevinvdb.dev/...                  │    │
│  │                                                               │    │
│  │  Si authentifié:                                              │    │
│  │  ↳ HTTP 200 + Headers (X-authentik-*)                        │    │
│  └─────────────────────────┬────────────────────────────────────┘    │
│                            │                                           │
│                            │ (2) Auth OK, forward request              │
│                            │                                           │
└────────────────────────────┼───────────────────────────────────────────┘
                             │
                             │ HTTP vers réseau local
                             │ http://192.168.1.202:3001
                             │
          ┌──────────────────▼──────────────────┐
          │  🖥️  BOOXSTREAM VM (192.168.1.202)  │
          ├─────────────────────────────────────┤
          │                                     │
          │  📦 BooxStream Web Server           │
          │  Port: 3001                         │
          │  Service: Screen streaming          │
          │                                     │
          │  Reçoit la requête avec headers:    │
          │  - X-authentik-username             │
          │  - X-authentik-email                │
          │  - X-authentik-groups               │
          │                                     │
          └─────────────────────────────────────┘
```

---

## 🔄 Flux Détaillé Étape par Étape

### Scénario 1 : Utilisateur NON authentifié

1. **Utilisateur** → `https://booxstream.kevinvdb.dev`
   ↓
2. **Cloudflare Edge** → Résout DNS + Tunnel
   ↓
3. **cloudflared (192.168.1.200)** → Reçoit requête chiffrée
   ↓
4. **cloudflared** → `http://traefik:80` (réseau proxy)
   ↓
5. **Traefik** → Analyse Host: `booxstream.kevinvdb.dev`
   ├─ Match router "booxstream"
   ├─ Applique middleware: `authentik-forward-auth`
   └─ Envoie: `GET http://authentik_server:9000/outpost.goauthentik.io/auth/traefik`
   ↓
6. **Authentik** → Vérifie session
   └─ Session inexistante
   ↓
7. **Authentik** → Répond: HTTP 302 Found
   └─ Location: `https://auth.kevinvdb.dev/if/flow/default-authentication-flow/?next=/`
   ↓
8. **Traefik** → Reçoit 302, forward au client
   ↓
9. **Navigateur** → Redirigé vers page de login Authentik
   ↓
10. **Utilisateur** → Se connecte sur `auth.kevinvdb.dev`
    ↓
11. **Authentik** → Crée session + cookie
    ↓
12. **Authentik** → Redirige vers `https://booxstream.kevinvdb.dev`
    ↓
13. **[Reprise du flux authentifié ci-dessous]**

---

### Scénario 2 : Utilisateur authentifié

1. **Utilisateur** → `https://booxstream.kevinvdb.dev`
   Header: `Cookie: authentik_session=...`
   ↓
2. **Cloudflare** → Cloudflare Tunnel
   ↓
3. **cloudflared (192.168.1.200)** → Traefik
   ↓
4. **Traefik** → Middleware `authentik-forward-auth`
   `GET http://authentik_server:9000/outpost.goauthentik.io/auth/traefik`
   Headers: Cookie, X-Forwarded-*
   ↓
5. **Authentik** → Vérifie session
   ✅ Session valide
   ✅ Permissions OK
   ↓
6. **Authentik** → Répond: HTTP 200 OK
   Headers ajoutés:
   - `X-authentik-username: kvdb`
   - `X-authentik-email: kvdb@example.com`
   - `X-authentik-groups: admins`
   - `X-authentik-uid: abc123`
   ↓
7. **Traefik** → Auth OK, forward vers backend
   `GET http://192.168.1.202:3001/`
   Headers: [tous les headers originaux + X-authentik-*]
   ↓
8. **BooxStream Server (192.168.1.202:3001)**
   Reçoit requête avec contexte utilisateur
   ↓
9. **BooxStream** → Génère réponse HTML/API
   ↓
10. **BooxStream** → Traefik → cloudflared → Cloudflare → Utilisateur
    ✅ Page affichée

---

## 📡 Topologie Réseau Détaillée

```
┌─────────────────────────────────────────────────────────────────┐
│  RÉSEAU LOCAL (192.168.1.0/24)                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────┐       │
│  │  Gateway VM - 192.168.1.200                         │       │
│  │  ┌───────────────────────────────────────────────┐  │       │
│  │  │  Réseau Docker: proxy (172.18.0.0/16)        │  │       │
│  │  │  ├─ traefik (172.18.0.2)                     │  │       │
│  │  │  ├─ authentik_server (172.18.0.3)            │  │       │
│  │  │  ├─ cloudflared (172.18.0.4)                 │  │       │
│  │  │  └─ homepage (172.18.0.5)                    │  │       │
│  │  └───────────────────────────────────────────────┘  │       │
│  │  ┌───────────────────────────────────────────────┐  │       │
│  │  │  Réseau Docker: authentik_default            │  │       │
│  │  │  ├─ authentik_server (172.21.0.5)            │  │       │
│  │  │  ├─ authentik_worker (172.21.0.4)            │  │       │
│  │  │  ├─ authentik_db (172.21.0.2)                │  │       │
│  │  │  └─ authentik_redis (172.21.0.3)             │  │       │
│  │  └───────────────────────────────────────────────┘  │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                  │
│  ┌─────────────────────────────────────────────────────┐       │
│  │  BooxStream VM - 192.168.1.202                      │       │
│  │  └─ BooxStream Web Server (port 3001)              │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Configuration Traefik pour BooxStream

**Fichier** : `/opt/traefik/config/booxstream.yml`

```yaml
http:
  routers:
    booxstream:
      rule: "Host(`booxstream.kevinvdb.dev`)"
      entrypoints:
        - web                          # Port 80
      middlewares:
        - authentik-forward-auth       # Protection SSO
      service: booxstream-backend

  services:
    booxstream-backend:
      loadBalancer:
        servers:
          - url: "http://192.168.1.202:3001"  # VM BooxStream
```

---

## 🎯 Points Clés

✅ **Gateway unique** : Tout passe par 192.168.1.200  
✅ **Zero Trust** : Authentik vérifie CHAQUE requête  
✅ **Isolation réseau** : BooxStream VM accessible uniquement via Traefik  
✅ **Headers contextuels** : BooxStream reçoit l'identité utilisateur  
✅ **Tunnel chiffré** : Cloudflare → Gateway (pas d'IP publique exposée)  

---

## 🚨 Important

**La VM BooxStream (192.168.1.202) n'est PAS directement accessible depuis Internet !**

Elle est uniquement accessible via :
- ✅ Traefik sur Gateway (192.168.1.200)
- ✅ Après authentification Authentik
- ✅ Via le tunnel Cloudflare chiffré

**Sécurité renforcée** : Aucun port ouvert sur BooxStream vers l'extérieur ! 🔒

---

## 📋 Checklist de Configuration

### Sur le Gateway (192.168.1.200)

- [ ] Fichier `/opt/traefik/config/booxstream.yml` créé
- [ ] Traefik redémarré pour charger la config
- [ ] Route dans `/opt/cloudflare/config.yml` : `booxstream.kevinvdb.dev → traefik:80`

### Dans Authentik

- [ ] Provider `booxstream-proxy` créé
  - External host: `https://booxstream.kevinvdb.dev`
  - Internal host: `http://192.168.1.202:3001`
- [ ] Application `BooxStream` créée
  - Provider: `booxstream-proxy`
  - Launch URL: `https://booxstream.kevinvdb.dev`
  - Métadonnées: Icon, Description, Publisher

### Sur la VM BooxStream (192.168.1.202)

- [ ] Service `booxstream-web` actif sur port 3001
- [ ] Service accessible depuis le gateway : `curl http://192.168.1.202:3001/api/hosts`

### Test Final

```bash
# Doit retourner 302 (redirection Authentik) comme Affine
curl -I https://booxstream.kevinvdb.dev/
```

---

## 🔄 Comparaison avec Affine

| Aspect | Affine | BooxStream |
|--------|--------|------------|
| **VM** | 192.168.1.201 | 192.168.1.202 |
| **Port** | 3010 | 3001 |
| **Router Traefik** | `affine` | `booxstream` |
| **Hostname** | `affine.kevinvdb.dev` | `booxstream.kevinvdb.dev` |
| **Middleware** | `authentik-forward-auth` | `authentik-forward-auth` |
| **Flux** | Identique | Identique |

**Architecture identique, seule l'IP et le port changent !**

