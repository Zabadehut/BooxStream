const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const sqlite3 = require('sqlite3').verbose();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const server = http.createServer(app);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Configuration
const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const DB_PATH = process.env.DB_PATH || './booxstream.db';

// Initialiser la base de données
const db = new sqlite3.Database(DB_PATH);

// Créer les tables
db.serialize(() => {
    // Table des hôtes (clients qui partagent leur écran)
    db.run(`CREATE TABLE IF NOT EXISTS hosts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        public_ip TEXT,
        name TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_seen DATETIME,
        is_active INTEGER DEFAULT 1
    )`);

    // Table des sessions de streaming
    db.run(`CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        host_uuid TEXT NOT NULL,
        viewer_token TEXT UNIQUE NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        expires_at DATETIME,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (host_uuid) REFERENCES hosts(uuid)
    )`);

    // Table des authentifications
    db.run(`CREATE TABLE IF NOT EXISTS auth_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_uuid TEXT UNIQUE NOT NULL,
        token_hash TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_used DATETIME
    )`);
});

// Middleware d'authentification
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Token manquant' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Token invalide' });
        }
        req.user = user;
        next();
    });
}

// Routes API

// Enregistrer un nouvel hôte (depuis l'app Android)
app.post('/api/hosts/register', (req, res) => {
    const { uuid, public_ip, name } = req.body;

    if (!uuid) {
        return res.status(400).json({ error: 'UUID requis' });
    }

    db.run(
        `INSERT OR REPLACE INTO hosts (uuid, public_ip, name, last_seen, is_active)
         VALUES (?, ?, ?, datetime('now'), 1)`,
        [uuid, public_ip || null, name || `Host ${uuid.substring(0, 8)}`],
        function(err) {
            if (err) {
                return res.status(500).json({ error: err.message });
            }

            // Générer un token JWT pour l'hôte
            const token = jwt.sign(
                { uuid, type: 'host' },
                JWT_SECRET,
                { expiresIn: '30d' }
            );

            res.json({
                success: true,
                token,
                host: {
                    uuid,
                    public_ip,
                    name: name || `Host ${uuid.substring(0, 8)}`
                }
            });
        }
    );
});

// Mettre à jour l'IP publique d'un hôte
app.post('/api/hosts/update-ip', authenticateToken, (req, res) => {
    const { public_ip } = req.body;
    const uuid = req.user.uuid;

    db.run(
        `UPDATE hosts SET public_ip = ?, last_seen = datetime('now') WHERE uuid = ?`,
        [public_ip, uuid],
        function(err) {
            if (err) {
                return res.status(500).json({ error: err.message });
            }
            res.json({ success: true });
        }
    );
});

// Lister tous les hôtes actifs
app.get('/api/hosts', (req, res) => {
    db.all(
        `SELECT uuid, public_ip, name, last_seen, is_active 
         FROM hosts 
         WHERE is_active = 1 
         ORDER BY last_seen DESC`,
        [],
        (err, rows) => {
            if (err) {
                return res.status(500).json({ error: err.message });
            }
            res.json(rows);
        }
    );
});

// Créer une session de streaming (depuis le site web)
app.post('/api/sessions/create', (req, res) => {
    const { host_uuid } = req.body;

    if (!host_uuid) {
        return res.status(400).json({ error: 'host_uuid requis' });
    }

    // Vérifier que l'hôte existe et est actif
    db.get(
        `SELECT * FROM hosts WHERE uuid = ? AND is_active = 1`,
        [host_uuid],
        (err, host) => {
            if (err) {
                return res.status(500).json({ error: err.message });
            }
            if (!host) {
                return res.status(404).json({ error: 'Hôte non trouvé ou inactif' });
            }

            // Générer un token pour le viewer
            const viewerToken = jwt.sign(
                { host_uuid, type: 'viewer' },
                JWT_SECRET,
                { expiresIn: '24h' }
            );

            // Créer la session
            db.run(
                `INSERT INTO sessions (host_uuid, viewer_token, expires_at, is_active)
                 VALUES (?, ?, datetime('now', '+24 hours'), 1)`,
                [host_uuid, viewerToken],
                function(err) {
                    if (err) {
                        return res.status(500).json({ error: err.message });
                    }

                    res.json({
                        success: true,
                        session: {
                            id: this.lastID,
                            host_uuid,
                            viewer_token: viewerToken,
                            public_ip: host.public_ip
                        }
                    });
                }
            );
        }
    );
});

// Vérifier un token de session
app.post('/api/sessions/verify', (req, res) => {
    const { token } = req.body;

    if (!token) {
        return res.status(400).json({ error: 'Token requis' });
    }

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) {
            return res.status(403).json({ error: 'Token invalide' });
        }

        // Vérifier que la session existe et est active
        db.get(
            `SELECT * FROM sessions WHERE viewer_token = ? AND is_active = 1 
             AND datetime('now') < expires_at`,
            [token],
            (err, session) => {
                if (err) {
                    return res.status(500).json({ error: err.message });
                }
                if (!session) {
                    return res.status(404).json({ error: 'Session non trouvée ou expirée' });
                }

                res.json({
                    valid: true,
                    host_uuid: session.host_uuid
                });
            }
        );
    });
});

// WebSocket pour les connexions Android
// Option 1 : Port séparé 8080 (pour accès direct, sans Cloudflare Tunnel)
const wssAndroidPort8080 = new WebSocket.Server({ port: 8080 });

// Option 2 : Chemin HTTP WebSocket sur port 3001 (pour Cloudflare Tunnel)
const wssAndroid = new WebSocket.Server({ 
    server: server,
    path: '/android-ws'
});

// Gestionnaire pour WebSocket Android via chemin HTTP (Cloudflare Tunnel compatible)
wssAndroid.on('connection', (ws, req) => {
    console.log('📱 Connexion Android WebSocket (HTTP)');
    handleAndroidConnection(ws);
});

// Gestionnaire pour WebSocket Android via port 8080 (accès direct)
wssAndroidPort8080.on('connection', (ws, req) => {
    console.log('📱 Connexion Android WebSocket (port 8080)');
    handleAndroidConnection(ws);
});

function handleAndroidConnection(ws) {
    
    let hostUuid = null;
    let authenticated = false;

    ws.on('message', async (data) => {
        try {
            const message = JSON.parse(data.toString());

            // Authentification initiale
            if (message.type === 'auth' && message.token) {
                jwt.verify(message.token, JWT_SECRET, (err, decoded) => {
                    if (err || decoded.type !== 'host') {
                        ws.send(JSON.stringify({ type: 'error', message: 'Authentification échouée' }));
                        ws.close();
                        return;
                    }

                    hostUuid = decoded.uuid;
                    authenticated = true;
                    ws.send(JSON.stringify({ type: 'authenticated', uuid: hostUuid }));
                    console.log(`✅ Hôte authentifié: ${hostUuid}`);
                });
                return;
            }

            // Relayer les frames seulement si authentifié
            if (authenticated && message.type === 'frame') {
                // Relayer aux viewers via le serveur web
                broadcastToViewers(hostUuid, message.data);
            }
        } catch (e) {
            console.error('Erreur message WebSocket:', e);
        }
    });

    ws.on('close', () => {
        console.log(`📱 Hôte déconnecté: ${hostUuid || 'non authentifié'}`);
    });
}

// WebSocket pour les viewers (via le serveur HTTP)
const wssViewers = new WebSocket.Server({ server });

const viewers = new Map(); // host_uuid -> Set of WebSocket connections

wssViewers.on('connection', (ws, req) => {
    console.log('🌐 Connexion viewer WebSocket');

    let hostUuid = null;

    ws.on('message', (data) => {
        try {
            const message = JSON.parse(data.toString());

            if (message.type === 'auth' && message.token) {
                jwt.verify(message.token, JWT_SECRET, (err, decoded) => {
                    if (err || decoded.type !== 'viewer') {
                        ws.send(JSON.stringify({ type: 'error', message: 'Token invalide' }));
                        ws.close();
                        return;
                    }

                    hostUuid = decoded.host_uuid;
                    
                    if (!viewers.has(hostUuid)) {
                        viewers.set(hostUuid, new Set());
                    }
                    viewers.get(hostUuid).add(ws);

                    ws.send(JSON.stringify({ type: 'authenticated', host_uuid: hostUuid }));
                    console.log(`✅ Viewer authentifié pour hôte: ${hostUuid}`);
                });
            }
        } catch (e) {
            console.error('Erreur viewer WebSocket:', e);
        }
    });

    ws.on('close', () => {
        if (hostUuid && viewers.has(hostUuid)) {
            viewers.get(hostUuid).delete(ws);
            if (viewers.get(hostUuid).size === 0) {
                viewers.delete(hostUuid);
            }
        }
        console.log('🌐 Viewer déconnecté');
    });
});

function broadcastToViewers(hostUuid, frameData) {
    if (viewers.has(hostUuid)) {
        const message = JSON.stringify({
            type: 'frame',
            data: frameData
        });

        viewers.get(hostUuid).forEach((viewer) => {
            if (viewer.readyState === WebSocket.OPEN) {
                viewer.send(message);
            }
        });
    }
}

// Route principale
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

server.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════╗
║   BooxStream Web Server démarré!      ║
╠════════════════════════════════════════╣
║ 🌐 API Web: http://localhost:${PORT}      ║
║ 📱 Android WebSocket: /android-ws (port ${PORT}) ou port 8080 ║
║ 👁️  Viewer WebSocket: port ${PORT}        ║
╚════════════════════════════════════════╝
    `);
});

// Nettoyage à l'arrêt
process.on('SIGINT', () => {
    console.log('\n🛑 Arrêt du serveur...');
    db.close();
    wssAndroid.close();
    wssViewers.close();
    server.close();
    process.exit(0);
});

