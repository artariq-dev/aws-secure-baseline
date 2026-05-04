output "primary_zone_id" {
  description = "Route53 hosted zone ID for the primary domain"
  value       = aws_route53_zone.primary.zone_id
}

output "primary_name_servers" {
  description = "Name servers to set at your domain registrar"
  value       = aws_route53_zone.primary.name_servers
}

output "dev_zone_id" {
  description = "Route53 zone ID for dev subdomain"
  value       = aws_route53_zone.dev.zone_id
}

output "sit_zone_id" {
  description = "Route53 zone ID for sit subdomain"
  value       = aws_route53_zone.sit.zone_id
}

output "staging_zone_id" {
  description = "Route53 zone ID for staging subdomain"
  value       = aws_route53_zone.staging.zone_id
}
