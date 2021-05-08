locals {
    tags = {
        "Application"   = "Kubernetes"
        "Terraform"     = "true"
        "Stage"         = terraform.workspace
        "Cluster"       = local.cluster_name
    }
    cluster_name = var.cluster_name == "" ? "eks-spot-${random_string.suffix.result}" : var.cluster_name
    k8s_service_account_namespace = "default"
    k8s_service_account_name      = "triggercmd"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.47"

  name                 = "test-vpc-spot"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
}

module "eks" {
  source          = "github.com/terraform-aws-modules/terraform-aws-eks"
  cluster_name    = local.cluster_name
  cluster_version = "1.17"
  subnets         = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id
  enable_irsa     = true

  worker_groups_launch_template = [
    {
      name                    = "spot-1"
      override_instance_types = ["m5.large", "m5a.large", "m5d.large", "m5ad.large"]
      spot_instance_pools     = 4
      asg_max_size            = 5
      asg_desired_capacity    = 5
      kubelet_extra_args      = "--node-labels=node.kubernetes.io/lifecycle=spot"
      public_ip               = true
    },
  ]
}

resource "aws_s3_bucket" "test_bucket" {
  bucket = "test-bucket-${local.cluster_name}"
  acl    = "private"

  tags = local.tags
}

module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "triggercmd"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.triggercmd_access.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"]
}

resource "aws_iam_policy" "triggercmd_access" {
  name_prefix = "triggercmd"
  description = "EKS triggercmd policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.triggercmd_access.json
}

data "aws_iam_policy_document" "triggercmd_access" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*"
    ]

    resources = [
      "${aws_s3_bucket.test_bucket.arn}",
      "${aws_s3_bucket.test_bucket.arn}/*"
    ]
  }
}

resource "kubernetes_service_account" "triggercmd" {
  metadata {
    name        = local.k8s_service_account_name
    namespace   = local.k8s_service_account_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/triggercmd"
    }
  }
}