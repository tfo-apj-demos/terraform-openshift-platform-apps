import {
  to = helm_release.tfe
  id = "tfe/terraform-enterprise"
}

locals {
  tfe_route       = file("${path.module}/manifests/tfe/tfe-route.yaml")
  hcp_tf_operator = file("${path.module}/manifests/tfe/hcp-tf-operator.yaml")
}


# deploy tfe using helm chart
resource "helm_release" "tfe" {
  name             = "terraform-enterprise"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "terraform-enterprise"
  version          = "1.3.2"
  create_namespace = false
  namespace        = "tfe"
  wait             = false
  force_update     = true

  values = [
    local.tfe_helm_values
  ]

}

# Openshift Route for TFE
resource "kubernetes_manifest" "tfe_route" {
  manifest = provider::kubernetes::manifest_decode(local.tfe_route)
}


# deploy hcp-tf-operator crd  
resource "kubernetes_manifest" "tfe_operator" {
  manifest = provider::kubernetes::manifest_decode(local.hcp_tf_operator)
  field_manager {
    force_conflicts = true
  }
}