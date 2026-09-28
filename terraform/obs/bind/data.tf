locals {
  grant_enabled = var.grant_principal != null && var.grant_principal != ""

  object_actions = var.grant_permission == "read" ? ["GetObject"] : ["GetObject", "PutObject", "DeleteObject"]

  policy_statements = concat(
    [
      {
        Sid       = "csb-bucket-access"
        Effect    = "Allow"
        Principal = { ID = var.grant_principal }
        Action    = ["ListBucket"]
        Resource  = var.bucket_name
      }
    ],
    [
      {
        Sid       = "csb-object-access"
        Effect    = "Allow"
        Principal = { ID = var.grant_principal }
        Action    = local.object_actions
        Resource  = "${var.bucket_name}/*"
      }
    ]
  )

  policy_json = jsonencode({ Statement = local.policy_statements })
}
