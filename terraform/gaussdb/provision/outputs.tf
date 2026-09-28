output "instance_id" {
  description = "ID of the GaussDB instance."
  value       = hcs_gaussdb_opengauss_instance.instance.id
}

output "name" {
  description = "Name of the GaussDB instance."
  value       = hcs_gaussdb_opengauss_instance.instance.name
}

output "endpoints" {
  description = "Connection endpoints as comma-joined host:port strings (HIL cannot pass lists through instance details)."
  value       = join(",", hcs_gaussdb_opengauss_instance.instance.endpoints)
}

output "private_ips" {
  description = "Private IP addresses as a comma-joined string."
  value       = join(",", hcs_gaussdb_opengauss_instance.instance.private_ips)
}

output "username" {
  description = "Administrator username."
  value       = hcs_gaussdb_opengauss_instance.instance.db_user_name
}

output "password" {
  description = "Administrator password."
  value       = local.generated_password
  sensitive   = true
}

output "port" {
  description = "Database port."
  value       = var.port
}

output "region" {
  description = "HCS region."
  value       = var.region
}

output "cloud" {
  description = "HCS cloud domain."
  value       = var.cloud
}
