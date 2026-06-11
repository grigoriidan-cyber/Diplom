#network.tf - сеть: VPC, подсети, NAT

resource "yandex_vpc_network" "diplom" {
  name = "diplom-network"
}

# --- Публичные подсети ---

resource "yandex_vpc_subnet" "public-a" {
  name           = "public-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

resource "yandex_vpc_subnet" "public-b" {
  name           = "public-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.10.2.0/24"]
}

# --- Приватные подсети (интернет через NAT) ---

resource "yandex_vpc_subnet" "private-a" {
  name           = "private-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.20.1.0/24"]
  route_table_id = yandex_vpc_route_table.private-rt.id
}

resource "yandex_vpc_subnet" "private-b" {
  name           = "private-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.20.2.0/24"]
  route_table_id = yandex_vpc_route_table.private-rt.id
}

# --- NAT-шлюз и таблица маршрутов ---

resource "yandex_vpc_gateway" "nat-gw" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private-rt" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.diplom.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat-gw.id
  }
}
