output "cluster_endpoint" {
  description = "Endpoint for the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.cluster.endpoint
}
output "kubeconfig" {
  description = "Kubeconfig for the cluster"
  value       = digitalocean_kubernetes_cluster.cluster.kube_config[0].raw_config
  sensitive   = true
}
output "cluster_id" {
  description = "ID of the cluster"
  value       = digitalocean_kubernetes_cluster.cluster.id
}

output "registry_server" {
  description = "Container registry server URL"
  value       = digitalocean_container_registry.registry.server_url
}

output "registry_name" {
  description = "Container registry name"
  value       = digitalocean_container_registry.registry.name
}

output "cluster_name" {
  value = digitalocean_kubernetes_cluster.cluster.name
}

output "region" {
  value = digitalocean_kubernetes_cluster.cluster.region
}
