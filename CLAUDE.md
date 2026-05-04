# CLAUDE.md — Terraform AWS

## Karpathy Principles

### 1. Think Before Coding
Don't assume. Don't hide confusion. Surface tradeoffs.
- State assumptions explicitly before writing any Terraform
- Present multiple interpretations when a request is ambiguous
- Ask for clarification rather than guessing
- For any destructive change, state the blast radius before proceeding

### 2. Simplicity First
Minimum code that solves the problem. Nothing speculative.
- No unrequested variables, resources, or modules
- No abstraction layers unless they eliminate real duplication
- No "we might need this later" patterns
- Test: would a senior engineer call this overcomplicated?

### 3. Surgical Changes
Touch only what you must. Clean up only your own mess.
- When modifying an environment's `main.tf`, preserve adjacent formatting
- Don't refactor environments you're not working in
- Only remove unused variables that your own changes introduced
- Preserve existing `terraform.tfvars` values unless the task explicitly changes them

### 4. Goal-Driven Execution
Define success criteria. Loop until verified.
- Convert vague requests into specific targets before starting: "update the infra" → "add Redis to dev, no other changes"
- State verification criteria upfront: "done when `terraform plan` shows 0 changes after apply"
- Run verification independently before declaring a task complete

---

## Context Navigation

1. Always query knowledge graph first: `/graphify query "your question"`
2. Only read raw files if explicitly asked to "read the file"
3. Use `graphify-out/wiki/index.md` as your navigation entrypoint

### Integrating graphify with this Terraform repo

Run `/graphify` to build a knowledge graph of the entire infrastructure layout. The graph surfaces:
- Which modules are shared across environments
- Security rule coverage per environment
- Module version consistency across accounts
- Variable naming patterns and drift

**Useful queries:**
```
/graphify query "which environments have WAF enabled"
/graphify query "show all RDS configurations"
/graphify query "find all references to module vpc"
/graphify query "which environments use single NAT gateway"
```

---

## Project Conventions

### Targeting environments
- Always confirm the target environment before editing any `.tf` file
- For `accounts/prod/` changes, require the user to confirm explicitly before applying
- Run `/plan <env>` before `/apply <env>` — no exceptions

### Module version pinning
- Terraform Registry: `version = "5.8.1"` (exact semver)
- Git source: `?ref=v1.0.0` (exact tag)
- Never use floating versions or `latest`

### State discipline
- Never manually edit `.tfstate` files
- Use `moved` blocks for renaming/reorganizing resources
- Each environment has its own isolated state file — see `.claude/rules/state.md`

### Bootstrap sequence (for new users forking this template)
1. `cd bootstrap && terraform init && terraform apply`
2. Copy `state_bucket_name` from outputs
3. `find . -name "backend.tf" -exec sed -i 's/REPLACE_WITH_STATE_BUCKET_NAME/<bucket>/g' {} \;`
4. `terraform init` in each environment directory
5. `/plan dev` to verify
