resource "random_password" "admin_password" {
  count = var.admin_password == null || var.admin_password == "" ? 1 : 0

  length           = 24
  special          = true
  override_special = "!@#%^*-_=+?"
}

resource "hcs_rds_instance" "instance" {
  name              = var.instance_name
  flavor            = var.flavor
  vpc_id            = data.hcs_vpcs.vpc.vpcs[0].id
  subnet_id         = data.hcs_vpc_subnets.subnet.subnets[0].id
  security_group_id = data.hcs_networking_secgroups.secgroup.security_groups[0].id
  availability_zone = var.availability_zones

  ha_replication_mode = local.is_ha ? var.ha_replication_mode : null

  db {
    type     = "PostgreSQL"
    version  = var.pg_version
    password = local.generated_password
    port     = var.port
  }

  volume {
    type = var.volume_type
    size = var.storage_gb
  }

  backup_strategy {
    start_time = var.backup_start_time
    keep_days  = var.backup_keep_days
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}
