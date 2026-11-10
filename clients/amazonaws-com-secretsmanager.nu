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
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
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
def sort-order-completer [] { ["asc" "desc"] }
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
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["cancel-rotate-secret" "create-secret" "delete-resource-policy" "delete-secret" "describe-secret" "get-random-password" "get-resource-policy" "get-secret-value" "list-secret-version-ids" "list-secrets" "put-resource-policy" "put-secret-value" "remove-regions-from-replication" "replicate-secret-to-regions" "restore-secret" "rotate-secret" "stop-replication-to-replica" "tag-resource" "untag-resource" "update-secret" "update-secret-version-stage" "validate-resource-policy" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "cancel-rotate-secret" [
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
  --x-amz-target: string@x-amz-target-completer # required
  secret_id: string # The ARN or name of the secret. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
]: any -> oneof<record<ARN: string, Name: string, VersionId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.CancelRotateSecret")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-secret" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  name: string # The name of the new secret. The secret name can contain ASCII letters, numbers, and the following characters: /_+=.@- Do not end your secret name with a hyphen followed by six characters. If you do so, you risk confusion and unexpected results when searching for a secret by partial ARN. Secrets Manager automatically adds a hyphen and six random characters after the secret name at the end of the ARN.
  --client-request-token: string # If you include SecretString or SecretBinary, then Secrets Manager creates an initial version for the secret, and this parameter specifies the unique identifier for the new version. If you use the Amazon Web Services CLI or one of the Amazon Web Services SDKs to call this operation, then you can leave this parameter empty. The CLI or SDK generates a random UUID for you and includes it as the value for this parameter in the request. If you don't use the SDK and instead generate a raw HTTP request to the Secrets Manager service endpoint, then you must generate a ClientRequestToken yourself for the new version and include the value in the request. This value helps ensure idempotency. Secrets Manager uses this value to prevent the accidental creation of duplicate versions if there are failures and retries during a rotation. We recommend that you generate a UUID-type (https://wikipedia.org/wiki/Universally_unique_identifier) value to ensure uniqueness of your versions within the specified secret. If the ClientRequestToken value isn't already associated with a version of the secret then a new version of the secret is created. If a version with this value already exists and the version SecretString and SecretBinary values are the same as those in the request, then the request is ignored. If a version with this value already exists and that version's SecretString and SecretBinary values are different from those in the request, then the request fails because you cannot modify an existing version. Instead, use PutSecretValue to create a new version. This value becomes the VersionId of the new version.
  --description: string # The description of the secret.
  --kms-key-id: string # The ARN, key ID, or alias of the KMS key that Secrets Manager uses to encrypt the secret value in the secret. An alias is always prefixed by alias/, for example alias/aws/secretsmanager. For more information, see About aliases (https://docs.aws.amazon.com/kms/latest/developerguide/alias-about.html). To use a KMS key in a different account, use the key ARN or the alias ARN. If you don't specify this value, then Secrets Manager uses the key aws/secretsmanager. If that key doesn't yet exist, then Secrets Manager creates it for you automatically the first time it encrypts the secret value. If the secret is in a different Amazon Web Services account from the credentials calling the API, then you can't use aws/secretsmanager to encrypt the secret, and you must create and use a customer managed KMS key.
  --secret-binary: string # The binary data to encrypt and store in the new version of the secret. We recommend that you store your binary data in a file and then pass the contents of the file as a parameter. Either SecretString or SecretBinary must have a value, but not both. This parameter is not available in the Secrets Manager console. (format: password)
  --secret-string: string # The text data to encrypt and store in this new version of the secret. We recommend you use a JSON structure of key/value pairs for your secret value. Either SecretString or SecretBinary must have a value, but not both. If you create a secret by using the Secrets Manager console then Secrets Manager puts the protected secret text in only the SecretString parameter. The Secrets Manager console stores the information as a JSON structure of key/value pairs that a Lambda rotation function can parse. (format: password)
  --tags: list # A list of tags to attach to the secret. Each tag is a key and value pair of strings in a JSON text string, for example: [{"Key":"CostCenter","Value":"12345"},{"Key":"environment","Value":"production"}] Secrets Manager tag key names are case sensitive. A tag with the key "ABC" is a different tag from one with key "abc". If you check tags in permissions policies as part of your security strategy, then adding or removing a tag can change permissions. If the completion of this operation would result in you losing your permissions for this secret, then Secrets Manager blocks the operation and returns an Access Denied error. For more information, see Control access to secrets using tags (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_examples.html#tag-secrets-abac) and Limit access to identities with tags that match secrets' tags (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_examples.html#auth-and-access_tags2). For information about how to format a JSON parameter for the various command line tool environments, see Using JSON for Parameters (https://docs.aws.amazon.com/cli/latest/userguide/cli-using-param.html#cli-using-param-json). If your command-line tool or SDK requires quotation marks around the parameter, you should use single quotes to avoid confusion with the double quotes required in the JSON text. The following restrictions apply to tags: Maximum number of tags per secret: 50 Maximum key length: 127 Unicode characters in UTF-8 Maximum value length: 255 Unicode characters in UTF-8 Tag keys and values are case sensitive. Do not use the aws: prefix in your tag names or values because Amazon Web Services reserves it for Amazon Web Services use. You can't edit or delete tag names or values with this prefix. Tags with this prefix do not count against your tags per secret limit. If you use your tagging schema across multiple services and resources, other services might have restrictions on allowed characters. Generally allowed characters: letters, spaces, and numbers representable in UTF-8, plus the following special characters: + - = . _ : / @. — item shape: {Key?: string, Value?: string}
  --add-replica-regions: list # A list of Regions and KMS keys to replicate secrets. — item shape: {Region?: string, KmsKeyId?: string}
  --force-overwrite-replica-secret: oneof<nothing, bool> # Specifies whether to overwrite a secret with the same name in the destination Region. By default, secrets aren't overwritten.
]: any -> oneof<record<ARN: string, Name: string, VersionId: string, ReplicationStatus: table<Region: string, KmsKeyId: string, Status: string, StatusMessage: string, LastAccessedDate: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.CreateSecret")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ClientRequestToken": $client_request_token, "Description": $description, "KmsKeyId": $kms_key_id, "SecretBinary": $secret_binary, "SecretString": $secret_string, "Tags": $tags, "AddReplicaRegions": $add_replica_regions, "ForceOverwriteReplicaSecret": $force_overwrite_replica_secret} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-resource-policy" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  secret_id: string # The ARN or name of the secret to delete the attached resource-based policy for. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
]: any -> oneof<record<ARN: string, Name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.DeleteResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-secret" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  secret_id: string # The ARN or name of the secret to delete. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
  --recovery-window-in-days: int # The number of days from 7 to 30 that Secrets Manager waits before permanently deleting the secret. You can't use both this parameter and ForceDeleteWithoutRecovery in the same call. If you don't use either, then by default Secrets Manager uses a 30 day recovery window.
  --force-delete-without-recovery: oneof<nothing, bool> # Specifies whether to delete the secret without any recovery window. You can't use both this parameter and RecoveryWindowInDays in the same call. If you don't use either, then by default Secrets Manager uses a 30 day recovery window. Secrets Manager performs the actual deletion with an asynchronous background process, so there might be a short delay before the secret is permanently deleted. If you delete a secret and then immediately create a secret with the same name, use appropriate back off and retry logic. Use this parameter with caution. This parameter causes the operation to skip the normal recovery window before the permanent deletion that Secrets Manager would normally impose with the RecoveryWindowInDays parameter. If you delete a secret with the ForceDeleteWithoutRecovery parameter, then you have no opportunity to recover the secret. You lose the secret permanently.
]: any -> oneof<record<ARN: string, Name: string, DeletionDate: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.DeleteSecret")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "RecoveryWindowInDays": $recovery_window_in_days, "ForceDeleteWithoutRecovery": $force_delete_without_recovery} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-secret" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  secret_id: string # The ARN or name of the secret. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
]: any -> oneof<record<ARN: string, Name: string, Description: string, KmsKeyId: string, RotationEnabled: bool, RotationLambdaARN: string, RotationRules: record<AutomaticallyAfterDays: int, Duration: string, ScheduleExpression: string>, LastRotatedDate: string, LastChangedDate: string, LastAccessedDate: string, DeletedDate: string, NextRotationDate: string, Tags: table<Key: string, Value: string>, VersionIdsToStages: record, OwningService: string, CreatedDate: string, PrimaryRegion: string, ReplicationStatus: table<Region: string, KmsKeyId: string, Status: string, StatusMessage: string, LastAccessedDate: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.DescribeSecret")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "get-random-password" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  --password-length: int # The length of the password. If you don't include this parameter, the default length is 32 characters.
  --exclude-characters: string # A string of the characters that you don't want in the password.
  --exclude-numbers: oneof<nothing, bool> # Specifies whether to exclude numbers from the password. If you don't include this switch, the password can contain numbers.
  --exclude-punctuation: oneof<nothing, bool> # Specifies whether to exclude the following punctuation characters from the password: ! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \ ] ^ _ ` { | } ~. If you don't include this switch, the password can contain punctuation.
  --exclude-uppercase: oneof<nothing, bool> # Specifies whether to exclude uppercase letters from the password. If you don't include this switch, the password can contain uppercase letters.
  --exclude-lowercase: oneof<nothing, bool> # Specifies whether to exclude lowercase letters from the password. If you don't include this switch, the password can contain lowercase letters.
  --include-space: oneof<nothing, bool> # Specifies whether to include the space character. If you include this switch, the password can contain space characters.
  --require-each-included-type: oneof<nothing, bool> # Specifies whether to include at least one upper and lowercase letter, one number, and one punctuation. If you don't include this switch, the password contains at least one of every character type.
]: any -> oneof<record<RandomPassword: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.GetRandomPassword")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"PasswordLength": $password_length, "ExcludeCharacters": $exclude_characters, "ExcludeNumbers": $exclude_numbers, "ExcludePunctuation": $exclude_punctuation, "ExcludeUppercase": $exclude_uppercase, "ExcludeLowercase": $exclude_lowercase, "IncludeSpace": $include_space, "RequireEachIncludedType": $require_each_included_type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "get-resource-policy" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  secret_id: string # The ARN or name of the secret to retrieve the attached resource-based policy for. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
]: any -> oneof<record<ARN: string, Name: string, ResourcePolicy: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.GetResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "get-secret-value" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  secret_id: string # The ARN or name of the secret to retrieve. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
  --version-id: string # The unique identifier of the version of the secret to retrieve. If you include both this parameter and VersionStage, the two parameters must refer to the same secret version. If you don't specify either a VersionStage or VersionId, then Secrets Manager returns the AWSCURRENT version. This value is typically a UUID-type (https://wikipedia.org/wiki/Universally_unique_identifier) value with 32 hexadecimal digits.
  --version-stage: string # The staging label of the version of the secret to retrieve. Secrets Manager uses staging labels to keep track of different versions during the rotation process. If you include both this parameter and VersionId, the two parameters must refer to the same secret version. If you don't specify either a VersionStage or VersionId, Secrets Manager returns the AWSCURRENT version.
]: any -> oneof<record<ARN: string, Name: string, VersionId: string, SecretBinary: string, SecretString: string, VersionStages: list<string>, CreatedDate: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.GetSecretValue")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "VersionId": $version_id, "VersionStage": $version_stage} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-secret-version-ids" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  secret_id: string # The ARN or name of the secret whose versions you want to list. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
  --body-max-results: int # The number of results to include in the response. If there are more results available, in the response, Secrets Manager includes NextToken. To get the next results, call ListSecretVersionIds again with the value from NextToken. (spec name: MaxResults)
  --body-next-token: string # A token that indicates where the output should continue from, if a previous call did not show all results. To get the next results, call ListSecretVersionIds again with this value. (spec name: NextToken)
  --include-deprecated: oneof<nothing, bool> # Specifies whether to include versions of secrets that don't have any staging labels attached to them. Versions without staging labels are considered deprecated and are subject to deletion by Secrets Manager. By default, versions without staging labels aren't included.
]: any -> oneof<record<Versions: table<VersionId: string, VersionStages: list, LastAccessedDate: string, CreatedDate: string, KmsKeyIds: list>, NextToken: string, ARN: string, Name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.ListSecretVersionIds")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"SecretId": $secret_id, "MaxResults": $body_max_results, "NextToken": $body_next_token, "IncludeDeprecated": $include_deprecated} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-secrets" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  --include-planned-deletion: oneof<nothing, bool> # Specifies whether to include secrets scheduled for deletion. By default, secrets scheduled for deletion aren't included.
  --body-max-results: int # The number of results to include in the response. If there are more results available, in the response, Secrets Manager includes NextToken. To get the next results, call ListSecrets again with the value from NextToken. (spec name: MaxResults)
  --body-next-token: string # A token that indicates where the output should continue from, if a previous call did not show all results. To get the next results, call ListSecrets again with this value. (spec name: NextToken)
  --filters: list # The filters to apply to the list of secrets. — item shape: {Key?: "description"|"name"|"tag-key"|"tag-value"|"primary-region"|"owning-service"|"all", Values?: list<string>}
  --sort-order: string@sort-order-completer # Secrets are listed by CreatedDate.
]: any -> oneof<record<SecretList: table<ARN: string, Name: string, Description: string, KmsKeyId: string, RotationEnabled: bool, RotationLambdaARN: string, RotationRules: record, LastRotatedDate: string, LastChangedDate: string, LastAccessedDate: string, DeletedDate: string, NextRotationDate: string, Tags: list, SecretVersionsToStages: record, OwningService: string, CreatedDate: string, PrimaryRegion: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.ListSecrets")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"IncludePlannedDeletion": $include_planned_deletion, "MaxResults": $body_max_results, "NextToken": $body_next_token, "Filters": $filters, "SortOrder": $sort_order} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "put-resource-policy" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  secret_id: string # The ARN or name of the secret to attach the resource-based policy. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
  resource_policy: string # A JSON-formatted string for an Amazon Web Services resource-based policy. For example policies, see Permissions policy examples (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_examples.html).
  --block-public-policy: oneof<nothing, bool> # Specifies whether to block resource-based policies that allow broad access to the secret, for example those that use a wildcard for the principal. By default, public policies aren't blocked.
]: any -> oneof<record<ARN: string, Name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.PutResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "ResourcePolicy": $resource_policy, "BlockPublicPolicy": $block_public_policy} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "put-secret-value" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  secret_id: string # The ARN or name of the secret to add a new version to. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen). If the secret doesn't already exist, use CreateSecret instead.
  --client-request-token: string # A unique identifier for the new version of the secret. If you use the Amazon Web Services CLI or one of the Amazon Web Services SDKs to call this operation, then you can leave this parameter empty because they generate a random UUID for you. If you don't use the SDK and instead generate a raw HTTP request to the Secrets Manager service endpoint, then you must generate a ClientRequestToken yourself for new versions and include that value in the request. This value helps ensure idempotency. Secrets Manager uses this value to prevent the accidental creation of duplicate versions if there are failures and retries during the Lambda rotation function processing. We recommend that you generate a UUID-type (https://wikipedia.org/wiki/Universally_unique_identifier) value to ensure uniqueness within the specified secret. If the ClientRequestToken value isn't already associated with a version of the secret then a new version of the secret is created. If a version with this value already exists and that version's SecretString or SecretBinary values are the same as those in the request then the request is ignored. The operation is idempotent. If a version with this value already exists and the version of the SecretString and SecretBinary values are different from those in the request, then the request fails because you can't modify a secret version. You can only create new versions to store new secret values. This value becomes the VersionId of the new version.
  --secret-binary: string # The binary data to encrypt and store in the new version of the secret. To use this parameter in the command-line tools, we recommend that you store your binary data in a file and then pass the contents of the file as a parameter. You must include SecretBinary or SecretString, but not both. You can't access this value from the Secrets Manager console. (format: password)
  --secret-string: string # The text to encrypt and store in the new version of the secret. You must include SecretBinary or SecretString, but not both. We recommend you create the secret string as JSON key/value pairs, as shown in the example. (format: password)
  --version-stages: list<string> # A list of staging labels to attach to this version of the secret. Secrets Manager uses staging labels to track versions of a secret through the rotation process. If you specify a staging label that's already associated with a different version of the same secret, then Secrets Manager removes the label from the other version and attaches it to this version. If you specify AWSCURRENT, and it is already attached to another version, then Secrets Manager also moves the staging label AWSPREVIOUS to the version that AWSCURRENT was removed from. If you don't include VersionStages, then Secrets Manager automatically moves the staging label AWSCURRENT to this version.
]: any -> oneof<record<ARN: string, Name: string, VersionId: string, VersionStages: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.PutSecretValue")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "ClientRequestToken": $client_request_token, "SecretBinary": $secret_binary, "SecretString": $secret_string, "VersionStages": $version_stages} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "remove-regions-from-replication" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  secret_id: string # The ARN or name of the secret.
  remove_replica_regions: list<string> # The Regions of the replicas to remove.
]: any -> oneof<record<ARN: string, ReplicationStatus: table<Region: string, KmsKeyId: string, Status: string, StatusMessage: string, LastAccessedDate: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.RemoveRegionsFromReplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "RemoveReplicaRegions": $remove_replica_regions} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "replicate-secret-to-regions" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  secret_id: string # The ARN or name of the secret to replicate.
  add_replica_regions: list # A list of Regions in which to replicate the secret. — item shape: {Region?: string, KmsKeyId?: string}
  --force-overwrite-replica-secret: oneof<nothing, bool> # Specifies whether to overwrite a secret with the same name in the destination Region. By default, secrets aren't overwritten.
]: any -> oneof<record<ARN: string, ReplicationStatus: table<Region: string, KmsKeyId: string, Status: string, StatusMessage: string, LastAccessedDate: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.ReplicateSecretToRegions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "AddReplicaRegions": $add_replica_regions, "ForceOverwriteReplicaSecret": $force_overwrite_replica_secret} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "restore-secret" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  secret_id: string # The ARN or name of the secret to restore. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
]: any -> oneof<record<ARN: string, Name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.RestoreSecret")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "rotate-secret" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  secret_id: string # The ARN or name of the secret to rotate. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
  --client-request-token: string # A unique identifier for the new version of the secret that helps ensure idempotency. Secrets Manager uses this value to prevent the accidental creation of duplicate versions if there are failures and retries during rotation. This value becomes the VersionId of the new version. If you use the Amazon Web Services CLI or one of the Amazon Web Services SDK to call this operation, then you can leave this parameter empty. The CLI or SDK generates a random UUID for you and includes that in the request for this parameter. If you don't use the SDK and instead generate a raw HTTP request to the Secrets Manager service endpoint, then you must generate a ClientRequestToken yourself for new versions and include that value in the request. You only need to specify this value if you implement your own retry logic and you want to ensure that Secrets Manager doesn't attempt to create a secret version twice. We recommend that you generate a UUID-type (https://wikipedia.org/wiki/Universally_unique_identifier) value to ensure uniqueness within the specified secret.
  --rotation-lambda-arn: string # For secrets that use a Lambda rotation function to rotate, the ARN of the Lambda rotation function. For secrets that use managed rotation, omit this field. For more information, see Managed rotation (https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotate-secrets_managed.html) in the Secrets Manager User Guide.
  --rotation-rules: record # A structure that defines the rotation configuration for the secret. — shape: {AutomaticallyAfterDays?: int, Duration?: string, ScheduleExpression?: string}
  --rotate-immediately: oneof<nothing, bool> # Specifies whether to rotate the secret immediately or wait until the next scheduled rotation window. The rotation schedule is defined in RotateSecretRequest$RotationRules. For secrets that use a Lambda rotation function to rotate, if you don't immediately rotate the secret, Secrets Manager tests the rotation configuration by running the testSecret step (https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotate-secrets_how.html) of the Lambda rotation function. The test creates an AWSPENDING version of the secret and then removes it. By default, Secrets Manager rotates the secret immediately.
]: any -> oneof<record<ARN: string, Name: string, VersionId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.RotateSecret")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "ClientRequestToken": $client_request_token, "RotationLambdaARN": $rotation_lambda_arn, "RotationRules": $rotation_rules, "RotateImmediately": $rotate_immediately} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "stop-replication-to-replica" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  secret_id: string # The ARN of the primary secret.
]: any -> oneof<record<ARN: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.StopReplicationToReplica")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  secret_id: string # The identifier for the secret to attach tags to. You can specify either the Amazon Resource Name (ARN) or the friendly name of the secret. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
  tags: list # The tags to attach to the secret as a JSON text string argument. Each element in the list consists of a Key and a Value. For storing multiple values, we recommend that you use a JSON text string argument and specify key/value pairs. For more information, see Specifying parameter values for the Amazon Web Services CLI (https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-parameters.html) in the Amazon Web Services CLI User Guide. — item shape: {Key?: string, Value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  secret_id: string # The ARN or name of the secret. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
  tag_keys: list<string> # A list of tag key names to remove from the secret. You don't specify the value. Both the key and its associated value are removed. This parameter requires a JSON text string argument. For storing multiple values, we recommend that you use a JSON text string argument and specify key/value pairs. For more information, see Specifying parameter values for the Amazon Web Services CLI (https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-parameters.html) in the Amazon Web Services CLI User Guide.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "TagKeys": $tag_keys} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-secret" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  secret_id: string # The ARN or name of the secret. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
  --client-request-token: string # If you include SecretString or SecretBinary, then Secrets Manager creates a new version for the secret, and this parameter specifies the unique identifier for the new version. If you use the Amazon Web Services CLI or one of the Amazon Web Services SDKs to call this operation, then you can leave this parameter empty. The CLI or SDK generates a random UUID for you and includes it as the value for this parameter in the request. If you don't use the SDK and instead generate a raw HTTP request to the Secrets Manager service endpoint, then you must generate a ClientRequestToken yourself for the new version and include the value in the request. This value becomes the VersionId of the new version.
  --description: string # The description of the secret.
  --kms-key-id: string # The ARN, key ID, or alias of the KMS key that Secrets Manager uses to encrypt new secret versions as well as any existing versions with the staging labels AWSCURRENT, AWSPENDING, or AWSPREVIOUS. For more information about versions and staging labels, see Concepts: Version (https://docs.aws.amazon.com/secretsmanager/latest/userguide/getting-started.html#term_version). A key alias is always prefixed by alias/, for example alias/aws/secretsmanager. For more information, see About aliases (https://docs.aws.amazon.com/kms/latest/developerguide/alias-about.html). If you set this to an empty string, Secrets Manager uses the Amazon Web Services managed key aws/secretsmanager. If this key doesn't already exist in your account, then Secrets Manager creates it for you automatically. All users and roles in the Amazon Web Services account automatically have access to use aws/secretsmanager. Creating aws/secretsmanager can result in a one-time significant delay in returning the result. You can only use the Amazon Web Services managed key aws/secretsmanager if you call this operation using credentials from the same Amazon Web Services account that owns the secret. If the secret is in a different account, then you must use a customer managed key and provide the ARN of that KMS key in this field. The user making the call must have permissions to both the secret and the KMS key in their respective accounts.
  --secret-binary: string # The binary data to encrypt and store in the new version of the secret. We recommend that you store your binary data in a file and then pass the contents of the file as a parameter. Either SecretBinary or SecretString must have a value, but not both. You can't access this parameter in the Secrets Manager console. (format: password)
  --secret-string: string # The text data to encrypt and store in the new version of the secret. We recommend you use a JSON structure of key/value pairs for your secret value. Either SecretBinary or SecretString must have a value, but not both. (format: password)
]: any -> oneof<record<ARN: string, Name: string, VersionId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.UpdateSecret")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "ClientRequestToken": $client_request_token, "Description": $description, "KmsKeyId": $kms_key_id, "SecretBinary": $secret_binary, "SecretString": $secret_string} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-secret-version-stage" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  secret_id: string # The ARN or the name of the secret with the version and staging labelsto modify. For an ARN, we recommend that you specify a complete ARN rather than a partial ARN. See Finding a secret from a partial ARN (https://docs.aws.amazon.com/secretsmanager/latest/userguide/troubleshoot.html#ARN_secretnamehyphen).
  version_stage: string # The staging label to add to this version.
  --remove-from-version-id: string # The ID of the version that the staging label is to be removed from. If the staging label you are trying to attach to one version is already attached to a different version, then you must include this parameter and specify the version that the label is to be removed from. If the label is attached and you either do not specify this parameter, or the version ID does not match, then the operation fails.
  --move-to-version-id: string # The ID of the version to add the staging label to. To remove a label from a version, then do not specify this parameter. If the staging label is already attached to a different version of the secret, then you must also specify the RemoveFromVersionId parameter.
]: any -> oneof<record<ARN: string, Name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.UpdateSecretVersionStage")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "VersionStage": $version_stage, "RemoveFromVersionId": $remove_from_version_id, "MoveToVersionId": $move_to_version_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "validate-resource-policy" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  --secret-id: string # This field is reserved for internal use.
  resource_policy: string # A JSON-formatted string that contains an Amazon Web Services resource-based policy. The policy in the string identifies who can access or manage this secret and its versions. For example policies, see Permissions policy examples (https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_examples.html).
]: any -> oneof<record<PolicyValidationPassed: bool, ValidationErrors: table<CheckName: string, ErrorMessage: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "secretsmanager.ValidateResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SecretId": $secret_id, "ResourcePolicy": $resource_policy} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
