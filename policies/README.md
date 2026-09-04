# Initial guardrails
check_plan.py rejects managed resource types outside the customer foundation allowlist. The manual Azure workflow enforces it against a saved plan. It is a narrow cost/scope check, not Azure Policy or a full security scanner. It does not validate pricing, rule changes, CIDRs or future resource SKUs. Review the human-readable plan too.

Bootstrap and identity are intentionally excluded: their resources are reviewed by the operator. The workflow cannot apply. Do not broaden the allowlist without reviewing costs and the access model.

