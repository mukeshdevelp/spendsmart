# getting current account id for IAM module
data "aws_caller_identity" "current" {
  # no code is required here, it would just return the account id
}
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # S3 bucket names are globally unique. The account ID makes the default
  # name unique while allowing callers to provide an explicit name instead.
  bucket_name = var.bucket_name != "" ? var.bucket_name : "${local.name_prefix}-${data.aws_caller_identity.current.account_id}"
  
  # EKS Cluster IAM policies
  eks_cluster_policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

  eks_vpc_resource_controller_policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"

  # EKS Node IAM policies
  eks_node_worker_policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

  eks_node_cni_policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

  eks_node_ecr_policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  
  
  # for IAM module
  iam_trusted_principal_identifiers = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]

}
