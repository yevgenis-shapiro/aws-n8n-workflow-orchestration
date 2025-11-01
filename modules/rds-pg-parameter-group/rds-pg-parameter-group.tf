locals {
  database_family = "${var.database-engine}${split(".", var.database-engine-version)[0]}"
}

resource "aws_db_parameter_group" "db-pg-parameter-group" {
  name   = "${var.environment-prefix}-${local.database_family}-parameter-group"
  family = local.database_family
  tags   = merge(var.tags, {
    Name = "${var.environment-prefix}-${local.database_family}"
  })

  parameter {
    name  = "effective_cache_size"
    value = var.effective-cache-size
  }

  parameter {
    name  = "maintenance_work_mem"
    value = var.maintenance-work-mem
  }

  parameter {
    name  = "max_connections"
    value = var.max-connections
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "shared_buffers"
    value = var.shared-buffers
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "work_mem"
    value = var.work-mem
  }
}