'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const path = require('node:path');
const fs = require('node:fs');
const vm = require('node:vm');
const WebSocket = require('ws');

const PORT = 25681;
const BASE = 'http://127.0.0.1:' + PORT;
let child;
function wait(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }
async function waitForServer() {
  for (let i = 0; i < 60; i++) {
    try { const r = await fetch(BASE + '/health'); if (r.ok) return; } catch {}
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

test('room creation, join capacity, server movement, and resource snapshots', async t => {
  child = spawn(process.execPath, [path.join(__dirname, '..', 'server.js')], {
    env: { ...process.env, PORT: String(PORT) }, stdio: 'ignore'
  });
  t.after(async () => { child?.kill('SIGTERM'); await wait(100); });
  await waitForServer();
  const clients = [];
  t.after(() => clients.forEach(ws => { try { ws.close(); } catch {} }));

  const host = await connect(); clients.push(host);
  const joinedPromise = nextMessage(host, m => m.type === 'joined');
  send(host, { type: 'create', name: 'Host' });
  const created = await joinedPromise;
  assert.match(created.roomCode, /^[A-HJ-NP-Z2-9]{5}$/);
  assert.equal(created.capacity, 4);
  const firstStatePromise = nextMessage(host, m => m.type === 'state');
  const firstState = await firstStatePromise;
  assert.ok(firstState.resources.some(r => r.kind === 'wood' && r.remaining > 0));
  assert.ok(firstState.resources.some(r => r.kind === 'berries' && r.remaining > 0));
  assert.deepEqual(firstState.objective, { title: 'Prepare the expedition', detail: 'Craft 3 camp kits for the party', progress: 0, target: 3, complete: false });
  assert.deepEqual(firstState.quest, { id: 'village-cook', title: 'Help the village cook', detail: 'Deliver 5 berries to Mara the Cook', progress: 0, target: 5, complete: false, reward: 8 });
  assert.deepEqual(firstState.quests.carpenter, { id: 'carpenter-wood', title: 'Repair the village workshop', progress: 0, target: 3, complete: false, reward: 12, unlocked: false });
  assert.equal(firstState.village.workshopRepaired, false);
  assert.equal(firstState.village.mood, 'Quiet');
  assert.deepEqual(firstState.campfire, { built: false, fuel: 0 });
  assert.equal(firstState.players[0].cookedMeals, 0);
  assert.equal(typeof firstState.clockSeconds, 'number');
  assert.equal(firstState.villagers.length, 2);
  assert.ok(firstState.villagers.some(v => v.name === 'Mara the Cook'));
  assert.ok(firstState.villagers.some(v => v.name === 'Bram the Carpenter'));
  const lockedQuestError = nextMessage(host, m => m.type === 'error' && /Help Mara the Cook first/i.test(m.message));
  send(host, { type: 'quest', questId: 'carpenter-wood' });
  assert.match((await lockedQuestError).message, /unlock Bram/i);
  const questSupplyError = nextMessage(host, m => m.type === 'error' && /needs 5 berries/i.test(m.message));
  send(host, { type: 'quest', questId: 'village-cook' });
  assert.match((await questSupplyError).message, /needs 5 berries/i);
  const noFireCookError = nextMessage(host, m => m.type === 'error' && /Build a campfire/i.test(m.message));
  send(host, { type: 'survival', action: 'cook' });
  assert.match((await noFireCookError).message, /campfire/i);
  const noMealError = nextMessage(host, m => m.type === 'error' && /no cooked meals/i.test(m.message));
  send(host, { type: 'survival', action: 'eat-meal' });
  assert.match((await noMealError).message, /no cooked meals/i);

  const recipeError = nextMessage(host, m => m.type === 'error' && /3 wood and 2 berries/i.test(m.message));
  send(host, { type: 'craft', recipe: 'camp-kit' });
  assert.match((await recipeError).message, /3 wood and 2 berries/i);
  // The server does not consume materials or advance the party goal on an invalid craft.

  for (let i = 0; i < 3; i++) {
    const ws = await connect(); clients.push(ws);
    const joinPromise = nextMessage(ws, m => m.type === 'joined');
    send(ws, { type: 'join', code: created.roomCode, name: 'Friend' + i });
    assert.equal((await joinPromise).roomCode, created.roomCode);
  }
  const full = await connect(); clients.push(full);
  const errorPromise = nextMessage(full, m => m.type === 'error');
  send(full, { type: 'join', code: created.roomCode, name: 'TooMany' });
  assert.match((await errorPromise).message, /full/i);

  const statePromise = nextMessage(host, m => m.type === 'state' && m.players.length === 4);
  await statePromise;
  const movedPromise = nextMessage(host, m => m.type === 'state' && m.players.some(p => p.name === 'Host' && p.x > 0));
  send(host, { type: 'input', input: { right: true } });
  assert.ok((await movedPromise).players.find(p => p.name === 'Host').x > 0);
  send(host, { type: 'input', input: { right: false } });

  const rejectedPromise = nextMessage(host, m => m.type === 'error' && /closer/i.test(m.message));
  send(host, { type: 'gather', kind: 'wood' });
  assert.match((await rejectedPromise).message, /closer/i);

  const farAwayPromise = nextMessage(host, m => m.type === 'state' && m.players.some(p => p.name === 'Host' && Math.abs(p.x) > 150));
  send(host, { type: 'input', input: { right: true } });
  await farAwayPromise;
  send(host, { type: 'input', input: { right: false } });
  const distantQuestError = nextMessage(host, m => m.type === 'error' && /current location/i.test(m.message));
  send(host, { type: 'quest', questId: 'village-cook' });
  assert.match((await distantQuestError).message, /current location/i);
});

test('browser game JavaScript parses without syntax errors', () => {
  const htmlPath = path.join(__dirname, '..', '..', 'index.html');
  const html = fs.readFileSync(htmlPath, 'utf8');
  const scriptStart = html.indexOf('<script>');
  const scriptEnd = html.indexOf('</script>', scriptStart);
  assert.ok(scriptStart >= 0 && scriptEnd > scriptStart, 'Expected the game HTML to contain an inline script');
  const script = html.slice(scriptStart + '<script>'.length, scriptEnd);
  assert.doesNotThrow(() => new vm.Script(script, { filename: 'blockside/index.html' }));
  assert.match(script, /function worldDraw\(\)/);
  assert.match(script, /worldDraw\(\);/);
  assert.match(script, /rgba\(15,24,48,/);
  assert.match(script, /function updateLocalVillagers\(\)/);
  assert.match(script, /carpenter-wood/);
  assert.match(script, /workshopRepaired/);
  assert.match(script, /The workshop is open/);
});
