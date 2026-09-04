# Validation record

Validated locally with OpenTofu 1.12.6 and AzureRM 4.81.0:

- Recursive formatting check passed.
- Bootstrap initialized without its backend and passed `tofu validate`.
- GitHub identity initialized without its backend and passed `tofu validate`.
- Customer root and reusable module initialized without the backend and passed `tofu validate`.
- Provider lock files were generated for all three roots and are included.

No Azure login, live plan, apply, state migration or destroy was performed. Those require your Azure subscription and permissions. GitHub workflows have not run remotely. Validation confirms configuration/provider schema consistency, not cloud authorization or deployment success.
