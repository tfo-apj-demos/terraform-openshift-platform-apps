locals {
  aap-vault-auth-sa = file("${path.module}/manifests/ansible/aap-vault-auth-sa.yaml")
  aap-platform = file("${path.module}/manifests/ansible/aap-platform.yaml")
}


# Ansible Automation Platform resource
resource "kubernetes_manifest" "aap-controller" {
  manifest = provider::kubernetes::manifest_decode(local.aap-platform)
  field_manager {
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "aap-sa" {
  manifest = provider::kubernetes::manifest_decode(local.aap-vault-auth-sa)
}