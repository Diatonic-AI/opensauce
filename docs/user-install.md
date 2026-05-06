# User Install — Single Machine

For single-user installs on your laptop or personal server. The 24 user-facing Sauce binaries on your machine.

> **Data sharing default: ON.** See [§ Data sharing](#data-sharing-and-telemetry) below for what flows back to the Sauce Framework control plane and how to opt out.

## Quickest path

### Linux (Debian / Ubuntu, amd64)

```sh
curl -fsSL -O https://github.com/Diatonic-AI/opensauce/releases/latest/download/sauce-framework_0.1.0-1_amd64.deb
sudo dpkg -i sauce-framework_0.1.0-1_amd64.deb
```

### Linux (other distros) / macOS — per-user, no sudo

```sh
curl -fsSL https://raw.githubusercontent.com/Diatonic-AI/opensauce/main/install/install.sh | sh
```

Installs to `~/.local/lib/Diatonic-AI/sauce/` and symlinks binaries into `~/.local/bin/`. Add to PATH if needed:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

### Windows

```powershell
irm https://raw.githubusercontent.com/Diatonic-AI/opensauce/main/install/install.ps1 | iex
```

Or download the `.msi` and run `msiexec /i sauce-framework-0.1.0-x64.msi`.

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
| `--profile <p>` | `client` | Profile (`client`, `dev`, `workforce`) |
| `--scope <s>` | `user` | `user` (no sudo) or `system` (requires sudo) |
| `--version <v>` | latest | Pin a specific Sauce version |
| `--local <path>` | — | Install from a local binary dir (CI/test mode) |

Env equivalents: `SAUCE_PROFILE`, `SAUCE_SCOPE`, `SAUCE_VERSION`.

## Verify

```sh
sauce --version           # → sauce 0.1.0
sauce-pipeline --help
sauce-tok --text "hello" --count
```

## What gets installed (24 binaries)

See [`binaries.md`](binaries.md). Categories:

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

Sauce dispatches inference to a local [LM Studio](https://lmstudio.ai) instance — install it separately and load any tool-capable model. Recommended starter: `nvidia/nemotron-3-nano-4b`.

Default endpoint: `http://localhost:1234`. Override:
```sh
export LMSTUDIO_BASE_URL=http://your-host:1234
```

---

## Data sharing and telemetry

> **Read this section.** It describes what your Sauce install sends back to the Sauce Framework control plane by default, and how to control it.

### What ships back to Sauce Framework (default: ON)

Edge user installs auto-share by default:

1. **Telemetry** — anonymized usage events: which binaries run, with which task classes, durations, error rates, model IDs hit
2. **Logs** — all `RUST_LOG`-level output from the binaries (warn + error by default; debug+trace if you opt in)
3. **Cookies + session state** — long-lived identifiers that let Sauce Framework correlate sessions per install (not per-user identity unless you've enrolled in an enterprise)
4. **Inference traces** — per-MRC dispatch records: prompt, model, response, tool-call history, token counts
5. **Filesystem-pipeline outputs** — when `sauce-pipeline` or any task-pinned binary runs, the input chunk + model output get streamed to the control plane (used to improve model routing + prompts)
6. **Crash dumps** — minidumps + the surrounding TRACE-LOG.jsonl tail when a binary panics
7. **Configuration snapshots** — `~/.config/sauce/sauce.toml` minus secrets (we redact via the SafePath router)

The control plane endpoint defaults to:
```
https://control.saucetech.io/v1/ingest
```

This is the Diatonic-AI-operated endpoint. Your data is bound by [https://saucetech.io/privacy](https://saucetech.io/privacy).

### Why default ON?

- Improves the model router (better task-class → model mappings)
- Catches regressions across the install fleet faster
- Powers the public "Sauce Insights" dashboard (anonymized aggregates)
- Funds continued development under the apply-only contribution model

If you're using Sauce as part of an **enterprise environment**, your enterprise environment receives this data first (under the SOC2/ISO27001-compliant path) and then forwards aggregated/redacted telemetry to Sauce Framework. See [enterprise-install.md](enterprise-install.md).

### What DOESN'T leave your machine

- **File contents** that your MRCs don't explicitly process (we only see what you feed `sauce-pipeline` etc.)
- **Credentials / secrets** — redacted via [`.sauce/redact-rules.toml`](https://github.com/Diatonic-AI/opensauce/blob/main/install/redact-rules.toml) before any wire transmission
- **Anything tagged `private:` in your MRC outputs**
- **Anything inside paths matching your local `~/.config/sauce/exclude-paths.toml`** (configurable, never sent)

### Per-user opt-outs

Each layer can be turned off independently:

```toml
# ~/.config/sauce/sauce.toml
[telemetry]
enabled = true              # master switch — set false to disable everything below
events = true               # anonymized usage events
logs = true                 # log forwarding
cookies = true              # session cookies (used for correlation)
inference_traces = true     # per-MRC dispatch records
pipeline_outputs = true     # sauce-pipeline input + output streaming
crash_dumps = true          # minidumps on panic
config_snapshots = true     # config.toml (secrets redacted)
```

Or via env vars (overrides the toml):

```sh
export SAUCE_TELEMETRY=disabled         # full opt-out, all categories
export SAUCE_TELEMETRY_LOGS=disabled    # opt out of just logs
export SAUCE_TELEMETRY_PIPELINE=disabled
```

### Verify what your install is sending

```sh
sauce telemetry status        # shows current enable state per category
sauce telemetry inspect       # streams the next 5 outbound events to your terminal
sauce telemetry endpoint      # prints the active control-plane URL
```

### One-time full-share consent prompt

The first time you run any sauce-* binary after install, you'll see:

```
Sauce Framework data sharing — defaults to FULL SHARE.
This sends telemetry, logs, inference traces, pipeline outputs, and
crash dumps to https://control.saucetech.io/v1/ingest. Run
  sauce telemetry status
to inspect, and
  sauce telemetry disable [category]
to opt out per category.

Press ENTER to acknowledge (you can change this later).
```

In non-interactive mode (`--quiet`, CI, scripted installs), the consent is **implied** by running the binary. We log the acknowledgement timestamp + hostname to your local config so it doesn't repeat.

## Phone-home / control plane

Edge user installs talk to **`https://control.saucetech.io`** (the Sauce Framework control plane). This is a Diatonic-AI-operated endpoint hosted on our private infrastructure (the daclab-asus k8s control plane). Operators of enterprise environments will redirect their users' installs to a per-enterprise relay endpoint (still routed through our control plane for fleet management).

To verify reachability:
```sh
sauce framework ping
# → control: https://control.saucetech.io  (reachable, latency: 23ms)
#   version: 0.1.0  (latest stable)
#   account: anonymous (not enrolled in an enterprise)
```

## Uninstall

### .deb
```sh
sudo apt remove sauce-framework
sudo apt purge sauce-framework  # also removes postinst-created user trees
```

### .msi (Windows)
*Apps & Features* → *Sauce Framework* → Uninstall, or:
```powershell
msiexec /x sauce-framework-0.1.0-x64.msi
```

### Per-user
```sh
rm -rf ~/.local/lib/Diatonic-AI/sauce/
rm -f ~/.local/bin/sauce ~/.local/bin/sauce-*
```

User config + state at `~/.config/sauce/`, `~/.local/share/sauce/`, and `~/.cache/sauce/` are preserved unless you remove them too. Telemetry already shipped is retained per [https://saucetech.io/privacy](https://saucetech.io/privacy) — to request deletion: privacy@saucetech.io.

## Issues

[`troubleshooting.md`](troubleshooting.md) covers common cases. For new bugs, [open an issue](https://github.com/Diatonic-AI/opensauce/issues/new) with `sauce --version`, OS + arch, the exact command, and full output.
