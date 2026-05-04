# /apply <env>

Apply a Terraform plan with safety gates appropriate to the environment.

## Usage
```
/apply dev | /apply sit | /apply staging | /apply prod
```

## Steps

1. **Verify a plan exists:**
```bash
ls -la accounts/<account>/<env>/tfplan
```
If no `tfplan` exists, instruct the user to run `/plan <env>` first and stop.

2. **Safety gate — staging:**
Display:
```
You are about to apply changes to STAGING. Type "yes" to proceed.
```
Wait for "yes". Any other input: abort.

3. **Safety gate — prod:**
Display:
```
⚠️  PRODUCTION APPLY
You are about to apply changes to PRODUCTION.
Type "CONFIRM PROD" to proceed.
```
Wait for exactly "CONFIRM PROD". Any other input: abort.

4. **Apply:**
```bash
cd accounts/<account>/<env>
terraform apply tfplan
```

5. **Cleanup:**
```bash
rm accounts/<account>/<env>/tfplan
```

6. Summarize all resources created / modified / destroyed with their names.
