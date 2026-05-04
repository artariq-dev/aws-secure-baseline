data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
}

# ─── IAM Role for Config ──────────────────────────────────────────────────────

resource "aws_iam_role" "config" {
  name = "${var.project}-aws-config"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = local.account_id
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_managed" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Allow Config to write to the S3 bucket
resource "aws_iam_role_policy" "config_s3" {
  name = "${var.project}-config-s3"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.config.arn}/AWSLogs/${local.account_id}/Config/*"
        Condition = {
          StringLike = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config.arn
      }
    ]
  })
}

# ─── S3 Bucket for Config History ────────────────────────────────────────────

resource "aws_s3_bucket" "config" {
  bucket        = "${var.project}-aws-config-${local.account_id}"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "config" {
  bucket = aws_s3_bucket.config.id

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
      days = var.config_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config.arn}/AWSLogs/${local.account_id}/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = local.account_id
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
        Resource = [aws_s3_bucket.config.arn, "${aws_s3_bucket.config.arn}/*"]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ─── Config Recorder & Delivery Channel ──────────────────────────────────────

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project}-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project}-config-delivery"
  s3_bucket_name = aws_s3_bucket.config.bucket

  snapshot_delivery_properties {
    delivery_frequency = var.snapshot_delivery_frequency
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# ─── Managed Config Rules ─────────────────────────────────────────────────────

locals {
  managed_rules = {
    # Encryption
    s3_bucket_server_side_encryption_enabled = {
      source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
    }
    s3_bucket_ssl_requests_only = {
      source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
    }
    encrypted_volumes = {
      source_identifier = "ENCRYPTED_VOLUMES"
    }
    rds_storage_encrypted = {
      source_identifier = "RDS_STORAGE_ENCRYPTED"
    }
    cloudtrail_encryption_enabled = {
      source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
    }

    # Access Control
    s3_bucket_public_read_prohibited = {
      source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
    }
    s3_bucket_public_write_prohibited = {
      source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
    }
    restricted_ssh = {
      source_identifier = "INCOMING_SSH_DISABLED"
    }
    restricted_common_ports = {
      source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
    }
    vpc_default_security_group_closed = {
      source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
    }
    iam_root_access_key_check = {
      source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
    }
    iam_user_mfa_enabled = {
      source_identifier = "IAM_USER_MFA_ENABLED"
    }
    root_account_mfa_enabled = {
      source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
    }
    mfa_enabled_for_iam_console_access = {
      source_identifier = "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS"
    }
    iam_password_policy = {
      source_identifier = "IAM_PASSWORD_POLICY"
    }
    access_keys_rotated = {
      source_identifier  = "ACCESS_KEYS_ROTATED"
      input_parameters   = jsonencode({ maxAccessKeyAge = tostring(var.max_access_key_age) })
    }

    # Logging & Monitoring
    cloudtrail_enabled = {
      source_identifier = "CLOUD_TRAIL_ENABLED"
    }
    cloudtrail_log_file_validation_enabled = {
      source_identifier = "CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED"
    }
    cloudtrail_multi_region_enabled = {
      source_identifier = "MULTI_REGION_CLOUD_TRAIL_ENABLED"
    }
    vpc_flow_logs_enabled = {
      source_identifier = "VPC_FLOW_LOGS_ENABLED"
    }

    # Networking
    vpc_sg_open_only_to_authorized_ports = {
      source_identifier = "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS"
    }
    no_unrestricted_route_to_igw = {
      source_identifier = "NO_UNRESTRICTED_ROUTE_TO_IGW"
    }

    # Compute
    ec2_imdsv2_check = {
      source_identifier = "EC2_IMDSV2_CHECK"
    }
    ec2_ebs_encryption_by_default = {
      source_identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT"
    }

    # RDS
    rds_instance_public_access_check = {
      source_identifier = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
    }
    rds_multi_az_support = {
      source_identifier = "RDS_MULTI_AZ_SUPPORT"
    }
    rds_automatic_minor_version_upgrade_enabled = {
      source_identifier = "RDS_AUTOMATIC_MINOR_VERSION_UPGRADE_ENABLED"
    }
  }
}

resource "aws_config_config_rule" "managed" {
  for_each = local.managed_rules

  name = "${var.project}-${replace(each.key, "_", "-")}"

  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }

  dynamic "input_parameters" {
    for_each = lookup(each.value, "input_parameters", null) != null ? [each.value.input_parameters] : []
    content {
      # input_parameters is a JSON string passed directly
    }
  }

  depends_on = [aws_config_configuration_recorder_status.main]
}

# ─── SNS Topic for Config Non-Compliance Notifications ───────────────────────

resource "aws_config_delivery_channel" "sns" {
  count = length(var.alarm_sns_topic_arns) > 0 ? 0 : 0 # placeholder — SNS via EventBridge below
}

resource "aws_cloudwatch_event_rule" "config_noncompliant" {
  name        = "${var.project}-config-noncompliant"
  description = "Capture AWS Config non-compliant resource changes"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "config_sns" {
  count = length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  rule      = aws_cloudwatch_event_rule.config_noncompliant.name
  target_id = "SendToSNS"
  arn       = var.alarm_sns_topic_arns[0]

  input_transformer {
    input_paths = {
      rule     = "$.detail.configRuleName"
      resource = "$.detail.resourceId"
      type     = "$.detail.resourceType"
      account  = "$.detail.awsAccountId"
      region   = "$.region"
    }
    input_template = "\"Config NON-COMPLIANT | Rule: <rule> | Resource: <resource> (<type>) | Account: <account> | Region: <region>\""
  }
}
