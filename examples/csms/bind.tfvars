# -----------------------------------------------------------------------------
# csb-hcs-csms — bind (reads back the secret)
# Run:  cd terraform/csms/bind
#       tofu init
#       tofu plan  -var-file=../../examples/csms/bind.tfvars
#       tofu apply -var-file=../../examples/csms/bind.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- connection (same two lines for every module) ---
region = "cn-north-1"
cloud  = "hcs.example.com"

# --- values from the provision run's outputs ---
secret_name = "OUTPUT-name"
