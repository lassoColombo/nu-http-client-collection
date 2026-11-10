# Auto-generated client for Amazon API Gateway v2015-07-09
# Source: https://api.apis.guru/v2/specs/amazonaws.com/apigateway/2015-07-09/openapi.json
# Auth: --token flag or $env.AMAZON_API_GATEWAY_TOKEN

const BASE_URL = "http://apigateway.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_API_GATEWAY_TOKEN | default "" }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://apigateway.us-east-1.amazonaws.com" "http://apigateway.us-east-2.amazonaws.com" "http://apigateway.us-west-1.amazonaws.com" "http://apigateway.us-west-2.amazonaws.com" "http://apigateway.us-gov-west-1.amazonaws.com" "http://apigateway.us-gov-east-1.amazonaws.com" "http://apigateway.ca-central-1.amazonaws.com" "http://apigateway.eu-north-1.amazonaws.com" "http://apigateway.eu-west-1.amazonaws.com" "http://apigateway.eu-west-2.amazonaws.com" "http://apigateway.eu-west-3.amazonaws.com" "http://apigateway.eu-central-1.amazonaws.com" "http://apigateway.eu-south-1.amazonaws.com" "http://apigateway.af-south-1.amazonaws.com" "http://apigateway.ap-northeast-1.amazonaws.com" "http://apigateway.ap-northeast-2.amazonaws.com" "http://apigateway.ap-northeast-3.amazonaws.com" "http://apigateway.ap-southeast-1.amazonaws.com" "http://apigateway.ap-southeast-2.amazonaws.com" "http://apigateway.ap-east-1.amazonaws.com" "http://apigateway.ap-south-1.amazonaws.com" "http://apigateway.sa-east-1.amazonaws.com" "http://apigateway.me-south-1.amazonaws.com" "https://apigateway.us-east-1.amazonaws.com" "https://apigateway.us-east-2.amazonaws.com" "https://apigateway.us-west-1.amazonaws.com" "https://apigateway.us-west-2.amazonaws.com" "https://apigateway.us-gov-west-1.amazonaws.com" "https://apigateway.us-gov-east-1.amazonaws.com" "https://apigateway.ca-central-1.amazonaws.com" "https://apigateway.eu-north-1.amazonaws.com" "https://apigateway.eu-west-1.amazonaws.com" "https://apigateway.eu-west-2.amazonaws.com" "https://apigateway.eu-west-3.amazonaws.com" "https://apigateway.eu-central-1.amazonaws.com" "https://apigateway.eu-south-1.amazonaws.com" "https://apigateway.af-south-1.amazonaws.com" "https://apigateway.ap-northeast-1.amazonaws.com" "https://apigateway.ap-northeast-2.amazonaws.com" "https://apigateway.ap-northeast-3.amazonaws.com" "https://apigateway.ap-southeast-1.amazonaws.com" "https://apigateway.ap-southeast-2.amazonaws.com" "https://apigateway.ap-east-1.amazonaws.com" "https://apigateway.ap-south-1.amazonaws.com" "https://apigateway.sa-east-1.amazonaws.com" "https://apigateway.me-south-1.amazonaws.com" "http://apigateway.cn-north-1.amazonaws.com.cn" "http://apigateway.cn-northwest-1.amazonaws.com.cn" "https://apigateway.cn-north-1.amazonaws.com.cn" "https://apigateway.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["COGNITO_USER_POOLS" "REQUEST" "TOKEN"] }
def cache-cluster-size-completer [] { ["0.5" "1.6" "118" "13.5" "237" "28.4" "58.2" "6.1"] }
def type-completer-1 [] { ["API" "AUTHORIZER" "METHOD" "MODEL" "PATH_PARAMETER" "QUERY_PARAMETER" "REQUEST_BODY" "REQUEST_HEADER" "RESOURCE" "RESPONSE" "RESPONSE_BODY" "RESPONSE_HEADER"] }
def location-status-completer [] { ["DOCUMENTED" "UNDOCUMENTED"] }
def mode-completer [] { ["merge" "overwrite"] }
def security-policy-completer [] { ["TLS_1_0" "TLS_1_2"] }
def api-key-source-completer [] { ["AUTHORIZER" "HEADER"] }
def response-type-completer [] { ["ACCESS_DENIED" "API_CONFIGURATION_ERROR" "AUTHORIZER_CONFIGURATION_ERROR" "AUTHORIZER_FAILURE" "BAD_REQUEST_BODY" "BAD_REQUEST_PARAMETERS" "DEFAULT_4XX" "DEFAULT_5XX" "EXPIRED_TOKEN" "INTEGRATION_FAILURE" "INTEGRATION_TIMEOUT" "INVALID_API_KEY" "INVALID_SIGNATURE" "MISSING_AUTHENTICATION_TOKEN" "QUOTA_EXCEEDED" "REQUEST_TOO_LARGE" "RESOURCE_NOT_FOUND" "THROTTLED" "UNAUTHORIZED" "UNSUPPORTED_MEDIA_TYPE" "WAF_FILTERED"] }
def type-completer-2 [] { ["AWS" "AWS_PROXY" "HTTP" "HTTP_PROXY" "MOCK"] }
def connection-type-completer [] { ["INTERNET" "VPC_LINK"] }
def content-handling-completer [] { ["CONVERT_TO_BINARY" "CONVERT_TO_TEXT"] }
def format-completer [] { ["csv"] }
def mode-completer-1 [] { ["import"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-api-key" "get-api-keys" "create-authorizer" "get-authorizers" "create-base-path-mapping" "get-base-path-mappings" "create-deployment" "get-deployments" "create-documentation-part" "get-documentation-parts" "import-documentation-parts" "create-documentation-version" "get-documentation-versions" "create-domain-name" "get-domain-names" "create-model" "get-models" "create-request-validator" "get-request-validators" "create-resource" "create-rest-api" "get-rest-apis" "create-stage" "get-stages" "create-usage-plan" "get-usage-plans" "create-usage-plan-key" "get-usage-plan-keys" "create-vpc-link" "get-vpc-links" "delete-api-key" "get-api-key" "update-api-key" "delete-authorizer" "get-authorizer" "test-invoke-authorizer" "update-authorizer" "delete-base-path-mapping" "get-base-path-mapping" "update-base-path-mapping" "delete-client-certificate" "get-client-certificate" "update-client-certificate" "delete-deployment" "get-deployment" "update-deployment" "delete-documentation-part" "get-documentation-part" "update-documentation-part" "delete-documentation-version" "get-documentation-version" "update-documentation-version" "delete-domain-name" "get-domain-name" "update-domain-name" "delete-gateway-response" "get-gateway-response" "put-gateway-response" "update-gateway-response" "delete-integration" "get-integration" "put-integration" "update-integration" "delete-integration-response" "get-integration-response" "put-integration-response" "update-integration-response" "delete-method" "get-method" "put-method" "test-invoke-method" "update-method" "delete-method-response" "get-method-response" "put-method-response" "update-method-response" "delete-model" "get-model" "update-model" "delete-request-validator" "get-request-validator" "update-request-validator" "delete-resource" "get-resource" "update-resource" "delete-rest-api" "get-rest-api" "put-rest-api" "update-rest-api" "delete-stage" "get-stage" "update-stage" "delete-usage-plan" "get-usage-plan" "update-usage-plan" "delete-usage-plan-key" "get-usage-plan-key" "delete-vpc-link" "get-vpc-link" "update-vpc-link" "flush-stage-authorizers-cache" "flush-stage-cache" "generate-client-certificate" "get-client-certificates" "get-account" "update-account" "get-export" "get-gateway-responses" "get-model-template" "get-resources" "get-sdk" "get-sdk-type" "get-sdk-types" "get-tags" "tag-resource" "get-usage" "import-api-keys" "import-rest-api" "untag-resource" "update-usage" "commands"] | sort) } | get name | first)
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

# Create an ApiKey resource.
#
# POST /apikeys
# operationId: CreateApiKey
export def "create-api-key" [
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
  --name: string # The name of the ApiKey.
  --description: string # The description of the ApiKey.
  --enabled: oneof<nothing, bool> # Specifies whether the ApiKey can be used by callers.
  --generate-distinct-id: oneof<nothing, bool> # Specifies whether (true) or not (false) the key identifier is distinct from the created API key value. This parameter is deprecated and should not be used.
  --value: string # Specifies a value of the API key.
  --stage-keys: list # DEPRECATED FOR USAGE PLANS - Specifies stages associated with the API key. — item shape: {restApiId?: string, stageName?: string}
  --customer-id: string # An AWS Marketplace customer identifier , when integrating with the AWS SaaS Marketplace.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> oneof<record<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list<string>, tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apikeys" $auth.query)
  let req_body = {"name": $name, "description": $description, "enabled": $enabled, "generateDistinctId": $generate_distinct_id, "value": $value, "stageKeys": $stage_keys, "customerId": $customer_id, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets information about the current ApiKeys resource.
#
# GET /apikeys
# operationId: GetApiKeys
export def "get-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --name: string # The name of queried API keys.
  --customer-id: string # The identifier of a customer in AWS Marketplace or an external system, such as a developer portal.
  --include-values: oneof<nothing, bool> # A boolean flag to specify whether (true) or not (false) the result contains key values.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<warnings: list<string>, position: string, items: table<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list, tags: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "customerId" $customer_id "scalar") (serialize-qp "includeValues" $include_values "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apikeys" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit, "name": $name, "customerId": $customer_id, "includeValues": $include_values} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a new Authorizer resource to an existing RestApi resource.
#
# POST /restapis/{restapi_id}/authorizers
# operationId: CreateAuthorizer
export def "create-authorizer" [
  restapi_id: string
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
  name: string # The name of the authorizer.
  type: string@type-completer # The authorizer type. Valid values are TOKEN for a Lambda function using a single authorization token submitted in a custom header, REQUEST for a Lambda function using incoming request parameters, and COGNITO_USER_POOLS for using an Amazon Cognito user pool.
  --provider-ar-ns: list<string> # A list of the Amazon Cognito user pool ARNs for the COGNITO_USER_POOLS authorizer. Each element is of this format: arn:aws:cognito-idp:{region}:{account_id}:userpool/{user_pool_id}. For a TOKEN or REQUEST authorizer, this is not defined.
  --auth-type: string # Optional customer-defined field, used in OpenAPI imports and exports without functional impact.
  --authorizer-uri: string # Specifies the authorizer's Uniform Resource Identifier (URI). For TOKEN or REQUEST authorizers, this must be a well-formed Lambda function URI, for example, arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:{account_id}:function:{lambda_function_name}/invocations. In general, the URI has this form arn:aws:apigateway:{region}:lambda:path/{service_api}, where {region} is the same as the region hosting the Lambda function, path indicates that the remaining substring in the URI should be treated as the path to the resource, including the initial /. For Lambda functions, this is usually of the form /2015-03-31/functions/[FunctionARN]/invocations.
  --authorizer-credentials: string # Specifies the required credentials as an IAM role for API Gateway to invoke the authorizer. To specify an IAM role for API Gateway to assume, use the role's Amazon Resource Name (ARN). To use resource-based permissions on the Lambda function, specify null.
  --identity-source: string # The identity source for which authorization is requested. For a TOKEN or COGNITO_USER_POOLS authorizer, this is required and specifies the request header mapping expression for the custom header holding the authorization token submitted by the client. For example, if the token header name is Auth, the header mapping expression is method.request.header.Auth. For the REQUEST authorizer, this is required when authorization caching is enabled. The value is a comma-separated string of one or more mapping expressions of the specified request parameters. For example, if an Auth header, a Name query string parameter are defined as identity sources, this value is method.request.header.Auth, method.request.querystring.Name. These parameters will be used to derive the authorization caching key and to perform runtime validation of the REQUEST authorizer by verifying all of the identity-related request parameters are present, not null and non-empty. Only when this is true does the authorizer invoke the authorizer Lambda function, otherwise, it returns a 401 Unauthorized response without calling the Lambda function. The valid value is a string of comma-separated mapping expressions of the specified request parameters. When the authorization caching is not enabled, this property is optional.
  --identity-validation-expression: string # A validation expression for the incoming identity token. For TOKEN authorizers, this value is a regular expression. For COGNITO_USER_POOLS authorizers, API Gateway will match the aud field of the incoming token from the client against the specified regular expression. It will invoke the authorizer's Lambda function when there is a match. Otherwise, it will return a 401 Unauthorized response without calling the Lambda function. The validation expression does not apply to the REQUEST authorizer.
  --authorizer-result-ttl-in-seconds: int # The TTL in seconds of cached authorizer results. If it equals 0, authorization caching is disabled. If it is greater than 0, API Gateway will cache authorizer responses. If this field is not set, the default value is 300. The maximum value is 3600, or 1 hour.
]: any -> oneof<record<id: string, name: string, type: string, providerARNs: list<string>, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/authorizers") $auth.query)
  let req_body = {"name": $name, "type": $type, "providerARNs": $provider_ar_ns, "authType": $auth_type, "authorizerUri": $authorizer_uri, "authorizerCredentials": $authorizer_credentials, "identitySource": $identity_source, "identityValidationExpression": $identity_validation_expression, "authorizerResultTtlInSeconds": $authorizer_result_ttl_in_seconds} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Describe an existing Authorizers resource.
#
# GET /restapis/{restapi_id}/authorizers
# operationId: GetAuthorizers
export def "get-authorizers" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<id: string, name: string, type: string, providerARNs: list, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/authorizers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new BasePathMapping resource.
#
# POST /domainnames/{domain_name}/basepathmappings
# operationId: CreateBasePathMapping
export def "create-base-path-mapping" [
  domain_name: string
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
  --base-path: string # The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify a base path name after the domain name.
  rest_api_id: string # The string identifier of the associated RestApi.
  --stage: string # The name of the API's stage that you want to use for this mapping. Specify '(none)' if you want callers to explicitly specify the stage name after any base path name.
]: any -> oneof<record<basePath: string, restApiId: string, stage: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domainnames/{domain_name}/basepathmappings") $auth.query)
  let req_body = {"basePath": $base_path, "restApiId": $rest_api_id, "stage": $stage} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Represents a collection of BasePathMapping resources.
#
# GET /domainnames/{domain_name}/basepathmappings
# operationId: GetBasePathMappings
export def "get-base-path-mappings" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<basePath: string, restApiId: string, stage: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domainnames/{domain_name}/basepathmappings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a Deployment resource, which makes a specified RestApi callable over the internet.
#
# POST /restapis/{restapi_id}/deployments
# operationId: CreateDeployment
export def "create-deployment" [
  restapi_id: string
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
  --stage-name: string # The name of the Stage resource for the Deployment resource to create.
  --stage-description: string # The description of the Stage resource for the Deployment resource to create.
  --description: string # The description for the Deployment resource to create.
  --cache-cluster-enabled: oneof<nothing, bool> # Enables a cache cluster for the Stage resource specified in the input.
  --cache-cluster-size: string@cache-cluster-size-completer # Returns the size of the CacheCluster.
  --variables: record # A map that defines the stage variables for the Stage resource that is associated with the new deployment. Variable names can have alphanumeric and underscore characters, and the values must match [A-Za-z0-9-._~:/?#&=,]+.
  --canary-settings: record # The input configuration for a canary deployment. — shape: {percentTraffic?: float, stageVariableOverrides?: record, useStageCache?: bool}
  --tracing-enabled: oneof<nothing, bool> # Specifies whether active tracing with X-ray is enabled for the Stage.
]: any -> oneof<record<id: string, description: string, createdDate: string, apiSummary: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/deployments") $auth.query)
  let req_body = {"stageName": $stage_name, "stageDescription": $stage_description, "description": $description, "cacheClusterEnabled": $cache_cluster_enabled, "cacheClusterSize": $cache_cluster_size, "variables": $variables, "canarySettings": $canary_settings, "tracingEnabled": $tracing_enabled} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets information about a Deployments collection.
#
# GET /restapis/{restapi_id}/deployments
# operationId: GetDeployments
export def "get-deployments" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<id: string, description: string, createdDate: string, apiSummary: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/deployments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a documentation part.
#
# POST /restapis/{restapi_id}/documentation/parts
# operationId: CreateDocumentationPart
export def "create-documentation-part" [
  restapi_id: string
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
  location: record # Specifies the target API entity to which the documentation applies. — shape: {type?: "API"|"AUTHORIZER"|"MODEL"|"RESOURCE"|"METHOD"|"PATH_PARAMETER"|"QUERY_PARAMETER"|"REQUEST_HEADER"|"REQUEST_BODY"|"RESPONSE"|"RESPONSE_HEADER"|"RESPONSE_BODY", path?: string, method?: string, statusCode?: string, name?: string}
  properties: string # The new documentation content map of the targeted API entity. Enclosed key-value pairs are API-specific, but only OpenAPI-compliant key-value pairs can be exported and, hence, published.
]: any -> oneof<record<id: string, location: record<type: string, path: string, method: string, statusCode: string, name: string>, properties: any>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/documentation/parts") $auth.query)
  let req_body = {"location": $location, "properties": $properties} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets documentation parts.
#
# GET /restapis/{restapi_id}/documentation/parts
# operationId: GetDocumentationParts
export def "get-documentation-parts" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # The type of API entities of the to-be-retrieved documentation parts.
  --name: string # The name of API entities of the to-be-retrieved documentation parts.
  --path: string # The path of API entities of the to-be-retrieved documentation parts.
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --location-status: string@location-status-completer # The status of the API documentation parts to retrieve. Valid values are DOCUMENTED for retrieving DocumentationPart resources with content and UNDOCUMENTED for DocumentationPart resources without content.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<id: string, location: record, properties: any>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "locationStatus" $location_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/documentation/parts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "name": $name, "path": $path, "position": $position, "limit": $limit, "locationStatus": $location_status} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Imports documentation parts
#
# PUT /restapis/{restapi_id}/documentation/parts
# operationId: ImportDocumentationParts
export def "import-documentation-parts" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer # A query parameter to indicate whether to overwrite (OVERWRITE) any existing DocumentationParts definition or to merge (MERGE) the new definition into the existing one. The default value is MERGE.
  --failonwarnings: oneof<nothing, bool> # A query parameter to specify whether to rollback the documentation importation (true) or not (false) when a warning is encountered. The default value is false.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # Raw byte array representing the to-be-imported documentation parts. To import from an OpenAPI file, this is a JSON object.
]: any -> oneof<record<ids: list<string>, warnings: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "mode" $mode "scalar") (serialize-qp "failonwarnings" $failonwarnings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/documentation/parts") $qp $auth.query)
  let req_body = {"body": $body} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"mode": $mode, "failonwarnings": $failonwarnings} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a documentation version
#
# POST /restapis/{restapi_id}/documentation/versions
# operationId: CreateDocumentationVersion
export def "create-documentation-version" [
  restapi_id: string
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
  documentation_version: string # The version identifier of the new snapshot.
  --stage-name: string # The stage name to be associated with the new documentation snapshot.
  --description: string # A description about the new documentation snapshot.
]: any -> oneof<record<version: string, createdDate: string, description: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/documentation/versions") $auth.query)
  let req_body = {"documentationVersion": $documentation_version, "stageName": $stage_name, "description": $description} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets documentation versions.
#
# GET /restapis/{restapi_id}/documentation/versions
# operationId: GetDocumentationVersions
export def "get-documentation-versions" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<version: string, createdDate: string, description: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/documentation/versions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new domain name.
#
# POST /domainnames
# operationId: CreateDomainName
export def "create-domain-name" [
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
  domain_name: string # The name of the DomainName resource.
  --certificate-name: string # The user-friendly name of the certificate that will be used by edge-optimized endpoint for this domain name.
  --certificate-body: string # [Deprecated] The body of the server certificate that will be used by edge-optimized endpoint for this domain name provided by your certificate authority.
  --certificate-private-key: string # [Deprecated] Your edge-optimized endpoint's domain name certificate's private key.
  --certificate-chain: string # [Deprecated] The intermediate certificates and optionally the root certificate, one after the other without any blank lines, used by an edge-optimized endpoint for this domain name. If you include the root certificate, your certificate chain must start with intermediate certificates and end with the root certificate. Use the intermediate certificates that were provided by your certificate authority. Do not include any intermediaries that are not in the chain of trust path.
  --certificate-arn: string # The reference to an AWS-managed certificate that will be used by edge-optimized endpoint for this domain name. AWS Certificate Manager is the only supported source.
  --regional-certificate-name: string # The user-friendly name of the certificate that will be used by regional endpoint for this domain name.
  --regional-certificate-arn: string # The reference to an AWS-managed certificate that will be used by regional endpoint for this domain name. AWS Certificate Manager is the only supported source.
  --endpoint-configuration: record # The endpoint configuration to indicate the types of endpoints an API (RestApi) or its custom domain name (DomainName) has. — shape: {types?: list<string>, vpcEndpointIds?: list<string>}
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
  --security-policy: string@security-policy-completer # The Transport Layer Security (TLS) version + cipher suite for this DomainName. The valid values are TLS_1_0 and TLS_1_2.
  --mutual-tls-authentication: record # The mutual TLS authentication configuration for a custom domain name. If specified, API Gateway performs two-way authentication between the client and the server. Clients must present a trusted certificate to access your API. — shape: {truststoreUri?: string, truststoreVersion?: string}
  --ownership-verification-certificate-arn: string # The ARN of the public certificate issued by ACM to validate ownership of your custom domain. Only required when configuring mutual TLS and using an ACM imported or private CA certificate ARN as the regionalCertificateArn.
]: any -> oneof<record<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record<truststoreUri: string, truststoreVersion: string, truststoreWarnings: list<string>>, ownershipVerificationCertificateArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domainnames" $auth.query)
  let req_body = {"domainName": $domain_name, "certificateName": $certificate_name, "certificateBody": $certificate_body, "certificatePrivateKey": $certificate_private_key, "certificateChain": $certificate_chain, "certificateArn": $certificate_arn, "regionalCertificateName": $regional_certificate_name, "regionalCertificateArn": $regional_certificate_arn, "endpointConfiguration": $endpoint_configuration, "tags": $tags, "securityPolicy": $security_policy, "mutualTlsAuthentication": $mutual_tls_authentication, "ownershipVerificationCertificateArn": $ownership_verification_certificate_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Represents a collection of DomainName resources.
#
# GET /domainnames
# operationId: GetDomainNames
export def "get-domain-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record, ownershipVerificationCertificateArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domainnames" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a new Model resource to an existing RestApi resource.
#
# POST /restapis/{restapi_id}/models
# operationId: CreateModel
export def "create-model" [
  restapi_id: string
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
  name: string # The name of the model. Must be alphanumeric.
  --description: string # The description of the model.
  --schema: string # The schema for the model. For application/json models, this should be JSON schema draft 4 model.
  content_type: string # The content-type for the model.
]: any -> oneof<record<id: string, name: string, description: string, schema: string, contentType: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/models") $auth.query)
  let req_body = {"name": $name, "description": $description, "schema": $schema, "contentType": $content_type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Describes existing Models defined for a RestApi resource.
#
# GET /restapis/{restapi_id}/models
# operationId: GetModels
export def "get-models" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<id: string, name: string, description: string, schema: string, contentType: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/models") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a RequestValidator of a given RestApi.
#
# POST /restapis/{restapi_id}/requestvalidators
# operationId: CreateRequestValidator
export def "create-request-validator" [
  restapi_id: string
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
  --name: string # The name of the to-be-created RequestValidator.
  --validate-request-body: oneof<nothing, bool> # A Boolean flag to indicate whether to validate request body according to the configured model schema for the method (true) or not (false).
  --validate-request-parameters: oneof<nothing, bool> # A Boolean flag to indicate whether to validate request parameters, true, or not false.
]: any -> oneof<record<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/requestvalidators") $auth.query)
  let req_body = {"name": $name, "validateRequestBody": $validate_request_body, "validateRequestParameters": $validate_request_parameters} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets the RequestValidators collection of a given RestApi.
#
# GET /restapis/{restapi_id}/requestvalidators
# operationId: GetRequestValidators
export def "get-request-validators" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/requestvalidators") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a Resource resource.
#
# POST /restapis/{restapi_id}/resources/{parent_id}
# operationId: CreateResource
export def "create-resource" [
  restapi_id: string
  parent_id: string
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
  path_part: string # The last path segment for this resource.
]: any -> oneof<record<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($parent_id | is-empty) { error make --unspanned { msg: "path parameter 'parent_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), parent_id: (encode-path-segment $parent_id)} | format pattern "/restapis/{restapi_id}/resources/{parent_id}") $auth.query)
  let req_body = {"pathPart": $path_part} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Creates a new RestApi resource.
#
# POST /restapis
# operationId: CreateRestApi
export def "create-rest-api" [
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
  name: string # The name of the RestApi.
  --description: string # The description of the RestApi.
  --version: string # A version identifier for the API.
  --clone-from: string # The ID of the RestApi that you want to clone from.
  --binary-media-types: list<string> # The list of binary media types supported by the RestApi. By default, the RestApi supports only UTF-8-encoded text payloads.
  --minimum-compression-size: int # A nullable integer that is used to enable compression (with non-negative between 0 and 10485760 (10M) bytes, inclusive) or disable compression (with a null value) on an API. When compression is enabled, compression or decompression is not applied on the payload if the payload size is smaller than this value. Setting it to zero allows compression for any payload size.
  --api-key-source: string@api-key-source-completer # The source of the API key for metering requests according to a usage plan. Valid values are: >HEADER to read the API key from the X-API-Key header of a request. AUTHORIZER to read the API key from the UsageIdentifierKey from a custom authorizer.
  --endpoint-configuration: record # The endpoint configuration to indicate the types of endpoints an API (RestApi) or its custom domain name (DomainName) has. — shape: {types?: list<string>, vpcEndpointIds?: list<string>}
  --policy: string # A stringified JSON policy document that applies to this RestApi regardless of the caller and Method configuration.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
  --disable-execute-api-endpoint: oneof<nothing, bool> # Specifies whether clients can invoke your API by using the default execute-api endpoint. By default, clients can invoke your API with the default https://{api_id}.execute-api.{region}.amazonaws.com endpoint. To require that clients use a custom domain name to invoke your API, disable the default endpoint
]: any -> oneof<record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restapis" $auth.query)
  let req_body = {"name": $name, "description": $description, "version": $version, "cloneFrom": $clone_from, "binaryMediaTypes": $binary_media_types, "minimumCompressionSize": $minimum_compression_size, "apiKeySource": $api_key_source, "endpointConfiguration": $endpoint_configuration, "policy": $policy, "tags": $tags, "disableExecuteApiEndpoint": $disable_execute_api_endpoint} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Lists the RestApis resources for your collection.
#
# GET /restapis
# operationId: GetRestApis
export def "get-rest-apis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<id: string, name: string, description: string, createdDate: string, version: string, warnings: list, binaryMediaTypes: list, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record, policy: string, tags: record, disableExecuteApiEndpoint: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapis" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Stage resource that references a pre-existing Deployment for the API.
#
# POST /restapis/{restapi_id}/stages
# operationId: CreateStage
export def "create-stage" [
  restapi_id: string
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
  stage_name: string # The name for the Stage resource. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  deployment_id: string # The identifier of the Deployment resource for the Stage resource.
  --description: string # The description of the Stage resource.
  --cache-cluster-enabled: oneof<nothing, bool> # Whether cache clustering is enabled for the stage.
  --cache-cluster-size: string@cache-cluster-size-completer # Returns the size of the CacheCluster.
  --variables: record # A map that defines the stage variables for the new Stage resource. Variable names can have alphanumeric and underscore characters, and the values must match [A-Za-z0-9-._~:/?#&=,]+.
  --documentation-version: string # The version of the associated API documentation.
  --canary-settings: record # Configuration settings of a canary deployment. — shape: {percentTraffic?: float, deploymentId?: string, stageVariableOverrides?: record, useStageCache?: bool}
  --tracing-enabled: oneof<nothing, bool> # Specifies whether active tracing with X-ray is enabled for the Stage.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> oneof<record<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record<format: string, destinationArn: string>, canarySettings: record<percentTraffic: float, deploymentId: string, stageVariableOverrides: record, useStageCache: bool>, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/stages") $auth.query)
  let req_body = {"stageName": $stage_name, "deploymentId": $deployment_id, "description": $description, "cacheClusterEnabled": $cache_cluster_enabled, "cacheClusterSize": $cache_cluster_size, "variables": $variables, "documentationVersion": $documentation_version, "canarySettings": $canary_settings, "tracingEnabled": $tracing_enabled, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets information about one or more Stage resources.
#
# GET /restapis/{restapi_id}/stages
# operationId: GetStages
export def "get-stages" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-id: string # The stages' deployment identifiers.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<item: table<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record, canarySettings: record, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "deploymentId" $deployment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/stages") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"deploymentId": $deployment_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload.
#
# POST /usageplans
# operationId: CreateUsagePlan
export def "create-usage-plan" [
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
  name: string # The name of the usage plan.
  --description: string # The description of the usage plan.
  --api-stages: list # The associated API stages of the usage plan. — item shape: {apiId?: string, stage?: string, throttle?: record}
  --throttle: record # The API request rate limits. — shape: {burstLimit?: int, rateLimit?: float}
  --quota: record # Quotas configured for a usage plan. — shape: {limit?: int, offset?: int, period?: "DAY"|"WEEK"|"MONTH"}
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> oneof<record<id: string, name: string, description: string, apiStages: table<apiId: string, stage: string, throttle: record>, throttle: record<burstLimit: int, rateLimit: float>, quota: record<limit: int, offset: int, period: string>, productCode: string, tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usageplans" $auth.query)
  let req_body = {"name": $name, "description": $description, "apiStages": $api_stages, "throttle": $throttle, "quota": $quota, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets all the usage plans of the caller's account.
#
# GET /usageplans
# operationId: GetUsagePlans
export def "get-usage-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --key-id: string # The identifier of the API key associated with the usage plans.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<id: string, name: string, description: string, apiStages: list, throttle: record, quota: record, productCode: string, tags: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "keyId" $key_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usageplans" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "keyId": $key_id, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a usage plan key for adding an existing API key to a usage plan.
#
# POST /usageplans/{usageplanId}/keys
# operationId: CreateUsagePlanKey
export def "create-usage-plan-key" [
  usageplan_id: string
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
  key_id: string # The identifier of a UsagePlanKey resource for a plan customer.
  key_type: string # The type of a UsagePlanKey resource for a plan customer.
]: any -> oneof<record<id: string, type: string, value: string, name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}/keys") $auth.query)
  let req_body = {"keyId": $key_id, "keyType": $key_type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets all the usage plan keys representing the API keys added to a specified usage plan.
#
# GET /usageplans/{usageplanId}/keys
# operationId: GetUsagePlanKeys
export def "get-usage-plan-keys" [
  usageplan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --name: string # A query parameter specifying the name of the to-be-returned usage plan keys.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<id: string, type: string, value: string, name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}/keys") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit, "name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
#
# POST /vpclinks
# operationId: CreateVpcLink
export def "create-vpc-link" [
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
  name: string # The name used to label and identify the VPC link.
  --description: string # The description of the VPC link.
  target_arns: list<string> # The ARN of the network load balancer of the VPC targeted by the VPC link. The network load balancer must be owned by the same AWS account of the API owner.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> oneof<record<id: string, name: string, description: string, targetArns: list<string>, status: string, statusMessage: string, tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vpclinks" $auth.query)
  let req_body = {"name": $name, "description": $description, "targetArns": $target_arns, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets the VpcLinks collection under the caller's account in a selected region.
#
# GET /vpclinks
# operationId: GetVpcLinks
export def "get-vpc-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<id: string, name: string, description: string, targetArns: list, status: string, statusMessage: string, tags: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vpclinks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes the ApiKey resource.
#
# DELETE /apikeys/{api_Key}
# operationId: DeleteApiKey
export def "delete-api-key" [
  api_key: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'api_Key' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/apikeys/{api_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets information about the current ApiKey resource.
#
# GET /apikeys/{api_Key}
# operationId: GetApiKey
export def "get-api-key" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-value: oneof<nothing, bool> # A boolean flag to specify whether (true) or not (false) the result contains the key value.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list<string>, tags: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'api_Key' must be non-empty" } }
  let qp = [(serialize-qp "includeValue" $include_value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/apikeys/{api_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"includeValue": $include_value} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Changes information about an ApiKey resource.
#
# PATCH /apikeys/{api_Key}
# operationId: UpdateApiKey
export def "update-api-key" [
  api_key: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<id: string, value: string, name: string, customerId: string, description: string, enabled: bool, createdDate: string, lastUpdatedDate: string, stageKeys: list<string>, tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_key | is-empty) { error make --unspanned { msg: "path parameter 'api_Key' must be non-empty" } }
  let full_url = (build-url $base ({api_key: (encode-path-segment $api_key)} | format pattern "/apikeys/{api_key}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an existing Authorizer resource.
#
# DELETE /restapis/{restapi_id}/authorizers/{authorizer_id}
# operationId: DeleteAuthorizer
export def "delete-authorizer" [
  restapi_id: string
  authorizer_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($authorizer_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizer_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), authorizer_id: (encode-path-segment $authorizer_id)} | format pattern "/restapis/{restapi_id}/authorizers/{authorizer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Describe an existing Authorizer resource.
#
# GET /restapis/{restapi_id}/authorizers/{authorizer_id}
# operationId: GetAuthorizer
export def "get-authorizer" [
  restapi_id: string
  authorizer_id: string
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
]: nothing -> oneof<record<id: string, name: string, type: string, providerARNs: list<string>, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($authorizer_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizer_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), authorizer_id: (encode-path-segment $authorizer_id)} | format pattern "/restapis/{restapi_id}/authorizers/{authorizer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Simulate the execution of an Authorizer in your RestApi with headers, parameters, and an incoming request body.
#
# POST /restapis/{restapi_id}/authorizers/{authorizer_id}
# operationId: TestInvokeAuthorizer
export def "test-invoke-authorizer" [
  restapi_id: string
  authorizer_id: string
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
  --headers: record # A key-value map of headers to simulate an incoming invocation request. This is where the incoming authorization token, or identity source, should be specified.
  --multi-value-headers: record # The headers as a map from string to list of values to simulate an incoming invocation request. This is where the incoming authorization token, or identity source, may be specified.
  --path-with-query-string: string # The URI path, including query string, of the simulated invocation request. Use this to specify path parameters and query string parameters.
  --body: string # The simulated request body of an incoming invocation request.
  --stage-variables: record # A key-value map of stage variables to simulate an invocation on a deployed Stage.
  --additional-context: record # A key-value map of additional context variables.
]: any -> oneof<record<clientStatus: int, log: string, latency: int, principalId: string, policy: string, authorization: record, claims: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($authorizer_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizer_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), authorizer_id: (encode-path-segment $authorizer_id)} | format pattern "/restapis/{restapi_id}/authorizers/{authorizer_id}") $auth.query)
  let req_body = {"headers": $headers, "multiValueHeaders": $multi_value_headers, "pathWithQueryString": $path_with_query_string, "body": $body, "stageVariables": $stage_variables, "additionalContext": $additional_context} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Updates an existing Authorizer resource.
#
# PATCH /restapis/{restapi_id}/authorizers/{authorizer_id}
# operationId: UpdateAuthorizer
export def "update-authorizer" [
  restapi_id: string
  authorizer_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<id: string, name: string, type: string, providerARNs: list<string>, authType: string, authorizerUri: string, authorizerCredentials: string, identitySource: string, identityValidationExpression: string, authorizerResultTtlInSeconds: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($authorizer_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizer_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), authorizer_id: (encode-path-segment $authorizer_id)} | format pattern "/restapis/{restapi_id}/authorizers/{authorizer_id}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the BasePathMapping resource.
#
# DELETE /domainnames/{domain_name}/basepathmappings/{base_path}
# operationId: DeleteBasePathMapping
export def "delete-base-path-mapping" [
  domain_name: string
  base_path: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  if ($base_path | is-empty) { error make --unspanned { msg: "path parameter 'base_path' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), base_path: (encode-path-segment $base_path)} | format pattern "/domainnames/{domain_name}/basepathmappings/{base_path}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Describe a BasePathMapping resource.
#
# GET /domainnames/{domain_name}/basepathmappings/{base_path}
# operationId: GetBasePathMapping
export def "get-base-path-mapping" [
  domain_name: string
  base_path: string
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
]: nothing -> oneof<record<basePath: string, restApiId: string, stage: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  if ($base_path | is-empty) { error make --unspanned { msg: "path parameter 'base_path' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), base_path: (encode-path-segment $base_path)} | format pattern "/domainnames/{domain_name}/basepathmappings/{base_path}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Changes information about the BasePathMapping resource.
#
# PATCH /domainnames/{domain_name}/basepathmappings/{base_path}
# operationId: UpdateBasePathMapping
export def "update-base-path-mapping" [
  domain_name: string
  base_path: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<basePath: string, restApiId: string, stage: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  if ($base_path | is-empty) { error make --unspanned { msg: "path parameter 'base_path' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), base_path: (encode-path-segment $base_path)} | format pattern "/domainnames/{domain_name}/basepathmappings/{base_path}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the ClientCertificate resource.
#
# DELETE /clientcertificates/{clientcertificate_id}
# operationId: DeleteClientCertificate
export def "delete-client-certificate" [
  clientcertificate_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($clientcertificate_id | is-empty) { error make --unspanned { msg: "path parameter 'clientcertificate_id' must be non-empty" } }
  let full_url = (build-url $base ({clientcertificate_id: (encode-path-segment $clientcertificate_id)} | format pattern "/clientcertificates/{clientcertificate_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets information about the current ClientCertificate resource.
#
# GET /clientcertificates/{clientcertificate_id}
# operationId: GetClientCertificate
export def "get-client-certificate" [
  clientcertificate_id: string
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
]: nothing -> oneof<record<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($clientcertificate_id | is-empty) { error make --unspanned { msg: "path parameter 'clientcertificate_id' must be non-empty" } }
  let full_url = (build-url $base ({clientcertificate_id: (encode-path-segment $clientcertificate_id)} | format pattern "/clientcertificates/{clientcertificate_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Changes information about an ClientCertificate resource.
#
# PATCH /clientcertificates/{clientcertificate_id}
# operationId: UpdateClientCertificate
export def "update-client-certificate" [
  clientcertificate_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($clientcertificate_id | is-empty) { error make --unspanned { msg: "path parameter 'clientcertificate_id' must be non-empty" } }
  let full_url = (build-url $base ({clientcertificate_id: (encode-path-segment $clientcertificate_id)} | format pattern "/clientcertificates/{clientcertificate_id}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a Deployment resource. Deleting a deployment will only succeed if there are no Stage resources associated with it.
#
# DELETE /restapis/{restapi_id}/deployments/{deployment_id}
# operationId: DeleteDeployment
export def "delete-deployment" [
  restapi_id: string
  deployment_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deployment_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/restapis/{restapi_id}/deployments/{deployment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets information about a Deployment resource.
#
# GET /restapis/{restapi_id}/deployments/{deployment_id}
# operationId: GetDeployment
export def "get-deployment" [
  restapi_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: list # A query parameter to retrieve the specified embedded resources of the returned Deployment resource in the response. In a REST API call, this embed parameter value is a list of comma-separated strings, as in GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the "apisummary" string. For example, GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<id: string, description: string, createdDate: string, apiSummary: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deployment_id' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/restapis/{restapi_id}/deployments/{deployment_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Changes information about a Deployment resource.
#
# PATCH /restapis/{restapi_id}/deployments/{deployment_id}
# operationId: UpdateDeployment
export def "update-deployment" [
  restapi_id: string
  deployment_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<id: string, description: string, createdDate: string, apiSummary: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deployment_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/restapis/{restapi_id}/deployments/{deployment_id}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a documentation part
#
# DELETE /restapis/{restapi_id}/documentation/parts/{part_id}
# operationId: DeleteDocumentationPart
export def "delete-documentation-part" [
  restapi_id: string
  part_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($part_id | is-empty) { error make --unspanned { msg: "path parameter 'part_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), part_id: (encode-path-segment $part_id)} | format pattern "/restapis/{restapi_id}/documentation/parts/{part_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets a documentation part.
#
# GET /restapis/{restapi_id}/documentation/parts/{part_id}
# operationId: GetDocumentationPart
export def "get-documentation-part" [
  restapi_id: string
  part_id: string
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
]: nothing -> oneof<record<id: string, location: record<type: string, path: string, method: string, statusCode: string, name: string>, properties: any>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($part_id | is-empty) { error make --unspanned { msg: "path parameter 'part_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), part_id: (encode-path-segment $part_id)} | format pattern "/restapis/{restapi_id}/documentation/parts/{part_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a documentation part.
#
# PATCH /restapis/{restapi_id}/documentation/parts/{part_id}
# operationId: UpdateDocumentationPart
export def "update-documentation-part" [
  restapi_id: string
  part_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<id: string, location: record<type: string, path: string, method: string, statusCode: string, name: string>, properties: any>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($part_id | is-empty) { error make --unspanned { msg: "path parameter 'part_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), part_id: (encode-path-segment $part_id)} | format pattern "/restapis/{restapi_id}/documentation/parts/{part_id}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a documentation version.
#
# DELETE /restapis/{restapi_id}/documentation/versions/{doc_version}
# operationId: DeleteDocumentationVersion
export def "delete-documentation-version" [
  restapi_id: string
  doc_version: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($doc_version | is-empty) { error make --unspanned { msg: "path parameter 'doc_version' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), doc_version: (encode-path-segment $doc_version)} | format pattern "/restapis/{restapi_id}/documentation/versions/{doc_version}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets a documentation version.
#
# GET /restapis/{restapi_id}/documentation/versions/{doc_version}
# operationId: GetDocumentationVersion
export def "get-documentation-version" [
  restapi_id: string
  doc_version: string
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
]: nothing -> oneof<record<version: string, createdDate: string, description: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($doc_version | is-empty) { error make --unspanned { msg: "path parameter 'doc_version' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), doc_version: (encode-path-segment $doc_version)} | format pattern "/restapis/{restapi_id}/documentation/versions/{doc_version}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a documentation version.
#
# PATCH /restapis/{restapi_id}/documentation/versions/{doc_version}
# operationId: UpdateDocumentationVersion
export def "update-documentation-version" [
  restapi_id: string
  doc_version: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<version: string, createdDate: string, description: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($doc_version | is-empty) { error make --unspanned { msg: "path parameter 'doc_version' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), doc_version: (encode-path-segment $doc_version)} | format pattern "/restapis/{restapi_id}/documentation/versions/{doc_version}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the DomainName resource.
#
# DELETE /domainnames/{domain_name}
# operationId: DeleteDomainName
export def "delete-domain-name" [
  domain_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domainnames/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
#
# GET /domainnames/{domain_name}
# operationId: GetDomainName
export def "get-domain-name" [
  domain_name: string
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
]: nothing -> oneof<record<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record<truststoreUri: string, truststoreVersion: string, truststoreWarnings: list<string>>, ownershipVerificationCertificateArn: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domainnames/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Changes information about the DomainName resource.
#
# PATCH /domainnames/{domain_name}
# operationId: UpdateDomainName
export def "update-domain-name" [
  domain_name: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<domainName: string, certificateName: string, certificateArn: string, certificateUploadDate: string, regionalDomainName: string, regionalHostedZoneId: string, regionalCertificateName: string, regionalCertificateArn: string, distributionDomainName: string, distributionHostedZoneId: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, domainNameStatus: string, domainNameStatusMessage: string, securityPolicy: string, tags: record, mutualTlsAuthentication: record<truststoreUri: string, truststoreVersion: string, truststoreWarnings: list<string>>, ownershipVerificationCertificateArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domainnames/{domain_name}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Clears any customization of a GatewayResponse of a specified response type on the given RestApi and resets it with the default settings.
#
# DELETE /restapis/{restapi_id}/gatewayresponses/{response_type}
# operationId: DeleteGatewayResponse
export def "delete-gateway-response" [
  restapi_id: string
  response_type: string@response-type-completer
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($response_type | is-empty) { error make --unspanned { msg: "path parameter 'response_type' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), response_type: (encode-path-segment $response_type)} | format pattern "/restapis/{restapi_id}/gatewayresponses/{response_type}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets a GatewayResponse of a specified response type on the given RestApi.
#
# GET /restapis/{restapi_id}/gatewayresponses/{response_type}
# operationId: GetGatewayResponse
export def "get-gateway-response" [
  restapi_id: string
  response_type: string@response-type-completer
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
]: nothing -> oneof<record<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($response_type | is-empty) { error make --unspanned { msg: "path parameter 'response_type' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), response_type: (encode-path-segment $response_type)} | format pattern "/restapis/{restapi_id}/gatewayresponses/{response_type}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a customization of a GatewayResponse of a specified response type and status code on the given RestApi.
#
# PUT /restapis/{restapi_id}/gatewayresponses/{response_type}
# operationId: PutGatewayResponse
export def "put-gateway-response" [
  restapi_id: string
  response_type: string@response-type-completer
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
  --status-code: string # The status code.
  --response-parameters: record # Response parameters (paths, query strings and headers) of the GatewayResponse as a string-to-string map of key-value pairs.
  --response-templates: record # Response templates of the GatewayResponse as a string-to-string map of key-value pairs.
]: any -> oneof<record<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($response_type | is-empty) { error make --unspanned { msg: "path parameter 'response_type' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), response_type: (encode-path-segment $response_type)} | format pattern "/restapis/{restapi_id}/gatewayresponses/{response_type}") $auth.query)
  let req_body = {"statusCode": $status_code, "responseParameters": $response_parameters, "responseTemplates": $response_templates} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Updates a GatewayResponse of a specified response type on the given RestApi.
#
# PATCH /restapis/{restapi_id}/gatewayresponses/{response_type}
# operationId: UpdateGatewayResponse
export def "update-gateway-response" [
  restapi_id: string
  response_type: string@response-type-completer
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($response_type | is-empty) { error make --unspanned { msg: "path parameter 'response_type' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), response_type: (encode-path-segment $response_type)} | format pattern "/restapis/{restapi_id}/gatewayresponses/{response_type}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Represents a delete integration.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# operationId: DeleteIntegration
export def "delete-integration" [
  restapi_id: string
  resource_id: string
  http_method: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get the integration settings.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# operationId: GetIntegration
export def "get-integration" [
  restapi_id: string
  resource_id: string
  http_method: string
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
]: nothing -> oneof<record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Sets up a method's integration.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# operationId: PutIntegration
export def "put-integration" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  type: string@type-completer-2 # The integration type. The valid value is HTTP for integrating an API method with an HTTP backend; AWS with any AWS service endpoints; MOCK for testing without actually invoking the backend; HTTP_PROXY for integrating with the HTTP proxy integration; AWS_PROXY for integrating with the Lambda proxy integration.
  --body-http-method: string # The HTTP method for the integration. (spec name: httpMethod)
  --uri: string # Specifies Uniform Resource Identifier (URI) of the integration endpoint. For HTTP or HTTP_PROXY integrations, the URI must be a fully formed, encoded HTTP(S) URL according to the RFC-3986 specification, for either standard integration, where connectionType is not VPC_LINK, or private integration, where connectionType is VPC_LINK. For a private HTTP integration, the URI is not used for routing. For AWS or AWS_PROXY integrations, the URI is of the form arn:aws:apigateway:{region}:{subdomain.service|service}:path|action/{service_api}. Here, {Region} is the API Gateway region (e.g., us-east-1); {service} is the name of the integrated Amazon Web Services service (e.g., s3); and {subdomain} is a designated subdomain supported by certain Amazon Web Services service for fast host-name lookup. action can be used for an Amazon Web Services service action-based API, using an Action={name}&{p1}={v1}&p2={v2}... query string. The ensuing {service_api} refers to a supported action {name} plus any required input parameters. Alternatively, path can be used for an Amazon Web Services service path-based API. The ensuing service_api refers to the path to an Amazon Web Services service resource, including the region of the integrated Amazon Web Services service, if applicable. For example, for integration with the S3 API of GetObject, the uri can be either arn:aws:apigateway:us-west-2:s3:action/GetObject&Bucket={bucket}&Key={key} or arn:aws:apigateway:us-west-2:s3:path/{bucket}/{key}.
  --connection-type: string@connection-type-completer # The type of the network connection to the integration endpoint. The valid value is INTERNET for connections through the public routable internet or VPC_LINK for private connections between API Gateway and a network load balancer in a VPC. The default value is INTERNET.
  --connection-id: string # The ID of the VpcLink used for the integration. Specify this value only if you specify VPC_LINK as the connection type.
  --credentials: string # Specifies whether credentials are required for a put integration.
  --request-parameters: record # A key-value map specifying request parameters that are passed from the method request to the back end. The key is an integration request parameter name and the associated value is a method request parameter value or static value that must be enclosed within single quotes and pre-encoded as required by the back end. The method request parameter value must match the pattern of method.request.{location}.{name}, where location is querystring, path, or header and name must be a valid and unique method request parameter name.
  --request-templates: record # Represents a map of Velocity templates that are applied on the request payload based on the value of the Content-Type header sent by the client. The content type value is the key in this map, and the template (as a String) is the value.
  --passthrough-behavior: string # Specifies the pass-through behavior for incoming requests based on the Content-Type header in the request, and the available mapping templates specified as the requestTemplates property on the Integration resource. There are three valid values: WHEN_NO_MATCH, WHEN_NO_TEMPLATES, and NEVER.
  --cache-namespace: string # Specifies a group of related cached parameters. By default, API Gateway uses the resource ID as the cacheNamespace. You can specify the same cacheNamespace across resources to return the same cached data for requests to different resources.
  --cache-key-parameters: list<string> # A list of request parameters whose values API Gateway caches. To be valid values for cacheKeyParameters, these parameters must also be specified for Method requestParameters.
  --content-handling: string@content-handling-completer # Specifies how to handle request payload content type conversions. Supported values are CONVERT_TO_BINARY and CONVERT_TO_TEXT, with the following behaviors: If this property is not defined, the request payload will be passed through from the method request to integration request without modification, provided that the passthroughBehavior is configured to support payload pass-through.
  --timeout-in-millis: int # Custom timeout between 50 and 29,000 milliseconds. The default value is 29,000 milliseconds or 29 seconds.
  --tls-config: record # Specifies the TLS configuration for an integration. — shape: {insecureSkipVerification?: bool}
]: any -> oneof<record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration") $auth.query)
  let req_body = {"type": $type, "httpMethod": $body_http_method, "uri": $uri, "connectionType": $connection_type, "connectionId": $connection_id, "credentials": $credentials, "requestParameters": $request_parameters, "requestTemplates": $request_templates, "passthroughBehavior": $passthrough_behavior, "cacheNamespace": $cache_namespace, "cacheKeyParameters": $cache_key_parameters, "contentHandling": $content_handling, "timeoutInMillis": $timeout_in_millis, "tlsConfig": $tls_config} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Represents an update integration.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration
# operationId: UpdateIntegration
export def "update-integration" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Represents a delete integration response.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# operationId: DeleteIntegrationResponse
export def "delete-integration-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Represents a get integration response.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# operationId: GetIntegrationResponse
export def "get-integration-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
]: nothing -> oneof<record<statusCode: string, selectionPattern: string, responseParameters: record, responseTemplates: record, contentHandling: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Represents a put integration.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# operationId: PutIntegrationResponse
export def "put-integration-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --selection-pattern: string # Specifies the selection pattern of a put integration response.
  --response-parameters: record # A key-value map specifying response parameters that are passed to the method response from the back end. The key is a method response header parameter name and the mapped value is an integration response header value, a static value enclosed within a pair of single quotes, or a JSON expression from the integration response body. The mapping key must match the pattern of method.response.header.{name}, where name is a valid and unique header name. The mapped non-static value must match the pattern of integration.response.header.{name} or integration.response.body.{JSON-expression}, where name must be a valid and unique response header name and JSON-expression a valid JSON expression without the $ prefix.
  --response-templates: record # Specifies a put integration response's templates.
  --content-handling: string@content-handling-completer # Specifies how to handle response payload content type conversions. Supported values are CONVERT_TO_BINARY and CONVERT_TO_TEXT, with the following behaviors: If this property is not defined, the response payload will be passed through from the integration response to the method response without modification.
]: any -> oneof<record<statusCode: string, selectionPattern: string, responseParameters: record, responseTemplates: record, contentHandling: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}") $auth.query)
  let req_body = {"selectionPattern": $selection_pattern, "responseParameters": $response_parameters, "responseTemplates": $response_templates, "contentHandling": $content_handling} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Represents an update integration response.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}
# operationId: UpdateIntegrationResponse
export def "update-integration-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<statusCode: string, selectionPattern: string, responseParameters: record, responseTemplates: record, contentHandling: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an existing Method resource.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# operationId: DeleteMethod
export def "delete-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Describe an existing Method resource.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# operationId: GetMethod
export def "get-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
]: nothing -> oneof<record<httpMethod: string, authorizationType: string, authorizerId: string, apiKeyRequired: bool, requestValidatorId: string, operationName: string, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, authorizationScopes: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a method to an existing Resource resource.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# operationId: PutMethod
export def "put-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  authorization_type: string # The method's authorization type. Valid values are NONE for open access, AWS_IAM for using AWS IAM permissions, CUSTOM for using a custom authorizer, or COGNITO_USER_POOLS for using a Cognito user pool.
  --authorizer-id: string # Specifies the identifier of an Authorizer to use on this Method, if the type is CUSTOM or COGNITO_USER_POOLS. The authorizer identifier is generated by API Gateway when you created the authorizer.
  --api-key-required: oneof<nothing, bool> # Specifies whether the method required a valid ApiKey.
  --operation-name: string # A human-friendly operation identifier for the method. For example, you can assign the operationName of ListPets for the GET /pets method in the PetStore example.
  --request-parameters: record # A key-value map defining required or optional method request parameters that can be accepted by API Gateway. A key defines a method request parameter name matching the pattern of method.request.{location}.{name}, where location is querystring, path, or header and name is a valid and unique parameter name. The value associated with the key is a Boolean flag indicating whether the parameter is required (true) or optional (false). The method request parameter names defined here are available in Integration to be mapped to integration request parameters or body-mapping templates.
  --request-models: record # Specifies the Model resources used for the request's content type. Request models are represented as a key/value map, with a content type as the key and a Model name as the value.
  --request-validator-id: string # The identifier of a RequestValidator for validating the method request.
  --authorization-scopes: list<string> # A list of authorization scopes configured on the method. The scopes are used with a COGNITO_USER_POOLS authorizer to authorize the method invocation. The authorization works by matching the method scopes against the scopes parsed from the access token in the incoming request. The method invocation is authorized if any method scopes matches a claimed scope in the access token. Otherwise, the invocation is not authorized. When the method scope is configured, the client must provide an access token instead of an identity token for authorization purposes.
]: any -> oneof<record<httpMethod: string, authorizationType: string, authorizerId: string, apiKeyRequired: bool, requestValidatorId: string, operationName: string, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, authorizationScopes: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}") $auth.query)
  let req_body = {"authorizationType": $authorization_type, "authorizerId": $authorizer_id, "apiKeyRequired": $api_key_required, "operationName": $operation_name, "requestParameters": $request_parameters, "requestModels": $request_models, "requestValidatorId": $request_validator_id, "authorizationScopes": $authorization_scopes} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Simulate the invocation of a Method in your RestApi with headers, parameters, and an incoming request body.
#
# POST /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# operationId: TestInvokeMethod
export def "test-invoke-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  --path-with-query-string: string # The URI path, including query string, of the simulated invocation request. Use this to specify path parameters and query string parameters.
  --body: string # The simulated request body of an incoming invocation request.
  --headers: record # A key-value map of headers to simulate an incoming invocation request.
  --multi-value-headers: record # The headers as a map from string to list of values to simulate an incoming invocation request.
  --client-certificate-id: string # A ClientCertificate identifier to use in the test invocation. API Gateway will use the certificate when making the HTTPS request to the defined back-end endpoint.
  --stage-variables: record # A key-value map of stage variables to simulate an invocation on a deployed Stage.
]: any -> oneof<record<status: int, body: string, headers: record, multiValueHeaders: record, log: string, latency: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}") $auth.query)
  let req_body = {"pathWithQueryString": $path_with_query_string, "body": $body, "headers": $headers, "multiValueHeaders": $multi_value_headers, "clientCertificateId": $client_certificate_id, "stageVariables": $stage_variables} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Updates an existing Method resource.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}
# operationId: UpdateMethod
export def "update-method" [
  restapi_id: string
  resource_id: string
  http_method: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<httpMethod: string, authorizationType: string, authorizerId: string, apiKeyRequired: bool, requestValidatorId: string, operationName: string, requestParameters: record, requestModels: record, methodResponses: record, methodIntegration: record<type: string, httpMethod: string, uri: string, connectionType: string, connectionId: string, credentials: string, requestParameters: record, requestTemplates: record, passthroughBehavior: string, contentHandling: string, timeoutInMillis: int, cacheNamespace: string, cacheKeyParameters: list<string>, integrationResponses: record, tlsConfig: record<insecureSkipVerification: bool>>, authorizationScopes: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an existing MethodResponse resource.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# operationId: DeleteMethodResponse
export def "delete-method-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Describes a MethodResponse resource.
#
# GET /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# operationId: GetMethodResponse
export def "get-method-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
]: nothing -> oneof<record<statusCode: string, responseParameters: record, responseModels: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a MethodResponse to an existing Method resource.
#
# PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# operationId: PutMethodResponse
export def "put-method-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --response-parameters: record # A key-value map specifying required or optional response parameters that API Gateway can send back to the caller. A key defines a method response header name and the associated value is a Boolean flag indicating whether the method response parameter is required or not. The method response header names must match the pattern of method.response.header.{name}, where name is a valid and unique header name. The response parameter names defined here are available in the integration response to be mapped from an integration response header expressed in integration.response.header.{name}, a static value enclosed within a pair of single quotes (e.g., 'application/json'), or a JSON expression from the back-end response payload in the form of integration.response.body.{JSON-expression}, where JSON-expression is a valid JSON expression without the $ prefix.)
  --response-models: record # Specifies the Model resources used for the response's content type. Response models are represented as a key/value map, with a content type as the key and a Model name as the value.
]: any -> oneof<record<statusCode: string, responseParameters: record, responseModels: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}") $auth.query)
  let req_body = {"responseParameters": $response_parameters, "responseModels": $response_models} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Updates an existing MethodResponse resource.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}
# operationId: UpdateMethodResponse
export def "update-method-response" [
  restapi_id: string
  resource_id: string
  http_method: string
  status_code: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<statusCode: string, responseParameters: record, responseModels: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  if ($http_method | is-empty) { error make --unspanned { msg: "path parameter 'http_method' must be non-empty" } }
  if ($status_code | is-empty) { error make --unspanned { msg: "path parameter 'status_code' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id), http_method: (encode-path-segment $http_method), status_code: (encode-path-segment $status_code)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# Deletes a model.
#
# DELETE /restapis/{restapi_id}/models/{model_name}
# operationId: DeleteModel
export def "delete-model" [
  restapi_id: string
  model_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($model_name | is-empty) { error make --unspanned { msg: "path parameter 'model_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), model_name: (encode-path-segment $model_name)} | format pattern "/restapis/{restapi_id}/models/{model_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Describes an existing model defined for a RestApi resource.
#
# GET /restapis/{restapi_id}/models/{model_name}
# operationId: GetModel
export def "get-model" [
  restapi_id: string
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flatten: oneof<nothing, bool> # A query parameter of a Boolean value to resolve (true) all external model references and returns a flattened model schema or not (false) The default is false.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<id: string, name: string, description: string, schema: string, contentType: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($model_name | is-empty) { error make --unspanned { msg: "path parameter 'model_name' must be non-empty" } }
  let qp = [(serialize-qp "flatten" $flatten "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), model_name: (encode-path-segment $model_name)} | format pattern "/restapis/{restapi_id}/models/{model_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"flatten": $flatten} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Changes information about a model.
#
# PATCH /restapis/{restapi_id}/models/{model_name}
# operationId: UpdateModel
export def "update-model" [
  restapi_id: string
  model_name: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<id: string, name: string, description: string, schema: string, contentType: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($model_name | is-empty) { error make --unspanned { msg: "path parameter 'model_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), model_name: (encode-path-segment $model_name)} | format pattern "/restapis/{restapi_id}/models/{model_name}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a RequestValidator of a given RestApi.
#
# DELETE /restapis/{restapi_id}/requestvalidators/{requestvalidator_id}
# operationId: DeleteRequestValidator
export def "delete-request-validator" [
  restapi_id: string
  requestvalidator_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($requestvalidator_id | is-empty) { error make --unspanned { msg: "path parameter 'requestvalidator_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), requestvalidator_id: (encode-path-segment $requestvalidator_id)} | format pattern "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets a RequestValidator of a given RestApi.
#
# GET /restapis/{restapi_id}/requestvalidators/{requestvalidator_id}
# operationId: GetRequestValidator
export def "get-request-validator" [
  restapi_id: string
  requestvalidator_id: string
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
]: nothing -> oneof<record<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($requestvalidator_id | is-empty) { error make --unspanned { msg: "path parameter 'requestvalidator_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), requestvalidator_id: (encode-path-segment $requestvalidator_id)} | format pattern "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a RequestValidator of a given RestApi.
#
# PATCH /restapis/{restapi_id}/requestvalidators/{requestvalidator_id}
# operationId: UpdateRequestValidator
export def "update-request-validator" [
  restapi_id: string
  requestvalidator_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<id: string, name: string, validateRequestBody: bool, validateRequestParameters: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($requestvalidator_id | is-empty) { error make --unspanned { msg: "path parameter 'requestvalidator_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), requestvalidator_id: (encode-path-segment $requestvalidator_id)} | format pattern "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a Resource resource.
#
# DELETE /restapis/{restapi_id}/resources/{resource_id}
# operationId: DeleteResource
export def "delete-resource" [
  restapi_id: string
  resource_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Lists information about a resource.
#
# GET /restapis/{restapi_id}/resources/{resource_id}
# operationId: GetResource
export def "get-resource" [
  restapi_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: list # A query parameter to retrieve the specified resources embedded in the returned Resource representation in the response. This embed parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded Method resources this way. The query parameter value must be a single-valued list and contain the "methods" string. For example, GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Changes information about a Resource resource.
#
# PATCH /restapis/{restapi_id}/resources/{resource_id}
# operationId: UpdateResource
export def "update-resource" [
  restapi_id: string
  resource_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resource_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), resource_id: (encode-path-segment $resource_id)} | format pattern "/restapis/{restapi_id}/resources/{resource_id}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the specified API.
#
# DELETE /restapis/{restapi_id}
# operationId: DeleteRestApi
export def "delete-rest-api" [
  restapi_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Lists the RestApi resource in the collection.
#
# GET /restapis/{restapi_id}
# operationId: GetRestApi
export def "get-rest-api" [
  restapi_id: string
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
]: nothing -> oneof<record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
#
# PUT /restapis/{restapi_id}
# operationId: PutRestApi
export def "put-rest-api" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer # The mode query parameter to specify the update mode. Valid values are "merge" and "overwrite". By default, the update mode is "merge".
  --failonwarnings: oneof<nothing, bool> # A query parameter to indicate whether to rollback the API update (true) or not (false) when a warning is encountered. The default value is false.
  --parameters: record # Custom header parameters as part of the request. For example, to exclude DocumentationParts from an imported API, set ignore=documentation as a parameters value, as in the AWS CLI command of aws apigateway import-rest-api --parameters ignore=documentation --body 'file:///path/to/imported-api-body.json'.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The PUT request body containing external API definitions. Currently, only OpenAPI definition JSON/YAML files are supported. The maximum size of the API definition file is 6MB.
]: any -> oneof<record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "mode" $mode "scalar") (serialize-qp "failonwarnings" $failonwarnings "scalar") (serialize-qp "parameters" $parameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}") $qp $auth.query)
  let req_body = {"body": $body} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"mode": $mode, "failonwarnings": $failonwarnings, "parameters": $parameters} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Changes information about the specified API.
#
# PATCH /restapis/{restapi_id}
# operationId: UpdateRestApi
export def "update-rest-api" [
  restapi_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a Stage resource.
#
# DELETE /restapis/{restapi_id}/stages/{stage_name}
# operationId: DeleteStage
export def "delete-stage" [
  restapi_id: string
  stage_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets information about a Stage resource.
#
# GET /restapis/{restapi_id}/stages/{stage_name}
# operationId: GetStage
export def "get-stage" [
  restapi_id: string
  stage_name: string
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
]: nothing -> oneof<record<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record<format: string, destinationArn: string>, canarySettings: record<percentTraffic: float, deploymentId: string, stageVariableOverrides: record, useStageCache: bool>, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Changes information about a Stage resource.
#
# PATCH /restapis/{restapi_id}/stages/{stage_name}
# operationId: UpdateStage
export def "update-stage" [
  restapi_id: string
  stage_name: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<deploymentId: string, clientCertificateId: string, stageName: string, description: string, cacheClusterEnabled: bool, cacheClusterSize: string, cacheClusterStatus: string, methodSettings: record, variables: record, documentationVersion: string, accessLogSettings: record<format: string, destinationArn: string>, canarySettings: record<percentTraffic: float, deploymentId: string, stageVariableOverrides: record, useStageCache: bool>, tracingEnabled: bool, webAclArn: string, tags: record, createdDate: string, lastUpdatedDate: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a usage plan of a given plan Id.
#
# DELETE /usageplans/{usageplanId}
# operationId: DeleteUsagePlan
export def "delete-usage-plan" [
  usageplan_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets a usage plan of a given plan identifier.
#
# GET /usageplans/{usageplanId}
# operationId: GetUsagePlan
export def "get-usage-plan" [
  usageplan_id: string
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
]: nothing -> oneof<record<id: string, name: string, description: string, apiStages: table<apiId: string, stage: string, throttle: record>, throttle: record<burstLimit: int, rateLimit: float>, quota: record<limit: int, offset: int, period: string>, productCode: string, tags: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a usage plan of a given plan Id.
#
# PATCH /usageplans/{usageplanId}
# operationId: UpdateUsagePlan
export def "update-usage-plan" [
  usageplan_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<id: string, name: string, description: string, apiStages: table<apiId: string, stage: string, throttle: record>, throttle: record<burstLimit: int, rateLimit: float>, quota: record<limit: int, offset: int, period: string>, productCode: string, tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a usage plan key and remove the underlying API key from the associated usage plan.
#
# DELETE /usageplans/{usageplanId}/keys/{keyId}
# operationId: DeleteUsagePlanKey
export def "delete-usage-plan-key" [
  usageplan_id: string
  key_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'keyId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id), key_id: (encode-path-segment $key_id)} | format pattern "/usageplans/{usageplan_id}/keys/{key_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets a usage plan key of a given key identifier.
#
# GET /usageplans/{usageplanId}/keys/{keyId}
# operationId: GetUsagePlanKey
export def "get-usage-plan-key" [
  usageplan_id: string
  key_id: string
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
]: nothing -> oneof<record<id: string, type: string, value: string, name: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'keyId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id), key_id: (encode-path-segment $key_id)} | format pattern "/usageplans/{usageplan_id}/keys/{key_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an existing VpcLink of a specified identifier.
#
# DELETE /vpclinks/{vpclink_id}
# operationId: DeleteVpcLink
export def "delete-vpc-link" [
  vpclink_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpclink_id | is-empty) { error make --unspanned { msg: "path parameter 'vpclink_id' must be non-empty" } }
  let full_url = (build-url $base ({vpclink_id: (encode-path-segment $vpclink_id)} | format pattern "/vpclinks/{vpclink_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets a specified VPC link under the caller's account in a region.
#
# GET /vpclinks/{vpclink_id}
# operationId: GetVpcLink
export def "get-vpc-link" [
  vpclink_id: string
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
]: nothing -> oneof<record<id: string, name: string, description: string, targetArns: list<string>, status: string, statusMessage: string, tags: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpclink_id | is-empty) { error make --unspanned { msg: "path parameter 'vpclink_id' must be non-empty" } }
  let full_url = (build-url $base ({vpclink_id: (encode-path-segment $vpclink_id)} | format pattern "/vpclinks/{vpclink_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing VpcLink of a specified identifier.
#
# PATCH /vpclinks/{vpclink_id}
# operationId: UpdateVpcLink
export def "update-vpc-link" [
  vpclink_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<id: string, name: string, description: string, targetArns: list<string>, status: string, statusMessage: string, tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpclink_id | is-empty) { error make --unspanned { msg: "path parameter 'vpclink_id' must be non-empty" } }
  let full_url = (build-url $base ({vpclink_id: (encode-path-segment $vpclink_id)} | format pattern "/vpclinks/{vpclink_id}") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Flushes all authorizer cache entries on a stage.
#
# DELETE /restapis/{restapi_id}/stages/{stage_name}/cache/authorizers
# operationId: FlushStageAuthorizersCache
export def "flush-stage-authorizers-cache" [
  restapi_id: string
  stage_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Flushes a stage's cache.
#
# DELETE /restapis/{restapi_id}/stages/{stage_name}/cache/data
# operationId: FlushStageCache
export def "flush-stage-cache" [
  restapi_id: string
  stage_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}/cache/data") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Generates a ClientCertificate resource.
#
# POST /clientcertificates
# operationId: GenerateClientCertificate
export def "generate-client-certificate" [
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
  --description: string # The description of the ClientCertificate.
  --tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> oneof<record<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clientcertificates" $auth.query)
  let req_body = {"description": $description, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets a collection of ClientCertificate resources.
#
# GET /clientcertificates
# operationId: GetClientCertificates
export def "get-client-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<clientCertificateId: string, description: string, pemEncodedCertificate: string, createdDate: string, expirationDate: string, tags: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clientcertificates" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets information about the current Account resource.
#
# GET /account
# operationId: GetAccount
export def "get-account" [
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
]: nothing -> oneof<record<cloudwatchRoleArn: string, throttleSettings: record<burstLimit: int, rateLimit: float>, features: list<string>, apiKeyVersion: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Changes information about the current Account resource.
#
# PATCH /account
# operationId: UpdateAccount
export def "update-account" [
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<cloudwatchRoleArn: string, throttleSettings: record<burstLimit: int, rateLimit: float>, features: list<string>, apiKeyVersion: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account" $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Exports a deployed version of a RestApi in a specified format.
#
# GET /restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}
# operationId: GetExport
export def "get-export" [
  restapi_id: string
  stage_name: string
  export_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameters: record # A key-value map of query string parameters that specify properties of the export, depending on the requested exportType. For exportType oas30 and swagger, any combination of the following parameters are supported: extensions='integrations' or extensions='apigateway' will export the API with x-amazon-apigateway-integration extensions. extensions='authorizers' will export the API with x-amazon-apigateway-authorizer extensions. postman will export the API with Postman extensions, allowing for import to the Postman tool
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --hdr-accept: string # The content-type of the export, for example application/json. Currently application/json and application/yaml are supported for exportType ofoas30 and swagger. This should be specified in the Accept header for direct API requests. (spec name: Accept)
]: nothing -> oneof<record<body: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  if ($export_type | is-empty) { error make --unspanned { msg: "path parameter 'export_type' must be non-empty" } }
  let qp = [(serialize-qp "parameters" $parameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name), export_type: (encode-path-segment $export_type)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"parameters": $parameters} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the GatewayResponses collection on the given RestApi. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default GatewayResponses collection for the supported response types.
#
# GET /restapis/{restapi_id}/gatewayresponses
# operationId: GetGatewayResponses
export def "get-gateway-responses" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set. The GatewayResponse collection does not support pagination and the position does not apply here.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The GatewayResponses collection does not support pagination and the limit does not apply here.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<responseType: string, statusCode: string, responseParameters: record, responseTemplates: record, defaultResponse: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/gatewayresponses") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Generates a sample mapping template that can be used to transform a payload into the structure of a model.
#
# GET /restapis/{restapi_id}/models/{model_name}/default_template
# operationId: GetModelTemplate
export def "get-model-template" [
  restapi_id: string
  model_name: string
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
]: nothing -> oneof<record<value: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($model_name | is-empty) { error make --unspanned { msg: "path parameter 'model_name' must be non-empty" } }
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), model_name: (encode-path-segment $model_name)} | format pattern "/restapis/{restapi_id}/models/{model_name}/default_template") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists information about a collection of Resource resources.
#
# GET /restapis/{restapi_id}/resources
# operationId: GetResources
export def "get-resources" [
  restapi_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --embed: list # A query parameter used to retrieve the specified resources embedded in the returned Resources resource in the response. This embed parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded Method resources this way. The query parameter value must be a single-valued list and contain the "methods" string. For example, GET /restapis/{restapi_id}/resources?embed=methods.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<id: string, parentId: string, pathPart: string, path: string, resourceMethods: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "embed" $embed "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id)} | format pattern "/restapis/{restapi_id}/resources") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit, "embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Generates a client SDK for a RestApi and Stage.
#
# GET /restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}
# operationId: GetSdk
export def "get-sdk" [
  restapi_id: string
  stage_name: string
  sdk_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameters: record # A string-to-string key-value map of query parameters sdkType-dependent properties of the SDK. For sdkType of objectivec or swift, a parameter named classPrefix is required. For sdkType of android, parameters named groupId, artifactId, artifactVersion, and invokerPackage are required. For sdkType of java, parameters named serviceName and javaPackageName are required.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<body: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($restapi_id | is-empty) { error make --unspanned { msg: "path parameter 'restapi_id' must be non-empty" } }
  if ($stage_name | is-empty) { error make --unspanned { msg: "path parameter 'stage_name' must be non-empty" } }
  if ($sdk_type | is-empty) { error make --unspanned { msg: "path parameter 'sdk_type' must be non-empty" } }
  let qp = [(serialize-qp "parameters" $parameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({restapi_id: (encode-path-segment $restapi_id), stage_name: (encode-path-segment $stage_name), sdk_type: (encode-path-segment $sdk_type)} | format pattern "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"parameters": $parameters} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets an SDK type.
#
# GET /sdktypes/{sdktype_id}
# operationId: GetSdkType
export def "get-sdk-type" [
  sdktype_id: string
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
]: nothing -> oneof<record<id: string, friendlyName: string, description: string, configurationProperties: table<name: string, friendlyName: string, description: string, required: bool, defaultValue: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sdktype_id | is-empty) { error make --unspanned { msg: "path parameter 'sdktype_id' must be non-empty" } }
  let full_url = (build-url $base ({sdktype_id: (encode-path-segment $sdktype_id)} | format pattern "/sdktypes/{sdktype_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets SDK types
#
# GET /sdktypes
# operationId: GetSdkTypes
export def "get-sdk-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<position: string, items: table<id: string, friendlyName: string, description: string, configurationProperties: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sdktypes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the Tags collection for a given resource.
#
# GET /tags/{resource_arn}
# operationId: GetTags
export def "get-tags" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: string # (Not currently supported) The current pagination position in the paged result set.
  --limit: int # (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<tags: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource_arn' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds or updates a tag on a given resource.
#
# PUT /tags/{resource_arn}
# operationId: TagResource
export def "tag-resource" [
  resource_arn: string
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
  tags: record # The key-value map of strings. The valid character set is [a-zA-Z+-=._:/]. The tag key can be up to 128 characters and must not start with aws:. The tag value can be up to 256 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource_arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $auth.query)
  let req_body = {"tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Gets the usage data of a usage plan in a specified time interval.
#
# GET /usageplans/{usageplanId}/usage
# operationId: GetUsage
export def "get-usage" [
  usageplan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key-id: string # The Id of the API key associated with the resultant usage data.
  --start-date: string # The starting date (e.g., 2016-01-01) of the usage data. (required)
  --end-date: string # The ending date (e.g., 2016-12-31) of the usage data. (required)
  --position: string # The current pagination position in the paged result set.
  --limit: int # The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<usagePlanId: string, startDate: string, endDate: string, position: string, items: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  if ($start_date == null) { error make --unspanned { msg: "required query parameter 'startDate' missing: pass --start-date" } }
  if ($end_date == null) { error make --unspanned { msg: "required query parameter 'endDate' missing: pass --end-date" } }
  let qp = [(serialize-qp "keyId" $key_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id)} | format pattern "/usageplans/{usageplan_id}/usage") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"keyId": $key_id, "startDate": $start_date, "endDate": $end_date, "position": $position, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Import API keys from an external source, such as a CSV-formatted file.
#
# POST /apikeys
# operationId: ImportApiKeys
export def "import-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # A query parameter to specify the input format to imported API keys. Currently, only the csv format is supported. (required)
  --failonwarnings: oneof<nothing, bool> # A query parameter to indicate whether to rollback ApiKey importation (true) or not (false) when error is encountered.
  --mode: string@mode-completer-1 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The payload of the POST request to import API keys. For the payload format, see API Key File Format.
]: any -> oneof<record<ids: list<string>, warnings: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let format = ($format | default "csv")
  let mode = ($mode | default "import")
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "failonwarnings" $failonwarnings "scalar") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apikeys" $qp $auth.query)
  let req_body = {"body": $body} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"format": $format, "failonwarnings": $failonwarnings, "mode": $mode} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# A feature of the API Gateway control service for creating a new API from an external API definition file.
#
# POST /restapis
# operationId: ImportRestApi
export def "import-rest-api" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --failonwarnings: oneof<nothing, bool> # A query parameter to indicate whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  --parameters: record # A key-value map of context-specific query string parameters specifying the behavior of different API importing operations. The following shows operation-specific parameters and their supported values. To exclude DocumentationParts from the import, set parameters as ignore=documentation. To configure the endpoint type, set parameters as endpointConfigurationTypes=EDGE, endpointConfigurationTypes=REGIONAL, or endpointConfigurationTypes=PRIVATE. The default endpoint type is EDGE. To handle imported basepath, set parameters as basepath=ignore, basepath=prepend or basepath=split. For example, the AWS CLI command to exclude documentation from the imported API is: The AWS CLI command to set the regional endpoint on the imported API is:
  --mode: string@mode-completer-1 # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  body: string # The POST request body containing external API definitions. Currently, only OpenAPI definition JSON/YAML files are supported. The maximum size of the API definition file is 6MB.
]: any -> oneof<record<id: string, name: string, description: string, createdDate: string, version: string, warnings: list<string>, binaryMediaTypes: list<string>, minimumCompressionSize: int, apiKeySource: string, endpointConfiguration: record<types: list<string>, vpcEndpointIds: list<string>>, policy: string, tags: record, disableExecuteApiEndpoint: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let mode = ($mode | default "import")
  let qp = [(serialize-qp "failonwarnings" $failonwarnings "scalar") (serialize-qp "parameters" $parameters "multi") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapis" $qp $auth.query)
  let req_body = {"body": $body} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"failonwarnings": $failonwarnings, "parameters": $parameters, "mode": $mode} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Removes a tag from a given resource.
#
# DELETE /tags/{resource_arn}
# operationId: UntagResource
export def "untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # The Tag keys to delete. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource_arn' must be non-empty" } }
  if ($tag_keys == null) { error make --unspanned { msg: "required query parameter 'tagKeys' missing: pass --tag-keys" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"tagKeys": $tag_keys} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
#
# PATCH /usageplans/{usageplanId}/keys/{keyId}/usage
# operationId: UpdateUsage
export def "update-usage" [
  usageplan_id: string
  key_id: string
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
  --patch-operations: list # A list of operations describing the updates to apply to the specified resource. The patches are applied in the order specified in the list. — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: string, from?: string}
]: any -> oneof<record<usagePlanId: string, startDate: string, endDate: string, position: string, items: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usageplan_id | is-empty) { error make --unspanned { msg: "path parameter 'usageplanId' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'keyId' must be non-empty" } }
  let full_url = (build-url $base ({usageplan_id: (encode-path-segment $usageplan_id), key_id: (encode-path-segment $key_id)} | format pattern "/usageplans/{usageplan_id}/keys/{key_id}/usage") $auth.query)
  let req_body = {"patchOperations": $patch_operations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}
