terraform {
  backend "azurerm" {
    use_azuread_auth = true
  }
}

variable "application_name" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "github_environment" {
  type = string
}

module "github_identity" {
  source = "../../modules/github-identity"

  application_name   = var.application_name
  github_repository  = var.github_repository
  github_environment = var.github_environment

  github_owner_id = tostring(
    local.github_repository_metadata.owner.id
  )

  github_repository_id = tostring(
    local.github_repository_metadata.id
  )

}

output "client_id" {
  value = module.github_identity.client_id
}

output "principal_id" {
  value = module.github_identity.principal_id
}

output "tenant_id" {
  value = var.tenant_id
}