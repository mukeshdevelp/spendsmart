output "data_bucket_name" {
  description = "S3 data-lake bucket name."
  value       = aws_s3_bucket.data.id
}

output "glue_database_name" {
  description = "Glue Data Catalog database name."
  value       = aws_glue_catalog_database.this.name
}

output "glue_role_arn" {
  description = "IAM role ARN for Glue jobs and crawlers."
  value       = aws_iam_role.glue.arn
}
