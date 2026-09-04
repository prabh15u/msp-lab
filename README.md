# MSP lab — Azure + OpenTofu + GitHub
An understandable, low-cost foundation for a multi-customer MSP. The fictional first customer is **summit-property-management**.

## Layout
- `environments/bootstrap`: state storage; starts with local state.
- `environments/github-identity`: customer-scoped managed identity, federation and RBAC.
- `customers/summit-property-management/lab`: independent customer root and state.
- `modules/network-baseline`: resource group, VNet, subnets and NSGs.
- `docs`: setup, architecture and teardown.
- `policies`: baseline rules and plan guard.
- `scripts`: local validation.
- `.github/workflows`: credential-free checks and manual OIDC plan.

Start with [the setup guide](docs/setup.md). Nothing has been deployed. Azure CLI and OpenTofu are prerequisites; GitHub is optional for local use.

## Cost boundary
No VMs, AKS, NAT gateway, VPN gateway, Bastion, firewall appliance, public IPs or log ingestion. State storage uses Standard LRS with a small recurring storage/transaction cost. This is not a guarantee of zero spend. Review each plan and your Azure Cost Management budget before applying.

## Design
Separate root modules and blob containers per customer; no workspaces as a security boundary. This version models customers in one Entra tenant/subscription. For real customers, prefer customer-owned subscriptions and identities. See [architecture](docs/architecture.md).

Azure Verified Modules are deliberately deferred: these few native resources are easier to inspect without additional abstraction. Evaluate AVM when adding more complex services; pin versions and review defaults/costs.

## Validation
```powershell
./scripts/validate.ps1
```
Run from the repository root. This downloads providers but does not authenticate or deploy. Commit generated `.terraform.lock.hcl` files; do not commit state, plans or local tfvars.

