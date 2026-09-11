variable "name_prefix" {
  description = "Prefix for resource names."
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

variable "public_subnet_id" {
  description = "Public subnet ID for the bastion."
  type        = string
}

variable "bastion_security_group_id" {
  description = "Bastion security group ID."
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
