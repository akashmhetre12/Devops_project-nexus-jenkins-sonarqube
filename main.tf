provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.tags
  )
}

# ── VPC ──────────────────────────────────────────────────────────────
module "vpc" {
  source = "git::https://github.com/ygminds73/terraform-module-vpc.git"

  cidr_block = var.vpc_cidr
  vpc_name   = "${local.name_prefix}-vpc"
  tags       = local.common_tags
}

resource "aws_internet_gateway" "our-igw" { # "aws_internet_gateway" will help to create igw abd our-igw is code name 
  vpc_id = module.vpc.vpc_id  # This will attach igw to the vpc
  tags = {  # This will tag the igw
    Name : "Our-IGW" # this is the name of the IGW
    Environment : var.environment # this is the environment in which we are launching the IGW
  }
}

resource "aws_route_table" "our-public-route-table" { # creating a new route table with help of "aws_route_table"
  vpc_id = module.vpc.vpc_id # new route table will be created in this vpc 
  tags = {
    Name : "Our-Public-Route-Table"
    Environment : var.environment
  }
}

resource "aws_route_table" "our-public-route-table2" { # creating a new route table with help of "aws_route_table"
  vpc_id = module.vpc.vpc_id # new route table will be created in this vpc 
  tags = {
    Name : "Our-Public-Route-Table"
    Environment : var.environment
  }
}
resource "aws_route_table" "our-private-route-table" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name : "Our-Private-Route-Table"
    Environment : var.environment
  }
}

resource "aws_route_table" "our-private-route-table2" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name : "Our-Private-Route-Table"
    Environment : var.environment
  }
}

########################################################################################
# AWS SUBNET ROUTE TABLE ASSOCIATION
########################################################################################

resource "aws_route_table_association" "our-public-route-table-association" { # This will associate route table with subnet
  subnet_id      = module.subnets["public-subnet-1"].subnet_id # This will associate route table with subnet
  route_table_id = aws_route_table.our-public-route-table.id # This is the route table which will be associated with
}

resource "aws_route_table_association" "our-public-route-table-association2" { # This will associate route table with subnet
  subnet_id      = module.subnets["public-subnet-2"].subnet_id # This will associate route table with subnet
  route_table_id = aws_route_table.our-public-route-table2.id # This is the route table which will be associated with
}

resource "aws_route_table_association" "our-private-route-table-association" {
  subnet_id      = module.subnets["private-subnet-1"].subnet_id
  route_table_id = aws_route_table.our-private-route-table.id
}

resource "aws_route_table_association" "our-private-route-table-association2" {
  subnet_id      = module.subnets["private-subnet-2"].subnet_id
  route_table_id = aws_route_table.our-private-route-table2.id
}

########################################################################################
# AWS ROUTE ADDITION INTO ROUTE TABLES
########################################################################################

resource "aws_route" "our-public-route" { # This will create routes inside route table
  route_table_id         = aws_route_table.our-public-route-table.id # this the route table in which routes will be created
  destination_cidr_block = "0.0.0.0/0" # this is the route for internet connections
  gateway_id             = aws_internet_gateway.our-igw.id # This is internet gateway to the route traffic to internet connections
}

resource "aws_route" "our-public-route2" { # This will create routes inside route table
  route_table_id         = aws_route_table.our-public-route-table2.id # this the route table in which routes will be created
  destination_cidr_block = "0.0.0.0/0" # this is the route for internet connections
  gateway_id             = aws_internet_gateway.our-igw.id # This is internet gateway to the route traffic to internet connections
}



# ── Subnets (4 subnets via for_each) ─────────────────────────────────
module "subnets" {
  source = "git::https://github.com/ygminds73/terraform-module-subnet.git"

  for_each          = var.subnets
  subnet_name       = "${local.name_prefix}-${each.key}"
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  vpc_id            = module.vpc.vpc_id
  is_public         = each.value.is_public
  tags              = merge(local.common_tags, { SubnetType = each.value.is_public ? "public" : "private" })
}

# ── EC2 Instances (2 instances via for_each) ─────────────────────────
resource "aws_instance" "nexus-server" {   # we are creating a new instance for jenkins-server
    ami = "ami-006f82a1d5a27da54"
    # we are using the latest ami that we fetched earlier
    instance_type = "m7i-flex.large"     # This is the type of the instance we are creating
    subnet_id     = module.subnets["public-subnet-1"].subnet_id   # this is the id of the subnet we are using to launch the instance
    user_data = file("./install-nexus-docker.sh")  # this is the script that will be executed during the creation of the instance
    key_name = "Mumbai" # this is the key name that we have created in console
    root_block_device {
      volume_size = 20
    }

    tags = {
        Name = "nexus-server"  # this will provide name to instance 
    }
}

resource "aws_instance" "sonarqube-server" {   # we are creating a new instance for jenkins-server
    ami = "ami-006f82a1d5a27da54"
    # we are using the latest ami that we fetched earlier
    instance_type = "c7i-flex.large"     # This is the type of the instance we are creating
    subnet_id     = module.subnets["public-subnet-2"].subnet_id   # this is the id of the subnet we are using to launch the instance
    user_data = file("./install-sonarqube-docker.sh")  # this is the script that will be executed during the creation of the instance
    key_name = "Mumbai" # this is the key name that we have created in console
    root_block_device {
      volume_size = 20
    }

    tags = {
        Name = "sonarqube-server"  # this will provide name to instance 
    }
}

/*
# ── S3 Bucket ─────────────────────────────────────────────────────────
module "s3_bucket" {
  source = "git::https://github.com/ygminds73/terraform-module-s3.git"

  bucket_name = "${local.name_prefix}-${var.bucket_suffix}"
  environment = var.environment
  tags        = merge(local.common_tags, { Purpose = "storage" })
}

*/