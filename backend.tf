# Rename this file to backend.tf only after the S3 bucket exists. Then replace
# the example bucket value with `terraform output bucket_name` and run
# `terraform init -migrate-state`.
terraform {
  backend "s3" {
    bucket       = var.bucket_name
    key          = var.state_file_key
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}
