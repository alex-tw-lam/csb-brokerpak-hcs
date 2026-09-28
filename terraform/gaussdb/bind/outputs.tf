locals {
  first_endpoint = var.endpoints != "" ? var.endpoints : ""
  hostname       = local.first_endpoint != "" ? split(":", local.first_endpoint)[0] : ""
  endpoints_list = var.endpoints != "" ? split(",", var.endpoints) : []
}

output "username" {
  description = "Administrator username."
  value       = var.username
}

output "password" {
  description = "Administrator password."
  value       = var.password
  sensitive   = true
}

output "endpoints" {
  description = "Connection endpoints as host:port strings."
  value       = local.endpoints_list
}

output "hostname" {
  description = "Host of the first connection endpoint."
  value       = local.hostname
}

output "port" {
  description = "Database port."
  value       = var.port
}

output "uri" {
  description = "PostgreSQL-wire compatible connection URI."
  value       = "postgresql://${var.username}:${var.password}@${local.first_endpoint}/postgres"
  sensitive   = true
}
