terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "REPLACE_WITH_STATE_BUCKET_NAME"
    key            = "global/route53/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "global"
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
    }
  }
}

resource "aws_route53_zone" "primary" {
  name = var.root_domain
}

resource "aws_route53_zone" "dev" {
  name = "dev.${var.root_domain}"
}

resource "aws_route53_zone" "sit" {
  name = "sit.${var.root_domain}"
}

resource "aws_route53_zone" "staging" {
  name = "staging.${var.root_domain}"
}

resource "aws_route53_record" "dev_ns" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "dev.${var.root_domain}"
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.dev.name_servers
}

resource "aws_route53_record" "sit_ns" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "sit.${var.root_domain}"
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.sit.name_servers
}

resource "aws_route53_record" "staging_ns" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "staging.${var.root_domain}"
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.staging.name_servers
}
