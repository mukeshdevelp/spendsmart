variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the shared S3 bucket."
  type        = string
}

variable "data_prefix" {
  description = "S3 key prefix for Glue / data-lake objects."
  type        = string
}

variable "glue_database_name" {
  description = "Glue Data Catalog database name."
  type        = string
}
