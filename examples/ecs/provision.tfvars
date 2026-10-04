# -----------------------------------------------------------------------------
# csb-hcs-ecs — provision an ECS instance
# Run:  cd terraform/ecs/provision
#       tofu init
#       tofu plan  -var-file=../../examples/ecs/provision.tfvars
#       tofu apply -var-file=../../examples/ecs/provision.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- connection (same two lines for every module) ---
region = "cn-north-1"
cloud  = "hcs.example.com"
# --- network (names, resolved to IDs by the module) ---
vpc_name     = "vpc-default"
subnet_name  = "subnet-ecs"

# --- sizing ---
flavor = "s6.large.2"          # plan flavor; drop this line to auto-resolve from cores/memory
security_group_name = "sg-ecs"

# --- instance ---
instance_name    = "csb-test-ecs"
image_name       = "Ubuntu 22.04 server 64bit"   # site-specific IMS image name
availability_zone = "az1"
system_disk_type = "business_type_01"            # site-specific disk type
system_disk_size = 40
allocate_eip     = false
eip_iptype       = "5_bgp"
bandwidth_size   = 5
# admin_pass     = "..."                          # optional; random when omitted

# --- tags ---
labels = {}
# namespace / instance_name / created_by tags come from the broker when it runs this module
