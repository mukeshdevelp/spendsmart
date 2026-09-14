output "bucket_name" {
  description = "Shared S3 bucket name."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "Shared S3 bucket ARN."
  value       = aws_s3_bucket.this.arn
}

output "data_prefix" {
  description = "S3 key prefix for Glue / data-lake objects."
  value       = var.data_prefix
}

output "data_location" {
  description = "S3 URI for Glue / data-lake objects."
  value       = "s3://${aws_s3_bucket.this.id}/${var.data_prefix}/"
}

output "athena_results_prefix" {
  description = "S3 key prefix for Athena query results."
  value       = var.athena_results_prefix
}

output "athena_output_location" {
  description = "S3 URI for Athena query results."
  value       = "s3://${aws_s3_bucket.this.id}/${var.athena_results_prefix}/"
}
