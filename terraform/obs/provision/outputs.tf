output "bucket_name" {
  description = "Name of the bucket."
  value       = hcs_obs_bucket.bucket.id
}

output "bucket_domain_name" {
  description = "Domain name of the bucket."
  value       = hcs_obs_bucket.bucket.bucket_domain_name
}

output "region" {
  description = "HCS region."
  value       = hcs_obs_bucket.bucket.region
}

output "cloud" {
  description = "HCS cloud domain."
  value       = var.cloud
}
