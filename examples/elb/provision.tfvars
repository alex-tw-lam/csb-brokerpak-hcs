# -----------------------------------------------------------------------------
# csb-hcs-elb — provision a TCP load balancer
# Run:  cd terraform/elb/provision
#       tofu init
#       tofu plan  -var-file=../../examples/elb/provision.tfvars
#       tofu apply -var-file=../../examples/elb/provision.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- connection (same two lines for every module) ---
region = "cn-north-1"
cloud  = "hcs.example.com"
# --- network (names, resolved to IDs by the module) ---
vpc_name     = "vpc-default"
subnet_name  = "subnet-elb"

# --- sizing (ELB flavor IDs are site-created; from your broker plan config) ---
l4_flavor_id = "CHANGE_ME_L4"
l7_flavor_id = "CHANGE_ME_L7"

# --- load balancer ---
loadbalancer_name = "csb-test-elb"
listener_protocol = "TCP"
listener_port     = 80
lb_method         = "ROUND_ROBIN"
# ipv4_address    = "192.168.1.100"              # optional; set to know the private VIP
allocate_eip      = false
eip_iptype        = "5_bgp"
bandwidth_size    = 5
# backend_members = [                             # optional; or register backends on bind
#   { address = "192.168.1.10", port = 8080 },
# ]

# --- tags ---
labels = {}
