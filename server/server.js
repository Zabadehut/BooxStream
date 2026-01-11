const WebSocket = require('ws');
const express = require('express');
const http = require('http');
const path = require('path');

const app = express();
const server = http.createServer(app);

// WebSocket pour l'app Android
const wssAndroid = new WebSocket.Server({ port: 8080 });

// WebSocket pour les clients web
const wssWeb = new WebSocket.Server({ server });

let androidClient = null;
const webClients = new Set();

// Connexion depuis l'app Android
wssAndroid.on('connection', (ws) => {
    console.log('📱 Tablette Boox connectée');
    androidClient = ws;
    
    // Notifier les clients web
    broadcastToWeb(JSON.stringify({ type: 'status', connected: true }));
    
    ws.on('message', (data) => {
        // Relayer les frames aux clients web
        if (webClients.size > 0) {
            const base64 = data.toString('base64');
            broadcastToWeb(JSON.stringify({
                type: 'frame',
                data: base64
            }));
        }
    });
    
    ws.on('close', () => {
        console.log('📱 Tablette déconnectée');
        androidClient = null;
        broadcastToWeb(JSON.stringify({ type: 'status', connected: false }));
    });
    
    ws.on('error', (error) => {
        console.error('❌ Erreur Android WebSocket:', error);
    });
});

// Connexion depuis les navigateurs web
wssWeb.on('connection', (ws) => {
    console.log('🌐 Client web connecté');
    webClients.add(ws);
    
    // Envoyer le statut initial
    ws.send(JSON.stringify({
        type: 'status',
        connected: androidClient !== null
    }));
    
    ws.on('close', () => {
        console.log('🌐 Client web déconnecté');
        webClients.delete(ws);
    });
    
    ws.on('error', (error) => {
        console.error('❌ Erreur Web WebSocket:', error);
        webClients.delete(ws);
    });
});

function broadcastToWeb(message) {
    webClients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(message);
        }
    });
}

// Serveur HTTP pour l'interface web
app.use(express.static('public'));

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const HTTP_PORT = 3000;
server.listen(HTTP_PORT, '0.0.0.0', () => {
    console.log(`
╔════════════════════════════════════════╗
║   BooxStream Server démarré!           ║
╠════════════════════════════════════════╣
║ 📱 Android WebSocket: port 8080        ║
║ 🌐 Interface web: http://localhost:${HTTP_PORT}  ║
╚════════════════════════════════════════╝
    `);
});

// Gestion propre de l'arrêt
process.on('SIGINT', () => {
    console.log('\n🛑 Arrêt du serveur...');
    wssAndroid.close();
    wssWeb.close();
    server.close();
    process.exit(0);
});

