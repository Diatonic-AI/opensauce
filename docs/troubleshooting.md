# Troubleshooting

Common install + runtime issues, in order of how often we see them.

## Install issues

### `sauce: command not found` after per-user install

**Cause**: `~/.local/bin` not on PATH.

**Fix**:
```sh
export PATH="$HOME/.local/bin:$PATH"   # add to ~/.bashrc or ~/.zshrc
```

### `dpkg: error processing archive` on Debian/Ubuntu

**Cause**: Missing dependencies (most often `libssl3`).

**Fix**:
```sh
sudo apt-get install -f                # auto-install missing deps
sudo dpkg -i sauce-framework_*.deb     # retry
```

### MSI installer fails silently on Windows

**Cause 1**: SmartScreen blocking the unsigned MSI.

**Fix**: Right-click → Properties → Unblock → re-run. Or run from elevated PowerShell with `-AllowUnsignedScripts`.

**Cause 2**: An older sauce install is present.

**Fix**: Use *Apps & Features* to uninstall first, then re-run.

### Cross-user install on macOS fails

**Cause**: macOS Gatekeeper rejecting the unsigned `.pkg`.

**Fix until v0.2.0 (when we ship notarized builds)**:
```sh
sudo xattr -d com.apple.quarantine sauce-framework-0.1.0.pkg
sudo installer -pkg sauce-framework-0.1.0.pkg -target /
```

## Runtime issues

### `LM Studio: connection refused`

**Cause**: LM Studio not running, or listening on a different port.

**Fix**:
```sh
# Verify LM Studio is up
curl http://localhost:1234/v1/models

# Or override the endpoint
export LMSTUDIO_BASE_URL=http://your-host:1234
```

### `tool loop exhausted after N turns`

**Cause**: The MRC's tool loop hit `max_tool_turns` without producing a final answer (R-LOOP-001 hard cap).

**Fix options**:
- Tighten the MRC prompt to discourage repeated tool calls
- Raise the cap: `export SAUCE_MAX_TOOL_TURNS=16` (clamped to [1, 64])
- Inspect the call history to find the loop pattern: the error includes `tool_call_history` showing every turn

### `sauce-pipeline.sh: not found`

**Cause**: The bash orchestrator script wasn't installed (older tarball install).

**Fix**: Re-install via `.deb` or `.msi` (both bundle the script under `/usr/share/sauce/scripts/` or `Program Files\SauceTech\Sauce\scripts\`).

Or set the override:
```sh
export SAUCE_PIPELINE_SCRIPT=/path/to/sauce-pipeline.sh
```

### Capability denied: `fs_write requires SAUCE_FS_WRITE_OK=1`

**Cause**: Defensive default. The builtin file-write tool refuses unless explicitly enabled.

**Fix**:
```sh
export SAUCE_FS_WRITE_OK=1            # for fs_write
export SAUCE_BASH_OK=1                # for bash_run / shell_exec
```

This is intentional defense-in-depth. **Don't set these globally** — scope them to the specific session that needs them.

## Enterprise control node issues

### `license validation failed` on bootstrap

**Cause 1**: License key expired or not yet provisioned.

**Fix**: Confirm key validity at [https://saucetech.io/license-status](https://saucetech.io/license-status) (requires login).

**Cause 2**: Control node can't reach Sauce Global.

**Fix**: Check egress to `https://global.saucetech.io`. If your network requires a proxy:
```sh
sauce enterprise bootstrap --license-key $LIC --proxy https://corp-proxy.example.com:3128
```

### OIDC authentication fails

**Cause**: Issuer URL mismatch or missing trust.

**Fix**:
```sh
sauce enterprise oidc test --issuer https://auth.acme.example.com/realms/acme
# → prints the discovery doc + verifies the JWKS

sauce enterprise oidc add-trust --issuer ... --ca-bundle /path/to/ca.pem
```

### Tenants stuck in `Pending` state in Kubernetes

**Cause**: Operator lacks permissions to create namespaces.

**Fix**:
```sh
kubectl auth can-i create namespaces --as system:serviceaccount:sauce-system:sauce-operator
# if "no", check ClusterRoleBinding:
kubectl describe clusterrolebinding sauce-operator
```

### Sauce Global registration not visible

**Cause**: Registration is async; can take up to 5 minutes.

**Fix**:
```sh
sauce global ping            # confirms reachability
sauce global status          # shows current registration

# Force re-sync
sauce global sync --force
```

## Performance

### High latency on `sauce-pipeline` runs

**Cause**: 4-chars/token estimator producing oversized chunks.

**Fix**: Confirm `sauce-tok` is on PATH (the bash orchestrator auto-detects it):
```sh
which sauce-tok                                  # should resolve
sauce-tok --count crates/some-source-file.rs     # should print integer
```

If sauce-tok is missing the script falls back to bytes/4 (warns to stderr) — chunks may exceed model context.

### `sauce-mcp` server timing out

**Cause**: Default 30s tool timeout too aggressive for some workloads.

**Fix**: Per-tool override in the MRC's `tool_config`:
```yaml
tool_config:
  tools:
    - id: tool-mcp-codegraph-build
      safety:
        timeout_ms: 120000     # bump for this tool
```

## Getting help

1. Check this page first.
2. Search [existing issues](https://github.com/Diatonic-AI/opensauce/issues?q=is%3Aissue).
3. [Open a new issue](https://github.com/Diatonic-AI/opensauce/issues/new) with the template.
4. Enterprise-license customers: contact your dedicated support channel.

When opening an issue, include:
- `sauce --version`
- `uname -a` (Linux/macOS) or `winver` (Windows)
- The exact command you ran
- Full output (with `RUST_LOG=debug` if it's a dispatch issue)
- Relevant config (`~/.config/sauce/sauce.toml` — redact secrets first)
