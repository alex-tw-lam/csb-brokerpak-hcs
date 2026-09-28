locals {
  # DCS account names allow letters, digits and underscores only.
  account_name   = replace(var.account_name, "-", "_")
  connection_uri = "redis://${local.account_name}:${random_password.password.result}@${var.domain_name}:${var.port}/"
}
