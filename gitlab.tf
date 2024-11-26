locals {

    gitlab_crd = file("${path.module}/manifests/gitlab/crd-gitlab.yaml")
    gitlab_route = file("${path.module}/manifests/gitlab/gitlab-route.yaml")
}



# resource "kubernetes_manifest" "gitlab_crd" {
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_crd)
# }

# resource "kubernetes_manifest" "gitlab_route" {
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_route)
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


