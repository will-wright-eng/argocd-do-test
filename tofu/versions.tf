terraform {
  required_version = "1.9.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.47.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
  }
}
