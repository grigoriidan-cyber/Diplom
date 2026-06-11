# provider.tf - провайдер и версия Terraform

terraform {
  required_version = ">= 1.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.206"
    }
  }
}

# Подключение к Yandex Cloud
# Ключ лежит в ../key.json
# ID облака и каталога - в переменных terraform.tfvars
provider "yandex" {
  service_account_key_file = var.sa_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}
