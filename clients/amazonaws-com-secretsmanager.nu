# Auto-generated client for AWS Secrets Manager v2017-10-17
# Source: https://api.apis.guru/v2/specs/amazonaws.com/secretsmanager/2017-10-17/openapi.json
# Auth: --token flag or $env.AWS_SECRETS_MANAGER_TOKEN

const BASE_URL = "http://secretsmanager.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_SECRETS_MANAGER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://secretsmanager.us-east-1.amazonaws.com" "http://secretsmanager.us-east-2.amazonaws.com" "http://secretsmanager.us-west-1.amazonaws.com" "http://secretsmanager.us-west-2.amazonaws.com" "http://secretsmanager.us-gov-west-1.amazonaws.com" "http://secretsmanager.us-gov-east-1.amazonaws.com" "http://secretsmanager.ca-central-1.amazonaws.com" "http://secretsmanager.eu-north-1.amazonaws.com" "http://secretsmanager.eu-west-1.amazonaws.com" "http://secretsmanager.eu-west-2.amazonaws.com" "http://secretsmanager.eu-west-3.amazonaws.com" "http://secretsmanager.eu-central-1.amazonaws.com" "http://secretsmanager.eu-south-1.amazonaws.com" "http://secretsmanager.af-south-1.amazonaws.com" "http://secretsmanager.ap-northeast-1.amazonaws.com" "http://secretsmanager.ap-northeast-2.amazonaws.com" "http://secretsmanager.ap-northeast-3.amazonaws.com" "http://secretsmanager.ap-southeast-1.amazonaws.com" "http://secretsmanager.ap-southeast-2.amazonaws.com" "http://secretsmanager.ap-east-1.amazonaws.com" "http://secretsmanager.ap-south-1.amazonaws.com" "http://secretsmanager.sa-east-1.amazonaws.com" "http://secretsmanager.me-south-1.amazonaws.com" "https://secretsmanager.us-east-1.amazonaws.com" "https://secretsmanager.us-east-2.amazonaws.com" "https://secretsmanager.us-west-1.amazonaws.com" "https://secretsmanager.us-west-2.amazonaws.com" "https://secretsmanager.us-gov-west-1.amazonaws.com" "https://secretsmanager.us-gov-east-1.amazonaws.com" "https://secretsmanager.ca-central-1.amazonaws.com" "https://secretsmanager.eu-north-1.amazonaws.com" "https://secretsmanager.eu-west-1.amazonaws.com" "https://secretsmanager.eu-west-2.amazonaws.com" "https://secretsmanager.eu-west-3.amazonaws.com" "https://secretsmanager.eu-central-1.amazonaws.com" "https://secretsmanager.eu-south-1.amazonaws.com" "https://secretsmanager.af-south-1.amazonaws.com" "https://secretsmanager.ap-northeast-1.amazonaws.com" "https://secretsmanager.ap-northeast-2.amazonaws.com" "https://secretsmanager.ap-northeast-3.amazonaws.com" "https://secretsmanager.ap-southeast-1.amazonaws.com" "https://secretsmanager.ap-southeast-2.amazonaws.com" "https://secretsmanager.ap-east-1.amazonaws.com" "https://secretsmanager.ap-south-1.amazonaws.com" "https://secretsmanager.sa-east-1.amazonaws.com" "https://secretsmanager.me-south-1.amazonaws.com" "http://secretsmanager.cn-north-1.amazonaws.com.cn" "http://secretsmanager.cn-northwest-1.amazonaws.com.cn" "https://secretsmanager.cn-north-1.amazonaws.com.cn" "https://secretsmanager.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["secretsmanager.CancelRotateSecret"] }
def x-amz-target-completer-1 [] { ["secretsmanager.CreateSecret"] }
def x-amz-target-completer-2 [] { ["secretsmanager.DeleteResourcePolicy"] }
def x-amz-target-completer-3 [] { ["secretsmanager.DeleteSecret"] }
def x-amz-target-completer-4 [] { ["secretsmanager.DescribeSecret"] }
def x-amz-target-completer-5 [] { ["secretsmanager.GetRandomPassword"] }
def x-amz-target-completer-6 [] { ["secretsmanager.GetResourcePolicy"] }
def x-amz-target-completer-7 [] { ["secretsmanager.GetSecretValue"] }
def x-amz-target-completer-8 [] { ["secretsmanager.ListSecretVersionIds"] }
def x-amz-target-completer-9 [] { ["secretsmanager.ListSecrets"] }
def x-amz-target-completer-10 [] { ["secretsmanager.PutResourcePolicy"] }
def x-amz-target-completer-11 [] { ["secretsmanager.PutSecretValue"] }
def x-amz-target-completer-12 [] { ["secretsmanager.RemoveRegionsFromReplication"] }
def x-amz-target-completer-13 [] { ["secretsmanager.ReplicateSecretToRegions"] }
def x-amz-target-completer-14 [] { ["secretsmanager.RestoreSecret"] }
def x-amz-target-completer-15 [] { ["secretsmanager.RotateSecret"] }
def x-amz-target-completer-16 [] { ["secretsmanager.StopReplicationToReplica"] }
def x-amz-target-completer-17 [] { ["secretsmanager.TagResource"] }
def x-amz-target-completer-18 [] { ["secretsmanager.UntagResource"] }
def x-amz-target-completer-19 [] { ["secretsmanager.UpdateSecret"] }
def x-amz-target-completer-20 [] { ["secretsmanager.UpdateSecretVersionStage"] }
def x-amz-target-completer-21 [] { ["secretsmanager.ValidateResourcePolicy"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api cancel-rotate-secret" } } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name not-in [$mod_name "commands"] | get decl_id)
  scope commands | where decl_id in $cmd_ids | each {|cmd|
    let sig = $cmd.signatures | values | first
    let params = $sig
      | where parameter_type not-in ["input" "output"]
      | where parameter_name not-in $builtin_flags
      | select parameter_name parameter_type syntax_shape is_optional description
    let return_type = ($sig | where parameter_type == "output" | get -o syntax_shape | first | default "any")
    {
      name: ($cmd.name | str replace $"($mod_name) " "")
      description: $cmd.description
      extra_description: $cmd.extra_description
      return_type: $return_type
      params: $params
    }
  }
}

# Turns off automatic rotation, and if a rotation is currently in progress, cancels the rotation. If you cancel a rotation in progress, it can leave the VersionStage labels in an unexpected state. You might need to remove the staging label AWSPENDING from the partially created version. You also need to determine whether to roll back to the previous version of the secret by moving the staging label AWSCURRENT to the version that has AWSPENDING. To determine which version has a specific staging label, call ListSecretVersionIds. Then use UpdateSecretVersionStage to change staging labels. For more information, see How rotation works (https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotate-secrets_how.html). To turn on automatic rotation again, call RotateSecret. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:CancelRotateSecret. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: CancelRotateSecret
export def "api cancel-rotate-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer
  secret_id: any
]: any -> record<ARN: record, Name: record, VersionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new secret. A secret can be a password, a set of credentials such as a user name and password, an OAuth token, or other secret information that you store in an encrypted form in Secrets Manager. The secret also includes the connection information to access a database or other service, which Secrets Manager doesn't encrypt. A secret in Secrets Manager consists of both the protected secret data and the important information needed to manage the secret. For secrets that use managed rotation, you need to create the secret through the managing service. For more information, see Secrets Manager secrets managed by other Amazon Web Services services (https://docs.aws.amazon.com/secretsmanager/latest/userguide/service-linked-secrets.html). For information about creating a secret in the console, see Create a secret (https://docs.aws.amazon.com/secretsmanager/latest/userguide/manage_create-basic-secret.html). To create a secret, you can provide the secret value to be encrypted in either the SecretString parameter or the SecretBinary parameter, but not both. If you include SecretString or SecretBinary then Secrets Manager creates an initial secret version and automatically attaches the staging label AWSCURRENT to it. For database credentials you want to rotate, for Secrets Manager to be able to rotate the secret, you must make sure the JSON you store in the SecretString matches the JSON structure of a database secret (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html). If you don't specify an KMS encryption key, Secrets Manager uses the Amazon Web Services managed key aws/secretsmanager. If this key doesn't already exist in your account, then Secrets Manager creates it for you automatically. All users and roles in the Amazon Web Services account automatically have access to use aws/secretsmanager. Creating aws/secretsmanager can result in a one-time significant delay in returning the result. If the secret is in a different Amazon Web Services account from the credentials calling the API, then you can't use aws/secretsmanager to encrypt the secret, and you must create and use a customer managed KMS key. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters except SecretBinary or SecretString because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:CreateSecret. If you include tags in the secret, you also need secretsmanager:TagResource. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html). To encrypt the secret with a KMS key other than aws/secretsmanager, you need kms:GenerateDataKey and kms:Decrypt permission to the key.
#
# POST /
# operationId: CreateSecret
export def "api create-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1
  name: any
  --client-request-token: any
  --description: any
  --kms-key-id: any
  --secret-binary: any
  --secret-string: any
  --tags: any
  --add-replica-regions: any
  --force-overwrite-replica-secret: any
]: any -> record<ARN: record, Name: record, VersionId: record, ReplicationStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ClientRequestToken": $client_request_token, "Description": $description, "KmsKeyId": $kms_key_id, "SecretBinary": $secret_binary, "SecretString": $secret_string, "Tags": $tags, "AddReplicaRegions": $add_replica_regions, "ForceOverwriteReplicaSecret": $force_overwrite_replica_secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the resource-based permission policy attached to the secret. To attach a policy to a secret, use PutResourcePolicy. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:DeleteResourcePolicy. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: DeleteResourcePolicy
export def "api delete-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-2
  secret_id: any
]: any -> record<ARN: record, Name: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a secret and all of its versions. You can specify a recovery window during which you can restore the secret. The minimum recovery window is 7 days. The default recovery window is 30 days. Secrets Manager attaches a DeletionDate stamp to the secret that specifies the end of the recovery window. At the end of the recovery window, Secrets Manager deletes the secret permanently. You can't delete a primary secret that is replicated to other Regions. You must first delete the replicas using RemoveRegionsFromReplication, and then delete the primary secret. When you delete a replica, it is deleted immediately. You can't directly delete a version of a secret. Instead, you remove all staging labels from the version using UpdateSecretVersionStage. This marks the version as deprecated, and then Secrets Manager can automatically delete the version in the background. To determine whether an application still uses a secret, you can create an Amazon CloudWatch alarm to alert you to any attempts to access a secret during the recovery window. For more information, see Monitor secrets scheduled for deletion (https://docs.aws.amazon.com/secretsmanager/latest/userguide/monitoring_cloudwatch_deleted-secrets.html). Secrets Manager performs the permanent secret deletion at the end of the waiting period as a background task with low priority. There is no guarantee of a specific time after the recovery window for the permanent delete to occur. At any time before recovery window ends, you can use RestoreSecret to remove the DeletionDate and cancel the deletion of the secret. When a secret is scheduled for deletion, you cannot retrieve the secret value. You must first cancel the deletion with RestoreSecret and then you can retrieve the secret. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:DeleteSecret. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: DeleteSecret
export def "api delete-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3
  secret_id: any
  --recovery-window-in-days: any
  --force-delete-without-recovery: any
]: any -> record<ARN: record, Name: record, DeletionDate: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "RecoveryWindowInDays": $recovery_window_in_days, "ForceDeleteWithoutRecovery": $force_delete_without_recovery} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the details of a secret. It does not include the encrypted secret value. Secrets Manager only returns fields that have a value in the response. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:DescribeSecret. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: DescribeSecret
export def "api get-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4
  secret_id: any
]: any -> record<ARN: record, Name: record, Description: record, KmsKeyId: record, RotationEnabled: record, RotationLambdaARN: record, RotationRules: record<AutomaticallyAfterDays: record, Duration: record, ScheduleExpression: record>, LastRotatedDate: record, LastChangedDate: record, LastAccessedDate: record, DeletedDate: record, NextRotationDate: record, Tags: record, VersionIdsToStages: record, OwningService: record, CreatedDate: record, PrimaryRegion: record, ReplicationStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Generates a random password. We recommend that you specify the maximum length and include every character type that the system you are generating a password for can support. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:GetRandomPassword. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: GetRandomPassword
export def "api get-random-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5
  --password-length: any
  --exclude-characters: any
  --exclude-numbers: any
  --exclude-punctuation: any
  --exclude-uppercase: any
  --exclude-lowercase: any
  --include-space: any
  --require-each-included-type: any
]: any -> record<RandomPassword: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"PasswordLength": $password_length, "ExcludeCharacters": $exclude_characters, "ExcludeNumbers": $exclude_numbers, "ExcludePunctuation": $exclude_punctuation, "ExcludeUppercase": $exclude_uppercase, "ExcludeLowercase": $exclude_lowercase, "IncludeSpace": $include_space, "RequireEachIncludedType": $require_each_included_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the JSON text of the resource-based policy document attached to the secret. For more information about permissions policies attached to a secret, see Permissions policies attached to a secret (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_resource-policies.html). Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:GetResourcePolicy. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: GetResourcePolicy
export def "api get-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6
  secret_id: any
]: any -> record<ARN: record, Name: record, ResourcePolicy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the contents of the encrypted fields SecretString or SecretBinary from the specified version of a secret, whichever contains content. We recommend that you cache your secret values by using client-side caching. Caching secrets improves speed and reduces your costs. For more information, see Cache secrets for your applications (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieving-secrets.html). To retrieve the previous version of a secret, use VersionStage and specify AWSPREVIOUS. To revert to the previous version of a secret, call UpdateSecretVersionStage (https://docs.aws.amazon.com/cli/latest/reference/secretsmanager/update-secret-version-stage.html). Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:GetSecretValue. If the secret is encrypted using a customer-managed key instead of the Amazon Web Services managed key aws/secretsmanager, then you also need kms:Decrypt permissions for that key. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: GetSecretValue
export def "api get-secret-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-7
  secret_id: any
  --version-id: any
  --version-stage: any
]: any -> record<ARN: record, Name: record, VersionId: record, SecretBinary: record, SecretString: record, VersionStages: record, CreatedDate: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "VersionId": $version_id, "VersionStage": $version_stage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the versions of a secret. Secrets Manager uses staging labels to indicate the different versions of a secret. For more information, see Secrets Manager concepts: Versions (https://docs.aws.amazon.com/secretsmanager/latest/userguide/getting-started.html#term_version). To list the secrets in the account, use ListSecrets. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:ListSecretVersionIds. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: ListSecretVersionIds
export def "api list-secret-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-8
  secret_id: any
  --max-results-body: any #  (body field)
  --next-token-body: any #  (body field)
  --include-deprecated: any
]: any -> record<Versions: record, NextToken: record, ARN: record, Name: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"SecretId": $secret_id, "MaxResults": $max_results_body, "NextToken": $next_token_body, "IncludeDeprecated": $include_deprecated} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the secrets that are stored by Secrets Manager in the Amazon Web Services account, not including secrets that are marked for deletion. To see secrets marked for deletion, use the Secrets Manager console. ListSecrets is eventually consistent, however it might not reflect changes from the last five minutes. To get the latest information for a specific secret, use DescribeSecret. To list the versions of a secret, use ListSecretVersionIds. To get the secret value from SecretString or SecretBinary, call GetSecretValue. For information about finding secrets in the console, see Find secrets in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/manage_search-secret.html). Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:ListSecrets. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: ListSecrets
export def "api list-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-9
  --include-planned-deletion: any
  --max-results-body: any #  (body field)
  --next-token-body: any #  (body field)
  --filters: any
  --sort-order: any
]: any -> record<SecretList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"IncludePlannedDeletion": $include_planned_deletion, "MaxResults": $max_results_body, "NextToken": $next_token_body, "Filters": $filters, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Attaches a resource-based permission policy to a secret. A resource-based policy is optional. For more information, see Authentication and access control for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html) For information about attaching a policy in the console, see Attach a permissions policy to a secret (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_resource-based-policies.html). Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:PutResourcePolicy. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: PutResourcePolicy
export def "api update-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-10
  secret_id: any
  resource_policy: any
  --block-public-policy: any
]: any -> record<ARN: record, Name: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "ResourcePolicy": $resource_policy, "BlockPublicPolicy": $block_public_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new version with a new encrypted secret value and attaches it to the secret. The version can contain a new SecretString value or a new SecretBinary value. We recommend you avoid calling PutSecretValue at a sustained rate of more than once every 10 minutes. When you update the secret value, Secrets Manager creates a new version of the secret. Secrets Manager removes outdated versions when there are more than 100, but it does not remove versions created less than 24 hours ago. If you call PutSecretValue more than once every 10 minutes, you create more versions than Secrets Manager removes, and you will reach the quota for secret versions. You can specify the staging labels to attach to the new version in VersionStages. If you don't include VersionStages, then Secrets Manager automatically moves the staging label AWSCURRENT to this version. If this operation creates the first version for the secret, then Secrets Manager automatically attaches the staging label AWSCURRENT to it. If this operation moves the staging label AWSCURRENT from another version to this version, then Secrets Manager also automatically moves the staging label AWSPREVIOUS to the version that AWSCURRENT was removed from. This operation is idempotent. If you call this operation with a ClientRequestToken that matches an existing version's VersionId, and you specify the same secret data, the operation succeeds but does nothing. However, if the secret data is different, then the operation fails because you can't modify an existing version; you can only create new ones. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters except SecretBinary or SecretString because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:PutSecretValue. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: PutSecretValue
export def "api update-secret-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-11
  secret_id: any
  --client-request-token: any
  --secret-binary: any
  --secret-string: any
  --version-stages: any
]: any -> record<ARN: record, Name: record, VersionId: record, VersionStages: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "ClientRequestToken": $client_request_token, "SecretBinary": $secret_binary, "SecretString": $secret_string, "VersionStages": $version_stages} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# For a secret that is replicated to other Regions, deletes the secret replicas from the Regions you specify. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:RemoveRegionsFromReplication. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: RemoveRegionsFromReplication
export def "api delete-regions-from-replication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-12
  secret_id: any
  remove_replica_regions: any
]: any -> record<ARN: record, ReplicationStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "RemoveReplicaRegions": $remove_replica_regions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replicates the secret to a new Regions. See Multi-Region secrets (https://docs.aws.amazon.com/secretsmanager/latest/userguide/create-manage-multi-region-secrets.html). Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:ReplicateSecretToRegions. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: ReplicateSecretToRegions
export def "api create-replicate-secret-to-regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-13
  secret_id: any
  add_replica_regions: any
  --force-overwrite-replica-secret: any
]: any -> record<ARN: record, ReplicationStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "AddReplicaRegions": $add_replica_regions, "ForceOverwriteReplicaSecret": $force_overwrite_replica_secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancels the scheduled deletion of a secret by removing the DeletedDate time stamp. You can access a secret again after it has been restored. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:RestoreSecret. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: RestoreSecret
export def "api create-restore-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-14
  secret_id: any
]: any -> record<ARN: record, Name: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Configures and starts the asynchronous process of rotating the secret. For information about rotation, see Rotate secrets (https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html) in the Secrets Manager User Guide. If you include the configuration parameters, the operation sets the values for the secret and then immediately starts a rotation. If you don't include the configuration parameters, the operation starts a rotation with the values already stored in the secret. When rotation is successful, the AWSPENDING staging label might be attached to the same version as the AWSCURRENT version, or it might not be attached to any version. If the AWSPENDING staging label is present but not attached to the same version as AWSCURRENT, then any later invocation of RotateSecret assumes that a previous rotation request is still in progress and returns an error. When rotation is unsuccessful, the AWSPENDING staging label might be attached to an empty secret version. For more information, see Troubleshoot rotation (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot_rotation.html) in the Secrets Manager User Guide. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:RotateSecret. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html). You also need lambda:InvokeFunction permissions on the rotation function. For more information, see Permissions for rotation (https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets-required-permissions-function.html).
#
# POST /
# operationId: RotateSecret
export def "api create-rotate-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-15
  secret_id: any
  --client-request-token: any
  --rotation-lambda-arn: any
  --rotation-rules: any
  --rotate-immediately: any
]: any -> record<ARN: record, Name: record, VersionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "ClientRequestToken": $client_request_token, "RotationLambdaARN": $rotation_lambda_arn, "RotationRules": $rotation_rules, "RotateImmediately": $rotate_immediately} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes the link between the replica secret and the primary secret and promotes the replica to a primary secret in the replica Region. You must call this operation from the Region in which you want to promote the replica to a primary secret. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:StopReplicationToReplica. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: StopReplicationToReplica
export def "api stop-replication-to-replica" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16
  secret_id: any
]: any -> record<ARN: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Attaches tags to a secret. Tags consist of a key name and a value. Tags are part of the secret's metadata. They are not associated with specific versions of the secret. This operation appends tags to the existing list of tags. The following restrictions apply to tags: Maximum number of tags per secret: 50 Maximum key length: 127 Unicode characters in UTF-8 Maximum value length: 255 Unicode characters in UTF-8 Tag keys and values are case sensitive. Do not use the aws: prefix in your tag names or values because Amazon Web Services reserves it for Amazon Web Services use. You can't edit or delete tag names or values with this prefix. Tags with this prefix do not count against your tags per secret limit. If you use your tagging schema across multiple services and resources, other services might have restrictions on allowed characters. Generally allowed characters: letters, spaces, and numbers representable in UTF-8, plus the following special characters: + - = . _ : / @. If you use tags as part of your security strategy, then adding or removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:TagResource. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: TagResource
export def "api tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17
  secret_id: any
  tags: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes specific tags from a secret. This operation is idempotent. If a requested tag is not attached to the secret, no error is returned and the secret metadata is unchanged. If you use tags as part of your security strategy, then removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:UntagResource. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: UntagResource
export def "api untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18
  secret_id: any
  tag_keys: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the details of a secret, including metadata and the secret value. To change the secret value, you can also use PutSecretValue. To change the rotation configuration of a secret, use RotateSecret instead. To change a secret so that it is managed by another service, you need to recreate the secret in that service. See Secrets Manager secrets managed by other Amazon Web Services services (https://docs.aws.amazon.com/secretsmanager/latest/userguide/service-linked-secrets.html). We recommend you avoid calling UpdateSecret at a sustained rate of more than once every 10 minutes. When you call UpdateSecret to update the secret value, Secrets Manager creates a new version of the secret. Secrets Manager removes outdated versions when there are more than 100, but it does not remove versions created less than 24 hours ago. If you update the secret value more than once every 10 minutes, you create more versions than Secrets Manager removes, and you will reach the quota for secret versions. If you include SecretString or SecretBinary to create a new secret version, Secrets Manager automatically moves the staging label AWSCURRENT to the new version. Then it attaches the label AWSPREVIOUS to the version that AWSCURRENT was removed from. If you call this operation with a ClientRequestToken that matches an existing version's VersionId, the operation results in an error. You can't modify an existing version, you can only create a new version. To remove a version, remove all staging labels from it. See UpdateSecretVersionStage. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters except SecretBinary or SecretString because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:UpdateSecret. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html). If you use a customer managed key, you must also have kms:GenerateDataKey and kms:Decrypt permissions on the key. For more information, see Secret encryption and decryption (https://docs.aws.amazon.com/secretsmanager/latest/userguide/security-encryption.html).
#
# POST /
# operationId: UpdateSecret
export def "api update-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19
  secret_id: any
  --client-request-token: any
  --description: any
  --kms-key-id: any
  --secret-binary: any
  --secret-string: any
]: any -> record<ARN: record, Name: record, VersionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "ClientRequestToken": $client_request_token, "Description": $description, "KmsKeyId": $kms_key_id, "SecretBinary": $secret_binary, "SecretString": $secret_string} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the staging labels attached to a version of a secret. Secrets Manager uses staging labels to track a version as it progresses through the secret rotation process. Each staging label can be attached to only one version at a time. To add a staging label to a version when it is already attached to another version, Secrets Manager first removes it from the other version first and then attaches it to this one. For more information about versions and staging labels, see Concepts: Version (https://docs.aws.amazon.com/secretsmanager/latest/userguide/getting-started.html#term_version). The staging labels that you specify in the VersionStage parameter are added to the existing list of staging labels for the version. You can move the AWSCURRENT staging label to this version by including it in this call. Whenever you move AWSCURRENT, Secrets Manager automatically moves the label AWSPREVIOUS to the version that AWSCURRENT was removed from. If this action results in the last label being removed from a version, then the version is considered to be 'deprecated' and can be deleted by Secrets Manager. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:UpdateSecretVersionStage. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: UpdateSecretVersionStage
export def "api update-secret-version-stage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20
  secret_id: any
  version_stage: any
  --remove-from-version-id: any
  --move-to-version-id: any
]: any -> record<ARN: record, Name: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "VersionStage": $version_stage, "RemoveFromVersionId": $remove_from_version_id, "MoveToVersionId": $move_to_version_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Validates that a resource policy does not grant a wide range of principals access to your secret. A resource-based policy is optional for secrets. The API performs three checks when validating the policy: Sends a call to Zelkova (https://aws.amazon.com/blogs/security/protect-sensitive-data-in-the-cloud-with-automated-reasoning-zelkova/), an automated reasoning engine, to ensure your resource policy does not allow broad access to your secret, for example policies that use a wildcard for the principal. Checks for correct syntax in a policy. Verifies the policy does not lock out a caller. Secrets Manager generates a CloudTrail log entry when you call this action. Do not include sensitive information in request parameters because it might be logged. For more information, see Logging Secrets Manager events with CloudTrail (https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieve-ct-entries.html). Required permissions: secretsmanager:ValidateResourcePolicy and secretsmanager:PutResourcePolicy. For more information, see IAM policy actions for Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_iam-permissions.html#reference_iam-permissions_actions) and Authentication and access control in Secrets Manager (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access.html).
#
# POST /
# operationId: ValidateResourcePolicy
export def "api validate-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21
  --secret-id: any
  resource_policy: any
]: any -> record<PolicyValidationPassed: record, ValidationErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "ResourcePolicy": $resource_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
