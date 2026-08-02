environment   = "dev"
project_name  = "myapp"
aws_region    = "ap-south-1"
vpc_cidr      = "10.0.0.0/16"
bucket_suffix = "assets-dev-20240102"

tags = {
  Owner      = "dev-team"
  CostCenter = "cc-dev-001"
  Terraform  = "true"
}

subnets = {
  "public-subnet-1"  = { cidr = "10.0.1.0/24", az = "ap-south-1a", is_public = true }
  "public-subnet-2"  = { cidr = "10.0.2.0/24", az = "ap-south-1b", is_public = true }
  "private-subnet-1" = { cidr = "10.0.3.0/24", az = "ap-south-1a", is_public = false }
  "private-subnet-2" = { cidr = "10.0.4.0/24", az = "ap-south-1b", is_public = false }
}

ami_id = ""
