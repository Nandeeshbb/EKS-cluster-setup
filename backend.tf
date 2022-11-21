terraform {
  backend "s3" {
    bucket = "terraform-miq-develop"
    key    = "eks-dev/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-lock-dynamo"
  }
}
