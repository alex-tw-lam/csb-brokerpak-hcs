# -----------------------------------------------------------------------------
# csb-hcs-gaussdb — bind (admin passthrough)
# Run:  cd terraform/gaussdb/bind
#       tofu init
#       tofu plan  -var-file=../../examples/gaussdb/bind.tfvars
#       tofu apply -var-file=../../examples/gaussdb/bind.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- connection (same two lines for every module) ---
region = "cn-north-1"
cloud  = "hcs.example.com"

# --- values from the provision run's outputs ---
instance_id = "OUTPUT-instance_id"
endpoints   = "OUTPUT-endpoints"                 # comma-joined host:port string
username    = "OUTPUT-username"
password    = "OUTPUT-password"
port        = "8000"
