locals {
  connection_uri      = "mysql://${var.user_name}:${random_password.password.result}@${var.hostname}:${var.port}/"
  connection_jdbc_url = "jdbc:mysql://${var.hostname}:${var.port}/"
}
