# csb-brokerpak-hcs

A [Cloud Service Broker](https://github.com/cloudfoundry/cloud-service-broker) (CSB)
**brokerpak** that provisions services on **Huawei Cloud Stack (HCS) 8.5.x** — Huawei's
air-gapped private cloud — through the [`huaweicloud/hcs` Terraform
provider](https://github.com/huaweicloud/terraform-provider-hcs) (v2.4.28, which targets
HCS 8.3.1/8.5.x).

## Where this fits

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Kubernetes                                                                    │
│                                                                              │
│  ┌──────────────────────┐      ┌──────────────────────────────────────────┐  │
│  │ Service Catalog      │ OSB  │ Cloud Service Broker (CSB)               │  │
│  │ (drycc-addons fork)  │─────▶│  └─ hcs-services.brokerpak               │  │
│  │                      │ HTTP │      ├─ OpenTofu (bundled)               │  │
│  │ ClusterServiceBroker │ basic│      └─ terraform-provider-hcs (bundled) │  │
│  │ ServiceInstance      │ auth │                                          │  │
│  │ ServiceBinding ──▶ Secret  └──────────────────────┬───────────────────┘  │
│  └──────────────────────┘                             │                      │
└───────────────────────────────────────────────────────┼──────────────────────┘
                                                        │ HCS APIs (Keystone v3
                                                        │ auth, endpoints derived
                                                        ▼ from HCS_CLOUD)
                                              ┌───────────────────┐
                                              │ Huawei Cloud Stack │
                                              │ 8.5.1              │
                                              └───────────────────┘
```

- Developers create `ServiceInstance`/`ServiceBinding` custom resources (or use `svcat`);
  Service Catalog translates them into [Open Service Broker
  API](https://github.com/openservicebrokerapi/servicebroker) calls against CSB.
- CSB executes the per-service Terraform (OpenTofu) modules shipped inside the brokerpak.
- Bind credentials come back as ordinary Kubernetes `Secret`s.
- Everything CSB needs at runtime (tofu binary + providers) is bundled **inside** the
  `.brokerpak` — no registry access is ever required, which is what makes this usable in
  an air-gapped HCS environment.

## Services

| Service | Name | Plans | Bind credentials |
|---|---|---|---|
| ECS compute instance | `csb-hcs-ecs` | inline: small/medium/large (cores/memory; flavor auto-resolved) | instance addresses |
| RDS for PostgreSQL | `csb-hcs-rds-postgresql` | inline: small (single node), medium/large (primary/standby) | per-binding DB account (`username`/`password`/`hostname`/`port`/`uri`/`jdbcUrl`) |
| DCS (Redis engine) | `csb-hcs-dcs` | inline: small/medium/large single-node + ha-large (capacity; flavor auto-resolved) | `host`/`port`/`password`/`uri` |
| Elastic Load Balance | `csb-hcs-elb` | operator-configured (ELB flavor IDs are site-specific) | VIP/EIP + listener |
| GaussDB (openGauss) | `csb-hcs-gaussdb` | inline: small (centralized HA), medium/large (distributed) | administrator credentials + endpoints |
| CSMS secret | `csb-hcs-csms` | inline: `default` | secret name/value/version |

Only `csb-hcs-elb` needs operator-defined plans via environment variables (its flavor
IDs are site-specific); see [docs/configuration.md](docs/configuration.md) for the full
configuration reference, including how to override the inline plans per site.

## Repository layout

```
manifest.yml                  # brokerpak manifest: tofu + provider binaries, env mapping
hcs-*.yml                     # one service definition per service
terraform/<svc>/{provision,bind}/*.tf
integration-tests/            # brokerpaktestframework suite (mocked tofu, runs offline)
scripts/fetch-binaries.sh     # the only step that needs internet: stages ./bin zips
bin/                          # staged release zips (gitignored)
docs/                         # installation & configuration guides
.reference/                   # reference repositories used to build this pak (gitignored)
```

## Quickstart

Prerequisites: Go 1.24+, curl, sha256sum, and OpenTofu (for `tofu fmt` in `make lint`).

```bash
# 1. Stage the tofu + provider release zips (internet required, checksum-verified)
make fetch-binaries

# 2. Build and validate the brokerpak (fully offline once ./bin is staged)
make build
make validate

# 3. Run the integration tests (mocked Terraform — no HCS access needed)
make test

# 4. Serve the broker locally (configure HCS_* env first, see docs/configuration.md)
make run

# 5. Check the catalog
curl -s -u user:pass http://localhost:8080/v2/catalog | jq '.services[].name'
```

The build produces `hcs-services-0.1.0.brokerpak`. Point CSB at it via
`GSB_BROKERPAK_BUILTIN_PATH` (place the file in that directory) or `brokerpak.sources`
in the CSB config. See [docs/installation.md](docs/installation.md) for the full
air-gapped workflow and CSB deployment notes.

## Service Catalog integration (short pointer)

On the Kubernetes side use the maintained OSS fork
[drycc-addons/service-catalog](https://github.com/drycc-addons/service-catalog)
(v0.5.x, CRD + webhook architecture):

```bash
helm install catalog oci://registry.drycc.cc/charts/catalog --namespace catalog
```

Mirror `registry.drycc.cc/drycc-addons/service-catalog:<tag>` into your private
registry for offline installs. Then register CSB as a broker:

```yaml
apiVersion: servicecatalog.k8s.io/v1beta1
kind: ClusterServiceBroker
metadata:
  name: csb-hcs
spec:
  url: http://csb-hcs.csb.svc.cluster.local:8080
  authInfo:
    basic:
      secretRef:
        name: csb-hcs-auth
        namespace: csb
---
apiVersion: v1
kind: Secret
metadata:
  name: csb-hcs-auth
  namespace: csb
type: Opaque
stringData:
  username: user
  password: pass
```

`ServiceInstance` creates/deletes HCS resources via the broker; `ServiceBinding` writes
the bind credentials into a `Secret` in the instance's namespace.

## Verification status & known limitations

- Every Terraform module in this pak passes `tofu validate` against the real published
  `huaweicloud/hcs` 2.4.28 provider schema, and the full broker behavior (catalog,
  provision variables, bind credentials, plan/property rules) is covered by 28
  integration tests that run against a mocked tofu.
- **No live HCS acceptance testing has been performed yet** — the environment is
  air-gapped. Flavor codes, image names, disk types and AZ names are site-specific and
  must be configured per site (see docs/configuration.md).
- The HCS provider exports no private VIP attribute for ELB; the binding only carries
  the VIP when `ipv4_address` was set explicitly at provision time.
- GaussDB has no per-account resource in provider v2.4.28, so its binding passes
  through the instance administrator credentials.
- RDS/GaussDB/DCS topology arguments (AZ, VPC, subnet, engine, volume type) are
  ForceNew in the provider and marked `prohibit_update` in the service definitions.

## License

Apache 2.0 (matching the upstream Cloud Service Broker brokerpaks).
