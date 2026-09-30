data "hcs_vpc_subnets" "subnet" {
  vpc_id = var.vpc_id
  name   = var.subnet_name
}

data "hcs_ims_images" "image" {
  name = var.image_name
}

data "hcs_ecs_compute_flavors" "flavors" {
  availability_zone = var.availability_zone
  cpu_core_count    = var.cores
  memory_size       = var.memory_gb
}

data "hcs_networking_secgroups" "secgroup" {
  for_each = toset([var.security_group_name])
  name     = each.value
}

locals {
  flavor_id          = var.flavor != null && var.flavor != "" ? var.flavor : data.hcs_ecs_compute_flavors.flavors.ids[0]
  security_group_ids = [for name in [var.security_group_name] : data.hcs_networking_secgroups.secgroup[name].security_groups[0].id]
  generated_password = var.admin_pass == null || var.admin_pass == "" ? random_password.admin_pass[0].result : var.admin_pass
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
