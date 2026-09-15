# SpendSmart AWS Infrastructure — Terraform

Terraform infrastructure for the **SpendSmart** platform.

The infrastructure provisions:

* VPC networking across two Availability Zones
* Public and private subnets
* Internet Gateway
* NAT Gateway
* Bastion EC2 host
* EKS cluster with EC2 managed node groups
* EKS cluster and node IAM roles
* EKS security groups
* EKS managed add-ons
* Internet-facing Application Load Balancer
* S3 analytics bucket
* AWS Glue Data Catalog
* Amazon Athena workgroup
* IAM roles and policies required by the analytics components

ClickHouse is deployed separately inside EKS using Kubernetes/Helm and is not created by this Terraform stack.

---

# Architecture

                                      ┌─────────────────┐
                                      │    INTERNET     │
                                      └────────┬────────┘
                                               │
                                               │
                                      ┌────────▼────────┐
                                      │ Internet Gateway│
                                      │      (IGW)      │
                                      └────────┬────────┘
                                               │
                     ┌─────────────────────────┴─────────────────────────┐
                     │                 VPC 10.0.0.0/16                  │
                     │                                                  │
                     │   ┌──────────────────────────────────────────┐   │
                     │   │            PUBLIC SUBNETS                │   │
                     │   │                                          │   │
                     │   │  ┌──────────────┐     ┌──────────────┐  │   │
                     │   │  │   Bastion    │     │     ALB      │  │   │
                     │   │  │     EC2      │     │ HTTP :80     │  │   │
                     │   │  │              │     │              │  │   │
                     │   │  │ SSH :22      │     │ Internet-    │  │   │
                     │   │  │              │     │ facing       │  │   │
                     │   │  └──────┬───────┘     └──────┬───────┘  │   │
                     │   │         │                     │          │   │
                     │   │         │ SSH :22             │          │   │
                     │   │         │                     │          │   │
                     │   │  ┌──────▼───────┐      ┌──────▼───────┐ │   │
                     │   │  │ NAT Gateway  │      │   ALB SG     │ │   │
                     │   │  │              │      │              │ │   │
                     │   │  └──────┬───────┘      └──────────────┘ │   │
                     │   │         │                               │   │
                     │   └─────────┼───────────────────────────────┘   │
                     │             │                                   │
                     │             │ NAT                               │
                     │             │                                   │
                     │   ┌─────────▼───────────────────────────────┐   │
                     │   │             PRIVATE SUBNETS            │   │
                     │   │                                          │   │
                     │   │  ┌────────────────┐  ┌────────────────┐ │   │
                     │   │  │ EKS Node Group │  │ EKS Node Group │ │   │
                     │   │  │      AZ-1      │  │      AZ-2      │ │   │
                     │   │  │                │  │                │ │   │
                     │   │  │ Node SG        │  │ Node SG        │ │   │
                     │   │  │ NodePort 30080 │  │ NodePort 30080 │ │   │
                     │   │  └───────┬────────┘  └───────┬────────┘ │   │
                     │   │          │                   │          │   │
                     │   └──────────┼───────────────────┼──────────┘   │
                     │              │                   │              │
                     │              │                   │              │
                     │              └─────────┬─────────┘              │
                     │                        │                        │
                     │               Kubernetes API                  │
                     │                        │                        │
                     │              ┌─────────▼─────────┐              │
                     │              │  EKS CONTROL      │              │
                     │              │      PLANE        │              │
                     │              │                    │              │
                     │              │ AWS Managed       │              │
                     │              │ Private API       │              │
                     │              └───────────────────┘              │
                     │                                                  │
                     └──────────────────────────────────────────────────┘


                              ANALYTICS SERVICES
                              =================

                    ┌───────────────────────────────┐
                    │       S3 ANALYTICS BUCKET     │
                    │                               │
                    │  data/                        │
                    │  athena-results/              │
                    └───────────────┬───────────────┘
                                    │
                         ┌──────────┴──────────┐
                         │                     │
                         │                     │
                ┌────────▼────────┐   ┌────────▼────────┐
                │  GLUE DATA      │   │    ATHENA       │
                │    CATALOG      │   │   WORKGROUP     │
                │                 │   │                 │
                │ Database        │   │ SQL Queries     │
                │ Tables/Metadata │   │ Query Results   │
                └────────┬────────┘   └────────┬────────┘
                         │                     │
                         └──────────┬──────────┘
                                    │
                                    ▼
                                  S3

## Network layout

| Component          | Configuration    |
| ------------------ | ---------------- |
| VPC                | `10.0.0.0/16`    |
| Availability Zones | 2                |
| Public subnet 1    | `10.0.0.0/24`    |
| Public subnet 2    | `10.0.1.0/24`    |
| Private subnet 1   | `10.0.2.0/24`    |
| Private subnet 2   | `10.0.3.0/24`    |
| NAT Gateway        | 1                |
| Bastion            | Public subnet    |
| ALB                | Public subnets   |
| EKS nodes          | Private subnets  |
| EKS API endpoint   | Private only     |
| ALB listener       | HTTP `80`        |
| EKS target port    | NodePort `30080` |

---

# High-Level Architecture

The infrastructure follows a typical production-style three-tier network layout:

```text
                         Internet
                            |
                     Internet Gateway
                            |
             +--------------+--------------+
             |                             |
       Public Subnet AZ-1            Public Subnet AZ-2
             |                             |
        +----+----+                   +----+----+
        | Bastion |                   |   ALB   |
        +---------+                   +---------+
             |                             |
             | SSH :22                     |
             |                             |
             +-------------+---------------+
                           |
                    Private Subnets
                           |
              +------------+------------+
              |                         |
        EKS Node Group 1         EKS Node Group 2
             AZ-1                     AZ-2
              |                         |
              +------------+------------+
                           |
                    EKS Control Plane
                    AWS Managed
                    Private Endpoint
```

Outbound traffic from private EKS nodes follows:

```text
EKS Node
   |
Private Route Table
   |
NAT Gateway
   |
Internet Gateway
   |
Internet
```

---

# Terraform Module Structure

The root module wires together the following modules:

| Module             | Purpose                                                |
| ------------------ | ------------------------------------------------------ |
| `network-skeleton` | VPC and networking                                     |
| `bastion`          | Bastion EC2 and security group                         |
| `eks`              | EKS cluster, node groups, IAM, security groups and ALB |
| `s3`               | Analytics S3 bucket                                    |
| `glue`             | Glue database and IAM                                  |
| `athena`           | Athena workgroup                                       |

---

# What Each Module Creates

## 1. `network-skeleton`

Creates:

* VPC
* Public subnets
* Private subnets
* Internet Gateway
* NAT Gateway
* NAT Elastic IP
* Public route tables
* Private route tables
* Routes
* Subnet associations
* DNS support and DNS hostnames

### Inputs

The module receives:

* VPC CIDR
* Public subnet CIDRs
* Private subnet CIDRs
* Availability Zones
* NAT configuration
* DNS configuration
* Internet route configuration

### Outputs consumed by other modules

The root module passes:

```text
VPC ID
Public subnet IDs
Private subnet IDs
First public subnet ID
```

to the Bastion and EKS modules.

---

# 2. Bastion Module

The Bastion is **always created** in the current architecture.

It provides SSH access to resources in the private subnets.

```text
Internet
   |
   | SSH :22
   v
Bastion
   |
   | SSH :22
   v
EKS Worker Node
```

## Bastion resources

The module creates:

* Bastion EC2 instance
* Bastion security group
* SSH ingress rule
* Egress rule
* Elastic IP
* Existing EC2 key-pair validation
* Latest Amazon Linux AMI lookup

The Bastion does **not** use AWS Systems Manager for instance management.

The AMI is retrieved using the AWS Systems Manager Parameter Store public AMI parameter:

```text
/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64
```

This is only an AMI lookup and does not mean the EC2 instance is managed through SSM.

---

# 3. EKS Module

The EKS module creates:

* EKS cluster
* EKS cluster IAM role
* EKS worker-node IAM role
* IAM policy attachments
* EKS node security group
* Node ingress/egress rules
* EKS launch template
* EKS managed node groups
* EKS add-ons
* Application Load Balancer
* ALB security group
* ALB target group
* ALB listener

---

# EKS Configuration

The cluster currently uses:

```text
EKS Version: 1.36
AMI: AL2023_x86_64_STANDARD
Instance Type: c7i-flex.large
Capacity Type: ON_DEMAND
```

The EKS API endpoint is private:

```hcl
eks_endpoint_private_access = true
eks_endpoint_public_access  = false
```

Therefore, the Kubernetes API is not directly accessible from the public Internet.

Access must come through a network path into the VPC, such as:

```text
Laptop
   |
VPN / Bastion / private network
   |
VPC
   |
Private EKS API endpoint
```

---

# EKS Node Groups

There are two private subnets:

```text
Private Subnet 1
10.0.2.0/24
AZ-1

Private Subnet 2
10.0.3.0/24
AZ-2
```

The Terraform configuration creates one managed node group for each private subnet.

Conceptually:

```text
             EKS Cluster
                  |
        +---------+---------+
        |                   |
   Node Group 1        Node Group 2
      AZ-1                AZ-2
        |                   |
   Private Subnet       Private Subnet
    10.0.2.0/24          10.0.3.0/24
```

This provides node distribution across two Availability Zones.

Each node group currently uses:

```text
Desired: 1
Minimum: 1
Maximum: 3
```

Therefore the initial cluster has:

```text
1 node in AZ-1
1 node in AZ-2

Total = 2 nodes
```

---

# EKS Node IAM

The EKS worker-node role contains:

```text
AmazonEKSWorkerNodePolicy
AmazonEKS_CNI_Policy
AmazonEC2ContainerRegistryReadOnly
```

The node role does **not** contain:

```text
AmazonSSMManagedInstanceCore
```

because SSM-based node management is not part of the current architecture.

---

# EKS Cluster IAM

The EKS cluster role contains:

```text
AmazonEKSClusterPolicy
AmazonEKSVPCResourceController
```

The trust policy allows:

```text
eks.amazonaws.com
```

to assume the cluster role.

---

# EKS Add-ons

The following EKS add-ons are enabled:

```text
vpc-cni
kube-proxy
coredns
```

These provide core Kubernetes networking, service routing, and DNS functionality.

---

# Security Groups

The architecture uses separate security groups for:

```text
Bastion
EKS Nodes
ALB
```

## Bastion → EKS Nodes

SSH is allowed from the Bastion security group to the EKS node security group:

```text
Bastion SG
     |
     | TCP 22
     v
EKS Node SG
```

The rule is not controlled by `bastion_enabled` because the Bastion is now a mandatory component.

---

# EKS Node-to-Node Traffic

The EKS node security group allows nodes belonging to the same security group to communicate.

Conceptually:

```text
EKS Node 1
    |
    | Node-to-node traffic
    |
EKS Node 2
```

The rule uses a security-group reference rather than a VPC CIDR.

---

# ALB

The Application Load Balancer is always created.

It is:

```text
Internet-facing
```

and is deployed across the public subnets.

```text
Internet
   |
   v
ALB
   |
   | HTTP :30080
   v
EKS Nodes
```

The ALB listener is currently:

```text
Protocol: HTTP
Port: 80
```

The target group forwards traffic to:

```text
Port: 30080
Protocol: HTTP
```

This corresponds to a Kubernetes `NodePort` service.

---

# ALB Security

The ALB currently allows:

```hcl
alb_allowed_ingress_cidr = "0.0.0.0/0"
```

Therefore:

```text
Internet
   |
   | TCP 80
   v
ALB
```

is publicly accessible.

The ALB then forwards traffic to the EKS node security group on port `30080`.

```text
Internet
    |
 TCP 80
    |
    v
  ALB
    |
 TCP 30080
    |
    v
EKS Node
    |
    v
NodePort Service
    |
    v
Application Pod
```

---

# ALB Health Check

The target group uses:

```text
Health check path: /healthz
Matcher: 200-399
Interval: 30 seconds
Timeout: 5 seconds
Healthy threshold: 2
Unhealthy threshold: 3
```

The application exposed through the NodePort should therefore provide a suitable `/healthz` endpoint.

---

# Important ALB / Kubernetes Note

Terraform creates:

```text
ALB
Target Group
Listener
```

but Terraform does not automatically discover Kubernetes pods and register them as ALB targets.

The recommended architecture is to use the:

```text
AWS Load Balancer Controller
```

inside EKS when Kubernetes-native ALB management is required.

Alternatively, targets can be registered manually.

---

# Bastion Access

The Bastion is placed in a public subnet.

Typical access flow:

```text
Developer Laptop
      |
      | SSH
      v
Bastion Public IP
      |
      | SSH
      v
EKS Worker Node Private IP
```

The Bastion security group controls who can connect to the Bastion.

For production use, replace broad SSH access such as:

```hcl
bastion_allowed_ssh_cidrs = ["0.0.0.0/0"]
```

with a trusted source IP:

```hcl
bastion_allowed_ssh_cidrs = ["YOUR_PUBLIC_IP/32"]
```

---

# Existing EC2 Key Pair

The infrastructure uses an **existing AWS EC2 key pair**.

Set:

```hcl
ec2_key_name = "observability.pem"
```

or the actual AWS EC2 key-pair name.

The corresponding private key must already exist outside Terraform.

Terraform validates the key pair using the AWS `aws_key_pair` data source.

The key is used by:

```text
Bastion
EKS worker nodes
```

The EKS control plane does not use this key.

AWS manages the EKS control plane and it cannot be accessed using an EC2 SSH key.

---

# S3 Analytics Module

The S3 module creates the shared analytics bucket.

The bucket provides storage for:

```text
Analytics data
Athena query results
```

Example structure:

```text
S3 Bucket
│
├── data/
│   └── application data
│
└── athena-results/
    └── query results
```

The bucket has:

* Versioning
* Server-side encryption
* Public access block
* Athena result lifecycle policy

---

# S3 Bucket Protection

The default configuration is:

```hcl
bucket_force_destroy = false
```

Therefore Terraform does not automatically delete bucket contents during:

```bash
terraform destroy
```

The bucket must be empty before Terraform can delete it.

Set:

```hcl
bucket_force_destroy = true
```

only when intentionally deleting all bucket contents.

---

# AWS Glue

The Glue module creates:

* Glue Data Catalog database
* Glue IAM role
* Glue service policy attachment
* S3 access policy

The Glue database points to the analytics data stored in S3.

Architecture:

```text
                S3
                 |
                 |
           Glue Data Catalog
                 |
                 |
              Athena
```

---

# Athena

The Athena module creates an Athena workgroup.

The workgroup:

* Enforces the S3 query-result location
* Controls query output
* Limits bytes scanned

Example flow:

```text
User
 |
 | SQL Query
 v
Athena
 |
 | Reads metadata
 v
Glue Data Catalog
 |
 | Reads data
 v
S3
 |
 v
Athena Results
```

---

# ClickHouse

ClickHouse is **not created by Terraform**.

It runs inside the EKS cluster.

Recommended deployment:

```text
EKS
 |
 +-- Frontend Pods
 |
 +-- Backend Pods
 |
 +-- ClickHouse
 |
 +-- Other Kubernetes workloads
```

ClickHouse should be deployed using Kubernetes manifests or Helm.

---

# Route 53

Route 53 is not managed by this Terraform stack.

DNS can be configured externally to point the application hostname toward:

```text
ALB DNS Name
```

Terraform exposes:

```bash
terraform output alb_dns_name
```

Example:

```text
Application DNS
       |
       v
ALB DNS
       |
       v
EKS NodePort
       |
       v
Application Pods
```

---

# Repository Layout

```text
.
├── backend.tf
├── main.tf
├── locals.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
├── versions.tf
│
└── modules/
    │
    ├── network-skeleton/
    │   ├── main.tf
    │   ├── locals.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── bastion/
    │   ├── main.tf
    │   ├── locals.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── eks/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── s3/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── glue/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── athena/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

# Module Dependency Flow

The root module wires the modules together.

```text
network-skeleton
       |
       +--------------------+
       |                    |
       v                    v
    bastion                EKS
       |                    |
       |                    |
       +------> EKS <-------+
       
S3
 |
 +---------> Glue
 |
 +---------> Athena
```

The important dependencies are:

```text
Network
   |
   v
Bastion
   |
   v
EKS
```

and:

```text
S3
 |
 +----> Glue
 |
 +----> Athena
```

Terraform normally detects these dependencies automatically when module outputs are passed directly into other module inputs.

---

# Example Module Wiring

```hcl
module "network_skeleton" {
  source = "./modules/network-skeleton"
}

module "bastion" {
  source = "./modules/bastion"

  vpc_id           = module.network_skeleton.vpc_id
  public_subnet_id = module.network_skeleton.first_public_subnet_id
}

module "eks" {
  source = "./modules/eks"

  vpc_id = module.network_skeleton.vpc_id

  private_subnet_ids = values(
    module.network_skeleton.private_subnet_ids
  )

  public_subnet_ids = values(
    module.network_skeleton.public_subnet_ids
  )

  bastion_security_group_id = module.bastion.bastion_security_group_id

  ec2_key_name = module.bastion.ec2_key_name
}

module "s3" {
  source = "./modules/s3"
}

module "glue" {
  source = "./modules/glue"

  bucket_arn = module.s3.bucket_arn
}

module "athena" {
  source = "./modules/athena"

  athena_output_location = module.s3.athena_output_location
}
```

---

# Important Terraform Design Decisions

## Bastion is mandatory

The current architecture always creates a Bastion.

Therefore there is no need for:

```hcl
bastion_enabled
```

or:

```hcl
count = var.bastion_enabled ? 1 : 0
```

for Bastion-related resources.

The Bastion → EKS node SSH rule is also always created.

---

## ALB is mandatory

The ALB is always created.

Therefore:

```hcl
alb_enabled
```

is no longer required.

The ALB resources are created directly:

```text
aws_security_group.alb
aws_lb.load_balancer
aws_lb_target_group.target_group_eks
aws_lb_listener.this
```

---

## Single ALB ingress CIDR

The ALB currently uses one ingress CIDR.

Instead of:

```hcl
alb_allowed_ingress_cidrs = [
  "0.0.0.0/0"
]
```

the configuration uses:

```hcl
alb_allowed_ingress_cidr = "0.0.0.0/0"
```

Therefore the ALB ingress rule does not need `for_each`.

---

## Single EKS node egress CIDR

When only one egress CIDR is required, the EKS node egress rule does not need `for_each`.

Instead of:

```hcl
for_each = toset(var.nodes_egress_cidrs)
```

the resource can directly reference:

```hcl
cidr_ipv4 = var.nodes_egress_cidr
```

This keeps the Terraform configuration simpler when the architecture has a fixed single egress rule.

---

# Terraform Variables

Important variables include:

## Network

```text
aws_region
vpc_cidr
availability_zones
public_subnet_cidrs
private_subnet_cidrs
enable_nat_gateway
enable_nat_per_az
enable_dns_hostnames
enable_dns_support
internet_route_cidr
```

## Bastion

```text
ec2_key_name
bastion_ssh_port
bastion_allowed_ssh_cidrs
bastion_egress_cidrs
bastion_instance_type
bastion_root_volume_size
bastion_root_volume_type
bastion_ami_ssm_parameter
bastion_associate_eip
```

There is no `bastion_enabled` variable in the current architecture.

## EKS

```text
eks_cluster_name
eks_cluster_version
eks_endpoint_private_access
eks_endpoint_public_access
eks_authentication_mode
eks_bootstrap_cluster_creator_admin_permissions
eks_node_instance_types
eks_node_desired_size
eks_node_min_size
eks_node_max_size
eks_node_disk_size
eks_node_disk_type
eks_node_ami_type
eks_node_capacity_type
eks_addons
```

## ALB

```text
alb_internal
alb_allowed_ingress_cidr
alb_listener_port
alb_listener_protocol
alb_target_port
alb_target_group_protocol
alb_health_check_path
alb_health_check_matcher
alb_health_check_interval
alb_health_check_timeout
alb_health_check_healthy_threshold
alb_health_check_unhealthy_threshold
```

There is no `alb_enabled` variable in the current architecture.

## Analytics

```text
bucket_name
data_prefix
athena_results_prefix
bucket_force_destroy
bucket_versioning_enabled
bucket_sse_algorithm
bucket_block_public_acls
bucket_block_public_policy
bucket_ignore_public_acls
bucket_restrict_public_buckets
athena_results_expiration_days
glue_database_name
athena_workgroup_name
athena_bytes_scanned_cutoff
```

---

# Example Terraform Configuration

A simplified version of the current configuration is:

```hcl
aws_region  = "us-east-1"

project_name = "spendsmart"
environment  = "dev"

vpc_cidr = "10.0.0.0/16"

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

bastion_ssh_port          = 22
bastion_associate_eip     = true
bastion_instance_type     = "t3.micro"
bastion_allowed_ssh_cidrs = ["YOUR_PUBLIC_IP/32"]
bastion_egress_cidrs      = "0.0.0.0/0"

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

eks_node_disk_size = 48
eks_node_disk_type = "gp3"

eks_node_ami_type      = "AL2023_x86_64_STANDARD"
eks_node_capacity_type = "ON_DEMAND"

eks_addons = [
  "vpc-cni",
  "kube-proxy",
  "coredns"
]

alb_internal           = false
alb_allowed_ingress_cidr = "0.0.0.0/0"

alb_listener_port     = 80
alb_listener_protocol = "HTTP"
alb_target_port       = 30080

alb_target_group_protocol = "HTTP"

alb_health_check_path = "/healthz"
```

---

# Terraform Backend

Terraform state should be stored remotely in S3.

The backend configuration uses:

```text
S3
 |
 +-- Terraform state
 |
 +-- Native S3 state locking
```

The backend bucket must exist before Terraform can initialize against it.

If the infrastructure creates the bucket itself, bootstrap the bucket first and then configure the backend.

---

# Initial Deployment

For a new environment where the remote backend bucket does not yet exist:

```bash
terraform init -backend=false
```

Validate the configuration:

```bash
terraform validate
```

Review the planned infrastructure:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

After the bucket is created, configure the remote backend and reinitialize Terraform.

```bash
terraform init -migrate-state
```

Then:

```bash
terraform plan
terraform apply
```

---

# Useful Terraform Commands

## Initialize

```bash
terraform init
```

## Format

```bash
terraform fmt -recursive
```

## Validate

```bash
terraform validate
```

## Plan

```bash
terraform plan
```

## Apply

```bash
terraform apply
```

## Show outputs

```bash
terraform output
```

## Destroy

```bash
terraform destroy
```

Be especially careful with:

```text
S3
EKS
NAT Gateway
ALB
```

because these resources can contain important data or incur ongoing AWS charges.

---

# Important Outputs

After deployment:

```bash
terraform output
```

Useful individual outputs include:

```bash
terraform output eks_configure_kubectl
```

```bash
terraform output bastion_public_ip
```

```bash
terraform output alb_dns_name
```

```bash
terraform output bucket_name
```

```bash
terraform output data_location
```

```bash
terraform output athena_output_location
```

---

# Connecting to the EKS Cluster

Because the EKS API endpoint is private:

```text
eks_endpoint_private_access = true
eks_endpoint_public_access  = false
```

`kubectl` must run from a machine that has network access to the VPC.

A typical architecture is:

```text
Laptop
   |
   | SSH / VPN
   v
Bastion / Private Network
   |
   v
Private EKS API
```

The EKS control plane itself is managed by AWS.

---

# Security Summary

| Component         | Access                                    |
| ----------------- | ----------------------------------------- |
| Bastion SSH       | Restricted by `bastion_allowed_ssh_cidrs` |
| Bastion egress    | Configurable                              |
| EKS API           | Private only                              |
| EKS nodes         | Private subnets                           |
| Node-to-node      | Allowed through node SG reference         |
| Bastion → Nodes   | TCP `22`                                  |
| ALB               | Internet-facing                           |
| ALB listener      | TCP `80`                                  |
| ALB → Nodes       | TCP `30080`                               |
| S3                | Public access blocked                     |
| EKS node IAM      | No SSM management policy                  |
| EKS control plane | AWS managed                               |

---

# Production Considerations

Before using this configuration in production, consider:

### 1. Restrict Bastion SSH

Avoid:

```hcl
bastion_allowed_ssh_cidrs = ["0.0.0.0/0"]
```

Prefer:

```hcl
bastion_allowed_ssh_cidrs = [
  "YOUR_PUBLIC_IP/32"
]
```

### 2. HTTPS for ALB

The current ALB uses:

```text
HTTP :80
```

For production, use:

```text
HTTPS :443
```

with an ACM certificate.

### 3. EKS Load Balancer Controller

For Kubernetes-native ALB management, deploy the AWS Load Balancer Controller rather than manually maintaining target registration.

### 4. NAT Gateway availability

The current configuration uses one NAT Gateway.

For higher availability, use one NAT Gateway per Availability Zone:

```hcl
enable_nat_per_az = true
```

This increases cost but removes the single-NAT failure dependency.

### 5. EKS node scaling

Current configuration:

```text
Desired: 1
Minimum: 1
Maximum: 3
```

Tune these values based on application workload.



---

# Final Architecture Summary

```text
                         INTERNET
                            |
                            v
                    Internet Gateway
                            |
             +--------------+--------------+
             |                             |
             v                             v
        Bastion EC2                       ALB
        Public Subnet                 Public Subnets
             |                             |
             | SSH :22                     | HTTP :80
             |                             |
             v                             v
       +-----------+                +-------------+
       | EKS Node  |<-------------->| EKS Node   |
       |   AZ-1    |  Node traffic  |    AZ-2    |
       +-----------+                +-------------+
             |                             |
             +-------------+---------------+
                           |
                     EKS Control Plane
                     AWS Managed
                     Private API
                           |
                           v
                          EKS

Private Nodes
     |
     v
 NAT Gateway
     |
     v
Internet Gateway
     |
     v
 Internet


                 ANALYTICS
                    |
        +-----------+-----------+
        |                       |
        v                       v
       S3                  Glue Catalog
        |                       |
        +-----------+-----------+
                    |
                    v
                  Athena
```

## Components Managed by Terraform

```text
AWS VPC
├── Public Subnets
├── Private Subnets
├── Internet Gateway
├── NAT Gateway
├── Route Tables
│
├── Bastion EC2
│   └── Bastion Security Group
│
├── EKS
│   ├── Control Plane
│   ├── IAM Roles
│   ├── Node Security Group
│   ├── Launch Template
│   ├── Managed Node Groups
│   └── EKS Add-ons
│   ├── Application Load Balancer
│   ├── Target Group
│   └── Listener
├── S3
├── Glue
└── Athena
```


