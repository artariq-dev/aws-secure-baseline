# /docs [path]

Generate or update Terraform documentation using terraform-docs.

## Usage
```
/docs                          # run in current directory
/docs accounts/non-prod/dev    # run in specific path
```

## Prerequisites (install once)
```bash
brew install terraform-docs
```

## Steps

1. If no `.terraform-docs.yml` exists in the target directory, create it:
```yaml
formatter: markdown table

output:
  file: README.md
  mode: inject
  template: |-
    <!-- BEGIN_TF_DOCS -->
    {{ .Content }}
    <!-- END_TF_DOCS -->

settings:
  indent: 2
  required: true
  sensitive: true
```

2. If `README.md` doesn't exist, create one with placeholder markers:
```bash
cat > <path>/README.md << 'EOF'
# <env> Environment

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
EOF
```

3. Run terraform-docs:
```bash
terraform-docs <path>
```

4. Show what changed:
```bash
git diff <path>/README.md
```
