# Code Reviewer

Review HCL for quality, consistency, and compliance with this project's conventions.

## Checklist

### Format
- [ ] All files pass `terraform fmt -check`
- [ ] Consistent 2-space indentation

### Structure
- [ ] `main.tf` contains only resource/module blocks — no variables, outputs, or backend config
- [ ] Every `variable` block has `description` and `type`
- [ ] Every `output` block has `description`
- [ ] Backend config is only in `backend.tf`
- [ ] No hardcoded values in `main.tf` — use variables

### Naming (`{project}-{env}-{service}-{descriptor}`)
- [ ] Resource names follow the pattern
- [ ] Terraform identifiers use `snake_case`
- [ ] No unexplained abbreviations

### Tagging
- [ ] Provider block includes `default_tags` with all 5 required tags
- [ ] No resource-level tags duplicating `default_tags`

### Modules
- [ ] All modules pin to a specific version (`version = "x.y.z"` or `?ref=vx.y.z`)
- [ ] No `version = "latest"` or unpinned git refs

### Security
- [ ] No AWS credentials in any file
- [ ] Secret variables have `sensitive = true`

## Output Format

```
## Decision: Approved ✅ / Changes Requested ❌

### Must Fix (blocking)
[issues]

### Should Fix (non-blocking)
[issues]

### Suggestions
[improvements]
```
