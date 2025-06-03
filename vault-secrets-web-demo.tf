locals {
  vault-secrets-web-demo-deployment = file("${path.module}/manifests/vault-live-secrets-demo/deployment.yaml")
  vault-secrets-web-demo-service = file("${path.module}/manifests/vault-live-secrets-demo/service.yaml")
  vault-secrets-web-demo-route = file("${path.module}/manifests/vault-live-secrets-demo/route.yaml")
  vault-secrets-web-demo-namespace = file("${path.module}/manifests/vault-live-secrets-demo/namespace.yaml")
  vault-secrets-web-demo-vault-connection = file("${path.module}/manifests/vault-live-secrets-demo/vault-connection.yaml")
  vault-secrets-web-demo-vault-auth-sa = file("${path.module}/manifests/vault-live-secrets-demo/vault-auth-sa.yaml")
  vault-secrets-web-demo-vault-auth = file("${path.module}/manifests/vault-live-secrets-demo/vault-auth.yaml")
  vault-secrets-web-demo-vault-static-secret = file("${path.module}/manifests/vault-live-secrets-demo/vault-static-secret.yaml")
}

resource "kubernetes_namespace" "vault-secrets-web-demo" {
  metadata {
    name = "vault-secrets-web-demo"
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
resource "kubernetes_manifest" "vault-secrets-web-demo-vault-connection" {
  depends_on = [kubernetes_namespace.vault-secrets-web-demo]
  manifest = provider::kubernetes::manifest_decode(local.vault-secrets-web-demo-vault-connection)
}

# Vault Auth Service Account
resource "kubernetes_manifest" "vault-secrets-web-demo-vault-auth-sa" {
  depends_on = [kubernetes_namespace.vault-secrets-web-demo]
  manifest = provider::kubernetes::manifest_decode(local.vault-secrets-web-demo-vault-auth-sa)
}

# Vault Auth resource
resource "kubernetes_manifest" "vault-secrets-web-demo-vault-auth" {
  depends_on = [
    kubernetes_manifest.vault-secrets-web-demo-vault-connection,
    kubernetes_manifest.vault-secrets-web-demo-vault-auth-sa
  ]
  manifest = provider::kubernetes::manifest_decode(local.vault-secrets-web-demo-vault-auth)
}

# Vault Static Secret resource
resource "kubernetes_manifest" "vault-secrets-web-demo-vault-static-secret" {
  depends_on = [kubernetes_manifest.vault-secrets-web-demo-vault-auth]
  manifest = provider::kubernetes::manifest_decode(local.vault-secrets-web-demo-vault-static-secret)
}

# Application Deployment
resource "kubernetes_manifest" "vault-secrets-web-demo-deployment" {
  depends_on = [kubernetes_manifest.vault-secrets-web-demo-vault-static-secret]
  manifest = provider::kubernetes::manifest_decode(local.vault-secrets-web-demo-deployment)
  field_manager {
    force_conflicts = true
  }
}

# Service
resource "kubernetes_manifest" "vault-secrets-web-demo-service" {
  depends_on = [kubernetes_manifest.vault-secrets-web-demo-deployment]
  manifest = provider::kubernetes::manifest_decode(local.vault-secrets-web-demo-service)
}

# OpenShift Route
resource "kubernetes_manifest" "vault-secrets-web-demo-route" {
  depends_on = [kubernetes_manifest.vault-secrets-web-demo-service]
  manifest = provider::kubernetes::manifest_decode(local.vault-secrets-web-demo-route)
}
