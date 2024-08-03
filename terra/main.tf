#main.tf
resource "yandex_kubernetes_cluster" "k8s-zonal" {
  name       = "k8s-zonal"
  network_id = yandex_vpc_network.terra-net.id
  master {
    master_location {
      zone      = yandex_vpc_subnet.terra-subnet.zone
      subnet_id = yandex_vpc_subnet.terra-subnet.id
    }
    public_ip          = true
    security_group_ids = [yandex_vpc_security_group.k8s-public-services.id]
  }
  service_account_id      = var.service_account_id
  node_service_account_id = var.service_account_id
  kms_provider {
    key_id = yandex_kms_symmetric_key.kms-key.id
  }
  provisioner "local-exec" {
    command = "yc managed-kubernetes cluster get-credentials ${yandex_kubernetes_cluster.k8s-zonal.name} --external --force"
  }
}


resource "yandex_vpc_network" "terra-net" {
  name = "terra-net"
}

resource "yandex_vpc_subnet" "terra-subnet" {
  name           = "terra-subnet"
  v4_cidr_blocks = ["10.1.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.terra-net.id
}

resource "yandex_dns_zone" "nuf1-fun" {
  name = "nuf1-fun"
  labels = {
    label1 = "owner-1-ag"
  }

  zone                = "nuf1.fun."
  public              = true
  deletion_protection = false
}

resource "yandex_dns_recordset" "rs1" {
  zone_id = yandex_dns_zone.nuf1-fun.id
  name    = "w.nuf1.fun."
  type    = "A"
  ttl     = 200
  data    = ["51.250.33.45"]
}

resource "yandex_kms_symmetric_key" "kms-key" {
  # Ключ Yandex Key Management Service для шифрования важной информации, такой как пароли, OAuth-токены и SSH-ключи.
  name              = "kms-key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" # 1 год.
}

resource "yandex_vpc_security_group" "k8s-public-services" {
  name        = "k8s-public-services"
  description = "Правила группы разрешают подключение к сервисам из интернета. Примените правила только для групп узлов."
  network_id  = yandex_vpc_network.terra-net.id
  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает проверки доступности с диапазона адресов балансировщика нагрузки. Нужно для работы отказоустойчивого кластера Managed Service for Kubernetes и сервисов балансировщика."
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие мастер-узел и узел-узел внутри группы безопасности."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol       = "ANY"
    description    = "Правило разрешает взаимодействие под-под и сервис-сервис. Укажите подсети вашего кластера Managed Service for Kubernetes и сервисов."
    v4_cidr_blocks = concat(yandex_vpc_subnet.terra-subnet.v4_cidr_blocks)
    from_port      = 0
    to_port        = 65535
  }
  ingress {
    protocol       = "ICMP"
    description    = "Правило разрешает отладочные ICMP-пакеты из внутренних подсетей."
    v4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  ingress {
    protocol       = "TCP"
    description    = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort. Добавьте или измените порты на нужные вам."
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }
  egress {
    protocol       = "ANY"
    description    = "Правило разрешает весь исходящий трафик. Узлы могут связаться с Yandex Container Registry, Yandex Object Storage, Docker Hub и т. д."
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
  ingress {
    protocol       = "TCP"
    description    = "Правило разрешает входящий трафик из интернета на публичный IP кластера"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 443
  }
}

resource "yandex_kubernetes_node_group" "k8s-diplom-ng" {
  name        = "k8s-diplom-ng"
  description = "Test node group"
  cluster_id  = yandex_kubernetes_cluster.k8s-zonal.id
  instance_template {
    name        = "test-{instance.short_id}-{instance_group.id}"
    platform_id = "standard-v3"
    metadata = {
      "enable-oslogin" = "true"
    }
    resources {
      cores         = 2
      core_fraction = 50
      memory        = 4
    }
    boot_disk {
      size = 30
      type = "network-ssd"
    }
    network_acceleration_type = "standard"
    network_interface {
      security_group_ids = [yandex_vpc_security_group.k8s-public-services.id]
      subnet_ids         = [yandex_vpc_subnet.terra-subnet.id]
      nat                = true
    }
    scheduling_policy {
      preemptible = true
    }
  }
  scale_policy {
    fixed_scale {
      size = 1
    }
  }
  deploy_policy {
    max_expansion   = 3
    max_unavailable = 1
  }
  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
    maintenance_window {
      start_time = "02:00"
      duration   = "6h"
    }
  }
  node_labels = {
    node-label1 = "node-value1"
  }
  labels = {
    "template-label1" = "template-value1"
  }
  allowed_unsafe_sysctls = ["kernel.msg*", "net.core.somaxconn"]
}

resource "yandex_iam_service_account" "svc-ingress" {
  name        = "svc-ingress"
  description = "for k8s ingress"
}

resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.svc-ingress.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.svc-ingress.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "load-balancer-admin" {
  folder_id = var.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.svc-ingress.id}"
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress-controller"
  atomic     = true
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  # set {
  #   name  = "service.type"
  #   value = "ClusterIP"
  # }
}
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = var.service_account_id
  description        = "static access key for object storage, generated by terraform"
}
resource "yandex_storage_bucket" "diplom-momo-img" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket     = "diplom-momo-img"
  acl        = "public-read"
}
resource "yandex_storage_object" "momo-img" {
  access_key  = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key  = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket      = yandex_storage_bucket.diplom-momo-img.bucket
  for_each    = fileset("/home/a/Downloads/momo-img/", "**")
  key         = each.value
  source      = "/home/a/Downloads/momo-img/${each.value}"
  source_hash = filemd5("/home/a/Downloads/momo-img/${each.value}")
  tags = {
    test = "value"
  }
}
