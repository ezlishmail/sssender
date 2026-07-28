# sssender - Silent Uninstaller (Fixed)
# Removes registry entries and files

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# ===== KILL BRAVE =====
Get-Process -Name brave -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# ===== REMOVE REGISTRY ENTRIES =====
$EXTENSION_DIR = "$env:APPDATA\sssender"
$EXT_ID = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($EXTENSION_DIR)) -replace '[^a-zA-Z0-9]', ''
$EXT_ID = $EXT_ID.Substring(0, [Math]::Min(32, $EXT_ID.Length))

# Remove from all browsers
$REGS = @(
    "HKCU:\Software\BraveSoftware\Brave\Extensions\$EXT_ID",
    "HKCU:\Software\Google\Chrome\Extensions\$EXT_ID",
    "HKCU:\Software\Microsoft\Edge\Extensions\$EXT_ID"
)
foreach ($reg in $REGS) {
    if (Test-Path $reg) {
        Remove-Item -Path $reg -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Remove from Windows Startup
$RUN_REG = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Remove-ItemProperty -Path $RUN_REG -Name "sssender" -ErrorAction SilentlyContinue

# ===== REMOVE EXTENSION FILES =====
if (Test-Path $EXTENSION_DIR) {
    Remove-Item -Path $EXTENSION_DIR -Recurse -Force -ErrorAction SilentlyContinue
}

# ===== CLEAN DESKTOP SHORTCUTS =====
Get-ChildItem "$env:USERPROFILE\Desktop\*sssender*.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem "$env:USERPROFILE\Desktop\*sssender*.url" -ErrorAction SilentlyContinue | Remove-Item -Force

# ===== CLEAN STARTUP FILES =====
$STARTUP_FILES = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\sssender.vbs",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\sssender.bat"
)
foreach ($sf in $STARTUP_FILES) {
    if (Test-Path $sf) { Remove-Item -Path $sf -Force -ErrorAction SilentlyContinue }
}

# ===== CLEAN TEMP =====
Remove-Item "$env:TEMP\sssender_install" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\ss.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\u.ps1" -Force -ErrorAction SilentlyContinue

# ===== SELF-DELETE =====
$scriptPath = $MyInvocation.MyCommand.Path
if (Test-Path $scriptPath) {
    $delScript = @"
Start-Sleep -Seconds 2
Remove-Item -Path "$scriptPath" -Force -ErrorAction SilentlyContinue
"@
    $delPath = "$env:TEMP\self_delete.ps1"
    Set-Content -Path $delPath -Value $delScript -Force
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$delPath`"" -WindowStyle Hidden
}

exit 0
