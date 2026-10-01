# SpendSmart CloudFormation Deployment

This folder contains the modular CloudFormation deployment of the infrastructure described by the Terraform configuration in the parent folder. It does not use or modify Terraform state. `main.yml` is the deployment entrypoint; its nested templates are under `modules/` and are uploaded with `aws cloudformation package`. `template.yaml` is a monolithic reference and is not the deployment entrypoint.

For deployment commands and troubleshooting, see [ONE_CLICK_DEPLOYMENT.md](ONE_CLICK_DEPLOYMENT.md). For ownership boundaries and outputs, see [ARCHITECTURE.md](ARCHITECTURE.md).

## What It Creates

- VPC, two public subnets, two private subnets in distinct AZs, internet gateway, and one NAT gateway/EIP when enabled.
- Optional bastion host.
- Private EKS cluster, two managed node groups, worker security group, and the VPC CNI, kube-proxy, CoreDNS, and Pod Identity Agent add-ons. Both node groups can place nodes in either private subnet.
- AWS Load Balancer Controller IAM role and EKS Pod Identity association.
- S3 data/results bucket, Glue database and role, Athena workgroup, and analytics IAM role/policy.

The AWS Load Balancer Controller creates the application ALB and target group from a Kubernetes Ingress. There is intentionally no independent CloudFormation ALB target group: EKS managed node groups do not attach their changing Auto Scaling groups to an unrelated target group automatically.

## Optional Application Deployment

`DeploySpendSmart` defaults to `false`. The chart consumes external credentials and service configuration, so first deploy the infrastructure, connect to the private cluster, create namespace `spendsmart`, and create these chart-required Secrets using an approved secret-management process:

- `harbor-ldc-coe-regcred`
- `encryption-key`
- `clickhouse`
- `clickhouse-db`
- `aws-access`
- `base-url`
- `gemini-key`
- `postgres-config`

Then package `main.yml` again and update the stack with `DeploySpendSmart=true`. The `modules/spendsmart/template.yaml` nested stack launches a private deployment host, installs the AWS Load Balancer Controller and the chart from branch `feature/spendsmart-helm-chart`, and applies the frontend Ingress. Its EKS access entry grants cluster-admin permissions while the host installs controller cluster-scoped resources. The private host has no inbound rules and uses Systems Manager Session Manager for administration; it remains until the module is removed and incurs EC2 charges while enabled.

The Ingress uses `target-type: instance` and forces `frontend.service.type=NodePort`. The controller owns the ALB and keeps eligible worker EC2 instances registered as nodes change. The ALB DNS name appears in `kubectl get ingress spendsmart -n spendsmart`, not in CloudFormation outputs.

Optional environment-specific, non-secret chart overrides can be downloaded from S3 by setting both `SpendSmartValuesS3Uri` and `SpendSmartValuesS3ObjectArn` to the object's URI and exact ARN. The deployment role receives `s3:GetObject` only for that ARN. Do not store credentials in the values file.

## Deploy Infrastructure

From this directory, replace `<TEMPLATE_BUCKET>` with an existing bucket in the target account and region:

```sh
aws cloudformation package \
  --template-file main.yml \
  --s3-bucket <TEMPLATE_BUCKET> \
  --output-template-file packaged.yml \
  --region us-east-1

aws cloudformation validate-template \
  --template-body file://packaged.yml \
  --region us-east-1

aws cloudformation create-stack \
  --stack-name spendsmart-dev \
  --template-body file://packaged.yml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

aws cloudformation wait stack-create-complete \
  --stack-name spendsmart-dev \
  --region us-east-1
```

Check stack events with:

```sh
aws cloudformation describe-stack-events \
  --stack-name spendsmart-dev \
  --region us-east-1
```

After setting up the namespace Secrets, package again and enable application installation:

```sh
aws cloudformation package --template-file main.yml --s3-bucket <TEMPLATE_BUCKET> \
  --output-template-file packaged.yml --region us-east-1
aws cloudformation deploy --template-file packaged.yml --stack-name spendsmart-dev \
  --parameter-overrides DeploySpendSmart=true \
  --capabilities CAPABILITY_NAMED_IAM --region us-east-1
```

Use the same region for the stack, template bucket, EC2 key pair, and AMI lookup. Change `BastionSshCidr` to a trusted CIDR and use a globally unique `S3BucketName`. The defaults create a NAT gateway and a private-only EKS endpoint; the NAT gateway, EKS control plane, EC2 nodes, optional bastion, optional deployment host, controller-managed ALB, and data transfer incur charges. The S3 bucket is retained when the stack is deleted.
