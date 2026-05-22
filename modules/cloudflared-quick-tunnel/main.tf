locals {
  namespace_name      = coalesce(var.namespace_name, "cloudflared-${var.name}")
  network_policy_name = coalesce(var.network_policy_name, "${var.name}-from-cloudflared-only")

  # Keep common_labels minimal so callers migrating from hand-rolled YAML don't
  # see a label-induced pod template diff that triggers a Recreate (which
  # rotates the *.trycloudflare.com URL). Add organisational labels via
  # var.labels on greenfield consumers only.
  pod_selector_labels = {
    "app.kubernetes.io/name"      = "cloudflared"
    "app.kubernetes.io/component" = "${var.name}-tunnel"
  }

  common_labels = merge(local.pod_selector_labels, var.labels)
}

resource "kubernetes_manifest" "namespace" {
  manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name   = local.namespace_name
      labels = local.common_labels
    }
  }
}

resource "kubernetes_manifest" "deployment" {
  depends_on = [kubernetes_manifest.namespace]

  field_manager {
    force_conflicts = true
  }

  manifest = {
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = "cloudflared"
      namespace = local.namespace_name
      labels    = local.common_labels
    }
    spec = {
      # Quick tunnels are per-pod (each replica would get its own *.trycloudflare.com URL).
      # replicas=1 keeps the discoverable URL singular.
      replicas = 1
      strategy = { type = "Recreate" }
      selector = { matchLabels = local.pod_selector_labels }
      template = {
        metadata = { labels = merge(local.common_labels, local.pod_selector_labels) }
        spec = {
          containers = [{
            name  = "cloudflared"
            image = var.image
            args = [
              "tunnel",
              "--no-autoupdate",
              "--metrics", "0.0.0.0:${var.metrics_port}",
              "--url", var.target_service_url,
            ]
            resources = {
              requests = var.resources.requests
              limits   = var.resources.limits
            }
            livenessProbe = {
              httpGet             = { path = "/ready", port = var.metrics_port }
              initialDelaySeconds = 10
              periodSeconds       = 30
              failureThreshold    = 3
            }
            readinessProbe = {
              httpGet             = { path = "/ready", port = var.metrics_port }
              initialDelaySeconds = 5
              periodSeconds       = 10
              failureThreshold    = 2
            }
          }]
        }
      }
    }
  }
}

# Restricts target_pod_port on backend pods to ingress from this tunnel's
# namespace only. Closes the in-cluster bypass where any pod could curl the
# Service directly. Stacks additively with NetworkPolicies from sibling tunnels
# — each tunnel owns its own port allowlist.
resource "kubernetes_manifest" "network_policy" {
  depends_on = [kubernetes_manifest.namespace]

  field_manager {
    force_conflicts = true
  }

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = local.network_policy_name
      namespace = var.target_pod_namespace
      labels    = local.common_labels
      annotations = {
        description = "Allow TCP/${var.target_pod_port} on backend pods only from namespace ${local.namespace_name} (the cloudflared tunnel for ${var.name})."
      }
    }
    spec = {
      podSelector = { matchLabels = var.target_pod_selector }
      policyTypes = ["Ingress"]
      ingress = [{
        from = [{
          namespaceSelector = {
            matchLabels = { "kubernetes.io/metadata.name" = local.namespace_name }
          }
        }]
        ports = [{
          protocol = "TCP"
          port     = var.target_pod_port
        }]
      }]
    }
  }
}
