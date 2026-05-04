data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
}

# ─── GuardDuty Detector ───────────────────────────────────────────────────────

resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
}

# ─── Findings Export: S3 ─────────────────────────────────────────────────────

resource "aws_kms_key" "guardduty" {
  description             = "KMS key for GuardDuty findings export — ${var.project}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow GuardDuty to use the key"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
            "aws:SourceArn"     = "arn:${local.partition}:guardduty:${local.region}:${local.account_id}:detector/${aws_guardduty_detector.main.id}"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "guardduty" {
  name          = "alias/${var.project}-guardduty"
  target_key_id = aws_kms_key.guardduty.key_id
}

resource "aws_s3_bucket" "findings" {
  bucket        = "${var.project}-guardduty-findings-${local.account_id}"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "findings" {
  bucket = aws_s3_bucket.findings.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "findings" {
  bucket = aws_s3_bucket.findings.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.guardduty.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "findings" {
  bucket                  = aws_s3_bucket.findings.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "findings" {
  bucket = aws_s3_bucket.findings.id

  rule {
    id     = "transition-and-expire"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = var.findings_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "findings" {
  bucket = aws_s3_bucket.findings.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGuardDutyGetBucketLocation"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:GetBucketLocation"
        Resource = aws_s3_bucket.findings.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
            "aws:SourceArn"     = "arn:${local.partition}:guardduty:${local.region}:${local.account_id}:detector/${aws_guardduty_detector.main.id}"
          }
        }
      },
      {
        Sid    = "AllowGuardDutyPutObject"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.findings.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
            "aws:SourceArn"     = "arn:${local.partition}:guardduty:${local.region}:${local.account_id}:detector/${aws_guardduty_detector.main.id}"
          }
        }
      },
      {
        Sid    = "DenyNonTLS"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action   = "s3:*"
        Resource = [aws_s3_bucket.findings.arn, "${aws_s3_bucket.findings.arn}/*"]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_guardduty_publishing_destination" "s3" {
  detector_id     = aws_guardduty_detector.main.id
  destination_arn = aws_s3_bucket.findings.arn
  kms_key_arn     = aws_kms_key.guardduty.arn

  depends_on = [aws_s3_bucket_policy.findings]
}

# ─── EventBridge Rule: High/Critical Findings → SNS ─────────────────────────

resource "aws_cloudwatch_event_rule" "guardduty_high_severity" {
  name        = "${var.project}-guardduty-high-severity"
  description = "Capture GuardDuty HIGH and CRITICAL severity findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 7] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  count = length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  rule      = aws_cloudwatch_event_rule.guardduty_high_severity.name
  target_id = "SendToSNS"
  arn       = var.alarm_sns_topic_arns[0]

  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      type        = "$.detail.type"
      description = "$.detail.description"
      account     = "$.detail.accountId"
      region      = "$.region"
    }
    input_template = "\"GuardDuty ALERT | Severity: <severity> | Type: <type> | Account: <account> | Region: <region> | <description>\""
  }
}

# ─── Threat Intel Feed (optional) ────────────────────────────────────────────

resource "aws_guardduty_ipset" "trusted_ips" {
  count = length(var.trusted_ip_list_s3_uri) > 0 ? 1 : 0

  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = var.trusted_ip_list_s3_uri
  name        = "${var.project}-trusted-ips"
}
