# security.tf - группы безопасности (фаервол)
# Открываем только те порты,которые реально нужны.

locals {
  my_ip     = [for ip in var.trusted_ips : "${ip}/32"] # белый список IP
  local_net = ["10.10.0.0/16", "10.20.0.0/16"] # внутренняя сеть
}


# ---- Бастион: только SSH ----

resource "yandex_vpc_security_group" "bastion" {
  name       = "sg-bastion"
  network_id = yandex_vpc_network.diplom.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = local.my_ip
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


# ---- Балансировщик: 80 для всех ----

resource "yandex_vpc_security_group" "alb" {
  name       = "sg-alb"
  network_id = yandex_vpc_network.diplom.id

  ingress {
    protocol       = "TCP"
    description    = "http"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "healthcheck"
    from_port         = 0
    to_port           = 65535
    predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


# ---- Веб-серверы: 80 от балансировщика, 22 от бастиона, 10050 zabbix ----

resource "yandex_vpc_security_group" "web" {
  name       = "sg-web"
  network_id = yandex_vpc_network.diplom.id

  ingress {
    protocol          = "TCP"
    description       = "http от балансировщика (healthcheck)"
    port              = 80
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    protocol          = "TCP"
    description       = "http от балансировщика"
    port              = 80
    security_group_id = yandex_vpc_security_group.alb.id
  }

  ingress {
    protocol          = "TCP"
    description       = "ssh от бастиона"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix agent"
    port           = 10050
    v4_cidr_blocks = local.local_net
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


# ---- Zabbix: 80 (веб), 10051 (метрики), 22 (ssh) ----

resource "yandex_vpc_security_group" "zabbix" {
  name       = "sg-zabbix"
  network_id = yandex_vpc_network.diplom.id

  ingress {
    protocol       = "TCP"
    description    = "веб-морда"
    port           = 80
    v4_cidr_blocks = local.my_ip
  }

  ingress {
    protocol       = "TCP"
    description    = "метрики от агентов"
    port           = 10051
    v4_cidr_blocks = local.local_net
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix agent"
    port           = 10050
    v4_cidr_blocks = local.local_net
  }

  ingress {
    protocol          = "TCP"
    description       = "ssh от бастиона"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


# ---- Elasticsearch: 9200 изнутри, 22 от бастиона ----

resource "yandex_vpc_security_group" "elastic" {
  name       = "sg-elastic"
  network_id = yandex_vpc_network.diplom.id

  ingress {
    protocol       = "TCP"
    description    = "elastic API"
    port           = 9200
    v4_cidr_blocks = local.local_net
  }

  ingress {
    protocol          = "TCP"
    description       = "ssh от бастиона"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix agent"
    port           = 10050
    v4_cidr_blocks = local.local_net
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


# ---- Kibana: 5601 с моего IP, 22 от бастиона ----

resource "yandex_vpc_security_group" "kibana" {
  name       = "sg-kibana"
  network_id = yandex_vpc_network.diplom.id

  ingress {
    protocol       = "TCP"
    description    = "kibana"
    port           = 5601
    v4_cidr_blocks = local.my_ip
  }

  ingress {
    protocol          = "TCP"
    description       = "ssh от бастиона"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix agent"
    port           = 10050
    v4_cidr_blocks = local.local_net
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
