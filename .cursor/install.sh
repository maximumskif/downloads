#!/usr/bin/env bash
# Idempotent install for Cursor Cloud Agents + local Ubuntu/WSL.
# Ensures Rust, Node/npm, Foundry, Hardhat, and Python trading/web3 deps.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export PATH="${HOME}/.foundry/bin:${HOME}/.cargo/bin:/usr/local/cargo/bin:${HOME}/.local/bin:${PATH}"

echo "[install] apt build deps"
if command -v sudo >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y \
    build-essential clang cmake pkg-config libssl-dev libudev-dev \
    curl git ca-certificates unzip python3 python3-pip python3-venv
else
  apt-get update -y
  apt-get install -y \
    build-essential clang cmake pkg-config libssl-dev libudev-dev \
    curl git ca-certificates unzip python3 python3-pip python3-venv
fi

echo "[install] Rust"
if ! command -v rustc >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# shellcheck disable=SC1091
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
export PATH="${HOME}/.cargo/bin:/usr/local/cargo/bin:${PATH}"
if command -v rustup >/dev/null 2>&1; then
  rustup default stable || true
  rustup target add wasm32-unknown-unknown || true
fi

echo "[install] Node via nvm"
export NVM_DIR="${HOME}/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"
nvm install 22
nvm alias default 22
npm install -g yarn pnpm hardhat solc @openzeppelin/contracts

echo "[install] Foundry"
if [ ! -x "$HOME/.foundry/bin/foundryup" ] && ! command -v foundryup >/dev/null 2>&1; then
  curl -L https://foundry.paradigm.xyz | bash
fi
export PATH="${HOME}/.foundry/bin:${PATH}"
foundryup

echo "[install] Python packages"
python3 -m pip install --user --upgrade pip || python3 -m pip install --upgrade pip
if [ -f requirements.txt ]; then
  python3 -m pip install --user -r requirements.txt || \
    python3 -m pip install --break-system-packages -r requirements.txt
else
  python3 -m pip install --user \
    web3 eth-account eth-utils hexbytes eth-abi \
    python-dotenv aiohttp websockets pandas ccxt numpy requests || \
  python3 -m pip install --break-system-packages \
    web3 eth-account eth-utils hexbytes eth-abi \
    python-dotenv aiohttp websockets pandas ccxt numpy requests
fi

if [ -f package.json ]; then
  echo "[install] npm project deps"
  npm install
fi

# Persist PATH for interactive + non-interactive shells
PROFILE_SNIPPET="${HOME}/.toolchain-path.sh"
cat > "$PROFILE_SNIPPET" <<'EOF'
export PATH="$HOME/.local/bin:$HOME/.foundry/bin:$HOME/.cargo/bin:/usr/local/cargo/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
EOF

for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  touch "$rc"
  grep -qxF "[ -f \"$HOME/.toolchain-path.sh\" ] && . \"$HOME/.toolchain-path.sh\"" "$rc" 2>/dev/null || \
    echo "[ -f \"$HOME/.toolchain-path.sh\" ] && . \"$HOME/.toolchain-path.sh\"" >> "$rc"
done

# shellcheck disable=SC1091
. "$PROFILE_SNIPPET"

echo "[install] done"
command -v rustc && rustc --version
command -v node && node --version
command -v npm && npm --version
command -v forge && forge --version | head -1
command -v hardhat && hardhat --version
python3 -c "import web3,ccxt,pandas; print('web3', web3.__version__)"
