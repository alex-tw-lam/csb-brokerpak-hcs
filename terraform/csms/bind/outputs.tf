output "name" {
  description = "Name of the CSMS secret."
  value       = var.secret_name
}

output "value" {
  description = "Latest version plaintext of the secret."
  value       = data.hcs_csms_secret_version.version.secret_text
  sensitive   = true
}

output "version" {
  description = "Version of the secret read back."
  value       = data.hcs_csms_secret_version.version.version
}
