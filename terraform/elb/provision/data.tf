data "hcs_vpc_subnets" "subnet" {
  vpc_id = var.vpc_id
  name   = var.subnet_name
}

locals {
  ipv4_subnet_id = data.hcs_vpc_subnets.subnet.subnets[0].ipv4_subnet_id
  vip_address    = var.ipv4_address == null || var.ipv4_address == "" ? "" : var.ipv4_address
}
