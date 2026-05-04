variable "project" {
  description = "Project name — used as a prefix for all SCP names"
  type        = string
}

variable "target_ou_ids" {
  description = "List of AWS Organizations OU IDs to attach all SCPs to"
  type        = list(string)
}

variable "approved_regions" {
  description = "List of approved AWS regions. Resources in other regions will be denied. Leave empty to skip region restriction."
  type        = list(string)
  default     = ["us-east-1", "us-west-2", "eu-west-1"]
}

variable "security_break_glass_role_arns" {
  description = "List of IAM role ARNs exempt from security service protection SCPs (break-glass emergency access)"
  type        = list(string)
  default     = []
}
