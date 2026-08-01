#!/usr/bin/env bash
# Thin wrapper: full install lives in .cursor/install.sh (shared by Cloud Agents + WSL).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chmod +x "$ROOT/.cursor/install.sh" "$ROOT/scripts/verify-toolchain.sh"
bash "$ROOT/.cursor/install.sh"
bash "$ROOT/scripts/verify-toolchain.sh"
