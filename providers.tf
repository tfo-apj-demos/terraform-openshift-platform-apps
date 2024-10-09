
provider "kubernetes" {
  # Configuration options
  host = var.k8s_api_server
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  client_key = base64decode(var.client_key)
  client_certificate = base64decode(var.client_certificate)
  
}

provider "helm" {
  # Configuration options
  kubernetes {  
    host = var.k8s_api_server
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    client_key = base64decode(var.client_key)
    client_certificate = base64decode(var.client_certificate)
  }
}

provider "boundary" {
  addr  = var.boundary_address
}
