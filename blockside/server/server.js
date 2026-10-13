'use strict';

const http = require('node:http');
const crypto = require('node:crypto');
const WebSocket = require('ws');

const PORT = Number(process.env.PORT || 2567);
const MAX_PLAYERS = 4;
const TICK_MS = 50;
const SPEED = 145;
const GATHER_RANGE = 90;
const GATHER_COOLDOWN_MS = 700;
const rooms = new Map();
const sockets = new Map();

function roomCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code;
  do { code = Array.from({ length: 5 }, () => alphabet[crypto.randomInt(alphabet.length)]).join(''); }
  while (rooms.has(code));
  return code;
}
function send(ws, payload) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(payload));
}
function createResources() {
  // Keep the same seeded generation order as the browser so both clients agree on world locations.
  let seed = 58321;
  const rand = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
  const nodes = [];
  for (let i = 0; i < 100; i++) {
    const x = (rand() - .5) * 1700, y = (rand() - .5) * 1300;
    if (Math.abs(x) < 120 && Math.abs(y) < 100) continue;
    rand(); // tree radius
    nodes.push({ id: 'tree-' + i, kind: 'wood', x, y, remaining: 3 });
  }
  for (let i = 0; i < 34; i++) {
    const x = (rand() - .5) * 1200, y = (rand() - .5) * 850;
    rand(); // bush radius
    const berries = 2 + Math.floor(rand() * 4);
    nodes.push({ id: 'bush-' + i, kind: 'berries', x, y, remaining: berries });
  }
  return nodes;
}
function publicState(room) {
  return {
    type: 'state', roomCode: room.code,
    players: [...room.players.values()].map(p => ({
      id: p.id, x: Math.round(p.x), y: Math.round(p.y), color: p.color,
      name: p.name, wood: p.wood, berries: p.berries, craftedKits: p.craftedKits
    })),
    objective: { title: 'Prepare the expedition', detail: 'Craft 3 camp kits for the party', progress: room.objective.kits, target: room.objective.target, complete: room.objective.kits >= room.objective.target },
    resources: room.resources.map(({ id, kind, x, y, remaining }) => ({ id, kind, x: Math.round(x), y: Math.round(y), remaining }))
  };
}
function broadcast(room) {
  const state = publicState(room);
  for (const player of room.players.values()) send(player.ws, state);
}
function removePlayer(ws) {
  const session = sockets.get(ws);
  if (!session) return;
  sockets.delete(ws);
  const room = rooms.get(session.roomCode);
  if (!room) return;
  room.players.delete(session.playerId);
  if (room.players.size === 0) rooms.delete(room.code);
  else broadcast(room);
}
function joinRoom(ws, code, requestedName) {
  const room = rooms.get(String(code || '').toUpperCase());
  if (!room) return send(ws, { type: 'error', message: 'Room not found. Check the code or create a new room.' });
  if (room.players.size >= MAX_PLAYERS) return send(ws, { type: 'error', message: 'This room is full (4/4 players).' });
  const id = crypto.randomUUID();
  const player = {
    id, ws, name: String(requestedName || 'Traveller').trim().slice(0, 18) || 'Traveller',
    x: room.players.size * 28, y: 0, vx: 0, vy: 0, color: room.players.size,
    input: { up: false, down: false, left: false, right: false },
    wood: 0, berries: 0, craftedKits: 0, lastGatherAt: 0
  };
  room.players.set(id, player);
  sockets.set(ws, { roomCode: room.code, playerId: id });
  send(ws, { type: 'joined', playerId: id, roomCode: room.code, capacity: MAX_PLAYERS });
  broadcast(room);
}
const server = http.createServer((req, res) => {
  if (req.url === '/health' || req.url === '/') {
    res.writeHead(200, { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' });
    res.end(JSON.stringify({ name: 'Blockside Realm Server', status: 'ok', maxPlayersPerRoom: MAX_PLAYERS, rooms: rooms.size }));
    return;
  }
  res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' });
  res.end('Not found');
});
const wss = new WebSocket.Server({ server, maxPayload: 2048 });
wss.on('connection', ws => {
  let messageCount = 0, windowStart = Date.now();
  ws.on('message', raw => {
    const now = Date.now();
    if (now - windowStart > 1000) { windowStart = now; messageCount = 0; }
    if (++messageCount > 45) return send(ws, { type: 'error', message: 'Too many messages; slow down.' });
    let msg;
    try { msg = JSON.parse(raw.toString()); } catch { return send(ws, { type: 'error', message: 'Invalid message format.' }); }
    if (!msg || typeof msg.type !== 'string') return;
    if (msg.type === 'create') {
      if (sockets.has(ws)) return send(ws, { type: 'error', message: 'You are already in a room.' });
      const code = roomCode();
      rooms.set(code, { code, players: new Map(), resources: createResources(), objective: { kits: 0, target: 3 } });
      return joinRoom(ws, code, msg.name);
    }
    if (msg.type === 'join') {
      if (sockets.has(ws)) return send(ws, { type: 'error', message: 'You are already in a room.' });
      if (typeof msg.code !== 'string' || !/^[A-HJ-NP-Z2-9]{5}$/i.test(msg.code))
        return send(ws, { type: 'error', message: 'Enter a valid five-character room code.' });
      return joinRoom(ws, msg.code, msg.name);
    }
    const session = sockets.get(ws);
    if (!session) return send(ws, { type: 'error', message: 'Create or join a room first.' });
    const room = rooms.get(session.roomCode), player = room && room.players.get(session.playerId);
    if (!player) return;
    if (msg.type === 'input') {
      const i = msg.input || {};
      for (const key of ['up', 'down', 'left', 'right']) player.input[key] = i[key] === true;
    } else if (msg.type === 'craft') {
      if (msg.recipe !== 'camp-kit') return send(ws, { type: 'error', message: 'Unknown recipe.' });
      if (player.wood < 3 || player.berries < 2)
        return send(ws, { type: 'error', message: 'Camp kit needs 3 wood and 2 berries. Gather more supplies.' });
      player.wood -= 3;
      player.berries -= 2;
      player.craftedKits++;
      room.objective.kits++;
      broadcast(room);
    } else if (msg.type === 'gather') {
      if (now - player.lastGatherAt < GATHER_COOLDOWN_MS)
        return send(ws, { type: 'error', message: 'Give it a moment before gathering again.' });
      if (msg.kind !== 'wood' && msg.kind !== 'berries')
        return send(ws, { type: 'error', message: 'Unknown resource.' });
      const node = room.resources
        .filter(r => r.kind === msg.kind && r.remaining > 0)
        .map(r => ({ resource: r, distance: Math.hypot(r.x - player.x, r.y - player.y) }))
        .sort((a, b) => a.distance - b.distance)[0];
      if (!node || node.distance > GATHER_RANGE)
        return send(ws, { type: 'error', message: 'Move closer to a living resource before gathering.' });
      node.resource.remaining--;
      if (msg.kind === 'wood') player.wood = Math.min(999, player.wood + 1);
      else player.berries = Math.min(999, player.berries + 1);
      player.lastGatherAt = now;
      broadcast(room);
    }
  });
  ws.on('close', () => removePlayer(ws));
  ws.on('error', () => removePlayer(ws));
});
const tick = setInterval(() => {
  for (const room of rooms.values()) {
    for (const p of room.players.values()) {
      let dx = Number(p.input.right) - Number(p.input.left);
      let dy = Number(p.input.down) - Number(p.input.up);
      if (dx && dy) { dx *= Math.SQRT1_2; dy *= Math.SQRT1_2; }
      p.x = Math.max(-3000, Math.min(3000, p.x + dx * SPEED * TICK_MS / 1000));
      p.y = Math.max(-3000, Math.min(3000, p.y + dy * SPEED * TICK_MS / 1000));
    }
    broadcast(room);
  }
}, TICK_MS);
server.on('close', () => clearInterval(tick));
server.listen(PORT, '0.0.0.0', () => console.log('Blockside Realm Server listening on ' + PORT));
