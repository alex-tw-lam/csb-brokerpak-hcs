output "instance_id" {
  description = "ID of the ECS instance."
  value       = hcs_ecs_compute_instance.instance.id
}

output "name" {
  description = "Name of the ECS instance."
  value       = hcs_ecs_compute_instance.instance.name
}

output "private_ip" {
  description = "Private IPv4 address of the instance."
  value       = hcs_ecs_compute_instance.instance.network[0].fixed_ip_v4
}

output "public_ip" {
  description = "Public IPv4 address of the instance."
  value       = hcs_ecs_compute_instance.instance.public_ip
}

output "admin_password" {
  description = "Administrator password (generated when not provided at provision time)."
  value       = local.generated_password
  sensitive   = true
}

output "region" {
  description = "HCS region."
  value       = var.region
}

output "cloud" {
  description = "HCS cloud domain."
  value       = var.cloud
}

output "project_name" {
  description = "HCS project name."
  value       = var.project_name
}
