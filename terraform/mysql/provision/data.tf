data "hcs_vpc_subnets" "subnet" {
  vpc_id = var.vpc_id
  name   = var.subnet_name
}

locals {
  is_ha              = length(var.availability_zones) > 1
  generated_password = var.admin_password == null || var.admin_password == "" ? random_password.admin_password[0].result : var.admin_password
}
