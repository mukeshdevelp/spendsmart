variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "iam_role_name_suffix" {
  description = "Suffix for the IAM role name"
  type        = string
  default     = "-analytics-role"
}

variable "iam_policy_name_suffix" {
  description = "Suffix for the IAM policy name"
  type        = string
  default     = "-analytics-policy"
}

variable "trusted_principal_type" {
  description = "Type of principal that can assume the IAM role"
  type        = string
  default     = "AWS"

  validation {
    condition     = contains(["AWS", "Service"], var.trusted_principal_type)
    error_message = "trusted_principal_type must be AWS or Service."
  }
}

variable "trusted_principal_identifiers" {
  description = "ARNs or service principals allowed to assume the role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}