# -----------------------------------------------------------------------------
# csb-hcs-elb — bind (registers a backend member)
# Run:  cd terraform/elb/bind
#       tofu init
#       tofu plan  -var-file=../../examples/shared.tfvars -var-file=../../examples/elb/bind.tfvars
#       tofu apply -var-file=../../examples/shared.tfvars -var-file=../../examples/elb/bind.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- backend to register ---
address = "192.168.1.10"
port    = 8080
weight  = 1
enable_health_check = true

# --- values from the provision run's outputs ---
loadbalancer_id = "OUTPUT-loadbalancer_id"
vip_address     = ""
public_ip       = ""
listener_port   = 80
protocol        = "TCP"
pool_id         = "OUTPUT-pool_id"
ipv4_subnet_id  = "OUTPUT-ipv4_subnet_id"
