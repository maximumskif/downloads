# downloads

Toolchain bootstrap for **smart contracts** and **ARTB trading** development after a Windows reset.

## Sign into Ubuntu from PowerShell

Open **PowerShell** and run:

```powershell
wsl -d Ubuntu
```

First time after a reset (if Ubuntu/WSL is missing):

```powershell
wsl --install -d Ubuntu
```

Reboot if prompted, finish the Ubuntu username/password setup, then `wsl -d Ubuntu` again.

Helper script (from this repo on Windows):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\enter-ubuntu.ps1
```

## Install everything inside Ubuntu

```bash
bash scripts/wsl-bootstrap.sh
bash scripts/verify-toolchain.sh
```

That installs / verifies:

| Tool | Purpose |
|------|---------|
| Rust (`rustc` / `cargo`) | Foundry & Rust tooling |
| Python 3 + `web3`, `ccxt`, `pandas` | Trading bots / chain scripts |
| Node.js + `npm` / `yarn` / `pnpm` | Hardhat & JS tooling |
| Foundry (`forge` / `cast` / `anvil`) | Solidity compile, test, local chain |
| Hardhat + OpenZeppelin + `solc` | Alternative Solidity stack |

## Expected PATH locations (Ubuntu / WSL)

```text
$HOME/.cargo/bin          # rustc, cargo
$HOME/.foundry/bin        # forge, cast, anvil
$HOME/.nvm/.../bin        # node, npm, npx, hardhat
$HOME/.local/bin          # pip --user scripts
/usr/bin/python3
```
