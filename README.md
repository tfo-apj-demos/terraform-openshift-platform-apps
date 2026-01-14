# terraform-openshift-platform-apps

Deploys and configures **application instances** on OpenShift. This repository creates the actual running applications using the operators installed by [terraform-openshift-config](https://github.com/tfo-apj-demos/terraform-openshift-config).

## Relationship with terraform-openshift-config

This repo works in conjunction with `terraform-openshift-config`:

| config Repo | This Repo (platform-apps) |
|-------------|---------------------------|
| Installs operators via OLM subscriptions | Deploys application instances (CRDs, Helm releases) |
| Creates namespaces | Configures application-specific settings |
| Sets up OperatorGroups | Creates routes, secrets, and integrations |
| Establishes RBAC foundations | Deploys Vault Secrets Operator integrations |

**Deployment Order:** Run `terraform-openshift-config` first, then run this repo.

## What This Repo Deploys

| Application | Resources Created |
|-------------|-------------------|
| **Terraform Enterprise** | Helm release, TFE secrets, OpenShift route, HCP TF Operator CRD |
| **Ansible Automation Platform** | AnsibleAutomationPlatform CRD instance, Vault auth integration, PKI certificate |
| **AWX** | AWX CRD instance, admin password secret, Vault auth SA, ClusterRoleBinding |
| **GitLab** | GitLab CRD instance, OpenShift route |
| **GitLab Runner** | Runner CRD instance with registration token |
| **Red Hat Developer Hub** | Backstage CRD instance |
| **IBM DB2** | Db2uCluster CRD instance |
| **Keycloak** | Keycloak CRD instance |
| **Langfuse** | Helm release (PostgreSQL, ClickHouse, Redis), S3 bucket claim, OpenShift route |
| **Vault Live Secrets Demo** | Full application stack (Deployment, Service, Route, Vault integration) |

## Deployment Patterns Used

### Pattern 1: Helm Chart Deployment
Used for applications with official Helm charts (e.g., TFE):
```hcl
resource "helm_release" "app" {
  name       = "app-name"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "chart-name"
  namespace  = "app-namespace"
  values     = [local.helm_values]
}
```

### Pattern 2: CRD Instance Deployment
Used for operator-managed applications (e.g., AAP, AWX, GitLab):
```hcl
resource "kubernetes_manifest" "app_instance" {
  manifest = provider::kubernetes::manifest_decode(local.app_crd)
}
```

### Pattern 3: Full Manifest Stack
Used for custom applications requiring multiple resources (e.g., vault-live-secrets-demo):
- Namespace → ServiceAccount → RBAC → VaultConnection → VaultAuth → Deployment → Service → Route

## Providers

- `kubernetes` - For deploying CRD instances and manifests
- `helm` - For deploying application Helm charts
- `boundary` - For registering services with HashiCorp Boundary

## Usage

```hcl
module "openshift_platform_apps" {
  source = "app.terraform.io/tfo-apj-demos/openshift-platform-apps/openshift"
  
  host                   = var.openshift_api_url
  client_certificate     = var.client_certificate
  client_key             = var.client_key
  cluster_ca_certificate = var.cluster_ca_certificate
  
  tfe_license             = var.tfe_license
  tfe_encryption_password = var.tfe_encryption_password
  awx_admin_password      = var.awx_admin_password
  gitlab_runner_token     = var.gitlab_runner_token
  
  # Langfuse secrets (generate with: openssl rand -hex 32)
  langfuse_nextauth_secret = var.langfuse_nextauth_secret
  langfuse_salt            = var.langfuse_salt
  langfuse_encryption_key  = var.langfuse_encryption_key
}
```
