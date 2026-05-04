terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
    }
  }
}

# ─── Networking ───────────────────────────────────────────────────────────────

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${var.project}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs
  intra_subnets   = var.intra_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ─── Compute: EKS ─────────────────────────────────────────────────────────────

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.11.1"

  cluster_name    = "${var.project}-${var.environment}-eks"
  cluster_version = var.eks_cluster_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = false

  eks_managed_node_groups = {
    general = {
      min_size       = var.eks_node_min_size
      max_size       = var.eks_node_max_size
      desired_size   = var.eks_node_desired_size
      instance_types = [var.eks_node_instance_type]
      capacity_type  = "ON_DEMAND"
    }
  }
}

# ─── Compute: Lambda ──────────────────────────────────────────────────────────

module "lambda_example" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.1"

  function_name = "${var.project}-${var.environment}-example"
  description   = "Example Lambda — replace with your function"
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  source_path = "${path.module}/../../../functions/example"

  environment_variables = {
    ENVIRONMENT = var.environment
  }
}

# ─── Data: RDS ────────────────────────────────────────────────────────────────

resource "aws_security_group" "rds" {
  name_prefix = "${var.project}-${var.environment}-rds-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.7.0"

  identifier = "${var.project}-${var.environment}-db"

  engine         = "postgres"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  allocated_storage = var.rds_allocated_storage

  db_name  = var.rds_db_name
  username = var.rds_username
  port     = "5432"

  manage_master_user_password = true

  vpc_security_group_ids = [aws_security_group.rds.id]
  subnet_ids             = module.vpc.intra_subnets
  create_db_subnet_group = true

  multi_az                = var.rds_multi_az
  deletion_protection     = var.rds_deletion_protection
  skip_final_snapshot     = var.rds_skip_final_snapshot
  storage_encrypted       = true
  backup_retention_period = var.rds_backup_retention
}

# ─── Data: ElastiCache ────────────────────────────────────────────────────────

module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "1.2.2"

  cluster_id                    = "${var.project}-${var.environment}-redis"
  create_replication_group      = true
  replication_group_description = "Redis for ${var.project}-${var.environment}"

  engine_version     = var.redis_engine_version
  node_type          = var.redis_node_type
  num_cache_clusters = var.redis_num_cache_clusters

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.intra_subnets

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
}

# ─── Data: SQS ────────────────────────────────────────────────────────────────

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project}-${var.environment}-main-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = "alias/aws/sqs"
}

resource "aws_sqs_queue" "main" {
  name                       = "${var.project}-${var.environment}-main"
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 30
  kms_master_key_id          = "alias/aws/sqs"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# ─── Data: SNS ────────────────────────────────────────────────────────────────

resource "aws_sns_topic" "alerts" {
  name              = "${var.project}-${var.environment}-alerts"
  kms_master_key_id = "alias/aws/sns"
}

# ─── Data: Secrets Manager ────────────────────────────────────────────────────

resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project}/${var.environment}/app"
  description             = "Application secrets for ${var.environment}"
  recovery_window_in_days = var.secrets_recovery_window
  kms_key_id              = "alias/aws/secretsmanager"
}

# ─── CDN: WAF ─────────────────────────────────────────────────────────────────

module "waf" {
  source  = "umotif-public/waf-webaclv2/aws"
  version = "3.10.0"

  name_prefix          = "${var.project}-${var.environment}"
  scope                = "CLOUDFRONT"
  allow_default_action = true

  visibility_config = {
    metric_name = "${var.project}-${var.environment}-waf"
  }

  managed_rules = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      priority        = 10
      override_action = "none"
      visibility_config = {
        metric_name = "AWSManagedRulesCommonRuleSet"
      }
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      priority        = 20
      override_action = "none"
      visibility_config = {
        metric_name = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    },
    {
      name            = "AWSManagedRulesAmazonIpReputationList"
      priority        = 30
      override_action = "none"
      visibility_config = {
        metric_name = "AWSManagedRulesAmazonIpReputationList"
      }
    }
  ]
}

# ─── CDN: CloudFront ──────────────────────────────────────────────────────────

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.4.0"

  aliases = var.cloudfront_aliases

  default_cache_behavior = {
    target_origin_id       = "${var.project}-${var.environment}-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
  }

  viewer_certificate = {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  web_acl_id = module.waf.web_acl_arn
}

# ─── Observability ────────────────────────────────────────────────────────────

module "observability" {
  source = "git::https://github.com/<YOUR_ORG>/terraform-aws-observability.git?ref=v1.0.0"

  project     = var.project
  environment = var.environment

  sns_alert_topic_arn = aws_sns_topic.alerts.arn
  eks_cluster_name    = module.eks.cluster_name
  rds_instance_id     = module.rds.db_instance_id
}

# ─── Security Baseline ────────────────────────────────────────────────────────

module "security_baseline" {
  source = "git::https://github.com/<YOUR_ORG>/terraform-aws-security-baseline.git?ref=v1.0.0"

  project     = var.project
  environment = var.environment

  sns_alert_topic_arn = aws_sns_topic.alerts.arn
}
