terraform {
    backend "s3" {
        bucket          = "prod-tfstate-cloudresumetoba"
        key             = "terraform.tfstate"
        region          = "eu-west-2"
        dynamodb_table  = "terraform-state-locking-prod"
        encrypt         = true
    }
}