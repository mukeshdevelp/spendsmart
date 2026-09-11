variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks."
  type        = list(string)
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "bastion_enabled" {
  description = "Create bastion security group."
  type        = bool
}

variable "bastion_allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to the bastion."
  type        = list(string)
}

variable "alb_enabled" {
  description = "Create ALB security group."
  type        = bool
}

variable "alb_target_port" {
  description = "ALB target group port for node ingress rule."
  type        = number
}

variable "clickhouse_enabled" {
  description = "Create ClickHouse security group."
  type        = bool
}

variable "clickhouse_http_port" {
  description = "ClickHouse HTTP port."
  type        = number
}

variable "clickhouse_native_port" {
  description = "ClickHouse native TCP port."
  type        = number
}

variable "eks_cluster_name" {
  description = "EKS cluster name for node security group tags."
  type        = string
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
