locals {
  # DCS account names allow letters, digits and underscores only.
  account_name = replace(var.account_name, "-", "_")

  # Passthrough mode hands out the instance password (the "default" ACL user).
  username = var.bind_mode == "account" ? hcs_dcs_account.account[0].account_name : "default"
  password = var.bind_mode == "account" ? random_password.password[0].result : var.instance_password

  connection_uri = "redis://${local.username}:${local.password}@${var.domain_name}:${var.port}/"
}
