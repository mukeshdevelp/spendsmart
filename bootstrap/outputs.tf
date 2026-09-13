output "bucket_name" {
  description = "Shared S3 bucket name."
  value       = module.bootstrap.bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  value       = module.bootstrap.dynamodb_table_name
}

output "backend_region" {
  description = "Region of the state backend."
  value       = var.aws_region
}
