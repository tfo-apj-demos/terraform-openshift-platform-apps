# Langfuse Implementation Tasks

## Task Checklist

### Phase 1: Preparation
- [ ] **Task 1.1:** Add Langfuse Helm repository locally and review default values.yaml
- [ ] **Task 1.2:** Review OpenShift SCC requirements for ClickHouse and ZooKeeper
- [ ] **Task 1.3:** Create S3 ObjectBucketClaim for Langfuse blob storage
- [ ] **Task 1.4:** Generate and store secrets in Vault (NEXTAUTH_SECRET, SALT, ENCRYPTION_KEY)

### Phase 2: Terraform - Config Repo (Optional)
- [ ] **Task 2.1:** Create `langfuse.tf` with namespace creation (if separating from platform-apps)
- [ ] **Task 2.2:** Create any required SCCs in `manifests/langfuse/` directory

### Phase 3: Terraform - Platform Apps Repo
- [ ] **Task 3.1:** Create `langfuse.tf` with Helm release and locals
- [ ] **Task 3.2:** Create `templates/langfuse_helm_values.yaml.tpl` template
- [ ] **Task 3.3:** Create `manifests/langfuse/` directory structure
- [ ] **Task 3.4:** Create `manifests/langfuse/langfuse-route.yaml` for OpenShift route
- [ ] **Task 3.5:** Create `manifests/langfuse/vault-connection.yaml` for Vault integration
- [ ] **Task 3.6:** Create `manifests/langfuse/vault-auth.yaml` for Vault auth
- [ ] **Task 3.7:** Create `manifests/langfuse/vault-auth-sa.yaml` for service account
- [ ] **Task 3.8:** Create `manifests/langfuse/crd-pki-langfusecert.yaml` for TLS certificate
- [ ] **Task 3.9:** Update `variables.tf` with Langfuse-specific variables

### Phase 4: Testing
- [ ] **Task 4.1:** Run `terraform plan` and review changes
- [ ] **Task 4.2:** Run `terraform apply` and monitor pod startup
- [ ] **Task 4.3:** Verify all pods reach Running state
- [ ] **Task 4.4:** Test web UI access via route
- [ ] **Task 4.5:** Create test user and organization
- [ ] **Task 4.6:** Test trace ingestion with SDK

### Phase 5: Documentation
- [ ] **Task 5.1:** Update README.md with Langfuse deployment info
- [ ] **Task 5.2:** Document any OpenShift-specific configurations
- [ ] **Task 5.3:** Create runbook for common operations

---

## Detailed Task Specifications

### Task 3.1: Create langfuse.tf

**File:** `terraform-openshift-platform-apps/langfuse.tf`

```hcl
locals {
  langfuse_route = file("${path.module}/manifests/langfuse/langfuse-route.yaml")
  langfuse_vault_connection = file("${path.module}/manifests/langfuse/vault-connection.yaml")
  langfuse_vault_auth = file("${path.module}/manifests/langfuse/vault-auth.yaml")
  langfuse_vault_auth_sa = file("${path.module}/manifests/langfuse/vault-auth-sa.yaml")
  langfuse_pki_cert = file("${path.module}/manifests/langfuse/crd-pki-langfusecert.yaml")
  
  langfuse_helm_values = templatefile("${path.module}/templates/langfuse_helm_values.yaml.tpl", {
    hostname           = "langfuse.apps.openshift-01.hashicorp.local"
    storage_class      = "ocs-storagecluster-cephfs"
    s3_endpoint        = "http://rook-ceph-rgw-ocs-storagecluster-cephobjectstore.openshift-storage.svc"
    s3_bucket          = data.kubernetes_resource.langfuse_s3.object.spec.bucketName
    s3_access_key      = data.kubernetes_secret.langfuse_s3.data.AWS_ACCESS_KEY_ID
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
      metadata.0.annotations["openshift.io/sa.scc.uid-range"]
    ]
  }
}

# S3 Bucket Claim for Langfuse
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

# Data sources for S3 credentials
data "kubernetes_secret" "langfuse_s3" {
  depends_on = [kubernetes_manifest.langfuse_s3_bucket]
  metadata {
    name      = "langfuse"
    namespace = "langfuse"
  }
}

data "kubernetes_resource" "langfuse_s3" {
  depends_on  = [kubernetes_manifest.langfuse_s3_bucket]
  api_version = "objectbucket.io/v1alpha1"
  kind        = "ObjectBucketClaim"
  metadata {
    name      = "langfuse"
    namespace = "langfuse"
  }
}

# Secrets for Langfuse
resource "kubernetes_secret" "langfuse_secrets" {
  depends_on = [kubernetes_namespace.langfuse]
  metadata {
    name      = "langfuse-secrets"
    namespace = "langfuse"
  }
  
  data = {
    NEXTAUTH_SECRET          = var.langfuse_nextauth_secret
    SALT                     = var.langfuse_salt
    LANGFUSE_ENCRYPTION_KEY  = var.langfuse_encryption_key
  }
}

# Helm release
resource "helm_release" "langfuse" {
  depends_on = [
    kubernetes_namespace.langfuse,
    kubernetes_secret.langfuse_secrets,
    kubernetes_manifest.langfuse_s3_bucket
  ]
  
  name             = "langfuse"
  repository       = "https://langfuse.github.io/langfuse-k8s"
  chart            = "langfuse"
  namespace        = "langfuse"
  create_namespace = false
  wait             = false
  force_update     = true
  
  values = [local.langfuse_helm_values]
}

# OpenShift Route
resource "kubernetes_manifest" "langfuse_route" {
  depends_on = [helm_release.langfuse]
  manifest   = provider::kubernetes::manifest_decode(local.langfuse_route)
}

# Vault integration (optional - uncomment when ready)
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
```

---

### Task 3.2: Create Helm Values Template

**File:** `terraform-openshift-platform-apps/templates/langfuse_helm_values.yaml.tpl`

```yaml
# Langfuse Helm Values for OpenShift
# Generated by Terraform

global:
  defaultStorageClass: "${storage_class}"

langfuse:
  nextauth:
    url: "https://${hostname}"
    secret:
      secretKeyRef:
        name: langfuse-secrets
        key: NEXTAUTH_SECRET
  
  salt:
    secretKeyRef:
      name: langfuse-secrets
      key: SALT
  
  encryptionKey:
    secretKeyRef:
      name: langfuse-secrets
      key: LANGFUSE_ENCRYPTION_KEY
  
  # Resource sizing for demo/development
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1"
      memory: "2Gi"
  
  # OpenShift ingress disabled - we use Route instead
  ingress:
    enabled: false
  
  # Service configuration
  service:
    type: ClusterIP
    port: 3000

# Use bundled PostgreSQL
postgresql:
  deploy: true
  auth:
    username: langfuse
    database: langfuse
  primary:
    persistence:
      storageClass: "${storage_class}"
      size: 10Gi

# Use bundled ClickHouse
clickhouse:
  deploy: true
  auth:
    username: default
  persistence:
    storageClass: "${storage_class}"
    size: 20Gi
  resources:
    requests:
      cpu: "500m"
      memory: "2Gi"
    limits:
      cpu: "1"
      memory: "4Gi"
  zookeeper:
    persistence:
      storageClass: "${storage_class}"
      size: 5Gi
    resources:
      requests:
        cpu: "250m"
        memory: "512Mi"
      limits:
        cpu: "500m"
        memory: "1Gi"

# Use bundled Redis
redis:
  deploy: true
  primary:
    persistence:
      storageClass: "${storage_class}"
      size: 5Gi
    resources:
      requests:
        cpu: "100m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"

# Use external S3 (Ceph RGW)
s3:
  deploy: false
  bucket: "${s3_bucket}"
  region: "us-east-1"
  endpoint: "${s3_endpoint}"
  forcePathStyle: true
  accessKeyId:
    value: "${s3_access_key}"
  secretAccessKey:
    secretKeyRef:
      name: langfuse
      key: AWS_SECRET_ACCESS_KEY
  eventUpload:
    prefix: "events/"
  batchExport:
    prefix: "exports/"
  mediaUpload:
    prefix: "media/"
```

---

### Task 3.4: Create OpenShift Route

**File:** `terraform-openshift-platform-apps/manifests/langfuse/langfuse-route.yaml`

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: langfuse
  namespace: langfuse
  annotations:
    haproxy.router.openshift.io/timeout: 300s
spec:
  host: langfuse.apps.openshift-01.hashicorp.local
  port:
    targetPort: 3000
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  to:
    kind: Service
    name: langfuse-web
    weight: 100
  wildcardPolicy: None
```

---

### Task 3.9: Update variables.tf

**Add to:** `terraform-openshift-platform-apps/variables.tf`

```hcl
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
```

---

## Dependencies Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    terraform-openshift-config                │
│  (Vault Secrets Operator already installed)                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                terraform-openshift-platform-apps             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐                                       │
│  │ kubernetes_      │                                       │
│  │ namespace        │◄─────────────────────────────────┐    │
│  │ "langfuse"       │                                  │    │
│  └────────┬─────────┘                                  │    │
│           │                                            │    │
│           ▼                                            │    │
│  ┌──────────────────┐    ┌──────────────────┐         │    │
│  │ kubernetes_      │    │ kubernetes_      │         │    │
│  │ manifest         │    │ secret           │         │    │
│  │ "s3_bucket"      │    │ "langfuse_secrets"│        │    │
│  └────────┬─────────┘    └────────┬─────────┘         │    │
│           │                       │                    │    │
│           └───────────┬───────────┘                    │    │
│                       │                                │    │
│                       ▼                                │    │
│              ┌──────────────────┐                      │    │
│              │ helm_release     │                      │    │
│              │ "langfuse"       │                      │    │
│              │                  │                      │    │
│              │ - PostgreSQL     │                      │    │
│              │ - ClickHouse     │                      │    │
│              │ - Redis          │                      │    │
│              │ - Web + Worker   │                      │    │
│              └────────┬─────────┘                      │    │
│                       │                                │    │
│                       ▼                                │    │
│              ┌──────────────────┐                      │    │
│              │ kubernetes_      │                      │    │
│              │ manifest         │                      │    │
│              │ "langfuse_route" │                      │    │
│              └──────────────────┘                      │    │
│                                                        │    │
│  ┌─────────────────────────────────────────────────┐  │    │
│  │ Optional: Vault Integration                      │  │    │
│  │ - vault-auth-sa.yaml                            │  │    │
│  │ - vault-connection.yaml                         │  │    │
│  │ - vault-auth.yaml                               │  │    │
│  │ - crd-pki-langfusecert.yaml                     │  │    │
│  └─────────────────────────────────────────────────┘  │    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Estimated Effort

| Phase | Estimated Time | Complexity |
|-------|---------------|------------|
| Phase 1: Preparation | 1 hour | Low |
| Phase 2: Config Repo | 30 mins | Low |
| Phase 3: Platform Apps | 2-3 hours | Medium |
| Phase 4: Testing | 1-2 hours | Medium |
| Phase 5: Documentation | 30 mins | Low |
| **Total** | **5-7 hours** | **Medium** |

---

## Next Steps After Completion

1. **Monitor resource usage** - Adjust sizing based on actual usage
2. **Add Keycloak SSO** - Integrate with existing Keycloak for unified auth
3. **Configure Vault dynamic secrets** - Replace static passwords with Vault-generated credentials
4. **Set up backup strategy** - Configure PostgreSQL and ClickHouse backups
5. **Add to Boundary** - Register Langfuse as a Boundary target
