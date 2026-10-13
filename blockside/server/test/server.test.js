'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const path = require('node:path');
const WebSocket = require('ws');

const PORT = 25681;
const BASE = 'http://127.0.0.1:' + PORT;
let child;

function wait(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }
async function waitForServer() {
  for (let i = 0; i < 60; i++) {
    try {
      const r = await fetch(BASE + '/health');
      if (r.ok) return;
    } catch {}
    await wait(100);
  }
  throw new Error('Server did not start in time');
}
function connect() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket('ws://127.0.0.1:' + PORT);
    ws.once('open', () => resolve(ws));
    ws.once('error', reject);
  });
}
function nextMessage(ws, predicate = () => true, timeout = 2500) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => { ws.off('message', onMessage); reject(new Error('Timed out waiting for WebSocket message')); }, timeout);
    function onMessage(raw) {
      let msg;
      try { msg = JSON.parse(raw.toString()); } catch { return; }
      if (!predicate(msg)) return;
      clearTimeout(timer); ws.off('message', onMessage); resolve(msg);
    }
    ws.on('message', onMessage);
  });
}
function send(ws, data) { ws.send(JSON.stringify(data)); }

test('room creation, join capacity, and server-ticked movement', async t => {
  child = spawn(process.execPath, [path.join(__dirname, '..', 'server.js')], {
    env: { ...process.env, PORT: String(PORT) }, stdio: 'ignore'
  });
  t.after(async () => {
    child?.kill('SIGTERM');
    await wait(100);
  });
  await waitForServer();
  const clients = [];
  t.after(() => clients.forEach(ws => { try { ws.close(); } catch {} }));

  const host = await connect(); clients.push(host);
  const joinedPromise = nextMessage(host, m => m.type === 'joined');
  send(host, { type: 'create', name: 'Host' });
  const created = await joinedPromise;
  assert.match(created.roomCode, /^[A-HJ-NP-Z2-9]{5}$/);
  assert.equal(created.capacity, 4);

  for (let i = 0; i < 3; i++) {
    const ws = await connect(); clients.push(ws);
    const joinPromise = nextMessage(ws, m => m.type === 'joined');
    send(ws, { type: 'join', code: created.roomCode, name: 'Friend' + i });
    const result = await joinPromise;
    assert.equal(result.roomCode, created.roomCode);
  }

  const full = await connect(); clients.push(full);
  const errorPromise = nextMessage(full, m => m.type === 'error');
  send(full, { type: 'join', code: created.roomCode, name: 'TooMany' });
  assert.match((await errorPromise).message, /full/i);

  const statePromise = nextMessage(host, m => m.type === 'state' && m.players.length === 4);
  await statePromise;
  const movedPromise = nextMessage(host, m => m.type === 'state' && m.players.some(p => p.name === 'Host' && p.x > 0));
  send(host, { type: 'input', input: { right: true } });
  const moved = await movedPromise;
  assert.ok(moved.players.find(p => p.name === 'Host').x > 0);
});
