# Security Rules

Non-negotiable for all AWS Terraform in this repository.

## Credentials
- ❌ Never hardcode AWS access keys, secret keys, or tokens in any file
- ✅ GitHub Actions authenticates via OIDC roles (see `global/iam/`)
- ✅ Application secrets go in Secrets Manager, not `.tfvars`

## Network Security
- ❌ No security group with `cidr_blocks = ["0.0.0.0/0"]` on port 22 or 3389
- ❌ No security group with `cidr_blocks = ["0.0.0.0/0"]` unless it's a public ALB/CloudFront listener on 443
- ✅ EKS: `cluster_endpoint_public_access = false`
- ✅ RDS: `publicly_accessible = false` (default, but verify)
- ✅ Lambda in prod/staging: deploy inside VPC

## Encryption at Rest
- ✅ S3: `sse_algorithm = "aws:kms"`
- ✅ RDS: `storage_encrypted = true`
- ✅ ElastiCache: `at_rest_encryption_enabled = true`
- ✅ SQS: `kms_master_key_id = "alias/aws/sqs"`
- ✅ SNS: `kms_master_key_id = "alias/aws/sns"`
- ✅ Secrets Manager: `kms_key_id = "alias/aws/secretsmanager"`

## Encryption in Transit
- ✅ ElastiCache: `transit_encryption_enabled = true`
- ✅ CloudFront: `viewer_protocol_policy = "redirect-to-https"`
- ✅ ALB listeners on 80: redirect to 443

## S3 Public Access Block (required on every bucket)
```hcl
resource "aws_s3_bucket_public_access_block" "<name>" {
  bucket                  = aws_s3_bucket.<name>.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## IAM
- ❌ No policy with `"Action": "*"` and `"Resource": "*"` together
- ✅ Use IAM roles, not users with access keys, for service-to-service auth

## Deletion Protection (staging and prod only)
- `deletion_protection = true` on RDS
- `prevent_destroy = true` lifecycle on S3 state bucket, RDS, EKS cluster
- `rds_skip_final_snapshot = false`
