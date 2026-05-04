# Terraform State Rules

State files are sacred. Mistakes here cause resource orphaning, data loss, and unrecoverable situations.

## Never Do
- ❌ Manually edit `.tfstate` files
- ❌ Run `terraform state rm` without peer review and a documented reason
- ❌ Apply with a local `-state` flag in prod
- ❌ Try to work around DynamoDB state locks — if locked, investigate before force-unlocking
- ❌ Delete the S3 state bucket or DynamoDB lock table

## Refactoring Resources (use moved blocks)

```hcl
moved {
  from = aws_s3_bucket.old_name
  to   = aws_s3_bucket.new_name
}
```
Apply, verify no unintended changes, then remove the `moved` block and commit.

## Importing Existing Resources

```bash
# 1. Write the resource block in main.tf first
# 2. Import
terraform import aws_s3_bucket.my_bucket my-existing-bucket-name
# 3. Verify — plan must show 0 changes
terraform plan -var-file=terraform.tfvars
```

## State Key Map

| Environment | State key |
|---|---|
| dev | `non-prod/dev/terraform.tfstate` |
| sit | `non-prod/sit/terraform.tfstate` |
| staging | `prod/staging/terraform.tfstate` |
| prod | `prod/prod/terraform.tfstate` |
| global/iam | `global/iam/terraform.tfstate` |
| global/route53 | `global/route53/terraform.tfstate` |
| global/security | `global/security/terraform.tfstate` |
| bootstrap | local state only (chicken-and-egg) |

## Force Unlock (emergency only)

Only if you are certain no other apply is in progress:
```bash
terraform force-unlock <LOCK_ID>
```
Document the reason in a git commit.
