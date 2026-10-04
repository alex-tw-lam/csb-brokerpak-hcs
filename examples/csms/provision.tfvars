# -----------------------------------------------------------------------------
# csb-hcs-csms — provision a CSMS secret
# Run:  cd terraform/csms/provision
#       tofu init
#       tofu plan  -var-file=../../examples/csms/provision.tfvars
#       tofu apply -var-file=../../examples/csms/provision.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- connection (same two lines for every module) ---
region = "cn-north-1"
cloud  = "hcs.example.com"

# --- secret ---
secret_name = "csb-test-secret"
# secret_text = "..."                            # optional; random when omitted
# kms_key_id  = "..."                            # optional; default KMS key when omitted

# --- tags ---
labels = {}
