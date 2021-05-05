variable "cluster_name" {
  type      = string
  default   = "test-eks-spot-${random_string.suffix.result}"
}