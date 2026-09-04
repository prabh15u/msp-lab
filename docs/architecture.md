# Architecture and extension
Three independently operated roots separate platform state, customer infrastructure and federation. Bootstrap and identity states use the platform container; the customer uses its own container and lab.tfstate key. Azure Blob leases provide backend locking. Never use -lock=false to bypass another operator.

For another customer: add a dedicated container in bootstrap, copy the customer root to a new slug, assign non-overlapping CIDRs, use a new backend key/container, and provision a dedicated identity with an exact environment subject and narrowly scoped roles. Never point two roots at the same state blob.

Customer data-plane isolation is not complete MSP isolation: the lab shares an Azure subscription and administrator. No cross-tenant delegation or Azure Lighthouse is implemented. Real deployments should establish customer-owned subscriptions, access review, backup/restore drills and support processes.

The module exposes RG, VNet and subnet IDs. All subnets receive NSGs; internet-originating inbound traffic is explicitly denied. Azure default NSG rules still allow VNet traffic and outbound internet. This is not zero-trust segmentation or guaranteed egress access; there is no explicit outbound connectivity resource. Add deliberate egress and segmentation policies before compute.

Bootstrap storage enables versioning and seven-day delete retention. This is recovery assistance, not immutable backup. Stored state may contain sensitive values; access to it is privileged. Public endpoint access is a lab tradeoff for hosted runners. Private endpoints require network access for the runner and introduce cost.

The root configuration keeps provider registration explicit. Native AzureRM resources keep the initial graph small; introduce pinned Azure Verified Modules when their tested service configuration provides a clear benefit. No budget or hard spending cap is provisioned in v1; configure Azure Cost Management alerts for your subscription. Budget alerts do not stop spending.

