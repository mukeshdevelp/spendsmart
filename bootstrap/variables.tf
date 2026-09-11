# Region for bootstrap
variable "aws_region" {
  description = "AWS region for the Terraform state backend."
  type        = string
  default     = "us-east-1"
}
# Project name
variable "project_name" {
  description = "Name prefix for backend resources."
  type        = string
  default     = "spendsmart"
}
# S3 bucket name
variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state."
  type        = string
  default     = ""
}
# DynamoDB table name
variable "dynamodb_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
  default     = ""
}

# Generalized tags
variable "tags" {
  description = "Tags applied to backend resources."
  type        = map(string)
  default = {
    Project   = "spendsmart"
    ManagedBy = "terraform"
    Component = "tfstate-backend"
  }
}
