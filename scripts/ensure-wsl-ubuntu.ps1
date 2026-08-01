# Comprehensive WSL + Ubuntu setup for lasting local use.
# Run in Windows PowerShell (Admin recommended for feature install):
#   powershell -ExecutionPolicy Bypass -File .\scripts\ensure-wsl-ubuntu.ps1
#
# What this does:
#  1) Unblocks PowerShell scripts for CurrentUser
#  2) Enables WSL + VirtualMachinePlatform if needed
#  3) Installs/updates WSL and Ubuntu
#  4) Sets Ubuntu as default distro
#  5) Enables systemd in Ubuntu
#  6) Installs smart-contract / trading toolchain inside Ubuntu
#  7) Verifies tools

$ErrorActionPreference = "Stop"
$RepoHttps = "https://github.com/maximumskif/downloads.git"
$RepoDir = "downloads"

function Write-Step($msg) {
  Write-Host ""
  Write-Host "==> $msg" -ForegroundColor Cyan
}

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  Ensure WSL + Ubuntu (system-wide readiness)" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green

Write-Step "Unblock PowerShell scripts (CurrentUser)"
try {
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
} catch {
  Write-Host "Could not set CurrentUser policy: $($_.Exception.Message)" -ForegroundColor Yellow
  Write-Host "Continuing with process-scoped Bypass..." -ForegroundColor Yellow
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}
Get-ExecutionPolicy -List | Format-Table -AutoSize

Write-Step "Check WSL command"
$wslCmd = Get-Command wsl -ErrorAction SilentlyContinue
if (-not $wslCmd) {
  Write-Step "WSL not found — installing (may require reboot)"
  if (-not (Test-IsAdmin)) {
    Write-Host "Open PowerShell as Administrator and re-run this script." -ForegroundColor Red
    Write-Host "Or run:  wsl --install -d Ubuntu" -ForegroundColor Yellow
    exit 1
  }
  wsl --install -d Ubuntu
  Write-Host ""
  Write-Host "If Windows asked for a reboot: reboot, finish Ubuntu user setup, then re-run this script." -ForegroundColor Yellow
  exit 0
}

Write-Step "Update WSL kernel/platform"
try { wsl --update } catch { Write-Host "wsl --update skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
try { wsl --set-default-version 2 } catch { Write-Host "default version 2 skipped: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Step "Installed distros"
wsl -l -v

$distrosRaw = @(wsl -l -q)
$distros = $distrosRaw | ForEach-Object {
  # wsl -l can emit UTF-16-ish junk; normalize
  ($_ -replace "`0", "").Trim()
} | Where-Object { $_ -ne "" }

$ubuntuName = $distros | Where-Object { $_ -match '^Ubuntu' } | Select-Object -First 1

if (-not $ubuntuName) {
  Write-Step "Ubuntu missing — installing"
  wsl --install -d Ubuntu
  Write-Host ""
  Write-Host "Complete Ubuntu first-run username/password, then re-run this script." -ForegroundColor Yellow
  exit 0
}

Write-Step "Set default distro to $ubuntuName"
wsl --set-default $ubuntuName

Write-Step "Enable systemd in Ubuntu (better service support)"
$systemdConf = @"
[boot]
systemd=true
"@
# Write wsl.conf inside Ubuntu
wsl -d $ubuntuName -- bash -lc "echo '$systemdConf' | sudo tee /etc/wsl.conf >/dev/null"
Write-Host "Restarting WSL to apply systemd..."
wsl --shutdown
Start-Sleep -Seconds 3

Write-Step "Smoke-test Ubuntu login"
wsl -d $ubuntuName -- bash -lc "echo UNAME=\$(uname -a); echo USER=\$USER; echo HOME=\$HOME"

Write-Step "Install / refresh toolchain inside Ubuntu"
$bootstrap = @"
set -euo pipefail
sudo apt-get update -y
sudo apt-get install -y git curl ca-certificates
cd \$HOME
if [ ! -d '$RepoDir/.git' ]; then
  git clone '$RepoHttps' '$RepoDir'
else
  cd '$RepoDir'
  git fetch origin || true
  git checkout cursor/smart-contract-env-setup-6634 2>/dev/null || git checkout main || true
  git pull --ff-only || true
  cd \$HOME
fi
cd \$HOME/$RepoDir
chmod +x scripts/*.sh .cursor/install.sh 2>/dev/null || true
bash .cursor/install.sh
bash scripts/verify-toolchain.sh
"@

wsl -d $ubuntuName -- bash -lc $bootstrap
if ($LASTEXITCODE -ne 0) {
  Write-Host "Ubuntu toolchain bootstrap failed (exit $LASTEXITCODE)." -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Step "Final Windows-side checks"
Write-Host "Default distro / versions:"
wsl -l -v
Write-Host ""
Write-Host "Tool versions via WSL:"
wsl -d $ubuntuName -- bash -lc "source \$HOME/.toolchain-path.sh 2>/dev/null || true; rustc --version; node -v; npm -v; forge --version | head -1; python3 -c 'import web3,ccxt,pandas; print(\"python-ok\", web3.__version__)'"

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  READY" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host "Daily login:" -ForegroundColor Cyan
Write-Host "  wsl"
Write-Host "  wsl -d $ubuntuName"
Write-Host ""
Write-Host "Run one Ubuntu command from PowerShell:" -ForegroundColor Cyan
Write-Host "  wsl -d $ubuntuName -- bash -lc `"forge --version`""
Write-Host ""
Write-Host "Optional: load PowerShell wrappers from this repo:" -ForegroundColor Cyan
Write-Host "  . .\scripts\wsl-bridge.ps1"
Write-Host ""
