output "username" {
  description = "Username of the binding account."
  value       = hcs_dcs_account.account.account_name
}

output "password" {
  description = "Randomly generated password of the binding account."
  value       = random_password.password.result
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
