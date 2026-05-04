# /cost-estimate <env>

Estimate monthly AWS cost for an environment using infracost.

## Usage
```
/cost-estimate dev | /cost-estimate prod
```

## Prerequisites (install once)
```bash
brew install infracost
infracost auth login
```

## Steps

1. Navigate to the environment directory (same path map as `/plan`)

2. Run breakdown:
```bash
infracost breakdown --path . --terraform-var-file terraform.tfvars --format json --out-file /tmp/infracost.json
```

3. Display table:
```bash
infracost output --path /tmp/infracost.json --format table
```

4. Flag individual resources costing >$50/month by parsing `/tmp/infracost.json` for `monthlyCost > 50`.

5. Clean up:
```bash
rm -f /tmp/infracost.json
```
