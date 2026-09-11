variable "athena_results_bucket_name" {
  description = "S3 bucket name for Athena query results."
  type        = string
}

variable "athena_workgroup_name" {
  description = "Athena workgroup name."
  type        = string
}

variable "athena_bytes_scanned_cutoff" {
  description = "Athena per-query bytes-scanned cutoff. Set 0 to disable."
  type        = number
}
