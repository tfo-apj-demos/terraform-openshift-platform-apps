# resource "kubernetes_secret" "gitlab_runner_token" {
#   metadata {
#     name      = "gitlab-runner-secret"
#     namespace = "gitlab-runner"
#   }

#   type = "Opaque"

#   data = {
#     "runner-token" = base64encode(var.gitlab_runner_token)
#   }
# }

# locals {
#   gitlab_runner_manifest = file("${path.module}/manifests/gitlab-runner/crd-runner.yaml")
# }

# resource "kubernetes_manifest" "gitlab_runner" {
#   depends_on = [kubernetes_secret.gitlab_runner_token]
#   manifest   = provider::kubernetes::manifest_decode(local.gitlab_runner_manifest)
# }
