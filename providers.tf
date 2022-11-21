#
# Provider Configuration
#

# provider "aws" {
#   region = "us-east-1"
#   version = "3.14.1"
#   profile = var.aws_profile
# }

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.42.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 1.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  #profile = var.aws_profile
}

# provider "aws" {
#   alias  = "peer"
#   region = "eu-west-2"
#   profile = var.aws_profile
#   # Accepter's credentials.
# }

# Using these data sources allows the configuration to be
# generic for any region.
data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

# Not required: currently used in conjuction with using
# icanhazip.com to determine local workstation external IP
# to open EC2 Security Group access to the Kubernetes cluster.
# provider "http" {
#   version = "~> 1.0"
# }
