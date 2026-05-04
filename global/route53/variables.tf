variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "owner" {
  description = "Team owner"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
}

variable "root_domain" {
  description = "Root domain for the project (e.g. myapp.example.com)"
  type        = string
}
