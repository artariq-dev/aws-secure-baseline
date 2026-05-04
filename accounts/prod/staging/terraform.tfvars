aws_region  = "us-east-1"
environment = "staging"
project     = "myapp"
owner       = "platform-team"
cost_center = "engineering"

# Networking — 3 AZs, HA NAT gateways for production parity
vpc_cidr             = "10.30.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnet_cidrs = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
public_subnet_cidrs  = ["10.30.101.0/24", "10.30.102.0/24", "10.30.103.0/24"]
intra_subnet_cidrs   = ["10.30.201.0/24", "10.30.202.0/24", "10.30.203.0/24"]
single_nat_gateway   = false

# EKS — production-grade instances, 3-node baseline
eks_cluster_version    = "1.29"
eks_node_min_size      = 2
eks_node_max_size      = 6
eks_node_desired_size  = 3
eks_node_instance_type = "m5.large"

# RDS — Multi-AZ, deletion protection, final snapshot
rds_engine_version      = "16.1"
rds_instance_class      = "db.m5.large"
rds_allocated_storage   = 100
rds_db_name             = "myappstaging"
rds_username            = "dbadmin"
rds_multi_az            = true
rds_deletion_protection = true
rds_skip_final_snapshot = false
rds_backup_retention    = 7

# ElastiCache — 2-node cluster for HA
redis_engine_version     = "7.1"
redis_node_type          = "cache.m5.large"
redis_num_cache_clusters = 2

# Secrets Manager
secrets_recovery_window = 30

# CloudFront
cloudfront_aliases  = ["staging.myapp.example.com"]
acm_certificate_arn = ""
