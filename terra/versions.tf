#versions.tf
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.87.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
  }
  # Описание бэкенда хранения состояния
  backend "s3" {
    endpoint = "storage.yandexcloud.net"
    bucket   = "terra-state-01"
    region   = "ru-central1"
    key      = "diplom/terraform.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
