output "bucket_name" {
  description = "Shared S3 bucket name."
  value       = aws_s3_bucket.storage.id
}

output "bucket_arn" {
  description = "Shared S3 bucket ARN."
  value       = aws_s3_bucket.storage.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.state_lock.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN for Terraform state locking."
  value       = aws_dynamodb_table.state_lock.arn
}
