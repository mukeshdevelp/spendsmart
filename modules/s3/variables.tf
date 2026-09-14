variable "bucket_name" {
  description = "Globally unique S3 bucket name."
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

variable "force_destroy" {
  description = "Allow bucket deletion when empty. Keep false to retain data on destroy."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable S3 bucket versioning."
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm for the bucket."
  type        = string
  default     = "AES256"
}

variable "bucket_key_enabled" {
  description = "Enable S3 bucket keys for SSE."
  type        = bool
  default     = true
}

variable "block_public_acls" {
  description = "Block public ACLs on the bucket."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs on the bucket."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies."
  type        = bool
  default     = true
}

variable "athena_results_expiration_days" {
  description = "Days before Athena result objects expire. Set 0 to disable expiration."
  type        = number
  default     = 30
}

variable "athena_lifecycle_rule_id" {
  description = "Lifecycle rule ID for Athena result object expiration."
  type        = string
  default     = "expire-athena-results"
}
