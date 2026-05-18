locals {
  cloudflared_tfc_eda_namespace  = file("${path.module}/manifests/cloudflared-tfc-eda/namespace.yaml")
  cloudflared_tfc_eda_deployment = file("${path.module}/manifests/cloudflared-tfc-eda/deployment.yaml")
}

resource "kubernetes_manifest" "cloudflared_tfc_eda_namespace" {
  manifest = provider::kubernetes::manifest_decode(local.cloudflared_tfc_eda_namespace)
}

resource "kubernetes_manifest" "cloudflared_tfc_eda_deployment" {
  depends_on = [kubernetes_manifest.cloudflared_tfc_eda_namespace]
  manifest   = provider::kubernetes::manifest_decode(local.cloudflared_tfc_eda_deployment)
  field_manager {
    force_conflicts = true
  }
}
