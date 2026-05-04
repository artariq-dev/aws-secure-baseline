# ─── Service Control Policies ─────────────────────────────────────────────────
#
# These SCPs are attached to OUs in AWS Organizations.
# They act as guardrails — even an account admin cannot override them.
#
# Prerequisites:
#   - AWS Organizations must be enabled with "All features" (not just consolidated billing)
#   - The caller must be in the management (root) account
#   - SCP policy type must be enabled on the target OU

data "aws_organizations_organization" "current" {}

# ─── Deny Leaving the Organization ───────────────────────────────────────────

resource "aws_organizations_policy" "deny_leave_org" {
  name        = "${var.project}-deny-leave-org"
  description = "Prevent any account from leaving the AWS Organization"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DenyLeaveOrganization"
      Effect   = "Deny"
      Action   = "organizations:LeaveOrganization"
      Resource = "*"
    }]
  })
}

# ─── Deny Disabling Security Services ────────────────────────────────────────

resource "aws_organizations_policy" "deny_disable_security_services" {
  name        = "${var.project}-deny-disable-security-services"
  description = "Prevent disabling GuardDuty, Security Hub, CloudTrail, and Config"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDisableGuardDuty"
        Effect = "Deny"
        Action = [
          "guardduty:DeleteDetector",
          "guardduty:DisassociateFromMasterAccount",
          "guardduty:DisassociateMembers",
          "guardduty:StopMonitoringMembers",
          "guardduty:UpdateDetector"
        ]
        Resource = "*"
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = var.security_break_glass_role_arns
          }
        }
      },
      {
        Sid    = "DenyDisableSecurityHub"
        Effect = "Deny"
        Action = [
          "securityhub:DeleteHub",
          "securityhub:DisableSecurityHub",
          "securityhub:DisassociateFromMasterAccount",
          "securityhub:DisassociateMembers"
        ]
        Resource = "*"
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = var.security_break_glass_role_arns
          }
        }
      },
      {
        Sid    = "DenyDisableCloudTrail"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = var.security_break_glass_role_arns
          }
        }
      },
      {
        Sid    = "DenyDisableConfig"
        Effect = "Deny"
        Action = [
          "config:DeleteConfigRule",
          "config:DeleteConfigurationRecorder",
          "config:DeleteDeliveryChannel",
          "config:StopConfigurationRecorder"
        ]
        Resource = "*"
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = var.security_break_glass_role_arns
          }
        }
      }
    ]
  })
}

# ─── Deny Root Account Usage ──────────────────────────────────────────────────

resource "aws_organizations_policy" "deny_root_usage" {
  name        = "${var.project}-deny-root-usage"
  description = "Prevent use of the root account for day-to-day operations"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyRootAccountUsage"
      Effect = "Deny"
      Action = "*"
      Resource = "*"
      Condition = {
        StringLike = {
          "aws:PrincipalArn" = [
            "arn:aws:iam::*:root"
          ]
        }
      }
    }]
  })
}

# ─── Deny Unapproved Regions ──────────────────────────────────────────────────

resource "aws_organizations_policy" "deny_unapproved_regions" {
  count = length(var.approved_regions) > 0 ? 1 : 0

  name        = "${var.project}-deny-unapproved-regions"
  description = "Restrict workloads to approved AWS regions only"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyUnapprovedRegions"
      Effect = "Deny"
      NotAction = [
        # Global services that don't have a region — must be excluded
        "a4b:*", "acm:*", "aws-marketplace-management:*", "aws-marketplace:*",
        "aws-portal:*", "budgets:*", "ce:*", "chime:*", "cloudfront:*",
        "config:*", "cur:*", "directconnect:*", "ec2:DescribeRegions",
        "ec2:DescribeTransitGateways", "fms:*", "globalaccelerator:*",
        "health:*", "iam:*", "importexport:*", "kms:*", "mobileanalytics:*",
        "networkmanager:*", "organizations:*", "pricing:*", "route53:*",
        "route53domains:*", "s3:GetAccountPublic*", "s3:ListAllMyBuckets",
        "s3:PutAccountPublic*", "shield:*", "sts:*", "support:*",
        "trustedadvisor:*", "waf-regional:*", "waf:*", "wafv2:*",
        "wellarchitected:*"
      ]
      Resource = "*"
      Condition = {
        StringNotIn = {
          "aws:RequestedRegion" = var.approved_regions
        }
      }
    }]
  })
}

# ─── Deny Public S3 Buckets ───────────────────────────────────────────────────

resource "aws_organizations_policy" "deny_public_s3" {
  name        = "${var.project}-deny-public-s3"
  description = "Prevent creation of public S3 buckets across all accounts"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyPublicS3ACL"
        Effect = "Deny"
        Action = [
          "s3:PutBucketAcl",
          "s3:PutObjectAcl"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = [
              "public-read",
              "public-read-write",
              "authenticated-read"
            ]
          }
        }
      },
      {
        Sid    = "DenyPublicS3Policy"
        Effect = "Deny"
        Action = "s3:PutBucketPublicAccessBlock"
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:PublicAccessBlockConfiguration/BlockPublicAcls"       = "false"
            "s3:PublicAccessBlockConfiguration/BlockPublicPolicy"     = "false"
            "s3:PublicAccessBlockConfiguration/IgnorePublicAcls"      = "false"
            "s3:PublicAccessBlockConfiguration/RestrictPublicBuckets" = "false"
          }
        }
      }
    ]
  })
}

# ─── Require IMDSv2 on EC2 ────────────────────────────────────────────────────

resource "aws_organizations_policy" "require_imdsv2" {
  name        = "${var.project}-require-imdsv2"
  description = "Require IMDSv2 on all EC2 instances to prevent SSRF attacks"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyIMDSv1"
      Effect = "Deny"
      Action = "ec2:RunInstances"
      Resource = "arn:aws:ec2:*:*:instance/*"
      Condition = {
        StringNotEquals = {
          "ec2:MetadataHttpTokens" = "required"
        }
      }
    }]
  })
}

# ─── Policy Attachments ───────────────────────────────────────────────────────

locals {
  # Map of policy → list of OU IDs to attach to
  policy_attachments = merge(
    # deny_leave_org → all target OUs
    { for ou_id in var.target_ou_ids : "deny_leave_org_${ou_id}" => {
      policy_id = aws_organizations_policy.deny_leave_org.id
      target_id = ou_id
    }},
    # deny_disable_security_services → all target OUs
    { for ou_id in var.target_ou_ids : "deny_disable_security_${ou_id}" => {
      policy_id = aws_organizations_policy.deny_disable_security_services.id
      target_id = ou_id
    }},
    # deny_root_usage → all target OUs
    { for ou_id in var.target_ou_ids : "deny_root_${ou_id}" => {
      policy_id = aws_organizations_policy.deny_root_usage.id
      target_id = ou_id
    }},
    # deny_public_s3 → all target OUs
    { for ou_id in var.target_ou_ids : "deny_public_s3_${ou_id}" => {
      policy_id = aws_organizations_policy.deny_public_s3.id
      target_id = ou_id
    }},
    # require_imdsv2 → all target OUs
    { for ou_id in var.target_ou_ids : "require_imdsv2_${ou_id}" => {
      policy_id = aws_organizations_policy.require_imdsv2.id
      target_id = ou_id
    }},
    # deny_unapproved_regions → all target OUs (only if policy was created)
    length(var.approved_regions) > 0 ? { for ou_id in var.target_ou_ids : "deny_regions_${ou_id}" => {
      policy_id = aws_organizations_policy.deny_unapproved_regions[0].id
      target_id = ou_id
    }} : {}
  )
}

resource "aws_organizations_policy_attachment" "this" {
  for_each = local.policy_attachments

  policy_id = each.value.policy_id
  target_id = each.value.target_id
}
