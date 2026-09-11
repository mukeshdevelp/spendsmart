# SpendSmart AWS Infrastructure (Terraform)

Terraform deployment for the SpendSmart architecture on AWS: two-AZ VPC, bastion, EKS (two node groups), ClickHouse, ALB, Route 53, S3 data lake, Glue, Athena, and a remote S3/DynamoDB state backend.

## Repository layout

```
spendsmart/
├── main.tf              # Root wrapper — calls all modules (start here)
├── variables.tf         # Input variable declarations
├── terraform.tfvars     # Your environment values
├── outputs.tf           # Re-exports module outputs
├── versions.tf          # Terraform and provider versions + AWS provider
├── backend.tf           # Remote state (S3 + DynamoDB)
├── bootstrap/           # One-time state-backend stack (local state)
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── outputs.tf
│   └── versions.tf
├── networking/          # VPC, subnets, IGW, NAT, routes, NACL
├── security/            # Security groups, SSM IAM, SSH key + Secrets Manager
├── ec2/                 # Bastion EC2 + Elastic IP
├── db/                  # ClickHouse EC2 + data volume
├── monitoring/          # CloudWatch log group for EKS
├── eks/                 # EKS cluster, node groups, addons, ALB, Route 53
├── glue/                # Data-lake S3 bucket, Glue catalog, Glue IAM
└── athena/              # Athena results S3 bucket + workgroup
```

Each module folder contains `main.tf`, `variables.tf`, `outputs.tf`, and `versions.tf`.

## Where is the wrapper code?

The **root wrapper** is not a separate folder — it is the Terraform files at the **repository root**:

| File | Role |
|------|------|
| `main.tf` | Wires all modules together (`module "networking"`, `module "security"`, etc.) |
| `variables.tf` | Declares inputs passed into modules |
| `terraform.tfvars` | Sets values for your environment (region, CIDRs, instance types, …) |
| `outputs.tf` | Exposes module outputs (`vpc_id`, `eks_cluster_name`, `bastion_public_ip`, …) |
| `versions.tf` | Provider configuration (`aws` region, default tags) |
| `backend.tf` | S3/DynamoDB remote state for the main stack |

Run `terraform plan` and `terraform apply` from the **repository root** (`spendsmart/`). The wrapper delegates all resource creation to the module directories listed above.

## Module structure

Dependency order enforced in `main.tf`:

```
networking → security → ec2 / db / monitoring → eks → glue / athena
```

| Module | Path | Responsibility | Key outputs |
|--------|------|----------------|-------------|
| `networking` | `networking/` | VPC (`main_vpc`), public/private subnets, IGW, NAT, routes, node NACL | `vpc_id`, `public_subnet_ids`, `private_subnet_ids` |
| `security` | `security/` | Bastion/ALB/EKS/ClickHouse security groups, SSM IAM, SSH key via Secrets Manager | `bastion_security_group_id`, `ec2_key_name`, `ssh_key_download_policy_arn` |
| `ec2` | `ec2/` | Bastion instance + Elastic IP | `bastion_instance_id`, `bastion_public_ip` |
| `db` | `db/` | ClickHouse EC2 + EBS data volume | `clickhouse_instance_id`, `clickhouse_private_ip` |
| `monitoring` | `monitoring/` | CloudWatch log group for EKS control plane | `eks_log_group_name` |
| `eks` | `eks/` | EKS cluster, 2 node groups, addons, ALB, Route 53 | `eks_cluster_name`, `alb_dns_name`, `app_fqdn` |
| `glue` | `glue/` | Data-lake S3 bucket, Glue catalog database, Glue IAM role | `data_bucket_name`, `glue_database_name` |
| `athena` | `athena/` | Athena results S3 bucket + workgroup | `athena_results_bucket_name`, `athena_workgroup_name` |

### How modules connect (wrapper excerpt)

`main.tf` passes outputs from one module as inputs to the next — for example:

- `module.networking` → `vpc_id`, subnet IDs → `module.security`, `module.ec2`, `module.db`, `module.eks`
- `module.security` → security group IDs, SSH key name → `module.ec2`, `module.db`, `module.eks`
- `module.monitoring` → `eks_log_group_name` → `module.eks`

## Resources created

| Stack | AWS service | Terraform resource | Module |
|-------|-------------|-------------------|--------|
| Bootstrap | S3 | `aws_s3_bucket.remote_backend` | `bootstrap/` |
| Bootstrap | S3 | `aws_s3_bucket_versioning.versioning` | `bootstrap/` |
| Bootstrap | S3 | `aws_s3_bucket_server_side_encryption_configuration.encryption` | `bootstrap/` |
| Bootstrap | S3 | `aws_s3_bucket_public_access_block.public_access_block` | `bootstrap/` |
| Bootstrap | DynamoDB | `aws_dynamodb_table.state_lock` | `bootstrap/` |
| Main | VPC | `aws_vpc.main_vpc` | `networking/` |
| Main | VPC | `aws_internet_gateway.internet_gateway` | `networking/` |
| Main | VPC | `aws_subnet.public_subnets` | `networking/` |
| Main | VPC | `aws_subnet.private_subents` | `networking/` |
| Main | VPC | `aws_eip.nat`, `aws_nat_gateway.this` | `networking/` |
| Main | VPC | `aws_route_table.*`, `aws_route.*` | `networking/` |
| Main | VPC | `aws_network_acl.nodes` | `networking/` |
| Main | EC2 | `aws_security_group.*` | `security/` |
| Main | IAM | `aws_iam_role.ec2_ssm`, `aws_iam_instance_profile.ec2_ssm` | `security/` |
| Main | Secrets Manager | `aws_secretsmanager_secret.ssh_private_key` | `security/` |
| Main | EC2 (via CLI) | `terraform_data.ssh_keypair` | `security/` |
| Main | EC2 | `aws_instance.bastion`, `aws_eip.bastion` | `ec2/` |
| Main | EC2 | `aws_instance.clickhouse` | `db/` |
| Main | CloudWatch | `aws_cloudwatch_log_group.eks` | `monitoring/` |
| Main | EKS | `aws_eks_cluster.this`, `aws_eks_node_group.this` | `eks/` |
| Main | EKS | `aws_eks_addon.*` | `eks/` |
| Main | ELB | `aws_lb.load_balancer`, `aws_lb_target_group.target_group_eks` | `eks/` |
| Main | Route 53 | `aws_route53_zone.this`, `aws_route53_record.app` | `eks/` |
| Main | S3 | `aws_s3_bucket.data` | `glue/` |
| Main | Glue | `aws_glue_catalog_database.this`, `aws_iam_role.glue` | `glue/` |
| Main | S3 | `aws_s3_bucket.athena_results` | `athena/` |
| Main | Athena | `aws_athena_workgroup.this` | `athena/` |

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured with credentials
- IAM permissions for VPC, EC2, EKS, S3, IAM, Route 53, Secrets Manager, etc.

## Deployment

```bash
# 1. Bootstrap (local state) — once
cd bootstrap && terraform init && terraform apply

# 2. Main stack (remote state in S3) — from repository root
cd .. && terraform init && terraform plan && terraform apply

# 3. kubectl
aws eks update-kubeconfig --region us-east-1 --name spendsmart
```

`backend.tf` must match bootstrap outputs (default bucket `spendsmart-tfstate`, table `spendsmart-tfstate-locks`).

## SSH key download

When `create_ssh_key = true`, attach IAM policy from output `ssh_key_download_policy_arn`, then:

```bash
aws secretsmanager get-secret-value \
  --region us-east-1 \
  --secret-id spendsmart-dev-ssh-private-key \
  --query SecretString --output text > spendsmart-dev-ssh.pem
chmod 400 spendsmart-dev-ssh.pem
ssh -i spendsmart-dev-ssh.pem ec2-user@<bastion_public_ip>
```

Or use `terraform output ssh_private_key_download_command`. SSM Session Manager works without the key.

## Important notes

- ClickHouse EC2 only mounts the data volume; ClickHouse software is not installed by Terraform.
- ALB target group exists but pods/nodes are not auto-registered — attach ASGs or install AWS Load Balancer Controller.
- S3 bucket names must be globally unique; override in `terraform.tfvars` if needed.
- `terraform apply` for SSH key creation requires AWS CLI (`ec2:CreateKeyPair`, `secretsmanager:PutSecretValue`).

## Destroy

```bash
terraform destroy          # main stack first (from repository root)
cd bootstrap && terraform destroy   # optional; fails if state bucket is not empty
```
