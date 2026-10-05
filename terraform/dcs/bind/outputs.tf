output "username" {
  description = "Username of the binding credential (the DCS account, or \"default\" in passthrough mode)."
  value       = local.username
}

output "password" {
  description = "Password of the binding credential (randomly generated for the account, or the instance password in passthrough mode)."
  value       = local.password
  sensitive   = true
}

output "host" {
  description = "Connection domain name of the instance."
  value       = var.domain_name
}

output "port" {
  description = "Connection port."
  value       = var.port
}

output "uri" {
  description = "Connection URI."
  value       = local.connection_uri
  sensitive   = true
}
