#provider.tf
provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
provider "kubernetes" {
  config_path = "~/.kube/config"
  # host                   = yandex_kubernetes_cluster.k8s-zonal.master[0].external_v4_endpoint
  # cluster_ca_certificate = base64decode(yandex_kubernetes_cluster.k8s-zonal.master[0].cluster_ca_certificate)
}
