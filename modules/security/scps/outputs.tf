output "deny_leave_org_policy_id" {
  description = "ID of the SCP that prevents accounts from leaving the organization"
  value       = aws_organizations_policy.deny_leave_org.id
}

output "deny_disable_security_services_policy_id" {
  description = "ID of the SCP that prevents disabling GuardDuty, Security Hub, CloudTrail, and Config"
  value       = aws_organizations_policy.deny_disable_security_services.id
}

output "deny_root_usage_policy_id" {
  description = "ID of the SCP that prevents root account usage"
  value       = aws_organizations_policy.deny_root_usage.id
}

output "deny_public_s3_policy_id" {
  description = "ID of the SCP that prevents public S3 buckets"
  value       = aws_organizations_policy.deny_public_s3.id
}

output "require_imdsv2_policy_id" {
  description = "ID of the SCP that requires IMDSv2 on all EC2 instances"
  value       = aws_organizations_policy.require_imdsv2.id
}

output "deny_unapproved_regions_policy_id" {
  description = "ID of the SCP that restricts workloads to approved regions (null if not enabled)"
  value       = length(aws_organizations_policy.deny_unapproved_regions) > 0 ? aws_organizations_policy.deny_unapproved_regions[0].id : null
}
