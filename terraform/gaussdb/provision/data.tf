data "hcs_vpc_subnets" "subnet" {
  vpc_id = var.vpc_id
  name   = var.subnet_name
}

locals {
  availability_zone  = join(",", var.availability_zones)
  generated_password = var.password == null || var.password == "" ? random_password.password[0].result : var.password
}
