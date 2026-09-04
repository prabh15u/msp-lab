# Setup and operating guide
Run all commands in PowerShell from this repository's root. Install Azure CLI and OpenTofu 1.12.6 first. Provider constraints stay on AzureRM 4.x to avoid an unreviewed major upgrade.

## 1. Azure login and prerequisites
Use a sandbox subscription. The bootstrap operator needs Contributor plus Role Based Access Control Administrator (or Owner) to create resources and assign roles. Subsequent customer operations need Contributor; GitHub gets Reader.
```powershell
az login
az account set --subscription YOUR-SUBSCRIPTION-UUID
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
$env:ARM_TENANT_ID = az account show --query tenantId -o tsv
$env:TF_VAR_subscription_id = $env:ARM_SUBSCRIPTION_ID
az ad signed-in-user show --query id -o tsv
az provider register --namespace Microsoft.Storage --wait
az provider register --namespace Microsoft.Network --wait
az provider register --namespace Microsoft.ManagedIdentity --wait
```
Provider registration is an explicit one-time administrative action because the customer identity has no subscription-wide registration permission.

## 2. Bootstrap state storage
```powershell
Copy-Item environments/bootstrap/terraform.tfvars.example environments/bootstrap/terraform.tfvars
# Edit tfvars: subscription UUID, unique lowercase storage name, signed-in user object ID.
tofu -chdir=environments/bootstrap init
tofu -chdir=environments/bootstrap validate
tofu -chdir=environments/bootstrap plan -out=bootstrap.tfplan
tofu -chdir=environments/bootstrap apply bootstrap.tfplan
```
The initial state lives locally and must be protected until migrated. RBAC propagation can take several minutes; retry initialization if storage access returns 403. Shared keys and anonymous blob access are disabled. The public storage endpoint is reachable for GitHub-hosted runners, but requires Entra authorization.

Migrate the bootstrap itself to the platform container after storage exists:
```powershell
$stateName = tofu -chdir=environments/bootstrap output -raw storage_account_name
@'
terraform {
  backend "azurerm" {
    use_azuread_auth = true
  }
}
'@ | Set-Content environments/bootstrap/backend.tf
@"
resource_group_name = "rg-msp-lab-state"
storage_account_name = "$stateName"
container_name = "platform"
key = "bootstrap.tfstate"
"@ | Set-Content environments/bootstrap/backend.hcl
tofu -chdir=environments/bootstrap init -migrate-state -backend-config=backend.hcl
tofu -chdir=environments/bootstrap state list
```
Confirm the migration prompt; keep a secure backup until you verify the remote state. Commit backend.tf (no secrets), but never backend.hcl or state backups.

## 3. First customer
Copy the backend example, set the storage name, then:
```powershell
Copy-Item customers/summit-property-management/lab/backend.hcl.example customers/summit-property-management/lab/backend.hcl
# Edit backend.hcl with the actual storage name.
tofu -chdir=customers/summit-property-management/lab init -backend-config=backend.hcl
tofu -chdir=customers/summit-property-management/lab validate
tofu -chdir=customers/summit-property-management/lab plan -out=customer.tfplan
tofu -chdir=customers/summit-property-management/lab show -json customer.tfplan | Set-Content work-plan.json
python policies/check_plan.py work-plan.json
Remove-Item work-plan.json
tofu -chdir=customers/summit-property-management/lab apply customer.tfplan
```
The plan guard requires Python 3. Alternatively review the plan manually before local apply. Expected initial customer plan: nine resources (one RG, one VNet, two subnets, two NSGs, two associations). No compute.

## 4. GitHub OIDC
First create your GitHub repository and push this folder. Local initialization:
```powershell
git init -b main
git add .
git commit -m "Add minimal Azure MSP lab foundation"
# After creating an empty GitHub repository:
git remote add origin https://github.com/YOUR-OWNER/YOUR-REPO.git
git push -u origin main
```
Use your normal GitHub sign-in. No Azure credentials go into Git.

Create a GitHub environment named **summit-lab**. Restrict deployment branches to **main**, enable required reviewers if your GitHub plan supports it, protect main, and require code review of workflow and IaC changes. Configure this before enabling the Azure workflow: an environment OIDC subject does not itself restrict the branch.

Now create the identity using your local operator login:
```powershell
Copy-Item environments/github-identity/backend.hcl.example environments/github-identity/backend.hcl
Copy-Item environments/github-identity/terraform.tfvars.example environments/github-identity/terraform.tfvars
# Fill in storage name, subscription and exact OWNER/REPO.
tofu -chdir=environments/github-identity init -backend-config=backend.hcl
tofu -chdir=environments/github-identity validate
tofu -chdir=environments/github-identity plan -out=identity.tfplan
tofu -chdir=environments/github-identity apply identity.tfplan
tofu -chdir=environments/github-identity output
```
Set these GitHub **environment variables**, not secrets:
- ARM_CLIENT_ID: identity output client_id
- ARM_TENANT_ID: identity output tenant_id
- ARM_SUBSCRIPTION_ID: subscription UUID
- STATE_STORAGE_ACCOUNT: bootstrap storage name

The federated subject is exactly `repo:OWNER/REPO:environment:summit-lab`; issuer is GitHub Actions and audience is AzureADTokenExchange. GitHub requests a short-lived OIDC token directly for OpenTofu. No client secret, storage key or azure/login step is needed.

Run **Azure customer plan** manually on main. It only plans. Reader on the customer RG permits refresh; Blob Data Contributor on only this customer's container permits backend locking. That storage permission can modify customer state, so workflow review still matters. The identity cannot manage platform state or provision resources. Local apply remains the deployment path.

## 5. Destroy
Keep state and the bootstrap until customer cleanup is finished. Use your local operator login, not the read-only GitHub identity.
```powershell
tofu -chdir=environments/github-identity plan -destroy -out=destroy.tfplan
tofu -chdir=environments/github-identity apply destroy.tfplan
tofu -chdir=customers/summit-property-management/lab plan -destroy -out=destroy.tfplan
tofu -chdir=customers/summit-property-management/lab apply destroy.tfplan
# Equivalent interactive customer command:
# tofu -chdir=customers/summit-property-management/lab destroy
```
Identity first: its configuration looks up the customer resource group. Keep bootstrap for reuse; only its storage continues accruing usage.

For full teardown, first archive any needed state securely, remove the bootstrap backend.tf file, then run `tofu -chdir=environments/bootstrap init -migrate-state` to copy state back locally. Confirm local state with `state list`. Remove the storage account's explicit `prevent_destroy` guard, then run `plan -destroy -out=destroy.tfplan` and `apply destroy.tfplan` in the bootstrap directory. This deletes all remaining containers and state storage. Do not destroy remote storage while it is still the active backend.

## Sources
- [OpenTofu Azure backend](https://opentofu.org/docs/language/settings/backends/azurerm/)
- [GitHub OIDC with Azure](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure)
- [AzureRM provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

