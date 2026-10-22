const { app, BrowserWindow, shell, nativeTheme } = require("electron");
const path = require("path");

function openExternal(url){
  if (/^https?:\/\//i.test(url)) shell.openExternal(url);
}

function createWindow(){
  const win = new BrowserWindow({
    width: 900,
    height: 820,
    minWidth: 380,
    minHeight: 500,
    title: "RepoHub",
    backgroundColor: nativeTheme.shouldUseDarkColors ? "#15161b" : "#f7f7f5",
    autoHideMenuBar: true,
    webPreferences: {
      contextIsolation: true,
      sandbox: true,
    },
  });

  // Repo links open in the default browser, never inside the app.
  win.webContents.setWindowOpenHandler(({ url }) => {
    openExternal(url);
    return { action: "deny" };
  });
  win.webContents.on("will-navigate", (e, url) => {
    if (url === win.webContents.getURL()) return;
    e.preventDefault();
    openExternal(url);
  });

  win.loadFile(path.join(__dirname, "web", "index.html"));
}

if (!app.requestSingleInstanceLock()){
  app.quit();
} else {
  app.on("second-instance", () => {
    const [win] = BrowserWindow.getAllWindows();
    if (win){
      if (win.isMinimized()) win.restore();
      win.focus();
    }
  });

  app.whenReady().then(() => {
    createWindow();
    app.on("activate", () => {
      if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
  });

  app.on("window-all-closed", () => {
    if (process.platform !== "darwin") app.quit();
  });
}
