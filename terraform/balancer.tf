# balancer.tf - балансировщик нагрузки (ALB)
#
# Цепочка: IP -> Target Group (web-a, web-b) -> Backend Group (healthcheck) -> Router -> ALB
# Проверяет серверы каждые 5 сек, упавший исключает через 3 провала.

# Зарезервированный IP
resource "yandex_vpc_address" "alb" {
  name = "alb-public-ip"
  external_ipv4_address { zone_id = var.zone }
}

# Target Group - список веб-серверов
resource "yandex_alb_target_group" "web" {
  name = "web-target-group"

  dynamic "target" {
    for_each = yandex_compute_instance.web
    content {
      subnet_id  = target.value.network_interface[0].subnet_id
      ip_address = target.value.network_interface[0].ip_address
    }
  }
}

# Backend Group - healthcheck /
resource "yandex_alb_backend_group" "web" {
  name = "web-backend-group"

  http_backend {
    name             = "web-http-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web.id]

    healthcheck {
      timeout             = "3s"
      interval            = "5s"
      healthy_threshold   = 2
      unhealthy_threshold = 3
      http_healthcheck { path = "/" }
    }
  }
}

# HTTP Router - все запросы кидаем в backend group
resource "yandex_alb_http_router" "web" {
  name = "web-router"
}

resource "yandex_alb_virtual_host" "web" {
  name           = "web-vhost"
  http_router_id = yandex_alb_http_router.web.id

  route {
    name = "root"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web.id
      }
    }
  }
}

# Сам балансировщик ( 80 порт)
resource "yandex_alb_load_balancer" "web" {
  name               = "web-alb"
  network_id         = yandex_vpc_network.diplom.id
  security_group_ids = [yandex_vpc_security_group.alb.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public-a.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.public-b.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {
          address = yandex_vpc_address.alb.external_ipv4_address[0].address
        }
      }
      ports = [80]
    }
    http {
      handler { http_router_id = yandex_alb_http_router.web.id }
    }
  }
}
