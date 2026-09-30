resource "hcs_obs_bucket" "bucket" {
  bucket        = var.bucket_name
  acl           = var.acl
  storage_class = var.storage_class
  versioning    = var.versioning

  encryption = var.encryption
  kms_key_id = var.kms_key_id

  force_destroy = var.force_destroy
  region        = var.region
  tags          = local.tags

  lifecycle {
    prevent_destroy = true
  }
}
