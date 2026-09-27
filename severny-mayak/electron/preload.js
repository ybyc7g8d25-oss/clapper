// Мост между игрой и Electron: игра вызывает window.native.* (см. game/js/core.js).
const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('native', {
  available: true,
  achieve: id => ipcRenderer.send('achieve', id),
  quit: () => ipcRenderer.send('quit'),
  setFullscreen: on => ipcRenderer.send('fullscreen', on),
  isFullscreen: () => ipcRenderer.sendSync('isFullscreen')
});
