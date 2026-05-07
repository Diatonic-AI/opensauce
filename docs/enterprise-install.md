# Enterprise Install — Managed Cloud Environment

> **Audience: enterprise operator persona.** You run the full L9 (control / mesh / pipelines) + L10 (governance / policy / identity / audit) + L11 (delivery) + L12 (surface) stack. AWS / Azure / GCP mappings live in the framework repo's `docs/architecture/hyperscaler-alignment.md`; silo vs pool tenancy in `docs/architecture/multi-tenancy.md`. See `docs/architecture/install-ladder.md` for the full persona map.

This is the path for organizations adopting Sauce at the enterprise level. **Enterprises do not self-host the Sauce Framework control plane.** That control plane runs on Sauce Technologies–managed infrastructure. What enterprises receive is a **managed cloud environment** provisioned for them — SOC2 + ISO27001 compliant — that hosts their business workspaces and routes to the control plane on their behalf.

Single-machine / personal installs should use [`user-install.md`](user-install.md) instead.

## How enterprise Sauce works

```
┌──────────────────────────────────────────────────────────────────┐
│ Sauce Framework Control Plane                                    │
│  (private — Sauce Technologies–managed infrastructure)           │
│  - Fleet management / version reconciliation                     │
│  - License compliance / seat tracking                            │
│  - Telemetry + log ingest                                        │
│  - Provisions enterprise cloud environments                      │
└──────────────────────────────────────────────────────────────────┘
                          │ provisions + manages
                          ▼
┌──────────────────────────────────────────────────────────────────┐
│ Your Enterprise Cloud Environment                                │
│  (cloud-hosted, SOC2 Type II + ISO 27001)                        │
│  Region(s) of your choice — AWS / Azure / GCP                    │
│  - Per-enterprise tenancy + isolation                            │
│  - Compliance audit logging                                      │
│  - Identity federation (your OIDC issuer)                        │
│  - Data residency enforcement                                    │
└──────────────────────────────────────────────────────────────────┘
                          │ hosts
                          ▼
┌──────────────────────────────────────────────────────────────────┐
│ Business Workspaces                                              │
│  Local-first, scale to your enterprise cloud env when needed     │
│  - Multi-user shared filesystem workbench                        │
│  - Run on a workspace lead's machine until usage justifies cloud │
│  - One-command promotion to cloud (data + state migrate)         │
└──────────────────────────────────────────────────────────────────┘
                          │ serves
                          ▼
┌──────────────────────────────────────────────────────────────────┐
│ Edge User Installs                                               │
│  Per-user laptops / dev boxes                                    │
│  - Standard install via opensauce/install.sh                     │
│  - Auto-enrolled into a workspace via enterprise enrollment      │
│  - Telemetry / logs / cookies route through the enterprise env   │
│    (not directly to Sauce Framework — your data stays in your    │
│    cloud env first, then aggregated forward)                     │
└──────────────────────────────────────────────────────────────────┘
```

You **never** stand up our control plane. We do. You get a managed cloud environment with a UI, an API, and a billing relationship.

## Getting an enterprise environment

### 1. Request

Email: **enterprise@saucetech.io** with:
- Organization name + primary domain
- Approximate seat count
- Cloud preference (AWS / Azure / GCP / multi)
- Region(s) for data residency
- Compliance requirements beyond SOC2/ISO27001 (HIPAA, FedRAMP, PCI, etc.)
- Identity provider (Okta / Auth0 / Entra / Cognito / Cloud Identity / Keycloak)

### 2. Provisioning (we do this)

Within typically 3 business days, we provision:

- **Dedicated VPC / VNet / project** in your chosen cloud + region
- **Managed Kubernetes cluster** (EKS / AKS / GKE) sized for your seat count
- **Sauce control-plane components** (sauce-edge, sauce-policy-engine, sauce-shadow-ledger, sauce-trace-collector) — the same components that run on the Sauce Framework control plane, scoped to your enterprise
- **Per-enterprise Postgres** (managed RDS / Azure SQL / Cloud SQL) with row-level tenant isolation
- **Per-enterprise object store** (S3 / Azure Blob / GCS) with KMS-managed encryption
- **OIDC federation** with your identity provider
- **DNS subdomain** under your primary domain (e.g. `sauce.acme.example.com`) with TLS via Let's Encrypt or your CA
- **Compliance logging** — SOC2 Type II evidence streams to your retention bucket; ISO27001 control attestations available on demand

You get:
- An **enterprise admin URL** (`https://sauce.acme.example.com/admin`)
- An **enterprise admin token** (rotated quarterly)
- A **billing portal** linked to your subscription

### 3. First-day setup

Log in to the admin URL with your enterprise admin token, then:

1. Define **workspaces** — usually one per product line, team, or business unit
2. Define **tenancy mode** per workspace — `pool` (cheaper, shared) or `silo` (isolated, regulated)
3. Generate **enrollment tokens** for users to onboard their edge installs

```
Enterprise: acme-corp
├── Workspace: platform-engineering   (pool)
│   ├── Tenant: globex-team           (auto-created from first enrollment)
│   └── Tenant: initech-team
└── Workspace: regulated-data         (silo, hardened compliance)
    └── Tenant: finance-team          (dedicated namespace + KMS keys)
```

## Business workspaces — local-first, scale to cloud

Each workspace starts as a **local shared workbench** running on one team member's machine. The workspace lead installs Sauce, designates a host, and shares a workspace endpoint over the team's VPN / Tailscale / ZeroTier.

```sh
# On the workspace lead's machine:
sudo dpkg -i sauce-framework_0.1.0-1_amd64.deb
sauce workspace init \
  --enterprise-token $ENTERPRISE_TOKEN \
  --workspace platform-engineering \
  --bind 0.0.0.0:9001 \
  --share-fs ~/work/shared-fs
```

Team members then point their edge installs at the workspace:

```sh
sauce enroll --workspace https://lead-machine.tailnet:9001
```

The lead's machine hosts the multi-user shared filesystem workbench. State stays local.

### Promote local → cloud

When usage outgrows the local host (more concurrent users, more compute, more storage, durability concerns), one command promotes the workspace to the cloud:

```sh
sauce workspace promote --to enterprise-cloud
```

This:
1. Snapshots local state + filesystem
2. Provisions the workspace in the enterprise cloud env (idempotent — if it already exists, just promotes data)
3. Migrates data via the SOC2-compliant transfer pipeline
4. Re-routes the workspace endpoint to the cloud URL
5. Edge user installs auto-discover the new endpoint via DNS

Total downtime: typically under 10 minutes for workspaces under 100 GB.

After promotion, the lead's local machine becomes a **regular edge install** — same workspace, no special status.

## Onboarding edge users

Each user runs the standard edge install (see [`user-install.md`](user-install.md)), then enrolls:

```sh
# Admin generates a one-time enrollment token via the enterprise admin UI
# (or programmatically: sauce enterprise tenant enroll-token --user alice@globex.com)

# User enrolls their install:
sauce enroll --token $ENROLLMENT_TOKEN
```

After enrollment, the edge install:
- Routes telemetry / logs / cookies through the enterprise cloud env (not directly to Sauce Framework)
- Authenticates via your OIDC issuer
- Receives workspace-scoped capability gates
- Falls under your enterprise's data-residency + compliance posture

## What lives where

| Layer | Where | Operator | Data residency |
|---|---|---|---|
| Sauce Framework control plane | Sauce Technologies–managed infrastructure | Sauce Technologies | n/a — control-plane only, no enterprise data |
| Enterprise cloud env | Your chosen cloud + region | Sauce Technologies (managed) | Pinned to your region(s) |
| Business workspace (local) | Workspace lead's machine | Your team | Lead's machine |
| Business workspace (cloud) | Inside your enterprise cloud env | Sauce Technologies (managed) | Pinned to your region(s) |
| Edge user install | Each user's machine | The user | The user's machine |

**Your enterprise data never traverses the Sauce Framework control plane.** It lives in your enterprise cloud env, governed by your contracted SOC2/ISO27001 controls. Sauce Framework's view of your enterprise is limited to: enterprise ID, license entitlement, version compliance, anonymized aggregate telemetry.

## Compliance posture

Every enterprise cloud env ships with:

- **SOC 2 Type II** — annual audit, evidence streams to your retention bucket
- **ISO 27001** — Annex A controls implemented + attested
- **Per-tenant audit log** — append-only via `sauce-shadow-ledger`
- **KMS-managed encryption** at rest, TLS 1.3 in transit
- **Capability gates** locked to `hardened` mode by default (no `fs_write` / `bash_run` for tenants without explicit per-policy allowlists)

Optional add-ons (per request):
- **HIPAA** — BAA available, enforced silo-only mode for relevant workspaces
- **FedRAMP** — High baseline, GovCloud / Azure Government / Assured Workloads deployment
- **PCI DSS** — dedicated VPC + KMS + attested controls

## Pricing model

Enterprise pricing is per-seat per-month with optional add-ons for compliance, regions, and silo-mode workspaces. Get a quote via the enterprise email above.

## Upgrade path

Sauce Framework releases new versions on the public opensauce repo. Your enterprise cloud env receives upgrades:

- **Patch versions** (`0.1.x`) — auto-applied within 7 days
- **Minor versions** (`0.x.0`) — opt-in, deployed during your maintenance window
- **Major versions** (`x.0.0`) — opt-in, requires explicit acceptance + migration playbook review

Edge user installs upgrade independently via standard apt / msiexec / install.sh. The enterprise cloud env handles version-skew compatibility (always supports current + previous minor for ≥ 6 months).

## Backup + DR

Backups are taken automatically by Sauce Technologies on a 4-hour cadence with 30-day retention (longer retention available per contract). DR runbooks are part of your enterprise SLA.

You can request an off-cycle backup at any time via the admin UI.

## Migration from local-only / per-user installs

If your organization currently runs Sauce as a fleet of edge user installs (no enterprise env), you can migrate:

1. Provision the enterprise env (steps above)
2. Issue enrollment tokens to existing users
3. Users run `sauce enroll --token $TOKEN` — their existing local state stays; future telemetry routes through the enterprise env
4. (Optional) Migrate per-user `.sauce/` trees to the enterprise via `sauce workspace import-user-state`

No reinstall required.

## Decommission

If you stop using Sauce, your enterprise env decommission process:

1. Final backup → delivered to a destination of your choice
2. 30-day reversible-deletion window
3. Permanent deletion (cryptographic erasure of all KMS keys) — affects all data including backups
4. Decommission attestation document delivered

## Contact

- **Enterprise sales**: enterprise@saucetech.io
- **Existing customer support**: your dedicated success contact, or support@saucetech.io
- **Privacy / data requests**: privacy@saucetech.io
- **Security disclosures**: security@saucetech.io (PGP key on request)
