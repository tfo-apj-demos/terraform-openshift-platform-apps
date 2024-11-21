locals {
  gitlab_deployment = file("${path.module}/manifests/gitlab-cde/gitlab-deployment.yaml")
  gitlab_service = file("${path.module}/manifests/gitlab-cde/gitlab-service.yaml")
  gitlab_pvc_logs = file("${path.module}/manifests/gitlab-cde/gitlab-pvc-logs.yaml")
  gitlab_route = file("${path.module}/manifests/gitlab-cde/gitlab-route.yaml")
}