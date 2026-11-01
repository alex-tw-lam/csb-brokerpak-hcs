# csb-brokerpak-hcs

A [Cloud Service Broker](https://github.com/cloudfoundry/cloud-service-broker) (CSB)
**brokerpak** that provisions services on **Huawei Cloud Stack (HCS) 8.5.x** — Huawei's
air-gapped private cloud — through the [`huaweicloud/hcs` Terraform
provider](https://github.com/huaweicloud/terraform-provider-hcs) (v2.4.26, which targets
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
| CSMS secret | `csb-hcs-csms` | inline: `default` | secret name/value/version |

The pak ships with the CSMS service; see [docs/configuration.md](docs/configuration.md)
for the configuration reference.

## Repository layout

```
manifest.yml                  # brokerpak manifest: tofu + provider binaries, env mapping
hcs-csms.yml                  # the CSMS service definition
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

- The Terraform modules pass `tofu validate` against the real published
  `huaweicloud/hcs` 2.4.26 provider schema, and the broker behavior (catalog,
  provision variables, bind credentials) is covered by integration tests that run
  against a mocked tofu.
- The CSMS service has been exercised end to end (provision, bind, destroy) on a real
  HCS 8.5.1 site with direct OpenTofu runs; the broker flow itself uses the same
  modules.

## License

Apache 2.0 (matching the upstream Cloud Service Broker brokerpaks).
