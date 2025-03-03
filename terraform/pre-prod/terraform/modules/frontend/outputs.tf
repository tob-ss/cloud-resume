output "bucket_id" {
    description = "The name of the bucket"
    value       = aws_s3_bucket.website.id
  }

output "bucket_arn" {
    description = "The ARN of the bucket"
    value       = aws_s3_bucket.website.arn
  }

output "bucket_regional_domain_name" {
    description = "The regional domain name of the bucket"
    value       = aws_s3_bucket.website.bucket_regional_domain_name
  }

output "cloudfront_distribution_id" {
    description = "The CloudFront distribution ID"
    value       = aws_cloudfront_distribution.website.id
  }

output "cloudfront_domain_name" {
    description = "The CloudFront distribution domain name"
    value       = aws_cloudfront_distribution.website.domain_name
  }

output "website_endpoint" {
    description = "The website endpoint"
    value       = "https://${var.domain_name}"
  }