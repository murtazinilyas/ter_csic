resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/hosts.tftpl",
    {
      jump_host  = [yandex_compute_instance.jump_host]
      webservers = yandex_compute_instance.count
      databases  = yandex_compute_instance.for_each
      storage    = [yandex_compute_instance.disk_vm]
    }
  )
  filename = "${abspath(path.module)}/hosts.cfg"
}