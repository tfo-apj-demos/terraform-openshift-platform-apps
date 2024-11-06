locals {
  aap-vault-auth-sa = file("${path.module}/manifests/ansible/aap-vault-auth-sa.yaml")
  aap-platform = file("${path.module}/manifests/ansible/aap-platform.yaml")
  aap-pki = file("${path.module}/manifests/ansible/crd-pki-aapcert.yaml")
  aap-vaultauth = file("${path.module}/manifests/ansible/crd-vault-auth.yaml")
  aap-vaultconnection = file("${path.module}/manifests/ansible/crd-vault-connection.yaml")
}


# Ansible Automation Platform resource
resource "kubernetes_manifest" "aap-controller" {
  manifest = provider::kubernetes::manifest_decode(local.aap-platform)
  field_manager {
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "aap-sa" {
  manifest = provider::kubernetes::manifest_decode(local.aap-vault-auth-sa)
}



resource "kubernetes_manifest" "aap-pki" {
  manifest = provider::kubernetes::manifest_decode(local.aap-pki)
}

resource "kubernetes_manifest" "aap-vaultauth" {
  manifest = provider::kubernetes::manifest_decode(local.aap-vaultauth)
}

resource "kubernetes_manifest" "aap-vaultconnection" {
  manifest = provider::kubernetes::manifest_decode(local.aap-vaultconnection)
}