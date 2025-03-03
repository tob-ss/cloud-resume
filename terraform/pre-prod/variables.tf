variable "region" {
    description = "AWS region"
    type        = string
    default     = "eu-west-2"
  }

variable "aws_profile" {
    description = "AWS CLI profile to use"
    type        = string
    default     = "pre-prod"
  }

variable "environment" {
    description = "Environment name"
    type        = string
    default     = "pre-prod"
  }

variable "website_bucket_name" {
    description = "S3 bucket name for website hosting"
    type        = string
  }

variable "tags" {
    description = "Tags to apply to resources"
    type        = map(string)
    default = {
      Project     = "Cloud Resume Challenge"
      ManagedBy   = "Terraform"
      Environment = "pre-prod"
    }
  }


variable "domain_name" {
    description = "Domain name for the website"
    type        = string
  }

variable "hosted_zone_id" {
    description = "Route 53 hosted zone ID for the domain"
    type        = string
  }