# -----------------------------------------------------------------------------
# csb-hcs-rds-postgresql — bind (creates a DB account)
# Run:  cd terraform/rds-postgresql/bind
#       tofu init
#       tofu plan  -var-file=../../examples/shared.tfvars -var-file=../../examples/rds-postgresql/bind.tfvars
#       tofu apply -var-file=../../examples/shared.tfvars -var-file=../../examples/rds-postgresql/bind.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- binding account ---
user_name = "appuser"

# --- values from the provision run's outputs ---
instance_id    = "OUTPUT-instance_id"
hostname       = "OUTPUT-hostname"
port           = 5432
admin_username = "OUTPUT-username"
admin_password = "OUTPUT-password"
