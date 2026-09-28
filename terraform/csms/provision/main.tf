resource "random_password" "secret" {
  count = var.secret_text == null || var.secret_text == "" ? 1 : 0

  length           = 32
  special          = true
  override_special = "!@#%^*-_=+?"
}

resource "hcs_csms_secret" "secret" {
  name        = var.secret_name
  secret_text = local.generated_secret
  kms_key_id  = var.kms_key_id
  description = var.description
  tags        = var.labels

  lifecycle {
    prevent_destroy = true
  }
}
