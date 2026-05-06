# Changelog

Per-release notes for the public install artifacts. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · [SemVer](https://semver.org/).

## [v0.1.0] — 2026-05-06

First public release. Linux `.deb` + Windows `.msi` ship the user-facing 24-binary surface.

### Bundled binaries (24)

- **Core (3)**: `sauce`, `sauce-mcp`, `sauce-registry`
- **Pipeline (2)**: `sauce-pipeline`, `sauce-tok`
- **Generalists (3)**: `sauce-classify`, `sauce-ontology`, `sauce-extract`
- **Cartography (16)**: `sauce-cart-{fs-inventory,deps-roles,ts-types,sql-schema,routes-map,api-surface,configs-canon,docs-canon,patterns,standards,lexicon,taxonomy,ontology,topology,epistemology,db-rel-graph}`

See [`docs/binaries.md`](docs/binaries.md) for the per-binary reference.

### Distribution

| OS | Format | Size |
|---|---|---|
| Debian / Ubuntu (amd64) | `.deb` | 5.8 MB |
| Windows x64 | `.msi` | 21 MB |

### Install paths

- Edge user: [`docs/user-install.md`](docs/user-install.md)
- Enterprise control node: [`docs/enterprise-install.md`](docs/enterprise-install.md)

## Roadmap

| Item | Target |
|---|---|
| `.rpm` (RHEL / Fedora / openSUSE) | v0.2.0 |
| `.apk` (Alpine) | v0.2.0 |
| `.pkg` + Homebrew formula (macOS) | v0.2.0 |
| winget + Chocolatey (Windows) | v0.2.0 |
| Apt + DNF + APK repos hosted | v0.3.0 |
| All cluster / ops / dusa tier packages | v0.3.0 |
| SBOM + SLSA Level 3 attestations | v1.0.0 |
| LTS channel | v1.0.0 |

[v0.1.0]: https://github.com/Diatonic-AI/opensauce/releases/tag/v0.1.0
