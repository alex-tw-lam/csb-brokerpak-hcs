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

variable "instance_id" {
  description = "ID of the provisioned GaussDB instance."
  type        = string
}

variable "endpoints" {
  description = "Connection endpoints as a comma-joined host:port string."
  type        = string
}

variable "username" {
  description = "Administrator username of the instance."
  type        = string
}

variable "password" {
  description = "Administrator password of the instance."
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Database port."
  type        = string
}
