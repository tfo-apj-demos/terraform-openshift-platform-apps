
provider "kubernetes" {
  # Configuration options
  host = var.host
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  client_key = base64decode(var.client_key)
  client_certificate = base64decode(var.client_certificate)
  
}

provider "helm" {
  # Configuration options
  kubernetes {  
    host = var.host
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    client_key = base64decode(var.client_key)
    client_certificate = base64decode(var.client_certificate)
  }
}

provider "boundary" {
  addr  = var.boundary_address
}
