# /security-scan [path]

Run tfsec and checkov against Terraform code.

## Usage
```
/security-scan                     # scans entire repo
/security-scan accounts/non-prod   # scans specific path
```

## Prerequisites (install once)
```bash
brew install tfsec
pip install checkov
```

## Steps

1. Run tfsec:
```bash
tfsec <path> --format json --out /tmp/tfsec-results.json --minimum-severity LOW
```

2. Run checkov:
```bash
checkov -d <path> --framework terraform --output json --output-file /tmp/checkov-results.json
```

3. Display results grouped by severity:
```
## CRITICAL (block merge)
[file:line — finding description]

## HIGH
[findings]

## MEDIUM
[findings]

## LOW / INFO
X findings (not listed — see raw output if needed)

## Summary
tfsec:   X critical, Y high, Z medium
checkov: X critical, Y high, Z medium
```

4. Clean up temp files:
```bash
rm -f /tmp/tfsec-results.json /tmp/checkov-results.json
```
