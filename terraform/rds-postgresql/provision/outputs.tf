output "instance_id" {
  description = "ID of the RDS instance."
  value       = hcs_rds_instance.instance.id
}

output "name" {
  description = "Name of the RDS instance."
  value       = hcs_rds_instance.instance.name
}

output "hostname" {
  description = "Private IP address of the instance."
  value       = hcs_rds_instance.instance.private_ips[0]
}

output "port" {
  description = "Database port."
  value       = var.port
}

output "username" {
  description = "Administrator username."
  value       = hcs_rds_instance.instance.db[0].user_name
}

output "password" {
  description = "Administrator password."
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
