variable "region" {
  description = "The HCS region to provision in."
  type        = string
}

variable "cloud" {
  description = "The HCS cloud domain used to derive service endpoints."
  type        = string
}

variable "bucket_name" {
  description = "Name of the provisioned bucket."
  type        = string
}

variable "bucket_domain_name" {
  description = "Domain name of the provisioned bucket."
  type        = string
}

variable "grant_principal" {
  description = "Optional OBS principal granted access to the bucket."
  type        = string
  default     = null
}

variable "grant_permission" {
  description = "Permission granted to grant_principal (read or read-write)."
  type        = string
}
