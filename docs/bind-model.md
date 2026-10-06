# The binding model, in pictures

Every OSB service instance has **one provision workspace** and **zero or more
bind workspaces**, each an independent tofu workspace with its own state. The
broker stitches them together with HIL: provision outputs land in
`instance.details`, and bind computed inputs read them back with
`${instance.details["..."]}`. A binding's resources live exactly as long as the
binding — unbind runs `tofu destroy` in the bind workspace.

```mermaid
sequenceDiagram
    participant SC as Service Catalog / OSB client
    participant B as CSB broker
    participant P as provision workspace
    participant BD as bind workspace
    participant H as HCS

    SC->>B: PUT /v2/service_instances/... (provision)
    B->>P: tofu apply (plan + user inputs + site config)
    P->>H: create the service resource
    P-->>B: outputs → stored as instance.details

    SC->>B: PUT .../service_bindings/... (bind)
    B->>BD: tofu apply, vars include ${instance.details["…"]}
    BD->>H: create binding-scoped resources (if the pattern has any)
    BD-->>B: outputs → binding credentials
    B-->>SC: 201 {credentials}

    SC->>B: DELETE .../service_bindings/... (unbind)
    B->>BD: tofu destroy — revoke / deregister / delete account
```

## The five bind patterns

### ① Passthrough — hand over connection info

No bind resources. The app already owns credentials; the bind only returns
addresses.

```mermaid
flowchart LR
    B["bind workspace<br/>(no resources)"] -->|echo| O["outputs:<br/>bucket, domain, port"]
    A["app"] -->|"connects with its OWN AK/SK"| R[("OBS bucket")]
```

### ② Credential minting — create an identity inside the service

The bind creates a fresh account + random secret in the service's own account
subsystem. Unbind deletes it — instant revocation.

```mermaid
flowchart LR
    B["bind workspace"] -->|creates| C["account + random password<br/>(hcs_rds_pg_account / hcs_dcs_account)"]
    A["app"] -->|"minted username/password"| R[("RDS / DCS instance")]
```

### ③ Permission grant — authorize an existing identity

The bind attaches a policy naming a principal that already exists. No new
credential is created; unbind detaches the policy.

```mermaid
flowchart LR
    B["bind workspace"] -->|attaches| P["bucket policy<br/>Principal: domain/…:user/… | group/… | agency/…"]
    A["app with existing identity"] -->|"own AK/SK, now authorized"| R[("OBS bucket")]
```

### ④ Backend registration — attach the consumer to an entry point

The provisioned resource fans traffic in; the bind registers the app's address
(+ health monitor) in its pool. No credentials involved.

```mermaid
flowchart LR
    C["client traffic"] --> L[("ELB listener / pool")]
    B["bind workspace"] -->|adds| M["pool member + TCP monitor<br/>(app address:port)"]
    L --> M
    M --> A["app backend"]
```

### ⑤ Secret read-back — the resource is the credential

Provision writes (or generates) the secret; the bind reads the latest version
back out with a data source.

```mermaid
flowchart LR
    P["provision"] -->|stores| S[("CSMS secret")]
    B["bind workspace"] -->|"data source reads latest version"| S
    B --> O["outputs: name, value, version"]
```

## Choosing a pattern

```mermaid
flowchart TD
    Q1{"service has its own<br/>account subsystem?"} -->|yes| M["② mint<br/>(RDS-PG, DCS account mode)"]
    Q1 -->|no| Q2{"resource can authorize an<br/>existing cloud identity?"}
    Q2 -->|yes| G["③ grant<br/>(OBS)"]
    Q2 -->|no| Q3{"resource is a traffic<br/>entry point?"}
    Q3 -->|yes| RG["④ register<br/>(ELB)"]
    Q3 -->|no| Q4{"the resource itself<br/>is a secret?"}
    Q4 -->|yes| RB["⑤ read-back<br/>(CSMS)"]
    Q4 -->|no| PT["① passthrough<br/>(ECS, OBS default, DCS passthrough mode)"]
```

Site feature flags can force a fallback (e.g. DCS accounts need
`feature.dcs2.support.acl`; without it bind_mode falls back to passthrough).
