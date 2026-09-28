locals {
  # PostgreSQL account names allow letters, digits and underscores only.
  account_name        = replace(var.user_name, "-", "_")
  connection_uri      = "postgresql://${local.account_name}:${random_password.password.result}@${var.hostname}:${var.port}/postgres"
  connection_jdbc_url = "jdbc:postgresql://${var.hostname}:${var.port}/postgres"
}
