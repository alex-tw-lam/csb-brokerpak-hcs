# -----------------------------------------------------------------------------
# csb-hcs-obs — provision an OBS bucket
# Run:  cd terraform/obs/provision
#       tofu init
#       tofu plan  -var-file=../../examples/obs/provision.tfvars
#       tofu apply -var-file=../../examples/obs/provision.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- connection (same two lines for every module) ---
region = "cn-north-1"
cloud  = "hcs.example.com"

# --- bucket ---
bucket_name   = "csb-test-bucket-CHANGE_ME"      # globally unique in OBS, DNS-compatible
acl           = "private"
storage_class = "STANDARD"
versioning    = false
force_destroy = true                             # convenient for trials; false in production
# encryption   = true                            # optional SSE-KMS
# kms_key_id   = "..."                           # optional with encryption

# --- tags ---
labels = {}
