resource "random_password" "admin_pass" {
  count = var.admin_pass == null || var.admin_pass == "" ? 1 : 0

  length           = 16
  special          = true
  override_special = "!@#%^*-_=+?"
}

resource "hcs_ecs_compute_instance" "instance" {
  name              = var.instance_name
  image_id          = data.hcs_ims_images.image.images[0].id
  flavor_id         = local.flavor_id
  availability_zone = var.availability_zone

  security_group_ids = local.security_group_ids

  network {
    uuid = data.hcs_vpc_subnets.subnet.subnets[0].id
  }

  admin_pass = local.generated_password

  system_disk_type = var.system_disk_type
  system_disk_size = var.system_disk_size

  eip_type = var.allocate_eip ? var.eip_iptype : null

  dynamic "bandwidth" {
    for_each = var.allocate_eip ? [1] : []
    content {
      share_type = "PER"
      size       = var.bandwidth_size
    }
  }

  delete_disks_on_termination = true
  delete_eip_on_termination   = true
  user_data                   = var.user_data
  tags                        = local.tags

  lifecycle {
    prevent_destroy = true
  }
}
