# Agent notes

## Cursor Cloud

- Environment config: `.cursor/environment.json`
- Boot install: `.cursor/install.sh` (idempotent)
- Verify: `bash scripts/verify-toolchain.sh`

After install, source PATH with:

```bash
source "$HOME/.toolchain-path.sh"
```

## Local Windows / WSL

User runs from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-from-powershell.ps1
```

Do not attempt to open the user's local PowerShell from a cloud agent — give them the commands above.
