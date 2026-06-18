# Auto-generated client for AWS AppSync v2017-07-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/appsync/2017-07-25/openapi.json
# Auth: --token flag or $env.AWS_APPSYNC_TOKEN

const BASE_URL = "http://appsync.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_APPSYNC_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def base-url-completer [] { ["http://appsync.us-east-1.amazonaws.com" "http://appsync.us-east-2.amazonaws.com" "http://appsync.us-west-1.amazonaws.com" "http://appsync.us-west-2.amazonaws.com" "http://appsync.us-gov-west-1.amazonaws.com" "http://appsync.us-gov-east-1.amazonaws.com" "http://appsync.ca-central-1.amazonaws.com" "http://appsync.eu-north-1.amazonaws.com" "http://appsync.eu-west-1.amazonaws.com" "http://appsync.eu-west-2.amazonaws.com" "http://appsync.eu-west-3.amazonaws.com" "http://appsync.eu-central-1.amazonaws.com" "http://appsync.eu-south-1.amazonaws.com" "http://appsync.af-south-1.amazonaws.com" "http://appsync.ap-northeast-1.amazonaws.com" "http://appsync.ap-northeast-2.amazonaws.com" "http://appsync.ap-northeast-3.amazonaws.com" "http://appsync.ap-southeast-1.amazonaws.com" "http://appsync.ap-southeast-2.amazonaws.com" "http://appsync.ap-east-1.amazonaws.com" "http://appsync.ap-south-1.amazonaws.com" "http://appsync.sa-east-1.amazonaws.com" "http://appsync.me-south-1.amazonaws.com" "https://appsync.us-east-1.amazonaws.com" "https://appsync.us-east-2.amazonaws.com" "https://appsync.us-west-1.amazonaws.com" "https://appsync.us-west-2.amazonaws.com" "https://appsync.us-gov-west-1.amazonaws.com" "https://appsync.us-gov-east-1.amazonaws.com" "https://appsync.ca-central-1.amazonaws.com" "https://appsync.eu-north-1.amazonaws.com" "https://appsync.eu-west-1.amazonaws.com" "https://appsync.eu-west-2.amazonaws.com" "https://appsync.eu-west-3.amazonaws.com" "https://appsync.eu-central-1.amazonaws.com" "https://appsync.eu-south-1.amazonaws.com" "https://appsync.af-south-1.amazonaws.com" "https://appsync.ap-northeast-1.amazonaws.com" "https://appsync.ap-northeast-2.amazonaws.com" "https://appsync.ap-northeast-3.amazonaws.com" "https://appsync.ap-southeast-1.amazonaws.com" "https://appsync.ap-southeast-2.amazonaws.com" "https://appsync.ap-east-1.amazonaws.com" "https://appsync.ap-south-1.amazonaws.com" "https://appsync.sa-east-1.amazonaws.com" "https://appsync.me-south-1.amazonaws.com" "http://appsync.cn-north-1.amazonaws.com.cn" "http://appsync.cn-northwest-1.amazonaws.com.cn" "https://appsync.cn-north-1.amazonaws.com.cn" "https://appsync.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def api-caching-behavior-completer [] { ["FULL_REQUEST_CACHING" "PER_RESOLVER_CACHING"] }
def type-completer [] { ["LARGE" "LARGE_12X" "LARGE_2X" "LARGE_4X" "LARGE_8X" "MEDIUM" "R4_2XLARGE" "R4_4XLARGE" "R4_8XLARGE" "R4_LARGE" "R4_XLARGE" "SMALL" "T2_MEDIUM" "T2_SMALL" "XLARGE"] }
def type-completer-1 [] { ["AMAZON_DYNAMODB" "AMAZON_ELASTICSEARCH" "AMAZON_EVENTBRIDGE" "AMAZON_OPENSEARCH_SERVICE" "AWS_LAMBDA" "HTTP" "NONE" "RELATIONAL_DATABASE"] }
def authentication-type-completer [] { ["AMAZON_COGNITO_USER_POOLS" "API_KEY" "AWS_IAM" "AWS_LAMBDA" "OPENID_CONNECT"] }
def kind-completer [] { ["PIPELINE" "UNIT"] }
def format-completer [] { ["JSON" "SDL"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domainnames-apiassociation create-associate" } } | get name | first)
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

# Maps an endpoint to your custom domain.
#
# POST /v1/domainnames/{domainName}/apiassociation
# operationId: AssociateApi
export def "domainnames-apiassociation create-associate" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  api_id: string # The API ID.
]: any -> record<apiAssociation: record<domainName: record, apiId: record, associationStatus: record, deploymentDetail: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v1/domainnames/{domain_name}/apiassociation"))
  let req_body = {"apiId": $api_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes an ApiAssociation object from a custom domain.
#
# DELETE /v1/domainnames/{domainName}/apiassociation
# operationId: DisassociateApi
export def "domainnames-apiassociation delete-disassociate" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v1/domainnames/{domain_name}/apiassociation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves an ApiAssociation object.
#
# GET /v1/domainnames/{domainName}/apiassociation
# operationId: GetApiAssociation
export def "domainnames-apiassociation get-association" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<apiAssociation: record<domainName: record, apiId: record, associationStatus: record, deploymentDetail: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v1/domainnames/{domain_name}/apiassociation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a cache for the GraphQL API.
#
# POST /v1/apis/{apiId}/ApiCaches
# operationId: CreateApiCache
export def "apis-api-caches create" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  ttl: int # TTL in seconds for cache entries. Valid values are 1–3,600 seconds.
  --transit-encryption-enabled: oneof<nothing, bool> # Transit encryption flag when connecting to cache. You cannot update this setting after creation.
  --at-rest-encryption-enabled: oneof<nothing, bool> # At-rest encryption flag for cache. You cannot update this setting after creation.
  api_caching_behavior: string@api-caching-behavior-completer # Caching behavior. FULL_REQUEST_CACHING: All requests are fully cached. PER_RESOLVER_CACHING: Individual resolvers that you specify are cached.
  type: string@type-completer # The cache instance type. Valid values are SMALL MEDIUM LARGE XLARGE LARGE_2X LARGE_4X LARGE_8X (not available in all regions) LARGE_12X Historically, instance types were identified by an EC2-style value. As of July 2020, this is deprecated, and the generic identifiers above should be used. The following legacy instance types are available, but their use is discouraged: T2_SMALL: A t2.small instance type. T2_MEDIUM: A t2.medium instance type. R4_LARGE: A r4.large instance type. R4_XLARGE: A r4.xlarge instance type. R4_2XLARGE: A r4.2xlarge instance type. R4_4XLARGE: A r4.4xlarge instance type. R4_8XLARGE: A r4.8xlarge instance type.
]: any -> record<apiCache: record<ttl: record, apiCachingBehavior: record, transitEncryptionEnabled: record, atRestEncryptionEnabled: record, type: record, status: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/ApiCaches"))
  let req_body = {"ttl": $ttl, "transitEncryptionEnabled": $transit_encryption_enabled, "atRestEncryptionEnabled": $at_rest_encryption_enabled, "apiCachingBehavior": $api_caching_behavior, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an ApiCache object.
#
# DELETE /v1/apis/{apiId}/ApiCaches
# operationId: DeleteApiCache
export def "apis-api-caches delete" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/ApiCaches"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves an ApiCache object.
#
# GET /v1/apis/{apiId}/ApiCaches
# operationId: GetApiCache
export def "apis-api-caches get" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<apiCache: record<ttl: record, apiCachingBehavior: record, transitEncryptionEnabled: record, atRestEncryptionEnabled: record, type: record, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/ApiCaches"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a unique key that you can distribute to clients who invoke your API.
#
# POST /v1/apis/{apiId}/apikeys
# operationId: CreateApiKey
export def "apis-apikeys create-key" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the purpose of the API key.
  --expires: int # From the creation time, the time after which the API key expires. The date is represented as seconds since the epoch, rounded down to the nearest hour. The default value for this parameter is 7 days from creation time. For more information, see .
]: any -> record<apiKey: record<id: record, description: record, expires: record, deletes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/apikeys"))
  let req_body = {"description": $description, "expires": $expires} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the API keys for a given API. API keys are deleted automatically 60 days after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call DeleteApiKey to manually delete a key before it's automatically deleted.
#
# GET /v1/apis/{apiId}/apikeys
# operationId: ListApiKeys
export def "apis-apikeys list-keys" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<apiKeys: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/apikeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a DataSource object.
#
# POST /v1/apis/{apiId}/datasources
# operationId: CreateDataSource
# --dynamodbConfig shape: {tableName?: any, awsRegion?: any, useCallerCredentials?: any, deltaSyncConfig?: any, versioned?: any}
# --lambdaConfig shape: {lambdaFunctionArn?: any}
# --elasticsearchConfig shape: {endpoint?: any, awsRegion?: any}
# --openSearchServiceConfig shape: {endpoint?: any, awsRegion?: any}
# --httpConfig shape: {endpoint?: any, authorizationConfig?: any}
# --relationalDatabaseConfig shape: {relationalDatabaseSourceType?: any, rdsHttpEndpointConfig?: any}
# --eventBridgeConfig shape: {eventBusArn?: any}
export def "apis-datasources create-data-source" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # A user-supplied name for the DataSource.
  --description: string # A description of the DataSource.
  type: string@type-completer-1 # The type of the DataSource.
  --service-role-arn: string # The Identity and Access Management (IAM) service role Amazon Resource Name (ARN) for the data source. The system assumes this role when accessing the data source.
  --dynamodb-config: record # Describes an Amazon DynamoDB data source configuration. — shape: {tableName?: any, awsRegion?: any, useCallerCredentials?: any, deltaSyncConfig?: any, versioned?: any}
  --lambda-config: record # Describes an Lambda data source configuration. — shape: {lambdaFunctionArn?: any}
  --elasticsearch-config: record # Describes an OpenSearch data source configuration. As of September 2021, Amazon Elasticsearch service is Amazon OpenSearch Service. This configuration is deprecated. For new data sources, use OpenSearchServiceDataSourceConfig to specify an OpenSearch data source. — shape: {endpoint?: any, awsRegion?: any}
  --open-search-service-config: record # Describes an OpenSearch data source configuration. — shape: {endpoint?: any, awsRegion?: any}
  --http-config: record # Describes an HTTP data source configuration. — shape: {endpoint?: any, authorizationConfig?: any}
  --relational-database-config: record # Describes a relational database data source configuration. — shape: {relationalDatabaseSourceType?: any, rdsHttpEndpointConfig?: any}
  --event-bridge-config: record # Describes an Amazon EventBridge bus data source configuration. — shape: {eventBusArn?: any}
]: any -> record<dataSource: record<dataSourceArn: record, name: record, description: record, type: record, serviceRoleArn: record, dynamodbConfig: record<tableName: record, awsRegion: record, useCallerCredentials: record, deltaSyncConfig: record, versioned: record>, lambdaConfig: record<lambdaFunctionArn: record>, elasticsearchConfig: record<endpoint: record, awsRegion: record>, openSearchServiceConfig: record<endpoint: record, awsRegion: record>, httpConfig: record<endpoint: record, authorizationConfig: record>, relationalDatabaseConfig: record<relationalDatabaseSourceType: record, rdsHttpEndpointConfig: record>, eventBridgeConfig: record<eventBusArn: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/datasources"))
  let req_body = {"name": $name, "description": $description, "type": $type, "serviceRoleArn": $service_role_arn, "dynamodbConfig": $dynamodb_config, "lambdaConfig": $lambda_config, "elasticsearchConfig": $elasticsearch_config, "openSearchServiceConfig": $open_search_service_config, "httpConfig": $http_config, "relationalDatabaseConfig": $relational_database_config, "eventBridgeConfig": $event_bridge_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the data sources for a given API.
#
# GET /v1/apis/{apiId}/datasources
# operationId: ListDataSources
export def "apis-datasources list-data-sources" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<dataSources: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/datasources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a custom DomainName object.
#
# POST /v1/domainnames
# operationId: CreateDomainName
export def "domainnames create-domain-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain_name: string # The domain name.
  certificate_arn: string # The Amazon Resource Name (ARN) of the certificate. This can be an Certificate Manager (ACM) certificate or an Identity and Access Management (IAM) server certificate.
  --description: string # A description of the DomainName.
]: any -> record<domainNameConfig: record<domainName: record, description: record, certificateArn: record, appsyncDomainName: record, hostedZoneId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domainnames")
  let req_body = {"domainName": $domain_name, "certificateArn": $certificate_arn, "description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists multiple custom domain names.
#
# GET /v1/domainnames
# operationId: ListDomainNames
export def "domainnames list-domain-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The API token.
  --max-results: int # The maximum number of results that you want the request to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<domainNameConfigs: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domainnames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Function object. A function is a reusable entity. You can use multiple functions to compose the resolver logic.
#
# POST /v1/apis/{apiId}/functions
# operationId: CreateFunction
# --syncConfig shape: {conflictHandler?: any, conflictDetection?: any, lambdaConflictHandlerConfig?: any}
# --runtime shape: {name?: any, runtimeVersion?: any}
export def "apis-functions create" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The Function name. The function name does not have to be unique.
  --description: string # The Function description.
  data_source_name: string # The Function DataSource name.
  --request-mapping-template: string # The Function request mapping template. Functions support only the 2018-05-29 version of the request mapping template.
  --response-mapping-template: string # The Function response mapping template.
  --function-version: string # The version of the request mapping template. Currently, the supported value is 2018-05-29. Note that when using VTL and mapping templates, the functionVersion is required.
  --sync-config: record # Describes a Sync configuration for a resolver. Specifies which Conflict Detection strategy and Resolution strategy to use when the resolver is invoked. — shape: {conflictHandler?: any, conflictDetection?: any, lambdaConflictHandlerConfig?: any}
  --max-batch-size: int # The maximum batching size for a resolver.
  --runtime: record # Describes a runtime used by an Amazon Web Services AppSync pipeline resolver or Amazon Web Services AppSync function. Specifies the name and version of the runtime to use. Note that if a runtime is specified, code must also be specified. — shape: {name?: any, runtimeVersion?: any}
  --code: string # The function code that contains the request and response functions. When code is used, the runtime is required. The runtime value must be APPSYNC_JS.
]: any -> record<functionConfiguration: record<functionId: record, functionArn: record, name: record, description: record, dataSourceName: record, requestMappingTemplate: record, responseMappingTemplate: record, functionVersion: record, syncConfig: record<conflictHandler: record, conflictDetection: record, lambdaConflictHandlerConfig: record>, maxBatchSize: record, runtime: record<name: record, runtimeVersion: record>, code: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/functions"))
  let req_body = {"name": $name, "description": $description, "dataSourceName": $data_source_name, "requestMappingTemplate": $request_mapping_template, "responseMappingTemplate": $response_mapping_template, "functionVersion": $function_version, "syncConfig": $sync_config, "maxBatchSize": $max_batch_size, "runtime": $runtime, "code": $code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List multiple functions.
#
# GET /v1/apis/{apiId}/functions
# operationId: ListFunctions
export def "apis-functions list" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<functions: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/functions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GraphqlApi object.
#
# POST /v1/apis
# operationId: CreateGraphqlApi
# --logConfig shape: {fieldLogLevel?: any, cloudWatchLogsRoleArn?: any, excludeVerboseContent?: any}
# --userPoolConfig shape: {userPoolId?: any, awsRegion?: any, defaultAction?: any, appIdClientRegex?: any}
# --openIDConnectConfig shape: {issuer?: any, clientId?: any, iatTTL?: any, authTTL?: any}
# --additionalAuthenticationProviders item shape: {authenticationType?: any, openIDConnectConfig?: any, userPoolConfig?: any, lambdaAuthorizerConfig?: any}
# --lambdaAuthorizerConfig shape: {authorizerResultTtlInSeconds?: any, authorizerUri?: any, identityValidationExpression?: any}
export def "apis create-graphql" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # A user-supplied name for the GraphqlApi.
  --log-config: record # The Amazon CloudWatch Logs configuration. — shape: {fieldLogLevel?: any, cloudWatchLogsRoleArn?: any, excludeVerboseContent?: any}
  authentication_type: string@authentication-type-completer # The authentication type: API key, Identity and Access Management (IAM), OpenID Connect (OIDC), Amazon Cognito user pools, or Lambda.
  --user-pool-config: record # Describes an Amazon Cognito user pool configuration. — shape: {userPoolId?: any, awsRegion?: any, defaultAction?: any, appIdClientRegex?: any}
  --open-id-connect-config: record # Describes an OpenID Connect (OIDC) configuration. — shape: {issuer?: any, clientId?: any, iatTTL?: any, authTTL?: any}
  --tags: record # A map with keys of TagKey objects and values of TagValue objects.
  --additional-authentication-providers: list # A list of additional authentication providers for the GraphqlApi API. — item shape: {authenticationType?: any, openIDConnectConfig?: any, userPoolConfig?: any, lambdaAuthorizerConfig?: any}
  --xray-enabled: oneof<nothing, bool> # A flag indicating whether to use X-Ray tracing for the GraphqlApi.
  --lambda-authorizer-config: record # A LambdaAuthorizerConfig specifies how to authorize AppSync API access when using the AWS_LAMBDA authorizer mode. Be aware that an AppSync API can have only one Lambda authorizer configured at a time. — shape: {authorizerResultTtlInSeconds?: any, authorizerUri?: any, identityValidationExpression?: any}
]: any -> record<graphqlApi: record<name: record, apiId: record, authenticationType: record, logConfig: record<fieldLogLevel: record, cloudWatchLogsRoleArn: record, excludeVerboseContent: record>, userPoolConfig: record<userPoolId: record, awsRegion: record, defaultAction: record, appIdClientRegex: record>, openIDConnectConfig: record<issuer: record, clientId: record, iatTTL: record, authTTL: record>, arn: record, uris: record, tags: record, additionalAuthenticationProviders: record, xrayEnabled: record, wafWebAclArn: record, lambdaAuthorizerConfig: record<authorizerResultTtlInSeconds: record, authorizerUri: record, identityValidationExpression: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/apis")
  let req_body = {"name": $name, "logConfig": $log_config, "authenticationType": $authentication_type, "userPoolConfig": $user_pool_config, "openIDConnectConfig": $open_id_connect_config, "tags": $tags, "additionalAuthenticationProviders": $additional_authentication_providers, "xrayEnabled": $xray_enabled, "lambdaAuthorizerConfig": $lambda_authorizer_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists your GraphQL APIs.
#
# GET /v1/apis
# operationId: ListGraphqlApis
export def "apis list-graphql" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<graphqlApis: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/apis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Resolver object. A resolver converts incoming requests into a format that a data source can understand, and converts the data source's responses into GraphQL.
#
# POST /v1/apis/{apiId}/types/{typeName}/resolvers
# operationId: CreateResolver
# --pipelineConfig shape: {functions?: any}
# --syncConfig shape: {conflictHandler?: any, conflictDetection?: any, lambdaConflictHandlerConfig?: any}
# --cachingConfig shape: {ttl?: any, cachingKeys?: any}
# --runtime shape: {name?: any, runtimeVersion?: any}
export def "apis-types-resolvers create" [
  api_id: string
  type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  field_name: string # The name of the field to attach the resolver to.
  --data-source-name: string # The name of the data source for which the resolver is being created.
  --request-mapping-template: string # The mapping template to use for requests. A resolver uses a request mapping template to convert a GraphQL expression into a format that a data source can understand. Mapping templates are written in Apache Velocity Template Language (VTL). VTL request mapping templates are optional when using an Lambda data source. For all other data sources, VTL request and response mapping templates are required.
  --response-mapping-template: string # The mapping template to use for responses from the data source.
  --kind: string@kind-completer # The resolver type. UNIT: A UNIT resolver type. A UNIT resolver is the default resolver type. You can use a UNIT resolver to run a GraphQL query against a single data source. PIPELINE: A PIPELINE resolver type. You can use a PIPELINE resolver to invoke a series of Function objects in a serial manner. You can use a pipeline resolver to run a GraphQL query against multiple data sources.
  --pipeline-config: record # The pipeline configuration for a resolver of kind PIPELINE. — shape: {functions?: any}
  --sync-config: record # Describes a Sync configuration for a resolver. Specifies which Conflict Detection strategy and Resolution strategy to use when the resolver is invoked. — shape: {conflictHandler?: any, conflictDetection?: any, lambdaConflictHandlerConfig?: any}
  --caching-config: record # The caching configuration for a resolver that has caching activated. — shape: {ttl?: any, cachingKeys?: any}
  --max-batch-size: int # The maximum batching size for a resolver.
  --runtime: record # Describes a runtime used by an Amazon Web Services AppSync pipeline resolver or Amazon Web Services AppSync function. Specifies the name and version of the runtime to use. Note that if a runtime is specified, code must also be specified. — shape: {name?: any, runtimeVersion?: any}
  --code: string # The resolver code that contains the request and response functions. When code is used, the runtime is required. The runtime value must be APPSYNC_JS.
]: any -> record<resolver: record<typeName: record, fieldName: record, dataSourceName: record, resolverArn: record, requestMappingTemplate: record, responseMappingTemplate: record, kind: record, pipelineConfig: record<functions: record>, syncConfig: record<conflictHandler: record, conflictDetection: record, lambdaConflictHandlerConfig: record>, cachingConfig: record<ttl: record, cachingKeys: record>, maxBatchSize: record, runtime: record<name: record, runtimeVersion: record>, code: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), type_name: (encode-path-segment $type_name)} | format pattern "/v1/apis/{api_id}/types/{type_name}/resolvers"))
  let req_body = {"fieldName": $field_name, "dataSourceName": $data_source_name, "requestMappingTemplate": $request_mapping_template, "responseMappingTemplate": $response_mapping_template, "kind": $kind, "pipelineConfig": $pipeline_config, "syncConfig": $sync_config, "cachingConfig": $caching_config, "maxBatchSize": $max_batch_size, "runtime": $runtime, "code": $code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the resolvers for a given API and type.
#
# GET /v1/apis/{apiId}/types/{typeName}/resolvers
# operationId: ListResolvers
export def "apis-types-resolvers list" [
  api_id: string
  type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<resolvers: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), type_name: (encode-path-segment $type_name)} | format pattern "/v1/apis/{api_id}/types/{type_name}/resolvers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Type object.
#
# POST /v1/apis/{apiId}/types
# operationId: CreateType
export def "apis-types create" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  definition: string # The type definition, in GraphQL Schema Definition Language (SDL) format. For more information, see the GraphQL SDL documentation (http://graphql.org/learn/schema/).
  format: string@format-completer # The type format: SDL or JSON.
]: any -> record<type: record<name: record, description: record, arn: record, definition: record, format: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/types"))
  let req_body = {"definition": $definition, "format": $format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an API key.
#
# DELETE /v1/apis/{apiId}/apikeys/{id}
# operationId: DeleteApiKey
export def "apis-apikeys delete-key" [
  api_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), id: (encode-path-segment $id)} | format pattern "/v1/apis/{api_id}/apikeys/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an API key. You can update the key as long as it's not deleted.
#
# POST /v1/apis/{apiId}/apikeys/{id}
# operationId: UpdateApiKey
export def "apis-apikeys update-key" [
  api_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the purpose of the API key.
  --expires: int # From the update time, the time after which the API key expires. The date is represented as seconds since the epoch. For more information, see .
]: any -> record<apiKey: record<id: record, description: record, expires: record, deletes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), id: (encode-path-segment $id)} | format pattern "/v1/apis/{api_id}/apikeys/{id}"))
  let req_body = {"description": $description, "expires": $expires} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a DataSource object.
#
# DELETE /v1/apis/{apiId}/datasources/{name}
# operationId: DeleteDataSource
export def "apis-datasources delete-data-source" [
  api_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), name: (encode-path-segment $name)} | format pattern "/v1/apis/{api_id}/datasources/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a DataSource object.
#
# GET /v1/apis/{apiId}/datasources/{name}
# operationId: GetDataSource
export def "apis-datasources get-data-source" [
  api_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<dataSource: record<dataSourceArn: record, name: record, description: record, type: record, serviceRoleArn: record, dynamodbConfig: record<tableName: record, awsRegion: record, useCallerCredentials: record, deltaSyncConfig: record, versioned: record>, lambdaConfig: record<lambdaFunctionArn: record>, elasticsearchConfig: record<endpoint: record, awsRegion: record>, openSearchServiceConfig: record<endpoint: record, awsRegion: record>, httpConfig: record<endpoint: record, authorizationConfig: record>, relationalDatabaseConfig: record<relationalDatabaseSourceType: record, rdsHttpEndpointConfig: record>, eventBridgeConfig: record<eventBusArn: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), name: (encode-path-segment $name)} | format pattern "/v1/apis/{api_id}/datasources/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a DataSource object.
#
# POST /v1/apis/{apiId}/datasources/{name}
# operationId: UpdateDataSource
# --dynamodbConfig shape: {tableName?: any, awsRegion?: any, useCallerCredentials?: any, deltaSyncConfig?: any, versioned?: any}
# --lambdaConfig shape: {lambdaFunctionArn?: any}
# --elasticsearchConfig shape: {endpoint?: any, awsRegion?: any}
# --openSearchServiceConfig shape: {endpoint?: any, awsRegion?: any}
# --httpConfig shape: {endpoint?: any, authorizationConfig?: any}
# --relationalDatabaseConfig shape: {relationalDatabaseSourceType?: any, rdsHttpEndpointConfig?: any}
# --eventBridgeConfig shape: {eventBusArn?: any}
export def "apis-datasources update-data-source" [
  api_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # The new description for the data source.
  type: string@type-completer-1 # The new data source type.
  --service-role-arn: string # The new service role Amazon Resource Name (ARN) for the data source.
  --dynamodb-config: record # Describes an Amazon DynamoDB data source configuration. — shape: {tableName?: any, awsRegion?: any, useCallerCredentials?: any, deltaSyncConfig?: any, versioned?: any}
  --lambda-config: record # Describes an Lambda data source configuration. — shape: {lambdaFunctionArn?: any}
  --elasticsearch-config: record # Describes an OpenSearch data source configuration. As of September 2021, Amazon Elasticsearch service is Amazon OpenSearch Service. This configuration is deprecated. For new data sources, use OpenSearchServiceDataSourceConfig to specify an OpenSearch data source. — shape: {endpoint?: any, awsRegion?: any}
  --open-search-service-config: record # Describes an OpenSearch data source configuration. — shape: {endpoint?: any, awsRegion?: any}
  --http-config: record # Describes an HTTP data source configuration. — shape: {endpoint?: any, authorizationConfig?: any}
  --relational-database-config: record # Describes a relational database data source configuration. — shape: {relationalDatabaseSourceType?: any, rdsHttpEndpointConfig?: any}
  --event-bridge-config: record # Describes an Amazon EventBridge bus data source configuration. — shape: {eventBusArn?: any}
]: any -> record<dataSource: record<dataSourceArn: record, name: record, description: record, type: record, serviceRoleArn: record, dynamodbConfig: record<tableName: record, awsRegion: record, useCallerCredentials: record, deltaSyncConfig: record, versioned: record>, lambdaConfig: record<lambdaFunctionArn: record>, elasticsearchConfig: record<endpoint: record, awsRegion: record>, openSearchServiceConfig: record<endpoint: record, awsRegion: record>, httpConfig: record<endpoint: record, authorizationConfig: record>, relationalDatabaseConfig: record<relationalDatabaseSourceType: record, rdsHttpEndpointConfig: record>, eventBridgeConfig: record<eventBusArn: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), name: (encode-path-segment $name)} | format pattern "/v1/apis/{api_id}/datasources/{name}"))
  let req_body = {"description": $description, "type": $type, "serviceRoleArn": $service_role_arn, "dynamodbConfig": $dynamodb_config, "lambdaConfig": $lambda_config, "elasticsearchConfig": $elasticsearch_config, "openSearchServiceConfig": $open_search_service_config, "httpConfig": $http_config, "relationalDatabaseConfig": $relational_database_config, "eventBridgeConfig": $event_bridge_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a custom DomainName object.
#
# DELETE /v1/domainnames/{domainName}
# operationId: DeleteDomainName
export def "domainnames delete-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v1/domainnames/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a custom DomainName object.
#
# GET /v1/domainnames/{domainName}
# operationId: GetDomainName
export def "domainnames get-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<domainNameConfig: record<domainName: record, description: record, certificateArn: record, appsyncDomainName: record, hostedZoneId: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v1/domainnames/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a custom DomainName object.
#
# POST /v1/domainnames/{domainName}
# operationId: UpdateDomainName
export def "domainnames update-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the DomainName.
]: any -> record<domainNameConfig: record<domainName: record, description: record, certificateArn: record, appsyncDomainName: record, hostedZoneId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v1/domainnames/{domain_name}"))
  let req_body = {"description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a Function.
#
# DELETE /v1/apis/{apiId}/functions/{functionId}
# operationId: DeleteFunction
export def "apis-functions delete" [
  api_id: string
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), function_id: (encode-path-segment $function_id)} | format pattern "/v1/apis/{api_id}/functions/{function_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Function.
#
# GET /v1/apis/{apiId}/functions/{functionId}
# operationId: GetFunction
export def "apis-functions get" [
  api_id: string
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<functionConfiguration: record<functionId: record, functionArn: record, name: record, description: record, dataSourceName: record, requestMappingTemplate: record, responseMappingTemplate: record, functionVersion: record, syncConfig: record<conflictHandler: record, conflictDetection: record, lambdaConflictHandlerConfig: record>, maxBatchSize: record, runtime: record<name: record, runtimeVersion: record>, code: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), function_id: (encode-path-segment $function_id)} | format pattern "/v1/apis/{api_id}/functions/{function_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a Function object.
#
# POST /v1/apis/{apiId}/functions/{functionId}
# operationId: UpdateFunction
# --syncConfig shape: {conflictHandler?: any, conflictDetection?: any, lambdaConflictHandlerConfig?: any}
# --runtime shape: {name?: any, runtimeVersion?: any}
export def "apis-functions update" [
  api_id: string
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The Function name.
  --description: string # The Function description.
  data_source_name: string # The Function DataSource name.
  --request-mapping-template: string # The Function request mapping template. Functions support only the 2018-05-29 version of the request mapping template.
  --response-mapping-template: string # The Function request mapping template.
  --function-version: string # The version of the request mapping template. Currently, the supported value is 2018-05-29. Note that when using VTL and mapping templates, the functionVersion is required.
  --sync-config: record # Describes a Sync configuration for a resolver. Specifies which Conflict Detection strategy and Resolution strategy to use when the resolver is invoked. — shape: {conflictHandler?: any, conflictDetection?: any, lambdaConflictHandlerConfig?: any}
  --max-batch-size: int # The maximum batching size for a resolver.
  --runtime: record # Describes a runtime used by an Amazon Web Services AppSync pipeline resolver or Amazon Web Services AppSync function. Specifies the name and version of the runtime to use. Note that if a runtime is specified, code must also be specified. — shape: {name?: any, runtimeVersion?: any}
  --code: string # The function code that contains the request and response functions. When code is used, the runtime is required. The runtime value must be APPSYNC_JS.
]: any -> record<functionConfiguration: record<functionId: record, functionArn: record, name: record, description: record, dataSourceName: record, requestMappingTemplate: record, responseMappingTemplate: record, functionVersion: record, syncConfig: record<conflictHandler: record, conflictDetection: record, lambdaConflictHandlerConfig: record>, maxBatchSize: record, runtime: record<name: record, runtimeVersion: record>, code: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), function_id: (encode-path-segment $function_id)} | format pattern "/v1/apis/{api_id}/functions/{function_id}"))
  let req_body = {"name": $name, "description": $description, "dataSourceName": $data_source_name, "requestMappingTemplate": $request_mapping_template, "responseMappingTemplate": $response_mapping_template, "functionVersion": $function_version, "syncConfig": $sync_config, "maxBatchSize": $max_batch_size, "runtime": $runtime, "code": $code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a GraphqlApi object.
#
# DELETE /v1/apis/{apiId}
# operationId: DeleteGraphqlApi
export def "apis delete-graphql" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a GraphqlApi object.
#
# GET /v1/apis/{apiId}
# operationId: GetGraphqlApi
export def "apis get-graphql" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<graphqlApi: record<name: record, apiId: record, authenticationType: record, logConfig: record<fieldLogLevel: record, cloudWatchLogsRoleArn: record, excludeVerboseContent: record>, userPoolConfig: record<userPoolId: record, awsRegion: record, defaultAction: record, appIdClientRegex: record>, openIDConnectConfig: record<issuer: record, clientId: record, iatTTL: record, authTTL: record>, arn: record, uris: record, tags: record, additionalAuthenticationProviders: record, xrayEnabled: record, wafWebAclArn: record, lambdaAuthorizerConfig: record<authorizerResultTtlInSeconds: record, authorizerUri: record, identityValidationExpression: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a GraphqlApi object.
#
# POST /v1/apis/{apiId}
# operationId: UpdateGraphqlApi
# --logConfig shape: {fieldLogLevel?: any, cloudWatchLogsRoleArn?: any, excludeVerboseContent?: any}
# --userPoolConfig shape: {userPoolId?: any, awsRegion?: any, defaultAction?: any, appIdClientRegex?: any}
# --openIDConnectConfig shape: {issuer?: any, clientId?: any, iatTTL?: any, authTTL?: any}
# --additionalAuthenticationProviders item shape: {authenticationType?: any, openIDConnectConfig?: any, userPoolConfig?: any, lambdaAuthorizerConfig?: any}
# --lambdaAuthorizerConfig shape: {authorizerResultTtlInSeconds?: any, authorizerUri?: any, identityValidationExpression?: any}
export def "apis update-graphql" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The new name for the GraphqlApi object.
  --log-config: record # The Amazon CloudWatch Logs configuration. — shape: {fieldLogLevel?: any, cloudWatchLogsRoleArn?: any, excludeVerboseContent?: any}
  --authentication-type: string@authentication-type-completer # The new authentication type for the GraphqlApi object.
  --user-pool-config: record # Describes an Amazon Cognito user pool configuration. — shape: {userPoolId?: any, awsRegion?: any, defaultAction?: any, appIdClientRegex?: any}
  --open-id-connect-config: record # Describes an OpenID Connect (OIDC) configuration. — shape: {issuer?: any, clientId?: any, iatTTL?: any, authTTL?: any}
  --additional-authentication-providers: list # A list of additional authentication providers for the GraphqlApi API. — item shape: {authenticationType?: any, openIDConnectConfig?: any, userPoolConfig?: any, lambdaAuthorizerConfig?: any}
  --xray-enabled: oneof<nothing, bool> # A flag indicating whether to use X-Ray tracing for the GraphqlApi.
  --lambda-authorizer-config: record # A LambdaAuthorizerConfig specifies how to authorize AppSync API access when using the AWS_LAMBDA authorizer mode. Be aware that an AppSync API can have only one Lambda authorizer configured at a time. — shape: {authorizerResultTtlInSeconds?: any, authorizerUri?: any, identityValidationExpression?: any}
]: any -> record<graphqlApi: record<name: record, apiId: record, authenticationType: record, logConfig: record<fieldLogLevel: record, cloudWatchLogsRoleArn: record, excludeVerboseContent: record>, userPoolConfig: record<userPoolId: record, awsRegion: record, defaultAction: record, appIdClientRegex: record>, openIDConnectConfig: record<issuer: record, clientId: record, iatTTL: record, authTTL: record>, arn: record, uris: record, tags: record, additionalAuthenticationProviders: record, xrayEnabled: record, wafWebAclArn: record, lambdaAuthorizerConfig: record<authorizerResultTtlInSeconds: record, authorizerUri: record, identityValidationExpression: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}"))
  let req_body = {"name": $name, "logConfig": $log_config, "authenticationType": $authentication_type, "userPoolConfig": $user_pool_config, "openIDConnectConfig": $open_id_connect_config, "additionalAuthenticationProviders": $additional_authentication_providers, "xrayEnabled": $xray_enabled, "lambdaAuthorizerConfig": $lambda_authorizer_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a Resolver object.
#
# DELETE /v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}
# operationId: DeleteResolver
export def "apis-types-resolvers delete" [
  api_id: string
  type_name: string
  field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), type_name: (encode-path-segment $type_name), field_name: (encode-path-segment $field_name)} | format pattern "/v1/apis/{api_id}/types/{type_name}/resolvers/{field_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a Resolver object.
#
# GET /v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}
# operationId: GetResolver
export def "apis-types-resolvers get" [
  api_id: string
  type_name: string
  field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<resolver: record<typeName: record, fieldName: record, dataSourceName: record, resolverArn: record, requestMappingTemplate: record, responseMappingTemplate: record, kind: record, pipelineConfig: record<functions: record>, syncConfig: record<conflictHandler: record, conflictDetection: record, lambdaConflictHandlerConfig: record>, cachingConfig: record<ttl: record, cachingKeys: record>, maxBatchSize: record, runtime: record<name: record, runtimeVersion: record>, code: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), type_name: (encode-path-segment $type_name), field_name: (encode-path-segment $field_name)} | format pattern "/v1/apis/{api_id}/types/{type_name}/resolvers/{field_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a Resolver object.
#
# POST /v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}
# operationId: UpdateResolver
# --pipelineConfig shape: {functions?: any}
# --syncConfig shape: {conflictHandler?: any, conflictDetection?: any, lambdaConflictHandlerConfig?: any}
# --cachingConfig shape: {ttl?: any, cachingKeys?: any}
# --runtime shape: {name?: any, runtimeVersion?: any}
export def "apis-types-resolvers update" [
  api_id: string
  type_name: string
  field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --data-source-name: string # The new data source name.
  --request-mapping-template: string # The new request mapping template. A resolver uses a request mapping template to convert a GraphQL expression into a format that a data source can understand. Mapping templates are written in Apache Velocity Template Language (VTL). VTL request mapping templates are optional when using an Lambda data source. For all other data sources, VTL request and response mapping templates are required.
  --response-mapping-template: string # The new response mapping template.
  --kind: string@kind-completer # The resolver type. UNIT: A UNIT resolver type. A UNIT resolver is the default resolver type. You can use a UNIT resolver to run a GraphQL query against a single data source. PIPELINE: A PIPELINE resolver type. You can use a PIPELINE resolver to invoke a series of Function objects in a serial manner. You can use a pipeline resolver to run a GraphQL query against multiple data sources.
  --pipeline-config: record # The pipeline configuration for a resolver of kind PIPELINE. — shape: {functions?: any}
  --sync-config: record # Describes a Sync configuration for a resolver. Specifies which Conflict Detection strategy and Resolution strategy to use when the resolver is invoked. — shape: {conflictHandler?: any, conflictDetection?: any, lambdaConflictHandlerConfig?: any}
  --caching-config: record # The caching configuration for a resolver that has caching activated. — shape: {ttl?: any, cachingKeys?: any}
  --max-batch-size: int # The maximum batching size for a resolver.
  --runtime: record # Describes a runtime used by an Amazon Web Services AppSync pipeline resolver or Amazon Web Services AppSync function. Specifies the name and version of the runtime to use. Note that if a runtime is specified, code must also be specified. — shape: {name?: any, runtimeVersion?: any}
  --code: string # The resolver code that contains the request and response functions. When code is used, the runtime is required. The runtime value must be APPSYNC_JS.
]: any -> record<resolver: record<typeName: record, fieldName: record, dataSourceName: record, resolverArn: record, requestMappingTemplate: record, responseMappingTemplate: record, kind: record, pipelineConfig: record<functions: record>, syncConfig: record<conflictHandler: record, conflictDetection: record, lambdaConflictHandlerConfig: record>, cachingConfig: record<ttl: record, cachingKeys: record>, maxBatchSize: record, runtime: record<name: record, runtimeVersion: record>, code: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), type_name: (encode-path-segment $type_name), field_name: (encode-path-segment $field_name)} | format pattern "/v1/apis/{api_id}/types/{type_name}/resolvers/{field_name}"))
  let req_body = {"dataSourceName": $data_source_name, "requestMappingTemplate": $request_mapping_template, "responseMappingTemplate": $response_mapping_template, "kind": $kind, "pipelineConfig": $pipeline_config, "syncConfig": $sync_config, "cachingConfig": $caching_config, "maxBatchSize": $max_batch_size, "runtime": $runtime, "code": $code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a Type object.
#
# DELETE /v1/apis/{apiId}/types/{typeName}
# operationId: DeleteType
export def "apis-types delete" [
  api_id: string
  type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), type_name: (encode-path-segment $type_name)} | format pattern "/v1/apis/{api_id}/types/{type_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a Type object.
#
# POST /v1/apis/{apiId}/types/{typeName}
# operationId: UpdateType
export def "apis-types update" [
  api_id: string
  type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --definition: string # The new definition.
  format: string@format-completer # The new type format: SDL or JSON.
]: any -> record<type: record<name: record, description: record, arn: record, definition: record, format: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), type_name: (encode-path-segment $type_name)} | format pattern "/v1/apis/{api_id}/types/{type_name}"))
  let req_body = {"definition": $definition, "format": $format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Evaluates the given code and returns the response. The code definition requirements depend on the specified runtime. For APPSYNC_JS runtimes, the code defines the request and response functions. The request function takes the incoming request after a GraphQL operation is parsed and converts it into a request configuration for the selected data source operation. The response function interprets responses from the data source and maps it to the shape of the GraphQL field output type.
#
# POST /v1/dataplane-evaluatecode
# operationId: EvaluateCode
# --runtime shape: {name?: any, runtimeVersion?: any}
export def "dataplane-evaluatecode create-evaluate-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  runtime: record # Describes a runtime used by an Amazon Web Services AppSync pipeline resolver or Amazon Web Services AppSync function. Specifies the name and version of the runtime to use. Note that if a runtime is specified, code must also be specified. — shape: {name?: any, runtimeVersion?: any}
  code: string # The code definition to be evaluated. Note that code and runtime are both required for this action. The runtime value must be APPSYNC_JS.
  context: string # The map that holds all of the contextual information for your resolver invocation. A context is required for this action.
  --function: string # The function within the code to be evaluated. If provided, the valid values are request and response.
]: any -> record<evaluationResult: record, error: record<message: record, codeErrors: record>, logs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplane-evaluatecode")
  let req_body = {"runtime": $runtime, "code": $code, "context": $context, "function": $function} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Evaluates a given template and returns the response. The mapping template can be a request or response template. Request templates take the incoming request after a GraphQL operation is parsed and convert it into a request configuration for the selected data source operation. Response templates interpret responses from the data source and map it to the shape of the GraphQL field output type. Mapping templates are written in the Apache Velocity Template Language (VTL).
#
# POST /v1/dataplane-evaluatetemplate
# operationId: EvaluateMappingTemplate
export def "dataplane-evaluatetemplate create-evaluate-mapping-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  template: string # The mapping template; this can be a request or response template. A template is required for this action.
  context: string # The map that holds all of the contextual information for your resolver invocation. A context is required for this action.
]: any -> record<evaluationResult: record, error: record<message: record>, logs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplane-evaluatetemplate")
  let req_body = {"template": $template, "context": $context} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Flushes an ApiCache object.
#
# DELETE /v1/apis/{apiId}/FlushCache
# operationId: FlushApiCache
export def "apis-flush-cache delete" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/FlushCache"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the introspection schema for a GraphQL API.
#
# GET /v1/apis/{apiId}/schema#format
# operationId: GetIntrospectionSchema
export def "apis-schemaformat get-introspection-schema" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The schema format: SDL or JSON.
  --include-directives: oneof<nothing, bool> # A flag that specifies whether the schema introspection should contain directives.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<schema: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "includeDirectives" $include_directives "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/schema#format") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the current status of a schema creation operation.
#
# GET /v1/apis/{apiId}/schemacreation
# operationId: GetSchemaCreationStatus
export def "apis-schemacreation get-schema-creation-status" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<status: record, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/schemacreation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a new schema to your GraphQL API. This operation is asynchronous. Use to determine when it has completed.
#
# POST /v1/apis/{apiId}/schemacreation
# operationId: StartSchemaCreation
export def "apis-schemacreation start-schema-creation" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  definition: string # The schema definition, in GraphQL schema language format.
]: any -> record<status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/schemacreation"))
  let req_body = {"definition": $definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a Type object.
#
# GET /v1/apis/{apiId}/types/{typeName}#format
# operationId: GetType
export def "apis-types get" [
  api_id: string
  type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The type format: SDL or JSON.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<type: record<name: record, description: record, arn: record, definition: record, format: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), type_name: (encode-path-segment $type_name)} | format pattern "/v1/apis/{api_id}/types/{type_name}#format") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the resolvers that are associated with a specific function.
#
# GET /v1/apis/{apiId}/functions/{functionId}/resolvers
# operationId: ListResolversByFunction
export def "apis-functions-resolvers list" [
  api_id: string
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<resolvers: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), function_id: (encode-path-segment $function_id)} | format pattern "/v1/apis/{api_id}/functions/{function_id}/resolvers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the tags for a resource.
#
# GET /v1/tags/{resourceArn}
# operationId: ListTagsForResource
export def "tags list-for-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tags a resource with user-supplied tags.
#
# POST /v1/tags/{resourceArn}
# operationId: TagResource
export def "tags tag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # A map with keys of TagKey objects and values of TagValue objects.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the types for a given API.
#
# GET /v1/apis/{apiId}/types#format
# operationId: ListTypes
export def "apis-typesformat list-types" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The type format: SDL or JSON.
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<types: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/types#format") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Untags a resource.
#
# DELETE /v1/tags/{resourceArn}#tagKeys
# operationId: UntagResource
export def "tags untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # A list of TagKey objects.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}#tagKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the cache for the GraphQL API.
#
# POST /v1/apis/{apiId}/ApiCaches/update
# operationId: UpdateApiCache
export def "apis-api-caches-update update" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  ttl: int # TTL in seconds for cache entries. Valid values are 1–3,600 seconds.
  api_caching_behavior: string@api-caching-behavior-completer # Caching behavior. FULL_REQUEST_CACHING: All requests are fully cached. PER_RESOLVER_CACHING: Individual resolvers that you specify are cached.
  type: string@type-completer # The cache instance type. Valid values are SMALL MEDIUM LARGE XLARGE LARGE_2X LARGE_4X LARGE_8X (not available in all regions) LARGE_12X Historically, instance types were identified by an EC2-style value. As of July 2020, this is deprecated, and the generic identifiers above should be used. The following legacy instance types are available, but their use is discouraged: T2_SMALL: A t2.small instance type. T2_MEDIUM: A t2.medium instance type. R4_LARGE: A r4.large instance type. R4_XLARGE: A r4.xlarge instance type. R4_2XLARGE: A r4.2xlarge instance type. R4_4XLARGE: A r4.4xlarge instance type. R4_8XLARGE: A r4.8xlarge instance type.
]: any -> record<apiCache: record<ttl: record, apiCachingBehavior: record, transitEncryptionEnabled: record, atRestEncryptionEnabled: record, type: record, status: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/v1/apis/{api_id}/ApiCaches/update"))
  let req_body = {"ttl": $ttl, "apiCachingBehavior": $api_caching_behavior, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
