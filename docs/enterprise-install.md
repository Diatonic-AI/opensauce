# Enterprise Install — Control Node + Tenant Onboarding

This is the path for enterprises standing up their own Sauce control plane: register with Sauce Global, own a domain, manage tenants under it.

Single-machine / personal installs should use [`user-install.md`](user-install.md) instead.

## Prerequisites

- A DNS domain you control (e.g. `acme.example.com`)
- A Linux host or Kubernetes cluster for the control node:
  - **Single-node**: 4 vCPU, 8 GB RAM, 50 GB disk minimum
  - **Cluster**: any conformant Kubernetes ≥ 1.28 (EKS / AKS / GKE / on-prem)
- A Sauce Global enterprise license key (request at [https://saucetech.io/enterprise](https://saucetech.io/enterprise))
- An OIDC identity provider (Auth0, Okta, Keycloak, or cloud-native Entra / Cognito / Cloud Identity)
- A Postgres-compatible database for the control plane state (≥ 15.x recommended)
- An object store (S3 / Azure Blob / GCS) for tenant artifacts

## Architecture overview

```
Sauce Global (Diatonic-AI managed)
       │
       ▼  enrollment + license + telemetry
┌─────────────────────────────────────────┐
│ Your Enterprise Control Node            │
│   ┌─────────────────────────────────┐   │
│   │ Domain: acme.example.com        │   │
│   │   ├── Workspace: acme-platform  │   │
│   │   │     ├── Tenant: globex      │   │
│   │   │     └── Tenant: initech     │   │
│   │   └── Workspace: acme-marketing │   │
│   └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
       │
       ▼  per-user installs phone home here
┌─────────────────────────────────────────┐
│ Edge User Installs                      │
│   ├── Laptop A (tenant: globex)         │
│   ├── Laptop B (tenant: globex)         │
│   └── Laptop C (tenant: initech)        │
└─────────────────────────────────────────┘
```

## Single-node install

For small enterprises or pilot deployments. One Linux host hosts the entire control plane.

### 1. Install the binaries

```sh
sudo dpkg -i sauce-framework_0.1.0-1_amd64.deb
```

The `.deb` ships the 24 user-facing binaries. For the cluster / ops / dusa tiers (needed for control-node operation), see the [tier downloads page](https://saucetech.io/tiers) — these install side-by-side and require a per-tier license entitlement.

### 2. Bootstrap the enterprise

```sh
sudo sauce enterprise bootstrap \
  --domain acme.example.com \
  --license-key $SAUCE_LICENSE_KEY \
  --oidc-issuer https://auth.acme.example.com/realms/acme \
  --db-url postgresql://sauce:$DB_PASS@localhost:5432/sauce \
  --object-store s3://acme-sauce-artifacts \
  --control-plane-endpoint https://control.acme.example.com
```

This:
1. Validates the license key against Sauce Global
2. Creates the `Enterprise` and root `Domain` records
3. Provisions the systemd units (`sauce-control.service`, `sauce-edge.service`, `sauce-policy.service`)
4. Issues the enterprise root certificate (used to sign tenant tokens)
5. Registers the control node with Sauce Global

### 3. Verify

```sh
sudo systemctl status sauce-control
sauce enterprise info
sauce global ping
```

Expected: control plane healthy, registered with Sauce Global, license valid.

## Kubernetes install

For production / larger enterprises. Run the control plane as a stateful service in your cluster.

### 1. Add the Helm repo

```sh
helm repo add opensauce https://charts.opensauce.diatonic.ai
helm repo update
```

### 2. Install the operator

```sh
helm install sauce-operator opensauce/sauce-k8s-operator \
  --namespace sauce-system \
  --create-namespace \
  --set licenseKey=$SAUCE_LICENSE_KEY
```

### 3. Create the Enterprise CRD

```yaml
# enterprise.yaml
apiVersion: sauce.diatonic.ai/v1
kind: Enterprise
metadata:
  name: acme-corp
spec:
  primaryDomain: acme.example.com
  globalControlPlane: https://global.saucetech.io
  oidcIssuer: https://auth.acme.example.com/realms/acme
  database:
    secretRef: sauce-db-credentials
  objectStore:
    type: s3
    bucket: acme-sauce-artifacts
    region: us-east-1
```

```sh
kubectl apply -f enterprise.yaml -n sauce-system
```

The operator reconciles → creates Domain + Workspace CRDs, issues certs, registers with Sauce Global.

## Adding workspaces + tenants

### Workspace

```yaml
apiVersion: sauce.diatonic.ai/v1
kind: Workspace
metadata:
  name: acme-platform
  namespace: sauce-system
spec:
  domain: acme.example.com
  cluster: us-east-1-prod
  tenancyMode: pool         # or: silo
```

### Tenant

```yaml
apiVersion: sauce.diatonic.ai/v1
kind: Tenant
metadata:
  name: tenant-globex
  namespace: acme-platform
spec:
  workspace: acme-platform
  billingId: ACME-001
  isolationLevel: standard  # standard | hardened | regulated
  initialAdmins:
    - email: admin@globex.example.com
```

The operator handles namespace creation (silo) or tenant-row insertion (pool), DB row-level security setup, secret bootstrap, and ingress route creation.

## Onboarding edge users

Each edge user enrolls into a tenant via:

```sh
# admin generates a one-time enrollment token
sauce tenant enroll-token --tenant globex --user alice@globex.example.com

# user installs Sauce on their machine, then:
sauce enroll --token $ENROLLMENT_TOKEN
```

After enrollment:
- The user's local install registers with the enterprise control node
- The control node registers the user-install with Sauce Global
- Local `sauce init` provisions per-user `.sauce/` with tenant-scoped credentials
- All future telemetry from this install routes through the enterprise control node

## Upgrade

### Single-node
```sh
curl -fsSL -O https://github.com/Diatonic-AI/opensauce/releases/latest/download/sauce-framework_<version>-1_amd64.deb
sudo dpkg -i sauce-framework_<version>-1_amd64.deb
sudo systemctl restart sauce-control
sauce enterprise check-version
```

### Kubernetes
```sh
helm upgrade sauce-operator opensauce/sauce-k8s-operator
kubectl rollout status -n sauce-system deployment/sauce-operator
```

The operator handles staged rollout: control-plane first, then per-namespace edge proxies, then announces availability for tenant migrations.

## Backup + DR

```sh
sauce enterprise backup --output s3://acme-sauce-backups/$(date +%Y-%m-%d)
```

Backed up: enterprise CRDs, all workspace/tenant configs, root cert + signing keys (encrypted), control plane DB snapshot, audit log (last 90 days).

DR restore: see the [DR runbook](https://saucetech.io/dr) (enterprise license required to access).

## Compliance

Each enterprise install can elect compliance mode at bootstrap:

| Mode | Effects |
|---|---|
| `standard` | Default. Full feature set. SOC 2 baseline. |
| `hardened` | Capability gates locked closed. No `fs_write` / `bash_run` for tenants. Audit log replicated to immutable storage. |
| `regulated` | Hardened + dedicated KMS keys per tenant + silo-only mode + FIPS-validated TLS. HIPAA / FedRAMP track. |

```sh
sauce enterprise set-compliance hardened
```

## Sauce Global integration

Every enterprise install is tracked by Sauce Global for:
- License compliance (seat count, feature entitlements)
- Version reconciliation (which versions across the fleet)
- Critical security advisories (CVE notifications scoped to your installed versions)
- Optional aggregated telemetry (opt-in per `[control_plane.share_telemetry]`)

You retain full control: telemetry is opt-in, audit logs are local-first, your tenants' data never leaves your infrastructure.

To verify the registration:

```sh
sauce global status
# → Registered: 2026-05-06T12:00Z
#   License: enterprise-pro (50 seats)
#   Version: 0.1.0
#   Last sync: 2 minutes ago
```

## Troubleshooting

See [`troubleshooting.md`](troubleshooting.md) — has dedicated sections for control-node bring-up, license errors, OIDC misconfigurations, and Sauce Global registration issues.

For enterprise-license support: ai@diatonic.ai (or your dedicated success contact).
