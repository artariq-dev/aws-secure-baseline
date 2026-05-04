# terraform-aws — End-to-End Explainer

---

## What Is This Project?

This is a **production-grade, multi-account AWS security and infrastructure platform** written entirely in Terraform. It provisions a complete AWS environment — networking, compute, databases, CDN, and a full security baseline — across four isolated environments (dev, sit, staging, prod), with a CI/CD pipeline that plans and applies changes automatically.

The security layer is the centrepiece. Five dedicated security modules implement the AWS security baseline that most teams either skip entirely or bolt on as an afterthought: CloudTrail audit logging, GuardDuty threat detection, Security Hub compliance aggregation, AWS Config resource governance, and Service Control Policies that act as organisation-wide guardrails no account admin can override.

This is not a tutorial project. It is the kind of infrastructure setup that would take a senior team several weeks to build correctly from scratch.

---

## The Problem This Project Solves

### Problem 1: Security is always "we'll add it later"

Most AWS environments start with someone clicking through the console to get something running. Security services get enabled manually, inconsistently, or not at all. GuardDuty might be on in prod but not dev. CloudTrail might be logging but nobody set up alerts. Config rules exist but nobody checks the compliance dashboard.

By the time the team decides to fix this, there are four environments with different security postures, no audit trail of what changed, and no automated enforcement to prevent it from drifting again.

**This project solves it by making security the default.** Every environment gets the full security stack on day one, configured identically, managed as code.

### Problem 2: No guardrails against catastrophic mistakes

Without organisation-level controls, any IAM admin in any account can:
- Disable GuardDuty and CloudTrail (covering their tracks)
- Create public S3 buckets (data exposure)
- Launch EC2 instances with IMDSv1 (SSRF vulnerability)
- Leave the AWS Organisation entirely

These aren't theoretical risks. They happen in real environments.

**This project solves it with SCPs** — Service Control Policies attached at the AWS Organizations level. They are enforced by AWS itself, above the IAM layer. Even an account's root user cannot override them.

### Problem 3: No visibility when something goes wrong

Without centralised logging and alerting, you find out about security incidents from customers, not from your own monitoring. By then, the attacker has had hours or days of undetected access.

**This project solves it with layered detection:** CloudTrail captures every API call, GuardDuty analyses behaviour patterns, Security Hub aggregates findings from all sources, and EventBridge routes HIGH/CRITICAL alerts to SNS in real time.

### Problem 4: Environment drift

Dev, staging, and prod should be structurally identical — only the sizes and costs should differ. In practice, teams make "quick fixes" directly in the console in prod, and those changes never make it back to the other environments. Over time, prod becomes a snowflake that nobody fully understands.

**This project solves it with Terraform.** Every resource in every environment is defined in code. The CI/CD pipeline blocks direct console changes from persisting — the next `terraform apply` would revert them.

---

## Project Structure

```
terraform-aws/
├── bootstrap/                    # Run once: creates S3 state bucket + DynamoDB lock table
├── global/
│   ├── iam/                      # GitHub Actions OIDC roles (no stored credentials)
│   ├── route53/                  # DNS hosted zones
│   └── security/                 # Account-wide security baseline (calls security modules)
├── accounts/
│   ├── non-prod/
│   │   ├── dev/                  # Development environment
│   │   └── sit/                  # System Integration Testing environment
│   └── prod/
│       ├── staging/              # Pre-production environment
│       └── prod/                 # Live production environment
├── modules/
│   └── security/
│       ├── cloudtrail/           # Audit logging module
│       ├── guardduty/            # Threat detection module
│       ├── securityhub/          # Compliance aggregation module
│       ├── config/               # Resource governance module
│       └── scps/                 # Organisation guardrails module
└── .github/workflows/            # CI/CD: plan on PR, apply on merge, security scan
```

Each environment folder contains:
- `main.tf` — all infrastructure modules wired together
- `variables.tf` — variable declarations with descriptions and types
- `terraform.tfvars` — the actual values for that environment
- `backend.tf` — remote state configuration
- `outputs.tf` — values exported after apply

---

## What Gets Provisioned Per Environment

### Networking — VPC
A dedicated VPC per environment with three subnet tiers:

- **Public subnets** — load balancers and NAT gateways only. Internet-facing.
- **Private subnets** — EKS worker nodes. Outbound internet via NAT, no inbound.
- **Intra subnets** — databases and cache. No internet access at all, in either direction.

This is defence in depth. If an attacker compromises the public tier, they still cannot reach the database directly — there is no route between them.

### Compute — EKS
A Kubernetes cluster running in private subnets. The cluster API endpoint is private-only (`cluster_endpoint_public_access = false`) — unreachable from the internet. Managed node groups with configurable autoscaling.

### Compute — Lambda
A placeholder Lambda function ready to be replaced with your actual function. Environment variables injected from Terraform.

### Database — RDS PostgreSQL
PostgreSQL in the intra subnets. Accessible only from EKS worker nodes via security group rules. Master password managed by AWS Secrets Manager — never stored in Terraform state or code. Storage encrypted. Multi-AZ in prod, single instance in dev/sit to save cost. Deletion protection enabled in prod.

### Cache — ElastiCache Redis
Redis in the intra subnets. Encryption at rest and in transit both enabled.

### Messaging — SQS + Dead Letter Queue
A main queue and a DLQ. Messages that fail processing three times are moved to the DLQ automatically instead of being lost. Both encrypted with KMS.

### Notifications — SNS
An alerts topic. All CloudWatch alarms, GuardDuty findings, Security Hub findings, and Config non-compliance events publish here.

### Secrets — Secrets Manager
A secret store at `{project}/{environment}/app`. KMS encrypted. Configurable recovery window.

### CDN — CloudFront + WAF
CloudFront with HTTPS enforcement and TLS 1.2 minimum. WAF with three AWS managed rule sets: OWASP Top 10 protections, known bad inputs, and IP reputation blocking.

---

## The Security Modules — In Depth

This is the core of the project. Five modules implement a layered security architecture where each layer catches what the others miss.

---

### Module 1: CloudTrail (`modules/security/cloudtrail`)

**What it is:** AWS CloudTrail records every API call made in your AWS account — who did what, when, from where, and whether it succeeded. It is the foundation of all AWS security investigation and compliance.

**The problem without it:** If an attacker compromises credentials and creates resources, exfiltrates data, or modifies security settings, you have no record of it. You cannot investigate what happened, when it started, or what was accessed.

**What this module provisions:**

- **KMS key** with a carefully scoped key policy. CloudTrail can only use it to encrypt logs. CloudWatch Logs can use it for the log group. The root account retains full key management. This prevents the key from being used for anything other than its intended purpose.

- **S3 bucket** with:
  - KMS encryption using the dedicated key
  - Versioning enabled (so deleted log files can be recovered)
  - Lifecycle policy: Standard → Standard-IA at 90 days → Glacier at 365 days → expire at 7 years (common compliance requirement)
  - Bucket policy that only allows CloudTrail to write, enforces TLS on all connections, and uses `aws:SourceArn` conditions to prevent confused deputy attacks

- **CloudWatch Log Group** with 90-day retention and KMS encryption. This enables real-time alerting on log content.

- **IAM role** scoped to only allow CloudTrail to write to the specific log group — nothing else.

- **Multi-region trail** with:
  - Management events (all API calls)
  - S3 data events (object-level operations on all buckets)
  - Lambda data events (function invocations)
  - CloudTrail Insights for both API call rate anomalies and API error rate anomalies
  - Log file validation enabled (SHA-256 hash of every log file, so you can prove logs haven't been tampered with)

- **9 CloudWatch metric filters + alarms** covering the CIS AWS Foundations Benchmark requirements:
  - Root account usage
  - Unauthorized API calls
  - Console sign-in without MFA
  - IAM policy changes
  - CloudTrail configuration changes
  - S3 bucket policy changes
  - Security group changes
  - VPC changes
  - KMS key deletion or disabling

Each alarm publishes to the SNS topic, so you get notified within 5 minutes of any of these events.

**Why the 7-year retention?** PCI DSS requires 1 year. HIPAA requires 6 years. SOC 2 requires 1 year. Many financial regulations require 7 years. Setting 7 years covers all common compliance frameworks.

---

### Module 2: GuardDuty (`modules/security/guardduty`)

**What it is:** Amazon GuardDuty is a threat detection service that continuously analyses CloudTrail logs, VPC flow logs, and DNS logs using machine learning and threat intelligence feeds to identify malicious or anomalous behaviour.

**The problem without it:** CloudTrail tells you what happened. GuardDuty tells you what's suspicious. Without GuardDuty, you'd need to manually analyse millions of API calls to find the handful that indicate compromise. Nobody does this manually.

**What GuardDuty detects (examples):**
- Credentials being used from a Tor exit node or known malicious IP
- An EC2 instance communicating with a known command-and-control server
- Unusual API call patterns suggesting credential theft (e.g., `GetSecretValue` called from a new region at 3am)
- Cryptocurrency mining activity
- S3 bucket reconnaissance (listing all buckets, checking permissions)
- Kubernetes API calls from unusual sources

**What this module provisions:**

- **GuardDuty detector** with all three protection plans enabled:
  - **S3 Protection** — analyses S3 data plane events for suspicious access patterns
  - **Kubernetes Protection** — analyses EKS audit logs for suspicious cluster activity
  - **Malware Protection** — scans EBS volumes of EC2 instances with suspicious findings

- **KMS key** for findings encryption. The key policy uses `aws:SourceArn` conditions scoped to the specific detector ARN — GuardDuty can only encrypt findings from this account's detector, not any other service.

- **S3 bucket** for findings export with KMS encryption, TLS-only policy, versioning, and lifecycle management (365-day retention by default).

- **Publishing destination** — GuardDuty exports all findings to S3 continuously, enabling long-term analysis and SIEM integration.

- **EventBridge rule** that captures findings with severity ≥ 7.0 (HIGH and CRITICAL) and routes them to SNS with a human-readable message including severity, finding type, account, region, and description. You get alerted within minutes of a high-severity finding.

- **Optional trusted IP set** — if you have known-good IP ranges (office IPs, VPN egress), you can provide an S3 URI to a TXT file and GuardDuty will not alert on activity from those IPs.

**Why severity ≥ 7.0?** GuardDuty uses a 1–10 scale. 7.0+ is HIGH severity — findings that indicate active compromise or high-confidence malicious activity. Lower severity findings (reconnaissance, unusual but not definitively malicious) are still recorded in S3 for review but don't trigger immediate alerts to avoid alert fatigue.

---

### Module 3: Security Hub (`modules/security/securityhub`)

**What it is:** AWS Security Hub is a compliance and findings aggregation service. It collects findings from GuardDuty, Config, Inspector, Macie, and other services into a single dashboard, and runs automated compliance checks against industry benchmarks.

**The problem without it:** GuardDuty findings are in one place. Config non-compliance is in another. Inspector vulnerabilities are somewhere else. You have no single view of your security posture, and no automated way to check whether your environment meets CIS or NIST standards.

**What this module provisions:**

- **Security Hub account** with `enable_default_standards = false` (we manage standards explicitly, not whatever AWS decides to enable by default) and `control_finding_generator = "SECURITY_CONTROL"` (deduplicates findings across standards — if a control appears in both CIS and AFSBP, you get one finding, not two).

- **Standards subscriptions** — configurable via variables:
  - **CIS AWS Foundations Benchmark v1.4.0** (enabled by default) — 58 controls covering IAM, logging, monitoring, and networking
  - **AWS Foundational Security Best Practices** (enabled by default) — 200+ controls across all major AWS services
  - **PCI DSS v3.2.1** (optional) — for payment card industry compliance
  - **NIST SP 800-53 Rev. 5** (optional) — for US federal and enterprise compliance

- **Finding aggregator** — aggregates findings from all regions into the home region. Without this, you'd need to check Security Hub in every region separately.

- **EventBridge rule** that captures CRITICAL and HIGH severity findings with `Workflow.Status = NEW` and `RecordState = ACTIVE` — only new, unacknowledged, active findings trigger alerts. This prevents re-alerting on findings you've already reviewed. The alert includes severity, title, description, account, region, and remediation recommendation.

**What CIS v1.4.0 checks (examples):**
- MFA enabled on root account
- No root account access keys
- CloudTrail enabled in all regions
- CloudTrail log file validation enabled
- VPC flow logs enabled
- No security groups allow unrestricted SSH (0.0.0.0/0 on port 22)
- Password policy meets minimum requirements
- Access keys rotated within 90 days

**Why not enable CIS v1.2.0 and v1.4.0 together?** v1.4.0 supersedes v1.2.0. Running both creates duplicate findings for the same controls. The module defaults to v1.4.0 only.

---

### Module 4: AWS Config (`modules/security/config`)

**What it is:** AWS Config continuously records the configuration of every AWS resource in your account and evaluates those configurations against rules you define. It answers the question: "Is this resource configured correctly, and has it always been?"

**The problem without it:** You can set up security correctly today and have it drift tomorrow. Someone adds an inbound rule to a security group allowing 0.0.0.0/0 on port 22. Someone creates an unencrypted S3 bucket. Someone disables multi-AZ on the production database. Without Config, you find out about these changes when something breaks or when an auditor asks.

**What this module provisions:**

- **IAM role** with the AWS-managed `AWS_ConfigRole` policy plus a scoped inline policy for S3 writes. The assume role policy uses `aws:SourceAccount` condition to prevent confused deputy attacks.

- **S3 bucket** for Config history with KMS encryption, TLS-only policy, versioning, and 7-year lifecycle (same compliance reasoning as CloudTrail).

- **Configuration recorder** recording all supported resource types including global resources (IAM).

- **Delivery channel** with configurable snapshot frequency (default: daily).

- **30 managed Config rules** covering:

  | Category | Rules |
  |---|---|
  | Encryption | S3 server-side encryption, S3 SSL-only, EBS volume encryption, RDS storage encryption, CloudTrail encryption |
  | Access Control | S3 public read/write prohibited, SSH restricted, common ports restricted, VPC default SG closed, root access key check, IAM user MFA, root MFA, console MFA, password policy, access key rotation |
  | Logging | CloudTrail enabled, log file validation, multi-region trail, VPC flow logs |
  | Networking | SG open only to authorised ports, no unrestricted route to IGW |
  | Compute | EC2 IMDSv2 required, EBS encryption by default |
  | RDS | No public access, Multi-AZ support, automatic minor version upgrades |

- **EventBridge rule** that captures `NON_COMPLIANT` compliance change events and routes them to SNS with the rule name, resource ID, resource type, account, and region.

**Why 30 rules?** These are the rules that map directly to CIS AWS Foundations Benchmark controls and AWS Foundational Security Best Practices. If Security Hub is enabled alongside Config, Security Hub will use Config's evaluation results for its compliance checks — they work together.

**The `access_keys_rotated` rule** is parameterised with `max_access_key_age = 90` (configurable). Any IAM access key older than 90 days is flagged as non-compliant. This enforces credential rotation without requiring manual audits.

---

### Module 5: SCPs (`modules/security/scps`)

**What it is:** Service Control Policies are AWS Organizations policies that set the maximum permissions available to accounts in an OU. They are enforced by AWS at the organisation level — above IAM, above account admins, above root users. An SCP `Deny` cannot be overridden by any IAM policy in the account.

**The problem without it:** IAM controls what principals *can* do. SCPs control what principals *are allowed to do at all*. Without SCPs, a compromised admin account can disable all security services, create public resources, and cover their tracks. With SCPs, those actions are architecturally impossible regardless of what credentials are compromised.

**What this module provisions:**

**1. Deny Leave Organisation**
Prevents any account from calling `organizations:LeaveOrganization`. Without this, a compromised account could remove itself from the organisation, escaping all SCPs and centralised billing controls.

**2. Deny Disabling Security Services**
Prevents disabling GuardDuty, Security Hub, CloudTrail, and Config. Specifically blocks:
- `guardduty:DeleteDetector`, `StopMonitoringMembers`, `UpdateDetector`
- `securityhub:DeleteHub`, `DisableSecurityHub`, `DisassociateFromMasterAccount`
- `cloudtrail:DeleteTrail`, `StopLogging`, `UpdateTrail`
- `config:DeleteConfigRule`, `DeleteConfigurationRecorder`, `StopConfigurationRecorder`

A `break-glass` exemption is built in — you can pass a list of emergency IAM role ARNs that are exempt from this SCP. This prevents the SCP from locking you out during a genuine incident response scenario where you need to modify security service configuration.

**3. Deny Root Account Usage**
Blocks all actions when the principal is `arn:aws:iam::*:root`. Root accounts should only be used for the handful of tasks that genuinely require root (changing account email, closing an account). Day-to-day operations should always use IAM roles.

**4. Deny Unapproved Regions**
Restricts resource creation to a configurable list of approved regions. Resources in unapproved regions are blocked at the API level. Global services (IAM, Route53, CloudFront, STS, etc.) are explicitly excluded from this restriction since they don't have a region.

This is important for data residency compliance — if your data must stay in the EU, this SCP ensures no one can accidentally create resources in `ap-southeast-1`.

**5. Deny Public S3 Buckets**
Blocks:
- Setting public ACLs on buckets or objects
- Disabling the S3 Block Public Access settings

Even if someone tries to create a public bucket, the API call is denied before it reaches S3.

**6. Require IMDSv2 on EC2**
Blocks `ec2:RunInstances` for any instance that doesn't set `MetadataHttpTokens = required`. IMDSv1 is vulnerable to SSRF attacks — if an application has an SSRF vulnerability, an attacker can use it to steal the EC2 instance's IAM credentials from the metadata service. IMDSv2 requires a PUT request with a session token first, which SSRF attacks cannot perform.

**Policy attachments** are managed via a `for_each` over the target OU IDs. Pass a list of OU IDs and all six SCPs are attached to all of them automatically.

---

## How the Security Layers Work Together

```
Internet
    │
    ▼
CloudFront + WAF          ← Blocks known malicious IPs and OWASP Top 10
    │
    ▼
Application (EKS)
    │
    ▼
AWS API Calls
    │
    ├──► CloudTrail        ← Records every API call (who, what, when, from where)
    │         │
    │         ▼
    │    CloudWatch        ← Alerts on suspicious patterns within 5 minutes
    │
    ├──► GuardDuty         ← Analyses behaviour, detects active threats
    │         │
    │         ▼
    │    EventBridge       ← Routes HIGH/CRITICAL findings to SNS immediately
    │
    ├──► Config            ← Checks resource configurations against 30 rules
    │         │
    │         ▼
    │    EventBridge       ← Routes non-compliance events to SNS
    │
    └──► Security Hub      ← Aggregates all findings, runs CIS/AFSBP checks
              │
              ▼
         EventBridge       ← Routes CRITICAL/HIGH findings to SNS

SCPs (above all of the above)
    └── Prevents disabling any of the above, regardless of credentials
```

Each layer catches different things:
- **WAF** catches known attack patterns at the edge
- **CloudTrail + CloudWatch** catches specific high-risk API calls in real time
- **GuardDuty** catches behavioural anomalies that don't match known patterns
- **Config** catches configuration drift that creates vulnerabilities
- **Security Hub** provides the compliance view and aggregates everything
- **SCPs** ensure none of the above can be disabled

---

## Global Resources

### IAM — OIDC for GitHub Actions
No stored credentials anywhere. GitHub Actions gets short-lived tokens via OIDC for each workflow run. Two roles:
- `github-actions-non-prod` — any workflow in the repo
- `github-actions-prod` — only workflows in the `prod` GitHub Environment (requires manual approval gate)

### Bootstrap
Run once to create the S3 state bucket and DynamoDB lock table. Solves the chicken-and-egg problem of needing state storage before you can create state storage.

---

## CI/CD Pipeline

| Trigger | What runs |
|---|---|
| Pull Request | pre-commit checks, tfsec + checkov security scan, terraform plan for changed environments |
| Merge to main | terraform apply for changed environments |
| Prod changes | Pauses for manual approval in GitHub Environments before applying |

The plan workflow detects which environments changed by checking which files were modified. Only changed environments are planned and applied.

---

## Tagging Strategy

Every resource gets five mandatory tags via `default_tags`:

| Tag | Value |
|---|---|
| `Environment` | dev / sit / staging / prod / global |
| `Project` | Project name |
| `Owner` | Team name |
| `CostCenter` | Billing allocation code |
| `ManagedBy` | Always `"terraform"` |

If a resource in the AWS console doesn't have `ManagedBy = terraform`, it was created manually and is not managed by this codebase.

---

## State Management

Each environment has its own isolated state file in S3. A mistake in dev cannot corrupt prod's state. DynamoDB locking prevents concurrent applies. State is versioned — you can roll back to any previous state.

---

## What You'd Need to Add for Real Production Use

1. **Your application workloads** — EKS needs Helm charts or ArgoCD manifests; Lambda needs your actual function code
2. **ACM certificates** — SSL certs for your domain (ARN referenced in `terraform.tfvars`)
3. **Tighter IAM policies** — GitHub Actions roles use `AdministratorAccess` as a starting point; scope these down in production
4. **AWS Organizations setup** — SCPs require Organizations with "All features" enabled; OU IDs must be provided
5. **SNS subscriptions** — the alerts SNS topic needs email/PagerDuty/Slack subscriptions to actually deliver notifications
6. **Backup testing** — RDS backup retention is configured; test the restore procedure
