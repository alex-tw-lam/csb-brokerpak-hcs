resource "hcs_elb_loadbalancer" "loadbalancer" {
  name = var.loadbalancer_name

  vpc_id         = data.hcs_vpcs.vpc.vpcs[0].id
  ipv4_subnet_id = local.ipv4_subnet_id
  ipv4_address   = var.ipv4_address

  l4_flavor_id = var.l4_flavor_id
  l7_flavor_id = var.l7_flavor_id

  iptype                = var.allocate_eip ? var.eip_iptype : null
  bandwidth_charge_mode = var.allocate_eip ? "traffic" : null
  sharetype             = var.allocate_eip ? "PER" : null
  bandwidth_size        = var.allocate_eip ? var.bandwidth_size : null

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcs_elb_listener" "listener" {
  name            = "${var.loadbalancer_name}-listener"
  protocol        = var.listener_protocol
  protocol_port   = var.listener_port
  loadbalancer_id = hcs_elb_loadbalancer.loadbalancer.id
}

resource "hcs_elb_pool" "pool" {
  name        = "${var.loadbalancer_name}-pool"
  protocol    = var.listener_protocol == "HTTPS" ? "HTTP" : var.listener_protocol
  lb_method   = var.lb_method
  listener_id = hcs_elb_listener.listener.id
}

resource "hcs_elb_member" "member" {
  for_each = { for m in var.backend_members : "${m.address}:${m.port}" => m }

  pool_id       = hcs_elb_pool.pool.id
  address       = each.value.address
  protocol_port = each.value.port
  subnet_id     = local.ipv4_subnet_id
}
