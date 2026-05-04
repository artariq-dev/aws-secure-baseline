aws_region  = "us-east-1"
environment = "sit"
project     = "myapp"
owner       = "platform-team"
cost_center = "engineering"

# Networking — non-overlapping CIDR for future VPC peering
vpc_cidr             = "10.20.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
private_subnet_cidrs = ["10.20.1.0/24", "10.20.2.0/24"]
public_subnet_cidrs  = ["10.20.101.0/24", "10.20.102.0/24"]
intra_subnet_cidrs   = ["10.20.201.0/24", "10.20.202.0/24"]
single_nat_gateway   = true

# EKS — slightly larger for integration test load
eks_cluster_version    = "1.29"
eks_node_min_size      = 1
eks_node_max_size      = 3
eks_node_desired_size  = 2
eks_node_instance_type = "t3.large"

# RDS — small, no HA
rds_engine_version      = "16.1"
rds_instance_class      = "db.t3.small"
rds_allocated_storage   = 50
rds_db_name             = "myappsit"
rds_username            = "dbadmin"
rds_multi_az            = false
rds_deletion_protection = false
rds_skip_final_snapshot = true
rds_backup_retention    = 3

# ElastiCache
redis_engine_version     = "7.1"
redis_node_type          = "cache.t3.small"
redis_num_cache_clusters = 1

# Secrets Manager
secrets_recovery_window = 7

# CloudFront
cloudfront_aliases  = ["sit.myapp.example.com"]
acm_certificate_arn = ""
