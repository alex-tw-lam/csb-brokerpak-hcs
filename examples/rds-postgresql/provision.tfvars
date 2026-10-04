# -----------------------------------------------------------------------------
# csb-hcs-rds-postgresql — provision an RDS for PostgreSQL instance
# Run:  cd terraform/rds-postgresql/provision
#       tofu init
#       tofu plan  -var-file=../../examples/rds-postgresql/provision.tfvars
#       tofu apply -var-file=../../examples/rds-postgresql/provision.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- connection (same two lines for every module) ---
region = "cn-north-1"
cloud  = "hcs.example.com"
# --- network (names, resolved to IDs by the module) ---
vpc_name     = "vpc-default"
subnet_name  = "subnet-rds-pg"

# --- sizing ---
flavor          = "rds.pg.n1.large.2"            # single node; use *.ha flavors with two AZs
security_group_name = "sg-rds-pg"

# --- instance ---
instance_name      = "csb-test-rds-pg"
pg_version         = "12"
storage_gb         = 100
volume_type        = "ULTRAHIGH"
availability_zones = ["az1"]                     # two entries for .ha flavors
ha_replication_mode = "async"                    # used by .ha flavors only
port               = 5432
backup_start_time  = "03:00-04:00"
backup_keep_days   = 7
# admin_password  = "..."                         # optional; random when omitted

# --- tags ---
labels = {}
