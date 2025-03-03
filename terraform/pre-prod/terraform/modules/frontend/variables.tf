variable "bucket_name" {
    description = "Name of the S3 bucket for website hosting"
    type        = string
  }

variable "tags" {
    description = "Tags to apply to resources"
    type        = map(string)
    default     = {}
  }

variable "environment" {
    description = "Environment (e.g., pre-prod, prod)"
    type        = string
  }


variable "domain_name" {
    description = "Domain name for the website"
    type        = string
  }

variable "hosted_zone_id" {
    description = "Route 53 hosted zone ID"
    type        = string
  }