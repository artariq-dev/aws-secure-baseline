variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
}

variable "config_retention_days" {
  description = "Number of days to retain Config history in S3"
  type        = number
  default     = 2557 # 7 years
}

variable "snapshot_delivery_frequency" {
  description = "Frequency for Config snapshot delivery (One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours)"
  type        = string
  default     = "TwentyFour_Hours"

  validation {
    condition     = contains(["One_Hour", "Three_Hours", "Six_Hours", "Twelve_Hours", "TwentyFour_Hours"], var.snapshot_delivery_frequency)
    error_message = "Must be one of: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours."
  }
}

variable "max_access_key_age" {
  description = "Maximum age in days for IAM access keys before flagging as non-compliant"
  type        = number
  default     = 90
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs to notify on non-compliant resources"
  type        = list(string)
  default     = []
}
