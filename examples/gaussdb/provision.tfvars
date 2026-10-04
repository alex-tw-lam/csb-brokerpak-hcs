# -----------------------------------------------------------------------------
# csb-hcs-gaussdb — provision a GaussDB (openGauss) instance
# Run:  cd terraform/gaussdb/provision
#       tofu init
#       tofu plan  -var-file=../../examples/gaussdb/provision.tfvars
#       tofu apply -var-file=../../examples/gaussdb/provision.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- connection (same two lines for every module) ---
region = "cn-north-1"
cloud  = "hcs.example.com"
# --- network (names, resolved to IDs by the module) ---
vpc_name     = "vpc-default"
subnet_name  = "subnet-gaussdb"

# --- sizing ---
flavor     = "gaussdb.opengauss.ee.dn.m6.2xlarge.8.in"
volume_type = "ULTRAHIGH"
volume_size = 480

# --- instance ---
instance_name           = "csb-test-gaussdb"
solution                = "hcs1"                 # AZ count depends on the solution
availability_zones      = ["az1", "az2", "az3"]  # must match the solution's AZ count
ha_mode                 = "combined"
ha_consistency          = "eventual"
ha_consistency_protocol = "quorum"
port                    = "8000"
sharding_num            = 3
coordinator_num         = 3
backup_start_time       = "03:00-04:00"
backup_keep_days        = 7
# security_group_name   = "sg-gaussdb"           # optional; required for custom ports
# password              = "..."                  # optional; random when omitted

# --- tags ---
labels = {}
