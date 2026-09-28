# Configuration

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

All variables are read natively by `terraform-provider-hcs` via environment passthrough
— credentials never enter the CSB database. The manifest additionally maps them into
broker config keys (`env_config_mapping`), which is what the per-service
`${config("hcs.region")}` / `${config("hcs.cloud")}` defaults read.

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

- The shipped flavor codes (`rds.pg.n1.large.2[.ha]`, `gaussdb.opengauss.ee.*`) come
  from the provider documentation examples; verify them against your site's flavor
  catalog and override where needed.
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
| `availability_zone`/`availability_zones` | all | Site AZ naming (e.g. `az1.dc1`) |
| `vpc_id` + `subnet_name` | all | Existing network; subnets are resolved via `hcs_vpc_subnets` |
| `security_group_id(s)` | mysql, redis, gaussdb, ecs | Existing security groups |

## Service-specific behavior

- **ECS**: `flavor_id` may be set explicitly; otherwise the flavor is auto-resolved
  from the plan's `cores`/`memory_gb` via `hcs_ecs_compute_flavors` in the target AZ.
- **RDS for PostgreSQL (`csb-hcs-rds-postgresql`) bind**: creates a dedicated `hcs_rds_pg_account` per binding with a
  random password; `user_name` defaults to `csb-<binding id>` and hyphens are
  converted to underscores to satisfy PostgreSQL account naming (the name must not
  start with "pg" or a digit). The connection URI targets the default `postgres`
  database.
- **DCS (`csb-hcs-dcs`) — Redis engine**: connection uses `domain_name` (the provider exports no IP attribute);
  flavor auto-resolved from `capacity`/`cache_mode`/`engine_version` via
  `hcs_dcs_flavors`.
- **ELB**: set `ipv4_address` explicitly if you need the private VIP in the binding
  (provider limitation); backend `subnet_id` uses the neutron subnet id resolved from
  `subnet_name`.
- **GaussDB bind**: passes through the instance administrator credentials (no
  per-account resource in provider v2.4.28). Endpoint lists are passed through
  instance details as comma-joined strings and re-split in the bind module.
- **CSMS bind**: reads the latest secret version via `hcs_csms_secret_version`.
- Password inputs left empty on any service are generated by `random_password` with
  HCS-compatible special characters and returned via the binding credentials.
