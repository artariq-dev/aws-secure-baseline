aws_region  = "us-east-1"
environment = "dev"
project     = "myapp"
owner       = "platform-team"
cost_center = "engineering"

# Networking — single NAT gateway for cost saving in dev
vpc_cidr             = "10.10.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
private_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
public_subnet_cidrs  = ["10.10.101.0/24", "10.10.102.0/24"]
intra_subnet_cidrs   = ["10.10.201.0/24", "10.10.202.0/24"]
single_nat_gateway   = true

# EKS — minimal for dev
eks_cluster_version    = "1.29"
eks_node_min_size      = 1
eks_node_max_size      = 3
eks_node_desired_size  = 1
eks_node_instance_type = "t3.medium"

# RDS — small, no HA, immediate delete ok
rds_engine_version      = "16.1"
rds_instance_class      = "db.t3.micro"
rds_allocated_storage   = 20
rds_db_name             = "myappdev"
rds_username            = "dbadmin"
rds_multi_az            = false
rds_deletion_protection = false
rds_skip_final_snapshot = true
rds_backup_retention    = 1

# ElastiCache — smallest node for dev
redis_engine_version     = "7.1"
redis_node_type          = "cache.t3.micro"
redis_num_cache_clusters = 1

# Secrets Manager — immediate delete in dev (no recovery window)
secrets_recovery_window = 0

# CloudFront — update acm_certificate_arn after cert is created
cloudfront_aliases  = ["dev.myapp.example.com"]
acm_certificate_arn = ""
