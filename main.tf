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

# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow inbound HTTP/HTTPS to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-alb-sg" })
}

resource "aws_security_group" "instance" {
  name        = "${local.name_prefix}-instance-sg"
  description = "Allow traffic from ALB and SSH from allowed range"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "App traffic from ALB"
    from_port       = var.instance_port
    to_port         = var.instance_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH for deployment"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["223.233.81.138/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-instance-sg" })
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
    instance_type = "m7i-flex.large"     # This is the type of the instance we are creating
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

# ---------------------------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------------------------

resource "aws_lb" "this" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [module.subnets["public-subnet-1"].subnet_id, module.subnets["public-subnet-2"].subnet_id]

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-alb" })
}

resource "aws_lb_target_group" "this" {
  name     = "${local.name_prefix}-tg"
  port     = var.instance_port-alb
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  # Important for rolling deploys: allow in-flight requests to finish
  deregistration_delay = 30

  tags = local.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# ---------------------------------------------------------------------------
# Launch Template
# ---------------------------------------------------------------------------
# NOTE ON YOUR SSH-DEPLOY -> AMI WORKFLOW:
# Initially point ami_id at a base AMI (e.g. Amazon Linux/RHEL) with only
# the runtime (Java) baked in. Deploy your JAR/WAR over SSH to a running
# instance, validate it, then create a new AMI from that instance
# (aws_ami_from_instance, or `aws ec2 create-image` in your Jenkins stage).
# Feed the new AMI ID back into this launch template (var.ami_id) and run
# `terraform apply` to trigger an Instance Refresh, which cycles the ASG
# onto the new golden image with zero manual instance handling.

resource "aws_launch_template" "this" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = "Mumbai"

  vpc_security_group_ids = [aws_security_group.instance.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type            = "gp3"
      delete_on_termination = true
      encrypted              = true
    }
  }

  metadata_options {
    http_tokens   = "required" # enforce IMDSv2
    http_endpoint = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${local.name_prefix}-instance" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Auto Scaling Group
# ---------------------------------------------------------------------------

resource "aws_autoscaling_group" "this" {
  name                = "${local.name_prefix}-asg"
  vpc_zone_identifier = [module.subnets["private-subnet-1"].subnet_id, module.subnets["private-subnet-2"].subnet_id]
  target_group_arns   = [aws_lb_target_group.this.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 120

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # Rolling replacement whenever the launch template (i.e. AMI) changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 90
    }
    triggers = ["launch_template"]
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${local.name_prefix}-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}
