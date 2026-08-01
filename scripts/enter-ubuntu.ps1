# Run this in Windows PowerShell (Admin recommended for first-time WSL install).
# After a PC reset, this gets you into Ubuntu and (optionally) bootstraps the toolchain.

$ErrorActionPreference = "Stop"

Write-Host "==> Checking WSL status..."
wsl --status 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "WSL not ready. Installing Ubuntu (reboot may be required)..."
  wsl --install -d Ubuntu
  Write-Host "If this is the first install, reboot Windows, then re-run this script."
  exit 0
}

Write-Host "==> Installed distros:"
wsl -l -v

$distro = "Ubuntu"
$hasUbuntu = (wsl -l -q) -match "Ubuntu"
if (-not $hasUbuntu) {
  Write-Host "Ubuntu not found. Installing..."
  wsl --install -d Ubuntu
  Write-Host "Finish Ubuntu first-run user setup, then re-run this script."
  exit 0
}

Write-Host ""
Write-Host "Signing into Ubuntu..."
Write-Host "Inside Ubuntu, clone this repo (or cd into it) and run:"
Write-Host "  bash scripts/wsl-bootstrap.sh"
Write-Host "  bash scripts/verify-toolchain.sh"
Write-Host ""

# Drop into an interactive Ubuntu shell
wsl -d $distro --cd ~
