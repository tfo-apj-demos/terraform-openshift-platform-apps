# Langfuse - LLM Observability Platform
# Deployed via Helm chart with external S3 storage (Ceph RGW)

locals {
  langfuse_route            = file("${path.module}/manifests/langfuse/langfuse-route.yaml")
  langfuse_vault_connection = file("${path.module}/manifests/langfuse/vault-connection.yaml")
  langfuse_vault_auth       = file("${path.module}/manifests/langfuse/vault-auth.yaml")
  langfuse_vault_auth_sa    = file("${path.module}/manifests/langfuse/vault-auth-sa.yaml")
  langfuse_pki_cert         = file("${path.module}/manifests/langfuse/crd-pki-langfusecert.yaml")

  langfuse_helm_values = templatefile("${path.module}/templates/langfuse_helm_values.yaml.tpl", {
    hostname            = "langfuse.apps.openshift-01.hashicorp.local"
    storage_class       = "ocs-storagecluster-cephfs"
    s3_endpoint         = "http://rook-ceph-rgw-ocs-storagecluster-cephobjectstore.openshift-storage.svc"
    s3_bucket           = data.kubernetes_resource.langfuse_s3.object.spec.bucketName
    s3_access_key       = data.kubernetes_secret.langfuse_s3.data.AWS_ACCESS_KEY_ID
    postgres_password   = var.langfuse_postgres_password
    clickhouse_password = var.langfuse_clickhouse_password
    redis_password      = var.langfuse_redis_password
  })
}

# Namespace
resource "kubernetes_namespace" "langfuse" {
  metadata {
    name = "langfuse"
  }

  lifecycle {
    ignore_changes = [
      metadata.0.annotations["openshift.io/sa.scc.mcs"],
      metadata.0.annotations["openshift.io/sa.scc.supplemental-groups"],
      metadata.0.annotations["openshift.io/sa.scc.uid-range"],
      metadata.0.labels

    ]
  }
}

# S3 Bucket Claim for Langfuse blob storage
resource "kubernetes_manifest" "langfuse_s3_bucket" {
  depends_on = [kubernetes_namespace.langfuse]
  manifest = {
    apiVersion = "objectbucket.io/v1alpha1"
    kind       = "ObjectBucketClaim"
    metadata = {
      name      = "langfuse"
      namespace = "langfuse"
    }
    spec = {
      generateBucketName = "langfuse"
      storageClassName   = "ocs-storagecluster-ceph-rgw"
    }
  }
}

# Data source for S3 credentials (created by ObjectBucketClaim)
data "kubernetes_secret" "langfuse_s3" {
  depends_on = [kubernetes_manifest.langfuse_s3_bucket]
  metadata {
    name      = "langfuse"
    namespace = "langfuse"
  }
}

# Data source for S3 bucket info
data "kubernetes_resource" "langfuse_s3" {
  depends_on  = [kubernetes_manifest.langfuse_s3_bucket]
  api_version = "objectbucket.io/v1alpha1"
  kind        = "ObjectBucketClaim"
  metadata {
    name      = "langfuse"
    namespace = "langfuse"
  }
}

# Secrets for Langfuse application
resource "kubernetes_secret" "langfuse_secrets" {
  depends_on = [kubernetes_namespace.langfuse]
  metadata {
    name      = "langfuse-secrets"
    namespace = "langfuse"
  }

  data = {
    NEXTAUTH_SECRET         = var.langfuse_nextauth_secret
    SALT                    = var.langfuse_salt
    LANGFUSE_ENCRYPTION_KEY = var.langfuse_encryption_key
  }
}

# Helm release for Langfuse
resource "helm_release" "langfuse" {
  depends_on = [
    kubernetes_namespace.langfuse,
    kubernetes_secret.langfuse_secrets,
    kubernetes_manifest.langfuse_s3_bucket,
    data.kubernetes_secret.langfuse_s3,
    data.kubernetes_resource.langfuse_s3
  ]

  name             = "langfuse"
  repository       = "https://langfuse.github.io/langfuse-k8s"
  chart            = "langfuse"
  namespace        = "langfuse"
  create_namespace = false
  wait             = false
  force_update     = true
  timeout          = 600

  values = [local.langfuse_helm_values]
}

# OpenShift Route for external access
resource "kubernetes_manifest" "langfuse_route" {
  depends_on = [helm_release.langfuse]
  manifest   = provider::kubernetes::manifest_decode(local.langfuse_route)
}

# Vault integration resources (for future use)
# Uncomment these when ready to integrate with Vault Secrets Operator

# resource "kubernetes_manifest" "langfuse_vault_auth_sa" {
#   depends_on = [kubernetes_namespace.langfuse]
#   manifest   = provider::kubernetes::manifest_decode(local.langfuse_vault_auth_sa)
# }

# resource "kubernetes_manifest" "langfuse_vault_connection" {
#   depends_on = [kubernetes_namespace.langfuse]
#   manifest   = provider::kubernetes::manifest_decode(local.langfuse_vault_connection)
# }

# resource "kubernetes_manifest" "langfuse_vault_auth" {
#   depends_on = [kubernetes_manifest.langfuse_vault_connection]
#   manifest   = provider::kubernetes::manifest_decode(local.langfuse_vault_auth)
# }

# resource "kubernetes_manifest" "langfuse_pki_cert" {
#   depends_on = [kubernetes_manifest.langfuse_vault_auth]
#   manifest   = provider::kubernetes::manifest_decode(local.langfuse_pki_cert)
# }
