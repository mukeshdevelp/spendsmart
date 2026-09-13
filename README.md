# SpendSmart AWS Infrastructure (Terraform)

Terraform deployment for the SpendSmart architecture on AWS: two-AZ VPC, bastion, ClickHouse, EKS (EC2 node groups), ALB, Route 53, S3 data lake, Glue, and Athena.

## Directory structure

```
.
├── backend.tf           # Main stack remote state (S3 + DynamoDB) — must exist before root apply
├── main.tf              # Root wrapper — infra modules only (no bootstrap)
├── outputs.tf
├── terraform.tfvars
├── variables.tf
├── versions.tf
├── bootstrap/           # One-time entry point (local state) → calls modules/bootstrap
└── modules/
    ├── bootstrap/       # Shared S3 bucket + DynamoDB lock table (reusable module)
    ├── network-skeleton/
    ├── bastion/
    ├── eks/
    ├── s3/
    ├── glue/
    └── athena/
```

## Bootstrap vs main stack (run bootstrap once)

The **state backend cannot live in the same Terraform apply as the infrastructure** that uses it (chicken-and-egg: the main stack needs the bucket before it can store state there).

| Stack | Folder | State | When to run |
|-------|--------|-------|-------------|
| Bootstrap | `bootstrap/` | **Local** (`bootstrap/terraform.tfstate`) | **Once** per account/region |
| Main | repository root | **Remote** S3 (`backend.tf`) | Every deploy |

After bootstrap succeeds, **root `terraform apply` only runs** `network-skeleton`, `bastion`, `eks`, `s3`, `glue`, `athena` — it does **not** recreate the bucket.

`modules/bootstrap/` creates **one shared S3 bucket** plus the DynamoDB lock table. The main stack uses folder prefixes inside that bucket:

| Prefix | Purpose |
|--------|---------|
| `aws/infra/terraform.tfstate` | Terraform remote state (`backend.tf`) |
| `data/` | Glue / data-lake objects |
| `athena-results/` | Athena query output |

### First-time setup

```bash
# 1. Bootstrap — ONCE (creates spendsmart-dev bucket + spendsmart-tfstate-locks table)
cd bootstrap && terraform init && terraform apply

# 2. Main stack — uses remote backend from backend.tf
cd .. && terraform init && terraform plan && terraform apply
```

Confirm `backend.tf` and `terraform.tfvars` use the same bucket name as bootstrap (default: `spendsmart-dev`).

### Later applies

```bash
# From repository root only — bootstrap is NOT run again
terraform plan
terraform apply
```

Re-running `cd bootstrap && terraform apply` is safe (Terraform updates in place, does not recreate the bucket if it already exists in bootstrap state), but you normally **do not need to** after the first time.

## Module wiring (`main.tf`)

```
network-skeleton → bastion → eks
                              ↓
                    s3 → glue / athena
```

| Module | Responsibility |
|--------|----------------|
| `bootstrap` | Shared S3 bucket + DynamoDB lock table (via `bootstrap/` stack only) |
| `network-skeleton` | VPC, subnets, IGW, NAT, routes, node NACL |
| `bastion` | Bastion + ClickHouse EC2, security groups, SSH key, SSM IAM |
| `eks` | EKS cluster, EC2 node groups, ALB/Route 53 security groups, load balancer, DNS |
| `s3` | Prefix lifecycle rules on the shared bucket (data + Athena folders) |
| `glue` | Glue Data Catalog database + IAM role |
| `athena` | Athena workgroup |

## Important notes

- ClickHouse EC2 only mounts the data volume; ClickHouse software is not installed by Terraform.
- ALB target group exists but pods/nodes are not auto-registered — attach ASGs or install AWS Load Balancer Controller.
- The shared S3 bucket name must be globally unique; override `bucket_name` in bootstrap and root `terraform.tfvars` if needed.
