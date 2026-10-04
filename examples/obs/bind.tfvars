# -----------------------------------------------------------------------------
# csb-hcs-obs — bind (passthrough; optional policy grant)
# Run:  cd terraform/obs/bind
#       tofu init
#       tofu plan  -var-file=../../examples/obs/bind.tfvars
#       tofu apply -var-file=../../examples/obs/bind.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- connection (same two lines for every module) ---
region = "cn-north-1"
cloud  = "hcs.example.com"

# --- values from the provision run's outputs ---
bucket_name         = "OUTPUT-bucket_name"
bucket_domain_name  = "OUTPUT-bucket_domain_name"
grant_permission    = "read-write"
# grant_principal   = "domain/<account-id>:user/<user>"   # set to attach a bucket policy
