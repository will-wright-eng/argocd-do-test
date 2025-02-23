resource "digitalocean_kubernetes_cluster" "cluster" {
  name    = var.cluster_name
  region  = var.region
  version = var.kubernetes_version

  node_pool {
    name       = "${var.cluster_name}-worker-pool"
    size       = var.node_pool_size
    node_count = var.node_count
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
    tags = ["${var.cluster_name}-node", var.environment]
  }

  tags = ["${var.cluster_name}", var.environment]
}
# Create a project to organize resources (optional but recommended)
resource "digitalocean_project" "project" {
  name        = "${var.cluster_name}-project"
  description = "A project to group ${var.environment} cluster resources"
  purpose     = "Demo/Learning"
  environment = var.environment
  resources   = [digitalocean_kubernetes_cluster.cluster.urn]
}

resource "digitalocean_container_registry" "registry" {
  name                   = "${var.cluster_name}-registry"
  subscription_tier_slug = "basic"
  region                 = var.region
}

# Add Kubernetes namespace resource
resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  depends_on = [digitalocean_kubernetes_cluster.cluster]
}
