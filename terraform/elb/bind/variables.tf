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

variable "loadbalancer_id" {
  description = "ID of the provisioned load balancer."
  type        = string
}

variable "vip_address" {
  description = "Private VIP address of the load balancer."
  type        = string
}

variable "public_ip" {
  description = "EIP address of the load balancer."
  type        = string
}

variable "listener_port" {
  description = "Listener frontend port."
  type        = number
}

variable "protocol" {
  description = "Listener protocol."
  type        = string
}

variable "pool_id" {
  description = "ID of the backend server pool."
  type        = string
}

variable "ipv4_subnet_id" {
  description = "Neutron subnet ID of the load balancer VIP subnet."
  type        = string
}

variable "address" {
  description = "IP address of the backend server to register."
  type        = string
}

variable "port" {
  description = "Backend port of the server to register."
  type        = number
}

variable "weight" {
  description = "Relative traffic weight of this backend member."
  type        = number
}

variable "enable_health_check" {
  description = "Create a health monitor for the backend port."
  type        = bool
}
