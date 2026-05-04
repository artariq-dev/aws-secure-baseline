variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
}

variable "enable_cis_1_2" {
  description = "Enable CIS AWS Foundations Benchmark v1.2.0"
  type        = bool
  default     = false # Superseded by 1.4
}

variable "enable_cis_1_4" {
  description = "Enable CIS AWS Foundations Benchmark v1.4.0"
  type        = bool
  default     = true
}

variable "enable_aws_foundational" {
  description = "Enable AWS Foundational Security Best Practices"
  type        = bool
  default     = true
}

variable "enable_pci_dss" {
  description = "Enable PCI DSS v3.2.1 standard"
  type        = bool
  default     = false
}

variable "enable_nist" {
  description = "Enable NIST SP 800-53 Rev. 5 standard"
  type        = bool
  default     = false
}

variable "enable_finding_aggregator" {
  description = "Aggregate findings from all regions into the home region"
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs to notify on CRITICAL/HIGH findings"
  type        = list(string)
  default     = []
}
