module "cloudflared_snow_eda" {
  source = "./modules/cloudflared-quick-tunnel"

  name = "snow-eda"

  target_service_url   = "http://snow-cr-approval.aap.svc.cluster.local:5005"
  target_pod_namespace = "aap"
  target_pod_selector  = { app = "eda" }
  target_pod_port      = 5005

  labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "snow-eda-tunnel"
  }
}

# Surfaces the *.trycloudflare.com URL once the pod is up. ServiceNow's
# Outbound REST Message "AAP EDA - CR approval" (sys_id
# 20cbe2f8938583105e8930018bba103b) endpoint must be PATCHed to this value
# after each cloudflared pod restart. Documented in the drift-remediation
# workflow doc.
output "cloudflared_snow_eda_url_command" {
  description = "Discover the public URL after apply with: $(this output)."
  value       = module.cloudflared_snow_eda.discover_url_command
}

output "cloudflared_tfc_eda_url_command" {
  description = "Discover the public URL after apply with: $(this output)."
  value       = module.cloudflared_tfc_eda.discover_url_command
}
