const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const sqlite3 = require('sqlite3').verbose();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
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
const RELEASES_PATH = path.join(__dirname, '..', 'releases');

// ============================================================================
// GESTION DES HÔTES CONNECTÉS EN TEMPS RÉEL
// ============================================================================

// Map pour tracker les hôtes connectés en streaming
const connectedHosts = new Map(); // uuid -> { ws, connectedAt, lastFrame, frameCount, streaming }

// Map pour les viewers par hôte
const viewers = new Map(); // host_uuid -> Set of WebSocket connections

// Statistiques des frames par hôte
const frameStats = new Map(); // uuid -> { frameCount, lastFrameTime, fps, avgLatency }

// ============================================================================
// BASE DE DONNÉES
// ============================================================================

const db = new sqlite3.Database(DB_PATH);

// Créer les tables
db.serialize(() => {
    // Table des hôtes (clients qui partagent leur écran)
    db.run(`CREATE TABLE IF NOT EXISTS hosts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        device_id TEXT,
        public_ip TEXT,
        name TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_seen DATETIME,
        is_active INTEGER DEFAULT 1
    )`);

    // Ajouter la colonne device_id si elle n'existe pas
    db.run(`ALTER TABLE hosts ADD COLUMN device_id TEXT`, (err) => {
        // Ignorer l'erreur si la colonne existe déjà
    });

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

    // Nettoyer les anciens hôtes (plus de 7 jours d'inactivité)
    db.run(`UPDATE hosts SET is_active = 0 WHERE last_seen < datetime('now', '-7 days')`);
});

// ============================================================================
// MIDDLEWARE
// ============================================================================

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

// ============================================================================
// ROUTES API - TÉLÉCHARGEMENT DES APPLICATIONS
// ============================================================================

// Endpoint pour télécharger l'APK Android
app.get('/api/download/android', (req, res) => {
    const apkPath = path.join(RELEASES_PATH, 'android', 'booxstream.apk');
    
    if (fs.existsSync(apkPath)) {
        res.download(apkPath, 'BooxStream.apk');
    } else {
        res.status(404).json({ 
            error: 'APK non disponible',
            message: 'Placez le fichier APK dans releases/android/booxstream.apk'
        });
    }
});

// Endpoint pour télécharger l'application Windows (MSI ou EXE)
app.get('/api/download/windows', (req, res) => {
    // Chercher le fichier d'installation Windows
    const windowsPath = path.join(RELEASES_PATH, 'windows');
    const files = fs.existsSync(windowsPath) ? fs.readdirSync(windowsPath) : [];
    
    const installerFile = files.find(f => f.endsWith('.msi') || f.endsWith('.exe'));
    
    if (installerFile) {
        res.download(path.join(windowsPath, installerFile), installerFile);
    } else {
        res.status(404).json({ 
            error: 'Installateur Windows non disponible',
            message: 'Placez le fichier MSI/EXE dans releases/windows/'
        });
    }
});

// Endpoint pour lister les téléchargements disponibles
app.get('/api/downloads', (req, res) => {
    const downloads = [];
    
    // Vérifier Android
    const apkPath = path.join(RELEASES_PATH, 'android', 'booxstream.apk');
    if (fs.existsSync(apkPath)) {
        const stats = fs.statSync(apkPath);
        downloads.push({
            platform: 'android',
            filename: 'BooxStream.apk',
            size: stats.size,
            url: '/api/download/android',
            lastModified: stats.mtime
        });
    }
    
    // Vérifier Windows
    const windowsPath = path.join(RELEASES_PATH, 'windows');
    if (fs.existsSync(windowsPath)) {
        const files = fs.readdirSync(windowsPath);
        const installer = files.find(f => f.endsWith('.msi') || f.endsWith('.exe'));
        if (installer) {
            const stats = fs.statSync(path.join(windowsPath, installer));
            downloads.push({
                platform: 'windows',
                filename: installer,
                size: stats.size,
                url: '/api/download/windows',
                lastModified: stats.mtime
            });
        }
    }
    
    res.json({ downloads });
});

// ============================================================================
// ROUTES API - GESTION DES HÔTES
// ============================================================================

// Enregistrer un nouvel hôte (depuis l'app Android)
app.post('/api/hosts/register', (req, res) => {
    const { uuid, public_ip, name, device_id } = req.body;

    if (!uuid) {
        return res.status(400).json({ error: 'UUID requis' });
    }

    db.run(
        `INSERT OR REPLACE INTO hosts (uuid, device_id, public_ip, name, last_seen, is_active)
         VALUES (?, ?, ?, ?, datetime('now'), 1)`,
        [uuid, device_id || null, public_ip || null, name || `Host ${uuid.substring(0, 8)}`],
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

// Lister tous les hôtes actifs avec statut de connexion en temps réel
app.get('/api/hosts', (req, res) => {
    db.all(
        `SELECT uuid, device_id, public_ip, name, last_seen, is_active 
         FROM hosts 
         WHERE is_active = 1 
         ORDER BY last_seen DESC`,
        [],
        (err, rows) => {
            if (err) {
                return res.status(500).json({ error: err.message });
            }
            
            // Ajouter le statut de connexion en temps réel
            const hostsWithStatus = rows.map(host => ({
                ...host,
                is_streaming: connectedHosts.has(host.uuid),
                viewers_count: viewers.has(host.uuid) ? viewers.get(host.uuid).size : 0,
                stats: frameStats.get(host.uuid) || null
            }));
            
            res.json(hostsWithStatus);
        }
    );
});

// Supprimer un hôte (désactiver)
app.delete('/api/hosts/:uuid', (req, res) => {
    const { uuid } = req.params;
    
    db.run(
        `UPDATE hosts SET is_active = 0 WHERE uuid = ?`,
        [uuid],
        function(err) {
            if (err) {
                return res.status(500).json({ error: err.message });
            }
            res.json({ success: true });
        }
    );
});

// Nettoyer les doublons (garder seulement le plus récent par appareil)
app.post('/api/hosts/cleanup', (req, res) => {
    // Désactiver les anciens hôtes avec le même nom mais UUID différent
    db.run(
        `UPDATE hosts SET is_active = 0 
         WHERE id NOT IN (
             SELECT MAX(id) FROM hosts 
             WHERE is_active = 1 
             GROUP BY name
         ) AND is_active = 1`,
        [],
        function(err) {
            if (err) {
                return res.status(500).json({ error: err.message });
            }
            res.json({ success: true, deactivated: this.changes });
        }
    );
});

// ============================================================================
// ROUTES API - SESSIONS
// ============================================================================

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
                            public_ip: host.public_ip,
                            is_streaming: connectedHosts.has(host_uuid)
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

// ============================================================================
// ROUTES API - STATISTIQUES
// ============================================================================

app.get('/api/stats', (req, res) => {
    const stats = {
        connectedHosts: connectedHosts.size,
        totalViewers: Array.from(viewers.values()).reduce((sum, set) => sum + set.size, 0),
        hosts: {}
    };
    
    connectedHosts.forEach((hostData, uuid) => {
        stats.hosts[uuid] = {
            connectedAt: hostData.connectedAt,
            frameCount: hostData.frameCount,
            streaming: hostData.streaming,
            viewers: viewers.has(uuid) ? viewers.get(uuid).size : 0,
            stats: frameStats.get(uuid) || null
        };
    });
    
    res.json(stats);
});

// ============================================================================
// WEBSOCKET - CONNEXIONS ANDROID
// ============================================================================

// Option 1 : Port séparé 8080 (pour accès direct)
const wssAndroidPort8080 = new WebSocket.Server({ port: 8080 });

// Option 2 : Chemin HTTP WebSocket sur port 3001 (pour Cloudflare Tunnel)
const wssAndroid = new WebSocket.Server({ noServer: true });

// WebSocket pour les viewers
const wssViewers = new WebSocket.Server({ noServer: true });

// Gestionnaires
wssAndroid.on('connection', (ws, req) => {
    console.log('📱 Connexion Android WebSocket (HTTP)');
    handleAndroidConnection(ws);
});

wssAndroidPort8080.on('connection', (ws, req) => {
    console.log('📱 Connexion Android WebSocket (port 8080)');
    handleAndroidConnection(ws);
});

// Gérer l'upgrade HTTP vers WebSocket
server.on('upgrade', (request, socket, head) => {
    if (request.url === '/android-ws') {
        wssAndroid.handleUpgrade(request, socket, head, (ws) => {
            wssAndroid.emit('connection', ws, request);
        });
    } else {
        wssViewers.handleUpgrade(request, socket, head, (ws) => {
            wssViewers.emit('connection', ws, request);
        });
    }
});

// ============================================================================
// GESTION DES CONNEXIONS ANDROID
// ============================================================================

function handleAndroidConnection(ws) {
    let hostUuid = null;
    let authenticated = false;
    let frameSequence = 0;

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
                    
                    // Enregistrer la connexion
                    connectedHosts.set(hostUuid, {
                        ws,
                        connectedAt: Date.now(),
                        lastFrame: null,
                        frameCount: 0,
                        streaming: true
                    });
                    
                    // Initialiser les stats
                    frameStats.set(hostUuid, {
                        frameCount: 0,
                        lastFrameTime: Date.now(),
                        fps: 0,
                        avgLatency: 0,
                        startTime: Date.now()
                    });
                    
                    // Mettre à jour last_seen dans la DB
                    db.run(`UPDATE hosts SET last_seen = datetime('now') WHERE uuid = ?`, [hostUuid]);
                    
                    ws.send(JSON.stringify({ type: 'authenticated', uuid: hostUuid }));
                    console.log(`✅ Hôte authentifié et connecté: ${hostUuid}`);
                    
                    // Notifier les viewers que l'hôte est en ligne
                    broadcastHostStatus(hostUuid, true);
                });
                return;
            }

            // Relayer les frames avec timestamps
            if (authenticated && message.type === 'frame') {
                const hostData = connectedHosts.get(hostUuid);
                if (hostData) {
                    hostData.frameCount++;
                    hostData.lastFrame = Date.now();
                    
                    // Mettre à jour les stats
                    const stats = frameStats.get(hostUuid);
                    if (stats) {
                        stats.frameCount++;
                        const now = Date.now();
                        const elapsed = (now - stats.startTime) / 1000;
                        stats.fps = Math.round(stats.frameCount / elapsed * 10) / 10;
                        stats.lastFrameTime = now;
                    }
                }
                
                // Ajouter métadonnées à la frame
                frameSequence++;
                const timestamp = Date.now();
                
                broadcastToViewers(hostUuid, {
                    data: message.data,
                    seq: frameSequence,
                    ts: timestamp,
                    hostTs: message.timestamp || timestamp
                });
            }
        } catch (e) {
            console.error('Erreur message WebSocket:', e);
        }
    });

    ws.on('close', () => {
        if (hostUuid) {
            connectedHosts.delete(hostUuid);
            console.log(`📱 Hôte déconnecté: ${hostUuid}`);
            
            // Notifier les viewers que l'hôte est hors ligne
            broadcastHostStatus(hostUuid, false);
        }
    });
    
    ws.on('error', (err) => {
        console.error(`❌ Erreur WebSocket hôte ${hostUuid}:`, err.message);
    });
}

// ============================================================================
// GESTION DES VIEWERS
// ============================================================================

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

                    // Envoyer l'état de l'hôte
                    const isStreaming = connectedHosts.has(hostUuid);
                    const stats = frameStats.get(hostUuid);
                    
                    ws.send(JSON.stringify({ 
                        type: 'authenticated', 
                        host_uuid: hostUuid,
                        is_streaming: isStreaming,
                        stats: stats
                    }));
                    
                    console.log(`✅ Viewer authentifié pour hôte: ${hostUuid} (streaming: ${isStreaming})`);
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

// ============================================================================
// BROADCAST HELPERS
// ============================================================================

function broadcastToViewers(hostUuid, frameData) {
    if (viewers.has(hostUuid)) {
        const message = JSON.stringify({
            type: 'frame',
            ...frameData
        });

        viewers.get(hostUuid).forEach((viewer) => {
            if (viewer.readyState === WebSocket.OPEN) {
                viewer.send(message);
            }
        });
    }
}

function broadcastHostStatus(hostUuid, isOnline) {
    if (viewers.has(hostUuid)) {
        const message = JSON.stringify({
            type: 'host_status',
            host_uuid: hostUuid,
            is_streaming: isOnline,
            timestamp: Date.now()
        });

        viewers.get(hostUuid).forEach((viewer) => {
            if (viewer.readyState === WebSocket.OPEN) {
                viewer.send(message);
            }
        });
    }
}

// ============================================================================
// ROUTES STATIQUES
// ============================================================================

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ============================================================================
// DÉMARRAGE DU SERVEUR
// ============================================================================

server.listen(PORT, '0.0.0.0', () => {
    console.log(`
╔═══════════════════════════════════════════════════════════╗
║          BooxStream Web Server v2.0 démarré!             ║
╠═══════════════════════════════════════════════════════════╣
║ 🌐 API Web:           http://0.0.0.0:${PORT}                ║
║ 📱 Android WebSocket: /android-ws (port ${PORT}) ou port 8080 ║
║ 👁️  Viewer WebSocket:  port ${PORT}                          ║
╠═══════════════════════════════════════════════════════════╣
║ 📥 Téléchargements:                                       ║
║    - Android: /api/download/android                       ║
║    - Windows: /api/download/windows                       ║
║    - Liste:   /api/downloads                              ║
╠═══════════════════════════════════════════════════════════╣
║ 📊 Statistiques: /api/stats                               ║
╚═══════════════════════════════════════════════════════════╝
    `);
});

// Nettoyage à l'arrêt
process.on('SIGINT', () => {
    console.log('\n🛑 Arrêt du serveur...');
    db.close();
    wssAndroid.close();
    wssAndroidPort8080.close();
    wssViewers.close();
    server.close();
    process.exit(0);
});
