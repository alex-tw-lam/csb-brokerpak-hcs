# Installation

This guide covers building the brokerpak and getting it served by Cloud Service Broker
(CSB), with particular attention to the air-gapped HCS workflow.

## Prerequisites

| Tool | Used for | Version |
|---|---|---|
| Go | `go run ... pak build`, integration tests | 1.24+ |
| curl, sha256sum | `scripts/fetch-binaries.sh` | any |
| OpenTofu (`tofu`) | `tofu fmt` in `make lint`, optional local validation | 1.6+ |

## Build

```bash
# Stage release binaries into ./bin (the ONLY step that requires internet).
# Downloads tofu 1.11.8, terraform-provider-hcs 2.4.28 and
# terraform-provider-random 3.9.0 for linux/amd64, verifies SHA256 checksums and
# unpacks them into bin/<name>_<version>_<os>_<arch>/ directories.
make fetch-binaries

# Build (offline once ./bin is staged). Produces hcs-services-0.1.0.brokerpak.
make build

# Validate the built pak (strict schema check of manifest + definitions + templates).
make validate

# Optional: generated user-facing docs for every service.
make docs
```

The manifest's `url_template` entries (e.g.
`./bin/${name}_${version}_${os}_${arch}/${name}_v${version}`) make `pak build` copy the
binaries from the local `bin/` directory instead of downloading them. Note that CSB
copies local files verbatim, so the binaries must be **unpacked** — which is what
`fetch-binaries.sh` does. For another target platform stage with `PAK_OS`/`PAK_ARCH`:

```bash
PAK_OS=linux PAK_ARCH=arm64 scripts/fetch-binaries.sh
```

## Air-gapped workflow

1. On a connected machine: `make fetch-binaries` (or download the three releases
   listed in `manifest.yml`, verify their checksums and unpack them into `bin/`).
2. Transfer this repository **including `bin/`** into the air-gapped environment.
3. `make build && make validate` there — no network access is needed.
4. Ship the resulting `hcs-services-<version>.brokerpak` next to the CSB binary.
5. At runtime CSB extracts tofu and the providers from the pak and runs
   `tofu init -plugin-dir=...`; the HCS API is the only outbound connection.

Note: the broker refuses to start until the plan environment variables for
`csb-hcs-mysql`, `csb-hcs-elb` and `csb-hcs-gaussdb` are set (see
configuration.md) — their flavor codes are site-specific by design.

## Running CSB with the brokerpak

CSB discovers brokerpaks via `GSB_BROKERPAK_BUILTIN_PATH` (a directory containing
`*.brokerpak` files, default `./`) or via `brokerpak.sources` URIs in its config file.
Minimal local run:

```bash
export GSB_BROKERPAK_BUILTIN_PATH=$PWD
export SECURITY_USER_NAME=user SECURITY_USER_PASSWORD=pass
export DB_TYPE=sqlite3 DB_PATH=/tmp/csb-hcs.db
export HCS_ACCESS_KEY=... HCS_SECRET_KEY=...     # credentials via environment
$EDITOR config/site-values.yaml   # ...everything else in one file
make gen-config                   # -> hcs-broker.yaml + examples/*/provision.tfvars
go run github.com/cloudfoundry/cloud-service-broker/v2 serve --config hcs-broker.yaml
```

For a container image, start from the CSB release binary (see
[cloud-service-broker](https://github.com/cloudfoundry/cloud-service-broker)) and copy
the `.brokerpak` into the image's working directory, or use the upstream `Dockerfile`
as a base. The upstream repository also ships a `k8s/csb-deployment.yaml` example
(Deployment + Service on port 8080, config via ConfigMap, credentials via Secrets) that
works unchanged with this pak; use MySQL instead of SQLite for production deployments.

## Kubernetes / Service Catalog side

Install the maintained fork of Service Catalog and register the broker:

```bash
helm install catalog oci://registry.drycc.cc/charts/catalog --namespace catalog
```

Then apply a `ClusterServiceBroker` pointing at the CSB service URL with basic auth
(see the snippet in the top-level README). After the broker relists, the six
`csb-hcs-*` services appear as `ClusterServiceClass`es and can be consumed through
`ServiceInstance`/`ServiceBinding` resources or the `svcat` CLI.

## Testing

```bash
make test   # lint + integration tests (mocked tofu; no HCS connection required)
```

The integration suite uses CSB's `brokerpaktestframework` with a mock tofu binary: it
asserts the catalog contents, the exact Terraform variables passed on provision, bind
credential shapes, plan-property immutability and input constraints.

Live acceptance against a real HCS 8.5.x site has not been performed yet; expect to
adjust flavor codes, image names, disk types and AZ names per site (see
configuration.md) before first use.
