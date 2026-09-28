output "username" {
  description = "Username for the binding account."
  value       = hcs_rds_mysql_account.account.name
}

output "password" {
  description = "Password for the binding account."
  value       = random_password.password.result
  sensitive   = true
}

output "hostname" {
  description = "Hostname (private IP) of the database."
  value       = var.hostname
}

output "port" {
  description = "Database port."
  value       = var.port
}

output "uri" {
  description = "Connection URI."
  value       = local.connection_uri
  sensitive   = true
}

output "jdbcUrl" {
  description = "JDBC connection URL."
  value       = local.connection_jdbc_url
}
