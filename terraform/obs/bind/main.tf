# The bind passes through the bucket connection details; when grant_principal is set it
# additionally attaches a bucket policy granting that principal access. The bucket policy
# is a singleton server-side, so only one grant binding should be active per bucket.
resource "hcs_obs_bucket_policy" "policy" {
  count = local.grant_enabled ? 1 : 0

  bucket = var.bucket_name
  policy = local.policy_json
}
