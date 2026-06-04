# Домашнее задание к занятию «Управляющие конструкции в коде Terraform»

### Задание 1

1. Изучите проект.
2. Инициализируйте проект, выполните код. 


Приложите скриншот входящих правил «Группы безопасности» в ЛК Yandex Cloud .

### Решение 1

![1](https://github.com/murtazinilyas/ter_csic/blob/main/screenshots/t1.png)

------

### Задание 2

1. Создайте файл count-vm.tf. Опишите в нём создание двух **одинаковых** ВМ  web-1 и web-2 (не web-0 и web-1) с минимальными параметрами, используя мета-аргумент **count loop**. Назначьте ВМ созданную в первом задании группу безопасности.(как это сделать узнайте в документации провайдера yandex/compute_instance )
2. Создайте файл for_each-vm.tf. Опишите в нём создание двух ВМ для баз данных с именами "main" и "replica" **разных** по cpu/ram/disk_volume , используя мета-аргумент **for_each loop**. Используйте для обеих ВМ одну общую переменную типа:
```
variable "each_vm" {
  type = list(object({  vm_name=string, cpu=number, ram=number, disk_volume=number }))
}
```  
При желании внесите в переменную все возможные параметры.

3. ВМ, описанные в файле count-vm.tf, должны создаваться после ВМ, описанных в файле for_each-vm.tf.
4. Используйте функцию file в local-переменной для считывания ключа ~/.ssh/id_rsa.pub и его последующего использования в блоке metadata, взятому из ДЗ 2.
5. Инициализируйте проект, выполните код.

### Решение 2

0. Чтобы в процессе решения домашней работы не упираться в квоту на выдачу nat-адресов создал ВМ [**jump_host**](https://github.com/murtazinilyas/ter_csic/blob/main/jump_host.tf):

```hcl
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
```

В блоке с сетями добавил **nat_gateway** и **route_table** для выхода в интернет машинам создаваемым далее:

```hcl
resource "yandex_vpc_subnet" "develop" {
...
  route_table_id = yandex_vpc_route_table.rt.id #Добавил в блок с подсетью айди route_table
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
```

Также в [**main.tf**](https://github.com/murtazinilyas/ter_csic/blob/main/main.tf) описал ресурс **yandex_compute_image** для его использования всеми создаваемыми в процессе ВМ:

```hcl
data "yandex_compute_image" "ubuntu" {
  family = var.vm_web_image_id
}
```

1,3. [**count-vm.tf**](https://github.com/murtazinilyas/ter_csic/blob/main/count-vm.tf):

```hcl
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
```

2. [**for_each-vm.tf**](https://github.com/murtazinilyas/ter_csic/blob/main/for_each-vm.tf):

```hcl
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
```

4. [**locals.tf**](https://github.com/murtazinilyas/ter_csic/blob/main/locals.tf):

```hcl
locals {
  sshkey = file("~/.ssh/id_ed25519.pub")
}
```

------

### Задание 3

1. Создайте 3 одинаковых виртуальных диска размером 1 Гб с помощью ресурса yandex_compute_disk и мета-аргумента count в файле **disk_vm.tf** .
2. Создайте в том же файле **одиночную**(использовать count или for_each запрещено из-за задания №4) ВМ c именем "storage"  . Используйте блок **dynamic secondary_disk{..}** и мета-аргумент for_each для подключения созданных вами дополнительных дисков.

### Решение 3

[**disk_vm.tf**](https://github.com/murtazinilyas/ter_csic/blob/main/disk_vm.tf):

```hcl
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
```

------

### Задание 4

1. В файле ansible.tf создайте inventory-файл для ansible.
Используйте функцию tepmplatefile и файл-шаблон для создания ansible inventory-файла из лекции.
Готовый код возьмите из демонстрации к лекции [**demonstration2**](https://github.com/netology-code/ter-homeworks/tree/main/03/demo).
Передайте в него в качестве переменных группы виртуальных машин из задания 2.1, 2.2 и 3.2, т. е. 5 ВМ.
2. Инвентарь должен содержать 3 группы и быть динамическим, т. е. обработать как группу из 2-х ВМ, так и 999 ВМ.
3. Добавьте в инвентарь переменную  [**fqdn**](https://cloud.yandex.ru/docs/compute/concepts/network#hostname).
``` 
[webservers]
web-1 ansible_host=<внешний ip-адрес> fqdn=<полное доменное имя виртуальной машины>
web-2 ansible_host=<внешний ip-адрес> fqdn=<полное доменное имя виртуальной машины>

[databases]
main ansible_host=<внешний ip-адрес> fqdn=<полное доменное имя виртуальной машины>
replica ansible_host<внешний ip-адрес> fqdn=<полное доменное имя виртуальной машины>

[storage]
storage ansible_host=<внешний ip-адрес> fqdn=<полное доменное имя виртуальной машины>
```
Пример fqdn: ```web1.ru-central1.internal```(в случае указания переменной hostname(не путать с переменной name)); ```fhm8k1oojmm5lie8i22a.auto.internal```(в случае отсутвия перменной hostname - автоматическая генерация имени,  зона изменяется на auto). нужную вам переменную найдите в документации провайдера или terraform console.

4. Выполните код. Приложите скриншот получившегося файла. 

Для общего зачёта создайте в вашем GitHub-репозитории новую ветку terraform-03. Закоммитьте в эту ветку свой финальный код проекта, пришлите ссылку на коммит.   
**Удалите все созданные ресурсы**.

### Решение 4

[**ansible.tf**](https://github.com/murtazinilyas/ter_csic/blob/main/ansible.tf):
```hcl
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
```

[**hosts.tftpl**](https://github.com/murtazinilyas/ter_csic/blob/main/hosts.tftpl) сразу с выполненным условием задания 6:

```hcl
[jump_host]

%{~ for i in jump_host ~}
${i["name"]}   ansible_host=${i["network_interface"][0]["nat_ip_address"]} fqdn=${i["fqdn"]}

%{~ endfor ~}

[webservers]

%{~ for i in webservers ~}
${i["name"]}   ansible_host=${i["network_interface"][0]["nat_ip_address"] != "" ? i["network_interface"][0]["nat_ip_address"] : i["network_interface"][0]["ip_address"]} fqdn=${i["fqdn"]}

%{~ endfor ~}

[databases]

%{~ for i in databases ~}
${i["name"]}   ansible_host=${i["network_interface"][0]["nat_ip_address"] != "" ? i["network_interface"][0]["nat_ip_address"] : i["network_interface"][0]["ip_address"]} fqdn=${i["fqdn"]}

%{~ endfor ~}

[storage]

%{~ for i in storage ~}
${i["name"]}   ansible_host=${i["network_interface"][0]["nat_ip_address"] != "" ? i["network_interface"][0]["nat_ip_address"] : i["network_interface"][0]["ip_address"]} fqdn=${i["fqdn"]}

%{~ endfor ~}

%{~ for i in jump_host ~}

[webservers:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q ubuntu@${i["network_interface"][0]["nat_ip_address"]}"'

[databases:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q ubuntu@${i["network_interface"][0]["nat_ip_address"]}"'

[storage:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q ubuntu@${i["network_interface"][0]["nat_ip_address"]}"'

%{~ endfor ~}
```

Скриншот получившегося файла **hosts.cfg**:

![4](https://github.com/murtazinilyas/ter_csic/blob/main/screenshots/t4.png)

------

### Задание 5* (необязательное)
1. Напишите output, который отобразит ВМ из ваших ресурсов count и for_each в виде списка словарей :
``` 
[
 {
  "name" = 'имя ВМ1'
  "id"   = 'идентификатор ВМ1'
  "fqdn" = 'Внутренний FQDN ВМ1'
 },
 {
  "name" = 'имя ВМ2'
  "id"   = 'идентификатор ВМ2'
  "fqdn" = 'Внутренний FQDN ВМ2'
 },
 ....
...итд любое количество ВМ в ресурсе(те требуется итерация по ресурсам, а не хардкод) !!!!!!!!!!!!!!!!!!!!!
]
```
Приложите скриншот вывода команды ```terrafrom output```.

### Решение 5

[**outputs.tf**](https://github.com/murtazinilyas/ter_csic/blob/main/outputs.tf):

```hcl
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
```

![5](https://github.com/murtazinilyas/ter_csic/blob/main/screenshots/t5.png)

------

### Задание 6* (необязательное)

1. Используя null_resource и local-exec, примените ansible-playbook к ВМ из ansible inventory-файла.
Готовый код возьмите из демонстрации к лекции [**demonstration2**](https://github.com/netology-code/ter-homeworks/tree/main/03/demo).
3. Модифицируйте файл-шаблон hosts.tftpl. Необходимо отредактировать переменную ```ansible_host="<внешний IP-address или внутренний IP-address если у ВМ отсутвует внешний адрес>```.

Для проверки работы уберите у ВМ внешние адреса(nat=false). Этот вариант используется при работе через bastion-сервер.
Для зачёта предоставьте код вместе с основной частью задания.

### Решение 6

В файл [**main.tf**](https://github.com/murtazinilyas/ter_csic/blob/terraform-03/main.tf) добавил **null_resource**:

```hcl
resource "null_resource" "ansible" {
  provisioner "local-exec" {
    command = "sleep 30 && ansible-playbook test.yml -i hosts.cfg"
  }
  depends_on = [yandex_compute_instance.count]
}
```

Перед запуском ансибл-плейбука добавил команду **sleep 30** для ожидания инициализации на целевых ВМ ssh-демона.

Шаблон [**hosts.tftpl**](https://github.com/murtazinilyas/ter_csic/blob/terraform-03/hosts.tftpl) создал в процессе выполнения задания 4 с текущими условиями.

### Правила приёма работы

В своём git-репозитории создайте новую ветку terraform-03, закоммитьте в эту ветку свой финальный код проекта. Ответы на задания и необходимые скриншоты оформите в md-файле в ветке terraform-03.

В качестве результата прикрепите ссылку на ветку terraform-03 в вашем репозитории.

Важно. Удалите все созданные ресурсы.

### Задание 7* (необязательное)
Ваш код возвращает вам следущий набор данных: 
```
> local.vpc
{
  "network_id" = "enp7i560tb28nageq0cc"
  "subnet_ids" = [
    "e9b0le401619ngf4h68n",
    "e2lbar6u8b2ftd7f5hia",
    "b0ca48coorjjq93u36pl",
    "fl8ner8rjsio6rcpcf0h",
  ]
  "subnet_zones" = [
    "ru-central1-a",
    "ru-central1-b",
    "ru-central1-c",
    "ru-central1-d",
  ]
}
```
Предложите выражение в terraform console, которое удалит из данной переменной 3 элемент из: subnet_ids и subnet_zones.(значения могут быть любыми) Образец конечного результата:
```
> <некое выражение>
{
  "network_id" = "enp7i560tb28nageq0cc"
  "subnet_ids" = [
    "e9b0le401619ngf4h68n",
    "e2lbar6u8b2ftd7f5hia",
    "fl8ner8rjsio6rcpcf0h",
  ]
  "subnet_zones" = [
    "ru-central1-a",
    "ru-central1-b",
    "ru-central1-d",
  ]
}
```
### Решение 7

Получилось следующее выражение:

```
merge(local.vpc, {subnet_ids = concat(slice(local.vpc.subnet_ids, 0, 1), slice(local.vpc.subnet_ids, 2, length(local.vpc.subnet_ids))), subnet_zones = concat(slice(local.vpc.subnet_zones, 0, 3), slice(local.vpc.subnet_zones, 4, length(local.vpc.subnet_zones)))})
```

Оно удаляет 2ой элемент из subnet_ids и 4ый элемент из subnet_zones

### Задание 8* (необязательное)
Идентифицируйте и устраните намеренно допущенную в tpl-шаблоне ошибку. Обратите внимание, что terraform сам сообщит на какой строке и в какой позиции ошибка!
```
[webservers]
%{~ for i in webservers ~}
${i["name"]} ansible_host=${i["network_interface"][0]["nat_ip_address"] platform_id=${i["platform_id "]}}
%{~ endfor ~}
```

### Решение 8

Ошибка в пробеле после **platform_id**, правильно будет написать

```
[webservers]
%{~ for i in webservers ~}
${i["name"]} ansible_host=${i["network_interface"][0]["nat_ip_address"] platform_id=${i["platform_id"]}}
%{~ endfor ~}
```

### Задание 9* (необязательное)
Напишите  terraform выражения, которые сформируют списки:
1. ["rc01","rc02","rc03","rc04",rc05","rc06",rc07","rc08","rc09","rc10....."rc99"] те список от "rc01" до "rc99"
2. ["rc01","rc02","rc03","rc04",rc05","rc06","rc11","rc12","rc13","rc14",rc15","rc16","rc19"....."rc96"] те список от "rc01" до "rc96", пропуская все номера, заканчивающиеся на "0","7", "8", "9", за исключением "rc19"

### Решение 9

1.
```
[for i in range(1, 100) : format("rc%02d", i)]
```

2.
```
[for i in range(1, 97) : format("rc%02d", i) if ((i % 10 != 0 && i % 10 != 7 && i % 10 != 8 && i % 10 != 9) || i == 19)]
```
