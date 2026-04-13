locals {
  keycloak_instance        = file("${path.module}/manifests/keycloak/keycloak-instance.yaml")
  keycloak_vault_auth_sa   = file("${path.module}/manifests/keycloak/vault-auth-sa.yaml")
  keycloak_vaultconnection = file("${path.module}/manifests/keycloak/crd-vault-connection.yaml")
  keycloak_vaultauth       = file("${path.module}/manifests/keycloak/crd-vault-auth.yaml")
  keycloak_pki             = file("${path.module}/manifests/keycloak/crd-pki-keycloakcert.yaml")
}

resource "kubernetes_manifest" "keycloak" {
  manifest = provider::kubernetes::manifest_decode(local.keycloak_instance)
}

resource "kubernetes_manifest" "keycloak_vault_auth_sa" {
  manifest = provider::kubernetes::manifest_decode(local.keycloak_vault_auth_sa)
}

resource "kubernetes_manifest" "keycloak_vaultconnection" {
  manifest = provider::kubernetes::manifest_decode(local.keycloak_vaultconnection)
}

resource "kubernetes_manifest" "keycloak_vaultauth" {
  manifest = provider::kubernetes::manifest_decode(local.keycloak_vaultauth)
}

resource "kubernetes_manifest" "keycloak_pki" {
  manifest = provider::kubernetes::manifest_decode(local.keycloak_pki)
}
