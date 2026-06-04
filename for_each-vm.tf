resource "yandex_compute_instance" "for_each" {
  for_each = {for vm in var.each_vm : vm.vm_name => vm}
  name        = each.value.vm_name
  hostname    = each.value.vm_name
  platform_id = each.value.platform_id
  resources {
    cores         = each.value.cpu
    memory        = each.value.ram
    core_fraction = each.value.core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size = each.value.disk_volume
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