"""Reject managed resource types beyond the minimal customer baseline."""
import json
import sys

ALLOWED = {
    "azurerm_resource_group",
    "azurerm_virtual_network",
    "azurerm_subnet",
    "azurerm_network_security_group",
    "azurerm_subnet_network_security_group_association",
}
with open(sys.argv[1], encoding="utf-8-sig") as handle:
    plan = json.load(handle)
violations = [
    change["address"]
    for change in plan.get("resource_changes", [])
    if change.get("mode") == "managed" and change["type"] not in ALLOWED
]
if violations:
    sys.exit("Disallowed resources: " + ", ".join(violations))
print("Customer resource-type guard passed.")

