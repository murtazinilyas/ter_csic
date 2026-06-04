output "vm_info" {
  value = {
    count = [
      for i in yandex_compute_instance.count : {
      name = i.name
      id = i.id
      fqdn = i.fqdn
      }
    ]
    for_each = [
      for i in yandex_compute_instance.for_each : {
      name = i.name
      id = i.id
      fqdn = i.fqdn
      }
    ]
  }
}