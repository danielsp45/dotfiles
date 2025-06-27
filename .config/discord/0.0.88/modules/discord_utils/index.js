const util = require('util');
const childProcess = require('child_process');
const execFile = util.promisify(childProcess.execFile);
const readline = require('node:readline');
const EventEmitter = require('node:events');
const fs = require('fs');
const path = require('path');
const {inputCaptureSetWatcher, inputCaptureRegisterElement} = require('./input_capture');
const {wrapInputEventRegister, wrapInputEventUnregister} = require('./input_event');
const {getDoNotDisturb, getSessionState} = require('macos-notification-state');
const {getNotificationState} = require('windows-notification-state');
const {getIsQuietHours} = require('windows-quiet-hours');

/* eslint-disable no-console */

module.exports = require('./discord_utils.node');
module.exports.clearCandidateGamesCallback = module.exports.setCandidateGamesCallback;

inputCaptureSetWatcher(module.exports.inputWatchAll);
delete module.exports.inputWatchAll;
module.exports.inputCaptureRegisterElement = inputCaptureRegisterElement;

module.exports.inputEventRegister = wrapInputEventRegister(module.exports.inputEventRegister);
module.exports.inputEventUnregister = wrapInputEventUnregister(module.exports.inputEventUnregister);

const isElectronRenderer = window?.DiscordNative?.isRenderer;
let dataDirectory;
if (isElectronRenderer) {
  try {
    dataDirectory = window.DiscordNative.fileManager.getModuleDataPathSync
      ? path.join(window.DiscordNative.fileManager.getModuleDataPathSync(), 'discord_utils')
      : null;
  } catch (e) {
    console.error('Failed to get data directory: ', e);
  }
  if (dataDirectory != null) {
    try {
      fs.mkdirSync(dataDirectory, {recursive: true});
    } catch (e) {
      console.warn('Could not create utils data directory ', dataDirectory, ':', e);
    }
  }
}

// Init logging
const isFileManagerAvailable = window?.DiscordNative?.fileManager;
const isLogDirAvailable = isFileManagerAvailable?.getAndCreateLogDirectorySync;
if (isLogDirAvailable) {
  const logDirectory = window.DiscordNative.fileManager.getAndCreateLogDirectorySync();
  const logLevel = window.DiscordNative.fileManager.logLevelSync();
  module.exports.init({logDirectory: logDirectory, logLevel: logLevel});
} else {
  console.warn('Unable to find log directory');
  module.exports.init();
}

function parseNvidiaSmiOutput(result) {
  if (!result || !result.stdout) {
    return {error: 'nvidia-smi produced no output'};
  }

  const match = result.stdout.match(/Driver Version: (\d+)\.(\d+)/);

  if (match.length === 3) {
    return {major: parseInt(match[1], 10), minor: parseInt(match[2], 10)};
  } else {
    return {error: 'failed to parse nvidia-smi output'};
  }
}

module.exports.getGPUDriverVersions = async () => {
  if (process.platform !== 'win32') {
    return {};
  }

  const result = {};
  const nvidiaSmiPath = `"${process.env['SystemRoot']}/System32/nvidia-smi.exe"`;

  try {
    result.nvidia = parseNvidiaSmiOutput(await execFile(nvidiaSmiPath, {windowsHide: true}));
  } catch (e) {
    result.nvidia = {error: e.toString()};
  }

  return result;
};

function warpCliPaths() {
  if (process.platform === 'darwin') {
    return ['/usr/local/bin/warp-cli'];
  } else if (process.platform === 'win32') {
    const programFiles = process.env['ProgramFiles'];
    if (programFiles == null) {
      return [];
    } else {
      return [programFiles + '\\Cloudflare\\Cloudflare WARP\\warp-cli.exe'];
    }
  } else {
    return ['/usr/bin/warp-cli', '/usr/local/bin/warp-cli'];
  }
}

let warpCliPath = undefined;

function findWarpCli() {
  if (warpCliPath == null) {
    for (const p of warpCliPaths()) {
      try {
        fs.accessSync(p, fs.constants.R_OK | fs.constants.X_OK);
        warpCliPath = p;
        break;
      } catch {}
    }
  }

  if (warpCliPath == null) {
    throw new Error('Failed to locate warp-cli');
  }

  return warpCliPath;
}

module.exports.runWarpCommand = async (command) => {
  const warpCliPath = findWarpCli();

  const allowedCommands = {
    connect: [],
    disconnect: [],
    status: [],
  };

  if (!Object.hasOwn(allowedCommands, command)) {
    throw new Error('Illegal command');
  }

  const args = ['-j', '--accept-tos', command];

  const subprocess = await execFile(warpCliPath, args, {windowsHide: true});
  if (subprocess?.stdout == null) {
    throw new Error('Got no stdout');
  }
  return JSON.parse(subprocess.stdout);
};

let warpListenerSubprocess;
const warpEventEmitter = new EventEmitter();
let warpEmitterStartTime = performance.now();

function startWarpListener() {
  if (warpListenerSubprocess != null) {
    return;
  }

  const now = performance.now();
  if (warpEmitterStartTime != null && warpEmitterStartTime > now - 10 * 1000) {
    // Don't just relaunch in a loop
    return;
  }
  warpEmitterStartTime = now;

  const warpCliPath = findWarpCli();

  warpListenerSubprocess = childProcess.spawn(warpCliPath, ['-j', '-l', '--accept-tos', 'status'], {
    windowsHide: true,
    stdio: ['ignore', 'pipe', 'ignore'],
  });
  warpListenerSubprocess.on('exit', () => {
    warpListenerSubprocess = null;
    startWarpListener();
  });
  const rl = readline.createInterface({
    input: warpListenerSubprocess.stdout,
    crlfDelay: Infinity,
  });
  rl.on('line', (line) => {
    try {
      warpEventEmitter.emit('update', JSON.parse(line));
    } catch {}
  });
}

module.exports.onWarpEvent = (func) => {
  startWarpListener();
  warpEventEmitter.on('update', func);
};

module.exports.submitLiveCrashReport = async (channel, sentryMetadata) => {
  console.log('submitLiveCrashReport: submitting...');

  const path = module.exports._generateLiveMinidump(dataDirectory);
  if (!path) {
    console.log('submitLiveCrashReport: minidump not created.');
    return null;
  }

  try {
    const fileData = await fs.promises.readFile(path);
    const blob = new Blob([fileData], {type: 'text/plain'});

    const formData = new FormData();
    formData.append('upload_file_minidump', blob, 'live_minidump.dmp');
    formData.append('channel', channel);
    formData.append('sentry', JSON.stringify(sentryMetadata));

    const sentryEndPoint = 'https://sentry.io/api/146342/minidump/?sentry_key=f11e8c3e62cb46b5a006c339b2086ba3';
    const response = await fetch(sentryEndPoint, {
      method: 'POST',
      body: formData,
    });

    console.log('submitLiveCrashReport: completed.', response);
  } catch (e) {
    console.error('submitLiveCrashReport: error', e);
  }
};

module.exports.shouldDisplayNotifications = () => {
  let dnd = false;
  let shouldDisplay = true;
  if (process.platform === 'darwin') {
    dnd = getDoNotDisturb();
    shouldDisplay = getSessionState() === 'SESSION_ON_CONSOLE_KEY';
  }

  if (process.platform === 'win32') {
    dnd = getIsQuietHours();
    const state = getNotificationState();
    shouldDisplay = state === 'QUNS_ACCEPTS_NOTIFICATIONS' || state === 'QUNS_APP';
  }

  return !dnd && shouldDisplay;
};
