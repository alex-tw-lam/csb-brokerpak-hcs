output "host" {
  description = "Connection domain name of the instance."
  value       = var.domain_name
}

output "port" {
  description = "Connection port."
  value       = var.port
}

output "password" {
  description = "Instance access password."
  value       = var.password
  sensitive   = true
}

output "uri" {
  description = "Connection URI."
  value       = "redis://:${var.password}@${var.domain_name}:${var.port}/"
  sensitive   = true
}
