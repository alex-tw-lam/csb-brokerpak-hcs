resource "random_password" "password" {
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+?"
}

resource "hcs_rds_pg_account" "account" {
  instance_id = var.instance_id
  name        = local.account_name
  password    = random_password.password.result
}
