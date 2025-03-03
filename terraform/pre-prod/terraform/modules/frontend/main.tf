terraform {
    required_providers {
      aws = {
        source                = "hashicorp/aws"
        configuration_aliases = [aws.us_east_1]
      }
    }
  }

provider "aws" {
    alias  = "us_east_1"
    region = "us-east-1"
  }

# S3 bucket for website hosting
resource "aws_s3_bucket" "website" {
    bucket = var.bucket_name

    tags = merge(
      var.tags,
      {
        Name        = var.bucket_name
        Environment = var.environment
      }
    )
  }

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
    bucket = aws_s3_bucket.website.id

    index_document {
      suffix = "index.html"
    }

    error_document {
      key = "error.html"
    }
  }

# Block public access
resource "aws_s3_bucket_public_access_block" "website" {
    bucket = aws_s3_bucket.website.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

# Bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "website" {
    bucket = aws_s3_bucket.website.id

    rule {
      object_ownership = "BucketOwnerPreferred"
    }
  }

# ACM Certificate for HTTPS
resource "aws_acm_certificate" "cert" {
    provider                  = aws.us_east_1  
    domain_name               = var.domain_name
    subject_alternative_names = ["*.${var.domain_name}"]
    validation_method         = "DNS"

    tags = merge(
      var.tags,
      {
        Name        = "${var.environment}-certificate"
        Environment = var.environment
      }
    )

    lifecycle {
      create_before_destroy = true
    }
  }

  # DNS Validation records
resource "aws_route53_record" "cert_validation" {
    for_each = {
      for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    }

    allow_overwrite = true
    name            = each.value.name
    records         = [each.value.record]
    ttl             = 60
    type            = each.value.type
    zone_id         = var.hosted_zone_id
  }

  # Certificate validation
resource "aws_acm_certificate_validation" "cert" {
    provider                = aws.us_east_1
    certificate_arn         = aws_acm_certificate.cert.arn
    validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  }

  # CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "oai" {
    comment = "OAI for ${var.domain_name}"
  }

  # S3 bucket policy
resource "aws_s3_bucket_policy" "website" {
    bucket = aws_s3_bucket.website.id
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Principal = {
            AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.oai.id}"
          }
          Action    = "s3:GetObject"
          Resource  = "${aws_s3_bucket.website.arn}/*"
        }
      ]
    })
  }

  # CloudFront distribution
resource "aws_cloudfront_distribution" "website" {
    origin {
      domain_name = aws_s3_bucket.website.bucket_regional_domain_name
      origin_id   = aws_s3_bucket.website.bucket_regional_domain_name

      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
      }
    }

    enabled             = true
    is_ipv6_enabled     = true
    default_root_object = "index.html"
    aliases             = [var.domain_name]

    default_cache_behavior {
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = aws_s3_bucket.website.bucket_regional_domain_name

      forwarded_values {
        query_string = false
        cookies {
          forward = "none"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 3600
      max_ttl                = 86400
    }

    restrictions {
      geo_restriction {
        restriction_type = "none"
      }
    }

    viewer_certificate {
      acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }

    price_class = "PriceClass_100"

    tags = merge(
      var.tags,
      {
        Name        = "${var.domain_name}-cloudfront"
        Environment = var.environment
      }
    )
  }

  # Route 53 record for CloudFront
resource "aws_route53_record" "website" {
    zone_id = var.hosted_zone_id
    name    = var.domain_name
    type    = "A"

    alias {
      name                   = aws_cloudfront_distribution.website.domain_name
      zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
      evaluate_target_health = false
    }
  }