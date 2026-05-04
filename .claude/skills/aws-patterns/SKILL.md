# AWS Infrastructure Patterns

Situational intelligence for common AWS IaC decisions. Load when designing or reviewing infrastructure.

## VPC CIDR Allocation

Non-overlapping /16 blocks per environment (enables future VPC peering):

| Environment | VPC CIDR |
|---|---|
| dev | 10.10.0.0/16 |
| sit | 10.20.0.0/16 |
| staging | 10.30.0.0/16 |
| prod | 10.40.0.0/16 |

Subnet breakdown per AZ within a /16:
- Private (app): `.1.0/24`, `.2.0/24`, `.3.0/24`
- Public (ALB/NAT): `.101.0/24`, `.102.0/24`, `.103.0/24`
- Intra (DB, no internet): `.201.0/24`, `.202.0/24`, `.203.0/24`

## Multi-AZ Decision Matrix

| Resource | Non-prod | Prod | Reason |
|---|---|---|---|
| NAT Gateway | `single_nat_gateway = true` | `single_nat_gateway = false` | ~$35/mo per AZ |
| RDS | `multi_az = false` | `multi_az = true` | 2× cost, required for HA |
| ElastiCache | 1 node | 2–3 nodes | 1 node = no failover |
| EKS nodes | 1–2 nodes | 3+ across 3 AZs | AZ failure tolerance |

## EKS Node Sizing

| Env | Instance | Min | Desired | Max |
|---|---|---|---|---|
| dev | t3.medium | 1 | 1 | 3 |
| sit | t3.large | 1 | 2 | 3 |
| staging | m5.large | 2 | 3 | 6 |
| prod | m5.xlarge | 3 | 5 | 20 |

## RDS Sizing

| Env | Class | Multi-AZ | Storage | Retention |
|---|---|---|---|---|
| dev | db.t3.micro | No | 20 GB | 1 day |
| sit | db.t3.small | No | 50 GB | 3 days |
| staging | db.m5.large | Yes | 100 GB | 7 days |
| prod | db.m5.2xlarge | Yes | 500 GB | 35 days |

## Least-Privilege IAM Pattern

```hcl
resource "aws_iam_policy" "app" {
  name = "${var.project}-${var.environment}-app"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::${var.project}-${var.environment}-*/*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/${var.environment}/*"
      }
    ]
  })
}
```

## CloudFront + WAF Placement

WAF for CloudFront must be created in `us-east-1` regardless of main region:

```hcl
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "waf" {
  source    = "..."
  providers = { aws = aws.us_east_1 }
  scope     = "CLOUDFRONT"
}
```

Recommended managed rules (in priority order):
1. `AWSManagedRulesCommonRuleSet` — OWASP Top 10
2. `AWSManagedRulesKnownBadInputsRuleSet` — known attack patterns
3. `AWSManagedRulesAmazonIpReputationList` — AWS threat intelligence

## Secrets Manager Pattern (never store secrets in tfvars)

```hcl
# Create the secret shell — value is set manually or by the app
resource "aws_secretsmanager_secret" "app" {
  name = "${var.project}/${var.environment}/app"
}

# Application reads from Secrets Manager at runtime via SDK
# Never do: resource "aws_secretsmanager_secret_version" with secret_string = var.db_password
```

## Bootstrap Sequence for New Users

1. `cd bootstrap && terraform init` (runs against local state)
2. `terraform apply -var="state_bucket_name=<name>" -var="project=<name>" -var="owner=<team>"`
3. Copy `state_bucket_name` output
4. `find . -name "backend.tf" -exec sed -i 's/REPLACE_WITH_STATE_BUCKET_NAME/<bucket>/g' {} \;`
5. `terraform init` in each environment (migrates to remote state)
6. `/plan dev` to verify
