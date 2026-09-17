# SpendSmart AWS Infrastructure

Terraform infrastructure for the **SpendSmart** platform.

This Terraform project provisions the core AWS infrastructure required by SpendSmart, including networking, Bastion access, Amazon EKS, Application Load Balancer, S3, Glue, Athena, and IAM resources.

* VPC networking across two Availability Zones.
* Public and private subnets.
* Internet Gateway and NAT Gateway.
* Bastion EC2 host.
* Amazon EKS cluster with EC2 managed node groups.
* EKS IAM roles, security groups, and managed add-ons.
* Internet-facing Application Load Balancer.
* S3 analytics bucket.
* AWS Glue Data Catalog.
* Amazon Athena workgroup.
* IAM roles and policies for analytics services.

<img width="727" height="810" alt="image" src="https://github.com/user-attachments/assets/fd7b5b04-289d-40c4-b606-684b16524a43" />


## Usage

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# cluster
resource "aws_eks_cluster" "this" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_cluster_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.eks_endpoint_private_access
    endpoint_public_access  = var.eks_endpoint_public_access
  }

  access_config {
    authentication_mode                         = var.eks_authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.eks_bootstrap_cluster_creator_admin_permissions
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]
}



# EKS NODE SECURITY GROUP

# security group for EKS nodes
resource "aws_security_group" "eks_nodes" {
  name        = local.eks_nodes_security_group_name
  description = var.eks_nodes_security_group_description
  vpc_id      = var.vpc_id

  tags = {
    Name                              = local.eks_nodes_security_group_name
    (local.eks_nodes_cluster_tag_key) = var.eks_nodes_cluster_tag_value
  }
}

# security group ingress for node to node communication
resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = var.eks_nodes_self_ingress_description
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# security group ingress for node - allows ssh access from bastion to nodes
resource "aws_vpc_security_group_ingress_rule" "nodes_ssh_from_bastion" {
  # count = var.bastion_enabled ? 1 : 0

  security_group_id            = aws_security_group.eks_nodes.id
  description                  = var.eks_nodes_ssh_ingress_description
  ip_protocol                  = "tcp"
  from_port                    = var.nodes_ssh_port
  to_port                      = var.nodes_ssh_port
  referenced_security_group_id = var.bastion_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "nodes_egress" {
  for_each = toset(var.nodes_egress_cidrs)

  security_group_id = aws_security_group.eks_nodes.id
  description       = var.eks_nodes_egress_description
  ip_protocol       = "-1"
  cidr_ipv4         = each.value
}



## Inputs

| Name                          | Description                                   | Type         | Default              | Required |
| ----------------------------- | --------------------------------------------- | ------------ | -------------------- | -------- |
| `aws_region`                  | AWS region for the infrastructure             | string       | `us-east-1`          | yes      |
| `project_name`                | Project name                                  | string       | `spendsmart`         | yes      |
| `environment`                 | Deployment environment                        | string       | `dev`                | yes      |
| `vpc_cidr`                    | CIDR block for the VPC                        | string       | `10.0.0.0/16`        | yes      |
| `availability_zones`          | Availability Zones used by the infrastructure | list(string) | `[]`                 | yes      |
| `public_subnet_cidrs`         | CIDRs for public subnets                      | list(string) | `[]`                 | yes      |
| `private_subnet_cidrs`        | CIDRs for private subnets                     | list(string) | `[]`                 | yes      |
| `enable_nat_gateway`          | Enable NAT Gateway                            | bool         | `true`               | no       |
| `enable_nat_per_az`           | Create a NAT Gateway in each AZ               | bool         | `false`              | no       |
| `ec2_key_name`                | Existing EC2 key pair name                    | string       | `null`               | yes      |
| `bastion_ssh_port`            | SSH port for Bastion                          | number       | `22`                 | no       |
| `bastion_allowed_ssh_cidrs`   | CIDRs allowed to SSH to Bastion               | list(string) | `[]`                 | yes      |
| `bastion_instance_type`       | Bastion EC2 instance type                     | string       | `t3.micro`           | no       |
| `eks_cluster_name`            | EKS cluster name                              | string       | `null`               | yes      |
| `eks_cluster_version`         | Kubernetes version                            | string       | `1.36`               | yes      |
| `eks_endpoint_private_access` | Enable private EKS API endpoint               | bool         | `true`               | no       |
| `eks_endpoint_public_access`  | Enable public EKS API endpoint                | bool         | `false`              | no       |
| `eks_node_instance_types`     | EKS worker node instance types                | list(string) | `["c7i-flex.large"]` | no       |
| `eks_node_desired_size`       | Desired number of nodes                       | number       | `1`                  | no       |
| `eks_node_min_size`           | Minimum number of nodes                       | number       | `1`                  | no       |
| `eks_node_max_size`           | Maximum number of nodes                       | number       | `3`                  | no       |
| `eks_node_capacity_type`      | EKS node capacity type                        | string       | `ON_DEMAND`          | no       |
| `alb_internal`                | Whether the ALB is internal                   | bool         | `false`              | no       |
| `alb_listener_port`           | ALB listener port                             | number       | `80`                 | no       |
| `alb_listener_protocol`       | ALB listener protocol                         | string       | `HTTP`               | no       |
| `alb_target_port`             | EKS NodePort target port                      | number       | `30080`              | no       |
| `alb_health_check_path`       | ALB health check path                         | string       | `/healthz`           | no       |
| `bucket_name`                 | Analytics S3 bucket name                      | string       | `null`               | yes      |
| `bucket_force_destroy`        | Force deletion of S3 bucket contents          | bool         | `false`              | no       |
| `bucket_versioning_enabled`   | Enable S3 versioning                          | bool         | `true`               | no       |
| `glue_database_name`          | Glue Data Catalog database name               | string       | `null`               | yes      |
| `athena_workgroup_name`       | Athena workgroup name                         | string       | `null`               | yes      |

## Outputs

| Name                            | Description                        |
| ------------------------------- | ---------------------------------- |
| `vpc_id`                        | ID of the SpendSmart VPC           |
| `public_subnet_ids`             | IDs of public subnets              |
| `private_subnet_ids`            | IDs of private subnets             |
| `first_public_subnet_id`        | ID of the first public subnet      |
| `eks_cluster_id`                | EKS cluster ID                     |
| `eks_cluster_arn`               | EKS cluster ARN                    |
| `eks_cluster_endpoint`          | EKS API endpoint                   |
| `eks_cluster_security_group_id` | EKS cluster security group ID      |
| `eks_node_security_group_id`    | EKS node security group ID         |
| `eks_node_group_names`          | EKS managed node group names       |
| `bastion_id`                    | Bastion EC2 instance ID            |
| `bastion_public_ip`             | Bastion public IP                  |
| `bastion_security_group_id`     | Bastion security group ID          |
| `alb_dns_name`                  | Application Load Balancer DNS name |
| `alb_arn`                       | Application Load Balancer ARN      |
| `target_group_arn`              | ALB target group ARN               |
| `bucket_name`                   | Analytics S3 bucket name           |
| `bucket_arn`                    | Analytics S3 bucket ARN            |
| `data_location`                 | S3 location for analytics data     |
| `athena_output_location`        | S3 location for Athena results     |
| `glue_database_name`            | Glue Data Catalog database name    |
| `athena_workgroup_name`         | Athena workgroup name              |

## Related Projects

This project is composed of the following Terraform modules.

* `network-skeleton` - Terraform module for VPC and networking resources.
* `bastion` - Terraform module for Bastion EC2 and security group.
* `eks` - Terraform module for EKS cluster, managed node groups, IAM, security groups, and ALB.
* `s3` - Terraform module for the analytics S3 bucket.
* `glue` - Terraform module for AWS Glue Data Catalog.
* `athena` - Terraform module for Amazon Athena workgroup.
* `iam` - Terraform module for analytics IAM roles and policies.

### Contributors

* Opstree DevOps Team
