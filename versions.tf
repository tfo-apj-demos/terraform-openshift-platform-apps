terraform {
  # Pin to the workspace's Terraform version line (openshift-platform-apps runs
  # ~> 1.14.0) so a stray local/older CLI can't operate on this state.
  required_version = "~> 1.14.0"

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
