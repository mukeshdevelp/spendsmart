# SpendSmart CloudFormation Deployment

This folder contains an independent AWS CloudFormation deployment of the infrastructure described by the Terraform files in the parent folder. It does not modify or depend on Terraform state.

For the guided Console deployment, single-command CLI deployment, and troubleshooting, see [ONE_CLICK_DEPLOYMENT.md](ONE_CLICK_DEPLOYMENT.md).

## Included resources

- A VPC with two public and two private subnets, internet gateway, and configurable one-per-AZ or shared NAT gateways.
- An optional public bastion EC2 instance, security group, and Elastic IP.
- A private EKS cluster, two managed node groups, the `vpc-cni`, `kube-proxy`, and `coredns` add-ons, and their IAM roles and security groups.
- An internet-facing Application Load Balancer, listener, target group, and security groups.
- An encrypted and versioned S3 bucket, Glue database and role, Athena workgroup, and analytics IAM role and policy.

## Terraform Output Compatibility

The template exposes all 30 Terraform outputs. CloudFormation output keys must be alphanumeric, so the output identifiers use PascalCase; the mapping below records the corresponding Terraform names. CloudFormation output values are strings, so AZ-keyed subnet/NAT maps and the node-group list are JSON-encoded strings.

| CloudFormation output | Terraform output |
| --- | --- |
| `VpcId` | `vpc_id` |
| `VpcCidr` | `vpc_cidr` |
| `PublicSubnetIds` | `public_subnet_ids` |
| `PrivateSubnetIds` | `private_subnet_ids` |
| `NatGatewayIds` | `nat_gateway_ids` |
| `InternetGatewayId` | `internet_gateway_id` |
| `BastionInstanceId` | `bastion_instance_id` |
| `BastionSecurityGroupId` | `bastion_security_group_id` |
| `SshKeyPairName` | `ssh_key_pair_name` |
| `BastionPublicIp` | `bastion_public_ip` |
| `EksClusterName` | `eks_cluster_name` |
| `EksClusterEndpoint` | `eks_cluster_endpoint` |
| `EksClusterArn` | `eks_cluster_arn` |
| `EksClusterSecurityGroupId` | `eks_cluster_security_group_id` |
| `EksNodesSecurityGroupId` | `eks_nodes_security_group_id` |
| `EksNodeGroupNames` | `eks_node_group_names` |
| `EksConfigureKubectl` | `eks_configure_kubectl` |
| `AlbDnsName` | `alb_dns_name` |
| `AlbArn` | `alb_arn` |
| `AlbTargetGroupArn` | `alb_target_group_arn` |
| `BucketName` | `bucket_name` |
| `DataLocation` | `data_location` |
| `AthenaOutputLocation` | `athena_output_location` |
| `GlueDatabaseName` | `glue_database_name` |
| `GlueRoleArn` | `glue_role_arn` |
| `AthenaWorkgroupName` | `athena_workgroup_name` |
| `AnalyticsIamRoleName` | `analytics_iam_role_name` |
| `AnalyticsIamRoleArn` | `analytics_iam_role_arn` |
| `AnalyticsIamPolicyName` | `analytics_iam_policy_name` |
| `AnalyticsIamPolicyArn` | `analytics_iam_policy_arn` |

## Parameters

All infrastructure input/configuration values are exposed as CloudFormation parameters with defaults matching the Terraform configuration. `parameters.json` contains example account-specific overrides. CloudFormation resource types, standard AWS tag keys, the Kubernetes AZ-label key, and the IAM policy statements remain fixed because they define the resource schema or the intended security behavior rather than deployment-specific inputs.

## Before deployment

1. Use AWS CLI v2 with credentials authorized to create VPC, EC2, EKS, IAM, ELB, S3, Glue, and Athena resources. The stack creates named IAM resources, so deployment requires `CAPABILITY_NAMED_IAM`.
2. Choose a region with at least two available Availability Zones and support for the selected EKS Kubernetes version and EC2 instance type.
3. Create an EC2 key pair in that region. Update `Ec2KeyName` in `parameters.json` to its exact key-pair name; the Terraform value `observability.pem` is only a starting value and may not be the AWS key-pair name.
4. Change `BastionSshCidr` in `parameters.json` from `0.0.0.0/0` to your trusted public IP in CIDR notation, such as `203.0.113.10/32`.
5. S3 bucket names are globally unique. Change `S3BucketName` in `parameters.json` if `athena-results-spendsmart-dev` is already taken.
6. Review `EksNodesEgressCidr`. Its default, `10.0.0.0/16`, matches Terraform but only allows node egress within the VPC. This can prevent image pulls and external access through the NAT gateway. Set it to `0.0.0.0/0` or provide suitable VPC endpoints and security-group rules.
7. The defaults use one NAT gateway and a private-only EKS API endpoint. A NAT gateway has ongoing hourly and data-processing charges. Use a connected VPC network, VPN, Direct Connect, or the bastion host to run `kubectl` and Helm against the cluster.

The template retains the S3 bucket when the stack is deleted. Remove its objects and delete the bucket separately if it should be removed.

## Deploy

From this `CFT` directory, validate the template and create the stack:

```sh
aws cloudformation validate-template \
  --template-body file://template.yaml \
  --region us-east-1

aws cloudformation create-stack \
  --stack-name spendsmart-dev \
  --template-body file://template.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

aws cloudformation wait stack-create-complete \
  --stack-name spendsmart-dev \
  --region us-east-1
```

Use the same region for the stack, key pair, and AMI lookup. For subsequent changes, use `aws cloudformation update-stack` with the same template, parameters, capabilities, and region. Check progress or failures with:

```sh
aws cloudformation describe-stack-events \
  --stack-name spendsmart-dev \
  --region us-east-1
```

Get the stack outputs, including the cluster endpoint, ALB DNS name, S3 locations, and IAM role ARNs:

```sh
aws cloudformation describe-stacks \
  --stack-name spendsmart-dev \
  --query 'Stacks[0].Outputs' \
  --output table \
  --region us-east-1
```

## Deploy workloads with Helm

CloudFormation provisions the EKS cluster and its node groups; install the application charts afterward from a machine that can reach the cluster's private API endpoint. First configure `kubectl` using the `EksConfigureKubectl` stack output, then verify access:

```sh
aws eks update-kubeconfig --region us-east-1 --name spendsmart
kubectl get nodes
```

Fill in the chart details below with the links and values for your charts:

- SpendSmart chart repository URL:
- SpendSmart chart reference:
- SpendSmart chart version:
- Values file path:
- AWS Load Balancer Controller chart repository URL, if used:
- AWS Load Balancer Controller chart reference, if used:

Add the chart repository and install or upgrade the application, substituting the chart reference and values file:

```sh
helm repo add spendsmart <CHART_REPOSITORY_URL>
helm repo update
helm upgrade --install spendsmart <CHART_REFERENCE> \
  --namespace spendsmart \
  --create-namespace \
  --values <VALUES_FILE>
```

Install any required controllers or dependencies before the application chart, following their chart documentation. Configure the chart's Service type, NodePort, health-check path, and ingress/load-balancer annotations to match the application.

### Load balancer integration

The Terraform configuration creates an ALB and a target group on port `30080`, but it does not register EKS node instances in that target group or install the AWS Load Balancer Controller. This CloudFormation template preserves that behavior. The ALB will not route successfully until targets are registered and healthy. Decide whether the Helm deployment should use the pre-created ALB/target group with explicit target registration, or whether the AWS Load Balancer Controller should provision an ALB from Kubernetes ingress resources. Those are distinct integration paths; configure the chart/controller accordingly.

## Delete the stack

Deleting the stack removes its compute and networking resources, including the NAT gateway(s), which stop incurring charges after deletion completes. The S3 bucket has a retain policy and will remain in the account:

```sh
aws cloudformation delete-stack \
  --stack-name spendsmart-dev \
  --region us-east-1
```

Delete the retained bucket manually only after confirming its data is no longer needed.