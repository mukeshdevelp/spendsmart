variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "clickhouse_enabled" {
  description = "Create ClickHouse instance."
  type        = bool
}

variable "clickhouse_instance_type" {
  description = "EC2 instance type for ClickHouse."
  type        = string
}

variable "clickhouse_root_volume_size" {
  description = "Root EBS volume size in GiB for ClickHouse."
  type        = number
}

variable "clickhouse_data_volume_size" {
  description = "Additional data EBS volume size in GiB for ClickHouse."
  type        = number
}

variable "private_subnet_id" {
  description = "Private subnet ID for ClickHouse."
  type        = string
}

variable "clickhouse_security_group_id" {
  description = "ClickHouse security group ID."
  type        = string
}

variable "ec2_ssm_instance_profile_name" {
  description = "EC2 SSM instance profile name."
  type        = string
}

variable "ec2_key_name" {
  description = "EC2 key pair name."
  type        = string
  default     = null
}
