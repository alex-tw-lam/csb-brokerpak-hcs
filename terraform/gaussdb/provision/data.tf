data "hcs_vpcs" "vpc" {
  name = var.vpc_name
}

data "hcs_vpc_subnets" "subnet" {
  vpc_id = data.hcs_vpcs.vpc.vpcs[0].id
  name   = var.subnet_name
}

data "hcs_networking_secgroups" "secgroup" {
  count = var.security_group_name != null && var.security_group_name != "" ? 1 : 0
  name  = var.security_group_name
}

locals {
  availability_zone  = join(",", var.availability_zones)
  generated_password = var.password == null || var.password == "" ? random_password.password[0].result : var.password
}
