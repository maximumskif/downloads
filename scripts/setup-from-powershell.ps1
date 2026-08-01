# Run this in Windows PowerShell on YOUR computer (I cannot open it remotely).
# 1) Ensures WSL + Ubuntu are available
# 2) Clones/updates this repo inside Ubuntu
# 3) Installs Rust, Node/npm, Foundry, Hardhat, Python web3/trading tools
# 4) Verifies everything, then drops you into an Ubuntu login shell
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\scripts\setup-from-powershell.ps1

$ErrorActionPreference = "Stop"
$RepoHttps = "https://github.com/maximumskif/downloads.git"
$RepoDir = "downloads"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ARTB / Smart-contract toolchain setup" -ForegroundColor Cyan
Write-Host "  PowerShell  ->  WSL Ubuntu" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

function Assert-Wsl {
  $wslCmd = Get-Command wsl -ErrorAction SilentlyContinue
  if (-not $wslCmd) {
    Write-Host "WSL not found. Installing Ubuntu (reboot may be required)..." -ForegroundColor Yellow
    wsl --install -d Ubuntu
    Write-Host "Reboot Windows if prompted, open PowerShell again, then re-run this script." -ForegroundColor Yellow
    exit 1
  }
}

Assert-Wsl

Write-Host "==> WSL status"
try { wsl --status } catch { Write-Host "(status unavailable, continuing)" }
Write-Host ""
Write-Host "==> Installed Linux distros"
wsl -l -v
Write-Host ""

$distros = @(wsl -l -q) | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ -ne "" }
$ubuntuName = $distros | Where-Object { $_ -match '^Ubuntu' } | Select-Object -First 1

if (-not $ubuntuName) {
  Write-Host "Ubuntu distro not found. Installing..." -ForegroundColor Yellow
  wsl --install -d Ubuntu
  Write-Host ""
  Write-Host "Finish the Ubuntu first-run username/password window, then re-run this script." -ForegroundColor Yellow
  exit 1
}

Write-Host "==> Using distro: $ubuntuName" -ForegroundColor Green
Write-Host "==> Installing toolchain inside Ubuntu (this can take several minutes)..." -ForegroundColor Green
Write-Host ""

# Non-interactive bootstrap inside Ubuntu, then verify.
# Uses login shell so nvm/cargo/foundry PATH files are sourced.
$bootstrap = @"
set -euo pipefail
cd `$HOME
if [ ! -d '$RepoDir/.git' ]; then
  git clone '$RepoHttps' '$RepoDir'
else
  cd '$RepoDir' && git pull --ff-only || true
  cd `$HOME
fi
cd `$HOME/$RepoDir
chmod +x scripts/*.sh .cursor/install.sh 2>/dev/null || true
bash .cursor/install.sh
bash scripts/verify-toolchain.sh
echo
echo 'LOGIN READY. Tools are on PATH in this Ubuntu shell.'
echo 'From PowerShell later you can also run:'
echo '  wsl -d $ubuntuName'
echo '  wsl -d $ubuntuName -- bash -lc \"forge --version\"'
"@

wsl -d $ubuntuName -- bash -lc $bootstrap
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "Bootstrap failed inside Ubuntu (exit $LASTEXITCODE)." -ForegroundColor Red
  Write-Host "Open Ubuntu manually and paste any errors, or run:" -ForegroundColor Red
  Write-Host "  wsl -d $ubuntuName" -ForegroundColor Yellow
  exit $LASTEXITCODE
}

Write-Host ""
Write-Host "==> Bootstrap OK. Opening Ubuntu login shell now..." -ForegroundColor Green
Write-Host "    Type commands like: forge --version | node -v | python3 -V" -ForegroundColor Green
Write-Host "    Exit Ubuntu with: exit" -ForegroundColor Green
Write-Host ""

# Interactive login for the user
wsl -d $ubuntuName --cd ~
