terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }

    boundary = {
      source  = "hashicorp/boundary"
      version = "~> 1"
    }
  }
}
