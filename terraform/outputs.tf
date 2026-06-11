# outputs.tf - что выводится посл terraform apply

output "bastion_public_ip" {
  description = "IP бастиона. Вход: ssh -A ubuntu@<IP>"
  value       = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "alb_public_ip" {
  description = "IP сайта. Проверка: curl -v http://<IP>:80"
  value       = yandex_vpc_address.alb.external_ipv4_address[0].address
}

output "zabbix_url" {
  description = "Zabbix (логин Admin / zabbix)"
  value       = "http://${yandex_compute_instance.zabbix.network_interface[0].nat_ip_address}/"
}

output "kibana_url" {
  description = "Kibana"
  value       = "http://${yandex_compute_instance.kibana.network_interface[0].nat_ip_address}:5601"
}

output "web_private_ips" {
  description = "Приватные IP веб-серверов"
  value       = { for k, n in yandex_compute_instance.web : n.name => n.network_interface[0].ip_address }
}

output "ssh_to_bastion" {
  description = "Команда для входа на бастион"
  value       = "ssh -A ubuntu@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address}"
}
