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
  description = "ID of the DCS instance to create the account on."
  type        = string
}

variable "bind_mode" {
  description = "Credential strategy: account creates a per-binding DCS account (requires the site flag feature.dcs2.support.acl); passthrough returns the instance password."
  type        = string
  default     = "account"

  validation {
    condition     = contains(["account", "passthrough"], var.bind_mode)
    error_message = "bind_mode must be either \"account\" or \"passthrough\"."
  }
}

variable "instance_password" {
  description = "Instance access password, returned in passthrough mode."
  type        = string
  sensitive   = true
  default     = null
}

variable "account_name" {
  description = "Name of the DCS account for this binding (hyphens are converted to underscores)."
  type        = string
}

variable "account_role" {
  description = "Privilege of the binding account (read or write)."
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
