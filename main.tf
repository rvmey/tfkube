locals {
    tags = {
        "Application"   = "Kubernetes"
        "Terraform"     = "true"
        "Stage"         = terraform.workspace
    }
}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_availability_zones" "available" {
}

locals {
  cluster_name = var.cluster_name
}

resource "random_string" "suffix" {
  length  = 8
  special = false
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
