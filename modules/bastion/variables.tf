variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the bastion."
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for ClickHouse."
  type        = string
}

variable "bastion_enabled" {
  description = "Create the bastion host."
  type        = bool
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host."
  type        = string
}

variable "bastion_associate_eip" {
  description = "Allocate and associate an Elastic IP with the bastion."
  type        = bool
}

variable "bastion_allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to the bastion."
  type        = list(string)
}

variable "create_ssh_key" {
  description = "Create an EC2 key pair and store the private key in Secrets Manager."
  type        = bool
}

variable "ssh_key_name" {
  description = "EC2 key pair name. Leave empty to use name_prefix-ssh-key."
  type        = string
  default     = ""
}

variable "ssh_private_key_secret_name" {
  description = "Secrets Manager secret name for the SSH private key PEM."
  type        = string
  default     = ""
}

variable "ssh_key_secret_recovery_window_days" {
  description = "Days to retain the secret after delete."
  type        = number
  default     = 7
}

variable "bastion_key_name" {
  description = "Existing EC2 key pair when create_ssh_key is false."
  type        = string
  default     = ""
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

variable "clickhouse_http_port" {
  description = "ClickHouse HTTP port."
  type        = number
}

variable "clickhouse_native_port" {
  description = "ClickHouse native TCP port."
  type        = number
}
