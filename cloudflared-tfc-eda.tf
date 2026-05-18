locals {
  cloudflared_tfc_eda_namespace        = file("${path.module}/manifests/cloudflared-tfc-eda/namespace.yaml")
  cloudflared_tfc_eda_deployment       = file("${path.module}/manifests/cloudflared-tfc-eda/deployment.yaml")
  cloudflared_tfc_eda_np_aap_eda_ingress = file("${path.module}/manifests/cloudflared-tfc-eda/np-aap-eda-ingress.yaml")
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

# Lives in the aap namespace (not cloudflared-tfc-eda) so it scopes to the
# AAP-EDA activation pods. The cloudflared namespace is the only allowed source
# of traffic to TCP/5004 on those pods.
resource "kubernetes_manifest" "cloudflared_tfc_eda_np_aap_eda_ingress" {
  depends_on = [kubernetes_manifest.cloudflared_tfc_eda_namespace]
  manifest   = provider::kubernetes::manifest_decode(local.cloudflared_tfc_eda_np_aap_eda_ingress)
  field_manager {
    force_conflicts = true
  }
}
