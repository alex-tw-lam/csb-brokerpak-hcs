resource "random_password" "password" {
  count = var.password == null || var.password == "" ? 1 : 0

  length           = 24
  special          = true
  override_special = "!@#%^*-_=+?"
}

resource "hcs_gaussdb_opengauss_instance" "instance" {
  name     = var.instance_name
  flavor   = var.flavor
  password = local.generated_password

  vpc_id          = data.hcs_vpcs.vpc.vpcs[0].id
  subnet_id       = data.hcs_vpc_subnets.subnet.subnets[0].id
  port            = var.port
  solution        = var.solution
  sharding_num    = var.sharding_num
  coordinator_num = var.coordinator_num

  security_group_id = length(data.hcs_networking_secgroups.secgroup) > 0 ? data.hcs_networking_secgroups.secgroup[0].security_groups[0].id : null

  availability_zone = local.availability_zone

  ha {
    mode                 = var.ha_mode
    replication_mode     = "sync"
    consistency          = var.ha_consistency
    consistency_protocol = var.ha_consistency_protocol
  }

  volume {
    type = var.volume_type
    size = var.volume_size
  }

  dynamic "datastore" {
    for_each = var.datastore_version != null && var.datastore_version != "" ? [1] : []
    content {
      engine  = "GaussDB(for openGauss)"
      version = var.datastore_version
    }
  }

  backup_strategy {
    start_time = var.backup_start_time
    keep_days  = var.backup_keep_days
  }

  lifecycle {
    prevent_destroy = true
  }
}
