# -----------------------------------------------------------------------------
# csb-hcs-gaussdb — bind (admin passthrough)
# Run:  cd terraform/gaussdb/bind
#       tofu init
#       tofu plan  -var-file=../../examples/shared.tfvars -var-file=../../examples/gaussdb/bind.tfvars
#       tofu apply -var-file=../../examples/shared.tfvars -var-file=../../examples/gaussdb/bind.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- values from the provision run's outputs ---
instance_id = "OUTPUT-instance_id"
endpoints   = "OUTPUT-endpoints"                 # comma-joined host:port string
username    = "OUTPUT-username"
password    = "OUTPUT-password"
port        = "8000"
