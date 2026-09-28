variable "region" {
  description = "The HCS region to provision in."
  type        = string
}

variable "cloud" {
  description = "The HCS cloud domain used to derive service endpoints."
  type        = string
}

variable "secret_name" {
  description = "Name of the CSMS secret."
  type        = string
}

variable "secret_text" {
  description = "Secret plaintext; random when null."
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "KMS key ID used to encrypt the secret; CSMS default when null."
  type        = string
  default     = null
}

variable "description" {
  description = "Optional description of the secret."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply as tags."
  type        = map(any)
}
