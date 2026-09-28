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

## Plans for site-specific services

`csb-hcs-mysql`, `csb-hcs-elb` and `csb-hcs-gaussdb` ship with `plans: []` because
their sizing values (RDS/GaussDB flavor spec codes, ELB flavor IDs) are site-specific.
Define plans via environment variables containing a JSON array — the plan `properties`
keys must be declared in that service's `plan_inputs`:

```bash
export GSB_SERVICE_CSB_HCS_MYSQL_PLANS='[{"name":"small","id":"<uuid>","description":"single node 4c16g","display_name":"small","flavor":"rds.mysql.large.4.single"}]'
export GSB_SERVICE_CSB_HCS_ELB_PLANS='[{"name":"default","id":"<uuid>","description":"default ELB","display_name":"default","l4_flavor_id":"<site-flavor-id>","l7_flavor_id":"<site-flavor-id>"}]'
export GSB_SERVICE_CSB_HCS_GAUSSDB_PLANS='[{"name":"default","id":"<uuid>","description":"default GaussDB","display_name":"default","flavor":"gaussdb.opengauss.ee.m6.2xlarge.x868.ha"}]'
```

Notes:

- HA RDS flavors carry an `.ha` suffix and require **two** entries in
  `availability_zones`; single-node flavors use a `.single` suffix with one AZ.
- GaussDB `flavor`/`solution` determine how many availability zones must be provided
  (`hcs1..hcs7` are the HCS-specific combined solutions).
- Plan properties cannot be overridden by user parameters at provision time.
- The Makefile exports sample values for all three variables (see `BROKER_GO_OPTS`);
  replace the `CHANGE_ME`/sample flavor codes before real use. The `.envrc` file
  documents the same for local development.

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
- **MySQL bind**: creates a dedicated `hcs_rds_mysql_account` per binding with a random
  password; `user_name` defaults to `csb-<truncated binding id>`.
- **Redis**: connection uses `domain_name` (the provider exports no IP attribute);
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
