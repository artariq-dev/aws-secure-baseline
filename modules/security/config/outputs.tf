output "recorder_name" {
  description = "Name of the AWS Config configuration recorder"
  value       = aws_config_configuration_recorder.main.name
}

output "delivery_channel_name" {
  description = "Name of the AWS Config delivery channel"
  value       = aws_config_delivery_channel.main.name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket storing Config history"
  value       = aws_s3_bucket.config.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket storing Config history"
  value       = aws_s3_bucket.config.arn
}

output "config_role_arn" {
  description = "ARN of the IAM role used by AWS Config"
  value       = aws_iam_role.config.arn
}

output "managed_rule_names" {
  description = "List of managed Config rule names created"
  value       = [for r in aws_config_config_rule.managed : r.name]
}
