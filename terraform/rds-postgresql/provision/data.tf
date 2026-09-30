data "hcs_vpcs" "vpc" {
  name = var.vpc_name
}

data "hcs_vpc_subnets" "subnet" {
  vpc_id = data.hcs_vpcs.vpc.vpcs[0].id
  name   = var.subnet_name
}

data "hcs_networking_secgroups" "secgroup" {
  name = var.security_group_name
}

locals {
  is_ha              = length(var.availability_zones) > 1
  generated_password = var.admin_password == null || var.admin_password == "" ? random_password.admin_password[0].result : var.admin_password
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
