# Langfuse Deployment Plan for OpenShift

## Overview

This document outlines the plan to deploy [Langfuse](https://langfuse.com/) - an open-source LLM engineering platform for tracing, evaluation, prompt management, and metrics - onto our OpenShift cluster using the established Terraform patterns.

## What is Langfuse?

Langfuse is an observability and analytics platform for LLM applications. It provides:
- **LLM Tracing** - Track and debug LLM calls
- **Prompt Management** - Version and manage prompts
- **Evaluation** - Score and evaluate LLM outputs
- **Metrics & Analytics** - Understand usage patterns
- **Datasets** - Manage test datasets

## Architecture Requirements

Langfuse requires the following components:

| Component | Purpose | OpenShift Equivalent |
|-----------|---------|---------------------|
| **PostgreSQL** | Primary database for application data | Crunchy PostgreSQL Operator (already deployed) |
| **ClickHouse** | Analytics database for traces/metrics | Deploy via Helm subchart or external |
| **Redis** | Caching and queue management | Deploy via Helm subchart or external |
| **S3-Compatible Storage** | Blob storage for events, exports, media | Ceph RGW (already available via `openshift-storage`) |
| **Web Application** | Langfuse UI and API | Helm chart deployment |
| **Worker** | Background job processing | Helm chart deployment |

## Deployment Strategy

Based on our existing patterns, we will use **Pattern 2: Helm Chart Deployment** similar to TFE.

### Repository Split

| Repository | Resources |
|------------|-----------|
| **terraform-openshift-config** | *(Optional)* Namespace creation if we want separation from platform-apps |
| **terraform-openshift-platform-apps** | Helm release, secrets, OpenShift route, Vault integration |

Since Langfuse uses a Helm chart with bundled dependencies (PostgreSQL, ClickHouse, Redis, S3/MinIO), we can deploy everything from **terraform-openshift-platform-apps** using the Helm chart pattern.

## Design Decisions

### Decision 1: Database Strategy

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **A: Use bundled PostgreSQL** | Simple, self-contained | Separate from existing PG infrastructure | For initial deployment |
| **B: Use existing Crunchy PostgreSQL** | Consistent management, backup strategy | More configuration needed | Future enhancement |

**Decision:** Start with bundled PostgreSQL, migrate to Crunchy PostgreSQL later if needed.

### Decision 2: ClickHouse Strategy

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **A: Use bundled ClickHouse** | Simple, managed by Helm | Resource overhead | ✅ Recommended |
| **B: External ClickHouse** | Shared infrastructure | Requires separate deployment | Future consideration |

**Decision:** Use bundled ClickHouse from Helm chart.

### Decision 3: Redis Strategy

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **A: Use bundled Redis** | Simple, managed by Helm | Separate from any shared Redis | ✅ Recommended |
| **B: External Redis** | Could share with other apps | Complexity | Not needed initially |

**Decision:** Use bundled Redis from Helm chart.

### Decision 4: Blob Storage Strategy

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **A: Use bundled MinIO** | Simple, self-contained | Duplicate storage | For initial deployment |
| **B: Use Ceph RGW (existing)** | Leverages existing storage | Configuration complexity | ✅ Recommended |

**Decision:** Use existing Ceph RGW S3-compatible storage (same pattern as TFE).

### Decision 5: TLS/Certificate Strategy

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **A: OpenShift default (edge termination)** | Simple, automatic | Less control | For initial deployment |
| **B: Vault PKI integration** | Consistent with other apps | More setup | ✅ Recommended |

**Decision:** Use Vault PKI for certificate generation (existing pattern).

### Decision 6: Authentication Strategy

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **A: Built-in auth** | Simple, works out of box | Separate user management | For initial deployment |
| **B: Keycloak OIDC** | SSO with other apps | Configuration needed | Future enhancement |

**Decision:** Start with built-in auth, add Keycloak integration later.

### Decision 7: Secrets Management

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **A: Kubernetes secrets only** | Simple | Manual rotation | For initial deployment |
| **B: Vault Secrets Operator** | Dynamic secrets, rotation | More setup | ✅ Recommended |

**Decision:** Use Vault Secrets Operator for sensitive values (consistent with other apps).

## Resource Sizing

Based on Langfuse documentation recommendations:

### Development/Demo
```yaml
langfuse:
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1"
      memory: "2Gi"
```

### Production
```yaml
langfuse:
  resources:
    requests:
      cpu: "2"
      memory: "4Gi"
    limits:
      cpu: "2"
      memory: "4Gi"

clickhouse:
  resources:
    requests:
      cpu: "2"
      memory: "8Gi"
    limits:
      cpu: "2"
      memory: "8Gi"
```

## Required Secrets

| Secret | Purpose | Source |
|--------|---------|--------|
| `NEXTAUTH_SECRET` | Session encryption | Generate: `openssl rand -hex 32` |
| `SALT` | Password hashing | Generate: `openssl rand -hex 32` |
| `ENCRYPTION_KEY` | Data encryption (optional) | Generate: `openssl rand -hex 32` |
| PostgreSQL password | Database auth | Auto-generated or Vault |
| ClickHouse password | Analytics DB auth | Auto-generated or Vault |
| Redis password | Cache auth | Auto-generated or Vault |
| S3 credentials | Blob storage auth | From Ceph RGW ObjectBucketClaim |

## Network Configuration

| Endpoint | Internal Service | External Route |
|----------|------------------|----------------|
| Web UI | `langfuse-web.langfuse.svc:3000` | `langfuse.apps.openshift-01.hashicorp.local` |
| API | Same as Web UI | Same route |

## Integration Points

### Vault Secrets Operator
- VaultConnection pointing to existing Vault
- VaultAuth for Kubernetes auth
- VaultStaticSecret or VaultDynamicSecret for credentials

### Boundary (Optional)
- Register Langfuse as a target for secure access

## Success Criteria

1. ✅ Langfuse web UI accessible via OpenShift route
2. ✅ User registration and login functional
3. ✅ Project creation working
4. ✅ Trace ingestion via SDK functional
5. ✅ Metrics and analytics displaying correctly
6. ✅ Persistent storage surviving pod restarts

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| ClickHouse resource consumption | Start with modest sizing, monitor and scale |
| Bitnami image registry changes | Use `bitnamilegacy/*` images as per Langfuse docs |
| OpenShift SCC restrictions | May need custom SCC for ClickHouse/ZooKeeper |
| Storage class compatibility | Test with `ocs-storagecluster-cephfs` |

## References

- [Langfuse Helm Chart](https://github.com/langfuse/langfuse-k8s)
- [Langfuse Self-Hosting Docs](https://langfuse.com/self-hosting)
- [Langfuse Configuration Guide](https://langfuse.com/self-hosting/configuration)
- [Langfuse Architecture](https://langfuse.com/self-hosting#architecture)
