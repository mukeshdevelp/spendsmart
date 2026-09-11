variable "eks_cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}
