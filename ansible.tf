locals {
  aap-vault-auth-sa   = file("${path.module}/manifests/ansible/aap-vault-auth-sa.yaml")
  aap-platform        = file("${path.module}/manifests/ansible/aap-platform.yaml")
  aap-pki             = file("${path.module}/manifests/ansible/crd-pki-aapcert.yaml")
  aap-vaultauth       = file("${path.module}/manifests/ansible/crd-vault-auth.yaml")
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

# Lab CA (HCP Vault Issuing -> Central Signing -> Root, verified against Vault's
# live leaf) so the VaultConnection can verify Vault's TLS instead of skipping it.
resource "kubernetes_secret" "aap-vault-ca" {
  metadata {
    name      = "vault-ca"
    namespace = "aap"
  }
  data = {
    "ca.crt" = file("${path.module}/manifests/ansible/vault-ca.pem")
  }
}

resource "kubernetes_manifest" "aap-vaultconnection" {
  depends_on = [kubernetes_secret.aap-vault-ca]
  manifest   = provider::kubernetes::manifest_decode(local.aap-vaultconnection)
}