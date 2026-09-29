# SpendSmart CloudFormation Deployment

This folder contains an independent AWS CloudFormation deployment of the infrastructure described by the Terraform files in the parent folder. It does not modify or depend on Terraform state. `main.yml` is the modular root stack; its nested templates live under `modules/` and are uploaded with `aws cloudformation package`. `template.yaml` remains the monolithic reference template.

For the guided Console deployment, single-command CLI deployment, and troubleshooting, see [ONE_CLICK_DEPLOYMENT.md](ONE_CLICK_DEPLOYMENT.md).
For the resource topology, CloudFormation/Helm ownership split, inline Lambda rationale, and complete output catalog, see [ARCHITECTURE.md](ARCHITECTURE.md).

The root stack re-exports outputs from the nested stacks. Subnet/NAT maps and the node-group list are JSON strings.

## What This Template Creates

CloudFormation provisions the AWS infrastructure. It does not deploy the SpendSmart application or install the AWS Load Balancer Controller workload.

### Network

- One configurable VPC with DNS support and DNS hostnames.
- Two public and two private subnets in separate Availability Zones, tagged for Kubernetes subnet discovery.
- An internet gateway, public route table/default route, and subnet route-table associations.
- One NAT gateway and EIP when NAT is enabled; both private subnets share its route table.

### Access and Compute

- Optional Amazon Linux bastion in a public subnet, with SSH security group, existing EC2 key pair, IMDSv2, encrypted root volume, and optional Elastic IP.
- Private EKS cluster with two managed node groups, one per private subnet/AZ.
- EKS cluster/node IAM roles, node launch template/security group, and the `vpc-cni`, `kube-proxy`, `coredns`, and `eks-pod-identity-agent` add-ons.

### Load Balancer Controller Foundation

- IAM role with the AWS Load Balancer Controller's published IAM policy.
- EKS Pod Identity association binding that role to the configured controller service account.
- An ALB security group, application load balancer, listener, and target group. The controller IAM role and Pod Identity association are also created; install the controller workload separately with Helm.

### Storage and Analytics

- S3 bucket with configurable versioning, encryption, public-access blocks, and Athena-results lifecycle policy. The bucket is retained on stack deletion.
- Glue database and service role with access to the configured S3 data prefix.
- Athena workgroup with S3 result location, encryption, metrics setting, and bytes-scanned cutoff.
- Analytics IAM role and policy for Athena, Glue, Cost Explorer, and AWS resource metadata.

### Created Later by Helm/Kubernetes

- AWS Load Balancer Controller Deployment in the configured namespace/service account.
- SpendSmart Deployment/Service and Ingress from the application Helm chart.
- Application-specific Kubernetes resources and Ingress configuration.

## Parameters

All infrastructure input/configuration values are exposed as CloudFormation parameters with defaults matching Terraform. `parameters.json` contains example account-specific overrides. CloudFormation resource types, standard AWS tag keys, the Kubernetes AZ-label key, and the AWS Load Balancer Controller policy actions remain fixed because they define resource schemas or controller security behavior.

## Before deployment

1. Use AWS CLI v2 with credentials authorized to create VPC, EC2, EKS, IAM, EKS Pod Identity associations, S3, Glue, and Athena resources. The stack creates named IAM resources, so deployment requires `CAPABILITY_NAMED_IAM`.
2. Choose a region with at least two available Availability Zones and support for the selected EKS Kubernetes version and EC2 instance type.
3. `Ec2KeyName` in `parameters.json` is set to `observabilty.pem`, the key-pair name verified in `us-east-1`. Keep the spelling exact and use this stack in the same region.
4. Change `BastionSshCidr` in `parameters.json` from `0.0.0.0/0` to your trusted public IP in CIDR notation, such as `203.0.113.10/32`.
5. S3 bucket names are globally unique. Change `S3BucketName` in `parameters.json` if `athena-results-spendsmart-dev` is already taken.
6. `EksNodesEgressCidr` defaults to `0.0.0.0/0` so private nodes can bootstrap and the controller can call AWS APIs through NAT. For production, restrict egress using the required VPC endpoints and corresponding security-group rules.
7. The defaults use one NAT gateway and a private-only EKS API endpoint. A NAT gateway has ongoing hourly and data-processing charges. Use a connected VPC network, VPN, Direct Connect, or the bastion host to run `kubectl` and Helm against the cluster.
8. Confirm the selected region/EKS version supports EKS Pod Identity and `AWS::EKS::PodIdentityAssociation`. CloudFormation creates the Pod Identity Agent and controller identity; Helm installs the controller workload after stack creation.

The template retains the S3 bucket when the stack is deleted. Remove its objects and delete the bucket separately if it should be removed.

## Deploy

From this `CFT` directory, package the nested templates to an existing S3 bucket, then create the root stack. Replace `<TEMPLATE_BUCKET>` with a bucket in the deployment account and region:

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

Use the same region for the template bucket, stack, key pair, and AMI lookup. For subsequent changes, package `main.yml` again and use the new `packaged.yml` with `aws cloudformation update-stack`. Check progress or failures with:

```sh
aws cloudformation describe-stack-events \
  --stack-name spendsmart-dev \
  --region us-east-1
```

Get the stack outputs, including the cluster endpoint, ALB DNS name, controller role ARN, S3 locations, and analytics role ARNs:

```sh
aws cloudformation describe-stacks \
  --stack-name spendsmart-dev \
  --query 'Stacks[0].Outputs' \
  --output table \
  --region us-east-1
```

## Deploy workloads with Helm

CloudFormation provisions EKS, node groups, the Pod Identity Agent, and the controller IAM role/association. Install the controller and application charts afterward from a machine that can reach the cluster's private API endpoint. First configure `kubectl` using the `EksConfigureKubectl` stack output, then verify access:

```sh
aws eks update-kubeconfig --region us-east-1 --name spendsmart
kubectl get nodes
```

Fill in the chart details below with the links and values for your charts:

- SpendSmart chart repository URL:
- SpendSmart chart reference:
- SpendSmart chart version:
- Values file path:
- AWS Load Balancer Controller chart repository URL:
- AWS Load Balancer Controller chart reference/version matching `AlbControllerVersion`:

Install the AWS Load Balancer Controller first using its official chart instructions and a version matching `AlbControllerVersion`. Configure its chart values to use the stack outputs/parameters `AlbControllerNamespace` and `AlbControllerServiceAccountName`. Do not create static AWS credentials: the EKS Pod Identity association binds this Kubernetes service account to `AlbControllerRoleArn`.

Add the SpendSmart chart repository and install or upgrade the application, substituting your chart reference and values file:

```sh
helm repo add spendsmart <CHART_REPOSITORY_URL>
helm repo update
helm upgrade --install spendsmart <CHART_REFERENCE> \
  --namespace spendsmart \
  --create-namespace \
  --values <VALUES_FILE>
```

Install the AWS Load Balancer Controller first using the official AWS chart instructions and the release matching `AlbControllerVersion`. Configure the chart to use `AlbControllerNamespace` and `AlbControllerServiceAccountName` from the stack. The service account must not use static AWS credentials: the EKS Pod Identity association binds it to `AlbControllerRoleArn`. The stack-created ALB is separate from any additional ALB the controller provisions for an Ingress.

The SpendSmart chart must create a Kubernetes Ingress using the AWS Load Balancer Controller class (usually `alb`) and appropriate scheme, listener, health-check, and certificate configuration. For example, the chart's Ingress template should produce equivalent annotations and fields:

```yaml
ingressClassName: alb
annotations:
  alb.ingress.kubernetes.io/scheme: internet-facing
  alb.ingress.kubernetes.io/target-type: ip
  alb.ingress.kubernetes.io/healthcheck-path: /healthz
```

Use `target-type: ip` for direct pod targets (recommended with the AWS VPC CNI); verify pod networking and service ports. Once the Ingress is accepted, the controller can provision its own ALB, listeners, target groups, security rules, and target registrations, reconciling them as pods/nodes change.

Verify controller and Ingress reconciliation:

```sh
kubectl -n kube-system get deployment aws-load-balancer-controller
kubectl -n spendsmart get ingress
kubectl -n spendsmart describe ingress spendsmart
```

The stack-created ALB DNS name is available in the `AlbDnsName` output. Any controller-created ALB DNS name appears in the Ingress `ADDRESS` field after reconciliation. `AlbTargetGroupArn` identifies the stack-created target group; inspect controller events or the EC2 Load Balancers console for Ingress-managed target groups.

## Delete the stack

Deleting the stack removes its compute and networking resources, including the single NAT gateway, which stops incurring charges after deletion completes. The S3 bucket has a retain policy and will remain in the account:

```sh
aws cloudformation delete-stack \
  --stack-name spendsmart-dev \
  --region us-east-1
```

Delete the retained bucket manually only after confirming its data is no longer needed.

---


SpendSmart AWS Infrastructure
│
├── 1. VPC Networking
│   ├── VPC
│   ├── Internet Gateway
│   ├── 2 Public Subnets
│   ├── 2 Private Subnets
│   ├── Route Tables
│   ├── NAT Gateway
│   └── NAT Elastic IP
│
├── 2. Bastion
│   ├── EC2 Instance
│   ├── Security Group
│   ├── Elastic IP
│   └── IAM Role
│
├── 3. EKS
│   ├── EKS Cluster
│   ├── Cluster IAM Role
│   ├── Node IAM Role
│   ├── Node Security Group
│   ├── Launch Template
│   ├── Node Group AZ1
│   └── Node Group AZ2
│
├── 4. ALB
│   ├── Security Group
│   ├── Application Load Balancer
│   ├── Listener
│   └── Target Group
│
├── 5. EKS Add-ons
│   ├── VPC CNI
│   ├── CoreDNS
│   ├── kube-proxy
│   └── Pod Identity Agent
│
├── 6. AWS Load Balancer Controller
│   ├── IAM Role
│   └── Pod Identity Association
│
├── 7. S3
│   └── Data Bucket
│
├── 8. AWS Glue
│   ├── Glue Database
│   └── Glue IAM Role
│
├── 9. Athena
│   └── Athena Workgroup
│
└── 10. Analytics IAM
    ├── Analytics Role
    └── Analytics Policy