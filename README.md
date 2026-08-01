# downloads

Portable toolchain for **smart contracts** and **ARTB trading**.

Works in:
- your local **Windows PowerShell → WSL Ubuntu**
- **Cursor Cloud Agents** (via `.cursor/environment.json`)

> A **Cloud Agent cannot use your local PowerShell** until a **My Machines worker** is running on your PC (or you use Cursor Desktop local agent). Unblocking scripts ≠ connecting this cloud session.

## 1) Ensure WSL + Ubuntu on your PC (recommended)

Open **Windows PowerShell as Administrator** and paste:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
cd $HOME
if (-not (Test-Path .\downloads\.git)) { git clone https://github.com/maximumskif/downloads.git downloads }
cd .\downloads
git fetch origin
git checkout cursor/smart-contract-env-setup-6634
powershell -ExecutionPolicy Bypass -File .\scripts\ensure-wsl-ubuntu.ps1
```

That script will:
1. unblock scripts
2. update WSL, install Ubuntu if needed, set it as default
3. enable systemd
4. install Rust / Node / Foundry / Hardhat / Python trading deps inside Ubuntu
5. verify from Windows via `wsl`

### Quick login only (after install)

```powershell
wsl
```

### Let Cloud Agents run commands on your PC

Keep this running in PowerShell:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
agent login
agent worker start --name "my-windows-pc"
```

Then start a **new** Cloud Agent and choose environment **my-windows-pc**.

## 2) Run Ubuntu tools from PowerShell

```powershell
. .\scripts\wsl-bridge.ps1
Forge --version
Npm -v
Invoke-Ubuntu "python3 -c `"import web3,ccxt; print('ok')`""
```

## What gets installed

| Tool | Purpose |
|------|---------|
| Rust (`rustc` / `cargo`) | Foundry & Rust tooling |
| Python 3 + `web3`, `ccxt`, `pandas` | Trading bots / chain scripts |
| Node.js + `npm` / `yarn` / `pnpm` | Hardhat & JS tooling |
| Foundry (`forge` / `cast` / `anvil`) | Solidity compile, test, local chain |
| Hardhat + OpenZeppelin + `solc` | Alternative Solidity stack |

## PATH (inside Ubuntu)

```text
$HOME/.cargo/bin          # rustc, cargo
$HOME/.foundry/bin        # forge, cast, anvil
$HOME/.nvm/.../bin        # node, npm, npx, hardhat
$HOME/.venvs/artb-trading # python/pip packages
$HOME/.toolchain-path.sh  # sourced by ~/.bashrc
```

## Future Cursor agents

`.cursor/environment.json` runs `.cursor/install.sh` on agent boot so new agents get the same toolchain after this branch is merged (or when agents start from this branch).
