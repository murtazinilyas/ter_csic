resource "yandex_compute_instance" "count" {
  count       = 2
  name        = "${var.vm_web_name}-${count.index+1}"
  hostname    = "${var.vm_web_name}-${count.index+1}"
  platform_id = var.vm_web_platform_id
  resources {
    cores         = var.vm_web_resources.cores
    memory        = var.vm_web_resources.memory
    core_fraction = var.vm_web_resources.core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = length(yandex_compute_instance.jump_host) > 0 ? false : true
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys = "ubuntu:${local.sshkey}"
  }

  depends_on = [yandex_compute_instance.for_each]

}