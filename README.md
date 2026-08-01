# downloads

Portable toolchain for **smart contracts** and **ARTB trading**.

Works in:
- your local **Windows PowerShell → WSL Ubuntu**
- **Cursor Cloud Agents** (via `.cursor/environment.json`)

> This cloud agent **cannot open PowerShell on your PC**. You run the login commands locally.

## 1) Open PowerShell on your computer

Press `Win`, type **PowerShell**, open **Windows PowerShell**.

## 2) One-command login + full install

If you already cloned this repo on Windows:

```powershell
cd path\to\downloads
powershell -ExecutionPolicy Bypass -File .\scripts\setup-from-powershell.ps1
```

That script will:
1. confirm WSL + Ubuntu
2. clone/update this repo inside Ubuntu
3. install Rust, Node/npm, Foundry, Hardhat, Python web3/trading packages
4. verify them
5. drop you into an Ubuntu login shell

### First-time only (if Ubuntu/WSL missing)

```powershell
wsl --install -d Ubuntu
```

Reboot if Windows asks. Finish the Ubuntu username/password setup, then re-run `setup-from-powershell.ps1`.

### Quick login only (after install)

```powershell
wsl -d Ubuntu
```

or:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\enter-ubuntu.ps1
```

## 3) Run Ubuntu tools from PowerShell

After install, either stay inside Ubuntu, or load the bridge:

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
$HOME/.local/bin          # pip --user scripts
$HOME/.toolchain-path.sh  # sourced by ~/.bashrc
```

## Future Cursor agents

`.cursor/environment.json` runs `.cursor/install.sh` on agent boot so new agents get the same toolchain after this branch is merged (or when agents start from this branch).
