resource "random_password" "password" {
  count = var.password == null || var.password == "" ? 1 : 0

  length           = 24
  special          = true
  override_special = "!@#%^*-_=+?"
}

resource "hcs_dcs_instance" "instance" {
  name               = var.instance_name
  engine             = "Redis"
  engine_version     = var.engine_version
  capacity           = var.capacity
  flavor             = local.flavor
  availability_zones = local.availability_zones

  vpc_id    = var.vpc_id
  subnet_id = data.hcs_vpc_subnets.subnet.subnets[0].id

  security_group_id = var.security_group_id
  port              = var.port
  password          = local.generated_password
  description       = var.description
  tags              = local.tags

  lifecycle {
    prevent_destroy = true
  }
}
