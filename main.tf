locals {
    tags = {
        "Application"   = "Kubernetes"
        "Terraform"     = "true"
        "Stage"         = terraform.workspace
        "Cluster"       = var.cluster_name
    }
}

data "aws_availability_zones" "available" {}

resource "aws_s3_bucket" "test_bucket" {
  bucket = "test-bucket-${var.cluster_name}"
  acl    = "private"

  tags = local.tags
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

resource "aws_iam_policy" "triggercmd_access" {
  name_prefix = "triggercmd"
  description = "EKS triggercmd policy for cluster ${module.k8s.cluster_id}"
  policy      = data.aws_iam_policy_document.triggercmd_access.json
  tags        = local.tags
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


module "k8s" {
  source  = "./modules/k8s"

  cluster_name        = "test-vpc-spot"

  subnets             = module.vpc.public_subnets
  vpc_id              = module.vpc.vpc_id
  iam_policy_arns     = [aws_iam_policy.triggercmd_access.arn]

  tags                = local.tags
}
