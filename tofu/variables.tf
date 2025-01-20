variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "demo-argocd"
}
variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc1"
}
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31.1-do.5"
}
variable "node_pool_size" {
  description = "Size of the node pool machines"
  type        = string
  default     = "s-2vcpu-4gb"
}
variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}
