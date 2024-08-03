output "cluster_ip_external" {
  value = yandex_kubernetes_cluster.k8s-zonal.master[0].external_v4_address
}
