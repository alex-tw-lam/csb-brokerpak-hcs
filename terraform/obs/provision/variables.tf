variable "region" {
  description = "The HCS region to provision in."
  type        = string
}

variable "cloud" {
  description = "The HCS cloud domain used to derive service endpoints."
  type        = string
}

variable "bucket_name" {
  description = "Name of the bucket."
  type        = string
}

variable "acl" {
  description = "Canned ACL for the bucket."
  type        = string
}

variable "storage_class" {
  description = "Storage class of the bucket."
  type        = string
}

variable "versioning" {
  description = "Enable object versioning."
  type        = bool
}

variable "encryption" {
  description = "Enable default server-side encryption (SSE-KMS)."
  type        = bool
}

variable "kms_key_id" {
  description = "KMS key ID for server-side encryption; default master key when null."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Delete all objects when destroying the bucket."
  type        = bool
}

variable "labels" {
  description = "Labels to apply as tags."
  type        = map(any)
}
