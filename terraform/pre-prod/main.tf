provider "aws" {
    region  = var.region
    profile = var.aws_profile
  }

provider "aws" {
    alias   = "us_east_1"
    region  = "us-east-1"
    profile = var.aws_profile  
}

module "frontend" {
    source = "./terraform/modules/frontend"

    bucket_name    = var.website_bucket_name
    environment    = var.environment
    tags           = var.tags
    domain_name    = var.domain_name
    hosted_zone_id = var.hosted_zone_id  # Use the hosted zone ID from variables
  }