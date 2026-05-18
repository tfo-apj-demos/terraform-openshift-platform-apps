locals {
  cloudflared_tfc_eda_namespace             = file("${path.module}/manifests/cloudflared-tfc-eda/namespace.yaml")
  cloudflared_tfc_eda_serviceaccount        = file("${path.module}/manifests/cloudflared-tfc-eda/serviceaccount.yaml")
  cloudflared_tfc_eda_vault_connection      = file("${path.module}/manifests/cloudflared-tfc-eda/crd-vault-connection.yaml")
  cloudflared_tfc_eda_vault_auth            = file("${path.module}/manifests/cloudflared-tfc-eda/crd-vault-auth.yaml")
  cloudflared_tfc_eda_vault_static_secret   = file("${path.module}/manifests/cloudflared-tfc-eda/crd-vault-static-secret.yaml")
  cloudflared_tfc_eda_deployment            = file("${path.module}/manifests/cloudflared-tfc-eda/deployment.yaml")
}

resource "kubernetes_manifest" "cloudflared_tfc_eda_namespace" {
  manifest = provider::kubernetes::manifest_decode(local.cloudflared_tfc_eda_namespace)
}

resource "kubernetes_manifest" "cloudflared_tfc_eda_serviceaccount" {
  depends_on = [kubernetes_manifest.cloudflared_tfc_eda_namespace]
  manifest   = provider::kubernetes::manifest_decode(local.cloudflared_tfc_eda_serviceaccount)
}

resource "kubernetes_manifest" "cloudflared_tfc_eda_vault_connection" {
  depends_on = [kubernetes_manifest.cloudflared_tfc_eda_namespace]
  manifest   = provider::kubernetes::manifest_decode(local.cloudflared_tfc_eda_vault_connection)
}

resource "kubernetes_manifest" "cloudflared_tfc_eda_vault_auth" {
  depends_on = [kubernetes_manifest.cloudflared_tfc_eda_vault_connection]
  manifest   = provider::kubernetes::manifest_decode(local.cloudflared_tfc_eda_vault_auth)
}

resource "kubernetes_manifest" "cloudflared_tfc_eda_vault_static_secret" {
  depends_on = [kubernetes_manifest.cloudflared_tfc_eda_vault_auth]
  manifest   = provider::kubernetes::manifest_decode(local.cloudflared_tfc_eda_vault_static_secret)
}

resource "kubernetes_manifest" "cloudflared_tfc_eda_deployment" {
  depends_on = [kubernetes_manifest.cloudflared_tfc_eda_vault_static_secret]
  manifest   = provider::kubernetes::manifest_decode(local.cloudflared_tfc_eda_deployment)
  field_manager {
    force_conflicts = true
  }
}
