# IBM DB2 instance — commented out, trial license expired 2025-06-09
# locals {
#   db2_instance = file("${path.module}/manifests/ibm-db2/db2-instance1.yaml")
# }
#
# resource "kubernetes_manifest" "db2" {
#   manifest = provider::kubernetes::manifest_decode(local.db2_instance)
# }
