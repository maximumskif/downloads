# Quick login: open Ubuntu from PowerShell.
# For full install, prefer:  .\scripts\setup-from-powershell.ps1

$ErrorActionPreference = "Stop"

Write-Host "==> Checking WSL / Ubuntu..."
$wslCmd = Get-Command wsl -ErrorAction SilentlyContinue
if (-not $wslCmd) {
  Write-Host "WSL missing. Run as Admin:" -ForegroundColor Yellow
  Write-Host "  wsl --install -d Ubuntu"
  exit 1
}

wsl -l -v
$distros = @(wsl -l -q) | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ -ne "" }
$ubuntuName = $distros | Where-Object { $_ -match '^Ubuntu' } | Select-Object -First 1

if (-not $ubuntuName) {
  Write-Host "Ubuntu not installed. Run:" -ForegroundColor Yellow
  Write-Host "  wsl --install -d Ubuntu"
  exit 1
}

Write-Host ""
Write-Host "Signing into $ubuntuName ..." -ForegroundColor Green
Write-Host "After login, if tools are missing run:" -ForegroundColor Cyan
Write-Host "  cd ~/downloads && bash .cursor/install.sh && bash scripts/verify-toolchain.sh"
Write-Host ""

wsl -d $ubuntuName --cd ~
