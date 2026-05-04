variable "aws_region" {
  description = "AWS region for state backend resources"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique name for the S3 state bucket"
  type        = string
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "project" {
  description = "Project name used for tagging"
  type        = string
}

variable "owner" {
  description = "Team or individual responsible for this infrastructure"
  type        = string
}
