output "instance_id" {
  description = "ID of the ECS instance."
  value       = var.instance_id
}

output "name" {
  description = "Name of the ECS instance."
  value       = var.name
}

output "private_ip" {
  description = "Private IPv4 address of the instance."
  value       = var.private_ip
}

output "public_ip" {
  description = "Public IPv4 address of the instance."
  value       = var.public_ip
}
