output "detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "detector_arn" {
  description = "GuardDuty detector ARN"
  value       = aws_guardduty_detector.main.arn
}

output "findings_bucket_name" {
  description = "Name of the S3 bucket storing GuardDuty findings"
  value       = aws_s3_bucket.findings.id
}

output "findings_bucket_arn" {
  description = "ARN of the S3 bucket storing GuardDuty findings"
  value       = aws_s3_bucket.findings.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt GuardDuty findings"
  value       = aws_kms_key.guardduty.arn
}
