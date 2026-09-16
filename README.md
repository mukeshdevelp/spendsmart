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



## Usage

```hcl
provider "aws" {
  region = "us-east-1"
}

module "spendsmart" {
  source = "./"

  project_name = "spendsmart"
  environment  = "dev"

  aws_region = "us-east-1"

  vpc_cidr = "10.0.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  public_subnet_cidrs = [
    "10.0.0.0/24",
    "10.0.1.0/24"
  ]

  private_subnet_cidrs = [
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  enable_nat_gateway = true
  enable_nat_per_az  = false

  ec2_key_name = "observability.pem"

  eks_cluster_name    = "spendsmart"
  eks_cluster_version = "1.36"

  eks_endpoint_private_access = true
  eks_endpoint_public_access  = false

  eks_node_instance_types = [
    "c7i-flex.large"
  ]

  eks_node_desired_size = 1
  eks_node_min_size     = 1
  eks_node_max_size     = 3

  eks_node_capacity_type = "ON_DEMAND"

  alb_internal             = false
  alb_listener_port        = 80
  alb_listener_protocol    = "HTTP"
  alb_target_port          = 30080
  alb_target_group_protocol = "HTTP"
  alb_health_check_path    = "/healthz"

  bucket_force_destroy = false
}
```

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Create an execution plan:

```bash
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply
```

Destroy the infrastructure:

```bash
terraform destroy
```

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
