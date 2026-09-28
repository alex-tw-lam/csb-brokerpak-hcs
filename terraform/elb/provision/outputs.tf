output "loadbalancer_id" {
  description = "ID of the load balancer."
  value       = hcs_elb_loadbalancer.loadbalancer.id
}

output "name" {
  description = "Name of the load balancer."
  value       = hcs_elb_loadbalancer.loadbalancer.name
}

output "vip_address" {
  description = "Private VIP address (only populated when ipv4_address was set explicitly)."
  value       = local.vip_address
}

output "public_ip" {
  description = "EIP address of the load balancer."
  value       = hcs_elb_loadbalancer.loadbalancer.ipv4_eip
}

output "listener_port" {
  description = "Listener frontend port."
  value       = var.listener_port
}

output "protocol" {
  description = "Listener protocol."
  value       = var.listener_protocol
}

output "region" {
  description = "HCS region."
  value       = var.region
}

output "cloud" {
  description = "HCS cloud domain."
  value       = var.cloud
}
