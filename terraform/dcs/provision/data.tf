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


locals {
  request_context = var.request_context_json != "" ? try(jsondecode(var.request_context_json), {}) : {}

  context_tags = {
    for key in ["namespace", "instance_name"] :
    key => try(local.request_context[key], null)
    if try(local.request_context[key], null) != null
  }

  originating_identity = var.originating_identity_json != "" ? try(jsondecode(var.originating_identity_json), {}) : {}

  identity_tags = {
    for key, expr in { created_by = try(local.originating_identity["username"], null) } :
    key => expr if expr != null
  }

  tags = merge(var.labels, local.context_tags, local.identity_tags)
}
