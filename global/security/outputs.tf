output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "config_recorder_name" {
  description = "AWS Config recorder name"
  value       = aws_config_configuration_recorder.main.name
}

output "config_bucket_name" {
  description = "S3 bucket storing AWS Config history"
  value       = aws_s3_bucket.config.id
}
