data "hcs_vpc_subnets" "subnet" {
  vpc_id = var.vpc_id
  name   = var.subnet_name
}

data "hcs_dcs_flavors" "flavors" {
  engine         = "Redis"
  engine_version = var.engine_version
  cache_mode     = var.cache_mode
  capacity       = var.capacity
}

locals {
  flavor             = var.flavor != null && var.flavor != "" ? var.flavor : data.hcs_dcs_flavors.flavors.flavors[0].name
  availability_zones = var.standby_availability_zone != null && var.standby_availability_zone != "" ? [var.availability_zone, var.standby_availability_zone] : [var.availability_zone]
  generated_password = var.password == null || var.password == "" ? random_password.password[0].result : var.password
}
