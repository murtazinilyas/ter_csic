resource "yandex_compute_instance" "jump_host" {
  name        = var.jh.vm_name
  hostname    = var.jh.vm_name
  platform_id = var.jh.platform_id
  resources {
    cores         = var.jh.cores
    memory        = var.jh.memory
    core_fraction = var.jh.core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = var.jh.size
      type     = var.jh.type
    }
  }

  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = true
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys = "ubuntu:${local.sshkey}"
  }

}