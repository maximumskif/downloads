# downloads

Complete Cursor ↔ Windows PC control + smart-contract / ARTB trading toolchain.

## What you want (full use case)

```text
You  →  Cursor  →  THIS computer (PowerShell / files / downloads)
                 →  WSL Ubuntu (Rust, Node, Foundry, Python, builds)
```

There are **two supported modes**. Pick one as your daily path.

| Mode | How Cursor reaches your PC | Best for |
|------|----------------------------|----------|
| **A. Local Agent** | Cursor Desktop → Agent → **This Computer** | Daily coding, full PC control |
| **B. My Machines** | `agent worker start` stays open → Cloud Agent picks **my-windows-pc** | Driving your PC from cursor.com |

A normal Cloud Agent on a remote Ubuntu VM **cannot** use your PowerShell until Mode B is running.

## One-time setup (Admin PowerShell)

Paste this on your Windows PC:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
cd $HOME
if (-not (Test-Path .\downloads\.git)) { git clone https://github.com/maximumskif/downloads.git downloads }
cd .\downloads
git fetch origin
git checkout cursor/smart-contract-env-setup-6634
powershell -ExecutionPolicy Bypass -File .\scripts\complete-cursor-pc-setup.ps1
```

That script will:
1. unblock PowerShell scripts + add `Enter-Ubuntu` helpers to your profile
2. install/update **WSL + Ubuntu**, set default, enable systemd
3. clone this repo on Windows and inside Ubuntu
4. install Rust / Node / Foundry / Hardhat / Python web3+trading deps in Ubuntu
5. install Cursor `agent` CLI and log in
6. verify tools via `wsl`
7. start worker **`my-windows-pc`** (leave that window open for Mode B)

## Daily use

### Mode A — Cursor Desktop (recommended)

1. Open **Cursor** on Windows  
2. **File → Open Folder** → `C:\Users\Max\downloads`  
   (or WSL path `\\wsl$\Ubuntu\home\<you>\downloads`)  
3. Start **Agent** → choose **This Computer / local** (not Cloud)  
4. Ask it to run PowerShell / `wsl` / installs — it runs on your PC  

### Mode B — Cloud Agent on your PC

1. Keep the setup window open (or later run):
   ```powershell
   agent worker start --name "my-windows-pc"
   ```
2. Go to [cursor.com/agents](https://cursor.com/agents)  
3. Start a **new** agent → environment **my-windows-pc**  
4. That agent’s shell is your computer  

### Everyday Ubuntu login from PowerShell

```powershell
wsl
# or after profile helpers load:
Enter-Ubuntu
Invoke-Ubuntu "forge --version"
```

## Toolchain (inside Ubuntu)

| Tool | Purpose |
|------|---------|
| Rust / Cargo | Foundry & Rust builds |
| Node / npm / yarn / pnpm | Hardhat & JS |
| Foundry (`forge`/`cast`/`anvil`) | Solidity |
| Hardhat + OpenZeppelin + solc | Solidity alt stack |
| Python venv `~/.venvs/artb-trading` | `web3`, `ccxt`, `pandas`, … |

Verify anytime:

```powershell
wsl -- bash -lc 'cd ~/downloads && bash scripts/verify-toolchain.sh'
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/complete-cursor-pc-setup.ps1` | **Full PC control setup** (use this) |
| `scripts/ensure-wsl-ubuntu.ps1` | WSL/Ubuntu + toolchain only |
| `scripts/setup-from-powershell.ps1` | Toolchain + Ubuntu login |
| `scripts/enter-ubuntu.ps1` | Quick Ubuntu login |
| `scripts/wsl-bridge.ps1` | `Forge` / `Npm` wrappers from PowerShell |
| `.cursor/install.sh` | Shared install for WSL + Cloud Agents |

## Cloud agents without your PC

`.cursor/environment.json` still installs the same toolchain on managed cloud VMs when no My Machines worker is selected.
