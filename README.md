# SpendSmart AWS Infrastructure (Terraform)

Terraform for the SpendSmart platform: VPC networking, bastion access, EKS with EC2 node groups, ALB, and analytics (S3, Glue, Athena).

## Architecture

```mermaid
flowchart TB
  internet([Internet])
  s3[(S3 bucket: state, data, Athena results)]
  glue[Glue Data Catalog]
  athena[Athena workgroup]

  subgraph vpc[VPC — network-skeleton]
    igw[Internet gateway]
    subgraph public[Public subnets — two AZs]
      bastion[Bastion EC2\nbastion security group]
      alb[Application Load Balancer\nALB security group]
      nat[NAT gateway(s)]
    end
    subgraph private[Private subnets — two AZs]
      nodes[EKS managed node groups\nnode security group]
    end
    control[EKS control plane]
  end

  internet --> igw
  igw --> bastion
  igw --> alb
  bastion -. SSH : 22 .-> nodes
  alb --> nodes
  nodes --> control
  private --> nat --> igw
  glue <--> s3
  athena --> s3
  athena --> glue
```

The EKS control plane is AWS-managed. The EKS nodes, bastion, ALB, NAT gateways, and security groups are created in the VPC.

## What each module creates

| Module | Created resources | Called by / key inputs | Outputs consumed by |
|---|---|---|---|
| `network-skeleton` | VPC, public/private subnets, internet gateway, NAT gateway(s), NAT Elastic IPs, route tables, routes, and subnet associations | Root `main.tf`; CIDRs, AZs, DNS, NAT settings, cluster name | `bastion`: VPC ID + first public subnet. `eks`: VPC ID + public/private subnet IDs. |
| `bastion` | Bastion EC2, bastion SG and SSH/egress rules, optional EIP, and SSM IAM role/profile | Root `main.tf`; VPC/subnet from `network-skeleton`, existing EC2 key-pair name, AMI, SSH, and instance settings | `eks`: bastion SG ID + validated EC2 key-pair name. Root outputs: instance ID, public IP, SG ID, and key name. |
| `eks` | EKS cluster, cluster/node IAM roles and attachments, node SG/rules, launch template, managed node groups, add-ons, and optional ALB, target group, listener, and ALB SG | Root `main.tf`; VPC/subnets from `network-skeleton`, bastion SG/key from `bastion`, EKS and ALB settings | Root outputs: cluster details, node SG, and optional ALB details. |
| `s3` | Shared S3 bucket, versioning, encryption, public-access block, and Athena-results lifecycle policy | Root `main.tf`; bucket name, prefixes, retention, and protection settings | `glue`: bucket ARN/data prefix. `athena`: results location. |
| `glue` | Glue catalog database, Glue IAM role, AWS Glue service-policy attachment, and S3 access policy | Root `main.tf`; bucket ARN/data prefix from `s3` and database name | Root outputs: database name and Glue role ARN. |
| `athena` | Athena workgroup with enforced S3 output location and bytes-scanned limit | Root `main.tf`; results location from `s3` and workgroup settings | Root output: workgroup name. |

Conditional resources are controlled by `bastion_enabled`, `bastion_associate_eip`, `enable_nat_gateway`, `enable_nat_per_az`, and `alb_enabled`.

**Not in Terraform:** ClickHouse (deploy in EKS via Helm/manifests), Route 53 (use external DNS → `alb_dns_name`).

## Repository layout

```
.
├── backend.tf              # Remote state (S3 + native lockfile)
├── main.tf                 # Module wiring
├── locals.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
├── versions.tf
└── modules/
    ├── network-skeleton/   # main.tf, locals.tf, variables.tf, outputs.tf
    ├── bastion/            # main.tf, locals.tf, variables.tf, outputs.tf
    ├── eks/                # main.tf, variables.tf, outputs.tf
    ├── s3/                 # Creates shared bucket (survives terraform destroy)
    ├── glue/
    └── athena/
```

## How modules are called

The root module calls every child module in [main.tf](main.tf). A module output passed to another module input creates the dependency relationship.

```hcl
module "network_skeleton" { source = "./modules/network-skeleton" }

module "bastion" {
  source           = "./modules/bastion"
  vpc_id           = module.network_skeleton.vpc_id
  public_subnet_id = module.network_skeleton.first_public_subnet_id
}

module "eks" {
  source                    = "./modules/eks"
  vpc_id                    = module.network_skeleton.vpc_id
  private_subnet_ids        = values(module.network_skeleton.private_subnet_ids)
  bastion_security_group_id = module.bastion.bastion_security_group_id
  ec2_key_name              = module.bastion.ec2_key_name
}

module "s3" { source = "./modules/s3" }
module "glue" {
  source     = "./modules/glue"
  bucket_arn = module.s3.bucket_arn
}
module "athena" {
  source                 = "./modules/athena"
  athena_output_location = module.s3.athena_output_location
}
```

The complete calls provide the configuration values from `terraform.tfvars`. Root `depends_on` declarations additionally enforce the network → bastion → EKS and S3 → Glue/Athena order.

## S3 bucket and remote state

The `s3` module creates the shared bucket on apply. Glue and Athena use separate prefixes in the same bucket (`data_prefix`, `athena_results_prefix`).

The bucket does not force-delete its contents:

- `bucket_force_destroy = false` — objects are not force-deleted on destroy

With the default setting, `terraform destroy` deletes the bucket only when it is empty. Set `bucket_force_destroy = true` only when you explicitly want Terraform to remove all objects and the bucket.

When `bucket_name` is empty, the default name is `{project_name}-{environment}-{account_id}`, for example `spendsmart-dev-123456789012`. This avoids S3's global bucket-name collisions. [backend.tf.example](backend.tf.example) is the template for enabling remote state after the bucket exists.

### Deploy

```bash
terraform init -backend=false
terraform apply

# Copy the bucket name from `terraform output bucket_name`, then create
# backend.tf from the template and replace its example bucket value.
cp backend.tf.example backend.tf
# Edit backend.tf: replace spendsmart-dev-123456789012 with the output value.
terraform init -migrate-state
terraform plan && terraform apply
```

## Security

| Rule | Detail |
|------|--------|
| Bastion only | Only bastion may use `0.0.0.0/0` (`bastion_allowed_ssh_cidrs`, `bastion_egress_cidrs`) |
| ALB / EKS API / nodes | Restricted to VPC CIDR or explicit lists in `terraform.tfvars` |
| No Route 53 | DNS is managed outside this stack |

## Key variables (`terraform.tfvars`)

| Area | Variables |
|------|-----------|
| Network | `vpc_cidr`, `public_subnet_cidrs`, `private_subnet_cidrs`, `internet_route_cidr`, `enable_nat_gateway`, `enable_nat_per_az` |
| Bastion | `ec2_key_name`, `bastion_enabled`, `bastion_ssh_port`, `bastion_allowed_ssh_cidrs`, `bastion_egress_cidrs` |
| EKS | `eks_cluster_name`, `eks_node_instance_types`, `eks_public_access_cidrs`, `eks_addons` |
| ALB | `alb_enabled`, `alb_allowed_ingress_cidrs`, `alb_target_port` |
| Data | `bucket_name`, `data_prefix`, `athena_results_prefix`, `bucket_force_destroy`, `bucket_block_public_acls`, `athena_results_expiration_days`, `glue_database_name`, `athena_workgroup_name` |

## Outputs

```bash
terraform output eks_configure_kubectl
terraform output bastion_public_ip
terraform output alb_dns_name
terraform output data_location
terraform output athena_output_location
```

## Notes

- **ClickHouse** runs in the EKS cluster, not as EC2.
- **ALB target group** is created but pods are not auto-registered — use AWS Load Balancer Controller or register targets manually.
- **Existing SSH key** — set `ec2_key_name` in `terraform.tfvars` to an EC2 key pair that already exists in the selected AWS account and region. Terraform validates it with the AWS `aws_key_pair` data source and attaches it to the bastion and all EKS worker nodes. Keep the corresponding private key outside Terraform.
- **Migration from the former generated-key option** — the prior key pair, Secrets Manager secret, and download policy are removed from Terraform state without deletion, so applying this version does not remove existing key material. Delete those old resources separately only if they are no longer needed.
- **EKS control plane ("master")** — AWS manages the control-plane instances; they cannot be assigned an EC2 SSH key. Access is through the EKS API, configured by the endpoint and IAM settings.
- **Nodes** — EC2 managed node groups (not Fargate).
