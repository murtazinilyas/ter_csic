resource "yandex_compute_disk" "hdd" {
  count = 3
  name  = "${var.vm_disk.disk_name}-${count.index+1}"
  size  = var.vm_disk.size
  type  = var.vm_disk.type
}

resource "yandex_compute_instance" "disk_vm" {
  name        = var.vm_disk.vm_name
  hostname    = var.vm_disk.vm_name
  platform_id = var.vm_disk.platform_id
  resources {
    cores         = var.vm_disk.cores
    memory        = var.vm_disk.memory
    core_fraction = var.vm_disk.core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
    }
  }

  dynamic "secondary_disk" {
    for_each = { for disk in yandex_compute_disk.hdd : disk.name => disk }
    content {
      device_name = secondary_disk.key
      disk_id     = secondary_disk.value.id
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

}