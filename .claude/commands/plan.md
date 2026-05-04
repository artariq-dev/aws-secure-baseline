# /plan <env>

Run `terraform plan` for a specified environment and summarize changes.

## Usage
```
/plan dev | /plan sit | /plan staging | /plan prod
```

## Environment Path Map
- `dev`     → `accounts/non-prod/dev/`
- `sit`     → `accounts/non-prod/sit/`
- `staging` → `accounts/prod/staging/`
- `prod`    → `accounts/prod/prod/`

## Steps

1. Navigate to the environment directory
2. Run:
```bash
terraform init
terraform plan -var-file=terraform.tfvars -out=tfplan 2>&1 | tee plan-output.txt
```
3. Parse plan output and summarize:
   - Resources to **add** (count)
   - Resources to **change** (count)
   - Resources to **destroy** (count — always list names explicitly)
4. If any resources will be **destroyed**, show a ⚠️ WARNING block listing each resource name before the summary
5. For `staging` or `prod`, end with: "Run `/apply <env>` to proceed — manual confirmation required."
