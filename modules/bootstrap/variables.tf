variable "project_name" {
  description = "Name prefix for backend resources."
  type        = string
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name. Leave empty to use project_name-environment."
  type        = string
  default     = ""
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for Terraform state locking. Leave empty to use project_name-tfstate-locks."
  type        = string
  default     = ""
}
