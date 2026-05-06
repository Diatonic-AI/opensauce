# User Install — Single Machine

For single-user installs on your laptop or personal server. No control plane, no tenant management — just the 24 user-facing Sauce binaries on your machine.

## Quickest path

### Linux (Debian / Ubuntu, amd64)

```sh
curl -fsSL -O https://github.com/Diatonic-AI/opensauce/releases/latest/download/sauce-framework_0.1.0-1_amd64.deb
sudo dpkg -i sauce-framework_0.1.0-1_amd64.deb
```

The `.deb` postinst hook auto-provisions per-user `.sauce/` trees for every interactive user with UID ≥ 1000.

### Linux (other distros) / macOS — per-user, no sudo

```sh
curl -fsSL https://raw.githubusercontent.com/Diatonic-AI/opensauce/main/install/install.sh | sh
```

This installs to `~/.local/lib/Diatonic-AI/sauce/` and symlinks binaries into `~/.local/bin/`. Add it to PATH if needed:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

### Windows

```powershell
irm https://raw.githubusercontent.com/Diatonic-AI/opensauce/main/install/install.ps1 | iex
```

Or download the `.msi` and run:

```powershell
msiexec /i sauce-framework-0.1.0-x64.msi
```

Per-user install (no admin):

```powershell
msiexec /i sauce-framework-0.1.0-x64.msi MSIINSTALLPERUSER=1 ALLUSERS=""
```

## Install script options

```sh
curl -fsSL .../install.sh | sh -s -- [options]
```

| Flag | Default | Purpose |
|---|---|---|
| `--profile <p>` | `client` | Profile passed to `sauce init` (`client`, `dev`, `workforce`) |
| `--scope <s>` | `user` | `user` (no sudo) or `system` (requires sudo) |
| `--version <v>` | latest | Pin a specific Sauce version |
| `--local <path>` | — | Install from a local binary dir (CI/test mode) |

Env-var equivalents: `SAUCE_PROFILE`, `SAUCE_SCOPE`, `SAUCE_VERSION`.

## Verify

```sh
sauce --version           # → sauce 0.1.0
sauce-pipeline --help     # full CLI surface
sauce-tok --text "hello" --count
```

## What gets installed (24 binaries)

See [`binaries.md`](binaries.md) for the per-binary reference. Quick categories:

- **Core (3)**: `sauce`, `sauce-mcp`, `sauce-registry`
- **Pipeline (2)**: `sauce-pipeline`, `sauce-tok`
- **Generalists (3)**: `sauce-classify`, `sauce-ontology`, `sauce-extract`
- **Cartography (16)**: `sauce-cart-*` — codebase / filesystem analysis tools

## First run

```sh
sauce init --scope user --profile dev
```

Continue at [`getting-started.md`](getting-started.md).

## LM Studio

Sauce dispatches inference to a local [LM Studio](https://lmstudio.ai) instance. Install it separately and load any tool-capable model. The recommended starter model is `nvidia/nemotron-3-nano-4b` (small, fast, 100% accuracy on the cartography eval bank).

Default endpoint: `http://localhost:1234`. Override:

```sh
export LMSTUDIO_BASE_URL=http://your-host:1234
```

## Phone-home / telemetry

Edge user installs **do not** phone home by default. The framework's global control plane only tracks installs registered through an enterprise control node. If your install is part of an enterprise deployment, your operator will configure the registration endpoint via:

```toml
# ~/.config/sauce/sauce.toml
[control_plane]
endpoint = "https://control.your-enterprise.example.com"
enrollment_token = "..."
```

To opt out entirely (even if your config has an endpoint set):

```sh
export SAUCE_TELEMETRY=disabled
```

## Uninstall

### .deb
```sh
sudo apt remove sauce-framework
# or to also remove postinst-created user trees:
sudo apt purge sauce-framework
```

### .msi (Windows)
Use *Apps & Features* → uninstall *Sauce Framework*, or:
```powershell
msiexec /x sauce-framework-0.1.0-x64.msi
```

### Per-user install
```sh
rm -rf ~/.local/lib/Diatonic-AI/sauce/
rm -f ~/.local/bin/sauce ~/.local/bin/sauce-*
```

User config + state at `~/.config/sauce/`, `~/.local/share/sauce/`, and `~/.cache/sauce/` are preserved unless you remove them too.

## Issues

If something doesn't work, [`troubleshooting.md`](troubleshooting.md) covers the common cases. For new bugs, [open an issue](https://github.com/Diatonic-AI/opensauce/issues/new) with:
- `sauce --version`
- OS + arch (`uname -a` / `winver`)
- The exact command you ran + the full output
