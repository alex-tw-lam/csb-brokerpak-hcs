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

variable "cpu_architecture" {
  description = "CPU architecture filter for the flavor lookup (x86_64 or aarch64). Null accepts whatever the site offers."
  type        = string
  default     = null
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

variable "vpc_name" {
  description = "Name of the VPC for the instance network."
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet within the VPC."
  type        = string
}

variable "security_group_name" {
  description = "Name of the security group (required for Redis 3.0)."
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

variable "request_context_json" {
  description = "JSON of the OSB request context (kubernetes namespace, instance_name, cluster id)."
  type        = string
  default     = ""
}

variable "originating_identity_json" {
  description = "JSON of the OSB originating identity (kubernetes username, groups, uid)."
  type        = string
  default     = ""
}
