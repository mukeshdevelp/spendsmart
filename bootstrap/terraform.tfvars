aws_region   = "us-east-1"
project_name = "spendsmart"
environment  = "dev"

# Leave empty to use spendsmart-dev (must match backend.tf and root terraform.tfvars)
bucket_name = ""

dynamodb_table_name = ""

tags = {
  Project     = "spendsmart"
  Environment = "dev"
  ManagedBy   = "terraform"
  Component   = "storage-backend"
}
