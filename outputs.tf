output "kubeconfig_filename" {
  description = "The filename of the generated kubectl config."
  value       = module.k8s.kubeconfig_filename
}