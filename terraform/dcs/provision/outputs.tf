output "instance_id" {
  description = "ID of the DCS instance."
  value       = hcs_dcs_instance.instance.id
}

output "name" {
  description = "Name of the DCS instance."
  value       = hcs_dcs_instance.instance.name
}

output "domain_name" {
  description = "Connection domain name of the instance."
  value       = hcs_dcs_instance.instance.domain_name
}

output "port" {
  description = "Connection port."
  value       = var.port
}

output "password" {
  description = "Instance access password."
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
