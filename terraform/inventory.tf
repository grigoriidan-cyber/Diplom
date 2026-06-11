# inventory.tf - инвентарь для Ansible
# Генерирует ../ansible/inventory.ini из созданных ВМ.
# Имена - внутренние FQDN (.ru-central1.internal).
# Файл перезаписывается при каждом terraform apply.

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/inventory.tftpl", {
    web_hosts    = join("\n", [for n in yandex_compute_instance.web : "${n.hostname}.ru-central1.internal"])
    zabbix_host  = "${yandex_compute_instance.zabbix.hostname}.ru-central1.internal"
    elastic_host = "${yandex_compute_instance.elastic.hostname}.ru-central1.internal"
    kibana_host  = "${yandex_compute_instance.kibana.hostname}.ru-central1.internal"
  })
}
