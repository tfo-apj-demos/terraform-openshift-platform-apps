locals {
  # Ansible Automation Platform
  aap_controller = file("${path.module}/manifests/ansible/aap-controller.yaml")
  aap_hub= file("${path.module}/manifests/ansible/aap-hub.yaml")
  aap_eda = file("${path.module}/manifests/ansible/aap-eda.yaml")
  aap-vault-auth-sa = file("${path.module}/manifests/ansible/aap-vault-auth-sa.yaml")
}


import {
  to = kubernetes_manifest.aap-controller
  id = "apiVersion=automationcontroller.ansible.com/v1beta1,kind=AutomationController,namespace=aap,name=controller"
}

# Ansible Controller resource
resource "kubernetes_manifest" "aap-controller" {
  manifest = provider::kubernetes::manifest_decode(local.aap_controller)
  field_manager {
    force_conflicts = true
  }
}


# Ansible EDA resource
resource "kubernetes_manifest" "aap-eda" {
  manifest = provider::kubernetes::manifest_decode(local.aap_eda)
}


# Ansible Automation Hub
resource "kubernetes_manifest" "aap-hub" {
  manifest = provider::kubernetes::manifest_decode(local.aap_hub)
}

resource "kubernetes_manifest" "aap-sa" {
  manifest = provider::kubernetes::manifest_decode(local.aap-vault-auth-sa)
}