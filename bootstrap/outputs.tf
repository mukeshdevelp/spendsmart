# OP - remote bucket state name
output "state_bucket_name" {
  description = "S3 bucket that stores Terraform state."

  value = aws_s3_bucket.remote_backend.id
}

# OP - dynamo table name
output "dynamodb_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.state_lock.name
}

# OP - backend region for bucket
output "backend_region" {
  description = "Region of the state backend."
  value       = var.aws_region
}
