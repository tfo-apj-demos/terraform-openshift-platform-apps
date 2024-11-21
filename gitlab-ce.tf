locals {
  gitlab_deployment = file("${path.module}/manifests/gitlab-ce/gitlab-deployment.yaml")
  gitlab_service = file("${path.module}/manifests/gitlab-ce/gitlab-service.yaml")
  gitlab_pvc_logs = file("${path.module}/manifests/gitlab-ce/gitlab-pvc-logs.yaml")
  gitlab_pvc_data = file("${path.module}/manifests/gitlab-ce/gitlab-pvc-data.yaml")
  gitlab_pvc_config = file("${path.module}/manifests/gitlab-ce/gitlab-pvc-config.yaml")
  gitlab_route = file("${path.module}/manifests/gitlab-ce/gitlab-route.yaml")

  #Gitlab Vault Resources for certificate
  gitlab_crd_vaultauth = file("${path.module}/manifests/gitlab-ce/crd-vault-auth.yaml")
  gitlab_crd_vaultconnection = file("${path.module}/manifests/gitlab-ce/crd-vault-connection.yaml")
  gitlab_pki-cert = file("${path.module}/manifests/gitlab-ce/crd-pki-gitlabcert.yaml")

}

resource "kubernetes_namespace" "gitlab" {
  metadata {
    name = "gitlab"
  }
  
}

resource "kubernetes_manifest" "gitlab_deployment" {
  depends_on = [kubernetes_namespace.gitlab]
  manifest   = provider::kubernetes::manifest_decode(local.gitlab_deployment)
}

resource "kubernetes_manifest" "gitlab_pvc_config" {
  depends_on = [kubernetes_namespace.gitlab]
  manifest   = provider::kubernetes::manifest_decode(local.gitlab_pvc_config)
}

resource "kubernetes_manifest" "gitlab_pvc_data" {
  depends_on = [kubernetes_namespace.gitlab]
  manifest   = provider::kubernetes::manifest_decode(local.gitlab_pvc_data)
}

resource "kubernetes_manifest" "gitlab_pvc_logs" {
  depends_on = [kubernetes_namespace.gitlab]
  manifest   = provider::kubernetes::manifest_decode(local.gitlab_pvc_logs)
}