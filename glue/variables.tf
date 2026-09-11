variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "data_bucket_name" {
  description = "S3 data-lake bucket name."
  type        = string
}

variable "glue_database_name" {
  description = "Glue Data Catalog database name."
  type        = string
}
