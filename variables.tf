variable "cloud_id" {
  type        = string
  default = "b1geap6dpsnun6sh70qj"
}

variable "folder_id" {
  type        = string
  default = "b1gfjo6em0ve76o982vg"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
}
variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network&subnet name"
}

variable "vm_web_image_id" {
  type        = string
  default = "ubuntu-2004-lts"
}

variable "vm_web_name" {
  type        = string
  default = "mia-web"
}

variable "vm_web_platform_id" {
  type        = string
  default = "standard-v4a"
}

variable "vm_web_resources" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
}

variable "each_vm" {
  type = list(object({  vm_name=string,  platform_id=string, cpu=number, ram=number, core_fraction=number, disk_volume=number }))
  default = [{
    vm_name = "mia-main"
    platform_id = "standard-v3"
    cpu = 2
    ram = 2
    core_fraction = 50
    disk_volume = 10
  },
  {
    vm_name = "mia-replica"
    platform_id = "standard-v4a"
    cpu = 2
    ram = 1
    core_fraction = 20
    disk_volume = 10
  }]
}

variable "vm_disk" {
  type = map(any)
  default = {
    vm_name       = "mia-storage"
    disk_name     = "mia-hdd"
    platform_id   = "standard-v4a"
    cores         = 2
    memory        = 1
    core_fraction = 20
    size          = 1
    type          = "network-hdd"
  }
}

variable "jh" {
  type = map(any)
  default = {
    vm_name       = "mia-jh"
    platform_id   = "standard-v4a"
    cores         = 2
    memory        = 1
    core_fraction = 20
    size          = 5
    type          = "network-hdd"
  }
}