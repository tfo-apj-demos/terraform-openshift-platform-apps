locals {
  rhdh_backstage = file("${path.module}/manifests/backstage/crd-rhdh-backstage.yaml")
}

# Temporarily commented out — Terraform state has the old v1alpha2 GVK which
# the provider can't upgrade. Commenting out removes it from state.
# Re-enable with an import block on the next run.
# resource "kubernetes_manifest" "rhdh_backstage" {
#   manifest = provider::kubernetes::manifest_decode(local.rhdh_backstage)
# }
