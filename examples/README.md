# Running the modules directly with OpenTofu

The CSMS modules can be exercised with plain OpenTofu — no broker, no Service
Catalog. Each module has an input file under `examples/csms/`. The bind file takes
the values printed by the provision run (`tofu output`).

The layout is layered: **`examples/shared.tfvars`** carries the common connection
values and the module's file adds only its own. OpenTofu accepts multiple
`-var-file` flags — later files win — so the run command is:

```bash
tofu apply -var-file=../../../examples/shared.tfvars -var-file=../../../examples/csms/<provision|bind>.tfvars
```

The shared file and the provision tfvars are **generated and gitignored** — edit
`config/site-values.yaml` (materialized from `config/site-values.yaml.example`; your
copy stays local) and run `make gen-config` (which also produces `hcs-broker.yaml`,
so one set of site values serves both direct-tofu runs and the broker). The bind
file is a **gitignored local copy** of the tracked `bind.tfvars.example` template
(`make gen-config` materializes it if missing, `make bind-tfvars-reset` restores
it) — fill in the `OUTPUT-*` placeholders from the provision run's `tofu output`
and your edits never reach git.

## Auth (provider-native)

```bash
export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...     # or HCS_DOMAIN_NAME/HCS_USER_NAME/HCS_USER_PASSWORD
export HCS_INSECURE=true                          # for self-signed certificates
```

`region`/`cloud` are passed as variables in the tfvars (not env) so the files are
self-contained. `tofu init` downloads the pinned providers (huaweicloud/hcs 2.4.26,
hashicorp/random 3.9.0) — run it on a connected machine, or mirror them for offline
use.

## The modules

| # | Module | Input file | What it creates |
|---|---|---|---|
| 1 | `terraform/csms/provision` | `examples/csms/provision.tfvars` | CSMS secret (random value) |
| 2 | `terraform/csms/bind` | `examples/csms/bind.tfvars` | reads back the latest secret version |

Run pattern, identical for both rows:

```bash
cd terraform/csms/<provision|bind>
tofu init
tofu plan  -var-file=../../../examples/shared.tfvars -var-file=../../../examples/csms/<provision|bind>.tfvars
tofu apply -var-file=../../../examples/shared.tfvars -var-file=../../../examples/csms/<provision|bind>.tfvars
tofu output                                     # copy these into the bind tfvars
```

Destroying: the bind workspace destroys normally (`tofu destroy -var-file=...`).
The provision secret is wrapped in `lifecycle { prevent_destroy = true }` (a guard
against accidental deletion). Through the broker this is a no-op — CSB flips it
off itself before deprovisioning — but raw tofu won't, so a direct destroy needs
the same one-line flip, restored afterwards:

```bash
cd terraform/csms/provision
sed -i 's/prevent_destroy = true/prevent_destroy = false/' main.tf
tofu destroy -var-file=../../../examples/shared.tfvars -var-file=../../../examples/csms/provision.tfvars
git restore main.tf        # put the guard back
```

Do **not** work around it with `tofu state rm` — that only makes tofu forget the
resource; the real secret in HCS is left orphaned.

## Notes

- Fill in your site values before the first run: `cloud`, `region`,
  `project_name` (via `config/site-values.yaml` → `make gen-config`).
- `secret_text` and `kms_key_id` are commented out — random secret and the default
  KMS key when omitted.
- `labels` is `{}` here; when the broker runs the module it also adds
  `namespace` / `instance_name` / `created_by` tags from the Service Catalog request.
