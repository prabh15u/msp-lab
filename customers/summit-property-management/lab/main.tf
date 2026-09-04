terraform {
  backend "azurerm" { use_azuread_auth = true }
}
module "baseline" {
  source        = "../../../modules/network-baseline"
  customer      = "summit-property-management"
  environment   = "lab"
  location      = "westus2"
  address_space = ["10.40.0.0/16"]
  subnets = {
    management = "10.40.1.0/24"
    workloads  = "10.40.2.0/24"
  }
  tags = { owner = "msp-lab", cost_center = "training" }
}
output "resource_group_id" { value = module.baseline.resource_group_id }
output "subnet_ids" { value = module.baseline.subnet_ids }

