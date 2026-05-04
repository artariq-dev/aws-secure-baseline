output "securityhub_arn" {
  description = "ARN of the Security Hub account subscription"
  value       = aws_securityhub_account.main.id
}

output "enabled_standards" {
  description = "Map of enabled Security Hub standards and their ARNs"
  value       = { for k, v in aws_securityhub_standards_subscription.this : k => v.standards_arn }
}

output "finding_aggregator_arn" {
  description = "ARN of the Security Hub finding aggregator (if enabled)"
  value       = length(aws_securityhub_finding_aggregator.main) > 0 ? aws_securityhub_finding_aggregator.main[0].id : null
}
