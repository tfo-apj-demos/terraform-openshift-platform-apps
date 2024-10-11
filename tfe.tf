import {
  to = helm_release.tfe
  id = "tfe/terraform-enterprise"
}

# deploy tfe using helm chart
resource "helm_release" "tfe" {
  name       = "terraform-enterprise"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "terraform-enterprise"
  version    = "1.3.2"
  create_namespace = false
  namespace = "tfe"
  wait = false
  force_update = true

  values = [
    local.tfe_helm_values
  ]

}
