locals {

}

# resource "kubernetes_namespace" "gitlab" {
#   metadata {
#     name = "gitlab"
#   }

#     lifecycle {
    
#     ignore_changes = [
#         metadata.0.annotations["openshift.io/sa.scc.mcs"],
#         metadata.0.annotations["openshift.io/sa.scc.supplemental-groups"],
#         metadata.0.annotations["openshift.io/sa.scc.uid-range"],
#     ]
#     }
  
# }

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


