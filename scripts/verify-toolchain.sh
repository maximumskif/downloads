#!/usr/bin/env bash
# Print versions and PATH locations for the smart-contract / trading toolchain.
set -euo pipefail

export PATH="${HOME}/.venvs/artb-trading/bin:${HOME}/.foundry/bin:${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
export NVM_DIR="${HOME}/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
# shellcheck disable=SC1091
[ -f "${HOME}/.toolchain-path.sh" ] && . "${HOME}/.toolchain-path.sh"
# shellcheck disable=SC1091
[ -f "${HOME}/.venvs/artb-trading/bin/activate" ] && . "${HOME}/.venvs/artb-trading/bin/activate"

ok()   { printf '  [OK]   %-12s %s\n' "$1" "$2"; }
miss() { printf '  [MISS] %-12s %s\n' "$1" "$2"; FAIL=1; }
FAIL=0

echo "Toolchain check ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
echo "Host: $(uname -srm) | $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || echo unknown)"
echo

check_cmd() {
  local name="$1" ver_cmd="$2"
  if command -v "$name" >/dev/null 2>&1; then
    local ver path
    ver=$(eval "$ver_cmd" 2>/dev/null | head -1 || echo installed)
    path=$(command -v "$name")
    ok "$name" "$ver  ($path)"
  else
    miss "$name" "not found on PATH"
  fi
}

check_cmd rustc  "rustc --version"
check_cmd cargo  "cargo --version"
check_cmd python3 "python3 --version"
check_cmd pip3   "pip3 --version"
check_cmd node   "node --version"
check_cmd npm    "npm --version"
check_cmd npx    "npx --version"
check_cmd yarn   "yarn --version"
check_cmd pnpm   "pnpm --version"
check_cmd forge  "forge --version"
check_cmd cast   "cast --version"
check_cmd anvil  "anvil --version"
check_cmd hardhat "hardhat --version"

echo
echo "Python packages:"
python3 - <<'PY' || FAIL=1
mods = ["web3", "eth_account", "pandas", "ccxt", "numpy", "requests", "dotenv"]
for m in mods:
    try:
        mod = __import__(m if m != "dotenv" else "dotenv")
        ver = getattr(mod, "__version__", "ok")
        print(f"  [OK]   {m:12} {ver}")
    except Exception as e:
        print(f"  [MISS] {m:12} {e}")
        raise SystemExit(1)
PY

echo
echo "Key PATH dirs:"
for d in \
  "$HOME/.foundry/bin" \
  "$HOME/.cargo/bin" \
  "$HOME/.local/bin" \
  "${NVM_DIR:-}/versions/node" \
  /usr/local/cargo/bin \
  /usr/bin
do
  [ -e "$d" ] && echo "  present: $d" || echo "  absent:  $d"
done

echo
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: all required tools present"
  exit 0
else
  echo "RESULT: missing tools — run: bash scripts/wsl-bootstrap.sh"
  exit 1
fi
