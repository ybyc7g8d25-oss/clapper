// Обёртка для Steam: окно Electron + достижения Steamworks.
// Без Steam (или без steamworks.js) игра просто работает без достижений.
const { app, BrowserWindow, ipcMain, Menu } = require('electron');
const path = require('path');
const fs = require('fs');

let steam = null;
try {
  const idFile = [path.join(process.cwd(), 'steam_appid.txt'), path.join(path.dirname(process.execPath), 'steam_appid.txt'), path.join(__dirname, '..', 'steam_appid.txt')]
    .find(f => fs.existsSync(f));
  const appId = idFile ? parseInt(fs.readFileSync(idFile, 'utf8'), 10) : undefined;
  const steamworks = require('steamworks.js');
  steam = steamworks.init(appId);
  steamworks.electronEnableSteamOverlay();
  console.log('Steam: ok, user', steam.localplayer.getName());
} catch (e) {
  console.log('Steam: not available —', e.message);
}

let win;
function create() {
  Menu.setApplicationMenu(null);
  win = new BrowserWindow({
    width: 1280, height: 800, minWidth: 960, minHeight: 600,
    backgroundColor: '#05040a',
    fullscreen: !process.argv.includes('--windowed'),
    title: 'Северный маяк',
    webPreferences: { preload: path.join(__dirname, 'preload.js'), contextIsolation: true, nodeIntegration: false, backgroundThrottling: false }
  });
  win.loadFile(path.join(__dirname, '..', 'game', 'index.html'));
  // внешние ссылки не открываем
  win.webContents.setWindowOpenHandler(() => ({ action: 'deny' }));
  win.webContents.on('will-navigate', e => e.preventDefault());
  // --smoke: проверка сборки — загрузиться, сделать снимок экрана и выйти
  if (process.argv.includes('--smoke')) {
    win.webContents.on('console-message', (_e, level, msg) => console.log('page:', msg));
    win.webContents.once('did-finish-load', () => setTimeout(async () => {
      const ok = await win.webContents.executeJavaScript('!!(window.native && window.native.available && window.SM)');
      const img = await win.webContents.capturePage();
      fs.writeFileSync(path.join(app.getPath('temp'), 'severny-mayak-smoke.png'), img.toPNG());
      console.log('SMOKE', ok ? 'OK' : 'FAIL');
      app.exit(ok ? 0 : 1);
    }, 2500));
  }
}

ipcMain.on('achieve', (_e, id) => {
  try { if (steam && !steam.achievement.isActivated(id)) steam.achievement.activate(id); } catch (err) { console.log('achievement', id, err.message); }
});
ipcMain.on('quit', () => app.quit());
ipcMain.on('fullscreen', (_e, on) => { if (win) win.setFullScreen(!!on); });
ipcMain.on('isFullscreen', e => { e.returnValue = !!(win && win.isFullScreen()); });

app.whenReady().then(create);
app.on('window-all-closed', () => app.quit());
