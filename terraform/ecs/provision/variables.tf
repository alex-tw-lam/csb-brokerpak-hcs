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
  description = "Name of the ECS instance."
  type        = string
}

variable "flavor" {
  description = "ECS flavor spec code from the plan; auto-resolved when empty."
  type        = string
  default     = null
}

variable "cores" {
  description = "Number of vCPUs used for the automatic flavor lookup."
  type        = number
  default     = 2
}

variable "memory_gb" {
  description = "Memory in GB used for the automatic flavor lookup."
  type        = number
  default     = 4
}

variable "image_name" {
  description = "Name of the IMS image to boot from."
  type        = string
}

variable "availability_zone" {
  description = "Availability zone to place the instance in."
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
  description = "Name of the security group to attach."
  type        = string
}

variable "admin_pass" {
  description = "Administrator password; random when null."
  type        = string
  default     = null
}

variable "system_disk_type" {
  description = "System disk type."
  type        = string
}

variable "system_disk_size" {
  description = "System disk size in GB."
  type        = number
}

variable "allocate_eip" {
  description = "Whether to allocate and attach a new EIP."
  type        = bool
}

variable "eip_iptype" {
  description = "EIP iptype used when allocating an EIP."
  type        = string
}

variable "bandwidth_size" {
  description = "EIP bandwidth size in Mbit/s used when allocating an EIP."
  type        = number
}

variable "user_data" {
  description = "Optional cloud-init user data."
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
