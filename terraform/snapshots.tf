#snapshots.tf - резервное копирование
# Ежедневные снапшоты дисков всех ВМ в 02:00, храняться неделю.

resource "yandex_compute_snapshot_schedule" "daily" {
  name = "daily-snapshots"

  schedule_policy {
    expression = "0 2 * * *"
  }

  retention_period = "168h"

  snapshot_spec {
    description = "Ежедневный снапшот"
  }

  disk_ids = concat(
    [
      yandex_compute_instance.bastion.boot_disk[0].disk_id,
      yandex_compute_instance.zabbix.boot_disk[0].disk_id,
      yandex_compute_instance.elastic.boot_disk[0].disk_id,
      yandex_compute_instance.kibana.boot_disk[0].disk_id,
    ],
    [for n in yandex_compute_instance.web : n.boot_disk[0].disk_id]
  )
}
