locals {
  mtv_forklift_controller = file("${path.module}/manifests/mtv/forklift-controller.yaml")
}

resource "kubernetes_manifest" "forklift_controller" {
  manifest = provider::kubernetes::manifest_decode(local.mtv_forklift_controller)
}
