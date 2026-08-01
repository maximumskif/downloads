# COMPLETE Cursor <-> Windows PC setup
# Goal: Cursor can consistently run commands, downloads, and tooling on THIS computer
#       via PowerShell + WSL Ubuntu.
#
# Run in Windows PowerShell AS ADMINISTRATOR:
#   powershell -ExecutionPolicy Bypass -File .\scripts\complete-cursor-pc-setup.ps1
#
# After this finishes, pick ONE daily mode:
#   A) Cursor Desktop -> Agent -> "This Computer"   (simplest full PC control)
#   B) Keep `agent worker start` running, then Cloud Agent -> environment "my-windows-pc"

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
  Write-Host ""
  Write-Host "==== $msg ====" -ForegroundColor Cyan
}

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "  COMPLETE Cursor PC control setup" -ForegroundColor Green
Write-Host "  PowerShell + WSL Ubuntu + Cursor worker" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green

if (-not (Test-IsAdmin)) {
  Write-Host "Re-open PowerShell as Administrator, then re-run this script." -ForegroundColor Red
  exit 1
}

# -------------------------------------------------------
# 1) PowerShell always allowed to run scripts
# -------------------------------------------------------
Write-Step "1/7 PowerShell execution policy"
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Get-ExecutionPolicy -List | Format-Table -AutoSize

# Persist a tiny profile helper so future PowerShell sessions are usable
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
$profileSnippet = @'
# Cursor / WSL helpers
function Enter-Ubuntu { wsl -d Ubuntu }
function Invoke-Ubuntu { param([Parameter(Mandatory=$true)][string]$Command) wsl -d Ubuntu -- bash -lc "source `$HOME/.toolchain-path.sh 2>/dev/null || true; $Command" }
Set-Alias ubu Enter-Ubuntu -ErrorAction SilentlyContinue
'@
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
$existing = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if ($existing -notmatch 'function Enter-Ubuntu') {
  Add-Content -Path $PROFILE -Value "`n$profileSnippet`n"
  Write-Host "Added Enter-Ubuntu / Invoke-Ubuntu helpers to $PROFILE"
} else {
  Write-Host "Profile helpers already present: $PROFILE"
}

# -------------------------------------------------------
# 2) WSL + Ubuntu installed, default, systemd on
# -------------------------------------------------------
Write-Step "2/7 WSL + Ubuntu"
$wslCmd = Get-Command wsl -ErrorAction SilentlyContinue
if (-not $wslCmd) {
  Write-Host "Installing WSL + Ubuntu (reboot may be required)..."
  wsl --install -d Ubuntu
  Write-Host "REBOOT Windows if prompted, finish Ubuntu username/password, then re-run this script." -ForegroundColor Yellow
  exit 0
}

try { wsl --update } catch { Write-Host "wsl --update: $($_.Exception.Message)" -ForegroundColor Yellow }
try { wsl --set-default-version 2 } catch { Write-Host "set-default-version: $($_.Exception.Message)" -ForegroundColor Yellow }

$distros = @(wsl -l -q) | ForEach-Object { ($_ -replace "`0","").Trim() } | Where-Object { $_ -ne "" }
$ubuntuName = $distros | Where-Object { $_ -match '^Ubuntu' } | Select-Object -First 1
if (-not $ubuntuName) {
  wsl --install -d Ubuntu
  Write-Host "Finish Ubuntu first-run setup, then re-run this script." -ForegroundColor Yellow
  exit 0
}

wsl --set-default $ubuntuName
wsl -d $ubuntuName -- bash -lc "printf '%s\n' '[boot]' 'systemd=true' | sudo tee /etc/wsl.conf >/dev/null"
wsl --shutdown
Start-Sleep -Seconds 3
Write-Host "Using distro: $ubuntuName"
wsl -l -v

# -------------------------------------------------------
# 3) Clone / update this repo on Windows AND Ubuntu
# -------------------------------------------------------
Write-Step "3/7 Clone downloads repo (Windows + Ubuntu)"
$winRepo = Join-Path $HOME "downloads"
if (-not (Test-Path (Join-Path $winRepo ".git"))) {
  if (Get-Command git -ErrorAction SilentlyContinue) {
    git clone https://github.com/maximumskif/downloads.git $winRepo
  } else {
    Write-Host "git not found on Windows — installing Git via winget..."
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    git clone https://github.com/maximumskif/downloads.git $winRepo
  }
} else {
  Push-Location $winRepo
  git fetch origin
  git checkout cursor/smart-contract-env-setup-6634 2>$null
  if ($LASTEXITCODE -ne 0) { git checkout main }
  git pull --ff-only
  Pop-Location
}

wsl -d $ubuntuName -- bash -lc @'
set -euo pipefail
cd "$HOME"
if [ ! -d downloads/.git ]; then
  git clone https://github.com/maximumskif/downloads.git downloads
else
  cd downloads
  git fetch origin || true
  git checkout cursor/smart-contract-env-setup-6634 2>/dev/null || git checkout main || true
  git pull --ff-only || true
fi
'@

# -------------------------------------------------------
# 4) Toolchain inside Ubuntu (Rust/Node/Foundry/Python)
# -------------------------------------------------------
Write-Step "4/7 Ubuntu toolchain bootstrap"
wsl -d $ubuntuName -- bash -lc @'
set -euo pipefail
cd "$HOME/downloads"
chmod +x scripts/*.sh .cursor/install.sh 2>/dev/null || true
bash .cursor/install.sh
bash scripts/verify-toolchain.sh
'@
if ($LASTEXITCODE -ne 0) { throw "Ubuntu toolchain bootstrap failed" }

# -------------------------------------------------------
# 5) Cursor CLI (agent) on Windows for My Machines worker
# -------------------------------------------------------
Write-Step "5/7 Cursor agent CLI on Windows"
$agentCmd = Get-Command agent -ErrorAction SilentlyContinue
if (-not $agentCmd) {
  Write-Host "Installing Cursor agent CLI..."
  irm 'https://cursor.com/install?win32=true' | iex
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}
agent --version

Write-Host ""
Write-Host "If not logged in yet, a browser/login prompt will appear." -ForegroundColor Yellow
agent login

# -------------------------------------------------------
# 6) Verify end-to-end command paths
# -------------------------------------------------------
Write-Step "6/7 Verify command paths"
Write-Host "PowerShell -> WSL forge:"
wsl -d $ubuntuName -- bash -lc "source `$HOME/.toolchain-path.sh 2>/dev/null || true; forge --version | head -1; node -v; npm -v; python3 -c 'import web3,ccxt; print(`"pip-ok`")'"

Write-Host ""
Write-Host "Windows repo path: $winRepo"
Write-Host "Ubuntu repo path:  \\wsl$\$ubuntuName\home\<you>\downloads  (or ~/downloads inside wsl)"

# -------------------------------------------------------
# 7) Start persistent worker (keeps Cloud Agents on THIS PC)
# -------------------------------------------------------
Write-Step "7/7 Start My Machines worker (leave this window OPEN)"
Write-Host ""
Write-Host "NEXT — choose how you want Cursor to control this PC:" -ForegroundColor Green
Write-Host ""
Write-Host "MODE A (simplest, recommended for daily work):" -ForegroundColor Cyan
Write-Host "  1. Open Cursor Desktop on Windows"
Write-Host "  2. File -> Open Folder -> $winRepo"
Write-Host "     (or open \\wsl`$\$ubuntuName\home\...)"
Write-Host "  3. Start Agent and select THIS COMPUTER / local (NOT Cloud)"
Write-Host "  4. Agent can then run PowerShell + wsl commands on this PC"
Write-Host ""
Write-Host "MODE B (Cloud Agents UI controlling this PC):" -ForegroundColor Cyan
Write-Host "  1. Keep this PowerShell window open"
Write-Host "  2. Worker will start below as 'my-windows-pc'"
Write-Host "  3. Go to https://cursor.com/agents"
Write-Host "  4. Start a NEW agent and choose environment: my-windows-pc"
Write-Host "  5. That agent runs commands on THIS computer"
Write-Host ""
Write-Host "Starting worker now. Do not close this window." -ForegroundColor Yellow
Write-Host ""

agent worker start --name "my-windows-pc"
