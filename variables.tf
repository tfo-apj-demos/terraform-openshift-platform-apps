variable "k8s_api_server" {
    type = string
    description = "The hostname (in form of URI) of the Kubernetes API"
}

variable "client_certificate" {
    type = string
    description = "The client certificate for authenticating to the Kubernetes cluster"
}

variable "client_key" {
    type = string
    description = "The client key for authenticating to the Kubernetes cluster"
    sensitive = true
}

variable "cluster_ca_certificate" {
    type = string
    description = "The CA certificate for authenticating to the Kubernetes cluster"
}

variable "boundary_address" {
  description = "The address of the Boundary server."
  type        = string
}

variable "create_helm_overrides_file" {
  description = "Whether to create the Helm overrides file."
  type        = bool
  default = true
}

variable "tfe_license" {
  description = "The TFE license."
  type        = string
  default = "dummy"
}

variable "tfe_encryption_password" {
  description = "The TFE encryption password."
  type        = string
  sensitive = true
  default = "terraformenterprise"
}