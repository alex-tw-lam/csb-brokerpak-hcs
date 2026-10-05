# Running the modules directly with OpenTofu

Every module can be exercised with plain OpenTofu — no broker, no Service Catalog.
Each module has an input file under `examples/<service>/`, all in the same format:
**connection → network → sizing → instance → tags**. The bind files take the values
printed by the corresponding provision run (`tofu output`).

The layout is layered: **`examples/shared.tfvars`** carries the common values
(connection, shared VPC) and each module's file adds only its own values. OpenTofu
accepts multiple `-var-file` flags — later files win — so the run command is:

```bash
tofu apply -var-file=../../../examples/shared.tfvars -var-file=../../../examples/<service>/<provision|bind>.tfvars
```

The shared file and the provision tfvars are **generated and gitignored** — edit
`config/site-values.yaml` (materialized from `config/site-values.yaml.example`; your
copy stays local) and run `make gen-config` (which also produces `hcs-broker.yaml`,
so one set of site values serves both direct-tofu runs and the broker). The bind
files are **gitignored local copies** of the tracked `bind.tfvars.example` templates
(`make gen-config` materializes them if missing, `make bind-tfvars-reset` restores
them) — fill in the `OUTPUT-*` placeholders from the provision run's `tofu output`
and your edits never reach git.

## Auth (every module, provider-native)

```bash
export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...     # or HCS_DOMAIN_NAME/HCS_USER_NAME/HCS_USER_PASSWORD
export HCS_INSECURE=true                          # for self-signed certificates
```

`region`/`cloud` are passed as variables in the tfvars (not env) so the files are
self-contained. `tofu init` downloads the pinned providers (huaweicloud/hcs 2.4.26,
hashicorp/random 3.9.0) — run it on a connected machine, or mirror them for offline
use.

## The list — one command per module

| # | Module | Input file | What it creates |
|---|---|---|---|
| 1 | `terraform/ecs/provision` | `examples/ecs/provision.tfvars` | ECS instance (flavor `s6.large.2`) |
| 2 | `terraform/ecs/bind` | `examples/ecs/bind.tfvars` | passthrough (addresses + admin password) |
| 3 | `terraform/rds-postgresql/provision` | `examples/rds-postgresql/provision.tfvars` | RDS PostgreSQL 12, single node |
| 4 | `terraform/rds-postgresql/bind` | `examples/rds-postgresql/bind.tfvars` | per-binding DB account |
| 5 | `terraform/dcs/provision` | `examples/dcs/provision.tfvars` | DCS Redis 5.0, single node 0.125GB |
| 6 | `terraform/dcs/bind` | `examples/dcs/bind.tfvars` | per-binding DCS account |
| 7 | `terraform/elb/provision` | `examples/elb/provision.tfvars` | TCP load balancer + listener + pool |
| 8 | `terraform/elb/bind` | `examples/elb/bind.tfvars` | backend member + health monitor |
| 9 | `terraform/gaussdb/provision` | `examples/gaussdb/provision.tfvars` | distributed GaussDB (hcs1 solution) |
| 10 | `terraform/gaussdb/bind` | `examples/gaussdb/bind.tfvars` | admin passthrough |
| 11 | `terraform/csms/provision` | `examples/csms/provision.tfvars` | CSMS secret (random value) |
| 12 | `terraform/csms/bind` | `examples/csms/bind.tfvars` | reads back the latest secret version |
| 13 | `terraform/obs/provision` | `examples/obs/provision.tfvars` | OBS bucket |
| 14 | `terraform/obs/bind` | `examples/obs/bind.tfvars` | passthrough (optional policy grant) |

Run pattern, identical for every row:

```bash
cd terraform/<service>/<provision|bind>
tofu init
tofu plan  -var-file=../../../examples/shared.tfvars -var-file=../../../examples/<service>/<provision|bind>.tfvars
tofu apply -var-file=../../../examples/shared.tfvars -var-file=../../../examples/<service>/<provision|bind>.tfvars
tofu output                                     # copy these into the bind tfvars
```

Destroying: bind workspaces destroy normally (`tofu destroy -var-file=...`). The
provision resources are wrapped in `lifecycle { prevent_destroy = true }` (a guard
against accidental replacement). Through the broker this is a no-op — CSB flips it
off itself before deprovisioning — but raw tofu won't, so a direct destroy needs the
same one-line flip, restored afterwards:

```bash
cd terraform/<service>/provision
sed -i 's/prevent_destroy = true/prevent_destroy = false/' main.tf
tofu destroy -var-file=../../../examples/shared.tfvars -var-file=../../../examples/<service>/provision.tfvars
git restore main.tf        # put the guard back
```

Do **not** work around it with `tofu state rm` — that only makes tofu forget the
resource; the real resource in HCS is left orphaned.

## Same values, three places

The tfvars values are deliberately identical to what you configure elsewhere, so
one set of site values works everywhere:

| tfvars key | `config/site-values.yaml` → generated `hcs-broker.yaml` | Service Catalog |
|---|---|---|
| `region`, `cloud`, `insecure` | `hcs.region`, `hcs.cloud`, `hcs.insecure` | — |
| `vpc_name`, `subnet_name`, `security_group_name` | `hcs.vpc_name`, `hcs.<service>.subnet_name`, `...security_group_name` | — (or per-instance override) |
| `l4_flavor_id` / `l7_flavor_id` (ELB) | `service.csb-hcs-elb.plans` | — |
| plan flavor (`flavor`, `capacity`, `storage_gb`, …) | plan definitions | plan selection |
| instance inputs (`image_name`, `availability_zones`, …) | — | `ServiceInstance.spec.parameters` |

## Notes

- Fill in your site values in the tfvars before the first run: `cloud`, `region`,
  image name, AZ names, disk type, flavor codes and the ELB flavor IDs.
- Variables with sensible in-module behaviour (passwords, `flavor` on ECS/DCS,
  `standby_availability_zone`, `cpu_architecture` on DCS, `backend_members`,
  `grant_principal`) are commented out — uncomment to set them.
- `labels` is `{}` here; when the broker runs the module it also adds
  `namespace` / `instance_name` / `created_by` tags from the Service Catalog request.
