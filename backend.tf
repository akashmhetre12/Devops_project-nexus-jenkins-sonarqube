terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment for remote state (recommended for teams)
   backend "s3" {
     bucket         = "devops-projects-terraform-state"
     key            = "dev/terraform.tfstate"
     region         = "ap-south-1"
     dynamodb_table = "terraform-lock"
     encrypt        = true
  }
}
