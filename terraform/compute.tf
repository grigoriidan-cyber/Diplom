# compute.tf - виртуальные машины 6 штук
# bastion - точка входа по SSH, внешний IP
# web-a, web-b - веб-серверы в разных зонах,без внешних IP
# zabbix - мониторинг, внешний IP
# elastic - хранение логов, без внешнего IP
# kibana - просмотр логов, внешний IP

data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

locals {
  ssh_keys = "ubuntu:${trimspace(file(pathexpand(var.ssh_public_key_path)))}"

  # два одинаковых веб-сервера, отличаются только зоной
  web_zones = {
    a = { zone = "ru-central1-a", subnet_id = yandex_vpc_subnet.private-a.id }
    b = { zone = "ru-central1-b", subnet_id = yandex_vpc_subnet.private-b.id }
  }
}


# -------------------- bastion --------------------

resource "yandex_compute_instance" "bastion" {
  name                      = "bastion"
  hostname                  = "bastion"
  zone                      = "ru-central1-a"
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  scheduling_policy { preemptible = var.preemptible }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }

  metadata = {
    "ssh-keys"  = local.ssh_keys
    "user-data" = file("${path.module}/files/bastion-cloud-init.yaml")
  }
}


# -------------------- web-a, web-b (через for_each) --------------------
#             Так гораздо удобнее, чем хардкодить каждый Веб

resource "yandex_compute_instance" "web" {
  for_each = local.web_zones

  name                      = "web-${each.key}"
  hostname                  = "web-${each.key}"
  zone                      = each.value.zone
  platform_id               = "standard-v3"
  allow_stopping_for_update = true


  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  scheduling_policy { preemptible = var.preemptible }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = each.value.subnet_id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = { "ssh-keys" = local.ssh_keys }
}


# -------------------- zabbix --------------------

resource "yandex_compute_instance" "zabbix" {
  name                      = "zabbix"
  hostname                  = "zabbix"
  zone                      = "ru-central1-a"
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  scheduling_policy { preemptible = var.preemptible }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.zabbix.id]
  }

  metadata = { "ssh-keys" = local.ssh_keys }
}


# -------------------- elasticsearch --------------------

resource "yandex_compute_instance" "elastic" {
  name                      = "elastic"
  hostname                  = "elastic"
  zone                      = "ru-central1-a"
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  scheduling_policy { preemptible = var.preemptible }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.elastic.id]
  }

  metadata = { "ssh-keys" = local.ssh_keys }
}


# -------------------- kibana --------------------

resource "yandex_compute_instance" "kibana" {
  name                      = "kibana"
  hostname                  = "kibana"
  zone                      = "ru-central1-a"
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  scheduling_policy { preemptible = var.preemptible }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 15
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kibana.id]
  }

  metadata = { "ssh-keys" = local.ssh_keys }
}
