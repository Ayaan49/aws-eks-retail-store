# AWS Region and Environment
aws_region = "us-east-1"
environment_name = "dev"
business_division = "retail"

# EKS Cluster 
cluster_name = "eksdemo1"
cluster_service_ipv4_cidr = "172.20.0.0/16"
cluster_version = "1.33"

# EKS Cluster Access Control
cluster_endpoint_private_access = false
cluster_endpoint_public_access = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

# EKS Node Group Configuration
node_instance_types = ["t3.large"] # Replace with desired types
node_capacity_type = "ON_DEMAND"   # or "SPOT"
node_disk_size = 20


