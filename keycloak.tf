locals {
  keycloak_instance = file("${path.module}/manifests/keycloak/keycloak-instance.yaml")
}

resource "kubernetes_manifest" "instance" {
    manifest = provider::kubernetes::manifest_decode(local.keycloak_instance)
}