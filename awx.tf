locals {
  # Ansible Automation Platform
  awx = file("${path.module}/manifests/awx/awx.yaml")
  awx-vault-auth-sa = file("${path.module}/manifests/awx/awx-vault-auth-sa.yaml")
  awx-clusterrolebinding = file("${path.module}/manifests/awx/awx-clusterrolebinding.yaml")
}

resource "kubernetes_secret_v1" "awx-admin-password" {
  metadata {
    name = "awx-admin-password"
    namespace = "awx"
  }

  data = {
    "password" = var.awx_admin_password
  }
}

resource "kubernetes_manifest" "awx" {
  depends_on = [ kubernetes_secret_v1.awx-admin-password ]
  manifest = provider::kubernetes::manifest_decode(local.awx)
  field_manager {
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "awx-sa" {
  depends_on = [ kubernetes_manifest.awx ]
  manifest = provider::kubernetes::manifest_decode(local.awx-vault-auth-sa)
  field_manager {
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "awx-clusterrolebinding" {
  depends_on = [ kubernetes_manifest.awx-sa ]
  manifest = provider::kubernetes::manifest_decode(local.awx-clusterrolebinding)
  field_manager {
    force_conflicts = true
  }
}