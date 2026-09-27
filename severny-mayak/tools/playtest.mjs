// Автотест: проходит игру целиком во всех финалах в Chromium (Playwright).
// Запуск: node tools/playtest.mjs [ru|en]
import { chromium } from 'playwright';  // npm i (devDependencies) или глобальный playwright
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const lang = process.argv[2] || 'ru';
const url = 'file://' + path.join(root, 'game', 'index.html') + '?test&lang=' + lang;
const shotDir = process.env.SHOTS || '';
const browser = await chromium.launch(process.env.CHROME ? { executablePath: process.env.CHROME } : {});
let failed = 0;

async function run(name, ending, { shards = false, caughtFirst = false } = {}) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  const shot = async n => { if (shotDir) await page.screenshot({ path: `${shotDir}/${lang}-${name}-${n}.png` }); };
  const until = (fn, arg, t = 30000) => page.waitForFunction(fn, arg, { timeout: t });
  const quiet = () => until(() => !document.querySelector('#avatar.talk') && SM.state && true).then(() => page.waitForTimeout(150));
  const open = async id => { await page.dblclick(`.icon[data-id="${id}"]`); await page.waitForTimeout(60); };
  const closeAll = () => page.evaluate(() => SM.closeAll());
  const grab = async () => { for (const b of await page.$$('.shard')) { try { await b.click({ timeout: 1500, force: true }); } catch {} } };
  try {
    await page.goto(url);
    await page.evaluate(() => localStorage.clear());
    await page.goto(url);
    await page.click('#wOk');
    await shot('title');
    await page.click('#tNew');
    await until(() => SM.state.goal === 'note');
    await shot('desk0');
    await open('note'); await until(() => SM.state.goal === 'find');
    await open('draw'); await page.click('.file[data-i="1"]'); if (shards) await grab();
    await page.click('.win[data-win="img1"] .x');
    await page.click('.win[data-win="draw"] .file[data-i="2"]'); if (shards) await grab();
    await closeAll();
    await open('pixel'); await closeAll();
    await open('web'); await until(() => SM.state.goal === 'diary' && SM.state.stage === 1);
    await closeAll();
    await open('mail');
    for (const box of ['inbox', 'drafts', 'sent']) {
      await page.click(`[data-b="${box}"]`);
      const ids = await page.$$eval('[data-m]', l => l.map(x => x.dataset.m));
      for (const id of ids) { await page.click(`[data-m="${id}"]`); if (shards) await grab(); }
    }
    await closeAll();
    await open('tale');
    for (let i = 0; i < 4; i++) { await page.click(`.win[data-win="tale"] .file[data-i="${i}"]`); if (shards) await grab(); await page.click(`.win[data-win="ch${i}"] .x`); }
    await closeAll();
    if (shards) { await open('cam'); await grab(); await closeAll(); }
    await open('diary');
    await page.fill('.lock input', 'котлета'); await page.click('.lock button');
    const pw = lang === 'en' ? 'north lighthouse' : 'северный маяк';
    await page.fill('.lock input', pw); await page.click('.lock button');
    await until(() => SM.state.stage === 2);
    if (shards) await grab();
    await shot('diary');
    await closeAll();
    // камера при маме в комнате поднимает «палево»
    // прятки: тихо пересидеть визит — палево падает; дёргать мышь — растёт
    await page.evaluate(() => SM.startVisit()); await until(() => SM.Visit.phase === 'in'); await page.waitForTimeout(150); await shot('visit');
    await until(() => SM.Visit.phase === null, null, 60000);
    const s1 = await page.evaluate(() => SM.state.sus);
    await page.evaluate(() => { SM.T.scale = 1; SM.startVisit(); }); await until(() => SM.Visit.phase === 'in');
    for (let i = 0; i < 6; i++) { await page.mouse.move(300 + i * 40, 300); await page.waitForTimeout(40); }
    await until(() => SM.Visit.phase === null, null, 60000);
    const s2 = await page.evaluate(() => { const v = SM.state.sus; SM.T.scale = 25; return v; });
    if (!(s2 > s1)) throw new Error('moving during visit did not raise suspicion ' + s1 + ' -> ' + s2);
    await open('cam'); await page.waitForTimeout(60); await page.click('.win[data-win="cam"] .x');
    const sus = await page.evaluate(() => SM.state.sus);
    if (!(sus > 0)) throw new Error('camera did not raise suspicion');
    if (caughtFirst) {
      await page.evaluate(() => SM.addSus(100, 'cam'));
      await until(() => !document.querySelector('#end').classList.contains('hide') && !document.querySelector('#endRetry').hidden);
      await shot('caught');
      await page.click('#endRetry');
      await until(() => SM.state.inGame && SM.state.stage === 2 && SM.state.sus <= 35);
    }
    await open('bin');
    await page.click('.win[data-win="bin"] button[data-i="2"]');
    await until(() => SM.state.goal === 'tm');
    await closeAll();
    await page.click('#startBtn'); await page.click('#menu [data-a="tm"]');
    if (shards) await grab();
    for (let i = 0; i < 3; i++) {
      await page.click('.tm tr.bad'); await page.click('#tmEnd'); await page.waitForTimeout(80);
    }
    await until(() => SM.state.goal === 'restore');
    await closeAll();
    if (shards) { const n = await page.evaluate(() => SM.state.shards.length); if (n !== 7) throw new Error('shards ' + n); }
    await open('bin');
    await page.click('.win[data-win="bin"] button[data-i="2"]');
    await until(() => SM.state.stage === 3, null, 60000);
    await shot('reveal');
    await until(() => !!document.querySelector('#tell'), null, 60000);
    await shot('choice');
    await page.click({ a: '#tell', t: '#tell', b: '#silent', c: '#pretend' }[ending]);
    if (ending === 't') { await until(() => !!SM.W.letter, null, 120000); await page.waitForTimeout(300); await shot('epilogue'); }
    await until(e => SM.state.ending === e, ending, 120000);
    await shot('end');
    const title = await page.textContent('#endTitle');
    if (errors.length) throw new Error(errors.join('\n'));
    console.log(`OK  ${lang} ${name}: «${title}»  палево max=${Math.round(await page.evaluate(() => SM.state.susMax))}`);
  } catch (e) {
    failed++;
    await shot('FAIL');
    console.log(`FAIL ${lang} ${name}: ${e.message}\n${errors.join('\n')}`);
  }
  await page.close();
}

await run('truth', 'a');
await run('true-ending', 't', { shards: true });
await run('silent', 'b', { caughtFirst: true });
await run('pretend', 'c');
await browser.close();
process.exit(failed ? 1 : 0);
