variable "region" {
  description = "The HCS region to provision in."
  type        = string
}

variable "cloud" {
  description = "The HCS cloud domain used to derive service endpoints."
  type        = string
}

variable "instance_name" {
  description = "Name of the DCS instance."
  type        = string
}

variable "flavor" {
  description = "DCS flavor spec code from the plan; auto-resolved when empty."
  type        = string
  default     = null
}

variable "capacity" {
  description = "Cache capacity in GB."
  type        = number
}

variable "cache_mode" {
  description = "DCS cache mode."
  type        = string
}

variable "engine_version" {
  description = "Redis engine version."
  type        = string
}

variable "availability_zone" {
  description = "Primary availability zone."
  type        = string
}

variable "standby_availability_zone" {
  description = "Standby availability zone for ha mode."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID of the VPC for the instance network."
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet within the VPC."
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group (required for Redis 3.0)."
  type        = string
  default     = null
}

variable "port" {
  description = "Custom port (Redis 4.0 and above only)."
  type        = number
}

variable "password" {
  description = "Instance access password; random when null."
  type        = string
  default     = null
}

variable "description" {
  description = "Optional description of the instance."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply as tags."
  type        = map(any)
}
