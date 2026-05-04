aws_region  = "us-east-1"
environment = "prod"
project     = "myapp"
owner       = "platform-team"
cost_center = "engineering"

# Networking — 3 AZs, HA NAT gateways
vpc_cidr             = "10.40.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnet_cidrs = ["10.40.1.0/24", "10.40.2.0/24", "10.40.3.0/24"]
public_subnet_cidrs  = ["10.40.101.0/24", "10.40.102.0/24", "10.40.103.0/24"]
intra_subnet_cidrs   = ["10.40.201.0/24", "10.40.202.0/24", "10.40.203.0/24"]
single_nat_gateway   = false

# EKS — production sizing with room to scale
eks_cluster_version    = "1.29"
eks_node_min_size      = 3
eks_node_max_size      = 20
eks_node_desired_size  = 5
eks_node_instance_type = "m5.xlarge"

# RDS — largest class, full HA, maximum retention
rds_engine_version      = "16.1"
rds_instance_class      = "db.m5.2xlarge"
rds_allocated_storage   = 500
rds_db_name             = "myappprod"
rds_username            = "dbadmin"
rds_multi_az            = true
rds_deletion_protection = true
rds_skip_final_snapshot = false
rds_backup_retention    = 35

# ElastiCache — 3-node cluster
redis_engine_version     = "7.1"
redis_node_type          = "cache.m5.xlarge"
redis_num_cache_clusters = 3

# Secrets Manager — 30-day recovery window
secrets_recovery_window = 30

# CloudFront — apex and www aliases
cloudfront_aliases  = ["myapp.example.com", "www.myapp.example.com"]
acm_certificate_arn = ""
