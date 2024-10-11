locals {
# Ansible Automation Platform
aap_controller = file("${path.module}/manifests/ansible/aap-controller.yaml")
aap_hub= file("${path.module}/manifests/ansible/aap-hub.yaml")
aap_eda = file("${path.module}/manifests/ansible/aap-eda.yaml")
}


# import {
#   to = kubernetes_manifest.aap-controller
#   id = "apiVersion=automationcontroller.ansible.com/v1beta1,kind=AutomationController,namespace=aap,name=controller"
# }

# # Ansible Controller resource
# resource "kubernetes_manifest" "aap-controller" {
#   manifest = provider::kubernetes::manifest_decode(local.aap_controller)
# }

import {
  to = kubernetes_manifest.aap-eda
  id = "apiVersion=eda.ansible.com/v1alpha1,kind=EDA,namespace=aap,name=eda"
}

# Ansible EDA resource
resource "kubernetes_manifest" "aap-eda" {
  manifest = provider::kubernetes::manifest_decode(local.aap_eda)
}


# Ansible Automation Hub
resource "kubernetes_manifest" "aap-hub" {
  manifest = provider::kubernetes::manifest_decode(local.aap_hub)
}