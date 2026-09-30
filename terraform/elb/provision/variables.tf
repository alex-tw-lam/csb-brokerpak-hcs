variable "region" {
  description = "The HCS region to provision in."
  type        = string
}

variable "cloud" {
  description = "The HCS cloud domain used to derive service endpoints."
  type        = string
}

variable "loadbalancer_name" {
  description = "Name of the load balancer."
  type        = string
}

variable "l4_flavor_id" {
  description = "Layer-4 flavor ID."
  type        = string
  default     = null
}

variable "l7_flavor_id" {
  description = "Layer-7 flavor ID."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID of the VPC for the load balancer network."
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet within the VPC."
  type        = string
}

variable "ipv4_address" {
  description = "Explicit private IPv4 address for the VIP."
  type        = string
  default     = null
}

variable "listener_protocol" {
  description = "Listener protocol."
  type        = string
}

variable "listener_port" {
  description = "Listener frontend port."
  type        = number
}

variable "lb_method" {
  description = "Backend load balancing algorithm."
  type        = string
}

variable "backend_members" {
  description = "Backend members as objects with address and port."
  type = list(object({
    address = string
    port    = number
  }))
  default = []
}

variable "allocate_eip" {
  description = "Whether to allocate and associate a new EIP."
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
