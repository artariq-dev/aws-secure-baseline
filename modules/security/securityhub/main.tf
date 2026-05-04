data "aws_region" "current" {}

locals {
  region = data.aws_region.current.name

  # All supported standards with their ARNs
  standards = {
    cis_1_2 = {
      arn     = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
      enabled = var.enable_cis_1_2
    }
    cis_1_4 = {
      arn     = "arn:aws:securityhub:${local.region}::standards/cis-aws-foundations-benchmark/v/1.4.0"
      enabled = var.enable_cis_1_4
    }
    aws_foundational = {
      arn     = "arn:aws:securityhub:${local.region}::standards/aws-foundational-security-best-practices/v/1.0.0"
      enabled = var.enable_aws_foundational
    }
    pci_dss = {
      arn     = "arn:aws:securityhub:${local.region}::standards/pci-dss/v/3.2.1"
      enabled = var.enable_pci_dss
    }
    nist = {
      arn     = "arn:aws:securityhub:${local.region}::standards/nist-800-53/v/5.0.0"
      enabled = var.enable_nist
    }
  }

  enabled_standards = {
    for k, v in local.standards : k => v if v.enabled
  }
}

# ─── Security Hub Account ─────────────────────────────────────────────────────

resource "aws_securityhub_account" "main" {
  enable_default_standards  = false # We manage standards explicitly below
  auto_enable_controls      = true
  control_finding_generator = "SECURITY_CONTROL"
}

# ─── Standards Subscriptions ─────────────────────────────────────────────────

resource "aws_securityhub_standards_subscription" "this" {
  for_each = local.enabled_standards

  standards_arn = each.value.arn
  depends_on    = [aws_securityhub_account.main]
}

# ─── Finding Aggregator (aggregate findings across regions) ──────────────────

resource "aws_securityhub_finding_aggregator" "main" {
  count = var.enable_finding_aggregator ? 1 : 0

  linking_mode = "ALL_REGIONS"
  depends_on   = [aws_securityhub_account.main]
}

# ─── Action Target: Send to SNS via EventBridge ──────────────────────────────

resource "aws_securityhub_action_target" "send_to_sns" {
  count = length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  name        = "Send to SNS"
  identifier  = "SendToSNS"
  description = "Send Security Hub findings to SNS topic"

  depends_on = [aws_securityhub_account.main]
}

# ─── EventBridge: CRITICAL/HIGH findings → SNS ───────────────────────────────

resource "aws_cloudwatch_event_rule" "securityhub_critical" {
  name        = "${var.project}-securityhub-critical"
  description = "Capture Security Hub CRITICAL and HIGH severity findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL", "HIGH"]
        }
        Workflow = {
          Status = ["NEW"]
        }
        RecordState = ["ACTIVE"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "securityhub_sns" {
  count = length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  rule      = aws_cloudwatch_event_rule.securityhub_critical.name
  target_id = "SendToSNS"
  arn       = var.alarm_sns_topic_arns[0]

  input_transformer {
    input_paths = {
      severity    = "$.detail.findings[0].Severity.Label"
      title       = "$.detail.findings[0].Title"
      description = "$.detail.findings[0].Description"
      account     = "$.detail.findings[0].AwsAccountId"
      region      = "$.region"
      remediation = "$.detail.findings[0].Remediation.Recommendation.Text"
    }
    input_template = "\"Security Hub ALERT | Severity: <severity> | Title: <title> | Account: <account> | Region: <region> | Remediation: <remediation>\""
  }
}
