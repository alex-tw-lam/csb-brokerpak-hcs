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
  description = "ID of the provisioned ECS instance."
  type        = string
}

variable "name" {
  description = "Name of the provisioned ECS instance."
  type        = string
}

variable "private_ip" {
  description = "Private IPv4 address of the instance."
  type        = string
}

variable "public_ip" {
  description = "Public IPv4 address of the instance."
  type        = string
}

variable "admin_password" {
  description = "Administrator password of the instance."
  type        = string
  sensitive   = true
}
