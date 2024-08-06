output "cluster_ip_external" {
  value = yandex_kubernetes_cluster.k8s-zonal.master[0].external_v4_address
}
# output "lb_ip_external" {
#   value = data.yandex_alb_load_balancer.tf-alb-data.listener.0
# }
# output "auth" {
#   value     = local.auth_json
#   sensitive = true
# }

# output "auth_json_one_line" {
#   value     = replace(local.auth_json, "/\\n/", "n")
#   sensitive = true
# }
# output "created_at" {
#   value = "${jsonencode({ created_at = yandex_iam_service_account_key.sa-auth-key.created_at
#     id = yandex_iam_service_account_key.sa-auth-key.id
#   public_key = yandex_iam_service_account_key.sa-auth-key.public_key })}\n"
# }
# output "created_at2" {
#   value     = local_file.auth_json_file
#   sensitive = true
# }
