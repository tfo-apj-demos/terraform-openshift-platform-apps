output "namespace" {
  description = "Namespace the cloudflared Deployment runs in."
  value       = local.namespace_name
}

output "deployment_name" {
  description = "Name of the cloudflared Deployment."
  value       = "cloudflared"
}

output "network_policy_name" {
  description = "Name of the NetworkPolicy created in the backend namespace."
  value       = local.network_policy_name
}

output "discover_url_command" {
  description = "Shell command to print the *.trycloudflare.com URL cloudflared advertised."
  value       = "oc -n ${local.namespace_name} logs deploy/cloudflared | grep -o 'https://[a-z0-9-]\\+\\.trycloudflare\\.com' | head -1"
}
