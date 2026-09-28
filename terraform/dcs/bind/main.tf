resource "random_password" "password" {
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+?"
}

resource "hcs_dcs_account" "account" {
  instance_id      = var.instance_id
  account_name     = local.account_name
  account_role     = var.account_role
  account_password = random_password.password.result
}
