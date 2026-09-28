resource "random_password" "password" {
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+?"
}

resource "hcs_rds_mysql_account" "account" {
  instance_id = var.instance_id
  name        = var.user_name
  password    = random_password.password.result
  hosts       = var.authorized_hosts
}
