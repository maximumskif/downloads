# Convenience wrappers so you can run Ubuntu tools FROM PowerShell without
# staying inside an interactive Ubuntu shell.
#
# Dot-source once per PowerShell session:
#   . .\scripts\wsl-bridge.ps1
#
# Then:
#   Invoke-Ubuntu "forge --version"
#   Invoke-Ubuntu "npm -v"
#   Forge --version
#   Node -v

function Get-UbuntuDistro {
  $distros = @(wsl -l -q) | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ -ne "" }
  $name = $distros | Where-Object { $_ -match '^Ubuntu' } | Select-Object -First 1
  if (-not $name) { throw "No Ubuntu WSL distro found. Run: wsl --install -d Ubuntu" }
  return $name
}

function Invoke-Ubuntu {
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command
  )
  $distro = Get-UbuntuDistro
  wsl -d $distro -- bash -lc "source `$HOME/.toolchain-path.sh 2>/dev/null || true; $Command"
}

function Forge { Invoke-Ubuntu ("forge " + ($args -join " ")) }
function Cast  { Invoke-Ubuntu ("cast "  + ($args -join " ")) }
function Anvil { Invoke-Ubuntu ("anvil " + ($args -join " ")) }
function Node  { Invoke-Ubuntu ("node "  + ($args -join " ")) }
function Npm   { Invoke-Ubuntu ("npm "   + ($args -join " ")) }
function Npx   { Invoke-Ubuntu ("npx "   + ($args -join " ")) }
function Hardhat { Invoke-Ubuntu ("hardhat " + ($args -join " ")) }

Write-Host "WSL bridge loaded. Examples:" -ForegroundColor Green
Write-Host "  Invoke-Ubuntu 'forge --version'"
Write-Host "  Forge --version"
Write-Host "  Npm -v"
