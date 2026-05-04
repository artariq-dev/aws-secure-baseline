variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudTrail logs in S3 before expiration"
  type        = number
  default     = 2557 # 7 years — common compliance requirement
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs to notify when a CloudWatch alarm fires"
  type        = list(string)
  default     = []
}
