locals {
  cnv_hyperconverged = file("${path.module}/manifests/cnv/hyperconverged.yaml")
}

resource "kubernetes_manifest" "hyperconverged" {
  manifest = provider::kubernetes::manifest_decode(local.cnv_hyperconverged)
}
