# Configuration

The single source of truth for site values is **`config/site-values.yaml`** — edit
that one file, then `make gen-config` generates both artifacts:

```bash
make gen-config
# -> hcs-broker.yaml                      (csb serve --config hcs-broker.yaml)
# -> examples/<service>/provision.tfvars  (direct OpenTofu runs, see examples/README.md)
csb serve --config hcs-broker.yaml
```

It carries everything static: the HCS connection settings (`hcs.cloud`, `hcs.region`,
…), the site network tree (`hcs.vpc_name` and the per-service
`subnet_name`/`security_group_name` keys) and the ELB plan definitions
(`service.csb-hcs-elb.plans`, JSON as a string). Only credentials are expected in the
environment. Keys listed in the manifest's `env_config_mapping` can still be set via
`HCS_*` environment variables — those override the file — which is handy for tests and
one-off runs.

## Broker API & storage (CSB core)

| Variable | Default | Description |
|---|---|---|
| `SECURITY_USER_NAME` / `SECURITY_USER_PASSWORD` | — | Basic auth for the OSB API |
| `PORT` | `8080` | Listen port |
| `DB_TYPE` | `mysql` | `mysql` or `sqlite3` (dev only) |
| `DB_PATH` | — | SQLite file (with `DB_TYPE=sqlite3`) |
| `DB_HOST`/`DB_PORT`/`DB_NAME`/`DB_USERNAME`/`DB_PASSWORD` | — | MySQL storage (with `DB_TYPE=mysql`) |
| `GSB_BROKERPAK_BUILTIN_PATH` | `./` | Directory containing `*.brokerpak` files |
| `GSB_BROKERPAK_CONFIG` | — | JSON brokerpak config, e.g. `{"global_labels":[{"key":"team","value":"x"}]}` |
| `GSB_PROVISION_DEFAULTS` | — | JSON map of default values for provision inputs |

## HCS connection

Non-secret connection settings live in `config/site-values.yaml` and land in the
generated `hcs-broker.yaml` under `hcs:`: `cloud`, `region`, `project_name`
(HCS project/tenant, commonly equal to the region name) and optionally `auth_url` /
`insecure`.
Credentials are passed as environment variables and are read natively by
`terraform-provider-hcs` — they never enter the CSB database or the config file.

### AK/SK authentication

| Variable | Example | Description |
|---|---|---|
| `HCS_ACCESS_KEY` | `AKTP...` | Access key |
| `HCS_SECRET_KEY` | — | Secret key |
| `HCS_SECURITY_TOKEN` | — | Optional, for temporary AK/SK |

### Domain/user/password authentication (Keystone v3)

| Variable | Example | Description |
|---|---|---|
| `HCS_DOMAIN_NAME` | `mydomain` | IAM domain |
| `HCS_USER_NAME` | `csb` | IAM user |
| `HCS_USER_PASSWORD` | — | IAM password |

### Shared

| Variable | Example | Description |
|---|---|---|
| `HCS_CLOUD` | `hcs.example.com` | Cloud domain; service endpoints are derived as `https://<service>.<region>.<cloud>/` — **required** on HCS |
| `HCS_REGION_NAME` | `cn-north-1` | Region; also used as the project name fallback |
| `HCS_AUTH_URL` | `https://iam-apigateway-proxy.hcs.example.com/v3` | Overrides the derived Keystone v3 endpoint |
| `HCS_INSECURE` | `true` | Skip TLS verification (typical for HCS self-signed certs) |

### Site network defaults

One shared VPC plus a dedicated subnet and security group per service — **all by
name**, configured once in the config file (`hcs:` tree). Names are resolved to IDs at
provision time (`hcs_vpcs` for the VPC, `hcs_vpc_subnets` per subnet,
`hcs_networking_secgroups` per security group), so no UUIDs ever appear in the
configuration.

| Config key | Env override | Used by |
|---|---|---|
| `hcs.vpc_name` | `HCS_VPC_NAME` | ecs, rds-postgresql, dcs, elb, gaussdb (shared VPC) |
| `hcs.ecs.subnet_name` | `HCS_ECS_SUBNET_NAME` | ecs |
| `hcs.ecs.security_group_name` | `HCS_ECS_SECURITY_GROUP_NAME` | ecs |
| `hcs.rds_postgresql.subnet_name` | `HCS_RDS_POSTGRESQL_SUBNET_NAME` | rds-postgresql |
| `hcs.rds_postgresql.security_group_name` | `HCS_RDS_POSTGRESQL_SECURITY_GROUP_NAME` | rds-postgresql |
| `hcs.dcs.subnet_name` | `HCS_DCS_SUBNET_NAME` | dcs |
| `hcs.elb.subnet_name` | `HCS_ELB_SUBNET_NAME` | elb |
| `hcs.gaussdb.subnet_name` | `HCS_GAUSSDB_SUBNET_NAME` | gaussdb |

The optional security group inputs on `csb-hcs-dcs` (Redis 3.0 only) and
`csb-hcs-gaussdb` (custom port only) remain per-instance parameters (also by name).

If your site's service endpoint hostnames do not follow the
`<service>.<region>.<cloud>` convention, set the provider `endpoints` map — this
currently requires extending `provider.tf` in the service modules.

## Plans

`csb-hcs-ecs`, `csb-hcs-rds-postgresql`, `csb-hcs-dcs`, `csb-hcs-gaussdb` and `csb-hcs-obs` ship with
inline plans in their service definitions, so the broker starts with a usable catalog
out of the box. `csb-hcs-elb` alone requires operator-defined plans because ELB flavor
IDs are site-specific — the broker refuses to start until its variable is set:

```bash
export GSB_SERVICE_CSB_HCS_ELB_PLANS='[{"name":"default","id":"<uuid>","description":"default ELB","display_name":"default","l4_flavor_id":"<site-flavor-id>","l7_flavor_id":"<site-flavor-id>"}]'
```

The inline plans can be replaced per site via the same environment variables (JSON
array; plan `properties` keys must be declared in that service's `plan_inputs`):

```bash
export GSB_SERVICE_CSB_HCS_RDS_POSTGRESQL_PLANS='[{"name":"small","id":"<uuid>","description":"single node","display_name":"small","flavor":"rds.pg.n1.large.2"}]'
export GSB_SERVICE_CSB_HCS_GAUSSDB_PLANS='[{"name":"small","id":"<uuid>","description":"centralized HA","display_name":"small","flavor":"gaussdb.opengauss.ee.m6.2xlarge.x868.ha"}]'
export GSB_SERVICE_CSB_HCS_DCS_PLANS='[{"name":"medium","id":"<uuid>","description":"single node 1GB","display_name":"medium","capacity":1,"cache_mode":"single","engine_version":"5.0"}]'
```

Notes:

- Plans are flavor-based wherever a meaningful default exists: `csb-hcs-ecs` uses
  `s6.*` spec codes, `csb-hcs-rds-postgresql` uses `rds.pg.*`, `csb-hcs-gaussdb` uses
  `gaussdb.opengauss.ee.*`, and `csb-hcs-dcs` exposes an optional `flavor` plan
  property (when a plan leaves it empty, the flavor is auto-resolved from capacity,
  cache mode and engine version; `ha-large` ships the documented
  `redis.ha.xu1.large.r2.4` code).
- `csb-hcs-elb` is the exception: ELB flavors are created per site (see
  `hcs_elb_flavor`), so its plans must be defined via the environment variable above.
- The shipped flavor codes come from the provider documentation examples; verify them
  against your site's flavor catalog and override where needed.
- HA RDS flavors carry an `.ha` suffix and require **two** entries in
  `availability_zones`; single-node flavors need one AZ.
- GaussDB `flavor`/`solution` determine how many availability zones must be provided
  (`hcs1..hcs7` are the HCS-specific combined solutions).
- Plan properties cannot be overridden by user parameters at provision time.
- The Makefile exports a sample ELB plan (replace the `CHANGE_ME` flavor IDs before
  real use); the `.envrc` file documents the same for local development.

## Site-specific user inputs

| Input | Service | Notes |
|---|---|---|
| `image_name` | ecs | Exact IMS image name, resolved via `hcs_ims_images` |
| `system_disk_type` | ecs | e.g. `business_type_01` — HCS disk type catalog differs per site |
| `eip_iptype` | ecs, elb | e.g. `5_bgp`/`5_sbgp` or site network name |
| `availability_zone`/`availability_zones` | all | Site AZ naming (e.g. `az1.dc1`) — per-instance input |
| `vpc_name` + `subnet_name` | ecs, rds-postgresql, dcs, elb, gaussdb | Defaulted per service from the site network configuration above |
| `security_group_name` | rds-postgresql (defaulted), ecs (defaulted), dcs/gaussdb (optional, per-instance) | Existing security groups |

## Tagging

Every service that supports tags (all except `csb-hcs-gaussdb`, whose provider resource
has no tags argument) applies these tags to the provisioned resource:

| Tag | Source |
|---|---|
| `pcf-instance-id` | OSB instance ID (always) |
| any `global_labels` entries | `GSB_BROKERPAK_CONFIG` (operator-defined, e.g. team/CostCenter) |
| `namespace` | Kubernetes namespace of the ServiceInstance (from the OSB request context) |
| `instance_name` | Kubernetes name of the ServiceInstance (from the OSB request context) |
| `created_by` | Kubernetes username that created the ServiceInstance (from the originating identity header) |

The Kubernetes values are sent by Service Catalog automatically (the originating
identity requires the `OriginatingIdentity` feature gate, enabled by default in the
drycc chart). They are parsed Terraform-side and silently omitted when absent, so
provisioning without Service Catalog (e.g. plain curl) still works. Note HCS tag
value constraints apply — usernames containing unusual characters are passed through
verbatim and may be rejected by the API on strict sites.

## Service-specific behavior

- **ECS**: `flavor_id` may be set explicitly; otherwise the flavor is auto-resolved
  from the plan's `cores`/`memory_gb` via `hcs_ecs_compute_flavors` in the target AZ.
- **RDS for PostgreSQL (`csb-hcs-rds-postgresql`) bind**: creates a dedicated `hcs_rds_pg_account` per binding with a
  random password; `user_name` defaults to `csb-<binding id>` and hyphens are
  converted to underscores to satisfy PostgreSQL account naming (the name must not
  start with "pg" or a digit). The connection URI targets the default `postgres`
  database.
- **DCS (`csb-hcs-dcs`) — Redis engine**: connection uses `domain_name` (the provider exports no IP attribute);
  the flavor comes from the plan when set, otherwise it is auto-resolved from
  `capacity`/`cache_mode`/`engine_version` via `hcs_dcs_flavors`. Bindings create a
  per-binding `hcs_dcs_account` with a random password (requires an engine version
  supporting accounts, Redis 4.0+).
- **ELB (TCP-based)**: the listener protocol defaults to TCP. Binding registers a
  backend member (`address` + `port`, optional `weight`) in the pool with an optional
  health check (TCP probe, or HTTP for HTTP/HTTPS listeners); unbinding removes the
  member. Set `ipv4_address` explicitly at provision time if you need the private VIP in
  the binding (provider limitation); backend `subnet_id` uses the neutron subnet id
  resolved from `subnet_name`.
- **ECS bind**: exposes the instance addresses plus the administrator password
  (generated at provision when not provided; username is image-dependent, typically
  root on Linux).
- **GaussDB bind**: passes through the instance administrator credentials (no
  per-account resource in provider v2.4.28). Endpoint lists are passed through
  instance details as comma-joined strings and re-split in the bind module.
- **CSMS bind**: reads the latest secret version via `hcs_csms_secret_version`.
- Password inputs left empty on any service are generated by `random_password` with
  HCS-compatible special characters and returned via the binding credentials.
- Bind credentials are randomly generated wherever the provider supports per-binding
  identities: `csb-hcs-rds-postgresql` (DB account) and `csb-hcs-dcs` (DCS account).
  `csb-hcs-gaussdb` bindings pass through the instance administrator password (the
  provider has no per-account resource); `csb-hcs-ecs`/`csb-hcs-elb`/`csb-hcs-obs`
  bindings carry no credentials.
