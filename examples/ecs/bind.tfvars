# -----------------------------------------------------------------------------
# csb-hcs-ecs — bind (passthrough)
# Run:  cd terraform/ecs/bind
#       tofu init
#       tofu plan  -var-file=../../examples/shared.tfvars -var-file=../../examples/ecs/bind.tfvars
#       tofu apply -var-file=../../examples/shared.tfvars -var-file=../../examples/ecs/bind.tfvars
# Auth: export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...   (or IAM user/password)
#       export HCS_INSECURE=true                        (self-signed certs)
# Values mirror config/hcs-broker.yaml.example + ServiceInstance parameters.
# -----------------------------------------------------------------------------
# --- values from the provision run's outputs ---
instance_id   = "OUTPUT-instance_id"
name          = "OUTPUT-name"
private_ip    = "OUTPUT-private_ip"
public_ip     = ""
admin_password = "OUTPUT-admin_password"
