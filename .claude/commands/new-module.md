# /new-module <name>

Scaffold a new Terraform module stub following project conventions.

## Usage
```
/new-module vpc-endpoints
/new-module custom-alb
```

## Steps

1. Create directory:
```bash
mkdir -p modules/<name>
```

2. Create `modules/<name>/main.tf`:
```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Add resource blocks here
```

3. Create `modules/<name>/variables.tf`:
```hcl
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Add module-specific variables here
```

4. Create `modules/<name>/outputs.tf`:
```hcl
# Add outputs here
```

5. Create `modules/<name>/README.md`:
```markdown
# <name>

## Usage

\`\`\`hcl
module "<name>" {
  source = "git::https://github.com/<YOUR_ORG>/terraform-aws-<name>.git?ref=v1.0.0"

  project     = var.project
  environment = var.environment
}
\`\`\`

## Inputs

| Name | Description | Type | Required |
|---|---|---|---|
| project | Project name | string | yes |
| environment | Environment name | string | yes |

## Outputs

| Name | Description |
|---|---|
```

6. Remind the user:
   - Add a `module "<name>"` block to the relevant environment's `main.tf`
   - Set a version tag before publishing: `git tag v1.0.0 && git push origin v1.0.0`
