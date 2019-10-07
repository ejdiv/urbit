/*
  Modules to control application life and create native browser window
*/
const {app, BrowserWindow, ipcMain} = require('electron');

const os = require('os');
const fs = require('fs');

const path = require('path');
const proc = require('child_process');
const root = require('app-root-dir');

////////////////////////////////////////////////////////////////////////////////

const env = { name: 'dev' };

const getPlatform = () => {
  switch(os.platform()) {
    case 'linux':
      return 'linux';
    case 'darwin':
      return 'mac';
    case 'win32':
      return 'win';
  };
};

////////////////////////////////////////////////////////////////////////////////

const shipsDir = path.join(root.get(), 'ships');

const pillPath = (env.name === 'production')
               ? path.join(path.dirname(root.get()), 'solid.pill')
               : path.join(root.get(), 'resources', 'solid.pill');

const execPath = (env.name === 'production')
               ? path.join(path.dirname(root.get()), 'bin')
               : path.join(root.get(), 'resources', getPlatform());

const arvoPath = (env.name === 'production')
               ? path.join(path.dirname(root.get()), 'arvo')
               : path.join(root.get(), 'resources', 'arvo');

const urbitExe = `${path.join(execPath, 'urbit')}`;

console.log(arvoPath);
console.log(pillPath);
console.log(urbitExe);

////////////////////////////////////////////////////////////////////////////////

ipcMain.on('ship-list', (event, arg) => {
  try { fs.mkdirSync(shipsDir); } catch(e) {}
  const ships = fs.readdirSync(shipsDir);
  console.log("ships", ships);
  event.returnValue = ships;
})

const checkShipExists = (ship, cb) => {
  const pax = path.join(shipsDir, ship);
  cb (fs.existsSync(path));
};

const readPorts = (ship, cb) => {
  const pax = path.join(shipsDir, ship, '.http.ports');

  fs.readFile(pax, {encoding: 'utf-8'}, function(err,data){
    if (!!err) {
      console.log(err);
      throw err;
    }

    console.log('== PORTS FILE ==');
    console.log(data);

    const ports = data.split(/\r\n|\n|\r/);

    var ins = null;
    var lop = null;
    var sec = null;

    ports.forEach(x => {
      if (x.match(/insecure loopback/)) {
        lop = Number(x.split(/ /)[0]);
      }
      else if (x.match(/insecure public/)) {
        ins = Number(x.split(/ /)[0]);
      }
      else if (x.match(/secure public/)) {
        sec = Number(x.split(/ /)[0]);
      }
    });

    cb({ins, lop, ins});
  });
};

const runShip = (ship, cb) => {
  const pier = path.join(shipsDir, ship);
  const args = ['-d', pier];

  console.log(urbitExe, args);

  const child = proc.spawn(urbitExe, args, {stdio: 'inherit'});

  child.on('exit', () => {
    console.log("Ship started");
    readPorts(ship, (ports) => cb(ship, ports));
  });
}

const bootShip = (ship, cb) => {
  const pier = path.join(shipsDir, ship);
  const args = ['-F', ship, '-d', '-B', pillPath, '-c', pier];

  console.log(urbitExe, args)

  const child = proc.spawn(urbitExe, args, {stdio: 'inherit'});

  child.on('exit', () => {
    console.log("Ship booted");
    readPorts(ship, (ports) => cb(ship, ports));
  });
}

////////////////////////////////////////////////////////////////////////////////

// In main process.
ipcMain.on('renderer-started', (event, arg) => {
  console.log(["renderer-started", arg]);
});

ipcMain.on('start-ship', (event, ship) => {
  console.log('start-ship', ship);

  runShip(ship, (ship, ports) => {
    const port = ports.ins;
    const url = `http://localhost:${port}`;
    createUrbitWindow(url)
    event.reply('ship-running', ship, ports);
  });
});

ipcMain.on('boot-ship', (event, ship) => {
  console.log('boot-ship', ship);

  bootShip(ship, (ship, ports) => {
    const port = ports.ins;
    const url = `http://localhost:${port}`;
    createUrbitWindow(url)
    event.reply('ship-running', ship, ports);
  });
});

// event.reply('asynchronous-reply', 'pong')

  // event.reply('urbit-started', 42283);

/*
  Keep a global reference of the window object, if you don't, the window will
  be closed automatically when the JavaScript object is garbage collected.
*/
let mainWindow

/*
  - Create the browser window.
  - Load the index.html of the app.
  - Open the DevTools.

  - When window.closed is emitted:

    Dereference the window object, usually you would store windows in
    an array if your app supports multi windows, this is the time when
    you should delete the corresponding element.
*/
const createUrbitWindow = (url) => {
  urbWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
      // preload: path.join(__dirname, 'preload.js'),
    }
  });

  urbWindow.loadURL(url);

  urbWindow.on('closed', () => {
    urbWindow = null;
  });
};

const createWindow = () => {
  mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
      preload: path.join(__dirname, 'preload.js'),
    }
  });

  mainWindow.loadFile('index.html');

  mainWindow.webContents.openDevTools();

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
};

/*
  This method will be called when Electron has finished initialization
  and is ready to create browser windows.  Some APIs can only be used
  after this event occurs.
*/
app.on('ready', createWindow);

/*
  Quit when all windows are closed.

  On macOS it is common for applications and their menu bar to stay
  active until the user quits explicitly with Cmd + Q
*/
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
})

/*
  On macOS it's common to re-create a window in the app when the dock
  icon is clicked and there are no other windows open.
*/
app.on('activate', () => {
  if (mainWindow === null) createWindow();
})

/*
  In this file you can include the rest of your app's specific main
  process code. You can also put them in separate files and require
  them here.
*/
console.log("APP LOGIC HERE");