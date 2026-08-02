variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment (dev, uat, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "myapp"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    cidr      = string
    az        = string
    is_public = bool
  }))
}

variable "bucket_suffix" {
  description = "Unique suffix for the S3 bucket name"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources via map meta-argument"
  type        = map(string)
  default     = {}
}

variable "instance_port" {
  description = "Port the application listens on inside the instance"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Path the ALB target group uses for health checks"
  type        = string
  default     = "/health"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID to launch"
  type        = string
  default     = "ami-0ae1a64593f9b9bbe" # Amazon Linux 2 AMI (HVM), SSD Volume Type
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "instance_port-alb" {
  description = "Port the application listens on inside the instance"
  type        = number
  default     = 8080
}
