# Auto-generated client for AWS Key Management Service v2014-11-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/kms/2014-11-01/openapi.json
# Auth: --token flag or $env.AWS_KEY_MANAGEMENT_SERVICE_TOKEN

const BASE_URL = "http://kms.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_KEY_MANAGEMENT_SERVICE_TOKEN | default "" }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://kms.us-east-1.amazonaws.com" "http://kms.us-east-2.amazonaws.com" "http://kms.us-west-1.amazonaws.com" "http://kms.us-west-2.amazonaws.com" "http://kms.us-gov-west-1.amazonaws.com" "http://kms.us-gov-east-1.amazonaws.com" "http://kms.ca-central-1.amazonaws.com" "http://kms.eu-north-1.amazonaws.com" "http://kms.eu-west-1.amazonaws.com" "http://kms.eu-west-2.amazonaws.com" "http://kms.eu-west-3.amazonaws.com" "http://kms.eu-central-1.amazonaws.com" "http://kms.eu-south-1.amazonaws.com" "http://kms.af-south-1.amazonaws.com" "http://kms.ap-northeast-1.amazonaws.com" "http://kms.ap-northeast-2.amazonaws.com" "http://kms.ap-northeast-3.amazonaws.com" "http://kms.ap-southeast-1.amazonaws.com" "http://kms.ap-southeast-2.amazonaws.com" "http://kms.ap-east-1.amazonaws.com" "http://kms.ap-south-1.amazonaws.com" "http://kms.sa-east-1.amazonaws.com" "http://kms.me-south-1.amazonaws.com" "https://kms.us-east-1.amazonaws.com" "https://kms.us-east-2.amazonaws.com" "https://kms.us-west-1.amazonaws.com" "https://kms.us-west-2.amazonaws.com" "https://kms.us-gov-west-1.amazonaws.com" "https://kms.us-gov-east-1.amazonaws.com" "https://kms.ca-central-1.amazonaws.com" "https://kms.eu-north-1.amazonaws.com" "https://kms.eu-west-1.amazonaws.com" "https://kms.eu-west-2.amazonaws.com" "https://kms.eu-west-3.amazonaws.com" "https://kms.eu-central-1.amazonaws.com" "https://kms.eu-south-1.amazonaws.com" "https://kms.af-south-1.amazonaws.com" "https://kms.ap-northeast-1.amazonaws.com" "https://kms.ap-northeast-2.amazonaws.com" "https://kms.ap-northeast-3.amazonaws.com" "https://kms.ap-southeast-1.amazonaws.com" "https://kms.ap-southeast-2.amazonaws.com" "https://kms.ap-east-1.amazonaws.com" "https://kms.ap-south-1.amazonaws.com" "https://kms.sa-east-1.amazonaws.com" "https://kms.me-south-1.amazonaws.com" "http://kms.cn-north-1.amazonaws.com.cn" "http://kms.cn-northwest-1.amazonaws.com.cn" "https://kms.cn-north-1.amazonaws.com.cn" "https://kms.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["TrentService.CancelKeyDeletion"] }
def x-amz-target-completer-1 [] { ["TrentService.ConnectCustomKeyStore"] }
def x-amz-target-completer-2 [] { ["TrentService.CreateAlias"] }
def x-amz-target-completer-3 [] { ["TrentService.CreateCustomKeyStore"] }
def x-amz-target-completer-4 [] { ["TrentService.CreateGrant"] }
def x-amz-target-completer-5 [] { ["TrentService.CreateKey"] }
def x-amz-target-completer-6 [] { ["TrentService.Decrypt"] }
def x-amz-target-completer-7 [] { ["TrentService.DeleteAlias"] }
def x-amz-target-completer-8 [] { ["TrentService.DeleteCustomKeyStore"] }
def x-amz-target-completer-9 [] { ["TrentService.DeleteImportedKeyMaterial"] }
def x-amz-target-completer-10 [] { ["TrentService.DescribeCustomKeyStores"] }
def x-amz-target-completer-11 [] { ["TrentService.DescribeKey"] }
def x-amz-target-completer-12 [] { ["TrentService.DisableKey"] }
def x-amz-target-completer-13 [] { ["TrentService.DisableKeyRotation"] }
def x-amz-target-completer-14 [] { ["TrentService.DisconnectCustomKeyStore"] }
def x-amz-target-completer-15 [] { ["TrentService.EnableKey"] }
def x-amz-target-completer-16 [] { ["TrentService.EnableKeyRotation"] }
def x-amz-target-completer-17 [] { ["TrentService.Encrypt"] }
def x-amz-target-completer-18 [] { ["TrentService.GenerateDataKey"] }
def x-amz-target-completer-19 [] { ["TrentService.GenerateDataKeyPair"] }
def x-amz-target-completer-20 [] { ["TrentService.GenerateDataKeyPairWithoutPlaintext"] }
def x-amz-target-completer-21 [] { ["TrentService.GenerateDataKeyWithoutPlaintext"] }
def x-amz-target-completer-22 [] { ["TrentService.GenerateMac"] }
def x-amz-target-completer-23 [] { ["TrentService.GenerateRandom"] }
def x-amz-target-completer-24 [] { ["TrentService.GetKeyPolicy"] }
def x-amz-target-completer-25 [] { ["TrentService.GetKeyRotationStatus"] }
def x-amz-target-completer-26 [] { ["TrentService.GetParametersForImport"] }
def x-amz-target-completer-27 [] { ["TrentService.GetPublicKey"] }
def x-amz-target-completer-28 [] { ["TrentService.ImportKeyMaterial"] }
def x-amz-target-completer-29 [] { ["TrentService.ListAliases"] }
def x-amz-target-completer-30 [] { ["TrentService.ListGrants"] }
def x-amz-target-completer-31 [] { ["TrentService.ListKeyPolicies"] }
def x-amz-target-completer-32 [] { ["TrentService.ListKeys"] }
def x-amz-target-completer-33 [] { ["TrentService.ListResourceTags"] }
def x-amz-target-completer-34 [] { ["TrentService.ListRetirableGrants"] }
def x-amz-target-completer-35 [] { ["TrentService.PutKeyPolicy"] }
def x-amz-target-completer-36 [] { ["TrentService.ReEncrypt"] }
def x-amz-target-completer-37 [] { ["TrentService.ReplicateKey"] }
def x-amz-target-completer-38 [] { ["TrentService.RetireGrant"] }
def x-amz-target-completer-39 [] { ["TrentService.RevokeGrant"] }
def x-amz-target-completer-40 [] { ["TrentService.ScheduleKeyDeletion"] }
def x-amz-target-completer-41 [] { ["TrentService.Sign"] }
def x-amz-target-completer-42 [] { ["TrentService.TagResource"] }
def x-amz-target-completer-43 [] { ["TrentService.UntagResource"] }
def x-amz-target-completer-44 [] { ["TrentService.UpdateAlias"] }
def x-amz-target-completer-45 [] { ["TrentService.UpdateCustomKeyStore"] }
def x-amz-target-completer-46 [] { ["TrentService.UpdateKeyDescription"] }
def x-amz-target-completer-47 [] { ["TrentService.UpdatePrimaryRegion"] }
def x-amz-target-completer-48 [] { ["TrentService.Verify"] }
def x-amz-target-completer-49 [] { ["TrentService.VerifyMac"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api cancel-key-deletion" } } | get name | first)
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

# Cancels the deletion of a KMS key. When this operation succeeds, the key state of the KMS key is Disabled. To enable the KMS key, use EnableKey. For more information about scheduling and canceling deletion of a KMS key, see Deleting KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html) in the Key Management Service Developer Guide. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:CancelKeyDeletion (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: ScheduleKeyDeletion
#
# POST /
# operationId: CancelKeyDeletion
export def "api cancel-key-deletion" [
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
  key_id: any
]: any -> record<KeyId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Connects or reconnects a custom key store (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html) to its backing key store. For an CloudHSM key store, ConnectCustomKeyStore connects the key store to its associated CloudHSM cluster. For an external key store, ConnectCustomKeyStore connects the key store to the external key store proxy that communicates with your external key manager. The custom key store must be connected before you can create KMS keys in the key store or use the KMS keys it contains. You can disconnect and reconnect a custom key store at any time. The connection process for a custom key store can take an extended amount of time to complete. This operation starts the connection process, but it does not wait for it to complete. When it succeeds, this operation quickly returns an HTTP 200 response and a JSON object with no properties. However, this response does not indicate that the custom key store is connected. To get the connection state of the custom key store, use the DescribeCustomKeyStores operation. This operation is part of the custom key stores (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html) feature in KMS, which combines the convenience and extensive integration of KMS with the isolation and control of a key store that you own and manage. The ConnectCustomKeyStore operation might fail for various reasons. To find the reason, use the DescribeCustomKeyStores operation and see the ConnectionErrorCode in the response. For help interpreting the ConnectionErrorCode, see CustomKeyStoresListEntry. To fix the failure, use the DisconnectCustomKeyStore operation to disconnect the custom key store, correct the error, use the UpdateCustomKeyStore operation if necessary, and then use ConnectCustomKeyStore again. CloudHSM key store During the connection process for an CloudHSM key store, KMS finds the CloudHSM cluster that is associated with the custom key store, creates the connection infrastructure, connects to the cluster, logs into the CloudHSM client as the kmsuser CU, and rotates its password. To connect an CloudHSM key store, its associated CloudHSM cluster must have at least one active HSM. To get the number of active HSMs in a cluster, use the DescribeClusters (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html) operation. To add HSMs to the cluster, use the CreateHsm (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html) operation. Also, the kmsuser crypto user (https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser) (CU) must not be logged into the cluster. This prevents KMS from using this account to log in. If you are having trouble connecting or disconnecting a CloudHSM key store, see Troubleshooting an CloudHSM key store (https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html) in the Key Management Service Developer Guide. External key store When you connect an external key store that uses public endpoint connectivity, KMS tests its ability to communicate with your external key manager by sending a request via the external key store proxy. When you connect to an external key store that uses VPC endpoint service connectivity, KMS establishes the networking elements that it needs to communicate with your external key manager via the external key store proxy. This includes creating an interface endpoint to the VPC endpoint service and a private hosted zone for traffic between KMS and the VPC endpoint service. To connect an external key store, KMS must be able to connect to the external key store proxy, the external key store proxy must be able to communicate with your external key manager, and the external key manager must be available for cryptographic operations. If you are having trouble connecting or disconnecting an external key store, see Troubleshooting an external key store (https://docs.aws.amazon.com/kms/latest/developerguide/xks-troubleshooting.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a custom key store in a different Amazon Web Services account. Required permissions: kms:ConnectCustomKeyStore (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy) Related operations CreateCustomKeyStore DeleteCustomKeyStore DescribeCustomKeyStores DisconnectCustomKeyStore UpdateCustomKeyStore
#
# POST /
# operationId: ConnectCustomKeyStore
export def "api create-connect-custom-key-store" [
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
  custom_key_store_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CustomKeyStoreId": $custom_key_store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a friendly name for a KMS key. Adding, deleting, or updating an alias can allow or deny permission to the KMS key. For details, see ABAC for KMS (https://docs.aws.amazon.com/kms/latest/developerguide/abac.html) in the Key Management Service Developer Guide. You can use an alias to identify a KMS key in the KMS console, in the DescribeKey operation and in cryptographic operations (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations), such as Encrypt and GenerateDataKey. You can also change the KMS key that's associated with the alias (UpdateAlias) or delete the alias (DeleteAlias) at any time. These operations don't affect the underlying KMS key. You can associate the alias with any customer managed key in the same Amazon Web Services Region. Each alias is associated with only one KMS key at a time, but a KMS key can have multiple aliases. A valid KMS key is required. You can't create an alias without a KMS key. The alias must be unique in the account and Region, but you can have aliases with the same name in different Regions. For detailed information about aliases, see Using aliases (https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html) in the Key Management Service Developer Guide. This operation does not return a response. To get the alias that you created, use the ListAliases operation. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on an alias in a different Amazon Web Services account. Required permissions kms:CreateAlias (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) on the alias (IAM policy). kms:CreateAlias (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) on the KMS key (key policy). For details, see Controlling access to aliases (https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html#alias-access) in the Key Management Service Developer Guide. Related operations: DeleteAlias ListAliases UpdateAlias
#
# POST /
# operationId: CreateAlias
export def "api create-alias" [
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
  alias_name: any
  target_key_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"AliasName": $alias_name, "TargetKeyId": $target_key_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a custom key store (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html) backed by a key store that you own and manage. When you use a KMS key in a custom key store for a cryptographic operation, the cryptographic operation is actually performed in your key store using your keys. KMS supports CloudHSM key stores (https://docs.aws.amazon.com/kms/latest/developerguide/keystore-cloudhsm.html) backed by an CloudHSM cluster (https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html) and external key stores (https://docs.aws.amazon.com/kms/latest/developerguide/keystore-external.html) backed by an external key store proxy and external key manager outside of Amazon Web Services. This operation is part of the custom key stores (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html) feature in KMS, which combines the convenience and extensive integration of KMS with the isolation and control of a key store that you own and manage. Before you create the custom key store, the required elements must be in place and operational. We recommend that you use the test tools that KMS provides to verify the configuration your external key store proxy. For details about the required elements and verification tests, see Assemble the prerequisites (for CloudHSM key stores) (https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore) or Assemble the prerequisites (for external key stores) (https://docs.aws.amazon.com/kms/latest/developerguide/create-xks-keystore.html#xks-requirements) in the Key Management Service Developer Guide. To create a custom key store, use the following parameters. To create an CloudHSM key store, specify the CustomKeyStoreName, CloudHsmClusterId, KeyStorePassword, and TrustAnchorCertificate. The CustomKeyStoreType parameter is optional for CloudHSM key stores. If you include it, set it to the default value, AWS_CLOUDHSM. For help with failures, see Troubleshooting an CloudHSM key store (https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html) in the Key Management Service Developer Guide. To create an external key store, specify the CustomKeyStoreName and a CustomKeyStoreType of EXTERNAL_KEY_STORE. Also, specify values for XksProxyConnectivity, XksProxyAuthenticationCredential, XksProxyUriEndpoint, and XksProxyUriPath. If your XksProxyConnectivity value is VPC_ENDPOINT_SERVICE, specify the XksProxyVpcEndpointServiceName parameter. For help with failures, see Troubleshooting an external key store (https://docs.aws.amazon.com/kms/latest/developerguide/xks-troubleshooting.html) in the Key Management Service Developer Guide. For external key stores: Some external key managers provide a simpler method for creating an external key store. For details, see your external key manager documentation. When creating an external key store in the KMS console, you can upload a JSON-based proxy configuration file with the desired values. You cannot use a proxy configuration with the CreateCustomKeyStore operation. However, you can use the values in the file to help you determine the correct values for the CreateCustomKeyStore parameters. When the operation completes successfully, it returns the ID of the new custom key store. Before you can use your new custom key store, you need to use the ConnectCustomKeyStore operation to connect a new CloudHSM key store to its CloudHSM cluster, or to connect a new external key store to the external key store proxy for your external key manager. Even if you are not going to use your custom key store immediately, you might want to connect it to verify that all settings are correct and then disconnect it until you are ready to use it. For help with failures, see Troubleshooting a custom key store (https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a custom key store in a different Amazon Web Services account. Required permissions: kms:CreateCustomKeyStore (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy). Related operations: ConnectCustomKeyStore DeleteCustomKeyStore DescribeCustomKeyStores DisconnectCustomKeyStore UpdateCustomKeyStore
#
# POST /
# operationId: CreateCustomKeyStore
export def "api create-custom-key-store" [
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
  custom_key_store_name: any
  --cloud-hsm-cluster-id: any
  --trust-anchor-certificate: any
  --key-store-password: any
  --custom-key-store-type: any
  --xks-proxy-uri-endpoint: any
  --xks-proxy-uri-path: any
  --xks-proxy-vpc-endpoint-service-name: any
  --xks-proxy-authentication-credential: any
  --xks-proxy-connectivity: any
]: any -> record<CustomKeyStoreId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CustomKeyStoreName": $custom_key_store_name, "CloudHsmClusterId": $cloud_hsm_cluster_id, "TrustAnchorCertificate": $trust_anchor_certificate, "KeyStorePassword": $key_store_password, "CustomKeyStoreType": $custom_key_store_type, "XksProxyUriEndpoint": $xks_proxy_uri_endpoint, "XksProxyUriPath": $xks_proxy_uri_path, "XksProxyVpcEndpointServiceName": $xks_proxy_vpc_endpoint_service_name, "XksProxyAuthenticationCredential": $xks_proxy_authentication_credential, "XksProxyConnectivity": $xks_proxy_connectivity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds a grant to a KMS key. A grant is a policy instrument that allows Amazon Web Services principals to use KMS keys in cryptographic operations. It also can allow them to view a KMS key (DescribeKey) and create and manage grants. When authorizing access to a KMS key, grants are considered along with key policies and IAM policies. Grants are often used for temporary permissions because you can create one, use its permissions, and delete it without changing your key policies or IAM policies. For detailed information about grants, including grant terminology, see Grants in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/grants.html) in the Key Management Service Developer Guide . For examples of working with grants in several programming languages, see Programming grants (https://docs.aws.amazon.com/kms/latest/developerguide/programming-grants.html). The CreateGrant operation returns a GrantToken and a GrantId. When you create, retire, or revoke a grant, there might be a brief delay, usually less than five minutes, until the grant is available throughout KMS. This state is known as eventual consistency. Once the grant has achieved eventual consistency, the grantee principal can use the permissions in the grant without identifying the grant. However, to use the permissions in the grant immediately, use the GrantToken that CreateGrant returns. For details, see Using a grant token (https://docs.aws.amazon.com/kms/latest/developerguide/grant-manage.html#using-grant-token) in the Key Management Service Developer Guide . The CreateGrant operation also returns a GrantId. You can use the GrantId and a key identifier to identify the grant in the RetireGrant and RevokeGrant operations. To find the grant ID, use the ListGrants or ListRetirableGrants operations. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. To perform this operation on a KMS key in a different Amazon Web Services account, specify the key ARN in the value of the KeyId parameter. Required permissions: kms:CreateGrant (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: ListGrants ListRetirableGrants RetireGrant RevokeGrant
#
# POST /
# operationId: CreateGrant
export def "api create-grant" [
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
  key_id: any
  grantee_principal: any
  --retiring-principal: any
  operations: any
  --constraints: any
  --grant-tokens: any
  --name: any
]: any -> record<GrantToken: record, GrantId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "GranteePrincipal": $grantee_principal, "RetiringPrincipal": $retiring_principal, "Operations": $operations, "Constraints": $constraints, "GrantTokens": $grant_tokens, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a unique customer managed KMS key (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#kms-keys) in your Amazon Web Services account and Region. You can use a KMS key in cryptographic operations, such as encryption and signing. Some Amazon Web Services services let you use KMS keys that you create and manage to protect your service resources. A KMS key is a logical representation of a cryptographic key. In addition to the key material used in cryptographic operations, a KMS key includes metadata, such as the key ID, key policy, creation date, description, and key state. For details, see Managing keys (https://docs.aws.amazon.com/kms/latest/developerguide/getting-started.html) in the Key Management Service Developer Guide Use the parameters of CreateKey to specify the type of KMS key, the source of its key material, its key policy, description, tags, and other properties. KMS has replaced the term customer master key (CMK) with KMS key and KMS key. The concept has not changed. To prevent breaking changes, KMS is keeping some variations of this term. To create different types of KMS keys, use the following guidance: Symmetric encryption KMS key By default, CreateKey creates a symmetric encryption KMS key with key material that KMS generates. This is the basic and most widely used type of KMS key, and provides the best performance. To create a symmetric encryption KMS key, you don't need to specify any parameters. The default value for KeySpec, SYMMETRIC_DEFAULT, the default value for KeyUsage, ENCRYPT_DECRYPT, and the default value for Origin, AWS_KMS, create a symmetric encryption KMS key with KMS key material. If you need a key for basic encryption and decryption or you are creating a KMS key to protect your resources in an Amazon Web Services service, create a symmetric encryption KMS key. The key material in a symmetric encryption key never leaves KMS unencrypted. You can use a symmetric encryption KMS key to encrypt and decrypt data up to 4,096 bytes, but they are typically used to generate data keys and data keys pairs. For details, see GenerateDataKey and GenerateDataKeyPair. Asymmetric KMS keys To create an asymmetric KMS key, use the KeySpec parameter to specify the type of key material in the KMS key. Then, use the KeyUsage parameter to determine whether the KMS key will be used to encrypt and decrypt or sign and verify. You can't change these properties after the KMS key is created. Asymmetric KMS keys contain an RSA key pair, Elliptic Curve (ECC) key pair, or an SM2 key pair (China Regions only). The private key in an asymmetric KMS key never leaves KMS unencrypted. However, you can use the GetPublicKey operation to download the public key so it can be used outside of KMS. KMS keys with RSA or SM2 key pairs can be used to encrypt or decrypt data or sign and verify messages (but not both). KMS keys with ECC key pairs can be used only to sign and verify messages. For information about asymmetric KMS keys, see Asymmetric KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html) in the Key Management Service Developer Guide. HMAC KMS key To create an HMAC KMS key, set the KeySpec parameter to a key spec value for HMAC KMS keys. Then set the KeyUsage parameter to GENERATE_VERIFY_MAC. You must set the key usage even though GENERATE_VERIFY_MAC is the only valid key usage value for HMAC KMS keys. You can't change these properties after the KMS key is created. HMAC KMS keys are symmetric keys that never leave KMS unencrypted. You can use HMAC keys to generate (GenerateMac) and verify (VerifyMac) HMAC codes for messages up to 4096 bytes. HMAC KMS keys are not supported in all Amazon Web Services Regions. If you try to create an HMAC KMS key in an Amazon Web Services Region in which HMAC keys are not supported, the CreateKey operation returns an UnsupportedOperationException. For a list of Regions in which HMAC KMS keys are supported, see HMAC keys in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html) in the Key Management Service Developer Guide. Multi-Region primary keys Imported key material To create a multi-Region primary key in the local Amazon Web Services Region, use the MultiRegion parameter with a value of True. To create a multi-Region replica key, that is, a KMS key with the same key ID and key material as a primary key, but in a different Amazon Web Services Region, use the ReplicateKey operation. To change a replica key to a primary key, and its primary key to a replica key, use the UpdatePrimaryRegion operation. You can create multi-Region KMS keys for all supported KMS key types: symmetric encryption KMS keys, HMAC KMS keys, asymmetric encryption KMS keys, and asymmetric signing KMS keys. You can also create multi-Region keys with imported key material. However, you can't create multi-Region keys in a custom key store. This operation supports multi-Region keys, an KMS feature that lets you create multiple interoperable KMS keys in different Amazon Web Services Regions. Because these KMS keys have the same key ID, key material, and other metadata, you can use them interchangeably to encrypt data in one Amazon Web Services Region and decrypt it in a different Amazon Web Services Region without re-encrypting the data or making a cross-Region call. For more information about multi-Region keys, see Multi-Region keys in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html) in the Key Management Service Developer Guide. To import your own key material into a KMS key, begin by creating a symmetric encryption KMS key with no key material. To do this, use the Origin parameter of CreateKey with a value of EXTERNAL. Next, use GetParametersForImport operation to get a public key and import token, and use the public key to encrypt your key material. Then, use ImportKeyMaterial with your import token to import the key material. For step-by-step instructions, see Importing Key Material (https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html) in the Key Management Service Developer Guide . This feature supports only symmetric encryption KMS keys, including multi-Region symmetric encryption KMS keys. You cannot import key material into any other type of KMS key. To create a multi-Region primary key with imported key material, use the Origin parameter of CreateKey with a value of EXTERNAL and the MultiRegion parameter with a value of True. To create replicas of the multi-Region primary key, use the ReplicateKey operation. For instructions, see Importing key material into multi-Region keys (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-import.html ). For more information about multi-Region keys, see Multi-Region keys in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html) in the Key Management Service Developer Guide. Custom key store A custom key store (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html) lets you protect your Amazon Web Services resources using keys in a backing key store that you own and manage. When you request a cryptographic operation with a KMS key in a custom key store, the operation is performed in the backing key store using its cryptographic keys. KMS supports CloudHSM key stores (https://docs.aws.amazon.com/kms/latest/developerguide/keystore-cloudhsm.html) backed by an CloudHSM cluster and external key stores (https://docs.aws.amazon.com/kms/latest/developerguide/keystore-external.html) backed by an external key manager outside of Amazon Web Services. When you create a KMS key in an CloudHSM key store, KMS generates an encryption key in the CloudHSM cluster and associates it with the KMS key. When you create a KMS key in an external key store, you specify an existing encryption key in the external key manager. Some external key managers provide a simpler method for creating a KMS key in an external key store. For details, see your external key manager documentation. Before you create a KMS key in a custom key store, the ConnectionState of the key store must be CONNECTED. To connect the custom key store, use the ConnectCustomKeyStore operation. To find the ConnectionState, use the DescribeCustomKeyStores operation. To create a KMS key in a custom key store, use the CustomKeyStoreId. Use the default KeySpec value, SYMMETRIC_DEFAULT, and the default KeyUsage value, ENCRYPT_DECRYPT to create a symmetric encryption key. No other key type is supported in a custom key store. To create a KMS key in an CloudHSM key store (https://docs.aws.amazon.com/kms/latest/developerguide/keystore-cloudhsm.html), use the Origin parameter with a value of AWS_CLOUDHSM. The CloudHSM cluster that is associated with the custom key store must have at least two active HSMs in different Availability Zones in the Amazon Web Services Region. To create a KMS key in an external key store (https://docs.aws.amazon.com/kms/latest/developerguide/keystore-external.html), use the Origin parameter with a value of EXTERNAL_KEY_STORE and an XksKeyId parameter that identifies an existing external key. Some external key managers provide a simpler method for creating a KMS key in an external key store. For details, see your external key manager documentation. Cross-account use: No. You cannot use this operation to create a KMS key in a different Amazon Web Services account. Required permissions: kms:CreateKey (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy). To use the Tags parameter, kms:TagResource (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy). For examples and information about related permissions, see Allow a user to create KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/iam-policies.html#iam-policy-example-create-key) in the Key Management Service Developer Guide. Related operations: DescribeKey ListKeys ScheduleKeyDeletion
#
# POST /
# operationId: CreateKey
export def "api create-key" [
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
  --policy: any
  --description: any
  --key-usage: any
  --customer-master-key-spec: any
  --key-spec: any
  --origin: any
  --custom-key-store-id: any
  --bypass-policy-lockout-safety-check: any
  --tags: any
  --multi-region: any
  --xks-key-id: any
]: any -> record<KeyMetadata: record<AWSAccountId: record, KeyId: record, Arn: record, CreationDate: record, Enabled: record, Description: record, KeyUsage: record, KeyState: record, DeletionDate: record, ValidTo: record, Origin: record, CustomKeyStoreId: record, CloudHsmClusterId: record, ExpirationModel: record, KeyManager: record, CustomerMasterKeySpec: record, KeySpec: record, EncryptionAlgorithms: record, SigningAlgorithms: record, MultiRegion: record, MultiRegionConfiguration: record<MultiRegionKeyType: record, PrimaryKey: record, ReplicaKeys: record>, PendingDeletionWindowInDays: record, MacAlgorithms: record, XksKeyConfiguration: record<Id: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"Policy": $policy, "Description": $description, "KeyUsage": $key_usage, "CustomerMasterKeySpec": $customer_master_key_spec, "KeySpec": $key_spec, "Origin": $origin, "CustomKeyStoreId": $custom_key_store_id, "BypassPolicyLockoutSafetyCheck": $bypass_policy_lockout_safety_check, "Tags": $tags, "MultiRegion": $multi_region, "XksKeyId": $xks_key_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Decrypts ciphertext that was encrypted by a KMS key using any of the following operations: Encrypt GenerateDataKey GenerateDataKeyPair GenerateDataKeyWithoutPlaintext GenerateDataKeyPairWithoutPlaintext You can use this operation to decrypt ciphertext that was encrypted under a symmetric encryption KMS key or an asymmetric encryption KMS key. When the KMS key is asymmetric, you must specify the KMS key and the encryption algorithm that was used to encrypt the ciphertext. For information about asymmetric KMS keys, see Asymmetric KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html) in the Key Management Service Developer Guide. The Decrypt operation also decrypts ciphertext that was encrypted outside of KMS by the public key in an KMS asymmetric KMS key. However, it cannot decrypt symmetric ciphertext produced by other libraries, such as the Amazon Web Services Encryption SDK (https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/) or Amazon S3 client-side encryption (https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html). These libraries return a ciphertext format that is incompatible with KMS. If the ciphertext was encrypted under a symmetric encryption KMS key, the KeyId parameter is optional. KMS can get this information from metadata that it adds to the symmetric ciphertext blob. This feature adds durability to your implementation by ensuring that authorized users can decrypt ciphertext decades after it was encrypted, even if they've lost track of the key ID. However, specifying the KMS key is always recommended as a best practice. When you use the KeyId parameter to specify a KMS key, KMS only uses the KMS key you specify. If the ciphertext was encrypted under a different KMS key, the Decrypt operation fails. This practice ensures that you use the KMS key that you intend. Whenever possible, use key policies to give users permission to call the Decrypt operation on a particular KMS key, instead of using &IAM; policies. Otherwise, you might create an &IAM; policy that gives the user Decrypt permission on all KMS keys. This user could decrypt ciphertext that was encrypted by KMS keys in other accounts if the key policy for the cross-account KMS key permits it. If you must use an IAM policy for Decrypt permissions, limit the user to particular KMS keys or particular trusted accounts. For details, see Best practices for IAM policies (https://docs.aws.amazon.com/kms/latest/developerguide/iam-policies.html#iam-policies-best-practices) in the Key Management Service Developer Guide. Applications in Amazon Web Services Nitro Enclaves can call this operation by using the Amazon Web Services Nitro Enclaves Development Kit (https://github.com/aws/aws-nitro-enclaves-sdk-c). For information about the supporting parameters, see How Amazon Web Services Nitro Enclaves use KMS (https://docs.aws.amazon.com/kms/latest/developerguide/services-nitro-enclaves.html) in the Key Management Service Developer Guide. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. If you use the KeyId parameter to identify a KMS key in a different Amazon Web Services account, specify the key ARN or the alias ARN of the KMS key. Required permissions: kms:Decrypt (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: Encrypt GenerateDataKey GenerateDataKeyPair ReEncrypt
#
# POST /
# operationId: Decrypt
export def "api create-decrypt" [
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
  ciphertext_blob: any
  --encryption-context: any
  --grant-tokens: any
  --key-id: any
  --encryption-algorithm: any
]: any -> record<KeyId: record, Plaintext: record, EncryptionAlgorithm: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CiphertextBlob": $ciphertext_blob, "EncryptionContext": $encryption_context, "GrantTokens": $grant_tokens, "KeyId": $key_id, "EncryptionAlgorithm": $encryption_algorithm} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the specified alias. Adding, deleting, or updating an alias can allow or deny permission to the KMS key. For details, see ABAC for KMS (https://docs.aws.amazon.com/kms/latest/developerguide/abac.html) in the Key Management Service Developer Guide. Because an alias is not a property of a KMS key, you can delete and change the aliases of a KMS key without affecting the KMS key. Also, aliases do not appear in the response from the DescribeKey operation. To get the aliases of all KMS keys, use the ListAliases operation. Each KMS key can have multiple aliases. To change the alias of a KMS key, use DeleteAlias to delete the current alias and CreateAlias to create a new alias. To associate an existing alias with a different KMS key, call UpdateAlias. Cross-account use: No. You cannot perform this operation on an alias in a different Amazon Web Services account. Required permissions kms:DeleteAlias (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) on the alias (IAM policy). kms:DeleteAlias (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) on the KMS key (key policy). For details, see Controlling access to aliases (https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html#alias-access) in the Key Management Service Developer Guide. Related operations: CreateAlias ListAliases UpdateAlias
#
# POST /
# operationId: DeleteAlias
export def "api delete-alias" [
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
  alias_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"AliasName": $alias_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a custom key store (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html). This operation does not affect any backing elements of the custom key store. It does not delete the CloudHSM cluster that is associated with an CloudHSM key store, or affect any users or keys in the cluster. For an external key store, it does not affect the external key store proxy, external key manager, or any external keys. This operation is part of the custom key stores (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html) feature in KMS, which combines the convenience and extensive integration of KMS with the isolation and control of a key store that you own and manage. The custom key store that you delete cannot contain any KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#kms_keys). Before deleting the key store, verify that you will never need to use any of the KMS keys in the key store for any cryptographic operations (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations). Then, use ScheduleKeyDeletion to delete the KMS keys from the key store. After the required waiting period expires and all KMS keys are deleted from the custom key store, use DisconnectCustomKeyStore to disconnect the key store from KMS. Then, you can delete the custom key store. For keys in an CloudHSM key store, the ScheduleKeyDeletion operation makes a best effort to delete the key material from the associated cluster. However, you might need to manually delete the orphaned key material (https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key) from the cluster and its backups. KMS never creates, manages, or deletes cryptographic keys in the external key manager associated with an external key store. You must manage them using your external key manager tools. Instead of deleting the custom key store, consider using the DisconnectCustomKeyStore operation to disconnect the custom key store from its backing key store. While the key store is disconnected, you cannot create or use the KMS keys in the key store. But, you do not need to delete KMS keys and you can reconnect a disconnected custom key store at any time. If the operation succeeds, it returns a JSON object with no properties. Cross-account use: No. You cannot perform this operation on a custom key store in a different Amazon Web Services account. Required permissions: kms:DeleteCustomKeyStore (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy) Related operations: ConnectCustomKeyStore CreateCustomKeyStore DescribeCustomKeyStores DisconnectCustomKeyStore UpdateCustomKeyStore
#
# POST /
# operationId: DeleteCustomKeyStore
export def "api delete-custom-key-store" [
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
  --x-amz-target: string@x-amz-target-completer-8
  custom_key_store_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CustomKeyStoreId": $custom_key_store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes key material that you previously imported. This operation makes the specified KMS key unusable. For more information about importing key material into KMS, see Importing Key Material (https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html) in the Key Management Service Developer Guide. When the specified KMS key is in the PendingDeletion state, this operation does not change the KMS key's state. Otherwise, it changes the KMS key's state to PendingImport. After you delete key material, you can use ImportKeyMaterial to reimport the same key material into the KMS key. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:DeleteImportedKeyMaterial (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: GetParametersForImport ImportKeyMaterial
#
# POST /
# operationId: DeleteImportedKeyMaterial
export def "api delete-imported-key-material" [
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
  --x-amz-target: string@x-amz-target-completer-9
  key_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about custom key stores (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html) in the account and Region. This operation is part of the custom key stores (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html) feature in KMS, which combines the convenience and extensive integration of KMS with the isolation and control of a key store that you own and manage. By default, this operation returns information about all custom key stores in the account and Region. To get only information about a particular custom key store, use either the CustomKeyStoreName or CustomKeyStoreId parameter (but not both). To determine whether the custom key store is connected to its CloudHSM cluster or external key store proxy, use the ConnectionState element in the response. If an attempt to connect the custom key store failed, the ConnectionState value is FAILED and the ConnectionErrorCode element in the response indicates the cause of the failure. For help interpreting the ConnectionErrorCode, see CustomKeyStoresListEntry. Custom key stores have a DISCONNECTED connection state if the key store has never been connected or you used the DisconnectCustomKeyStore operation to disconnect it. Otherwise, the connection state is CONNECTED. If your custom key store connection state is CONNECTED but you are having trouble using it, verify that the backing store is active and available. For an CloudHSM key store, verify that the associated CloudHSM cluster is active and contains the minimum number of HSMs required for the operation, if any. For an external key store, verify that the external key store proxy and its associated external key manager are reachable and enabled. For help repairing your CloudHSM key store, see the Troubleshooting CloudHSM key stores (https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html). For help repairing your external key store, see the Troubleshooting external key stores (https://docs.aws.amazon.com/kms/latest/developerguide/xks-troubleshooting.html). Both topics are in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a custom key store in a different Amazon Web Services account. Required permissions: kms:DescribeCustomKeyStores (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy) Related operations: ConnectCustomKeyStore CreateCustomKeyStore DeleteCustomKeyStore DisconnectCustomKeyStore UpdateCustomKeyStore
#
# POST /
# operationId: DescribeCustomKeyStores
export def "api get-custom-key-stores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-10
  --custom-key-store-id: any
  --custom-key-store-name: any
  --limit-body: any #  (body field)
  --marker-body: any #  (body field)
]: any -> record<CustomKeyStores: record, NextMarker: record, Truncated: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"CustomKeyStoreId": $custom_key_store_id, "CustomKeyStoreName": $custom_key_store_name, "Limit": $limit_body, "Marker": $marker_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Limit": $limit, "Marker": $marker} | compact), body: $req_body}
}

# Provides detailed information about a KMS key. You can run DescribeKey on a customer managed key (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk) or an Amazon Web Services managed key (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk). This detailed information includes the key ARN, creation date (and deletion date, if applicable), the key state, and the origin and expiration date (if any) of the key material. It includes fields, like KeySpec, that help you distinguish different types of KMS keys. It also displays the key usage (encryption, signing, or generating and verifying MACs) and the algorithms that the KMS key supports. For multi-Region keys (kms/latest/developerguide/multi-region-keys-overview.html), DescribeKey displays the primary key and all related replica keys. For KMS keys in CloudHSM key stores (kms/latest/developerguide/keystore-cloudhsm.html), it includes information about the key store, such as the key store ID and the CloudHSM cluster ID. For KMS keys in external key stores (kms/latest/developerguide/keystore-external.html), it includes the custom key store ID and the ID of the external key. DescribeKey does not return the following information: Aliases associated with the KMS key. To get this information, use ListAliases. Whether automatic key rotation is enabled on the KMS key. To get this information, use GetKeyRotationStatus. Also, some key states prevent a KMS key from being automatically rotated. For details, see How Automatic Key Rotation Works (https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-how-it-works) in the Key Management Service Developer Guide. Tags on the KMS key. To get this information, use ListResourceTags. Key policies and grants on the KMS key. To get this information, use GetKeyPolicy and ListGrants. In general, DescribeKey is a non-mutating operation. It returns data about KMS keys, but doesn't change them. However, Amazon Web Services services use DescribeKey to create Amazon Web Services managed keys (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk) from a predefined Amazon Web Services alias with no key ID. Cross-account use: Yes. To perform this operation with a KMS key in a different Amazon Web Services account, specify the key ARN or alias ARN in the value of the KeyId parameter. Required permissions: kms:DescribeKey (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: GetKeyPolicy GetKeyRotationStatus ListAliases ListGrants ListKeys ListResourceTags ListRetirableGrants
#
# POST /
# operationId: DescribeKey
export def "api get-key" [
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
  key_id: any
  --grant-tokens: any
]: any -> record<KeyMetadata: record<AWSAccountId: record, KeyId: record, Arn: record, CreationDate: record, Enabled: record, Description: record, KeyUsage: record, KeyState: record, DeletionDate: record, ValidTo: record, Origin: record, CustomKeyStoreId: record, CloudHsmClusterId: record, ExpirationModel: record, KeyManager: record, CustomerMasterKeySpec: record, KeySpec: record, EncryptionAlgorithms: record, SigningAlgorithms: record, MultiRegion: record, MultiRegionConfiguration: record<MultiRegionKeyType: record, PrimaryKey: record, ReplicaKeys: record>, PendingDeletionWindowInDays: record, MacAlgorithms: record, XksKeyConfiguration: record<Id: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "GrantTokens": $grant_tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sets the state of a KMS key to disabled. This change temporarily prevents use of the KMS key for cryptographic operations (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations). For more information about how key state affects the use of a KMS key, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide . The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:DisableKey (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: EnableKey
#
# POST /
# operationId: DisableKey
export def "api disable-key" [
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
  key_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disables automatic rotation of the key material (https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html) of the specified symmetric encryption KMS key. Automatic key rotation is supported only on symmetric encryption KMS keys. You cannot enable automatic rotation of asymmetric KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html), HMAC KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html), KMS keys with imported key material (https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html), or KMS keys in a custom key store (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html). To enable or disable automatic rotation of a set of related multi-Region keys (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-manage.html#multi-region-rotate), set the property on the primary key. You can enable (EnableKeyRotation) and disable automatic rotation of the key material in customer managed KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk). Key material rotation of Amazon Web Services managed KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk) is not configurable. KMS always rotates the key material for every year. Rotation of Amazon Web Services owned KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-cmk) varies. In May 2022, KMS changed the rotation schedule for Amazon Web Services managed keys from every three years to every year. For details, see EnableKeyRotation. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:DisableKeyRotation (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: EnableKeyRotation GetKeyRotationStatus
#
# POST /
# operationId: DisableKeyRotation
export def "api disable-key-rotation" [
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
  key_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disconnects the custom key store (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html) from its backing key store. This operation disconnects an CloudHSM key store from its associated CloudHSM cluster or disconnects an external key store from the external key store proxy that communicates with your external key manager. This operation is part of the custom key stores (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html) feature in KMS, which combines the convenience and extensive integration of KMS with the isolation and control of a key store that you own and manage. While a custom key store is disconnected, you can manage the custom key store and its KMS keys, but you cannot create or use its KMS keys. You can reconnect the custom key store at any time. While a custom key store is disconnected, all attempts to create KMS keys in the custom key store or to use existing KMS keys in cryptographic operations (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations) will fail. This action can prevent users from storing and accessing sensitive data. When you disconnect a custom key store, its ConnectionState changes to Disconnected. To find the connection state of a custom key store, use the DescribeCustomKeyStores operation. To reconnect a custom key store, use the ConnectCustomKeyStore operation. If the operation succeeds, it returns a JSON object with no properties. Cross-account use: No. You cannot perform this operation on a custom key store in a different Amazon Web Services account. Required permissions: kms:DisconnectCustomKeyStore (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy) Related operations: ConnectCustomKeyStore CreateCustomKeyStore DeleteCustomKeyStore DescribeCustomKeyStores UpdateCustomKeyStore
#
# POST /
# operationId: DisconnectCustomKeyStore
export def "api create-disconnect-custom-key-store" [
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
  custom_key_store_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CustomKeyStoreId": $custom_key_store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sets the key state of a KMS key to enabled. This allows you to use the KMS key for cryptographic operations (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#cryptographic-operations). The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:EnableKey (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: DisableKey
#
# POST /
# operationId: EnableKey
export def "api enable-key" [
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
  key_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Enables automatic rotation of the key material (https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html) of the specified symmetric encryption KMS key. When you enable automatic rotation of acustomer managed KMS key (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk), KMS rotates the key material of the KMS key one year (approximately 365 days) from the enable date and every year thereafter. You can monitor rotation of the key material for your KMS keys in CloudTrail and Amazon CloudWatch. To disable rotation of the key material in a customer managed KMS key, use the DisableKeyRotation operation. Automatic key rotation is supported only on symmetric encryption KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#symmetric-cmks). You cannot enable automatic rotation of asymmetric KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html), HMAC KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html), KMS keys with imported key material (https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html), or KMS keys in a custom key store (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html). To enable or disable automatic rotation of a set of related multi-Region keys (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-manage.html#multi-region-rotate), set the property on the primary key. You cannot enable or disable automatic rotation Amazon Web Services managed KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk). KMS always rotates the key material of Amazon Web Services managed keys every year. Rotation of Amazon Web Services owned KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-cmk) varies. In May 2022, KMS changed the rotation schedule for Amazon Web Services managed keys from every three years (approximately 1,095 days) to every year (approximately 365 days). New Amazon Web Services managed keys are automatically rotated one year after they are created, and approximately every year thereafter. Existing Amazon Web Services managed keys are automatically rotated one year after their most recent rotation, and every year thereafter. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:EnableKeyRotation (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: DisableKeyRotation GetKeyRotationStatus
#
# POST /
# operationId: EnableKeyRotation
export def "api enable-key-rotation" [
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
  key_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Encrypts plaintext of up to 4,096 bytes using a KMS key. You can use a symmetric or asymmetric KMS key with a KeyUsage of ENCRYPT_DECRYPT. You can use this operation to encrypt small amounts of arbitrary data, such as a personal identifier or database password, or other sensitive information. You don't need to use the Encrypt operation to encrypt a data key. The GenerateDataKey and GenerateDataKeyPair operations return a plaintext data key and an encrypted copy of that data key. If you use a symmetric encryption KMS key, you can use an encryption context to add additional security to your encryption operation. If you specify an EncryptionContext when encrypting data, you must specify the same encryption context (a case-sensitive exact match) when decrypting the data. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see Encryption Context (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context) in the Key Management Service Developer Guide. If you specify an asymmetric KMS key, you must also specify the encryption algorithm. The algorithm must be compatible with the KMS key spec. When you use an asymmetric KMS key to encrypt or reencrypt data, be sure to record the KMS key and encryption algorithm that you choose. You will be required to provide the same KMS key and encryption algorithm when you decrypt the data. If the KMS key and algorithm do not match the values used to encrypt the data, the decrypt operation fails. You are not required to supply the key ID and encryption algorithm when you decrypt with symmetric encryption KMS keys because KMS stores this information in the ciphertext blob. KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields. The maximum size of the data that you can encrypt varies with the type of KMS key and the encryption algorithm that you choose. Symmetric encryption KMS keys SYMMETRIC_DEFAULT: 4096 bytes RSA_2048 RSAES_OAEP_SHA_1: 214 bytes RSAES_OAEP_SHA_256: 190 bytes RSA_3072 RSAES_OAEP_SHA_1: 342 bytes RSAES_OAEP_SHA_256: 318 bytes RSA_4096 RSAES_OAEP_SHA_1: 470 bytes RSAES_OAEP_SHA_256: 446 bytes SM2PKE: 1024 bytes (China Regions only) The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. To perform this operation with a KMS key in a different Amazon Web Services account, specify the key ARN or alias ARN in the value of the KeyId parameter. Required permissions: kms:Encrypt (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: Decrypt GenerateDataKey GenerateDataKeyPair
#
# POST /
# operationId: Encrypt
export def "api create-encrypt" [
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
  key_id: any
  plaintext: any
  --encryption-context: any
  --grant-tokens: any
  --encryption-algorithm: any
]: any -> record<CiphertextBlob: record, KeyId: record, EncryptionAlgorithm: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "Plaintext": $plaintext, "EncryptionContext": $encryption_context, "GrantTokens": $grant_tokens, "EncryptionAlgorithm": $encryption_algorithm} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a unique symmetric data key for use outside of KMS. This operation returns a plaintext copy of the data key and a copy that is encrypted under a symmetric encryption KMS key that you specify. The bytes in the plaintext key are random; they are not related to the caller or the KMS key. You can use the plaintext key to encrypt your data outside of KMS and store the encrypted data key with the encrypted data. To generate a data key, specify the symmetric encryption KMS key that will be used to encrypt the data key. You cannot use an asymmetric KMS key to encrypt data keys. To get the type of your KMS key, use the DescribeKey operation. You must also specify the length of the data key. Use either the KeySpec or NumberOfBytes parameters (but not both). For 128-bit and 256-bit data keys, use the KeySpec parameter. To generate a 128-bit SM4 data key (China Regions only), specify a KeySpec value of AES_128 or a NumberOfBytes value of 16. The symmetric encryption key used in China Regions to encrypt your data key is an SM4 encryption key. To get only an encrypted copy of the data key, use GenerateDataKeyWithoutPlaintext. To generate an asymmetric data key pair, use the GenerateDataKeyPair or GenerateDataKeyPairWithoutPlaintext operation. To get a cryptographically secure random byte string, use GenerateRandom. You can use an optional encryption context to add additional security to the encryption operation. If you specify an EncryptionContext, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see Encryption Context (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context) in the Key Management Service Developer Guide. Applications in Amazon Web Services Nitro Enclaves can call this operation by using the Amazon Web Services Nitro Enclaves Development Kit (https://github.com/aws/aws-nitro-enclaves-sdk-c). For information about the supporting parameters, see How Amazon Web Services Nitro Enclaves use KMS (https://docs.aws.amazon.com/kms/latest/developerguide/services-nitro-enclaves.html) in the Key Management Service Developer Guide. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. How to use your data key We recommend that you use the following pattern to encrypt data locally in your application. You can write your own code or use a client-side encryption library, such as the Amazon Web Services Encryption SDK (https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/), the Amazon DynamoDB Encryption Client (https://docs.aws.amazon.com/dynamodb-encryption-client/latest/devguide/), or Amazon S3 client-side encryption (https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html) to do these tasks for you. To encrypt data outside of KMS: Use the GenerateDataKey operation to get a data key. Use the plaintext data key (in the Plaintext field of the response) to encrypt your data outside of KMS. Then erase the plaintext data key from memory. Store the encrypted data key (in the CiphertextBlob field of the response) with the encrypted data. To decrypt data outside of KMS: Use the Decrypt operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key. Use the plaintext data key to decrypt data outside of KMS, then erase the plaintext data key from memory. Cross-account use: Yes. To perform this operation with a KMS key in a different Amazon Web Services account, specify the key ARN or alias ARN in the value of the KeyId parameter. Required permissions: kms:GenerateDataKey (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: Decrypt Encrypt GenerateDataKeyPair GenerateDataKeyPairWithoutPlaintext GenerateDataKeyWithoutPlaintext
#
# POST /
# operationId: GenerateDataKey
export def "api generate-data-key" [
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
  key_id: any
  --encryption-context: any
  --number-of-bytes: any
  --key-spec: any
  --grant-tokens: any
]: any -> record<CiphertextBlob: record, Plaintext: record, KeyId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "EncryptionContext": $encryption_context, "NumberOfBytes": $number_of_bytes, "KeySpec": $key_spec, "GrantTokens": $grant_tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a unique asymmetric data key pair for use outside of KMS. This operation returns a plaintext public key, a plaintext private key, and a copy of the private key that is encrypted under the symmetric encryption KMS key you specify. You can use the data key pair to perform asymmetric cryptography and implement digital signatures outside of KMS. The bytes in the keys are random; they not related to the caller or to the KMS key that is used to encrypt the private key. You can use the public key that GenerateDataKeyPair returns to encrypt data or verify a signature outside of KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the Decrypt operation to decrypt the encrypted private key. To generate a data key pair, you must specify a symmetric encryption KMS key to encrypt the private key in a data key pair. You cannot use an asymmetric KMS key or a KMS key in a custom key store. To get the type and origin of your KMS key, use the DescribeKey operation. Use the KeyPairSpec parameter to choose an RSA or Elliptic Curve (ECC) data key pair. In China Regions, you can also choose an SM2 data key pair. KMS recommends that you use ECC key pairs for signing, and use RSA and SM2 key pairs for either encryption or signing, but not both. However, KMS cannot enforce any restrictions on the use of data key pairs outside of KMS. If you are using the data key pair to encrypt data, or for any operation where you don't immediately need a private key, consider using the GenerateDataKeyPairWithoutPlaintext operation. GenerateDataKeyPairWithoutPlaintext returns a plaintext public key and an encrypted private key, but omits the plaintext private key that you need only to decrypt ciphertext or sign a message. Later, when you need to decrypt the data or sign a message, use the Decrypt operation to decrypt the encrypted private key in the data key pair. GenerateDataKeyPair returns a unique data key pair for each request. The bytes in the keys are random; they are not related to the caller or the KMS key that is used to encrypt the private key. The public key is a DER-encoded X.509 SubjectPublicKeyInfo, as specified in RFC 5280 (https://tools.ietf.org/html/rfc5280). The private key is a DER-encoded PKCS8 PrivateKeyInfo, as specified in RFC 5958 (https://tools.ietf.org/html/rfc5958). You can use an optional encryption context to add additional security to the encryption operation. If you specify an EncryptionContext, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see Encryption Context (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context) in the Key Management Service Developer Guide. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. To perform this operation with a KMS key in a different Amazon Web Services account, specify the key ARN or alias ARN in the value of the KeyId parameter. Required permissions: kms:GenerateDataKeyPair (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: Decrypt Encrypt GenerateDataKey GenerateDataKeyPairWithoutPlaintext GenerateDataKeyWithoutPlaintext
#
# POST /
# operationId: GenerateDataKeyPair
export def "api generate-data-key-pair" [
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
  --encryption-context: any
  key_id: any
  key_pair_spec: any
  --grant-tokens: any
]: any -> record<PrivateKeyCiphertextBlob: record, PrivateKeyPlaintext: record, PublicKey: record, KeyId: record, KeyPairSpec: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"EncryptionContext": $encryption_context, "KeyId": $key_id, "KeyPairSpec": $key_pair_spec, "GrantTokens": $grant_tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a unique asymmetric data key pair for use outside of KMS. This operation returns a plaintext public key and a copy of the private key that is encrypted under the symmetric encryption KMS key you specify. Unlike GenerateDataKeyPair, this operation does not return a plaintext private key. The bytes in the keys are random; they are not related to the caller or to the KMS key that is used to encrypt the private key. You can use the public key that GenerateDataKeyPairWithoutPlaintext returns to encrypt data or verify a signature outside of KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the Decrypt operation to decrypt the encrypted private key. To generate a data key pair, you must specify a symmetric encryption KMS key to encrypt the private key in a data key pair. You cannot use an asymmetric KMS key or a KMS key in a custom key store. To get the type and origin of your KMS key, use the DescribeKey operation. Use the KeyPairSpec parameter to choose an RSA or Elliptic Curve (ECC) data key pair. In China Regions, you can also choose an SM2 data key pair. KMS recommends that you use ECC key pairs for signing, and use RSA and SM2 key pairs for either encryption or signing, but not both. However, KMS cannot enforce any restrictions on the use of data key pairs outside of KMS. GenerateDataKeyPairWithoutPlaintext returns a unique data key pair for each request. The bytes in the key are not related to the caller or KMS key that is used to encrypt the private key. The public key is a DER-encoded X.509 SubjectPublicKeyInfo, as specified in RFC 5280 (https://tools.ietf.org/html/rfc5280). You can use an optional encryption context to add additional security to the encryption operation. If you specify an EncryptionContext, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see Encryption Context (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context) in the Key Management Service Developer Guide. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. To perform this operation with a KMS key in a different Amazon Web Services account, specify the key ARN or alias ARN in the value of the KeyId parameter. Required permissions: kms:GenerateDataKeyPairWithoutPlaintext (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: Decrypt Encrypt GenerateDataKey GenerateDataKeyPair GenerateDataKeyWithoutPlaintext
#
# POST /
# operationId: GenerateDataKeyPairWithoutPlaintext
export def "api generate-data-key-pair-without-plaintext" [
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
  --encryption-context: any
  key_id: any
  key_pair_spec: any
  --grant-tokens: any
]: any -> record<PrivateKeyCiphertextBlob: record, PublicKey: record, KeyId: record, KeyPairSpec: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"EncryptionContext": $encryption_context, "KeyId": $key_id, "KeyPairSpec": $key_pair_spec, "GrantTokens": $grant_tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a unique symmetric data key for use outside of KMS. This operation returns a data key that is encrypted under a symmetric encryption KMS key that you specify. The bytes in the key are random; they are not related to the caller or to the KMS key. GenerateDataKeyWithoutPlaintext is identical to the GenerateDataKey operation except that it does not return a plaintext copy of the data key. This operation is useful for systems that need to encrypt data at some point, but not immediately. When you need to encrypt the data, you call the Decrypt operation on the encrypted copy of the key. It's also useful in distributed systems with different levels of trust. For example, you might store encrypted data in containers. One component of your system creates new containers and stores an encrypted data key with each container. Then, a different component puts the data into the containers. That component first decrypts the data key, uses the plaintext data key to encrypt data, puts the encrypted data into the container, and then destroys the plaintext data key. In this system, the component that creates the containers never sees the plaintext data key. To request an asymmetric data key pair, use the GenerateDataKeyPair or GenerateDataKeyPairWithoutPlaintext operations. To generate a data key, you must specify the symmetric encryption KMS key that is used to encrypt the data key. You cannot use an asymmetric KMS key or a key in a custom key store to generate a data key. To get the type of your KMS key, use the DescribeKey operation. You must also specify the length of the data key. Use either the KeySpec or NumberOfBytes parameters (but not both). For 128-bit and 256-bit data keys, use the KeySpec parameter. To generate an SM4 data key (China Regions only), specify a KeySpec value of AES_128 or NumberOfBytes value of 128. The symmetric encryption key used in China Regions to encrypt your data key is an SM4 encryption key. If the operation succeeds, you will find the encrypted copy of the data key in the CiphertextBlob field. You can use an optional encryption context to add additional security to the encryption operation. If you specify an EncryptionContext, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see Encryption Context (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context) in the Key Management Service Developer Guide. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. To perform this operation with a KMS key in a different Amazon Web Services account, specify the key ARN or alias ARN in the value of the KeyId parameter. Required permissions: kms:GenerateDataKeyWithoutPlaintext (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: Decrypt Encrypt GenerateDataKey GenerateDataKeyPair GenerateDataKeyPairWithoutPlaintext
#
# POST /
# operationId: GenerateDataKeyWithoutPlaintext
export def "api generate-data-key-without-plaintext" [
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
  key_id: any
  --encryption-context: any
  --key-spec: any
  --number-of-bytes: any
  --grant-tokens: any
]: any -> record<CiphertextBlob: record, KeyId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "EncryptionContext": $encryption_context, "KeySpec": $key_spec, "NumberOfBytes": $number_of_bytes, "GrantTokens": $grant_tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generates a hash-based message authentication code (HMAC) for a message using an HMAC KMS key and a MAC algorithm that the key supports. HMAC KMS keys and the HMAC algorithms that KMS uses conform to industry standards defined in RFC 2104 (https://datatracker.ietf.org/doc/html/rfc2104). You can use value that GenerateMac returns in the VerifyMac operation to demonstrate that the original message has not changed. Also, because a secret key is used to create the hash, you can verify that the party that generated the hash has the required secret key. You can also use the raw result to implement HMAC-based algorithms such as key derivation functions. This operation is part of KMS support for HMAC KMS keys. For details, see HMAC keys in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html) in the Key Management Service Developer Guide . Best practices recommend that you limit the time during which any signing mechanism, including an HMAC, is effective. This deters an attack where the actor uses a signed message to establish validity repeatedly or long after the message is superseded. HMAC tags do not include a timestamp, but you can include a timestamp in the token or message to help you detect when its time to refresh the HMAC. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. To perform this operation with a KMS key in a different Amazon Web Services account, specify the key ARN or alias ARN in the value of the KeyId parameter. Required permissions: kms:GenerateMac (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: VerifyMac
#
# POST /
# operationId: GenerateMac
export def "api generate-mac" [
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
  --x-amz-target: string@x-amz-target-completer-22
  message: any
  key_id: any
  mac_algorithm: any
  --grant-tokens: any
]: any -> record<Mac: record, MacAlgorithm: record, KeyId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"Message": $message, "KeyId": $key_id, "MacAlgorithm": $mac_algorithm, "GrantTokens": $grant_tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a random byte string that is cryptographically secure. You must use the NumberOfBytes parameter to specify the length of the random byte string. There is no default value for string length. By default, the random byte string is generated in KMS. To generate the byte string in the CloudHSM cluster associated with an CloudHSM key store, use the CustomKeyStoreId parameter. Applications in Amazon Web Services Nitro Enclaves can call this operation by using the Amazon Web Services Nitro Enclaves Development Kit (https://github.com/aws/aws-nitro-enclaves-sdk-c). For information about the supporting parameters, see How Amazon Web Services Nitro Enclaves use KMS (https://docs.aws.amazon.com/kms/latest/developerguide/services-nitro-enclaves.html) in the Key Management Service Developer Guide. For more information about entropy and random number generation, see Key Management Service Cryptographic Details (https://docs.aws.amazon.com/kms/latest/cryptographic-details/). Cross-account use: Not applicable. GenerateRandom does not use any account-specific resources, such as KMS keys. Required permissions: kms:GenerateRandom (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy)
#
# POST /
# operationId: GenerateRandom
export def "api generate-random" [
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
  --x-amz-target: string@x-amz-target-completer-23
  --number-of-bytes: any
  --custom-key-store-id: any
]: any -> record<Plaintext: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"NumberOfBytes": $number_of_bytes, "CustomKeyStoreId": $custom_key_store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a key policy attached to the specified KMS key. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:GetKeyPolicy (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: PutKeyPolicy
#
# POST /
# operationId: GetKeyPolicy
export def "api get-key-policy" [
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
  --x-amz-target: string@x-amz-target-completer-24
  key_id: any
  policy_name: any
]: any -> record<Policy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "PolicyName": $policy_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a Boolean value that indicates whether automatic rotation of the key material (https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html) is enabled for the specified KMS key. When you enable automatic rotation for customer managed KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk), KMS rotates the key material of the KMS key one year (approximately 365 days) from the enable date and every year thereafter. You can monitor rotation of the key material for your KMS keys in CloudTrail and Amazon CloudWatch. Automatic key rotation is supported only on symmetric encryption KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#symmetric-cmks). You cannot enable automatic rotation of asymmetric KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html), HMAC KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html), KMS keys with imported key material (https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html), or KMS keys in a custom key store (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html). To enable or disable automatic rotation of a set of related multi-Region keys (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-manage.html#multi-region-rotate), set the property on the primary key.. You can enable (EnableKeyRotation) and disable automatic rotation (DisableKeyRotation) of the key material in customer managed KMS keys. Key material rotation of Amazon Web Services managed KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk) is not configurable. KMS always rotates the key material in Amazon Web Services managed KMS keys every year. The key rotation status for Amazon Web Services managed KMS keys is always true. In May 2022, KMS changed the rotation schedule for Amazon Web Services managed keys from every three years to every year. For details, see EnableKeyRotation. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Disabled: The key rotation status does not change when you disable a KMS key. However, while the KMS key is disabled, KMS does not rotate the key material. When you re-enable the KMS key, rotation resumes. If the key material in the re-enabled KMS key hasn't been rotated in one year, KMS rotates it immediately, and every year thereafter. If it's been less than a year since the key material in the re-enabled KMS key was rotated, the KMS key resumes its prior rotation schedule. Pending deletion: While a KMS key is pending deletion, its key rotation status is false and KMS does not rotate the key material. If you cancel the deletion, the original key rotation status returns to true. Cross-account use: Yes. To perform this operation on a KMS key in a different Amazon Web Services account, specify the key ARN in the value of the KeyId parameter. Required permissions: kms:GetKeyRotationStatus (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: DisableKeyRotation EnableKeyRotation
#
# POST /
# operationId: GetKeyRotationStatus
export def "api get-key-rotation-status" [
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
  --x-amz-target: string@x-amz-target-completer-25
  key_id: any
]: any -> record<KeyRotationEnabled: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the items you need to import key material into a symmetric encryption KMS key. For more information about importing key material into KMS, see Importing key material (https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html) in the Key Management Service Developer Guide. This operation returns a public key and an import token. Use the public key to encrypt the symmetric key material. Store the import token to send with a subsequent ImportKeyMaterial request. You must specify the key ID of the symmetric encryption KMS key into which you will import key material. The KMS key Origin must be EXTERNAL. You must also specify the wrapping algorithm and type of wrapping key (public key) that you will use to encrypt the key material. You cannot perform this operation on an asymmetric KMS key, an HMAC KMS key, or on any KMS key in a different Amazon Web Services account. To import key material, you must use the public key and import token from the same response. These items are valid for 24 hours. The expiration date and time appear in the GetParametersForImport response. You cannot use an expired token in an ImportKeyMaterial request. If your key and token expire, send another GetParametersForImport request. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:GetParametersForImport (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: ImportKeyMaterial DeleteImportedKeyMaterial
#
# POST /
# operationId: GetParametersForImport
export def "api get-parameters-for-import" [
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
  --x-amz-target: string@x-amz-target-completer-26
  key_id: any
  wrapping_algorithm: any
  wrapping_key_spec: any
]: any -> record<KeyId: record, ImportToken: record, PublicKey: record, ParametersValidTo: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "WrappingAlgorithm": $wrapping_algorithm, "WrappingKeySpec": $wrapping_key_spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the public key of an asymmetric KMS key. Unlike the private key of a asymmetric KMS key, which never leaves KMS unencrypted, callers with kms:GetPublicKey permission can download the public key of an asymmetric KMS key. You can share the public key to allow others to encrypt messages and verify signatures outside of KMS. For information about asymmetric KMS keys, see Asymmetric KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html) in the Key Management Service Developer Guide. You do not need to download the public key. Instead, you can use the public key within KMS by calling the Encrypt, ReEncrypt, or Verify operations with the identifier of an asymmetric KMS key. When you use the public key within KMS, you benefit from the authentication, authorization, and logging that are part of every KMS operation. You also reduce of risk of encrypting data that cannot be decrypted. These features are not effective outside of KMS. To help you use the public key safely outside of KMS, GetPublicKey returns important information about the public key in the response, including: KeySpec (https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-KeySpec): The type of key material in the public key, such as RSA_4096 or ECC_NIST_P521. KeyUsage (https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-KeyUsage): Whether the key is used for encryption or signing. EncryptionAlgorithms (https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-EncryptionAlgorithms) or SigningAlgorithms (https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-SigningAlgorithms): A list of the encryption algorithms or the signing algorithms for the key. Although KMS cannot enforce these restrictions on external operations, it is crucial that you use this information to prevent the public key from being used improperly. For example, you can prevent a public signing key from being used encrypt data, or prevent a public key from being used with an encryption algorithm that is not supported by KMS. You can also avoid errors, such as using the wrong signing algorithm in a verification operation. To verify a signature outside of KMS with an SM2 public key (China Regions only), you must specify the distinguishing ID. By default, KMS uses 1234567812345678 as the distinguishing ID. For more information, see Offline verification with SM2 key pairs (https://docs.aws.amazon.com/kms/latest/developerguide/asymmetric-key-specs.html#key-spec-sm-offline-verification). The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. To perform this operation with a KMS key in a different Amazon Web Services account, specify the key ARN or alias ARN in the value of the KeyId parameter. Required permissions: kms:GetPublicKey (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: CreateKey
#
# POST /
# operationId: GetPublicKey
export def "api get-public-key" [
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
  --x-amz-target: string@x-amz-target-completer-27
  key_id: any
  --grant-tokens: any
]: any -> record<KeyId: record, PublicKey: record, CustomerMasterKeySpec: record, KeySpec: record, KeyUsage: record, EncryptionAlgorithms: record, SigningAlgorithms: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "GrantTokens": $grant_tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Imports key material into an existing symmetric encryption KMS key that was created without key material. After you successfully import key material into a KMS key, you can reimport the same key material (https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#reimport-key-material) into that KMS key, but you cannot import different key material. You cannot perform this operation on an asymmetric KMS key, an HMAC KMS key, or on any KMS key in a different Amazon Web Services account. For more information about creating KMS keys with no key material and then importing key material, see Importing Key Material (https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html) in the Key Management Service Developer Guide. Before using this operation, call GetParametersForImport. Its response includes a public key and an import token. Use the public key to encrypt the key material. Then, submit the import token from the same GetParametersForImport response. When calling this operation, you must specify the following values: The key ID or key ARN of a KMS key with no key material. Its Origin must be EXTERNAL. To create a KMS key with no key material, call CreateKey and set the value of its Origin parameter to EXTERNAL. To get the Origin of a KMS key, call DescribeKey.) The encrypted key material. To get the public key to encrypt the key material, call GetParametersForImport. The import token that GetParametersForImport returned. You must use a public key and token from the same GetParametersForImport response. Whether the key material expires (ExpirationModel) and, if so, when (ValidTo). If you set an expiration date, on the specified date, KMS deletes the key material from the KMS key, making the KMS key unusable. To use the KMS key in cryptographic operations again, you must reimport the same key material. The only way to change the expiration model or expiration date is by reimporting the same key material and specifying a new expiration date. When this operation is successful, the key state of the KMS key changes from PendingImport to Enabled, and you can use the KMS key. If this operation fails, use the exception to help determine the problem. If the error is related to the key material, the import token, or wrapping key, use GetParametersForImport to get a new public key and import token for the KMS key and repeat the import procedure. For help, see How To Import Key Material (https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#importing-keys-overview) in the Key Management Service Developer Guide. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:ImportKeyMaterial (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: DeleteImportedKeyMaterial GetParametersForImport
#
# POST /
# operationId: ImportKeyMaterial
export def "api import-key-material" [
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
  --x-amz-target: string@x-amz-target-completer-28
  key_id: any
  import_token: any
  encrypted_key_material: any
  --valid-to: any
  --expiration-model: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "ImportToken": $import_token, "EncryptedKeyMaterial": $encrypted_key_material, "ValidTo": $valid_to, "ExpirationModel": $expiration_model} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a list of aliases in the caller's Amazon Web Services account and region. For more information about aliases, see CreateAlias. By default, the ListAliases operation returns all aliases in the account and region. To get only the aliases associated with a particular KMS key, use the KeyId parameter. The ListAliases response can include aliases that you created and associated with your customer managed keys, and aliases that Amazon Web Services created and associated with Amazon Web Services managed keys in your account. You can recognize Amazon Web Services aliases because their names have the format aws/<service-name>, such as aws/dynamodb. The response might also include aliases that have no TargetKeyId field. These are predefined aliases that Amazon Web Services has created but has not yet associated with a KMS key. Aliases that Amazon Web Services creates in your account, including predefined aliases, do not count against your KMS aliases quota (https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit). Cross-account use: No. ListAliases does not return aliases in other Amazon Web Services accounts. Required permissions: kms:ListAliases (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy) For details, see Controlling access to aliases (https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html#alias-access) in the Key Management Service Developer Guide. Related operations: CreateAlias DeleteAlias UpdateAlias
#
# POST /
# operationId: ListAliases
export def "api list-aliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29
  --key-id: any
  --limit-body: any #  (body field)
  --marker-body: any #  (body field)
]: any -> record<Aliases: record, NextMarker: record, Truncated: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"KeyId": $key_id, "Limit": $limit_body, "Marker": $marker_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Limit": $limit, "Marker": $marker} | compact), body: $req_body}
}

# Gets a list of all grants for the specified KMS key. You must specify the KMS key in all requests. You can filter the grant list by grant ID or grantee principal. For detailed information about grants, including grant terminology, see Grants in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/grants.html) in the Key Management Service Developer Guide . For examples of working with grants in several programming languages, see Programming grants (https://docs.aws.amazon.com/kms/latest/developerguide/programming-grants.html). The GranteePrincipal field in the ListGrants response usually contains the user or role designated as the grantee principal in the grant. However, when the grantee principal in the grant is an Amazon Web Services service, the GranteePrincipal field contains the service principal (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-services), which might represent several different grantee principals. Cross-account use: Yes. To perform this operation on a KMS key in a different Amazon Web Services account, specify the key ARN in the value of the KeyId parameter. Required permissions: kms:ListGrants (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: CreateGrant ListRetirableGrants RetireGrant RevokeGrant
#
# POST /
# operationId: ListGrants
export def "api list-grants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30
  --limit-body: any #  (body field)
  --marker-body: any #  (body field)
  key_id: any
  --grant-id: any
  --grantee-principal: any
]: any -> record<Grants: record, NextMarker: record, Truncated: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"Limit": $limit_body, "Marker": $marker_body, "KeyId": $key_id, "GrantId": $grant_id, "GranteePrincipal": $grantee_principal} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Limit": $limit, "Marker": $marker} | compact), body: $req_body}
}

# Gets the names of the key policies that are attached to a KMS key. This operation is designed to get policy names that you can use in a GetKeyPolicy operation. However, the only valid policy name is default. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:ListKeyPolicies (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: GetKeyPolicy PutKeyPolicy
#
# POST /
# operationId: ListKeyPolicies
export def "api list-key-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31
  key_id: any
  --limit-body: any #  (body field)
  --marker-body: any #  (body field)
]: any -> record<PolicyNames: record, NextMarker: record, Truncated: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"KeyId": $key_id, "Limit": $limit_body, "Marker": $marker_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Limit": $limit, "Marker": $marker} | compact), body: $req_body}
}

# Gets a list of all KMS keys in the caller's Amazon Web Services account and Region. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:ListKeys (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy) Related operations: CreateKey DescribeKey ListAliases ListResourceTags
#
# POST /
# operationId: ListKeys
export def "api list-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32
  --limit-body: any #  (body field)
  --marker-body: any #  (body field)
]: any -> record<Keys: record, NextMarker: record, Truncated: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"Limit": $limit_body, "Marker": $marker_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Limit": $limit, "Marker": $marker} | compact), body: $req_body}
}

# Returns all tags on the specified KMS key. For general information about tags, including the format and syntax, see Tagging Amazon Web Services resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. For information about using tags in KMS, see Tagging keys (https://docs.aws.amazon.com/kms/latest/developerguide/tagging-keys.html). Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:ListResourceTags (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: CreateKey ReplicateKey TagResource UntagResource
#
# POST /
# operationId: ListResourceTags
export def "api list-resource-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33
  key_id: any
  --limit-body: any #  (body field)
  --marker-body: any #  (body field)
]: any -> record<Tags: record, NextMarker: record, Truncated: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"KeyId": $key_id, "Limit": $limit_body, "Marker": $marker_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Limit": $limit, "Marker": $marker} | compact), body: $req_body}
}

# Returns information about all grants in the Amazon Web Services account and Region that have the specified retiring principal. You can specify any principal in your Amazon Web Services account. The grants that are returned include grants for KMS keys in your Amazon Web Services account and other Amazon Web Services accounts. You might use this operation to determine which grants you may retire. To retire a grant, use the RetireGrant operation. For detailed information about grants, including grant terminology, see Grants in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/grants.html) in the Key Management Service Developer Guide . For examples of working with grants in several programming languages, see Programming grants (https://docs.aws.amazon.com/kms/latest/developerguide/programming-grants.html). Cross-account use: You must specify a principal in your Amazon Web Services account. However, this operation can return grants in any Amazon Web Services account. You do not need kms:ListRetirableGrants permission (or any other additional permission) in any Amazon Web Services account other than your own. Required permissions: kms:ListRetirableGrants (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy) in your Amazon Web Services account. Related operations: CreateGrant ListGrants RetireGrant RevokeGrant
#
# POST /
# operationId: ListRetirableGrants
export def "api list-retirable-grants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34
  --limit-body: any #  (body field)
  --marker-body: any #  (body field)
  retiring_principal: any
]: any -> record<Grants: record, NextMarker: record, Truncated: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"Limit": $limit_body, "Marker": $marker_body, "RetiringPrincipal": $retiring_principal} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Limit": $limit, "Marker": $marker} | compact), body: $req_body}
}

# Attaches a key policy to the specified KMS key. For more information about key policies, see Key Policies (https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html) in the Key Management Service Developer Guide. For help writing and formatting a JSON policy document, see the IAM JSON Policy Reference (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html) in the Identity and Access Management User Guide . For examples of adding a key policy in multiple programming languages, see Setting a key policy (https://docs.aws.amazon.com/kms/latest/developerguide/programming-key-policies.html#put-policy) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:PutKeyPolicy (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: GetKeyPolicy
#
# POST /
# operationId: PutKeyPolicy
export def "api update-key-policy" [
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
  --x-amz-target: string@x-amz-target-completer-35
  key_id: any
  policy_name: any
  policy: any
  --bypass-policy-lockout-safety-check: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "PolicyName": $policy_name, "Policy": $policy, "BypassPolicyLockoutSafetyCheck": $bypass_policy_lockout_safety_check} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Decrypts ciphertext and then reencrypts it entirely within KMS. You can use this operation to change the KMS key under which data is encrypted, such as when you manually rotate (https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-manually) a KMS key or change the KMS key that protects a ciphertext. You can also use it to reencrypt ciphertext under the same KMS key, such as to change the encryption context (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context) of a ciphertext. The ReEncrypt operation can decrypt ciphertext that was encrypted by using a KMS key in an KMS operation, such as Encrypt or GenerateDataKey. It can also decrypt ciphertext that was encrypted by using the public key of an asymmetric KMS key (https://docs.aws.amazon.com/kms/latest/developerguide/symm-asymm-concepts.html#asymmetric-cmks) outside of KMS. However, it cannot decrypt ciphertext produced by other libraries, such as the Amazon Web Services Encryption SDK (https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/) or Amazon S3 client-side encryption (https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html). These libraries return a ciphertext format that is incompatible with KMS. When you use the ReEncrypt operation, you need to provide information for the decrypt operation and the subsequent encrypt operation. If your ciphertext was encrypted under an asymmetric KMS key, you must use the SourceKeyId parameter to identify the KMS key that encrypted the ciphertext. You must also supply the encryption algorithm that was used. This information is required to decrypt the data. If your ciphertext was encrypted under a symmetric encryption KMS key, the SourceKeyId parameter is optional. KMS can get this information from metadata that it adds to the symmetric ciphertext blob. This feature adds durability to your implementation by ensuring that authorized users can decrypt ciphertext decades after it was encrypted, even if they've lost track of the key ID. However, specifying the source KMS key is always recommended as a best practice. When you use the SourceKeyId parameter to specify a KMS key, KMS uses only the KMS key you specify. If the ciphertext was encrypted under a different KMS key, the ReEncrypt operation fails. This practice ensures that you use the KMS key that you intend. To reencrypt the data, you must use the DestinationKeyId parameter to specify the KMS key that re-encrypts the data after it is decrypted. If the destination KMS key is an asymmetric KMS key, you must also provide the encryption algorithm. The algorithm that you choose must be compatible with the KMS key. When you use an asymmetric KMS key to encrypt or reencrypt data, be sure to record the KMS key and encryption algorithm that you choose. You will be required to provide the same KMS key and encryption algorithm when you decrypt the data. If the KMS key and algorithm do not match the values used to encrypt the data, the decrypt operation fails. You are not required to supply the key ID and encryption algorithm when you decrypt with symmetric encryption KMS keys because KMS stores this information in the ciphertext blob. KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. The source KMS key and destination KMS key can be in different Amazon Web Services accounts. Either or both KMS keys can be in a different account than the caller. To specify a KMS key in a different account, you must use its key ARN or alias ARN. Required permissions: kms:ReEncryptFrom (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) permission on the source KMS key (key policy) kms:ReEncryptTo (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) permission on the destination KMS key (key policy) To permit reencryption from or to a KMS key, include the "kms:ReEncrypt*" permission in your key policy (https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html). This permission is automatically included in the key policy when you use the console to create a KMS key. But you must include it manually when you create a KMS key programmatically or when you use the PutKeyPolicy operation to set a key policy. Related operations: Decrypt Encrypt GenerateDataKey GenerateDataKeyPair
#
# POST /
# operationId: ReEncrypt
export def "api create-re-encrypt" [
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
  --x-amz-target: string@x-amz-target-completer-36
  ciphertext_blob: any
  --source-encryption-context: any
  --source-key-id: any
  destination_key_id: any
  --destination-encryption-context: any
  --source-encryption-algorithm: any
  --destination-encryption-algorithm: any
  --grant-tokens: any
]: any -> record<CiphertextBlob: record, SourceKeyId: record, KeyId: record, SourceEncryptionAlgorithm: record, DestinationEncryptionAlgorithm: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CiphertextBlob": $ciphertext_blob, "SourceEncryptionContext": $source_encryption_context, "SourceKeyId": $source_key_id, "DestinationKeyId": $destination_key_id, "DestinationEncryptionContext": $destination_encryption_context, "SourceEncryptionAlgorithm": $source_encryption_algorithm, "DestinationEncryptionAlgorithm": $destination_encryption_algorithm, "GrantTokens": $grant_tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replicates a multi-Region key into the specified Region. This operation creates a multi-Region replica key based on a multi-Region primary key in a different Region of the same Amazon Web Services partition. You can create multiple replicas of a primary key, but each must be in a different Region. To create a multi-Region primary key, use the CreateKey operation. This operation supports multi-Region keys, an KMS feature that lets you create multiple interoperable KMS keys in different Amazon Web Services Regions. Because these KMS keys have the same key ID, key material, and other metadata, you can use them interchangeably to encrypt data in one Amazon Web Services Region and decrypt it in a different Amazon Web Services Region without re-encrypting the data or making a cross-Region call. For more information about multi-Region keys, see Multi-Region keys in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html) in the Key Management Service Developer Guide. A replica key is a fully-functional KMS key that can be used independently of its primary and peer replica keys. A primary key and its replica keys share properties that make them interoperable. They have the same key ID (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-id-key-id) and key material. They also have the same key spec (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-spec), key usage (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-usage), key material origin (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-origin), and automatic key rotation status (https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html). KMS automatically synchronizes these shared properties among related multi-Region keys. All other properties of a replica key can differ, including its key policy (https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html), tags (https://docs.aws.amazon.com/kms/latest/developerguide/tagging-keys.html), aliases (https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html), and Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html). KMS pricing and quotas for KMS keys apply to each primary key and replica key. When this operation completes, the new replica key has a transient key state of Creating. This key state changes to Enabled (or PendingImport) after a few seconds when the process of creating the new replica key is complete. While the key state is Creating, you can manage key, but you cannot yet use it in cryptographic operations. If you are creating and using the replica key programmatically, retry on KMSInvalidStateException or call DescribeKey to check its KeyState value before using it. For details about the Creating key state, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. You cannot create more than one replica of a primary key in any Region. If the Region already includes a replica of the key you're trying to replicate, ReplicateKey returns an AlreadyExistsException error. If the key state of the existing replica is PendingDeletion, you can cancel the scheduled key deletion (CancelKeyDeletion) or wait for the key to be deleted. The new replica key you create will have the same shared properties (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html#mrk-sync-properties) as the original replica key. The CloudTrail log of a ReplicateKey operation records a ReplicateKey operation in the primary key's Region and a CreateKey operation in the replica key's Region. If you replicate a multi-Region primary key with imported key material, the replica key is created with no key material. You must import the same key material that you imported into the primary key. For details, see Importing key material into multi-Region keys (kms/latest/developerguide/multi-region-keys-import.html) in the Key Management Service Developer Guide. To convert a replica key to a primary key, use the UpdatePrimaryRegion operation. ReplicateKey uses different default values for the KeyPolicy and Tags parameters than those used in the KMS console. For details, see the parameter descriptions. Cross-account use: No. You cannot use this operation to create a replica key in a different Amazon Web Services account. Required permissions: kms:ReplicateKey on the primary key (in the primary key's Region). Include this permission in the primary key's key policy. kms:CreateKey in an IAM policy in the replica Region. To use the Tags parameter, kms:TagResource in an IAM policy in the replica Region. Related operations CreateKey UpdatePrimaryRegion
#
# POST /
# operationId: ReplicateKey
export def "api create-replicate-key" [
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
  --x-amz-target: string@x-amz-target-completer-37
  key_id: any
  replica_region: any
  --policy: any
  --bypass-policy-lockout-safety-check: any
  --description: any
  --tags: any
]: any -> record<ReplicaKeyMetadata: record<AWSAccountId: record, KeyId: record, Arn: record, CreationDate: record, Enabled: record, Description: record, KeyUsage: record, KeyState: record, DeletionDate: record, ValidTo: record, Origin: record, CustomKeyStoreId: record, CloudHsmClusterId: record, ExpirationModel: record, KeyManager: record, CustomerMasterKeySpec: record, KeySpec: record, EncryptionAlgorithms: record, SigningAlgorithms: record, MultiRegion: record, MultiRegionConfiguration: record<MultiRegionKeyType: record, PrimaryKey: record, ReplicaKeys: record>, PendingDeletionWindowInDays: record, MacAlgorithms: record, XksKeyConfiguration: record<Id: record>>, ReplicaPolicy: record, ReplicaTags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "ReplicaRegion": $replica_region, "Policy": $policy, "BypassPolicyLockoutSafetyCheck": $bypass_policy_lockout_safety_check, "Description": $description, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a grant. Typically, you retire a grant when you no longer need its permissions. To identify the grant to retire, use a grant token (https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token), or both the grant ID and a key identifier (key ID or key ARN) of the KMS key. The CreateGrant operation returns both values. This operation can be called by the retiring principal for a grant, by the grantee principal if the grant allows the RetireGrant operation, and by the Amazon Web Services account in which the grant is created. It can also be called by principals to whom permission for retiring a grant is delegated. For details, see Retiring and revoking grants (https://docs.aws.amazon.com/kms/latest/developerguide/grant-manage.html#grant-delete) in the Key Management Service Developer Guide. For detailed information about grants, including grant terminology, see Grants in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/grants.html) in the Key Management Service Developer Guide . For examples of working with grants in several programming languages, see Programming grants (https://docs.aws.amazon.com/kms/latest/developerguide/programming-grants.html). Cross-account use: Yes. You can retire a grant on a KMS key in a different Amazon Web Services account. Required permissions::Permission to retire a grant is determined primarily by the grant. For details, see Retiring and revoking grants (https://docs.aws.amazon.com/kms/latest/developerguide/grant-manage.html#grant-delete) in the Key Management Service Developer Guide. Related operations: CreateGrant ListGrants ListRetirableGrants RevokeGrant
#
# POST /
# operationId: RetireGrant
export def "api create-retire-grant" [
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
  --x-amz-target: string@x-amz-target-completer-38
  --grant-token: any
  --key-id: any
  --grant-id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"GrantToken": $grant_token, "KeyId": $key_id, "GrantId": $grant_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the specified grant. You revoke a grant to terminate the permissions that the grant allows. For more information, see Retiring and revoking grants (https://docs.aws.amazon.com/kms/latest/developerguide/managing-grants.html#grant-delete) in the Key Management Service Developer Guide . When you create, retire, or revoke a grant, there might be a brief delay, usually less than five minutes, until the grant is available throughout KMS. This state is known as eventual consistency. For details, see Eventual consistency (https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#terms-eventual-consistency) in the Key Management Service Developer Guide . For detailed information about grants, including grant terminology, see Grants in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/grants.html) in the Key Management Service Developer Guide . For examples of working with grants in several programming languages, see Programming grants (https://docs.aws.amazon.com/kms/latest/developerguide/programming-grants.html). Cross-account use: Yes. To perform this operation on a KMS key in a different Amazon Web Services account, specify the key ARN in the value of the KeyId parameter. Required permissions: kms:RevokeGrant (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy). Related operations: CreateGrant ListGrants ListRetirableGrants RetireGrant
#
# POST /
# operationId: RevokeGrant
export def "api delete-grant" [
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
  --x-amz-target: string@x-amz-target-completer-39
  key_id: any
  grant_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "GrantId": $grant_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Schedules the deletion of a KMS key. By default, KMS applies a waiting period of 30 days, but you can specify a waiting period of 7-30 days. When this operation is successful, the key state of the KMS key changes to PendingDeletion and the key can't be used in any cryptographic operations. It remains in this state for the duration of the waiting period. Before the waiting period ends, you can use CancelKeyDeletion to cancel the deletion of the KMS key. After the waiting period ends, KMS deletes the KMS key, its key material, and all KMS data associated with it, including all aliases that refer to it. Deleting a KMS key is a destructive and potentially dangerous operation. When a KMS key is deleted, all data that was encrypted under the KMS key is unrecoverable. (The only exception is a multi-Region replica key.) To prevent the use of a KMS key without deleting it, use DisableKey. You can schedule the deletion of a multi-Region primary key and its replica keys at any time. However, KMS will not delete a multi-Region primary key with existing replica keys. If you schedule the deletion of a primary key with replicas, its key state changes to PendingReplicaDeletion and it cannot be replicated or used in cryptographic operations. This status can continue indefinitely. When the last of its replicas keys is deleted (not just scheduled), the key state of the primary key changes to PendingDeletion and its waiting period (PendingWindowInDays) begins. For details, see Deleting multi-Region keys (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-delete.html) in the Key Management Service Developer Guide. When KMS deletes a KMS key from an CloudHSM key store (https://docs.aws.amazon.com/kms/latest/developerguide/delete-cmk-keystore.html), it makes a best effort to delete the associated key material from the associated CloudHSM cluster. However, you might need to manually delete the orphaned key material (https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key) from the cluster and its backups. Deleting a KMS key from an external key store (https://docs.aws.amazon.com/kms/latest/developerguide/delete-xks-key.html) has no effect on the associated external key. However, for both types of custom key stores, deleting a KMS key is destructive and irreversible. You cannot decrypt ciphertext encrypted under the KMS key by using only its associated external key or CloudHSM key. Also, you cannot recreate a KMS key in an external key store by creating a new KMS key with the same key material. For more information about scheduling a KMS key for deletion, see Deleting KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html) in the Key Management Service Developer Guide. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:ScheduleKeyDeletion (key policy) Related operations CancelKeyDeletion DisableKey
#
# POST /
# operationId: ScheduleKeyDeletion
export def "api create-schedule-key-deletion" [
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
  --x-amz-target: string@x-amz-target-completer-40
  key_id: any
  --pending-window-in-days: any
]: any -> record<KeyId: record, DeletionDate: record, KeyState: record, PendingWindowInDays: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "PendingWindowInDays": $pending_window_in_days} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a digital signature (https://en.wikipedia.org/wiki/Digital_signature) for a message or message digest by using the private key in an asymmetric signing KMS key. To verify the signature, use the Verify operation, or use the public key in the same asymmetric KMS key outside of KMS. For information about asymmetric KMS keys, see Asymmetric KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html) in the Key Management Service Developer Guide. Digital signatures are generated and verified by using asymmetric key pair, such as an RSA or ECC pair that is represented by an asymmetric KMS key. The key owner (or an authorized user) uses their private key to sign a message. Anyone with the public key can verify that the message was signed with that particular private key and that the message hasn't changed since it was signed. To use the Sign operation, provide the following information: Use the KeyId parameter to identify an asymmetric KMS key with a KeyUsage value of SIGN_VERIFY. To get the KeyUsage value of a KMS key, use the DescribeKey operation. The caller must have kms:Sign permission on the KMS key. Use the Message parameter to specify the message or message digest to sign. You can submit messages of up to 4096 bytes. To sign a larger message, generate a hash digest of the message, and then provide the hash digest in the Message parameter. To indicate whether the message is a full message or a digest, use the MessageType parameter. Choose a signing algorithm that is compatible with the KMS key. When signing a message, be sure to record the KMS key and the signing algorithm. This information is required to verify the signature. Best practices recommend that you limit the time during which any signature is effective. This deters an attack where the actor uses a signed message to establish validity repeatedly or long after the message is superseded. Signatures do not include a timestamp, but you can include a timestamp in the signed message to help you detect when its time to refresh the signature. To verify the signature that this operation generates, use the Verify operation. Or use the GetPublicKey operation to download the public key and then use the public key to verify the signature outside of KMS. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. To perform this operation with a KMS key in a different Amazon Web Services account, specify the key ARN or alias ARN in the value of the KeyId parameter. Required permissions: kms:Sign (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: Verify
#
# POST /
# operationId: Sign
export def "api create-sign" [
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
  --x-amz-target: string@x-amz-target-completer-41
  key_id: any
  message: any
  --message-type: any
  --grant-tokens: any
  signing_algorithm: any
]: any -> record<KeyId: record, Signature: record, SigningAlgorithm: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "Message": $message, "MessageType": $message_type, "GrantTokens": $grant_tokens, "SigningAlgorithm": $signing_algorithm} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds or edits tags on a customer managed key (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk). Tagging or untagging a KMS key can allow or deny permission to the KMS key. For details, see ABAC for KMS (https://docs.aws.amazon.com/kms/latest/developerguide/abac.html) in the Key Management Service Developer Guide. Each tag consists of a tag key and a tag value, both of which are case-sensitive strings. The tag value can be an empty (null) string. To add a tag, specify a new tag key and a tag value. To edit a tag, specify an existing tag key and a new tag value. You can use this operation to tag a customer managed key (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk), but you cannot tag an Amazon Web Services managed key (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk), an Amazon Web Services owned key (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-cmk), a custom key store (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#keystore-concept), or an alias (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#alias-concept). You can also add tags to a KMS key while creating it (CreateKey) or replicating it (ReplicateKey). For information about using tags in KMS, see Tagging keys (https://docs.aws.amazon.com/kms/latest/developerguide/tagging-keys.html). For general information about tags, including the format and syntax, see Tagging Amazon Web Services resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:TagResource (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations CreateKey ListResourceTags ReplicateKey UntagResource
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
  --x-amz-target: string@x-amz-target-completer-42
  key_id: any
  tags: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes tags from a customer managed key (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk). To delete a tag, specify the tag key and the KMS key. Tagging or untagging a KMS key can allow or deny permission to the KMS key. For details, see ABAC for KMS (https://docs.aws.amazon.com/kms/latest/developerguide/abac.html) in the Key Management Service Developer Guide. When it succeeds, the UntagResource operation doesn't return any output. Also, if the specified tag key isn't found on the KMS key, it doesn't throw an exception or return a response. To confirm that the operation worked, use the ListResourceTags operation. For information about using tags in KMS, see Tagging keys (https://docs.aws.amazon.com/kms/latest/developerguide/tagging-keys.html). For general information about tags, including the format and syntax, see Tagging Amazon Web Services resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:UntagResource (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations CreateKey ListResourceTags ReplicateKey TagResource
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
  --x-amz-target: string@x-amz-target-completer-43
  key_id: any
  tag_keys: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Associates an existing KMS alias with a different KMS key. Each alias is associated with only one KMS key at a time, although a KMS key can have multiple aliases. The alias and the KMS key must be in the same Amazon Web Services account and Region. Adding, deleting, or updating an alias can allow or deny permission to the KMS key. For details, see ABAC for KMS (https://docs.aws.amazon.com/kms/latest/developerguide/abac.html) in the Key Management Service Developer Guide. The current and new KMS key must be the same type (both symmetric or both asymmetric or both HMAC), and they must have the same key usage. This restriction prevents errors in code that uses aliases. If you must assign an alias to a different type of KMS key, use DeleteAlias to delete the old alias and CreateAlias to create a new alias. You cannot use UpdateAlias to change an alias name. To change an alias name, use DeleteAlias to delete the old alias and CreateAlias to create a new alias. Because an alias is not a property of a KMS key, you can create, update, and delete the aliases of a KMS key without affecting the KMS key. Also, aliases do not appear in the response from the DescribeKey operation. To get the aliases of all KMS keys in the account, use the ListAliases operation. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions kms:UpdateAlias (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) on the alias (IAM policy). kms:UpdateAlias (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) on the current KMS key (key policy). kms:UpdateAlias (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) on the new KMS key (key policy). For details, see Controlling access to aliases (https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html#alias-access) in the Key Management Service Developer Guide. Related operations: CreateAlias DeleteAlias ListAliases
#
# POST /
# operationId: UpdateAlias
export def "api update-alias" [
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
  --x-amz-target: string@x-amz-target-completer-44
  alias_name: any
  target_key_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"AliasName": $alias_name, "TargetKeyId": $target_key_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Changes the properties of a custom key store. You can use this operation to change the properties of an CloudHSM key store or an external key store. Use the required CustomKeyStoreId parameter to identify the custom key store. Use the remaining optional parameters to change its properties. This operation does not return any property values. To verify the updated property values, use the DescribeCustomKeyStores operation. This operation is part of the custom key stores (https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html) feature in KMS, which combines the convenience and extensive integration of KMS with the isolation and control of a key store that you own and manage. When updating the properties of an external key store, verify that the updated settings connect your key store, via the external key store proxy, to the same external key manager as the previous settings, or to a backup or snapshot of the external key manager with the same cryptographic keys. If the updated connection settings fail, you can fix them and retry, although an extended delay might disrupt Amazon Web Services services. However, if KMS permanently loses its access to cryptographic keys, ciphertext encrypted under those keys is unrecoverable. For external key stores: Some external key managers provide a simpler method for updating an external key store. For details, see your external key manager documentation. When updating an external key store in the KMS console, you can upload a JSON-based proxy configuration file with the desired values. You cannot upload the proxy configuration file to the UpdateCustomKeyStore operation. However, you can use the file to help you determine the correct values for the UpdateCustomKeyStore parameters. For an CloudHSM key store, you can use this operation to change the custom key store friendly name (NewCustomKeyStoreName), to tell KMS about a change to the kmsuser crypto user password (KeyStorePassword), or to associate the custom key store with a different, but related, CloudHSM cluster (CloudHsmClusterId). To update any property of an CloudHSM key store, the ConnectionState of the CloudHSM key store must be DISCONNECTED. For an external key store, you can use this operation to change the custom key store friendly name (NewCustomKeyStoreName), or to tell KMS about a change to the external key store proxy authentication credentials (XksProxyAuthenticationCredential), connection method (XksProxyConnectivity), external proxy endpoint (XksProxyUriEndpoint) and path (XksProxyUriPath). For external key stores with an XksProxyConnectivity of VPC_ENDPOINT_SERVICE, you can also update the Amazon VPC endpoint service name (XksProxyVpcEndpointServiceName). To update most properties of an external key store, the ConnectionState of the external key store must be DISCONNECTED. However, you can update the CustomKeyStoreName, XksProxyAuthenticationCredential, and XksProxyUriPath of an external key store when it is in the CONNECTED or DISCONNECTED state. If your update requires a DISCONNECTED state, before using UpdateCustomKeyStore, use the DisconnectCustomKeyStore operation to disconnect the custom key store. After the UpdateCustomKeyStore operation completes, use the ConnectCustomKeyStore to reconnect the custom key store. To find the ConnectionState of the custom key store, use the DescribeCustomKeyStores operation. Before updating the custom key store, verify that the new values allow KMS to connect the custom key store to its backing key store. For example, before you change the XksProxyUriPath value, verify that the external key store proxy is reachable at the new path. If the operation succeeds, it returns a JSON object with no properties. Cross-account use: No. You cannot perform this operation on a custom key store in a different Amazon Web Services account. Required permissions: kms:UpdateCustomKeyStore (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (IAM policy) Related operations: ConnectCustomKeyStore CreateCustomKeyStore DeleteCustomKeyStore DescribeCustomKeyStores DisconnectCustomKeyStore
#
# POST /
# operationId: UpdateCustomKeyStore
export def "api update-custom-key-store" [
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
  --x-amz-target: string@x-amz-target-completer-45
  custom_key_store_id: any
  --new-custom-key-store-name: any
  --key-store-password: any
  --cloud-hsm-cluster-id: any
  --xks-proxy-uri-endpoint: any
  --xks-proxy-uri-path: any
  --xks-proxy-vpc-endpoint-service-name: any
  --xks-proxy-authentication-credential: any
  --xks-proxy-connectivity: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"CustomKeyStoreId": $custom_key_store_id, "NewCustomKeyStoreName": $new_custom_key_store_name, "KeyStorePassword": $key_store_password, "CloudHsmClusterId": $cloud_hsm_cluster_id, "XksProxyUriEndpoint": $xks_proxy_uri_endpoint, "XksProxyUriPath": $xks_proxy_uri_path, "XksProxyVpcEndpointServiceName": $xks_proxy_vpc_endpoint_service_name, "XksProxyAuthenticationCredential": $xks_proxy_authentication_credential, "XksProxyConnectivity": $xks_proxy_connectivity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the description of a KMS key. To see the description of a KMS key, use DescribeKey. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: No. You cannot perform this operation on a KMS key in a different Amazon Web Services account. Required permissions: kms:UpdateKeyDescription (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations CreateKey DescribeKey
#
# POST /
# operationId: UpdateKeyDescription
export def "api update-key-description" [
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
  --x-amz-target: string@x-amz-target-completer-46
  key_id: any
  description: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "Description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Changes the primary key of a multi-Region key. This operation changes the replica key in the specified Region to a primary key and changes the former primary key to a replica key. For example, suppose you have a primary key in us-east-1 and a replica key in eu-west-2. If you run UpdatePrimaryRegion with a PrimaryRegion value of eu-west-2, the primary key is now the key in eu-west-2, and the key in us-east-1 becomes a replica key. For details, see Updating the primary Region (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-manage.html#multi-region-update) in the Key Management Service Developer Guide. This operation supports multi-Region keys, an KMS feature that lets you create multiple interoperable KMS keys in different Amazon Web Services Regions. Because these KMS keys have the same key ID, key material, and other metadata, you can use them interchangeably to encrypt data in one Amazon Web Services Region and decrypt it in a different Amazon Web Services Region without re-encrypting the data or making a cross-Region call. For more information about multi-Region keys, see Multi-Region keys in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html) in the Key Management Service Developer Guide. The primary key of a multi-Region key is the source for properties that are always shared by primary and replica keys, including the key material, key ID (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-id-key-id), key spec (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-spec), key usage (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-usage), key material origin (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-origin), and automatic key rotation (https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html). It's the only key that can be replicated. You cannot delete the primary key (https://docs.aws.amazon.com/kms/latest/APIReference/API_ScheduleKeyDeletion.html) until all replica keys are deleted. The key ID and primary Region that you specify uniquely identify the replica key that will become the primary key. The primary Region must already have a replica key. This operation does not create a KMS key in the specified Region. To find the replica keys, use the DescribeKey operation on the primary key or any replica key. To create a replica key, use the ReplicateKey operation. You can run this operation while using the affected multi-Region keys in cryptographic operations. This operation should not delay, interrupt, or cause failures in cryptographic operations. Even after this operation completes, the process of updating the primary Region might still be in progress for a few more seconds. Operations such as DescribeKey might display both the old and new primary keys as replicas. The old and new primary keys have a transient key state of Updating. The original key state is restored when the update is complete. While the key state is Updating, you can use the keys in cryptographic operations, but you cannot replicate the new primary key or perform certain management operations, such as enabling or disabling these keys. For details about the Updating key state, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. This operation does not return any output. To verify that primary key is changed, use the DescribeKey operation. Cross-account use: No. You cannot use this operation in a different Amazon Web Services account. Required permissions: kms:UpdatePrimaryRegion on the current primary key (in the primary key's Region). Include this permission primary key's key policy. kms:UpdatePrimaryRegion on the current replica key (in the replica key's Region). Include this permission in the replica key's key policy. Related operations CreateKey ReplicateKey
#
# POST /
# operationId: UpdatePrimaryRegion
export def "api update-primary-region" [
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
  --x-amz-target: string@x-amz-target-completer-47
  key_id: any
  primary_region: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "PrimaryRegion": $primary_region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verifies a digital signature that was generated by the Sign operation. Verification confirms that an authorized user signed the message with the specified KMS key and signing algorithm, and the message hasn't changed since it was signed. If the signature is verified, the value of the SignatureValid field in the response is True. If the signature verification fails, the Verify operation fails with an KMSInvalidSignatureException exception. A digital signature is generated by using the private key in an asymmetric KMS key. The signature is verified by using the public key in the same asymmetric KMS key. For information about asymmetric KMS keys, see Asymmetric KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html) in the Key Management Service Developer Guide. To use the Verify operation, specify the same asymmetric KMS key, message, and signing algorithm that were used to produce the signature. The message type does not need to be the same as the one used for signing, but it must indicate whether the value of the Message parameter should be hashed as part of the verification process. You can also verify the digital signature by using the public key of the KMS key outside of KMS. Use the GetPublicKey operation to download the public key in the asymmetric KMS key and then use the public key to verify the signature outside of KMS. The advantage of using the Verify operation is that it is performed within KMS. As a result, it's easy to call, the operation is performed within the FIPS boundary, it is logged in CloudTrail, and you can use key policy and IAM policy to determine who is authorized to use the KMS key to verify signatures. To verify a signature outside of KMS with an SM2 public key (China Regions only), you must specify the distinguishing ID. By default, KMS uses 1234567812345678 as the distinguishing ID. For more information, see Offline verification with SM2 key pairs (https://docs.aws.amazon.com/kms/latest/developerguide/asymmetric-key-specs.html#key-spec-sm-offline-verification). The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. To perform this operation with a KMS key in a different Amazon Web Services account, specify the key ARN or alias ARN in the value of the KeyId parameter. Required permissions: kms:Verify (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: Sign
#
# POST /
# operationId: Verify
export def "api verify" [
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
  --x-amz-target: string@x-amz-target-completer-48
  key_id: any
  message: any
  --message-type: any
  signature: any
  signing_algorithm: any
  --grant-tokens: any
]: any -> record<KeyId: record, SignatureValid: record, SigningAlgorithm: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"KeyId": $key_id, "Message": $message, "MessageType": $message_type, "Signature": $signature, "SigningAlgorithm": $signing_algorithm, "GrantTokens": $grant_tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verifies the hash-based message authentication code (HMAC) for a specified message, HMAC KMS key, and MAC algorithm. To verify the HMAC, VerifyMac computes an HMAC using the message, HMAC KMS key, and MAC algorithm that you specify, and compares the computed HMAC to the HMAC that you specify. If the HMACs are identical, the verification succeeds; otherwise, it fails. Verification indicates that the message hasn't changed since the HMAC was calculated, and the specified key was used to generate and verify the HMAC. HMAC KMS keys and the HMAC algorithms that KMS uses conform to industry standards defined in RFC 2104 (https://datatracker.ietf.org/doc/html/rfc2104). This operation is part of KMS support for HMAC KMS keys. For details, see HMAC keys in KMS (https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html) in the Key Management Service Developer Guide. The KMS key that you use for this operation must be in a compatible key state. For details, see Key states of KMS keys (https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html) in the Key Management Service Developer Guide. Cross-account use: Yes. To perform this operation with a KMS key in a different Amazon Web Services account, specify the key ARN or alias ARN in the value of the KeyId parameter. Required permissions: kms:VerifyMac (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) (key policy) Related operations: GenerateMac
#
# POST /
# operationId: VerifyMac
export def "api verify-mac" [
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
  --x-amz-target: string@x-amz-target-completer-49
  message: any
  key_id: any
  mac_algorithm: any
  mac: any
  --grant-tokens: any
]: any -> record<KeyId: record, MacValid: record, MacAlgorithm: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"Message": $message, "KeyId": $key_id, "MacAlgorithm": $mac_algorithm, "Mac": $mac, "GrantTokens": $grant_tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
