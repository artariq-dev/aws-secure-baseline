output "github_actions_non_prod_role_arn" {
  description = "GitHub Actions IAM role ARN for non-prod — use as NON_PROD_ROLE_ARN secret"
  value       = aws_iam_role.github_actions_non_prod.arn
}

output "github_actions_prod_role_arn" {
  description = "GitHub Actions IAM role ARN for prod — use as PROD_ROLE_ARN secret"
  value       = aws_iam_role.github_actions_prod.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}
