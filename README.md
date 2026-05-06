# OpenSauce

> **Install Sauce.** Public download + setup paths for the [Sauce Framework](https://saucetech.io).
> Edge users · enterprise managed-cloud environments.

[![Latest release](https://img.shields.io/github/v/release/Diatonic-AI/opensauce?display_name=tag&label=release)](https://github.com/Diatonic-AI/opensauce/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE-MIT)

---

## How Sauce is shaped

```
┌─────────────────────────────────────────────────────────────┐
│  Sauce Framework Control Plane                              │
│  (PRIVATE — Diatonic-AI's infrastructure; you don't run it) │
│   • fleet management • version reconciliation               │
│   • license compliance • telemetry + log ingest             │
│   • provisions enterprise cloud environments                │
└─────────────────────────────────────────────────────────────┘
                       │ provisions + manages
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  Enterprise Cloud Environments                              │
│  (managed by Diatonic-AI, hosted in your chosen cloud,      │
│   SOC 2 Type II + ISO 27001)                                │
│   • per-enterprise tenancy • OIDC federation                │
│   • data residency • compliance audit logging               │
└─────────────────────────────────────────────────────────────┘
                       │ hosts
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  Business Workspaces (local-first, scale to cloud)          │
│   • multi-user shared filesystem workbench                  │
│   • run on one machine, promote to cloud when needed        │
└─────────────────────────────────────────────────────────────┘
                       │ serves
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  Edge User Installs (per-user, no backend)                  │
│   • 24-binary user-facing surface                           │
│   • telemetry / logs / cookies auto-share defaults ON       │
│   • per-user opt-out for any data category                  │
└─────────────────────────────────────────────────────────────┘
```

You install the **edge layer** from this repo. Enterprises **request a managed cloud environment** — you don't stand up the control plane yourself; Diatonic-AI does.

---

## The 12 layers — and which ones you touch

Sauce is organized as a 12-layer vertical stack (canonical model in the framework repo's `docs/architecture/layer-stack.md`). **OpenSauce ships only L11 (delivery / packaging) and L12 (user surfaces).** The deeper layers — storage, semantics, model runtime, agent contracts, mesh control, governance — live behind the binary boundary in the framework repo.

| What you want | Layers you touch | Where to start |
|---|---|---|
| "I just want to use it." | L11 + L12 | [`docs/user-install.md`](docs/user-install.md) |
| "I want to extend it (skills, plugins, MCP)." | + L8 (Agency) | SDK crates: `sauce-skill-sdk`, `sauce-plugin-sdk`, `sauce-mcp-sdk` (framework repo) |
| "I run this for an org." | + L9 (Control), L10 (Governance) | [`docs/enterprise-install.md`](docs/enterprise-install.md) |
| "I want to understand the whole thing." | L1 → L12 | Framework repo `docs/architecture/layer-stack.md` |

The four-tier control-plane diagram above is *deployment topology*. The 12 layers are *what kind of concern lives where*. They are orthogonal axes — see the framework repo's `docs/architecture/README.md` § "The five axes of Sauce."

---

## Two install paths

### 👤 Edge user (single machine)
Install the 24 user-facing Sauce binaries on your laptop / dev box / personal Linux server. No sudo by default.
👉 **[docs/user-install.md](docs/user-install.md)**

```sh
curl -fsSL https://raw.githubusercontent.com/Diatonic-AI/opensauce/main/install/install.sh | sh
```

⚠️ **Default data sharing is ON** — telemetry, logs, cookies, inference traces, and pipeline outputs auto-share to the Sauce Framework control plane. See [`docs/user-install.md` § Data sharing and telemetry](docs/user-install.md#data-sharing-and-telemetry) for what's sent and how to opt out per category.

### 🏢 Enterprise (managed cloud environment)
Your organization gets a SOC2/ISO27001-compliant cloud environment provisioned + managed by Diatonic-AI. Your business workspaces run local-first and scale to the cloud env when usage justifies.
👉 **[docs/enterprise-install.md](docs/enterprise-install.md)**

Request via: **enterprise@saucetech.io**

---

## Direct downloads

Latest release: [v0.1.0](https://github.com/Diatonic-AI/opensauce/releases/tag/v0.1.0)

| OS | Format | Size | Direct link |
|---|---|---|---|
| Debian / Ubuntu (amd64) | `.deb` | 5.8 MB | [sauce-framework_0.1.0-1_amd64.deb](https://github.com/Diatonic-AI/opensauce/releases/latest/download/sauce-framework_0.1.0-1_amd64.deb) |
| Windows x64 | `.msi` | 21 MB | [sauce-framework-0.1.0-x64.msi](https://github.com/Diatonic-AI/opensauce/releases/latest/download/sauce-framework-0.1.0-x64.msi) |

`.rpm`, `.apk`, `.pkg` (macOS), Homebrew, winget, and Chocolatey ship in v0.2.0. See [CHANGELOG.md](CHANGELOG.md) for the roadmap.

---

## After install

```sh
sauce --version
sauce init --scope user --profile dev
```

Walk through the first-run flow at [`docs/getting-started.md`](docs/getting-started.md).

Want to extend Sauce with your own skills, plugins, or MCP servers? [`docs/hobbyist-quickstart.md`](docs/hobbyist-quickstart.md) — adds L7 (local model) and L8 (agency) on top of your install.

Stuck? [`docs/troubleshooting.md`](docs/troubleshooting.md).

What each of the 24 binaries does: [`docs/binaries.md`](docs/binaries.md).

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
    ├── user-install.md        # edge-user / single-machine install + telemetry terms
    ├── enterprise-install.md  # how to request a managed cloud environment
    ├── getting-started.md     # post-install first-run walkthrough
    ├── binaries.md            # what each of the 24 bundled binaries does
    └── troubleshooting.md     # install + runtime issue catalogue
```

---

## How does this relate to Sauce Framework?

| Repo | Visibility | Contains |
|---|---|---|
| **`Diatonic-AI/sauce-framework-rs`** | Private | Rust source, 74 binaries, 104 crates, framework architecture, control-plane Helm charts, plugin/skill/MCP authoring, the `.sauce/` protocol spec, internal CI |
| **`Diatonic-AI/opensauce`** (this repo) | Public | Install scripts, signed release artifacts, edge-user + enterprise setup docs, troubleshooting |

The Sauce Framework control plane runs on Diatonic-AI's private infrastructure. Source contributions to the framework happen via the licensed channel at [https://saucetech.io/contribute](https://saucetech.io/contribute).

You can fork this repo to customize install scripts for your environment. Bug reports and install-script PRs are welcome via [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

The install scripts and docs in this repo are MIT — see [LICENSE-MIT](LICENSE-MIT).

The Sauce binaries themselves ship under their own license (bundled inside the `.deb`/`.msi` as `LICENSE`).
