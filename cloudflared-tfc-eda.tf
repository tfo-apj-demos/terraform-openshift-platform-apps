module "cloudflared_tfc_eda" {
  source = "./modules/cloudflared-quick-tunnel"

  name = "tfc-eda"
  # Preserves the existing NetworkPolicy name from before this was modularised
  # so the cutover doesn't open a brief default-allow window during the rename.
  network_policy_name = "aap-eda-activation-from-cloudflared-only"

  target_service_url   = "http://tfc-notification-drift.aap.svc.cluster.local:5004"
  target_pod_namespace = "aap"
  target_pod_selector  = { app = "eda" }
  target_pod_port      = 5004
}

# Migrate state for resources that already exist under the old flat addresses.
# kubernetes_manifest preserves the underlying object if the manifest content
# is unchanged; minor label drift will be reconciled in-place by the apply.
moved {
  from = kubernetes_manifest.cloudflared_tfc_eda_namespace
  to   = module.cloudflared_tfc_eda.kubernetes_manifest.namespace
}

moved {
  from = kubernetes_manifest.cloudflared_tfc_eda_deployment
  to   = module.cloudflared_tfc_eda.kubernetes_manifest.deployment
}

moved {
  from = kubernetes_manifest.cloudflared_tfc_eda_np_aap_eda_ingress
  to   = module.cloudflared_tfc_eda.kubernetes_manifest.network_policy
}
