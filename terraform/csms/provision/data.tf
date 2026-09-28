locals {
  generated_secret = var.secret_text == null || var.secret_text == "" ? random_password.secret[0].result : var.secret_text
}
