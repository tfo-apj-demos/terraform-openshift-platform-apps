locals {
  db2_instance = file("${path.module}/manifests/ibm-db2/db2-instance.yaml")
}

resource "kubernetes_manifest" "instance" {
    manifest = provider::kubernetes::manifest_decode(local.db2_instance)
}