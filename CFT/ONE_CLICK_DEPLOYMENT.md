# SpendSmart One-Click Deployment Guide

This guide deploys the modular CloudFormation root stack in `main.yml`. Its nested templates are under `modules/`; package them to S3 before deployment. SpendSmart Helm deployment is opt-in because its image-pull and application Secrets must already exist in EKS. See [ARCHITECTURE.md](ARCHITECTURE.md) for the module layout and stack outputs.

## What Gets Deployed

CloudFormation creates the VPC, public/private subnets and routing, one NAT gateway, optional bastion, private EKS cluster, two managed node groups eligible in both private subnets, EKS add-ons including the Pod Identity Agent, the Load Balancer Controller IAM role and Pod Identity association, S3, Glue, Athena, and analytics IAM resources. The controller creates the application ALB and target group from the Ingress and registers worker nodes.

Set `DeploySpendSmart=true` only after the required namespace Secrets exist. The optional nested module installs the controller and app with Helm and applies the frontend Ingress.

## Before You Start

1. Select the target AWS account and region. Commands below use `us-east-1`.
2. Use credentials authorized for CloudFormation, IAM, VPC/EC2, EKS and Pod Identity, S3, Glue, and Athena. The stack creates named IAM resources; deployment requires `CAPABILITY_NAMED_IAM`.
3. The current `parameters.json` uses EC2 key-pair name `mukesh`. Keep the exact AWS spelling.
4. Replace the broad `BastionSshCidr` value in `parameters.json` with your trusted public IP in CIDR notation, for example `203.0.113.10/32`.
5. S3 bucket names are globally unique. Set `S3BucketName` to an unused name in `parameters.json` before deploying.
6. Confirm the EKS version, instance type, EKS/EC2/NAT quotas, and EKS Pod Identity support are available in the selected region.
7. `EksNodesEgressCidr` defaults to `0.0.0.0/0` so private nodes can bootstrap and the controller can reach AWS APIs through NAT. Restrict egress in production using the required VPC endpoints and security-group rules.
8. The EKS API endpoint is private-only by default. Run `kubectl` and Helm from a network with VPC connectivity, such as VPN, Direct Connect, or the configured bastion.

The NAT gateway, EKS control plane, EC2 nodes, bastion, ALB, and data transfer incur AWS charges. The S3 bucket is retained when the stack is deleted.

## Console Deployment

1. From the `CFT` directory, package `main.yml` and its nested templates to an S3 bucket in the target region:

   ```sh
   aws cloudformation package \
     --template-file main.yml \
     --s3-bucket <TEMPLATE_BUCKET> \
     --output-template-file packaged.yml \
     --region us-east-1
   ```

2. Open CloudFormation in the target region and choose **Create stack**, then **With new resources (standard)**.
3. Upload `CFT/packaged.yml`.
4. Use stack name `spendsmart-dev`.
5. Review parameters. Confirm `Ec2KeyName`, set `BastionSshCidr` to your IP, and choose a unique `S3BucketName`.
6. Continue to **Review**, acknowledge IAM resource creation, then submit.
7. Wait for `CREATE_COMPLETE`. If it fails, open **Events** and inspect the earliest resource-level failure.
8. In **Outputs**, record `EksConfigureKubectl`, `AlbControllerRoleArn`, `AlbControllerNamespace`, `AlbControllerServiceAccountName`, `AlbControllerVersion`, and the data/analytics values you need.

## CLI Deployment

From the `CFT` directory, use AWS CLI v2. Edit the `S3BucketName` and `BastionSshCidr` values in `parameters.json` first. Replace `<TEMPLATE_BUCKET>` with an existing S3 bucket in the deployment region:

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

For updates, package `main.yml` again and use `aws cloudformation update-stack` with the packaged template, parameters, and capabilities. To inspect stack outputs:

```sh
aws cloudformation describe-stacks \
  --stack-name spendsmart-dev \
  --query 'Stacks[0].Outputs' \
  --output table \
  --region us-east-1
```

For a failed operation, inspect the earliest failed event:

```sh
aws cloudformation describe-stack-events \
  --stack-name spendsmart-dev \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`].[Timestamp,LogicalResourceId,ResourceStatusReason]' \
  --output table \
  --region us-east-1
```

## Deploy SpendSmart

Deploy the infrastructure first with the default `DeploySpendSmart=false`. From a network connected to the private EKS API, configure kubectl and create the namespace:

```sh
aws eks update-kubeconfig --region us-east-1 --name spendsmart
kubectl get nodes
kubectl create namespace spendsmart
```

Create these Kubernetes Secrets in `spendsmart` through your approved secret-management process before enabling the module:

- `harbor-ldc-coe-regcred`
- `encryption-key`
- `clickhouse`
- `clickhouse-db`
- `aws-access`
- `base-url`
- `gemini-key`
- `postgres-config`

Package `main.yml` again and update the stack with `DeploySpendSmart=true`:

```sh
aws cloudformation package --template-file main.yml --s3-bucket <TEMPLATE_BUCKET> \
  --output-template-file packaged.yml --region us-east-1
aws cloudformation deploy --template-file packaged.yml --stack-name spendsmart-dev \
  --parameter-overrides DeploySpendSmart=true \
  --capabilities CAPABILITY_NAMED_IAM --region us-east-1
```

For environment-specific, non-secret overrides, set both `SpendSmartValuesS3Uri` and `SpendSmartValuesS3ObjectArn` to the URI and exact object ARN. Never put credentials in this file.

The module installs the AWS Load Balancer Controller and chart from `feature/spendsmart-helm-chart`, changes the frontend Service to `NodePort`, and applies an Ingress with `target-type: instance`. Verify the Ingress and target health:

```sh
kubectl -n kube-system get deployment aws-load-balancer-controller
kubectl -n spendsmart get ingress spendsmart
kubectl -n spendsmart describe ingress spendsmart
```

The ALB DNS name appears in the Ingress `ADDRESS` field. The controller owns and reconciles the target group and worker-node registration.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `InvalidClientTokenId`, `ExpiredToken`, or `AccessDenied` | Credentials are expired, point to another account, or lack permissions. | Reauthenticate, verify `aws sts get-caller-identity`, and check CloudFormation/IAM/EC2/EKS/Pod Identity/S3/Glue/Athena permissions. |
| `InsufficientCapabilitiesException` | Named IAM resources were not acknowledged. | Add `--capabilities CAPABILITY_NAMED_IAM` or acknowledge IAM resources in the Console. |
| EKS cluster creation fails | Unsupported EKS version, missing quota, or regional availability issue. | Select a supported EKS version/region and verify service quotas. |
| Node groups fail or have no ready nodes | Instance capacity, IAM, subnet IP capacity, or egress issue. | Inspect EKS node-group health; verify node role, private subnet routes, IP capacity, and required AWS API/image-pull egress. |
| `InvalidKeyPair.NotFound` | Key-pair name is misspelled or in another region. | Use the exact regional key name `mukesh` in `us-east-1`. |
| S3 bucket name conflict | Bucket names are globally unique. | Choose a new unused `S3BucketName`. |
| `kubectl` cannot connect | EKS endpoint is private-only. | Run commands from a network connected to the VPC or deliberately enable restricted public endpoint access. |
| Controller reports `AccessDenied` | Pod Identity association or service-account settings do not match the Helm release. | Compare Helm namespace/service account with `AlbControllerNamespace` and `AlbControllerServiceAccountName`; inspect controller logs and association status. |
| Ingress has no ALB address | Controller is not ready, Ingress class is wrong, subnet tags are missing, or AWS API egress is blocked. | Check controller deployment/events, `ingressClassName: alb`, public-subnet discovery tags, and node/pod egress through NAT or endpoints. |
| ALB target health is unhealthy/503 | Backend Service ports, target type, health-check path, or pod reachability is wrong. | Check Service endpoints/ports and Ingress annotations; inspect controller logs and target health. |

## Delete and Cost Cleanup

Remove application Ingress resources first so the controller can delete their ALBs and target groups, then delete the CloudFormation stack:

```sh
aws cloudformation delete-stack \
  --stack-name spendsmart-dev \
  --region us-east-1
aws cloudformation wait stack-delete-complete \
  --stack-name spendsmart-dev \
  --region us-east-1
```

The S3 bucket is retained with its data. Delete it separately only after confirming its contents are no longer needed.
