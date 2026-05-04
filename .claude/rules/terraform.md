# Terraform HCL Rules

## Version Requirements
- Terraform: `>= 1.6.0`
- AWS provider: `~> 5.0`
- Module versions: exact semver tag (`version = "5.8.1"`) or `?ref=vX.Y.Z` for git sources

## File Organization
- `main.tf` — resource and module blocks only
- `variables.tf` — all `variable` blocks; every variable needs `description` and `type`
- `outputs.tf` — all `output` blocks; every output needs `description`
- `backend.tf` — backend configuration only
- `terraform.tfvars` — environment values; never commit secrets here

## HCL Style
- Use `for_each` over `count` for resources that need individual addressing
- Use `moved` blocks instead of destroy/recreate when renaming or reorganizing resources
- Use `locals` for computed expressions referenced more than twice
- `depends_on` is a last resort — prefer implicit dependency through resource references

## Module Calls
- Registry: `source = "terraform-aws-modules/vpc/aws"` with `version = "5.8.1"`
- Git: `source = "git::https://github.com/<org>/<repo>.git?ref=v1.0.0"`
- No local path modules inside `accounts/` — use git sources

## Sensitive Values
- Mark all secret variables with `sensitive = true`
- Use Secrets Manager or SSM for runtime secrets — not `.tfvars`
- Never output sensitive values without `sensitive = true` on the output block

## Provider Config
- Always include `default_tags` (see tagging rules)
- Use `data "aws_caller_identity" "current" {}` — never hardcode account IDs
- Use `var.aws_region` in resource ARN strings — never hardcode region
