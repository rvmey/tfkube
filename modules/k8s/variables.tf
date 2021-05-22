variable "cluster_name" {
  type      = string
  default   = ""
}

variable tags {
  type      = map
}

variable iam_policy_arns {
  type      = list
  default   = []
}

variable vpc_id {
  type      = string
}

variable subnets {
  type      = list
}


