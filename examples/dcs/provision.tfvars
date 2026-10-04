# -----------------------------------------------------------------------------
# csb-hcs-dcs — provision a DCS (Redis) instance
# Run:  cd terraform/dcs/provision
#       tofu init
#       tofu plan  -var-file=../../examples/dcs/provision.tfvars
#       tofu apply -var-file=../../examples/dcs/provision.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- connection (same two lines for every module) ---
region = "cn-north-1"
cloud  = "hcs.example.com"
# --- network (names, resolved to IDs by the module) ---
vpc_name     = "vpc-default"
subnet_name  = "subnet-dcs"

# --- sizing ---
capacity       = 0.125
cache_mode     = "single"                        # single | ha | cluster | proxy
engine_version = "5.0"
# flavor        = "redis.ha.xu1.large.r2.4"       # optional; auto-resolved from capacity/mode when omitted

# --- instance ---
instance_name     = "csb-test-dcs"
availability_zone = "az1"
# standby_availability_zone = "az2"              # required for ha mode
port              = 6379
# password       = "..."                          # optional; random when omitted

# --- tags ---
labels = {}
