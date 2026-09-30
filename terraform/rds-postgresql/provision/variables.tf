variable "region" {
  description = "The HCS region to provision in."
  type        = string
}

variable "cloud" {
  description = "The HCS cloud domain used to derive service endpoints."
  type        = string
}

variable "instance_name" {
  description = "Name of the RDS instance."
  type        = string
}

variable "flavor" {
  description = "RDS flavor spec code."
  type        = string
}

variable "pg_version" {
  description = "PostgreSQL engine version."
  type        = string
}

variable "storage_gb" {
  description = "Storage size in GB."
  type        = number
}

variable "volume_type" {
  description = "Volume type for the instance."
  type        = string
}

variable "availability_zones" {
  description = "Availability zone list (one for single, two for HA)."
  type        = list(string)
}

variable "ha_replication_mode" {
  description = "HA replication mode for HA flavors (async or sync)."
  type        = string
}

variable "port" {
  description = "Database port."
  type        = number
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
  description = "Name of the security group controlling access."
  type        = string
}

variable "admin_password" {
  description = "Administrator password; random when null."
  type        = string
  default     = null
}

variable "backup_start_time" {
  description = "Backup window start."
  type        = string
}

variable "backup_keep_days" {
  description = "Days to keep automated backups."
  type        = number
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
