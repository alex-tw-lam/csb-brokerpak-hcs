output "loadbalancer_id" {
  description = "ID of the load balancer."
  value       = var.loadbalancer_id
}

output "vip_address" {
  description = "Private VIP address (only populated when ipv4_address was set explicitly)."
  value       = var.vip_address
}

output "public_ip" {
  description = "EIP address of the load balancer."
  value       = var.public_ip
}

output "listener_port" {
  description = "Listener frontend port."
  value       = var.listener_port
}

output "protocol" {
  description = "Listener protocol."
  value       = var.protocol
}
