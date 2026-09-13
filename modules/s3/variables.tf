variable "bucket_name" {
  description = "Shared S3 bucket name (created by bootstrap)."
  type        = string
}

variable "data_prefix" {
  description = "S3 key prefix for Glue / data-lake objects."
  type        = string
  default     = "data"
}

variable "athena_results_prefix" {
  description = "S3 key prefix for Athena query results."
  type        = string
  default     = "athena-results"
}
