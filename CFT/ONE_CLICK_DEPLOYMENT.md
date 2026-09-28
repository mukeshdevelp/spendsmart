# SpendSmart One-Click Deployment Guide

This guide deploys the infrastructure in `template.yaml` as one CloudFormation stack. The AWS Console path is a short guided form; the CLI path is a single deploy command after the values below have been prepared. The application Helm release is a separate step because the chart links and values are intentionally left for you to provide.

## What Gets Deployed

The stack creates a VPC, two public and two private subnets, internet gateway, one or two NAT gateways, optional bastion host, private EKS cluster, two EKS managed node groups, three EKS add-ons, an Application Load Balancer, an encrypted/versioned S3 bucket, a Glue database and role, an Athena workgroup, and analytics IAM resources.

CloudFormation manages these resources independently from Terraform. Do not deploy this stack over resources already managed by Terraform unless you have a deliberate resource-import/migration plan.

## One-Time Preparation

Do these checks once before creating the stack:

1. Select the AWS account and region where the infrastructure should live. The example region below is `us-east-1`.
2. Make sure the account has deployment permissions for CloudFormation, IAM, EC2/VPC, EKS, ELB, S3, Glue, and Athena. The IAM role names are explicit, so the deploy action must allow `CAPABILITY_NAMED_IAM`.
3. `parameters.json` uses the existing `us-east-1` EC2 key-pair name `observabilty.pem` (spelled exactly as AWS reports it). The parameter must be the key-pair **name**, not a different local private-key filename.
4. Change `BastionSshCidr` in `parameters.json` to your public IP followed by `/32`, for example `203.0.113.10/32`. Do not leave `0.0.0.0/0` for production.
5. Change `S3BucketName` in `parameters.json` to a name not already used anywhere in AWS. Bucket names are globally unique.
6. Confirm that the selected region has at least two available AZs, EKS quota, NAT gateway/EIP quota, and support for `EksClusterVersion` and `EksNodeInstanceType` in `template.yaml`.
7. Review `EksNodesEgressCidr`. The default `10.0.0.0/16` copies Terraform. Ensure the cluster's security groups and your required VPC endpoints/NAT path permit the node bootstrap, image pulls, and application egress that your deployment needs.
8. Review costs before continuing. NAT gateways, EKS control planes, EC2 nodes, the bastion, ALB, and data transfer have ongoing charges.

The template defaults to a private-only EKS API endpoint. Your computer must have private network connectivity to the VPC (such as VPN or Direct Connect) to run `kubectl` and Helm. Otherwise, connect from an appropriately configured bastion host. The EC2 key pair only provides SSH access; the template does not install kubectl or Helm on the bastion.

## Console: Guided One-Click Path

1. Open the AWS CloudFormation console in the target region.
2. Choose **Create stack**, then **With new resources (standard)**.
3. Choose **Upload a template file**, select `CFT/template.yaml`, and continue.
4. Enter stack name `spendsmart-dev` (or another unique name), then continue.
5. On the parameters page, keep the Terraform-matching defaults where suitable. Set at least:
  - `Ec2KeyName`: `observabilty.pem`, the verified regional key-pair name.
   - `BastionSshCidr`: your trusted public IP CIDR, not `0.0.0.0/0`.
   - `S3BucketName`: globally unique bucket name.
   - `EksClusterVersion` and `EksNodeInstanceType`: versions/types available in this region.
6. Continue through **Configure stack options**. Add tags or notifications if needed.
7. On **Review**, acknowledge that CloudFormation may create IAM resources by selecting the acknowledgement for custom names, then choose **Submit**.
8. On the stack page, wait for `CREATE_COMPLETE`. For errors, open **Events** and start with the first `CREATE_FAILED` entry, not only the final rollback message.
9. Open **Outputs** and save the cluster name, `EksConfigureKubectl` command, ALB DNS name, bucket name, Glue database, and analytics role ARN.

The Console uses the local template directly. No template S3 bucket is required for this template size.

## Folder Structure
my-platform/
│
├── README.md
├── Makefile
├── .gitignore
│
├── cloudformation/
│   │
│   ├── modules/
│   │   │
│   │   ├── network/
│   │   │   ├── vpc.yaml
│   │   │   ├── subnets.yaml
│   │   │   ├── routes.yaml
│   │   │   ├── nat.yaml
│   │   │   └── outputs.yaml
│   │   │
│   │   ├── security/
│   │   │   ├── security-groups.yaml
│   │   │   └── nacl.yaml
│   │   │
│   │   ├── iam/
│   │   │   ├── roles.yaml
│   │   │   ├── policies.yaml
│   │   │   └── instance-profiles.yaml
│   │   │
│   │   ├── compute/
│   │   │   ├── launch-template.yaml
│   │   │   ├── autoscaling.yaml
│   │   │   └── ec2.yaml
│   │   │
│   │   ├── load-balancer/
│   │   │   ├── alb.yaml
│   │   │   ├── target-groups.yaml
│   │   │   └── listeners.yaml
│   │   │
│   │   ├── database/
│   │   │   ├── rds.yaml
│   │   │   ├── subnet-group.yaml
│   │   │   └── parameter-group.yaml
│   │   │
│   │   ├── cache/
│   │   │   └── redis.yaml
│   │   │
│   │   ├── storage/
│   │   │   ├── s3.yaml
│   │   │   └── ebs.yaml
│   │   │
│   │   ├── container/
│   │   │   └── ecr.yaml
│   │   │
│   │   ├── monitoring/
│   │   │   ├── cloudwatch.yaml
│   │   │   ├── alarms.yaml
│   │   │   └── dashboards.yaml
│   │   │
│   │   └── dns/
│   │       └── route53.yaml
│   │
│   ├── stacks/
│   │   │
│   │   ├── network.yaml
│   │   ├── security.yaml
│   │   ├── iam.yaml
│   │   ├── compute.yaml
│   │   ├── alb.yaml
│   │   ├── database.yaml
│   │   ├── cache.yaml
│   │   ├── storage.yaml
│   │   └── monitoring.yaml
│   │
│   └── policies/
│       ├── cfn-policy.yaml
│       └── resource-policy.yaml
│
├── environments/
│   │
│   ├── dev/
│   │   ├── parameters.json
│   │   └── config.yaml
│   │
│   ├── staging/
│   │   ├── parameters.json
│   │   └── config.yaml
│   │
│   └── prod/
│       ├── parameters.json
│       └── config.yaml
│
├── scripts/
│   ├── validate.sh
│   ├── lint.sh
│   ├── deploy.sh
│   ├── delete.sh
│   └── package.sh
│
├── helm/
│   │
│   └── application/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-staging.yaml
│       ├── values-prod.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── configmap.yaml
│           ├── secret.yaml
│           ├── hpa.yaml
│           └── serviceaccount.yaml
│
├── application/
│   ├── Dockerfile
│   ├── src/
│   └── tests/
│
├── ci-cd/
│   ├── Jenkinsfile
│   └── pipelines/
│       ├── infrastructure.groovy
│       ├── application.groovy
│       └── security.groovy
│
└── docs/
    ├── architecture.md
    ├── networking.md
    ├── security.md
    ├── deployment.md
    └── disaster-recovery.md
## CLI: Single-Command Deployment

Install AWS CLI v2, set credentials for the intended account, and edit `parameters.json` as described above. From a terminal, run this command from the `CFT` folder; replace the region if needed:

```sh
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name spendsmart-dev \
  --parameter-overrides Ec2KeyName=observabilty.pem BastionSshCidr=203.0.113.10/32 S3BucketName=your-globally-unique-bucket-name \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

This command creates or updates the stack and waits for the deployment result. Replace the example key-pair name, IP, bucket, and region with your own. Other parameter defaults come from `template.yaml`. To use the values in `parameters.json` instead, use the Console flow above or run `create-stack` with `--parameters file://parameters.json` and then wait for completion.

Confirm status and fetch outputs:

```sh
aws cloudformation describe-stacks \
  --stack-name spendsmart-dev \
  --query 'Stacks[0].[StackStatus,Outputs]' \
  --output yaml \
  --region us-east-1
```

To find the cause of a failure:

```sh
aws cloudformation describe-stack-events \
  --stack-name spendsmart-dev \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table \
  --region us-east-1
```

## Install the Application with Helm

Infrastructure creation does not install the SpendSmart application. Configure network access to the private EKS endpoint, then use the `EksConfigureKubectl` stack output:

```sh
aws eks update-kubeconfig --region us-east-1 --name spendsmart
kubectl get nodes
```

Fill these chart details when ready; links are intentionally blank:

- SpendSmart Helm repository URL:
- SpendSmart chart reference:
- SpendSmart chart version:
- Values file path:
- AWS Load Balancer Controller Helm repository URL, if required:
- AWS Load Balancer Controller chart reference, if required:

Example install command after filling in your chart values:

```sh
helm repo add spendsmart <CHART_REPOSITORY_URL>
helm repo update
helm upgrade --install spendsmart <CHART_REFERENCE> \
  --namespace spendsmart \
  --create-namespace \
  --values <VALUES_FILE>
```

### ALB and Helm Are Not Yet Connected

The stack creates an ALB listener and target group on port `30080`, but the Terraform and CloudFormation configurations do not register EKS node instances in that target group and do not install the AWS Load Balancer Controller. The ALB can therefore exist while reporting no healthy targets. Before expecting application traffic to work, choose and configure one integration:

- Use the pre-created ALB/target group and arrange target registration plus health-check/NodePort compatibility; or
- Install and configure the AWS Load Balancer Controller and let Kubernetes ingress resources manage an ALB.

These are different approaches. Configure the Helm chart and networking for the approach you choose.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `InvalidClientTokenId`, `ExpiredToken`, or `AccessDenied` | CLI credentials are expired, wrong-account, or lack required permissions. | Re-authenticate (for example, `aws sso login --profile <profile>`), set the intended profile, run `aws sts get-caller-identity`, and retry. Check IAM permissions for all resource services and `iam:PassRole`. |
| `InsufficientCapabilitiesException` | Named IAM resources were not acknowledged. | In the Console, acknowledge IAM resource creation. In CLI, include `--capabilities CAPABILITY_NAMED_IAM`. |
| `CREATE_FAILED` for `EksCluster` due to version/platform | Kubernetes version is unsupported in the selected region, or EKS quota is exhausted. | Choose an EKS version currently offered in that region and confirm cluster quota before retrying. |
| Node group fails or has zero ready nodes | Instance type unavailable, subnet/AZ capacity issue, IAM role issue, or required node network egress is blocked. | Check the node-group event reason; choose an available instance type, verify both private subnets and node IAM policies, and ensure required EKS/ECR/S3 connectivity through permitted security-group egress and NAT/VPC endpoints. |
| `InvalidKeyPair.NotFound` or EC2 key validation failure | `Ec2KeyName` is misspelled or belongs to another region. | Use the exact key-pair name from the target region. The verified `us-east-1` value is `observabilty.pem`. |
| `BucketAlreadyExists` or bucket name conflict | The bucket name is globally allocated to another AWS account. | Change `S3BucketName` to a globally unique name and redeploy. |
| NAT gateway or EIP quota error | Regional quotas or address limits are insufficient. | Request a quota increase, or set `EnableNatPerAz` to `false` for one NAT; set `EnableNatGateway` to `false` only if private subnet connectivity is not required/provided elsewhere. |
| Subnet CIDR overlap or insufficient IP addresses | The default CIDRs conflict with an existing network or are too small for cluster resources. | Choose four non-overlapping CIDRs within `VpcCidr`; reserve adequate private subnet IP capacity for EKS ENIs and pods. |
| `CREATE_ROLLBACK_IN_PROGRESS` | An earlier resource failed and CloudFormation is removing resources it created. | Use the Events query above to find the first failure, correct its cause, wait for `ROLLBACK_COMPLETE`, then retry. If stack deletion is still running, wait for it to finish before reusing the stack name. |
| Stack says `UPDATE_COMPLETE` but no resources changed | Submitted template/parameters match the current stack. | This is expected; check Outputs and Events. Make a real parameter/template change to trigger an update. |
| `kubectl` times out or cannot connect | The EKS API endpoint is private-only by default. | Run kubectl from a host with VPN/Direct Connect/VPC connectivity, or change endpoint access intentionally and restrict public CIDRs before applying. |
| `kubectl get nodes` returns no nodes | Node group is still provisioning, or node bootstrap/connectivity failed. | Wait for node-group status `ACTIVE`; inspect EKS node-group health issues, CloudFormation events, cluster security groups, node role, subnet routes, and egress. |
| Helm cannot find chart or reports repository errors | Chart repository/reference placeholders were not filled or repository credentials are missing. | Fill the chart URL/reference, run `helm repo add` with the correct URL and credentials, then `helm repo update`. |
| ALB has no healthy targets or returns 503 | The target group is not connected to Kubernetes targets; this is the current template behavior. | Implement one of the ALB integrations described above, then verify target port, health-check path, security-group access, and target health. |

For every failure, the first useful diagnostic is the earliest resource-level `CREATE_FAILED` event and its `ResourceStatusReason`. The final rollback event usually only reports the consequence.

## Delete and Cost Cleanup

Deleting the stack removes the EKS cluster, nodes, NAT gateway(s), ALB, bastion, and network resources. The S3 bucket uses a retain policy and remains in the account with its data. Confirm that the bucket contents are no longer needed before manually deleting it.

```sh
aws cloudformation delete-stack \
  --stack-name spendsmart-dev \
  --region us-east-1

aws cloudformation wait stack-delete-complete \
  --stack-name spendsmart-dev \
  --region us-east-1
```