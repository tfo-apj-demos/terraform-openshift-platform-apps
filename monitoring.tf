# Monitoring Stack - Prometheus, Grafana, and Loki for OpenShift
# Deployed via Helm charts from prometheus-community and grafana
# Reference: https://github.com/prometheus-community/helm-charts
# Reference: https://github.com/grafana/helm-charts

locals {
  prometheus_route = file("${path.module}/manifests/monitoring/prometheus-route.yaml")
  grafana_route    = file("${path.module}/manifests/monitoring/grafana-route.yaml")
  loki_route       = file("${path.module}/manifests/monitoring/loki-route.yaml")

  prometheus_helm_values = templatefile("${path.module}/templates/prometheus_helm_values.yaml.tpl", {
    storage_class = var.monitoring_storage_class
  })

  grafana_helm_values = templatefile("${path.module}/templates/grafana_helm_values.yaml.tpl", {
    admin_password = var.grafana_admin_password
    prometheus_url = "http://prometheus-server.monitoring.svc.cluster.local:80"
    loki_url       = "http://loki-gateway.monitoring.svc.cluster.local:80"
    storage_class  = var.monitoring_storage_class
    root_url       = "https://grafana.apps.openshift-01.hashicorp.local"
  })

  loki_helm_values = templatefile("${path.module}/templates/loki_helm_values.yaml.tpl", {
    storage_class = var.monitoring_storage_class
  })
}

# Namespace for monitoring stack
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
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

# SCC for Prometheus and Grafana - allow pods to run with required permissions
# Prometheus node-exporter needs hostNetwork and hostPID access
resource "kubernetes_manifest" "monitoring_nonroot_scc" {
  depends_on = [kubernetes_namespace.monitoring]
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "monitoring-nonroot-scc"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "system:openshift:scc:nonroot-v2"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "prometheus-server"
        namespace = "monitoring"
      },
      {
        kind      = "ServiceAccount"
        name      = "grafana"
        namespace = "monitoring"
      },
      {
        kind      = "ServiceAccount"
        name      = "prometheus-alertmanager"
        namespace = "monitoring"
      },
      {
        kind      = "ServiceAccount"
        name      = "prometheus-kube-state-metrics"
        namespace = "monitoring"
      },
      {
        kind      = "ServiceAccount"
        name      = "loki"
        namespace = "monitoring"
      },
      {
        kind      = "ServiceAccount"
        name      = "loki-canary"
        namespace = "monitoring"
      }
    ]
  }
}

# Node exporter requires hostaccess SCC for host metrics
resource "kubernetes_manifest" "monitoring_hostaccess_scc" {
  depends_on = [kubernetes_namespace.monitoring]
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "monitoring-hostaccess-scc"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "system:openshift:scc:hostaccess"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "prometheus-prometheus-node-exporter"
        namespace = "monitoring"
      }
    ]
  }
}

# Prometheus Helm Release
resource "helm_release" "prometheus" {
  depends_on = [
    kubernetes_namespace.monitoring,
    kubernetes_manifest.monitoring_nonroot_scc,
    kubernetes_manifest.monitoring_hostaccess_scc
  ]

  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = var.prometheus_helm_version
  namespace        = "monitoring"
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [local.prometheus_helm_values]
}

# Grafana Helm Release
resource "helm_release" "grafana" {
  depends_on = [
    kubernetes_namespace.monitoring,
    kubernetes_manifest.monitoring_nonroot_scc,
    helm_release.prometheus
  ]

  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = var.grafana_helm_version
  namespace        = "monitoring"
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [local.grafana_helm_values]
}

# OpenShift Route for Prometheus
resource "kubernetes_manifest" "prometheus_route" {
  depends_on = [helm_release.prometheus]
  manifest   = provider::kubernetes::manifest_decode(local.prometheus_route)
}

# OpenShift Route for Grafana
resource "kubernetes_manifest" "grafana_route" {
  depends_on = [helm_release.grafana]
  manifest   = provider::kubernetes::manifest_decode(local.grafana_route)
}

# Loki Helm Release - Log aggregation
resource "helm_release" "loki" {
  depends_on = [
    kubernetes_namespace.monitoring,
    kubernetes_manifest.monitoring_nonroot_scc
  ]

  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = var.loki_helm_version
  namespace        = "monitoring"
  create_namespace = false
  wait             = true
  timeout          = 900 # Loki can take longer due to MinIO initialization

  values = [local.loki_helm_values]
}

# OpenShift Route for Loki Gateway
resource "kubernetes_manifest" "loki_route" {
  depends_on = [helm_release.loki]
  manifest   = provider::kubernetes::manifest_decode(local.loki_route)
}
