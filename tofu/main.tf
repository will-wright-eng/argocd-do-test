resource "digitalocean_kubernetes_cluster" "cluster" {
  name    = var.cluster_name
  region  = var.region
  version = var.kubernetes_version
  node_pool {
    name       = "worker-pool"
    size       = var.node_pool_size
    node_count = var.node_count
    labels = {
      environment = "prototype"
    }
  }
}
# Create a project to organize resources (optional but recommended)
resource "digitalocean_project" "project" {
  name        = "${var.cluster_name}-project"
  description = "A project to group demo cluster resources"
  purpose     = "Demo/Learning"
  environment = "Development"
  resources   = [digitalocean_kubernetes_cluster.cluster.urn]
}

resource "digitalocean_container_registry" "registry" {
  name                   = "${var.cluster_name}-registry"
  subscription_tier_slug = "basic"
  region                 = "nyc3"
}
