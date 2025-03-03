variable "environment" {
    description = "Environment (e.g., pre-prod, prod)"
    type        = string
  }

  variable "tags" {
    description = "Tags to apply to resources"
    type        = map(string)
    default     = {}
  }