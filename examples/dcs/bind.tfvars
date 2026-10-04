# -----------------------------------------------------------------------------
# csb-hcs-dcs — bind (creates a DCS account)
# Run:  cd terraform/dcs/bind
#       tofu init
#       tofu plan  -var-file=../../examples/dcs/bind.tfvars
#       tofu apply -var-file=../../examples/dcs/bind.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- connection (same two lines for every module) ---
region = "cn-north-1"
cloud  = "hcs.example.com"

# --- binding account ---
account_name = "appuser"
account_role = "write"                           # read | write

# --- values from the provision run's outputs ---
instance_id  = "OUTPUT-instance_id"
domain_name  = "OUTPUT-domain_name"
port         = 6379
