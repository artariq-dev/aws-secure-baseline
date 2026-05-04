variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
}

variable "finding_publishing_frequency" {
  description = "Frequency for publishing GuardDuty findings (FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS)"
  type        = string
  default     = "SIX_HOURS"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "Must be one of: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  }
}

variable "findings_retention_days" {
  description = "Number of days to retain GuardDuty findings in S3"
  type        = number
  default     = 365
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs to notify on HIGH/CRITICAL findings"
  type        = list(string)
  default     = []
}

variable "trusted_ip_list_s3_uri" {
  description = "S3 URI (s3://bucket/key) of a TXT file containing trusted IP addresses. Leave empty to skip."
  type        = string
  default     = ""
}
