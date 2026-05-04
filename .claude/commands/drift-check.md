# /drift-check <env>

Detect differences between Terraform state and actual AWS infrastructure.

## Usage
```
/drift-check dev | /drift-check prod
```

## Steps

1. Navigate to the environment directory (same path map as `/plan`)

2. Run plan with exit code tracking:
```bash
terraform init
terraform plan -var-file=terraform.tfvars -detailed-exitcode -refresh=true 2>&1 | tee /tmp/drift-output.txt
EXITCODE=${PIPESTATUS[0]}
```

Exit codes:
- `0` = No drift
- `1` = Error (show error and stop)
- `2` = Drift detected

3. Interpret:
   - Exit 0: `✅ No drift. Infrastructure matches Terraform state.`
   - Exit 2: `⚠️ Drift detected:` — list each changed resource with the type of change

4. For each drifted resource, suggest:
   - Modified outside Terraform → `terraform apply -target=<resource>` to restore
   - Deleted outside Terraform → `terraform apply -target=<resource>` to recreate
   - New unmanaged resource → `terraform import <resource_type>.<name> <aws_id>` to adopt

5. Clean up:
```bash
rm -f /tmp/drift-output.txt
```
