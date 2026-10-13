'use strict';
const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');
const base = process.env.BLOCKSIDE_URL || 'http://127.0.0.1:4173/blockside/';
const out = path.join(__dirname, 'results');
fs.mkdirSync(out, { recursive: true });
const errors = [];
(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1 });
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    const response = await page.goto(base + '?qa=1', { waitUntil: 'networkidle' });
    if (!response || !response.ok()) throw new Error('Game page failed to load: ' + (response && response.status()));
    await page.getByRole('button', { name: 'PLAY SOLO' }).click();
    await page.waitForTimeout(1200);
    const report = await page.evaluate(() => window.__BLOCKSIDE_QA__?.report());
    if (!report) throw new Error('Browser QA bridge is missing');
    const failures = Object.entries(report.checks).filter(([, ok]) => !ok).map(([name]) => name);
    if (failures.length) throw new Error('World checks failed: ' + failures.join(', ') + ' — ' + JSON.stringify(report.collisions));
    await page.evaluate(() => { const badge = document.getElementById('qaBadge'); if (badge) badge.style.display = 'none'; });
    await page.screenshot({ path: path.join(out, 'desktop.png'), fullPage: true });
    const pixelCheck = await page.locator('#game').evaluate(canvas => {
      const ctx = canvas.getContext('2d');
      const data = ctx.getImageData(Math.floor(canvas.width / 2), Math.floor(canvas.height / 2), 1, 1).data;
      return { width: canvas.width, height: canvas.height, centerPixel: [...data] };
    });
    if (pixelCheck.width < 1 || pixelCheck.height < 1) throw new Error('Canvas has zero size');
    await page.setViewportSize({ width: 390, height: 844 });
    await page.waitForTimeout(400);
    const mobile = await page.evaluate(() => ({
      width: innerWidth, height: innerHeight,
      canvasWidth: document.querySelector('#game').getBoundingClientRect().width,
      controlsVisible: !!document.querySelector('.controls') && getComputedStyle(document.querySelector('.controls')).display !== 'none',
      buttons: [...document.querySelectorAll('.actions button')].map(b => ({ id: b.id, right: Math.round(b.getBoundingClientRect().right), bottom: Math.round(b.getBoundingClientRect().bottom) }))
    }));
    await page.screenshot({ path: path.join(out, 'mobile.png'), fullPage: true });
    if (mobile.canvasWidth < mobile.width - 2) throw new Error('Canvas does not fill mobile viewport');
    const movementBefore = report.player;
    await page.keyboard.down('ArrowRight');
    await page.waitForTimeout(350);
    await page.keyboard.up('ArrowRight');
    const movementAfter = await page.evaluate(() => window.__BLOCKSIDE_QA__.report().player);
    if (movementAfter.x <= movementBefore.x) throw new Error('Keyboard movement did not move the player');
    const finalReport = { status: errors.length ? 'failed' : 'passed', timestamp: new Date().toISOString(), page: base, desktop: report, mobile, pixelCheck, movement: { before: movementBefore, after: movementAfter }, consoleErrors: errors };
    fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(finalReport, null, 2));
    if (errors.length) throw new Error('Browser console errors: ' + errors.join(' | '));
    console.log(JSON.stringify(finalReport, null, 2));
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error.stack || error); process.exitCode = 1; });
