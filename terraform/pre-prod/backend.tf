terraform {
    backend "s3" {
        bucket          = "preprod-tfstate-cloudresumetoba"
        key             = "terraform.tfstate"
        region          = "eu-west-2"
        dynamodb_table  = "terraform-state-locking"
        encrypt         = true
    }
}