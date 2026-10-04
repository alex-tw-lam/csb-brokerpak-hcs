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
  description = "Name of the GaussDB instance."
  type        = string
}

variable "flavor" {
  description = "GaussDB flavor spec code."
  type        = string
}

variable "password" {
  description = "Database administrator password; random when null."
  type        = string
  default     = null
}

variable "availability_zones" {
  description = "Availability zone list, joined per solution semantics."
  type        = list(string)
}

variable "solution" {
  description = "Deployment solution."
  type        = string
}

variable "ha_mode" {
  description = "HA deployment mode."
  type        = string
}

variable "ha_consistency" {
  description = "HA consistency level."
  type        = string
}

variable "ha_consistency_protocol" {
  description = "HA consistency protocol."
  type        = string
}

variable "volume_type" {
  description = "Volume type for the instance."
  type        = string
}

variable "volume_size" {
  description = "Storage size in GB."
  type        = number
}

variable "port" {
  description = "Database port as a string."
  type        = string
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
  description = "Name of the security group; required for custom ports."
  type        = string
  default     = null
}

variable "sharding_num" {
  description = "Number of shards."
  type        = number
}

variable "coordinator_num" {
  description = "Number of coordinator nodes."
  type        = number
}

variable "datastore_version" {
  description = "GaussDB engine version; latest when null."
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
