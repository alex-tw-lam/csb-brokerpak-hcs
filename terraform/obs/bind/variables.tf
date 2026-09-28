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
