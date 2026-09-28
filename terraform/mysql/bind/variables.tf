variable "region" {
  description = "The HCS region to provision in."
  type        = string
}

variable "cloud" {
  description = "The HCS cloud domain used to derive service endpoints."
  type        = string
}

variable "instance_id" {
  description = "ID of the RDS instance to create the account on."
  type        = string
}

variable "user_name" {
  description = "Name of the MySQL account for this binding."
  type        = string
}

variable "authorized_hosts" {
  description = "Host patterns the account may connect from."
  type        = list(string)
}

variable "hostname" {
  description = "Private IP address of the database."
  type        = string
}

variable "port" {
  description = "Database port."
  type        = number
}

variable "admin_username" {
  description = "Administrator username of the instance."
  type        = string
}

variable "admin_password" {
  description = "Administrator password of the instance."
  type        = string
  sensitive   = true
}
