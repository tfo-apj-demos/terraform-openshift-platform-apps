variable "name" {
  description = "Short identifier for the tunnel — used in namespace, deployment, and NetworkPolicy names. Example: \"snow-eda\", \"tfc-eda\"."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}[a-z0-9]$", var.name))
    error_message = "name must be a DNS-1123 label (lowercase alphanumeric and dashes, 3-42 chars)."
  }
}

variable "target_service_url" {
  description = "The in-cluster URL cloudflared proxies traffic to. Example: \"http://snow-cr-approval.aap.svc.cluster.local:5005\"."
  type        = string
}

variable "target_pod_namespace" {
  description = "Namespace of the backend pods (used by the NetworkPolicy)."
  type        = string
}

variable "target_pod_selector" {
  description = "Label selector identifying backend pods to grant ingress to. Example: {app = \"eda\"}."
  type        = map(string)
}

variable "target_pod_port" {
  description = "TCP port on the backend pods that cloudflared connects to."
  type        = number
}

variable "image" {
  description = "Container image used to run cloudflared."
  type        = string
  default     = "cloudflare/cloudflared:latest"
}

variable "metrics_port" {
  description = "Port cloudflared binds its metrics/probe server to. Used by liveness/readiness probes hitting /ready."
  type        = number
  default     = 2000
}

variable "resources" {
  description = "Pod resource requests/limits for the cloudflared container."
  type = object({
    requests = optional(object({ cpu = string, memory = string }), { cpu = "50m", memory = "64Mi" })
    limits   = optional(object({ cpu = string, memory = string }), { cpu = "200m", memory = "256Mi" })
  })
  default = {}
}

variable "namespace_name" {
  description = "Kubernetes namespace cloudflared runs in. Defaults to \"cloudflared-<name>\"."
  type        = string
  default     = null
}

variable "network_policy_name" {
  description = "Name of the NetworkPolicy created in target_pod_namespace. Defaults to \"<name>-from-cloudflared-only\"."
  type        = string
  default     = null
}

variable "labels" {
  description = "Extra labels merged into all resources this module creates."
  type        = map(string)
  default     = {}
}
