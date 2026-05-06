# OpenSauce

> **Install Sauce.** Public download + setup paths for the [Sauce Framework](https://saucetech.io).
> Edge users · enterprise control nodes · tenant onboarding.

[![Latest release](https://img.shields.io/github/v/release/Diatonic-AI/opensauce?display_name=tag&label=release)](https://github.com/Diatonic-AI/opensauce/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE-MIT)

---

## What is this repo?

This is the **public install layer** for Sauce. It contains the install scripts, native packages (`.deb` / `.msi` / etc.), and per-environment setup docs you need to deploy Sauce on a machine, a control node, or an enterprise tenant.

It is **not** the framework source — that lives in a private repo and ships here as signed binaries. Everyone — single users, enterprise operators, or contributors — installs from here.

The Sauce Framework's global control plane tracks every install for fleet management, version compliance, and enterprise license reconciliation. Your install will phone home (configurable, see [`docs/enterprise-install.md`](docs/enterprise-install.md)) so your enterprise's Sauce Global view can manage it.

---

## Two install paths

### 👤 Edge user (single machine)
Install Sauce on your laptop / dev box / personal Linux server. No sudo required by default; system scope optional.
👉 **[docs/user-install.md](docs/user-install.md)**

```sh
curl -fsSL https://raw.githubusercontent.com/Diatonic-AI/opensauce/main/install/install.sh | sh
```

### 🏢 Enterprise control node
Stand up the enterprise control plane that registers with Sauce Global, owns a domain, and manages tenants under it.
👉 **[docs/enterprise-install.md](docs/enterprise-install.md)**

```sh
sudo dpkg -i sauce-framework_0.1.0-1_amd64.deb
sudo sauce enterprise bootstrap --domain acme.example.com --license-key $LIC
```

---

## Direct downloads

Latest release: [v0.1.0](https://github.com/Diatonic-AI/opensauce/releases/tag/v0.1.0)

| OS | Format | Size | Direct link |
|---|---|---|---|
| Debian / Ubuntu (amd64) | `.deb` | 5.8 MB | [sauce-framework_0.1.0-1_amd64.deb](https://github.com/Diatonic-AI/opensauce/releases/latest/download/sauce-framework_0.1.0-1_amd64.deb) |
| Windows x64 | `.msi` | 21 MB | [sauce-framework-0.1.0-x64.msi](https://github.com/Diatonic-AI/opensauce/releases/latest/download/sauce-framework-0.1.0-x64.msi) |

`.rpm`, `.apk`, `.pkg` (macOS), Homebrew, winget, and Chocolatey ship in v0.2.0. Track progress in [CHANGELOG.md](CHANGELOG.md).

---

## After install

```sh
sauce --version
sauce init --scope user --profile dev
```

Walk through the first-run flow at [`docs/getting-started.md`](docs/getting-started.md).

Stuck? [`docs/troubleshooting.md`](docs/troubleshooting.md) covers the common install + runtime errors.

What each of the 24 bundled binaries does: [`docs/binaries.md`](docs/binaries.md).

---

## Repo layout

```
opensauce/
├── README.md                  # this file
├── LICENSE-MIT
├── CHANGELOG.md               # release notes per version
├── install/
│   ├── install.sh             # POSIX install (Linux + macOS)
│   └── install.ps1            # Windows install
└── docs/
    ├── user-install.md        # edge-user / single-machine install
    ├── enterprise-install.md  # enterprise control node + tenant onboarding
    ├── getting-started.md     # post-install first-run walkthrough
    ├── binaries.md            # what each of the 24 bundled binaries does
    └── troubleshooting.md     # install + runtime issue catalogue
```

---

## How does this relate to Sauce Framework?

| Repo | Visibility | Contains |
|---|---|---|
| **`Diatonic-AI/sauce-framework-rs`** | Private | Rust source, 74 binaries, 104 crates, framework architecture, plugin/skill/MCP authoring, the `.sauce/` protocol spec, internal CI |
| **`Diatonic-AI/opensauce`** (this repo) | Public | Install scripts, signed release artifacts, per-environment setup docs, troubleshooting |

The framework itself is **apply-only** — the source ships here as binaries, and any contribution back into the framework happens via the licensed channel described at [https://saucetech.io/contribute](https://saucetech.io/contribute).

You can absolutely fork this repo, customize the install scripts for your environment, or vendor the artifacts inside your own deployment system. Bug reports and install-script PRs are welcome via [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

The install scripts and docs in this repo are MIT — see [LICENSE-MIT](LICENSE-MIT).

The Sauce binaries themselves ship under their own license (see the bundled `LICENSE` inside the `.deb`/`.msi`).
