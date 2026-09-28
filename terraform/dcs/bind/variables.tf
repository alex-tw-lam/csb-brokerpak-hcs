variable "region" {
  description = "The HCS region to provision in."
  type        = string
}

variable "cloud" {
  description = "The HCS cloud domain used to derive service endpoints."
  type        = string
}

variable "instance_id" {
  description = "ID of the provisioned DCS instance."
  type        = string
}

variable "domain_name" {
  description = "Connection domain name of the instance."
  type        = string
}

variable "port" {
  description = "Connection port."
  type        = number
}

variable "password" {
  description = "Instance access password."
  type        = string
  sensitive   = true
}
