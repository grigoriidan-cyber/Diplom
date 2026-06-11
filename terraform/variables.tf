# переменные - сюда Terraform подставляет значения из terraform.tfvars
# если чего-то нет ни в tfvars ни в default - спросит при запуске

variable "cloud_id" {
  description = "ID облака. Где взять:открыть терминал, вбить yc config list, скопировать cloud-id"
  type        = string
}

variable "folder_id" {
  description = "ID каталога. Там же: yc config list folder-id"
  type        = string
}

variable "trusted_ips" {
  description = "Доверенные IP для белого списка (SSH, Zabbix, Kibana). Свой узнать: открыть 2ip и скопировать"
  type        = list(string)
  sensitive   = true
}

variable "zone" {
  description = "Зона датацентра по умолчанию Москва - ru-central1-a"
  type        = string
  default     = "ru-central1-a"
}

variable "sa_key_file" {
  description = "Файл-ключ для входа в облако.Лежит в корне проекта."
  type        = string
  default     = "../key.json"
}

variable "ssh_public_key_path" {
  description = "SSH-ключ."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "preemptible" {
  description = "Дешёвые ВМ (true). живут не больше суток. Перед сдачей надо бы не забыть поставить false"
  type        = bool
  default     = false
}

variable "image_family" {
  description = "Операционка. Ubuntu 22.04."
  type        = string
  default     = "ubuntu-2204-lts"
}
