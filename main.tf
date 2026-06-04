resource "yandex_vpc_network" "develop" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "develop" {
  name           = var.vpc_name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = var.default_cidr
  route_table_id = yandex_vpc_route_table.rt.id
}

data "yandex_compute_image" "ubuntu" {
  family = var.vm_web_image_id
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = var.vpc_name
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name       = var.vpc_name
  network_id = yandex_vpc_network.develop.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}