# Rename this file to backend.tf only after the S3 bucket exists. Then replace
# the example bucket value with `terraform output bucket_name` and run
# `terraform init -migrate-state`.
terraform {
  backend "s3" {
    bucket       = "spendsmart-dev-123456789012"
    key          = "aws/infra/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
