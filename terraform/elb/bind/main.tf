resource "hcs_elb_member" "member" {
  pool_id       = var.pool_id
  address       = var.address
  protocol_port = var.port
  subnet_id     = var.ipv4_subnet_id
  weight        = var.weight
}

resource "hcs_elb_monitor" "monitor" {
  count = var.enable_health_check ? 1 : 0

  pool_id     = var.pool_id
  protocol    = var.protocol == "HTTP" || var.protocol == "HTTPS" ? "HTTP" : "TCP"
  port        = var.port
  interval    = 10
  timeout     = 5
  max_retries = 3
}
