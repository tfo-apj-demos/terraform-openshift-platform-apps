variable "host" {
  type        = string
  description = "The hostname (in form of URI) of the Kubernetes API"
}

variable "client_certificate" {
  type        = string
  description = "The client certificate for authenticating to the Kubernetes cluster"
}

variable "client_key" {
  type        = string
  description = "The client key for authenticating to the Kubernetes cluster"
  sensitive   = true
}

variable "cluster_ca_certificate" {
  type        = string
  description = "The CA certificate for authenticating to the Kubernetes cluster"
}

variable "boundary_address" {
  description = "The address of the Boundary server."
  type        = string
}

variable "create_helm_overrides_file" {
  description = "Whether to create the Helm overrides file."
  type        = bool
  default     = true
}

variable "tfe_license" {
  description = "The TFE license."
  type        = string
  default     = "dummy"
}

variable "tfe_encryption_password" {
  description = "The TFE encryption password."
  type        = string
  sensitive   = true
  default     = "terraformenterprise"
}

variable "awx_admin_password" {
  description = "The AWX admin password."
  type        = string
  sensitive   = true
}

variable "gitlab_runner_token" {
  description = "The GitLab project runner token used to authenticate the runner with GitLab."
  type        = string
  sensitive   = true
}

# Langfuse Configuration
variable "langfuse_nextauth_secret" {
  description = "NextAuth secret for Langfuse session encryption. Generate with: openssl rand -hex 32"
  type        = string
  sensitive   = true
}

variable "langfuse_salt" {
  description = "Salt for Langfuse password hashing. Generate with: openssl rand -hex 32"
  type        = string
  sensitive   = true
}

variable "langfuse_encryption_key" {
  description = "Encryption key for Langfuse data encryption. Generate with: openssl rand -hex 32"
  type        = string
  sensitive   = true
  default     = ""
}

variable "langfuse_postgres_password" {
  description = "Password for the bundled PostgreSQL database. Generate with: openssl rand -base64 24"
  type        = string
  sensitive   = true
}

variable "langfuse_clickhouse_password" {
  description = "Password for the bundled ClickHouse database. Generate with: openssl rand -base64 24"
  type        = string
  sensitive   = true
}

variable "langfuse_redis_password" {
  description = "Password for the bundled Redis cache. Generate with: openssl rand -base64 24"
  type        = string
  sensitive   = true
}

# Sentry Configuration
variable "sentry_secret_key" {
  description = "Secret key for Sentry encryption. Generate with: openssl rand -hex 32"
  type        = string
  sensitive   = true
}

variable "sentry_admin_email" {
  description = "Email address for the Sentry admin user"
  type        = string
  default     = "admin@example.com"
}

variable "sentry_admin_password" {
  description = "Password for the Sentry admin user. Generate with: openssl rand -base64 24"
  type        = string
  sensitive   = true
}

variable "sentry_redis_password" {
  description = "Password for the bundled Redis cache. Generate with: openssl rand -base64 24"
  type        = string
  sensitive   = true
}

variable "sentry_clickhouse_password" {
  description = "Password for the bundled ClickHouse database. Generate with: openssl rand -base64 24"
  type        = string
  sensitive   = true
}

variable "sentry_kafka_password" {
  description = "Password for the bundled Kafka. Generate with: openssl rand -base64 24"
  type        = string
  sensitive   = true
}

variable "sentry_mail_host" {
  description = "SMTP mail server host for Sentry notifications"
  type        = string
  default     = ""
}

variable "sentry_mail_port" {
  description = "SMTP mail server port"
  type        = number
  default     = 587
}

variable "sentry_mail_username" {
  description = "SMTP mail server username"
  type        = string
  default     = ""
}

variable "sentry_mail_password" {
  description = "SMTP mail server password"
  type        = string
  sensitive   = true
  default     = ""
}