provider "aws" {
    region          = "us-east-1"
}

terraform {
    backend "s3" {
        bucket          = "rvmey-terraform-deployments"
        key             = "demos/tfkube.tfstate"

        region          = "us-east-1"
        dynamodb_table  = "rvmey-terraform-deployments"
    }
}