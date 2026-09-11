output "athena_results_bucket_name" {
  description = "S3 bucket for Athena query results."
  value       = aws_s3_bucket.athena_results.id
}

output "athena_workgroup_name" {
  description = "Athena workgroup name."
  value       = aws_athena_workgroup.this.name
}
