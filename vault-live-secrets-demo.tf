locals {
  vault-live-secrets-demo-deployment = file("${path.module}/manifests/vault-live-secrets-demo/deployment.yaml")
  vault-live-secrets-demo-service = file("${path.module}/manifests/vault-live-secrets-demo/service.yaml")
  vault-live-secrets-demo-route = file("${path.module}/manifests/vault-live-secrets-demo/route.yaml")
  vault-live-secrets-demo-namespace = file("${path.module}/manifests/vault-live-secrets-demo/namespace.yaml")
  vault-live-secrets-demo-vault-connection = file("${path.module}/manifests/vault-live-secrets-demo/vault-connection.yaml")
  vault-live-secrets-demo-vault-auth-sa = file("${path.module}/manifests/vault-live-secrets-demo/vault-auth-sa.yaml")
  vault-live-secrets-demo-vault-auth-crb = file("${path.module}/manifests/vault-live-secrets-demo/vault-auth-clusterrolebinding.yaml")
  vault-live-secrets-demo-vault-auth = file("${path.module}/manifests/vault-live-secrets-demo/vault-auth.yaml")
  vault-live-secrets-demo-vault-static-secret = file("${path.module}/manifests/vault-live-secrets-demo/vault-static-secret.yaml")
}

resource "kubernetes_namespace" "vault-live-secrets-demo" {
  metadata {
    name = "vault-live-secrets-demo"
  }
  
  lifecycle {
    ignore_changes = [
      metadata.0.annotations["openshift.io/sa.scc.mcs"],
      metadata.0.annotations["openshift.io/sa.scc.supplemental-groups"],
      metadata.0.annotations["openshift.io/sa.scc.uid-range"]
    ]
  }
}

# Vault Connection resource
resource "kubernetes_manifest" "vault-live-secrets-demo-vault-connection" {
  depends_on = [kubernetes_namespace.vault-live-secrets-demo]
  manifest = provider::kubernetes::manifest_decode(local.vault-live-secrets-demo-vault-connection)
}

# Vault Auth Service Account
resource "kubernetes_manifest" "vault-live-secrets-demo-vault-auth-sa" {
  depends_on = [kubernetes_namespace.vault-live-secrets-demo]
  manifest = provider::kubernetes::manifest_decode(local.vault-live-secrets-demo-vault-auth-sa)
}

# Vault Auth ClusterRoleBinding
resource "kubernetes_manifest" "vault-live-secrets-demo-vault-auth-crb" {
  depends_on = [kubernetes_manifest.vault-live-secrets-demo-vault-auth-sa]
  manifest = provider::kubernetes::manifest_decode(local.vault-live-secrets-demo-vault-auth-crb)
}

# Vault Auth resource
resource "kubernetes_manifest" "vault-live-secrets-demo-vault-auth" {
  depends_on = [
    kubernetes_manifest.vault-live-secrets-demo-vault-connection,
    kubernetes_manifest.vault-live-secrets-demo-vault-auth-crb
  ]
  manifest = provider::kubernetes::manifest_decode(local.vault-live-secrets-demo-vault-auth)
}

# Vault Static Secret resource
resource "kubernetes_manifest" "vault-live-secrets-demo-vault-static-secret" {
  depends_on = [kubernetes_manifest.vault-live-secrets-demo-vault-auth]
  manifest = provider::kubernetes::manifest_decode(local.vault-live-secrets-demo-vault-static-secret)
}

# Application Deployment
resource "kubernetes_manifest" "vault-live-secrets-demo-deployment" {
  depends_on = [kubernetes_manifest.vault-live-secrets-demo-vault-static-secret]
  manifest = provider::kubernetes::manifest_decode(local.vault-live-secrets-demo-deployment)
  field_manager {
    force_conflicts = true
  }
}

# Service
resource "kubernetes_manifest" "vault-live-secrets-demo-service" {
  depends_on = [kubernetes_manifest.vault-live-secrets-demo-deployment]
  manifest = provider::kubernetes::manifest_decode(local.vault-live-secrets-demo-service)
}

# OpenShift Route
resource "kubernetes_manifest" "vault-live-secrets-demo-route" {
  depends_on = [kubernetes_manifest.vault-live-secrets-demo-service]
  manifest = provider::kubernetes::manifest_decode(local.vault-live-secrets-demo-route)
}
