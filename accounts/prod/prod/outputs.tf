output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = module.elasticache.replication_group_primary_endpoint_address
  sensitive   = true
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

output "sqs_queue_url" {
  description = "Main SQS queue URL"
  value       = aws_sqs_queue.main.url
}

output "sns_alerts_arn" {
  description = "SNS alerts topic ARN"
  value       = aws_sns_topic.alerts.arn
}

output "app_secret_arn" {
  description = "ARN of the application Secrets Manager secret"
  value       = aws_secretsmanager_secret.app.arn
}
