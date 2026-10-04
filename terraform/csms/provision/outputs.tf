output "secret_id" {
  description = "ID of the CSMS secret."
  value       = hcs_csms_secret.secret.secret_id
}

output "name" {
  description = "Name of the CSMS secret."
  value       = hcs_csms_secret.secret.name
}

output "latest_version" {
  description = "Latest version of the secret."
  value       = hcs_csms_secret.secret.latest_version
}

output "secret_text" {
  description = "Secret plaintext."
  value       = local.generated_secret
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
