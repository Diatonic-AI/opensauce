# Contributing to OpenSauce

OpenSauce is the **public install layer** for Sauce. It contains install scripts, signed release artifacts, and setup docs. Contributions accepted here are scoped to that surface.

## What we accept

- 🐛 **Install bugs** — `dpkg` / `msiexec` failures, missing dependencies, OS-specific install issues
- 📝 **Doc fixes** — typos, clarifications, missing edge cases in `docs/`
- 🔧 **Install-script improvements** — cross-distro compatibility, better error messages, additional package format support
- 📦 **New OS / package format support** — when v0.2.0+ rolls out `.rpm`, `.apk`, `.pkg`, etc., contributions to those packagings are welcome

## What goes elsewhere

| You want to … | Go to |
|---|---|
| Submit a plugin / skill / MCP server | Sauce Framework's contribution channel — see [https://saucetech.io/contribute](https://saucetech.io/contribute) |
| Report a runtime bug in a `sauce-*` binary | Same — Sauce Framework is private + apply-only |
| Request a framework feature | Same — open a feature request via your enterprise license channel or [https://saucetech.io/feature-requests](https://saucetech.io/feature-requests) |

## Filing an install bug

Use the [bug-report template](https://github.com/Diatonic-AI/opensauce/issues/new?template=install-bug.yml). Include:

- `sauce --version` (or "couldn't install" if the binary's not on PATH)
- OS + arch (`uname -a` for Linux/macOS, `winver` for Windows)
- Distro version (`lsb_release -a` or `/etc/os-release`)
- The exact command you ran
- Full output (use `RUST_LOG=debug` for runtime issues)

## PR guidelines

- Branch naming: `fix/<scope>` or `docs/<scope>` or `feat/<scope>`
- Keep PRs scoped to one concern
- Run shell scripts through `shellcheck` before submitting
- Test on the OS you're touching (we'll re-test in CI but author-side smoke-test catches the obvious things)

## License

By contributing, you agree your contributions are licensed MIT (matches the install scripts + docs in this repo). The Sauce binaries themselves ship under their own license.

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
