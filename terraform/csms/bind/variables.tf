variable "region" {
  description = "The HCS region to provision in."
  type        = string
}

variable "cloud" {
  description = "The HCS cloud domain used to derive service endpoints."
  type        = string
}
variable "project_name" {
  description = "The HCS project (tenant) name."
  type        = string
}

variable "secret_name" {
  description = "Name of the provisioned CSMS secret."
  type        = string
}
