# terraform backend configs
terraform {
  backend "s3" {
    bucket         = "spendsmart-dev"
    key            = "aws/infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "spendsmart-tfstate-locks"
    encrypt        = true
  }
}
