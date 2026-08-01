#!/usr/bin/env bash
# Bootstrap Ubuntu (WSL or native) for smart-contract + ARTB trading development.
# Run inside Ubuntu after:  wsl -d Ubuntu
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "==> Updating apt packages"
sudo apt-get update -y
sudo apt-get install -y \
  build-essential clang cmake pkg-config libssl-dev libudev-dev \
  curl git ca-certificates unzip python3 python3-pip python3-venv

echo "==> Installing Rust (rustup)"
if ! command -v rustc >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# shellcheck disable=SC1091
source "$HOME/.cargo/env"
rustup default stable
rustup target add wasm32-unknown-unknown

echo "==> Installing Node.js via nvm"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck disable=SC1091
source "$NVM_DIR/nvm.sh"
nvm install 22
nvm alias default 22
npm install -g yarn pnpm hardhat solc @openzeppelin/contracts

echo "==> Installing Foundry (forge / cast / anvil)"
if ! command -v foundryup >/dev/null 2>&1; then
  curl -L https://foundry.paradigm.xyz | bash
fi
# shellcheck disable=SC1091
source "$HOME/.bashrc" || true
export PATH="$HOME/.foundry/bin:$PATH"
foundryup

echo "==> Installing Python packages for web3 + trading"
python3 -m pip install --user --upgrade pip
python3 -m pip install --user \
  web3 eth-account eth-utils hexbytes eth-abi \
  python-dotenv aiohttp websockets pandas ccxt numpy requests

# Persist PATH for future shells
BASHRC="$HOME/.bashrc"
ensure_path_line() {
  local line="$1"
  grep -qxF "$line" "$BASHRC" 2>/dev/null || echo "$line" >> "$BASHRC"
}
ensure_path_line 'export PATH="$HOME/.local/bin:$PATH"'
ensure_path_line 'export PATH="$HOME/.foundry/bin:$PATH"'
ensure_path_line 'export PATH="$HOME/.cargo/bin:$PATH"'
ensure_path_line 'export NVM_DIR="$HOME/.nvm"'
ensure_path_line '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'

echo
echo "==> Bootstrap complete. Run:  bash scripts/verify-toolchain.sh"
echo "    Or open a new Ubuntu shell so PATH updates apply."
