provider "aws" {
    profile = "prod"
    region = "eu-west-2"
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "prod-tfstate-cloudresumetoba"

    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
    bucket      = aws_s3_bucket.terraform_state.bucket
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

resource "aws_dynamodb_table" "terraform_locks" {
    name        = "terraform-state-locking-prod"
    billing_mode = "PAY_PER_REQUEST"
    hash_key    = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
}