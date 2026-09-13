variable "athena_output_location" {
  description = "S3 URI prefix for Athena query results (must end with /)."
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
