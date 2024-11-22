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

  gitlab_sa = file("${path.module}/manifests/gitlab-ce/gitlab-sa.yaml")
  gitlab_scc = file("${path.module}/manifests/gitlab-ce/gitlab-scc.yaml")

  #Gitlab Vault Service Account
  gitlab_vault_sa = file("${path.module}/manifests/gitlab-ce/crd-vault-auth-sa.yaml")

}

resource "kubernetes_namespace" "gitlab" {
  metadata {
    name = "gitlab"
  }

    lifecycle {
    
    ignore_changes = [
        metadata.0.annotations["openshift.io/sa.scc.mcs"],
        metadata.0.annotations["openshift.io/sa.scc.supplemental-groups"],
        metadata.0.annotations["openshift.io/sa.scc.uid-range"],
    ]
    }
  
}

# resource "kubernetes_manifest" "gitlab_scc" {
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_scc)
# }

# resource "kubernetes_manifest" "gitlab_sa" {
#   depends_on = [kubernetes_namespace.gitlab]
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_sa)
# }



# resource "kubernetes_manifest" "gitlab_deployment" {
#   depends_on = [kubernetes_namespace.gitlab]
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_deployment)
# }

# resource "kubernetes_manifest" "gitlab_pvc_config" {
#   depends_on = [kubernetes_namespace.gitlab]
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_pvc_config)
# }

# resource "kubernetes_manifest" "gitlab_pvc_data" {
#   depends_on = [kubernetes_namespace.gitlab]
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_pvc_data)
# }

# resource "kubernetes_manifest" "gitlab_pvc_logs" {
#   depends_on = [kubernetes_namespace.gitlab]
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_pvc_logs)
# }

# resource "kubernetes_manifest" "gitlab_route" {
#   depends_on = [kubernetes_namespace.gitlab]
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_route)
# }

# resource "kubernetes_manifest" "gitlab_service" {
#   depends_on = [kubernetes_namespace.gitlab]
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_service)
# }


# #vault resources

# resource "kubernetes_manifest" "gitlab_crd_vaultauth" {
#   depends_on = [kubernetes_namespace.gitlab]
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_crd_vaultauth)
# }

# resource "kubernetes_manifest" "gitlab_crd_vaultconnection" {
#   depends_on = [kubernetes_namespace.gitlab]
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_crd_vaultconnection)
# }

# resource "kubernetes_manifest" "gitlab_pki-cert" {
#   depends_on = [kubernetes_namespace.gitlab]
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_pki-cert)
# }

# # vault sa kubernetes_manifest
# resource "kubernetes_manifest" "gitlab_vault_sa" {
#   depends_on = [kubernetes_namespace.gitlab]
#   manifest = provider::kubernetes::manifest_decode(local.gitlab_vault_sa)
# }


