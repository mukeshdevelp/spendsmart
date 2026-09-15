variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the bastion."
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

variable "bastion_root_volume_size" {
  description = "Root EBS volume size in GiB for the bastion."
  type        = number
}

variable "bastion_root_volume_type" {
  description = "Root EBS volume type for the bastion."
  type        = string
}

variable "bastion_ami_ssm_parameter" {
  description = "SSM parameter path for the bastion AMI."
  type        = string
}

variable "bastion_associate_eip" {
  description = "Allocate and associate an Elastic IP with the bastion."
  type        = bool
}

variable "ec2_key_name" {
  description = "Name of an existing EC2 key pair to validate and attach to EC2 instances."
  type        = string
}
/*
variable "ec2_ssm_policy_arn" {
  description = "IAM policy ARN for SSM on the bastion."
  type        = string
}
*/  

variable "bastion_ssh_port" {
  description = "TCP port for SSH ingress to the bastion security group."
  type        = number
  default     = 22
}

variable "bastion_allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to the bastion."
  type        = list(string)
  default     = []
}

variable "bastion_egress_cidrs" {
  description = "CIDR blocks allowed for bastion egress."
  type        = string

}
variable "vpc_id" {
  description = "VPC ID where the bastion security group and EC2 instance are created."
  type        = string
}
