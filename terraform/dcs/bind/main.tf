resource "random_password" "password" {
  count            = var.bind_mode == "account" ? 1 : 0
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+?"
}

resource "hcs_dcs_account" "account" {
  count            = var.bind_mode == "account" ? 1 : 0
  instance_id      = var.instance_id
  account_name     = local.account_name
  account_role     = var.account_role
  account_password = random_password.password[0].result
}
