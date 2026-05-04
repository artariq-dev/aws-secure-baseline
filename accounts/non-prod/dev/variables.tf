variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, sit, staging, prod)"
  type        = string
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

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "intra_subnet_cidrs" {
  description = "CIDR blocks for intra (database) subnets"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway to reduce cost in non-prod"
  type        = bool
  default     = false
}

variable "eks_cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "eks_node_min_size" {
  description = "Minimum EKS node count"
  type        = number
}

variable "eks_node_max_size" {
  description = "Maximum EKS node count"
  type        = number
}

variable "eks_node_desired_size" {
  description = "Desired EKS node count"
  type        = number
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "rds_db_name" {
  description = "Database name"
  type        = string
}

variable "rds_username" {
  description = "Database master username"
  type        = string
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot on destroy"
  type        = bool
  default     = true
}

variable "rds_backup_retention" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
}

variable "redis_num_cache_clusters" {
  description = "Number of Redis cache clusters"
  type        = number
  default     = 1
}

variable "secrets_recovery_window" {
  description = "Recovery window in days for deleted secrets (0 = immediate in dev)"
  type        = number
  default     = 7
}

variable "cloudfront_aliases" {
  description = "CNAME aliases for CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (must be in us-east-1)"
  type        = string
  default     = ""
}
