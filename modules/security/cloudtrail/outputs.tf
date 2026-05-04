output "trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.main.arn
}

output "trail_home_region" {
  description = "Home region of the CloudTrail trail"
  value       = aws_cloudtrail.main.home_region
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt CloudTrail logs"
  value       = aws_kms_key.cloudtrail.arn
}

output "kms_key_id" {
  description = "ID of the KMS key used to encrypt CloudTrail logs"
  value       = aws_kms_key.cloudtrail.key_id
}

output "log_group_name" {
  description = "Name of the CloudWatch log group receiving CloudTrail events"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group receiving CloudTrail events"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}
