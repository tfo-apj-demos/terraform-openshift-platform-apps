locals {
  rhdh_backstage = file("${path.module}/manifests/backstage/crd-rhdh-backstage.yaml")

}



resource "kubernetes_manifest" "rhdh_operator_group" {
  manifest = provider::kubernetes::manifest_decode(local.rhdh_backstage)
}

