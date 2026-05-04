# Tagging Standards

All AWS resources managed by Terraform must carry these five tags.

## Required Tags

| Tag | Source | Example |
|---|---|---|
| `Environment` | `var.environment` | `prod` |
| `Project` | `var.project` | `myapp` |
| `Owner` | `var.owner` | `platform-team` |
| `CostCenter` | `var.cost_center` | `engineering` |
| `ManagedBy` | literal `"terraform"` | `terraform` |

## Apply via default_tags (not per-resource)

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
    }
  }
}
```

## Per-Resource Tags

Only add resource-level tags for the `Name` tag (resource-specific):
```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}
```

## Anti-Pattern

```hcl
# ❌ Don't repeat default_tags on individual resources
tags = {
  Environment = var.environment  # already in default_tags
  Project     = var.project      # already in default_tags
}
```

## Global Resources

Resources in `global/` use `Environment = "global"` as a literal string.
