variable "region" {
  description = "The HCS region to provision in."
  type        = string
}

variable "cloud" {
  description = "The HCS cloud domain used to derive service endpoints."
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
