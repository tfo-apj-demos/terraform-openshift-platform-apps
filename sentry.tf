# Sentry - Self-hosted Error Tracking Platform
# Deployed via Helm chart with external PostgreSQL (Crunchy) and S3 storage (Ceph RGW)
# Reference: https://github.com/sentry-kubernetes/charts

locals {
  sentry_route            = file("${path.module}/manifests/sentry/sentry-route.yaml")
  sentry_postgres_cluster = file("${path.module}/manifests/sentry/postgres-cluster.yaml")

  sentry_helm_values = templatefile("${path.module}/templates/sentry_helm_values.yaml.tpl", {
    hostname          = "sentry.apps.openshift-01.hashicorp.local"
    storage_class     = "ocs-storagecluster-cephfs"
    secret_key        = var.sentry_secret_key
    admin_email       = var.sentry_admin_email
    admin_password    = var.sentry_admin_password
    postgres_host     = "sentrydb-primary.sentry.svc"
    postgres_port     = 5432
    postgres_username = data.kubernetes_secret.sentry_postgres.data.user
    postgres_password = data.kubernetes_secret.sentry_postgres.data.password
    postgres_database = data.kubernetes_secret.sentry_postgres.data.dbname
    redis_password    = var.sentry_redis_password
    s3_endpoint       = "http://rook-ceph-rgw-ocs-storagecluster-cephobjectstore.openshift-storage.svc"
    s3_bucket         = data.kubernetes_resource.sentry_s3.object.spec.bucketName
    s3_access_key     = data.kubernetes_secret.sentry_s3.data.AWS_ACCESS_KEY_ID
    s3_secret_key     = data.kubernetes_secret.sentry_s3.data.AWS_SECRET_ACCESS_KEY
    mail_host         = var.sentry_mail_host
    mail_port         = var.sentry_mail_port
    mail_username     = var.sentry_mail_username
    mail_password     = var.sentry_mail_password
  })
}

# Namespace
resource "kubernetes_namespace" "sentry" {
  metadata {
    name = "sentry"
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

# PostgresCluster CRD for Sentry database
resource "kubernetes_manifest" "sentry_postgres_cluster" {
  depends_on = [kubernetes_namespace.sentry]
  manifest   = provider::kubernetes::manifest_decode(local.sentry_postgres_cluster)

  field_manager {
    force_conflicts = true
  }
}

# Data source for PostgreSQL credentials (created by Crunchy Postgres Operator)
data "kubernetes_secret" "sentry_postgres" {
  depends_on = [kubernetes_manifest.sentry_postgres_cluster]
  metadata {
    name      = "sentrydb-pguser-sentry"
    namespace = "sentry"
  }
}

# S3 ObjectBucketClaim for Sentry blob storage
resource "kubernetes_manifest" "sentry_s3_bucket" {
  depends_on = [kubernetes_namespace.sentry]
  manifest = {
    apiVersion = "objectbucket.io/v1alpha1"
    kind       = "ObjectBucketClaim"
    metadata = {
      name      = "sentry"
      namespace = "sentry"
    }
    spec = {
      generateBucketName = "sentry"
      storageClassName   = "ocs-storagecluster-ceph-rgw"
    }
  }
}

# Data source for S3 credentials (created by ObjectBucketClaim)
data "kubernetes_secret" "sentry_s3" {
  depends_on = [kubernetes_manifest.sentry_s3_bucket]
  metadata {
    name      = "sentry"
    namespace = "sentry"
  }
}

# Data source for S3 bucket info
data "kubernetes_resource" "sentry_s3" {
  depends_on  = [kubernetes_manifest.sentry_s3_bucket]
  api_version = "objectbucket.io/v1alpha1"
  kind        = "ObjectBucketClaim"
  metadata {
    name      = "sentry"
    namespace = "sentry"
  }
}

# Secrets for Sentry application
resource "kubernetes_secret" "sentry_secrets" {
  depends_on = [kubernetes_namespace.sentry]
  metadata {
    name      = "sentry-secrets"
    namespace = "sentry"
  }

  data = {
    SENTRY_SECRET_KEY = var.sentry_secret_key
  }
}

# Helm release for Sentry
resource "helm_release" "sentry" {
  depends_on = [
    kubernetes_namespace.sentry,
    kubernetes_manifest.sentry_postgres_cluster,
    kubernetes_manifest.sentry_s3_bucket,
    kubernetes_secret.sentry_secrets,
    data.kubernetes_secret.sentry_postgres,
    data.kubernetes_secret.sentry_s3,
    data.kubernetes_resource.sentry_s3
  ]

  name             = "sentry"
  repository       = "https://sentry-kubernetes.github.io/charts"
  chart            = "sentry"
  namespace        = "sentry"
  create_namespace = false
  wait             = false
  force_update     = true
  timeout          = 1200 # Sentry takes longer to deploy

  values = [local.sentry_helm_values]
}

# OpenShift Route for external access
resource "kubernetes_manifest" "sentry_route" {
  depends_on = [helm_release.sentry]
  manifest   = provider::kubernetes::manifest_decode(local.sentry_route)
}

# Optional: Vault integration resources (for future use)
# Uncomment these when ready to integrate with Vault Secrets Operator

# resource "kubernetes_manifest" "sentry_vault_auth_sa" {
#   depends_on = [kubernetes_namespace.sentry]
#   manifest   = provider::kubernetes::manifest_decode(local.sentry_vault_auth_sa)
# }

# resource "kubernetes_manifest" "sentry_vault_connection" {
#   depends_on = [kubernetes_namespace.sentry]
#   manifest   = provider::kubernetes::manifest_decode(local.sentry_vault_connection)
# }

# resource "kubernetes_manifest" "sentry_vault_auth" {
#   depends_on = [kubernetes_manifest.sentry_vault_connection]
#   manifest   = provider::kubernetes::manifest_decode(local.sentry_vault_auth)
# }
