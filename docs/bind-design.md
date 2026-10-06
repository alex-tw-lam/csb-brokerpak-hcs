# Bind design patterns

Every OSB bind is its own Terraform workspace: computed inputs pull provision
outputs out of `instance.details` via HIL (`${instance.details["..."]}`), and any
resource created there lives exactly as long as the binding — unbind destroys the
workspace. Choosing a bind design therefore means answering one question: **what
should exist for the lifetime of a binding, given how the service authenticates
consumers?**

The five patterns used across this brokerpak, with the rationale and how the
official AWS/Azure/GCP brokerpaks solve the same problem:

## 1. Passthrough (ECS, OBS default)

No resources. The bind echoes the connection details (addresses, domain names,
ports) from provision outputs; the app authenticates with credentials it already
owns.

- **When**: the service authenticates the client itself (S3-style request signing,
  cloud IAM) and no tighter scoping is possible, or the credential is a fixed
  master secret shared with the provision owner.
- **Reference**: the Azure brokerpak takes this to its degenerate form — the
  `azure-redis` and `azure-mongodb` binds are `noop.tf` templates with no outputs
  at all; consumers are expected to use the provision outputs / console.

## 2. Credential minting (RDS PostgreSQL, DCS account mode)

Bind creates a fresh identity *inside the service's own account subsystem* plus a
random secret, and returns them. Unbind deletes the account — instant revocation,
least privilege, one credential per binding.

- **When**: the service has a native account concept (SQL users, Redis ACL
  accounts, cloud IAM users).
- **Reference**: AWS S3 bind = `aws_iam_user` + `aws_iam_access_key` +
  `aws_iam_user_policy` (a bucket-scoped inline policy for the minted user).
  GCP Storage bind = `google_service_account` + `google_service_account_key` +
  `google_storage_bucket_iam_member`. Azure MSSQL bind = `csbsqlserver_binding`
  with a random username/password and `db_owner`.
- **HCS**: identity lives in the VDC plane — `hcs_vdc_user` (with
  `auth_type = MACHINE_USER` + `access_mode = programmatic` for app identities),
  plus `hcs_vdc_user_group`, `hcs_vdc_role`, `hcs_vdc_group_role_assignment`,
  `hcs_vdc_agency`, `hcs_vdc_project`, backed by HCS `rest/vdc/v3.x` APIs. A VDC
  user can be minted, but the provider has no resource that issues an access key
  (AK/SK) for one, so OBS-style signature credentials cannot be minted
  end-to-end; DCS (`hcs_dcs_account`) and RDS (`hcs_rds_pg_account`) mint
  service-native accounts instead.

## 3. Permission grant (OBS opt-in)

Bind attaches a policy/ACL to the resource naming an *existing* principal. No new
credential exists; the consumer keeps using its own identity, which has just been
authorized on the resource. Unbind detaches the policy.

- **When**: consumers already hold a cloud identity and the resource supports a
  attachable policy.
- **Implementation**: `hcs_obs_bucket_policy` with `ListBucket` on the bucket and
  `GetObject`/`PutObject`/`DeleteObject` on the objects, principal
  `domain/<account-id>:user/<name>`; read or read-write.
- **Caveat**: both bucket policies and bucket ACLs are singletons server-side, so
  at most one grant binding should be active per bucket — hence opt-in.
- **Variant (unimplemented)**: cross-account grants via `hcs_obs_bucket_acl`
  `account_permission { account_id, permission }`.
- GCP's bind is really patterns 2+3 fused (mint an SA, then grant it a role).

## 4. Backend registration (ELB)

The provisioned resource is a traffic entry point; the consumer is a backend.
Bind registers the consumer's address in the resource's pool (+ health monitor);
unbind deregisters. No credential is involved.

- **When**: load balancers and similar fan-in resources. None of the three
  reference brokerpaks ship an LB service, so this pattern has no cross-cloud
  precedent here; the mental model is a Kubernetes Service's endpoints.

## 5. Secret read-back (CSMS)

The resource *is* a credential container. Provision writes the secret (or lets
CSMS generate it); bind reads the latest version back out. Symmetric to pattern 1
but the payload is the secret itself, not connection info.

- **Reference**: none of the AWS/Azure/GCP brokerpaks include a secret-manager
  service; this pattern is standard for them (AWS would use
  `aws_secretsmanager_secret_version` data source).

## The decision rule

Ask, in order:

1. Does the service have its own account subsystem → **mint** (pattern 2).
2. If not, do consumers hold a cloud identity the resource can authorize →
   **grant** (pattern 3).
3. If neither, is there anything to attach the consumer to → **register**
   (pattern 4).
4. Is the resource itself the secret → **read back** (pattern 5).
5. Otherwise → **passthrough** (pattern 1).

Site feature flags can gate pattern 2 (e.g. DCS accounts need
`feature.dcs2.support.acl`; bind_mode falls back to passthrough).
