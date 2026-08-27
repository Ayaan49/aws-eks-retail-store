# Environment & Region 
environment_name = "dev"
aws_region       = "us-east-1"

# CIDR for VPC
vpc_cidr = "10.0.0.0/16"

# Subnet mask (/24 subnets)
subnet_newbits = 8

# Tags 
tags = {
  Terraform   = "true"
  Project     = "retail-store"
  Owner       = "your-name"
}