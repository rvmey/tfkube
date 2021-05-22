output "cluster_id" {
  value = module.eks.cluster_id
}

output "kubeconfig_filename" {
  description = "The filename of the generated kubectl config."
  value       = module.eks.kubeconfig_filename
}