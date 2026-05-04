# Naming Conventions

Pattern: `{project}-{environment}-{service}-{descriptor}`

## Examples

| Resource | Name |
|---|---|
| VPC | `myapp-dev-vpc` |
| EKS cluster | `myapp-dev-eks` |
| RDS instance | `myapp-dev-db` |
| RDS security group | `myapp-dev-rds-sg` |
| S3 state bucket | `myapp-terraform-state-123456789012` |
| SQS queue | `myapp-dev-main` |
| SQS DLQ | `myapp-dev-main-dlq` |
| SNS topic | `myapp-dev-alerts` |
| Lambda | `myapp-dev-example` |
| CloudWatch log group | `/myapp/dev/eks` |

## Rules
- All lowercase, words separated by hyphens
- No underscores in resource names (underscores are for Terraform identifiers only)
- Environments: `dev`, `sit`, `staging`, `prod` — no abbreviation variants
- Max 63 characters (S3 bucket limit)
- Globally unique resources (S3): append account ID suffix

## Terraform Identifiers
Use `snake_case` for all resource/variable/output identifiers:
- `resource "aws_s3_bucket" "terraform_state"` ✅
- `variable "vpc_cidr"` ✅
- `resource "aws_s3_bucket" "terraform-state"` ❌

## Name Tag
The `Name` tag should always match the resource name:
```hcl
tags = {
  Name = "${var.project}-${var.environment}-vpc"
}
```
