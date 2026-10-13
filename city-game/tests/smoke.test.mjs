import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';

const file = new URL('../index.html', import.meta.url);
test('game entry file exists', () => assert.ok(existsSync(file)));
const html = readFileSync(file, 'utf8');
test('has mobile viewport and canvas', () => {
  assert.match(html, /name="viewport"/);
  assert.match(html, /<canvas id="game"/);
});
test('has touch and keyboard controls', () => {
  assert.match(html, /id="joy"/);
  assert.match(html, /ArrowRight/);
  assert.match(html, /pointerdown/);
});
test('has online room, player sync and chat hooks', () => {
  assert.match(html, /new Peer/);
  assert.match(html, /p\.connect\(id/);
  assert.match(html, /type:'state'/);
  assert.match(html, /type:'chat'/);
});
test('has core mobile UI actions', () => {
  assert.match(html, /id="host"/);
  assert.match(html, /id="join"/);
  assert.match(html, /id="wave"/);
  assert.match(html, /id="reset"/);
});
