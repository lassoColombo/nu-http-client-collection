# Auto-generated client for Gcore OpenAPI – CDN API v2b9ad3cd04a0
# Source: https://gcore.com/docs/api-reference/services_docs_mintlify/cdn_api.yaml
# Auth: --token flag or $env.GCORE_OPENAPI_CDN_API_TOKEN

const BASE_URL = "https://api.gcore.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GCORE_OPENAPI_CDN_API_TOKEN | default "" }
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.gcore.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def format-completer [] { ["json" "plain"] }
def Accept-completer [] { ["application/json" "text/plain"] }
def accept-completer [] { ["application/json" "text/plain"] }
def status-completer [] { ["active" "deleted" "processed" "suspended"] }
def originProtocol-completer [] { ["HTTP" "HTTPS" "MATCH"] }
def format-type-completer [] { ["" "json"] }
def storage-type-completer [] { ["azure_blob" "ftp" "http" "s3_amazon" "s3_gcore" "s3_oss" "s3_other" "s3_v1" "sftp" "sls"] }
def overrideOriginProtocol-completer [] { ["HTTP" "HTTPS" "MATCH"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cdn-public-ip-list get-cdn-servers-ip-addresses" } } | get name | first)
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

# Get CDN servers IP addresses
#
# GET /cdn/public-ip-list
# operationId: get-cdn-servers-ip-addresses
export def "cdn-public-ip-list get-cdn-servers-ip-addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Optional format override. When set, this takes precedence over the `Accept` header.
  --Accept: string@Accept-completer # Content negotiation header. Defaults to `application/json` if not provided.
]: nothing -> record<addresses: list<string>, addresses_v6: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/public-ip-list" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CDN servers networks
#
# GET /cdn/public-net-list
# operationId: get-cdn-servers-networks
export def "cdn-public-net-list get-cdn-servers-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Optional format override. When set, this takes precedence over the `Accept` header.
  --Accept: string@Accept-completer # Content negotiation header. Defaults to `application/json` if not provided.
]: nothing -> record<addresses: list<string>, addresses_v6: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/public-net-list" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CDN service details
#
# GET /cdn/clients/me
# operationId: get-cdn-service-details
export def "cdn-clients-me get-cdn-service-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, created: string, updated: string, service: record<enabled: bool, status: string, updated: string>, utilization_level: int, cname: string, use_balancer: bool, auto_suspend_enabled: bool, cdn_resources_rules_max_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/clients/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change CDN service
#
# PUT /cdn/clients/me
# operationId: change-cdn-service
export def "cdn-clients-me change-cdn-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --utilization-level: int # CDN traffic usage limit in gigabytes.  When the limit is reached, we will send an email notification. (e.g. 1111)
]: any -> record<id: int, created: string, updated: string, service: record<enabled: bool, status: string, updated: string>, utilization_level: int, cname: string, use_balancer: bool, auto_suspend_enabled: bool, cdn_resources_rules_max_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/clients/me")
  let body = {utilization_level: $utilization_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change CDN service
#
# PATCH /cdn/clients/me
# operationId: patch-cdn-service
export def "cdn-clients-me patch-cdn-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --utilization-level: int # CDN traffic usage limit in gigabytes.  When the limit is reached, we will send an email notification. (e.g. 1111)
]: any -> record<id: int, created: string, updated: string, service: record<enabled: bool, status: string, updated: string>, utilization_level: int, cname: string, use_balancer: bool, auto_suspend_enabled: bool, cdn_resources_rules_max_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/clients/me")
  let body = {utilization_level: $utilization_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get CDN features details
#
# GET /cdn/clients/me/features
# operationId: get-cdn-features-details
export def "cdn-clients-me-features get-cdn-features-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, paid_features: table<feature_id: int, name: string, paid_feature_id: int, create_date: string>, free_features: table<feature_id: int, name: string, free_feature_id: int, create_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/clients/me/features")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CDN limits details
#
# GET /cdn/clients/me/limits
# operationId: get-cdn-limits-details
export def "cdn-clients-me-limits get-cdn-limits-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, resources_limit: int, rules_limit: int, origins_in_group_limit: int, secondary_hostnames_limit: int, purge_pattern_limit: int, purge_max_urls_limit: int, purge_request_limit: string, purge_by_urls_request_limit: string, prefetch_pattern_limit: int, prefetch_request_limit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/clients/me/limits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get origin groups list
#
# GET /cdn/origin_groups
# operationId: get-origin-groups-list
export def "cdn-origin-groups get-origin-groups-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Origin group name.
  --sources: string # Origin sources (IP addresses or domains) in the origin group.
  --has-related-resources: string@bool-completer # Defines whether the origin group has related CDN resources.  Possible values: - **true** – Origin group has related CDN resources. - **false** – Origin group does not have related CDN resources.
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "sources" $sources "scalar") (serialize-qp "has_related_resources" $has_related_resources "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/origin_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create origin group
#
# POST /cdn/origin_groups
# operationId: create-origin-group
# --auth shape: {s3_type: string, s3_access_key_id: string, s3_secret_access_key: string, s3_bucket_name: string, s3_storage_hostname?: string, s3_region?: string}
@deprecated --flag auth-type
@deprecated --flag body-auth
export def "cdn-origin-groups create-origin-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Origin group name. (e.g. YourOriginGroup)
  --use-next: string@bool-completer # Defines whether to use the next origin from the origin group if origin responds with the cases specified in `proxy_next_upstream`. If you enable it, you must specify cases in `proxy_next_upstream`.  Possible values: - **true** - Option is enabled. - **false** - Option is disabled. (e.g. true)
  --proxy-next-upstream: list # Defines cases when the request should be passed on to the next origin.  Possible values: - **error** - an error occurred while establishing a connection with the origin, passing a request to it, or reading the response header - **timeout** - a timeout has occurred while establishing a connection with the origin, passing a request to it, or reading the response header - **`invalid_header`** - a origin returned an empty or invalid response - **`http_403`** - a origin returned a response with the code 403 - **`http_404`** - a origin returned a response with the code 404 - **`http_429`** - a origin returned a response with the code 429 - **`http_500`** - a origin returned a response with the code 500 - **`http_502`** - a origin returned a response with the code 502 - **`http_503`** - a origin returned a response with the code 503 - **`http_504`** - a origin returned a response with the code 504 (default: [error, timeout], e.g. [error, timeout, invalid_header, http_500, http_502, http_503, http_504])
  --auth-type: string # **Deprecated.** No longer necessary. Defaults to `none`.  Origin authentication type.  Possible values: - **none** - Used for public origins. - **awsSignatureV4** - Used for S3 storage. (DEPRECATED, default: none, e.g. none)
  --sources: list
  --body-auth: record # **Deprecated.** To create S3 origins, configure them directly in sources with `origin_type` and `config` instead.  Credentials to access the private bucket. (DEPRECATED, e.g. {s3_type: amazon, s3_access_key_id: EXAMPLEFODNN7EXAMPLE, s3_secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY, s3_bucket_name: bucket_name, s3_region: us-east-2}) — shape: {s3_type: string, s3_access_key_id: string, s3_secret_access_key: string, s3_bucket_name: string, s3_storage_hostname?: string, s3_region?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/origin_groups")
  let body = {name: $name, use_next: $use_next, proxy_next_upstream: $proxy_next_upstream, auth_type: $auth_type, sources: $sources, auth: $body_auth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get origin group details
#
# GET /cdn/origin_groups/{origin_group_id}
# operationId: get-origin-group-details
export def "cdn-origin-groups get-origin-group-details" [
  origin_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/origin_groups/($origin_group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change origin group
#
# PUT /cdn/origin_groups/{origin_group_id}
# operationId: change-origin-group
# --auth shape: {s3_type: string, s3_access_key_id: string, s3_secret_access_key: string, s3_bucket_name: string, s3_storage_hostname?: string, s3_region?: string}
@deprecated --flag auth-type
@deprecated --flag path
@deprecated --flag body-auth
export def "cdn-origin-groups change-origin-group" [
  origin_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Origin group name. (e.g. YourOriginGroup)
  --use-next: string@bool-completer # Defines whether to use the next origin from the origin group if origin responds with the cases specified in `proxy_next_upstream`. If you enable it, you must specify cases in `proxy_next_upstream`.  Possible values: - **true** - Option is enabled. - **false** - Option is disabled. (e.g. true)
  --proxy-next-upstream: list # Defines cases when the request should be passed on to the next origin.  Possible values: - **error** - an error occurred while establishing a connection with the origin, passing a request to it, or reading the response header - **timeout** - a timeout has occurred while establishing a connection with the origin, passing a request to it, or reading the response header - **`invalid_header`** - a origin returned an empty or invalid response - **`http_403`** - a origin returned a response with the code 403 - **`http_404`** - a origin returned a response with the code 404 - **`http_429`** - a origin returned a response with the code 429 - **`http_500`** - a origin returned a response with the code 500 - **`http_502`** - a origin returned a response with the code 502 - **`http_503`** - a origin returned a response with the code 503 - **`http_504`** - a origin returned a response with the code 504 (default: [error, timeout], e.g. [error, timeout, invalid_header, http_500, http_502, http_503, http_504])
  --auth-type: string # **Deprecated.** No longer necessary. Defaults to `none`.  Origin authentication type.  Possible values: - **none** - Used for public origins. - **awsSignatureV4** - Used for S3 storage. (DEPRECATED, default: none, e.g. none)
  --sources: list # e.g. [{enabled: true, source: yourdomain.com, backup: false}]
  --path: string # **Deprecated.** No longer necessary. Omit this field and the default origin path behavior will be used.  Origin path prefix. (DEPRECATED, e.g. )
  --body-auth: record # **Deprecated.** To create S3 origins, configure them directly in sources with `origin_type` and `config` instead.  Credentials to access the private bucket. (DEPRECATED, e.g. {s3_type: amazon, s3_access_key_id: EXAMPLEFODNN7EXAMPLE, s3_secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY, s3_bucket_name: bucket_name, s3_region: us-east-2}) — shape: {s3_type: string, s3_access_key_id: string, s3_secret_access_key: string, s3_bucket_name: string, s3_storage_hostname?: string, s3_region?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/origin_groups/($origin_group_id)")
  let body = {name: $name, use_next: $use_next, proxy_next_upstream: $proxy_next_upstream, auth_type: $auth_type, sources: $sources, path: $path, auth: $body_auth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change origin group
#
# PATCH /cdn/origin_groups/{origin_group_id}
# operationId: patch-origin-group
# --auth shape: {s3_type: string, s3_access_key_id: string, s3_secret_access_key: string, s3_bucket_name: string, s3_storage_hostname?: string, s3_region?: string}
@deprecated --flag auth-type
@deprecated --flag path
@deprecated --flag body-auth
export def "cdn-origin-groups patch-origin-group" [
  origin_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Origin group name. (e.g. YourOriginGroup)
  --use-next: string@bool-completer # Defines whether to use the next origin from the origin group if origin responds with the cases specified in `proxy_next_upstream`. If you enable it, you must specify cases in `proxy_next_upstream`.  Possible values: - **true** - Option is enabled. - **false** - Option is disabled. (e.g. true)
  --proxy-next-upstream: list # Defines cases when the request should be passed on to the next origin.  Possible values: - **error** - an error occurred while establishing a connection with the origin, passing a request to it, or reading the response header - **timeout** - a timeout has occurred while establishing a connection with the origin, passing a request to it, or reading the response header - **`invalid_header`** - a origin returned an empty or invalid response - **`http_403`** - a origin returned a response with the code 403 - **`http_404`** - a origin returned a response with the code 404 - **`http_429`** - a origin returned a response with the code 429 - **`http_500`** - a origin returned a response with the code 500 - **`http_502`** - a origin returned a response with the code 502 - **`http_503`** - a origin returned a response with the code 503 - **`http_504`** - a origin returned a response with the code 504 (default: [error, timeout], e.g. [error, timeout, invalid_header, http_500, http_502, http_503, http_504])
  --auth-type: string # **Deprecated.** No longer necessary. Defaults to `none`.  Origin authentication type.  Possible values: - **none** - Used for public origins. - **awsSignatureV4** - Used for S3 storage. (DEPRECATED, default: none, e.g. none)
  --sources: list # e.g. [{enabled: true, source: yourdomain.com, backup: false}]
  --path: string # **Deprecated.** No longer necessary. Omit this field and the default origin path behavior will be used.  Origin path prefix. (DEPRECATED, e.g. )
  --body-auth: record # **Deprecated.** To create S3 origins, configure them directly in sources with `origin_type` and `config` instead.  Credentials to access the private bucket. (DEPRECATED, e.g. {s3_type: amazon, s3_access_key_id: EXAMPLEFODNN7EXAMPLE, s3_secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY, s3_bucket_name: bucket_name, s3_region: us-east-2}) — shape: {s3_type: string, s3_access_key_id: string, s3_secret_access_key: string, s3_bucket_name: string, s3_storage_hostname?: string, s3_region?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/origin_groups/($origin_group_id)")
  let body = {name: $name, use_next: $use_next, proxy_next_upstream: $proxy_next_upstream, auth_type: $auth_type, sources: $sources, path: $path, auth: $body_auth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete origin group
#
# DELETE /cdn/origin_groups/{origin_group_id}
# operationId: delete-origin-group
export def "cdn-origin-groups delete-origin-group" [
  origin_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/origin_groups/($origin_group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CDN resources list
#
# GET /cdn/resources
# operationId: get-cdn-resources-list
export def "cdn-resources get-cdn-resources-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleted: string@bool-completer # Defines whether a CDN resource has been deleted.  Possible values: - **true** - CDN resource has been deleted. - **false** - CDN resource has not been deleted.
  --enabled: string@bool-completer # Enables or disables a CDN resource change by a user.  Possible values: - **true** - CDN resource is enabled. - **false** - CDN resource is disabled.
  --originGroup: int # Origin group ID.
  --sslEnabled: string@bool-completer # Defines whether the HTTPS protocol is enabled for content delivery.  Possible values: - **true** - HTTPS protocol is enabled for CDN resource. - **false** - HTTPS protocol is disabled for CDN resource.
  --sslData: int # SSL certificate ID.
  --sslData-in: int # SSL certificates IDs.  Example: - ?`sslData_in`=1643,1644,1652
  --min-created: string # Earliest date of CDN resource creation for which CDN resources should be returned (ISO 8601/RFC 3339 format, UTC.)
  --max-created: string # Most recent date of CDN resource creation for which CDN resources should be returned (ISO 8601/RFC 3339 format, UTC.)
  --cname: string # Delivery domain (CNAME) of the CDN resource.
  --secondaryHostnames: string # Additional delivery domains (CNAMEs) of the CDN resource.
  --vp-enabled: string@bool-completer # Defines whether the CDN resource is integrated with the Streaming platform.  Possible values: - **true** - CDN resource is used for Streaming platform. - **false** - CDN resource is not used for Streaming platform.
  --rules: string # Rule name or pattern.
  --shielded: string@bool-completer # Defines whether origin shielding is enabled for the CDN resource.  Possible values: - **true** - Origin shielding is enabled for the CDN resource. - **false** - Origin shielding is disabled for the CDN resource.
  --shield-dc: string # Name of the origin shielding data center location.
  --suspend: string@bool-completer # Defines whether the CDN resource was automatically suspended by the system.  Possible values: - **true** - CDN resource is selected for automatic suspension in the next 7 days. - **false** - CDN resource is not selected for automatic suspension.
  --status: string@status-completer # CDN resource status.
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleted" $deleted "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "originGroup" $originGroup "scalar") (serialize-qp "sslEnabled" $sslEnabled "scalar") (serialize-qp "sslData" $sslData "scalar") (serialize-qp "sslData_in" $sslData_in "scalar") (serialize-qp "min_created" $min_created "scalar") (serialize-qp "max_created" $max_created "scalar") (serialize-qp "cname" $cname "scalar") (serialize-qp "secondaryHostnames" $secondaryHostnames "scalar") (serialize-qp "vp_enabled" $vp_enabled "scalar") (serialize-qp "rules" $rules "scalar") (serialize-qp "shielded" $shielded "scalar") (serialize-qp "shield_dc" $shield_dc "scalar") (serialize-qp "suspend" $suspend "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create CDN resource
#
# POST /cdn/resources
# operationId: create-cdn-resource
# --options shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, grpc_passthrough?: record, gzipOn?: record, hostHeader?: record, http3_enabled?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, network_error_logging?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, tls_versions?: record, use_default_le_chain?: record, use_dns01_le_challenge?: record, use_rsa_le_cert?: record, user_agent_acl?: record, waap?: record, websockets?: record}
export def "cdn-resources create-cdn-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  cname: string # Delivery domains that will be used for content delivery through a CDN.  Delivery domains should be added to your DNS settings. (e.g. cdn.site.com)
  --originGroup: int # Origin group ID with which the CDN resource is associated.  Exactly one of `origin` or `originGroup` must be provided during resource creation. (e.g. 132)
  --origin: string # IP address or domain name of the origin and the port, if custom port is used.  Exactly one of `origin` or `originGroup` must be provided during resource creation. (e.g. example.com)
  --active: string@bool-completer # Enables or disables a CDN resource.  Possible values: - **true** - CDN resource is active. Content is being delivered. - **false** - CDN resource is deactivated. Content is not being delivered. (default: true, e.g. true)
  --originProtocol: string@originProtocol-completer # Protocol used by CDN servers to request content from an origin source.  Possible values: - **HTTPS** - CDN servers will connect to the origin via HTTPS. - **HTTP** - CDN servers will connect to the origin via HTTP. - **MATCH** - connection protocol will be chosen automatically (content on the origin source should be available for the CDN both through HTTP and HTTPS).  If protocol is not specified, HTTP is used to connect to an origin server. (default: HTTP, e.g. HTTPS)
  --name: string # CDN resource name. (nullable, e.g. Resource for images)
  --description: string # Optional comment describing the CDN resource. (e.g. My resource)
  --secondaryHostnames: list # Additional delivery domains (CNAMEs) that will be used to deliver content via the CDN.  Up to ten additional CNAMEs are possible. (e.g. [first.example.com, second.example.com])
  --sslEnabled: string@bool-completer # Defines whether the HTTPS protocol enabled for content delivery.  Possible values: - **true** - HTTPS is enabled. - **false** - HTTPS is disabled. (default: false, e.g. false)
  --sslData: int # ID of the SSL certificate linked to the CDN resource.  Can be used only with `"sslEnabled": true`. (nullable, e.g. 192)
  --proxy-ssl-enabled: string@bool-completer # Enables or disables SSL certificate validation of the origin server before completing any connection.  Possible values: - **true** - Origin SSL certificate validation is enabled. - **false** - Origin SSL certificate validation is disabled. (default: false, e.g. false)
  --proxy-ssl-ca: int # ID of the trusted CA certificate used to verify an origin.  It can be used only with `"proxy_ssl_enabled": true`. (nullable)
  --proxy-ssl-data: int # ID of the SSL certificate used to verify an origin.  It can be used only with `"proxy_ssl_enabled": true`. (nullable)
  --primary-resource: int # ID of the main CDN resource which has a shared caching zone with a reserve CDN resource.  If the parameter is not empty, then the current CDN resource is the reserve. You cannot change some options, create rules, set up origin shielding, or use the reserve CDN resource for Streaming. (nullable)
  --waap-api-domain-enabled: string@bool-completer # Defines whether the associated WAAP Domain is identified as an API Domain.  Possible values: - **true** - The associated WAAP Domain is designated as an API Domain. - **false** - The associated WAAP Domain is not designated as an API Domain.
  --options: record # List of options that can be configured for the CDN resource.  In case of `null` value the option is not added to the CDN resource. Option may inherit its value from the global account settings. — shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, grpc_passthrough?: record, gzipOn?: record, hostHeader?: record, http3_enabled?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, network_error_logging?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, tls_versions?: record, use_default_le_chain?: record, use_dns01_le_challenge?: record, use_rsa_le_cert?: record, user_agent_acl?: record, waap?: record, websockets?: record}
]: any -> record<id: int, cname: string, active: bool, enabled: bool, status: string, deleted: bool, client: int, name: string, description: string, created: string, updated: string, originGroup: int, originGroup_name: string, originProtocol: string, secondaryHostnames: list<string>, shielded: bool, shield_dc: string, shield_enabled: bool, shield_routing_map: int, sslEnabled: bool, sslData: int, proxy_ssl_enabled: bool, proxy_ssl_ca: int, proxy_ssl_data: int, preset_applied: bool, vp_enabled: bool, full_custom_enabled: bool, can_purge_by_urls: bool, suspend_date: string, suspended: bool, primary_resource: int, is_primary: bool, waap_domain_id: string, rules: list<record>, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, grpc_passthrough: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, http3_enabled: record<enabled: bool, value: bool>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, network_error_logging: record<enabled: bool, value: bool>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, tls_versions: record<enabled: bool, value: list>, use_default_le_chain: record<enabled: bool, value: bool>, use_dns01_le_challenge: record<enabled: bool, value: bool>, use_rsa_le_cert: record<enabled: bool, value: bool>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/resources")
  let body = {cname: $cname, originGroup: $originGroup, origin: $origin, active: $active, originProtocol: $originProtocol, name: $name, description: $description, secondaryHostnames: $secondaryHostnames, sslEnabled: $sslEnabled, sslData: $sslData, proxy_ssl_enabled: $proxy_ssl_enabled, proxy_ssl_ca: $proxy_ssl_ca, proxy_ssl_data: $proxy_ssl_data, primary_resource: $primary_resource, waap_api_domain_enabled: $waap_api_domain_enabled, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get CDN resource details
#
# GET /cdn/resources/{resource_id}
# operationId: get-cdn-resource-details
export def "cdn-resources get-cdn-resource-details" [
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, cname: string, active: bool, enabled: bool, status: string, deleted: bool, client: int, name: string, description: string, created: string, updated: string, originGroup: int, originGroup_name: string, originProtocol: string, secondaryHostnames: list<string>, shielded: bool, shield_dc: string, shield_enabled: bool, shield_routing_map: int, sslEnabled: bool, sslData: int, proxy_ssl_enabled: bool, proxy_ssl_ca: int, proxy_ssl_data: int, preset_applied: bool, vp_enabled: bool, full_custom_enabled: bool, can_purge_by_urls: bool, suspend_date: string, suspended: bool, primary_resource: int, is_primary: bool, waap_domain_id: string, rules: list<record>, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, grpc_passthrough: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, http3_enabled: record<enabled: bool, value: bool>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, network_error_logging: record<enabled: bool, value: bool>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, tls_versions: record<enabled: bool, value: list>, use_default_le_chain: record<enabled: bool, value: bool>, use_dns01_le_challenge: record<enabled: bool, value: bool>, use_rsa_le_cert: record<enabled: bool, value: bool>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change CDN resource
#
# PUT /cdn/resources/{resource_id}
# operationId: change-cdn-resource
# --options shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, grpc_passthrough?: record, gzipOn?: record, hostHeader?: record, http3_enabled?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, network_error_logging?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, tls_versions?: record, use_default_le_chain?: record, use_dns01_le_challenge?: record, use_rsa_le_cert?: record, user_agent_acl?: record, waap?: record, websockets?: record}
export def "cdn-resources change-cdn-resource" [
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Enables or disables a CDN resource.  Possible values: - **true** - CDN resource is active. Content is being delivered. - **false** - CDN resource is deactivated. Content is not being delivered. (default: true, e.g. true)
  --name: string # CDN resource name. (nullable, e.g. Resource for images)
  --description: string # Optional comment describing the CDN resource. (e.g. My resource)
  --secondaryHostnames: list # Additional delivery domains (CNAMEs) that will be used to deliver content via the CDN.  Up to ten additional CNAMEs are possible. (e.g. [first.example.com, second.example.com])
  originGroup: int # Origin group ID with which the CDN resource is associated. (e.g. 132)
  --originProtocol: string@originProtocol-completer # Protocol used by CDN servers to request content from an origin source.  Possible values: - **HTTPS** - CDN servers will connect to the origin via HTTPS. - **HTTP** - CDN servers will connect to the origin via HTTP. - **MATCH** - connection protocol will be chosen automatically (content on the origin source should be available for the CDN both through HTTP and HTTPS).  If protocol is not specified, HTTP is used to connect to an origin server. (default: HTTP, e.g. HTTPS)
  --sslEnabled: string@bool-completer # Defines whether the HTTPS protocol enabled for content delivery.  Possible values: - **true** - HTTPS is enabled. - **false** - HTTPS is disabled. (default: false, e.g. false)
  --sslData: int # ID of the SSL certificate linked to the CDN resource.  Can be used only with `"sslEnabled": true`. (nullable, e.g. 192)
  --proxy-ssl-enabled: string@bool-completer # Enables or disables SSL certificate validation of the origin server before completing any connection.  Possible values: - **true** - Origin SSL certificate validation is enabled. - **false** - Origin SSL certificate validation is disabled. (default: false, e.g. false)
  --proxy-ssl-ca: int # ID of the trusted CA certificate used to verify an origin.  It can be used only with `"proxy_ssl_enabled": true`. (nullable)
  --proxy-ssl-data: int # ID of the SSL certificate used to verify an origin.  It can be used only with `"proxy_ssl_enabled": true`. (nullable)
  --waap-api-domain-enabled: string@bool-completer # Defines whether the associated WAAP Domain is identified as an API Domain.  Possible values: - **true** - The associated WAAP Domain is designated as an API Domain. - **false** - The associated WAAP Domain is not designated as an API Domain.
  --options: record # List of options that can be configured for the CDN resource.  In case of `null` value the option is not added to the CDN resource. Option may inherit its value from the global account settings. — shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, grpc_passthrough?: record, gzipOn?: record, hostHeader?: record, http3_enabled?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, network_error_logging?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, tls_versions?: record, use_default_le_chain?: record, use_dns01_le_challenge?: record, use_rsa_le_cert?: record, user_agent_acl?: record, waap?: record, websockets?: record}
]: any -> record<id: int, cname: string, active: bool, enabled: bool, status: string, deleted: bool, client: int, name: string, description: string, created: string, updated: string, originGroup: int, originGroup_name: string, originProtocol: string, secondaryHostnames: list<string>, shielded: bool, shield_dc: string, shield_enabled: bool, shield_routing_map: int, sslEnabled: bool, sslData: int, proxy_ssl_enabled: bool, proxy_ssl_ca: int, proxy_ssl_data: int, preset_applied: bool, vp_enabled: bool, full_custom_enabled: bool, can_purge_by_urls: bool, suspend_date: string, suspended: bool, primary_resource: int, is_primary: bool, waap_domain_id: string, rules: list<record>, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, grpc_passthrough: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, http3_enabled: record<enabled: bool, value: bool>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, network_error_logging: record<enabled: bool, value: bool>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, tls_versions: record<enabled: bool, value: list>, use_default_le_chain: record<enabled: bool, value: bool>, use_dns01_le_challenge: record<enabled: bool, value: bool>, use_rsa_le_cert: record<enabled: bool, value: bool>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)")
  let body = {active: $active, name: $name, description: $description, secondaryHostnames: $secondaryHostnames, originGroup: $originGroup, originProtocol: $originProtocol, sslEnabled: $sslEnabled, sslData: $sslData, proxy_ssl_enabled: $proxy_ssl_enabled, proxy_ssl_ca: $proxy_ssl_ca, proxy_ssl_data: $proxy_ssl_data, waap_api_domain_enabled: $waap_api_domain_enabled, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change CDN resource
#
# PATCH /cdn/resources/{resource_id}
# operationId: patch-cdn-resource
# --options shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, grpc_passthrough?: record, gzipOn?: record, hostHeader?: record, http3_enabled?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, network_error_logging?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, tls_versions?: record, use_default_le_chain?: record, use_dns01_le_challenge?: record, use_rsa_le_cert?: record, user_agent_acl?: record, waap?: record, websockets?: record}
export def "cdn-resources patch-cdn-resource" [
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Enables or disables a CDN resource.  Possible values: - **true** - CDN resource is active. Content is being delivered. - **false** - CDN resource is deactivated. Content is not being delivered. (default: true, e.g. true)
  --name: string # CDN resource name. (nullable, e.g. Resource for images)
  --description: string # Optional comment describing the CDN resource. (e.g. My resource)
  --secondaryHostnames: list # Additional delivery domains (CNAMEs) that will be used to deliver content via the CDN.  Up to ten additional CNAMEs are possible. (e.g. [first.example.com, second.example.com])
  --originGroup: int # Origin group ID with which the CDN resource is associated. (e.g. 132)
  --originProtocol: string@originProtocol-completer # Protocol used by CDN servers to request content from an origin source.  Possible values: - **HTTPS** - CDN servers will connect to the origin via HTTPS. - **HTTP** - CDN servers will connect to the origin via HTTP. - **MATCH** - connection protocol will be chosen automatically (content on the origin source should be available for the CDN both through HTTP and HTTPS).  If protocol is not specified, HTTP is used to connect to an origin server. (default: HTTP, e.g. HTTPS)
  --sslEnabled: string@bool-completer # Defines whether the HTTPS protocol enabled for content delivery.  Possible values: - **true** - HTTPS is enabled. - **false** - HTTPS is disabled. (default: false, e.g. false)
  --sslData: int # ID of the SSL certificate linked to the CDN resource.  Can be used only with `"sslEnabled": true`. (nullable, e.g. 192)
  --proxy-ssl-enabled: string@bool-completer # Enables or disables SSL certificate validation of the origin server before completing any connection.  Possible values: - **true** - Origin SSL certificate validation is enabled. - **false** - Origin SSL certificate validation is disabled. (default: false, e.g. false)
  --proxy-ssl-ca: int # ID of the trusted CA certificate used to verify an origin.  It can be used only with `"proxy_ssl_enabled": true`. (nullable)
  --proxy-ssl-data: int # ID of the SSL certificate used to verify an origin.  It can be used only with `"proxy_ssl_enabled": true`. (nullable)
  --options: record # List of options that can be configured for the CDN resource.  In case of `null` value the option is not added to the CDN resource. Option may inherit its value from the global account settings. — shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, grpc_passthrough?: record, gzipOn?: record, hostHeader?: record, http3_enabled?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, network_error_logging?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, tls_versions?: record, use_default_le_chain?: record, use_dns01_le_challenge?: record, use_rsa_le_cert?: record, user_agent_acl?: record, waap?: record, websockets?: record}
]: any -> record<id: int, cname: string, active: bool, enabled: bool, status: string, deleted: bool, client: int, name: string, description: string, created: string, updated: string, originGroup: int, originGroup_name: string, originProtocol: string, secondaryHostnames: list<string>, shielded: bool, shield_dc: string, shield_enabled: bool, shield_routing_map: int, sslEnabled: bool, sslData: int, proxy_ssl_enabled: bool, proxy_ssl_ca: int, proxy_ssl_data: int, preset_applied: bool, vp_enabled: bool, full_custom_enabled: bool, can_purge_by_urls: bool, suspend_date: string, suspended: bool, primary_resource: int, is_primary: bool, waap_domain_id: string, rules: list<record>, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, grpc_passthrough: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, http3_enabled: record<enabled: bool, value: bool>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, network_error_logging: record<enabled: bool, value: bool>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, tls_versions: record<enabled: bool, value: list>, use_default_le_chain: record<enabled: bool, value: bool>, use_dns01_le_challenge: record<enabled: bool, value: bool>, use_rsa_le_cert: record<enabled: bool, value: bool>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)")
  let body = {active: $active, name: $name, description: $description, secondaryHostnames: $secondaryHostnames, originGroup: $originGroup, originProtocol: $originProtocol, sslEnabled: $sslEnabled, sslData: $sslData, proxy_ssl_enabled: $proxy_ssl_enabled, proxy_ssl_ca: $proxy_ssl_ca, proxy_ssl_data: $proxy_ssl_data, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete CDN resource
#
# DELETE /cdn/resources/{resource_id}
# operationId: delete-cdn-resource
export def "cdn-resources delete-cdn-resource" [
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CDN activity logs
#
# GET /cdn/activity_log/requests
# operationId: get-activity-logs
export def "cdn-activity-log-requests get-activity-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # Exact URL path.
  --user-id: int # User ID.
  --token-id: int # Permanent API token ID. Requests made with this token should be displayed.
  --client-id: int # Client ID.
  --method: string # HTTP method type of requests.  Use upper case only.  Example: - ?method=DELETE
  --min-requested-at: string # Beginning of the requested time period (ISO 8601/RFC 3339 format, UTC.)  You can specify a date with a time separated by a space, or just a date.  Examples: - &`min_requested_at`=2021-05-05 12:00:00 - &`min_requested_at`=2021-05-05
  --max-requested-at: string # End of the requested time period (ISO 8601/RFC 3339 format, UTC.)  You can specify a date with a time separated by a space, or just a date.  Examples: - &`max_requested_at`=2021-05-05 12:00:00 - &`max_requested_at`=2021-05-05
  --remote-ip-address: string # Exact IP address from which requests are sent.
  --status-code: int # Status code returned in the response.  Specify the first numbers of a status code to get requests for a group of status codes.  To filter the activity logs by 4xx codes, use: - &`status_code`=4 -
  --limit: int # Maximum number of items in response.
  --offset: int # Offset relative to the beginning of activity logs.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "token_id" $token_id "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "min_requested_at" $min_requested_at "scalar") (serialize-qp "max_requested_at" $max_requested_at "scalar") (serialize-qp "remote_ip_address" $remote_ip_address "scalar") (serialize-qp "status_code" $status_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/activity_log/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CDN activity logs details
#
# GET /cdn/activity_log/requests/{log_id}
# operationId: get-activity-logs-details
export def "cdn-activity-log-requests get-activity-logs-details" [
  log_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/activity_log/requests/($log_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CDN logs
#
# GET /cdn/advanced/v1/logs
# operationId: get-cdn-logs
export def "cdn-advanced-logs get-cdn-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date and time of the requested time period (ISO 8601/RFC 3339 format, UTC.)  Difference between "from" and "to" cannot exceed 6 hours.  Examples: - &from=2021-06-14T00:00:00Z - &from=2021-06-14T00:00:00.000Z
  --qp-to: string # End date and time of the requested time period (ISO 8601/RFC 3339 format, UTC.)  Difference between "from" and "to" cannot exceed 6 hours.  Examples: - &to=2021-06-15T00:00:00Z - &to=2021-06-15T00:00:00.000Z
  --offset: int # Number of log records to skip starting from the beginning of the requested period. (default: 0)
  --limit: int # Maximum number of log records in the response. (default: 100)
  --ordering: string # Sorting rules.  Possible values: - **method** - Request HTTP method. - **`client_ip`** - IP address of the client who sent the request. - **status** - Status code in the response. - **size** - Response size in bytes. - **cname** - Custom domain of the requested resource. - **`resource_id`** - ID of the requested CDN resource. - **`cache_status`** - Caching status. - **datacenter** - Data center where request was processed. - **timestamp** - Date and time when the request was made.  Parameter may have multiple values separated by a comma.  By default, ascending sorting is applied. To sort in descending order, add '-' prefix.  Example: - &ordering=-timestamp,status
  --qp-fields: string # A comma-separated list of returned fields.  Supported fields are presented in the responses section.  Example: - &fields=timestamp,path,status (default: timestamp,path,method,referer,user_agent,client_ip,status,size,cname,resource_id,cache_status,datacenter,sent_http_content_type,tcpinfo_rtt)
  --method-eq: string # Request HTTP method. Possible values: 'CONNECT', 'DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT', 'TRACE'.
  --method-ne: string # Request HTTP method. Possible values: 'CONNECT', 'DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT', 'TRACE'.
  --method-in: string # Request HTTP method. Possible values: 'CONNECT', 'DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT', 'TRACE'. Values should be separated by a comma.
  --method-not-in: string # Request HTTP method. Possible values: 'CONNECT', 'DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT', 'TRACE'. Values should be separated by a comma.
  --client-ip-eq: string # IP address of the client who sent the request.
  --client-ip-ne: string # IP address of the client who did not send the request.
  --client-ip-in: string # List of IP addresses of the clients who sent the request.
  --client-ip-not-in: string # List of IP addresses of the clients who did not send the request.
  --status-gt: int # Status code in the response greater than the specified value.
  --status-gte: int # Status code in the response greater than or equal to the specified value.
  --status-lt: int # Status code in the response less than the specified value.
  --status-lte: int # Status code in the response less than or equal to the specified value.
  --status-eq: int # Status code in the response equal to the specified value.
  --status-ne: int # Status code in the response not equal to the specified value.
  --status-in: string # List of status codes in the response. Values should be separated by a comma.
  --status-not-in: string # List of status codes not in the response. Values should be separated by a comma.
  --size-gt: int # Response size in bytes greater than the specified value.
  --size-gte: int # Response size in bytes greater than or equal to the specified value.
  --size-lt: int # Response size in bytes less than the specified value.
  --size-lte: int # Response size in bytes less than or equal to the specified value.
  --size-eq: int # Response size in bytes equal to the specified value.
  --size-ne: int # Response size in bytes not equal to the specified value.
  --size-in: string # List of response sizes in bytes. Values should be separated by a comma.
  --size-not-in: string # List of response sizes in bytes not equal to the specified values. Values should be separated by
  --cname-eq: string # Custom domain of the requested CDN resource.
  --cname-ne: string # Custom domain of the requested CDN resource not equal to the specified value.
  --cname-in: string # List of custom domains of the requested CDN resource. Values should be separated by a comma.
  --cname-not-in: string # List of custom domains of the requested CDN resource not equal to the specified values. Values should be separated by a comma.
  --cname-contains: string # Part of the custom domain of the requested CDN resource. Minimum length is 3 characters.
  --resource-id-gt: int # ID of the requested CDN resource greater than the specified value.
  --resource-id-gte: int # ID of the requested CDN resource greater than or equal to the specified value.
  --resource-id-lt: int # ID of the requested CDN resource less than the specified value.
  --resource-id-lte: int # ID of the requested CDN resource less than or equal to the specified value.
  --resource-id-eq: int # ID of the requested CDN resource equal to the specified value.
  --resource-id-ne: int # ID of the requested CDN resource not equal to the specified value.
  --resource-id-in: string # List of IDs of the requested CDN resource. Values should be separated by a comma.
  --resource-id-not-in: string # List of IDs of the requested CDN resource not equal to the specified values. Values should be separated by a comma.
  --cache-status-eq: string # Caching status. Possible values: 'MISS', 'BYPASS', 'EXPIRED', 'STALE', 'PENDING', 'UPDATING', 'REVALIDATED', 'HIT', '-'.
  --cache-status-ne: string # Caching status not equal to the specified value. Possible values: 'MISS', 'BYPASS', 'EXPIRED', 'STALE', 'PENDING', 'UPDATING', 'REVALIDATED', 'HIT', '-'.
  --cache-status-in: string # List of caching statuses. Possible values: 'MISS', 'BYPASS', 'EXPIRED', 'STALE', 'PENDING', 'UPDATING', 'REVALIDATED', 'HIT', '-'. Values should be separated by a comma.
  --cache-status-not-in: string # List of caching statuses not equal to the specified values. Possible values: 'MISS', 'BYPASS', 'EXPIRED', 'STALE', 'PENDING', 'UPDATING', 'REVALIDATED', 'HIT', '-'. Values should be separated by a comma.
  --datacenter-eq: string # Data center where request was processed.
  --datacenter-ne: string # Data center where request was not processed.
  --datacenter-in: string # List of data centers where request was processed. Values should be separated by a comma.
  --datacenter-not-in: string # List of data centers where request was not processed. Values should be separated by a comma.
]: nothing -> record<data: table<timestamp: int, client_ip: string, cname: string, resource_id: int, path: string, method: string, user_agent: string, status: int, size: int, cache_status: string, datacenter: string, referer: string, sent_http_content_type: string, tcpinfo_rtt: int>, meta: record<count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "method__eq" $method_eq "scalar") (serialize-qp "method__ne" $method_ne "scalar") (serialize-qp "method__in" $method_in "scalar") (serialize-qp "method__not_in" $method_not_in "scalar") (serialize-qp "client_ip__eq" $client_ip_eq "scalar") (serialize-qp "client_ip__ne" $client_ip_ne "scalar") (serialize-qp "client_ip__in" $client_ip_in "scalar") (serialize-qp "client_ip__not_in" $client_ip_not_in "scalar") (serialize-qp "status__gt" $status_gt "scalar") (serialize-qp "status__gte" $status_gte "scalar") (serialize-qp "status__lt" $status_lt "scalar") (serialize-qp "status__lte" $status_lte "scalar") (serialize-qp "status__eq" $status_eq "scalar") (serialize-qp "status__ne" $status_ne "scalar") (serialize-qp "status__in" $status_in "scalar") (serialize-qp "status__not_in" $status_not_in "scalar") (serialize-qp "size__gt" $size_gt "scalar") (serialize-qp "size__gte" $size_gte "scalar") (serialize-qp "size__lt" $size_lt "scalar") (serialize-qp "size__lte" $size_lte "scalar") (serialize-qp "size__eq" $size_eq "scalar") (serialize-qp "size__ne" $size_ne "scalar") (serialize-qp "size__in" $size_in "scalar") (serialize-qp "size__not_in" $size_not_in "scalar") (serialize-qp "cname__eq" $cname_eq "scalar") (serialize-qp "cname__ne" $cname_ne "scalar") (serialize-qp "cname__in" $cname_in "scalar") (serialize-qp "cname__not_in" $cname_not_in "scalar") (serialize-qp "cname__contains" $cname_contains "scalar") (serialize-qp "resource_id__gt" $resource_id_gt "scalar") (serialize-qp "resource_id__gte" $resource_id_gte "scalar") (serialize-qp "resource_id__lt" $resource_id_lt "scalar") (serialize-qp "resource_id__lte" $resource_id_lte "scalar") (serialize-qp "resource_id__eq" $resource_id_eq "scalar") (serialize-qp "resource_id__ne" $resource_id_ne "scalar") (serialize-qp "resource_id__in" $resource_id_in "scalar") (serialize-qp "resource_id__not_in" $resource_id_not_in "scalar") (serialize-qp "cache_status__eq" $cache_status_eq "scalar") (serialize-qp "cache_status__ne" $cache_status_ne "scalar") (serialize-qp "cache_status__in" $cache_status_in "scalar") (serialize-qp "cache_status__not_in" $cache_status_not_in "scalar") (serialize-qp "datacenter__eq" $datacenter_eq "scalar") (serialize-qp "datacenter__ne" $datacenter_ne "scalar") (serialize-qp "datacenter__in" $datacenter_in "scalar") (serialize-qp "datacenter__not_in" $datacenter_not_in "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/advanced/v1/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download CDN logs
#
# GET /cdn/advanced/v1/logs/download
# operationId: download-cdn-logs
export def "cdn-advanced-logs-download download-cdn-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date and time of the requested time period (ISO 8601/RFC 3339 format, UTC.)  Difference between "from" and "to" cannot exceed 6 hours.  Examples: - &from=2021-06-14T00:00:00Z - &from=2021-06-14T00:00:00.000Z
  --qp-to: string # End date and time of the requested time period (ISO 8601/RFC 3339 format, UTC.)  Difference between "from" and "to" cannot exceed 6 hours.  Examples: - &to=2021-06-15T00:00:00Z - &to=2021-06-15T00:00:00.000Z
  --offset: int # Number of log records to skip starting from the beginning of the requested period. (default: 0)
  --limit: int # Maximum number of log records in the response. (default: 10000)
  --method-eq: string # Request HTTP method. Possible values: 'CONNECT', 'DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT', 'TRACE'.
  --method-ne: string # Request HTTP method. Possible values: 'CONNECT', 'DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT', 'TRACE'.
  --method-in: string # Request HTTP method. Possible values: 'CONNECT', 'DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT', 'TRACE'. Values should be separated by a comma.
  --method-not-in: string # Request HTTP method. Possible values: 'CONNECT', 'DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT', 'TRACE'. Values should be separated by a comma.
  --client-ip-eq: string # IP address of the client who sent the request.
  --client-ip-ne: string # IP address of the client who did not send the request.
  --client-ip-in: string # List of IP addresses of the clients who sent the request.
  --client-ip-not-in: string # List of IP addresses of the clients who did not send the request.
  --status-gt: int # Status code in the response greater than the specified value.
  --status-gte: int # Status code in the response greater than or equal to the specified value.
  --status-lt: int # Status code in the response less than the specified value.
  --status-lte: int # Status code in the response less than or equal to the specified value.
  --status-eq: int # Status code in the response equal to the specified value.
  --status-ne: int # Status code in the response not equal to the specified value.
  --status-in: string # List of status codes in the response. Values should be separated by a comma.
  --status-not-in: string # List of status codes not in the response. Values should be separated by a comma.
  --size-gt: int # Response size in bytes greater than the specified value.
  --size-gte: int # Response size in bytes greater than or equal to the specified value.
  --size-lt: int # Response size in bytes less than the specified value.
  --size-lte: int # Response size in bytes less than or equal to the specified value.
  --size-eq: int # Response size in bytes equal to the specified value.
  --size-ne: int # Response size in bytes not equal to the specified value.
  --size-in: string # List of response sizes in bytes. Values should be separated by a comma.
  --size-not-in: string # List of response sizes in bytes not equal to the specified values. Values should be separated by
  --cname-eq: string # Custom domain of the requested CDN resource.
  --cname-ne: string # Custom domain of the requested CDN resource not equal to the specified value.
  --cname-in: string # List of custom domains of the requested CDN resource. Values should be separated by a comma.
  --cname-not-in: string # List of custom domains of the requested CDN resource not equal to the specified values. Values should be separated by a comma.
  --cname-contains: string # Part of the custom domain of the requested CDN resource. Minimum length is 3 characters.
  --resource-id-gt: int # ID of the requested CDN resource greater than the specified value.
  --resource-id-gte: int # ID of the requested CDN resource greater than or equal to the specified value.
  --resource-id-lt: int # ID of the requested CDN resource less than the specified value.
  --resource-id-lte: int # ID of the requested CDN resource less than or equal to the specified value.
  --resource-id-eq: int # ID of the requested CDN resource equal to the specified value.
  --resource-id-ne: int # ID of the requested CDN resource not equal to the specified value.
  --resource-id-in: string # List of IDs of the requested CDN resource. Values should be separated by a comma.
  --resource-id-not-in: string # List of IDs of the requested CDN resource not equal to the specified values. Values should be separated by a comma.
  --cache-status-eq: string # Caching status. Possible values: 'MISS', 'BYPASS', 'EXPIRED', 'STALE', 'PENDING', 'UPDATING', 'REVALIDATED', 'HIT', '-'.
  --cache-status-ne: string # Caching status not equal to the specified value. Possible values: 'MISS', 'BYPASS', 'EXPIRED', 'STALE', 'PENDING', 'UPDATING', 'REVALIDATED', 'HIT', '-'.
  --cache-status-in: string # List of caching statuses. Possible values: 'MISS', 'BYPASS', 'EXPIRED', 'STALE', 'PENDING', 'UPDATING', 'REVALIDATED', 'HIT', '-'. Values should be separated by a comma.
  --cache-status-not-in: string # List of caching statuses not equal to the specified values. Possible values: 'MISS', 'BYPASS', 'EXPIRED', 'STALE', 'PENDING', 'UPDATING', 'REVALIDATED', 'HIT', '-'. Values should be separated by a comma.
  --datacenter-eq: string # Data center where request was processed.
  --datacenter-ne: string # Data center where request was not processed.
  --datacenter-in: string # List of data centers where request was processed. Values should be separated by a comma.
  --datacenter-not-in: string # List of data centers where request was not processed. Values should be separated by a comma.
  --qp-sort: string # Sorting rules.  Possible values: - **method** - Request HTTP method. - **`client_ip`** - IP address of the client who sent the request. - **status** - Status code in the response. - **size** - Response size in bytes. - **cname** - Custom domain of the requested resource. - **`resource_id`** - ID of the requested CDN resource. - **`cache_status`** - Caching status. - **datacenter** - Data center where request was processed. - **timestamp** - Date and time when the request was made.  May include multiple values separated by a comma.  Example: - &sort=-timestamp,status
  --qp-fields: string # A comma-separated list of returned fields.  Supported fields are presented in the responses section.  Example: - &fields=timestamp,path,status (default: timestamp,path,method,referer,user_agent,client_ip,status,size,cname,resource_id,cache_status,datacenter)
  --format: string # Output format.  Possible values: - csv - tsv
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "method__eq" $method_eq "scalar") (serialize-qp "method__ne" $method_ne "scalar") (serialize-qp "method__in" $method_in "scalar") (serialize-qp "method__not_in" $method_not_in "scalar") (serialize-qp "client_ip__eq" $client_ip_eq "scalar") (serialize-qp "client_ip__ne" $client_ip_ne "scalar") (serialize-qp "client_ip__in" $client_ip_in "scalar") (serialize-qp "client_ip__not_in" $client_ip_not_in "scalar") (serialize-qp "status__gt" $status_gt "scalar") (serialize-qp "status__gte" $status_gte "scalar") (serialize-qp "status__lt" $status_lt "scalar") (serialize-qp "status__lte" $status_lte "scalar") (serialize-qp "status__eq" $status_eq "scalar") (serialize-qp "status__ne" $status_ne "scalar") (serialize-qp "status__in" $status_in "scalar") (serialize-qp "status__not_in" $status_not_in "scalar") (serialize-qp "size__gt" $size_gt "scalar") (serialize-qp "size__gte" $size_gte "scalar") (serialize-qp "size__lt" $size_lt "scalar") (serialize-qp "size__lte" $size_lte "scalar") (serialize-qp "size__eq" $size_eq "scalar") (serialize-qp "size__ne" $size_ne "scalar") (serialize-qp "size__in" $size_in "scalar") (serialize-qp "size__not_in" $size_not_in "scalar") (serialize-qp "cname__eq" $cname_eq "scalar") (serialize-qp "cname__ne" $cname_ne "scalar") (serialize-qp "cname__in" $cname_in "scalar") (serialize-qp "cname__not_in" $cname_not_in "scalar") (serialize-qp "cname__contains" $cname_contains "scalar") (serialize-qp "resource_id__gt" $resource_id_gt "scalar") (serialize-qp "resource_id__gte" $resource_id_gte "scalar") (serialize-qp "resource_id__lt" $resource_id_lt "scalar") (serialize-qp "resource_id__lte" $resource_id_lte "scalar") (serialize-qp "resource_id__eq" $resource_id_eq "scalar") (serialize-qp "resource_id__ne" $resource_id_ne "scalar") (serialize-qp "resource_id__in" $resource_id_in "scalar") (serialize-qp "resource_id__not_in" $resource_id_not_in "scalar") (serialize-qp "cache_status__eq" $cache_status_eq "scalar") (serialize-qp "cache_status__ne" $cache_status_ne "scalar") (serialize-qp "cache_status__in" $cache_status_in "scalar") (serialize-qp "cache_status__not_in" $cache_status_not_in "scalar") (serialize-qp "datacenter__eq" $datacenter_eq "scalar") (serialize-qp "datacenter__ne" $datacenter_ne "scalar") (serialize-qp "datacenter__in" $datacenter_in "scalar") (serialize-qp "datacenter__not_in" $datacenter_not_in "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/advanced/v1/logs/download" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get policies list
#
# GET /cdn/logs_uploader/policies
# operationId: get-policies-list
export def "cdn-logs-uploader-policies get-policies-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search by policy name or id.
  --config-ids: list # Filter by ids of related logs uploader configs that use given policy.
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "config_ids" $config_ids "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/logs_uploader/policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create policy
#
# POST /cdn/logs_uploader/policies
# operationId: create-policy
export def "cdn-logs-uploader-policies create-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-empty-logs: string@bool-completer # Include empty logs in the upload. (default: false)
  --include-shield-logs: string@bool-completer # Include logs from origin shielding in the upload. (default: false)
  --name: string # Name of the policy. (default: Policy)
  --description: string # Description of the policy.
  --retry-interval-minutes: int # Interval in minutes to retry failed uploads. (default: 60)
  --rotate-interval-minutes: int # Interval in minutes to rotate logs. (default: 5)
  --rotate-threshold-mb: int # Threshold in MB to rotate logs. (nullable)
  --rotate-threshold-lines: int # Threshold in lines to rotate logs. (default: 0)
  --date-format: string # Date format for logs.
  --field-delimiter: string # Field delimiter for logs. (default: ")
  --field-separator: string # Field separator for logs. (default:  )
  --body-fields: list # List of fields to include in logs. (default: [remote_addr, -, remote_user, time_local, request, status, body_bytes_sent, http_referer, http_user_agent, bytes_sent, hostname, scheme, host, request_time, upstream_response_time, request_length, http_range, dc, upstream_cache_status, upstream_response_length, upstream_addr, gcdn_api_client_id, gcdn_api_resource_id, uid_got, uid_set, geoip2_country_code, geoip2_city, shield_type, real_server_addr, server_port, upstream_status, -, upstream_connect_time, upstream_header_time, shard_addr, geoip2_data_asnumber, connection, connection_requests, http_traceparent, http_x_forwarded_proto, gcdn_internal_status_code, ssl_cipher, ssl_session_id, ssl_session_reused, sent_http_content_type, real_tcpinfo_rtt, server_country_code, gcdn_tcpinfo_snd_cwnd, gcdn_tcpinfo_total_retrans, gcdn_rule_id])
  --file-name-template: string # Template for log file name. (default: {{YYYY}}/{{MM}}/{{DD}}/{{HH}}/{{mm}}/{{ss}}/{{HOST}}_{{CNAME}}_access.log.gz)
  --format-type: string@format-type-completer # Format type for logs.  Possible values: - **""** - empty, it means it will apply the format configurations from the policy. - **"json"** - output the logs as json lines.
  --tags: record # Tags allow for dynamic decoration of logs by adding predefined fields to the log format. These tags serve as customizable key-value pairs that can be included in log entries to enhance context and readability.
  --escape-special-characters: string@bool-completer # When set to true, the service sanitizes string values by escaping characters that may be unsafe for transport, logging, or downstream processing.  The following categories of characters are escaped: - Control and non-printable characters - Quotation marks and escape characters - Characters outside the standard ASCII range  The resulting output contains only printable ASCII characters. (default: false)
  --log-sample-rate: float # Sampling rate for logs. A value between 0 and 1 that determines the fraction of log entries to collect.  - **1** - collect all logs (default). - **0.5** - collect approximately 50% of logs. - **0** - collect no logs (effectively disables logging without removing the policy). (format: float, default: 1)
]: any -> record<id: int, client_id: int, created: string, updated: string, include_empty_logs: bool, include_shield_logs: bool, name: string, description: string, retry_interval_minutes: int, rotate_interval_minutes: int, rotate_threshold_mb: int, rotate_threshold_lines: int, date_format: string, field_delimiter: string, field_separator: string, fields: list<string>, file_name_template: string, format_type: string, tags: record, escape_special_characters: bool, log_sample_rate: float, related_uploader_configs: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/logs_uploader/policies")
  let body = {include_empty_logs: $include_empty_logs, include_shield_logs: $include_shield_logs, name: $name, description: $description, retry_interval_minutes: $retry_interval_minutes, rotate_interval_minutes: $rotate_interval_minutes, rotate_threshold_mb: $rotate_threshold_mb, rotate_threshold_lines: $rotate_threshold_lines, date_format: $date_format, field_delimiter: $field_delimiter, field_separator: $field_separator, fields: $body_fields, file_name_template: $file_name_template, format_type: $format_type, tags: $tags, escape_special_characters: $escape_special_characters, log_sample_rate: $log_sample_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get policy details
#
# GET /cdn/logs_uploader/policies/{id}
# operationId: get-policy-details
export def "cdn-logs-uploader-policies get-policy-details" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, client_id: int, created: string, updated: string, include_empty_logs: bool, include_shield_logs: bool, name: string, description: string, retry_interval_minutes: int, rotate_interval_minutes: int, rotate_threshold_mb: int, rotate_threshold_lines: int, date_format: string, field_delimiter: string, field_separator: string, fields: list<string>, file_name_template: string, format_type: string, tags: record, escape_special_characters: bool, log_sample_rate: float, related_uploader_configs: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change policy
#
# PUT /cdn/logs_uploader/policies/{id}
# operationId: change-policy
export def "cdn-logs-uploader-policies change-policy" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-empty-logs: string@bool-completer # Include empty logs in the upload. (default: false)
  --include-shield-logs: string@bool-completer # Include logs from origin shielding in the upload. (default: false)
  --name: string # Name of the policy. (default: Policy)
  --description: string # Description of the policy.
  --retry-interval-minutes: int # Interval in minutes to retry failed uploads. (default: 60)
  --rotate-interval-minutes: int # Interval in minutes to rotate logs. (default: 5)
  --rotate-threshold-mb: int # Threshold in MB to rotate logs. (nullable)
  --rotate-threshold-lines: int # Threshold in lines to rotate logs. (default: 0)
  --date-format: string # Date format for logs.
  --field-delimiter: string # Field delimiter for logs. (default: ")
  --field-separator: string # Field separator for logs. (default:  )
  --body-fields: list # List of fields to include in logs. (default: [remote_addr, -, remote_user, time_local, request, status, body_bytes_sent, http_referer, http_user_agent, bytes_sent, hostname, scheme, host, request_time, upstream_response_time, request_length, http_range, dc, upstream_cache_status, upstream_response_length, upstream_addr, gcdn_api_client_id, gcdn_api_resource_id, uid_got, uid_set, geoip2_country_code, geoip2_city, shield_type, real_server_addr, server_port, upstream_status, -, upstream_connect_time, upstream_header_time, shard_addr, geoip2_data_asnumber, connection, connection_requests, http_traceparent, http_x_forwarded_proto, gcdn_internal_status_code, ssl_cipher, ssl_session_id, ssl_session_reused, sent_http_content_type, real_tcpinfo_rtt, server_country_code, gcdn_tcpinfo_snd_cwnd, gcdn_tcpinfo_total_retrans, gcdn_rule_id])
  --file-name-template: string # Template for log file name. (default: {{YYYY}}/{{MM}}/{{DD}}/{{HH}}/{{mm}}/{{ss}}/{{HOST}}_{{CNAME}}_access.log.gz)
  --format-type: string@format-type-completer # Format type for logs.  Possible values: - **""** - empty, it means it will apply the format configurations from the policy. - **"json"** - output the logs as json lines.
  --tags: record # Tags allow for dynamic decoration of logs by adding predefined fields to the log format. These tags serve as customizable key-value pairs that can be included in log entries to enhance context and readability.
  --escape-special-characters: string@bool-completer # When set to true, the service sanitizes string values by escaping characters that may be unsafe for transport, logging, or downstream processing.  The following categories of characters are escaped: - Control and non-printable characters - Quotation marks and escape characters - Characters outside the standard ASCII range  The resulting output contains only printable ASCII characters. (default: false)
  --log-sample-rate: float # Sampling rate for logs. A value between 0 and 1 that determines the fraction of log entries to collect.  - **1** - collect all logs (default). - **0.5** - collect approximately 50% of logs. - **0** - collect no logs (effectively disables logging without removing the policy). (format: float, default: 1)
]: any -> record<id: int, client_id: int, created: string, updated: string, include_empty_logs: bool, include_shield_logs: bool, name: string, description: string, retry_interval_minutes: int, rotate_interval_minutes: int, rotate_threshold_mb: int, rotate_threshold_lines: int, date_format: string, field_delimiter: string, field_separator: string, fields: list<string>, file_name_template: string, format_type: string, tags: record, escape_special_characters: bool, log_sample_rate: float, related_uploader_configs: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/policies/($id)")
  let body = {include_empty_logs: $include_empty_logs, include_shield_logs: $include_shield_logs, name: $name, description: $description, retry_interval_minutes: $retry_interval_minutes, rotate_interval_minutes: $rotate_interval_minutes, rotate_threshold_mb: $rotate_threshold_mb, rotate_threshold_lines: $rotate_threshold_lines, date_format: $date_format, field_delimiter: $field_delimiter, field_separator: $field_separator, fields: $body_fields, file_name_template: $file_name_template, format_type: $format_type, tags: $tags, escape_special_characters: $escape_special_characters, log_sample_rate: $log_sample_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change policy
#
# PATCH /cdn/logs_uploader/policies/{id}
# operationId: patch-policy
export def "cdn-logs-uploader-policies patch-policy" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-empty-logs: string@bool-completer # Include empty logs in the upload.
  --include-shield-logs: string@bool-completer # Include logs from origin shielding in the upload.
  --name: string # Name of the policy.
  --description: string # Description of the policy.
  --retry-interval-minutes: int # Interval in minutes to retry failed uploads.
  --rotate-interval-minutes: int # Interval in minutes to rotate logs.
  --rotate-threshold-mb: int # Threshold in MB to rotate logs. (nullable)
  --rotate-threshold-lines: int # Threshold in lines to rotate logs.
  --date-format: string # Date format for logs.
  --field-delimiter: string # Field delimiter for logs.
  --field-separator: string # Field separator for logs.
  --body-fields: list # List of fields to include in logs.
  --file-name-template: string # Template for log file name.
  --format-type: string@format-type-completer # Format type for logs.  Possible values: - **""** - empty, it means it will apply the format configurations from the policy. - **"json"** - output the logs as json lines.
  --tags: record # Tags allow for dynamic decoration of logs by adding predefined fields to the log format. These tags serve as customizable key-value pairs that can be included in log entries to enhance context and readability.
  --escape-special-characters: string@bool-completer # When set to true, the service sanitizes string values by escaping characters that may be unsafe for transport, logging, or downstream processing.  The following categories of characters are escaped: - Control and non-printable characters - Quotation marks and escape characters - Characters outside the standard ASCII range  The resulting output contains only printable ASCII characters.
  --log-sample-rate: float # Sampling rate for logs. A value between 0 and 1 that determines the fraction of log entries to collect.  - **1** - collect all logs (default). - **0.5** - collect approximately 50% of logs. - **0** - collect no logs (effectively disables logging without removing the policy). (format: float)
]: any -> record<id: int, client_id: int, created: string, updated: string, include_empty_logs: bool, include_shield_logs: bool, name: string, description: string, retry_interval_minutes: int, rotate_interval_minutes: int, rotate_threshold_mb: int, rotate_threshold_lines: int, date_format: string, field_delimiter: string, field_separator: string, fields: list<string>, file_name_template: string, format_type: string, tags: record, escape_special_characters: bool, log_sample_rate: float, related_uploader_configs: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/policies/($id)")
  let body = {include_empty_logs: $include_empty_logs, include_shield_logs: $include_shield_logs, name: $name, description: $description, retry_interval_minutes: $retry_interval_minutes, rotate_interval_minutes: $rotate_interval_minutes, rotate_threshold_mb: $rotate_threshold_mb, rotate_threshold_lines: $rotate_threshold_lines, date_format: $date_format, field_delimiter: $field_delimiter, field_separator: $field_separator, fields: $body_fields, file_name_template: $file_name_template, format_type: $format_type, tags: $tags, escape_special_characters: $escape_special_characters, log_sample_rate: $log_sample_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete policy
#
# DELETE /cdn/logs_uploader/policies/{id}
# operationId: delete-policy
export def "cdn-logs-uploader-policies delete-policy" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get policy fields
#
# GET /cdn/logs_uploader/policies/fields
# operationId: get-policy-fields
export def "cdn-logs-uploader-policies-fields get-policy-fields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/logs_uploader/policies/fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get targets list
#
# GET /cdn/logs_uploader/targets
# operationId: get-targets-list
export def "cdn-logs-uploader-targets get-targets-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search by target name or id.
  --config-ids: list # Filter by ids of related logs uploader configs that use given target.
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "config_ids" $config_ids "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/logs_uploader/targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create target
#
# POST /cdn/logs_uploader/targets
# operationId: create-target
export def "cdn-logs-uploader-targets create-target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  storage_type: string@storage-type-completer # Type of storage for logs.
  --name: string # Name of the target. (default: Target)
  --description: string # Description of the target.
  config: any # Config for specific storage type.
]: any -> record<id: int, client_id: int, created: string, updated: string, storage_type: string, name: string, description: string, related_uploader_configs: list<int>, status: record<status: string, code: int, updated: string, details: string>, config: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/logs_uploader/targets")
  let body = {storage_type: $storage_type, name: $name, description: $description, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get target details
#
# GET /cdn/logs_uploader/targets/{id}
# operationId: get-target-details
export def "cdn-logs-uploader-targets get-target-details" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, client_id: int, created: string, updated: string, storage_type: string, name: string, description: string, related_uploader_configs: list<int>, status: record<status: string, code: int, updated: string, details: string>, config: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/targets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change target
#
# PUT /cdn/logs_uploader/targets/{id}
# operationId: change-target
export def "cdn-logs-uploader-targets change-target" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  storage_type: string@storage-type-completer # Type of storage for logs.
  --name: string # Name of the target. (default: Target)
  --description: string # Description of the target.
  config: any # Config for specific storage type.
]: any -> record<id: int, client_id: int, created: string, updated: string, storage_type: string, name: string, description: string, related_uploader_configs: list<int>, status: record<status: string, code: int, updated: string, details: string>, config: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/targets/($id)")
  let body = {storage_type: $storage_type, name: $name, description: $description, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change target
#
# PATCH /cdn/logs_uploader/targets/{id}
# operationId: patch-target
export def "cdn-logs-uploader-targets patch-target" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --storage-type: string@storage-type-completer # Type of storage for logs.
  --name: string # Name of the target.
  --description: string # Description of the target.
  --config: any # Config for specific storage type.
]: any -> record<id: int, client_id: int, created: string, updated: string, storage_type: string, name: string, description: string, related_uploader_configs: list<int>, status: record<status: string, code: int, updated: string, details: string>, config: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/targets/($id)")
  let body = {storage_type: $storage_type, name: $name, description: $description, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete target
#
# DELETE /cdn/logs_uploader/targets/{id}
# operationId: delete-target
export def "cdn-logs-uploader-targets delete-target" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/targets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate target
#
# POST /cdn/logs_uploader/targets/{id}/validate
# operationId: validate-target
export def "cdn-logs-uploader-targets-validate validate-target" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, code: int, updated: string, details: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/targets/($id)/validate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get configs list
#
# GET /cdn/logs_uploader/configs
# operationId: get-configs-list
export def "cdn-logs-uploader-configs get-configs-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search by config name or id.
  --resource-ids: list # Filter by ids of CDN resources that are assigned to given config.
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "resource_ids" $resource_ids "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/logs_uploader/configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create config
#
# POST /cdn/logs_uploader/configs
# operationId: create-config
export def "cdn-logs-uploader-configs create-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Enables or disables the config. (default: true)
  name: string # Name of the config.
  policy: int # ID of the policy that should be assigned to given config.
  target: int # ID of the target to which logs should be uploaded.
  --for-all-resources: string@bool-completer # If set to true, the config will be applied to all CDN resources. If set to false, the config will be applied to the resources specified in the `resources` field. (default: false)
  --resources: list # List of resource IDs to which the config should be applied.
]: any -> record<id: int, client_id: int, created: string, updated: string, enabled: bool, name: string, policy: int, target: int, for_all_resources: bool, resources: list<int>, status: record<status: string, code: int, updated: string, details: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/logs_uploader/configs")
  let body = {enabled: $enabled, name: $name, policy: $policy, target: $target, for_all_resources: $for_all_resources, resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get config details
#
# GET /cdn/logs_uploader/configs/{id}
# operationId: get-config-details
export def "cdn-logs-uploader-configs get-config-details" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, client_id: int, created: string, updated: string, enabled: bool, name: string, policy: int, target: int, for_all_resources: bool, resources: list<int>, status: record<status: string, code: int, updated: string, details: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change config
#
# PUT /cdn/logs_uploader/configs/{id}
# operationId: change-config
export def "cdn-logs-uploader-configs change-config" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Enables or disables the config. (default: true)
  name: string # Name of the config.
  policy: int # ID of the policy that should be assigned to given config.
  target: int # ID of the target to which logs should be uploaded.
  --for-all-resources: string@bool-completer # If set to true, the config will be applied to all CDN resources. If set to false, the config will be applied to the resources specified in the `resources` field. (default: false)
  --resources: list # List of resource IDs to which the config should be applied.
]: any -> record<id: int, client_id: int, created: string, updated: string, enabled: bool, name: string, policy: int, target: int, for_all_resources: bool, resources: list<int>, status: record<status: string, code: int, updated: string, details: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/configs/($id)")
  let body = {enabled: $enabled, name: $name, policy: $policy, target: $target, for_all_resources: $for_all_resources, resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change config
#
# PATCH /cdn/logs_uploader/configs/{id}
# operationId: patch-config
export def "cdn-logs-uploader-configs patch-config" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Enables or disables the config.
  --name: string # Name of the config.
  --policy: int # ID of the policy that should be assigned to given config.
  --target: int # ID of the target to which logs should be uploaded.
  --for-all-resources: string@bool-completer # If set to true, the config will be applied to all CDN resources. If set to false, the config will be applied to the resources specified in the `resources` field.
  --resources: list # List of resource IDs to which the config should be applied.
]: any -> record<id: int, client_id: int, created: string, updated: string, enabled: bool, name: string, policy: int, target: int, for_all_resources: bool, resources: list<int>, status: record<status: string, code: int, updated: string, details: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/configs/($id)")
  let body = {enabled: $enabled, name: $name, policy: $policy, target: $target, for_all_resources: $for_all_resources, resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete config
#
# DELETE /cdn/logs_uploader/configs/{id}
# operationId: delete-config
export def "cdn-logs-uploader-configs delete-config" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate config
#
# POST /cdn/logs_uploader/configs/{id}/validate
# operationId: validate-config
export def "cdn-logs-uploader-configs-validate validate-config" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, code: int, updated: string, details: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/logs_uploader/configs/($id)/validate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get AWS regions list
#
# GET /cdn/aws_regions
# operationId: get-aws-regions-list
export def "cdn-aws-regions get-aws-regions-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/aws_regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Alibaba regions list
#
# GET /cdn/alibaba_regions
# operationId: get-alibaba-regions-list
export def "cdn-alibaba-regions get-alibaba-regions-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/alibaba_regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Prefetch content
#
# POST /cdn/resources/{resource_id}/prefetch
# operationId: prefetch-content
export def "cdn-resources-prefetch prefetch-content" [
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  paths: list # Paths to files that should be pre-populated to the CDN.  Paths to the files should be specified without a domain name. (e.g. [/test.jpg, test1.jpg])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)/prefetch")
  let body = {paths: $paths} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Purge cache
#
# POST /cdn/resources/{resource_id}/purge
# operationId: purge-cache
export def "cdn-resources-purge purge-cache" [
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --urls: list # **Purge by URL** clears the cache of a specific files. This purge type is recommended.  Specify file URLs including query strings. URLs should start with / without a domain name.  Purge by URL depends on the following CDN options:  1. "vary response header" is used. If your origin serves variants of the same content depending on the Vary HTTP response header, purge by URL will delete only one version of the file. 2. "slice" is used. If you update several files in the origin without clearing the CDN cache, purge by URL will delete only the first slice (with bytes=0… .) 3. "ignoreQueryString" is used. Don’t specify parameters in the purge request. 4. "query_params_blacklist" is used. Only files with the listed in the option parameters will be cached as different objects. Files with other parameters will be cached as one object. In this case, specify the listed parameters in the Purge request. Don't specify other parameters. 5. "query_params_whitelist" is used. Files with listed in the option parameters will be cached as one object. Files with other parameters will be cached as different objects. In this case, specify other parameters (if any) besides the ones listed in the purge request.
  --paths: list # **Purge by pattern** clears the cache that matches the pattern.  Use * operator, which replaces any number of symbols in your path. It's important to note that wildcard usage (*) is permitted only at the end of a pattern.  Query string added to any patterns will be ignored, and purge request will be processed as if there weren't any parameters.  Purge by pattern is recursive. Both /path and /path* will result in recursive purging, meaning all content under the specified path will be affected. As such, using the pattern /path* is functionally equivalent to simply using /path.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)/purge")
  let body = {urls: $urls, paths: $paths} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get rules list
#
# GET /cdn/resources/{resource_id}/rules
# operationId: get-rules-list
export def "cdn-resources-rules get-rules-list" [
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cdn/resources/($resource_id)/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create rule
#
# POST /cdn/resources/{resource_id}/rules
# operationId: create-rule
# --options shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
export def "cdn-resources-rules create-rule" [
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Rule name. (e.g. My first rule)
  rule: string # Path to the file or folder for which the rule will be applied.  The rule is applied if the requested URI matches the rule path.  We add a leading forward slash to any rule path. Specify a path without a forward slash. (e.g. /folder/images/*.png)
  ruleType: int # Rule type.  Possible values: - **Type 0** - Regular expression. Must start with '^/' or '/'. - **Type 1** - Regular expression. Note that for this rule type we automatically add / to each rule pattern before your regular expression. This type is **legacy**, please use Type 0. (e.g. 0)
  --active: string@bool-completer # Enables or disables a rule.  Possible values: - **true** - Rule is active, rule settings are applied. - **false** - Rule is inactive, rule settings are not applied. (e.g. true)
  --weight: int # Rule execution order: from lowest (1) to highest.  If requested URI matches multiple rules, the one higher in the order of the rules will be applied. (e.g. 1)
  --overrideOriginProtocol: string@overrideOriginProtocol-completer # Sets a protocol other than the one specified in the CDN resource settings to connect to the origin.  Possible values: - **HTTPS** - CDN servers connect to origin via HTTPS protocol. - **HTTP** - CDN servers connect to origin via HTTP protocol. - **MATCH** - Connection protocol is chosen automatically; in this case, content on origin source should be available for the CDN both through HTTP and HTTPS protocols. - **null** - `originProtocol` setting is inherited from the CDN resource settings. (nullable)
  --originGroup: int # ID of the origin group to which the rule is applied.  If the origin group is not specified, the rule is applied to the origin group that the CDN resource is associated with. (nullable)
  --options: record # List of options that can be configured for the rule.  In case of `null` value the option is not added to the rule. Option inherits its value from the CDN resource settings. — shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
]: any -> record<id: int, name: string, active: bool, deleted: bool, originGroup: int, rule: string, ruleType: int, weight: int, originProtocol: string, overrideOriginProtocol: string, preset_applied: bool, primary_rule: int, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)/rules")
  let body = {name: $name, rule: $rule, ruleType: $ruleType, active: $active, weight: $weight, overrideOriginProtocol: $overrideOriginProtocol, originGroup: $originGroup, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get rule details
#
# GET /cdn/resources/{resource_id}/rules/{rule_id}
# operationId: get-rule-details
export def "cdn-resources-rules get-rule-details" [
  resource_id: int
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, active: bool, deleted: bool, originGroup: int, rule: string, ruleType: int, weight: int, originProtocol: string, overrideOriginProtocol: string, preset_applied: bool, primary_rule: int, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)/rules/($rule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change rule
#
# PUT /cdn/resources/{resource_id}/rules/{rule_id}
# operationId: change-rule
# --options shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
export def "cdn-resources-rules change-rule" [
  resource_id: int
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Enables or disables a rule.  Possible values: - **true** - Rule is active, rule settings are applied. - **false** - Rule is inactive, rule settings are not applied. (e.g. true)
  --name: string # Rule name. (e.g. My first rule)
  rule: string # Path to the file or folder for which the rule will be applied.  The rule is applied if the requested URI matches the rule path.  We add a leading forward slash to any rule path. Specify a path without a forward slash. (e.g. /folder/images/*.png)
  ruleType: int # Rule type.  Possible values: - **Type 0** - Regular expression. Must start with '^/' or '/'. - **Type 1** - Regular expression. Note that for this rule type we automatically add / to each rule pattern before your regular expression. This type is **legacy**, please use Type 0. (e.g. 0)
  --weight: int # Rule execution order: from lowest (1) to highest.  If requested URI matches multiple rules, the one higher in the order of the rules will be applied. (e.g. 1)
  --overrideOriginProtocol: string@overrideOriginProtocol-completer # Sets a protocol other than the one specified in the CDN resource settings to connect to the origin.  Possible values: - **HTTPS** - CDN servers connect to origin via HTTPS protocol. - **HTTP** - CDN servers connect to origin via HTTP protocol. - **MATCH** - Connection protocol is chosen automatically; in this case, content on origin source should be available for the CDN both through HTTP and HTTPS protocols. - **null** - `originProtocol` setting is inherited from the CDN resource settings. (nullable)
  --originGroup: int # ID of the origin group to which the rule is applied.  If the origin group is not specified, the rule is applied to the origin group that the CDN resource is associated with. (nullable)
  --options: record # List of options that can be configured for the rule.  In case of `null` value the option is not added to the rule. Option inherits its value from the CDN resource settings. — shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
]: any -> record<id: int, name: string, active: bool, deleted: bool, originGroup: int, rule: string, ruleType: int, weight: int, originProtocol: string, overrideOriginProtocol: string, preset_applied: bool, primary_rule: int, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)/rules/($rule_id)")
  let body = {active: $active, name: $name, rule: $rule, ruleType: $ruleType, weight: $weight, overrideOriginProtocol: $overrideOriginProtocol, originGroup: $originGroup, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change rule
#
# PATCH /cdn/resources/{resource_id}/rules/{rule_id}
# operationId: patch-rule
# --options shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
export def "cdn-resources-rules patch-rule" [
  resource_id: int
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Enables or disables a rule.  Possible values: - **true** - Rule is active, rule settings are applied. - **false** - Rule is inactive, rule settings are not applied. (e.g. true)
  --name: string # Rule name. (e.g. My first rule)
  --rule: string # Path to the file or folder for which the rule will be applied.  The rule is applied if the requested URI matches the rule path.  We add a leading forward slash to any rule path. Specify a path without a forward slash. (e.g. /folder/images/*.png)
  --ruleType: int # Rule type.  Possible values: - **Type 0** - Regular expression. Must start with '^/' or '/'. - **Type 1** - Regular expression. Note that for this rule type we automatically add / to each rule pattern before your regular expression. This type is **legacy**, please use Type 0. (e.g. 0)
  --weight: int # Rule execution order: from lowest (1) to highest.  If requested URI matches multiple rules, the one higher in the order of the rules will be applied. (e.g. 1)
  --overrideOriginProtocol: string@overrideOriginProtocol-completer # Sets a protocol other than the one specified in the CDN resource settings to connect to the origin.  Possible values: - **HTTPS** - CDN servers connect to origin via HTTPS protocol. - **HTTP** - CDN servers connect to origin via HTTP protocol. - **MATCH** - Connection protocol is chosen automatically; in this case, content on origin source should be available for the CDN both through HTTP and HTTPS protocols. - **null** - `originProtocol` setting is inherited from the CDN resource settings. (nullable)
  --originGroup: int # ID of the origin group to which the rule is applied.  If the origin group is not specified, the rule is applied to the origin group that the CDN resource is associated with. (nullable)
  --options: record # List of options that can be configured for the rule.  In case of `null` value the option is not added to the rule. Option inherits its value from the CDN resource settings. — shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
]: any -> record<id: int, name: string, active: bool, deleted: bool, originGroup: int, rule: string, ruleType: int, weight: int, originProtocol: string, overrideOriginProtocol: string, preset_applied: bool, primary_rule: int, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)/rules/($rule_id)")
  let body = {active: $active, name: $name, rule: $rule, ruleType: $ruleType, weight: $weight, overrideOriginProtocol: $overrideOriginProtocol, originGroup: $originGroup, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete rule
#
# DELETE /cdn/resources/{resource_id}/rules/{rule_id}
# operationId: delete-rule
export def "cdn-resources-rules delete-rule" [
  resource_id: int
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)/rules/($rule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get rule templates list
#
# GET /cdn/resources/rule_templates
# operationId: get-rule-templates-list
export def "cdn-resources-rule-templates get-rule-templates-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/resources/rule_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create rule template
#
# POST /cdn/resources/rule_templates
# operationId: create-rule-template
# --options shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
export def "cdn-resources-rule-templates create-rule-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Rule template name. (e.g. All images template)
  rule: string # Path to the file or folder for which the rule will be applied.  The rule is applied if the requested URI matches the rule path.  We add a leading forward slash to any rule path. Specify a path without a forward slash. (e.g. /folder/images/*.png)
  ruleType: int # Rule type.  Possible values: - **Type 0** - Regular expression. Must start with '^/' or '/'. - **Type 1** - Regular expression. Note that for this rule type we automatically add / to each rule pattern before your regular expression. This type is **legacy**, please use Type 0. (e.g. 0)
  --weight: int # Rule execution order: from lowest (1) to highest.  If requested URI matches multiple rules, the one higher in the order of the rules will be applied. (e.g. 1)
  --overrideOriginProtocol: string@overrideOriginProtocol-completer # Sets a protocol other than the one specified in the CDN resource settings to connect to the origin.  Possible values: - **HTTPS** - CDN servers connect to origin via HTTPS protocol. - **HTTP** - CDN servers connect to origin via HTTP protocol. - **MATCH** - Connection protocol is chosen automatically; in this case, content on origin source should be available for the CDN both through HTTP and HTTPS protocols. - **null** - `originProtocol` setting is inherited from the CDN resource settings. (nullable)
  --options: record # List of options that can be configured for the rule.  In case of `null` value the option is not added to the rule. Option inherits its value from the CDN resource settings. — shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
]: any -> record<id: int, name: string, client: int, deleted: bool, rule: string, ruleType: int, weight: int, template: bool, default: bool, overrideOriginProtocol: string, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/resources/rule_templates")
  let body = {name: $name, rule: $rule, ruleType: $ruleType, weight: $weight, overrideOriginProtocol: $overrideOriginProtocol, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get rule template details
#
# GET /cdn/resources/rule_templates/{rule_template_id}
# operationId: get-rule-template-details
export def "cdn-resources-rule-templates get-rule-template-details" [
  rule_template_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, client: int, deleted: bool, rule: string, ruleType: int, weight: int, template: bool, default: bool, overrideOriginProtocol: string, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/rule_templates/($rule_template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change rule template
#
# PUT /cdn/resources/rule_templates/{rule_template_id}
# operationId: change-rule-template
# --options shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
export def "cdn-resources-rule-templates change-rule-template" [
  rule_template_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Rule template name. (e.g. All images template)
  rule: string # Path to the file or folder for which the rule will be applied.  The rule is applied if the requested URI matches the rule path.  We add a leading forward slash to any rule path. Specify a path without a forward slash. (e.g. /folder/images/*.png)
  ruleType: int # Rule type.  Possible values: - **Type 0** - Regular expression. Must start with '^/' or '/'. - **Type 1** - Regular expression. Note that for this rule type we automatically add / to each rule pattern before your regular expression. This type is **legacy**, please use Type 0. (e.g. 0)
  --weight: int # Rule execution order: from lowest (1) to highest.  If requested URI matches multiple rules, the one higher in the order of the rules will be applied. (e.g. 1)
  --overrideOriginProtocol: string@overrideOriginProtocol-completer # Sets a protocol other than the one specified in the CDN resource settings to connect to the origin.  Possible values: - **HTTPS** - CDN servers connect to origin via HTTPS protocol. - **HTTP** - CDN servers connect to origin via HTTP protocol. - **MATCH** - Connection protocol is chosen automatically; in this case, content on origin source should be available for the CDN both through HTTP and HTTPS protocols. - **null** - `originProtocol` setting is inherited from the CDN resource settings. (nullable)
  --options: record # List of options that can be configured for the rule.  In case of `null` value the option is not added to the rule. Option inherits its value from the CDN resource settings. — shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
]: any -> record<id: int, name: string, client: int, deleted: bool, rule: string, ruleType: int, weight: int, template: bool, default: bool, overrideOriginProtocol: string, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/rule_templates/($rule_template_id)")
  let body = {name: $name, rule: $rule, ruleType: $ruleType, weight: $weight, overrideOriginProtocol: $overrideOriginProtocol, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change rule template
#
# PATCH /cdn/resources/rule_templates/{rule_template_id}
# operationId: patch-rule-template
# --options shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
export def "cdn-resources-rule-templates patch-rule-template" [
  rule_template_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Rule template name. (e.g. All images template)
  --rule: string # Path to the file or folder for which the rule will be applied.  The rule is applied if the requested URI matches the rule path.  We add a leading forward slash to any rule path. Specify a path without a forward slash. (e.g. /folder/images/*.png)
  --ruleType: int # Rule type.  Possible values: - **Type 0** - Regular expression. Must start with '^/' or '/'. - **Type 1** - Regular expression. Note that for this rule type we automatically add / to each rule pattern before your regular expression. This type is **legacy**, please use Type 0. (e.g. 0)
  --weight: int # Rule execution order: from lowest (1) to highest.  If requested URI matches multiple rules, the one higher in the order of the rules will be applied. (e.g. 1)
  --overrideOriginProtocol: string@overrideOriginProtocol-completer # Sets a protocol other than the one specified in the CDN resource settings to connect to the origin.  Possible values: - **HTTPS** - CDN servers connect to origin via HTTPS protocol. - **HTTP** - CDN servers connect to origin via HTTP protocol. - **MATCH** - Connection protocol is chosen automatically; in this case, content on origin source should be available for the CDN both through HTTP and HTTPS protocols. - **null** - `originProtocol` setting is inherited from the CDN resource settings. (nullable)
  --options: record # List of options that can be configured for the rule.  In case of `null` value the option is not added to the rule. Option inherits its value from the CDN resource settings. — shape: {allowedHttpMethods?: record, brotli_compression?: record, browser_cache_settings?: record, cache_http_headers?: record, cors?: record, country_acl?: record, disable_cache?: record, disable_proxy_force_ranges?: record, edge_cache_settings?: record, fastedge?: record, fetch_compressed?: record, follow_origin_redirect?: record, force_return?: record, forward_host_header?: record, gzipOn?: record, hostHeader?: record, ignore_cookie?: record, ignoreQueryString?: record, image_stack?: record, ip_address_acl?: record, limit_bandwidth?: record, proxy_cache_key?: record, proxy_cache_methods_set?: record, proxy_connect_timeout?: record, proxy_read_timeout?: record, query_params_blacklist?: record, query_params_whitelist?: record, query_string_forwarding?: record, redirect_http_to_https?: record, redirect_https_to_http?: record, referrer_acl?: record, response_headers_hiding_policy?: record, rewrite?: record, secure_key?: record, slice?: record, sni?: record, stale?: record, static_response_headers?: record, staticHeaders?: record, staticRequestHeaders?: record, user_agent_acl?: record, waap?: record, websockets?: record}
]: any -> record<id: int, name: string, client: int, deleted: bool, rule: string, ruleType: int, weight: int, template: bool, default: bool, overrideOriginProtocol: string, options: record<allowedHttpMethods: record<enabled: bool, value: list>, brotli_compression: record<enabled: bool, value: list>, browser_cache_settings: record<enabled: bool, value: string>, cache_http_headers: record<enabled: bool, value: list>, cors: record<enabled: bool, value: list, always: bool>, country_acl: record<enabled: bool, policy_type: string, excepted_values: list>, disable_cache: record<enabled: bool, value: bool>, disable_proxy_force_ranges: record<enabled: bool, value: bool>, edge_cache_settings: record<enabled: bool, value: string, custom_values: record, default: string>, fastedge: record<enabled: bool, on_request_headers: record, on_request_headers_after_cache: record, on_request_body: record, on_response_headers: record, on_response_body: record>, fetch_compressed: record<enabled: bool, value: bool>, follow_origin_redirect: record<enabled: bool, codes: list>, force_return: record<enabled: bool, code: int, body: string, time_interval: record>, forward_host_header: record<enabled: bool, value: bool>, gzipOn: record<enabled: bool, value: bool>, hostHeader: record<enabled: bool, value: string>, ignore_cookie: record<enabled: bool, value: bool>, ignoreQueryString: record<enabled: bool, value: bool>, image_stack: record<enabled: bool, avif_enabled: bool, webp_enabled: bool, quality: int, png_lossless: bool>, ip_address_acl: record<enabled: bool, policy_type: string, excepted_values: list>, limit_bandwidth: record<enabled: bool, limit_type: string, speed: int, buffer: int>, proxy_cache_key: record<enabled: bool, value: string>, proxy_cache_methods_set: record<enabled: bool, value: bool>, proxy_connect_timeout: record<enabled: bool, value: string>, proxy_read_timeout: record<enabled: bool, value: string>, query_params_blacklist: record<enabled: bool, value: list>, query_params_whitelist: record<enabled: bool, value: list>, query_string_forwarding: record<enabled: bool, forward_from_file_types: list, forward_to_file_types: list, forward_only_keys: list, forward_except_keys: list>, redirect_http_to_https: record<enabled: bool, value: bool>, redirect_https_to_http: record<enabled: bool, value: bool>, referrer_acl: record<enabled: bool, policy_type: string, excepted_values: list>, response_headers_hiding_policy: record<enabled: bool, mode: string, excepted: list>, rewrite: record<enabled: bool, flag: string, body: string>, secure_key: record<enabled: bool, key: string, type: int>, slice: record<enabled: bool, value: bool>, sni: record<enabled: bool, sni_type: string, custom_hostname: string>, stale: record<enabled: bool, value: list>, static_response_headers: record<enabled: bool, value: list>, staticHeaders: record<enabled: bool, value: record>, staticRequestHeaders: record<enabled: bool, value: record>, user_agent_acl: record<enabled: bool, policy_type: string, excepted_values: list>, waap: record<enabled: bool, value: bool>, websockets: record<enabled: bool, value: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/rule_templates/($rule_template_id)")
  let body = {name: $name, rule: $rule, ruleType: $ruleType, weight: $weight, overrideOriginProtocol: $overrideOriginProtocol, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete rule template
#
# DELETE /cdn/resources/rule_templates/{rule_template_id}
# operationId: delete-rule-template
export def "cdn-resources-rule-templates delete-rule-template" [
  rule_template_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/rule_templates/($rule_template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get purges history list
#
# GET /cdn/purge_statuses
# operationId: get-purge-status-list
export def "cdn-purge-statuses get-purge-status-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cname: string # Purges associated with a specific resource CNAME.  Example: - &cname=example.com
  --status: string
  --purge-type: string
  --from-created: string # Start date and time of the requested time period (ISO 8601/RFC 3339 format, UTC.)  Examples: - &`from_created`=2021-06-14T00:00:00Z - &`from_created`=2021-06-14T00:00:00.000Z
  --to-created: string # End date and time of the requested time period (ISO 8601/RFC 3339 format, UTC.)  Examples: - &`to_created`=2021-06-15T00:00:00Z - &`to_created`=2021-06-15T00:00:00.000Z
  --offset: int # Number of purge requests in the response to skip starting from the beginning of the requested period. (default: 0)
  --limit: int # Maximum number of purges in the response. (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cname" $cname "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "purge_type" $purge_type "scalar") (serialize-qp "from_created" $from_created "scalar") (serialize-qp "to_created" $to_created "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/purge_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SSL certificates list
#
# GET /cdn/sslData
# operationId: get-ssl-certificates-list
export def "cdn-ssl-data get-ssl-certificates-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --automated: string@bool-completer # How the SSL certificate was issued.  Possible values: - **true** – Certificate was issued automatically. - **false** – Certificate was added by a user.
  --validity-not-after-lte: string # Date and time when the certificate become untrusted (ISO 8601/RFC 3339 format, UTC.)  Response will contain only certificates valid until the specified time.
  --resource-id: int # CDN resource ID for which certificates are requested.
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "automated" $automated "scalar") (serialize-qp "validity_not_after_lte" $validity_not_after_lte "scalar") (serialize-qp "resource_id" $resource_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/sslData" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add SSL certificate
#
# POST /cdn/sslData
# operationId: add-ssl-certificate
export def "cdn-ssl-data add-ssl-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # SSL certificate name.  It must be unique. (e.g. New certificate)
  --sslCertificate: string # Public part of the SSL certificate.  All chain of the SSL certificate should be added. (e.g. -----BEGIN CERTIFICATE----- MIIFWzCCBEOgAwIBAgISBK6qoNitg//89H/YJamujpWlMA0GCSqGSIb3DQEBCwUA MEoxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MSMwIQYDVQQD ExpMZXQncyBFbmNyeXB0IEF1dGhvcml0eSBYMzAeFw0xODExMTMxMjQwMDJaFw0x OTAyMTExMjQwMDJaMBwxGjAYBgNVBAMTEWNkbjIudG50LWNsdWIuY29tMIIBIjAN BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzaHExDEXNSf6ELS0WUR7qq8gs9cc xx99sM2zs3Jld0twPmuldkVNe5xte/Hj03r4SesfOBczR7pn+t60YujPvUQDN8lx WYpvRuetOneyf4gNPatwzR/W1GWGlahet1xPVYGrttqL4gCJeShIXvU4aCyzW941 Pt0wCs+bg9u+59fXFkigWrWJPkwbR7bJ14XTStYynMbYLfCg+VPeGWj3d8wOhQcf AD86o8TLTbVfK2BDXwS5S8Dgf5u8g+WvmVHYDIkYKCxcLj0jP61Y7uHoFbSg41oN A9yPOa+0cYxA7U702V2WjxbfIeATYtNLZvH17lk+DYlQl8q3MLwguqZdgwIDAQAB iIqI2xquGONtHFDOKJvy1O2qYTVRtNRVZqhc1ol+mw== -----END CERTIFICATE----- -----BEGIN CERTIFICATE----- MIIEkjCCA3qgAwIBAgIQCgFBQgAAAVOFc2oLheynCDANBgkqhkiG9w0BAQsFADA/ MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT DkRTVCBSb290IENBIFgzMB4XDTE2MDMxNzE2NDA0NloXDTIxMDMxNzE2NDA0Nlow SjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUxldCdzIEVuY3J5cHQxIzAhBgNVBAMT GkxldCdzIEVuY3J5cHQgQXV0aG9yaXR5IFgzMIIBIjANBgkqhkiG9w0BAQEFAAOC AQ8AMIIBCgKCAQEAnNMM8FrlLke3cl03g7NoYzDq1zUmGSXhvb418XCSL7e4S0EF q6meNQhY7LEqxGiHC6PjdeTm86dicbp5gWAf15Gan/PQeGdxyGkOlZHP/uaZ6WA8 SMx+yk13EiSdRxta67nsHjcAHJyse6cF6s5K671B5TaYucv9bTyWaN8jKkKQDIZ0 KOqkqm57TH2H3eDJAkSnh6/DNFu0Qg== -----END CERTIFICATE----- )
  --sslPrivateKey: string # Private key of the SSL certificate. (e.g. -----BEGIN PRIVATE KEY----- MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDZcNCZiNNHfX2O dZpf12mv2rAZwqGZBAdpox0wntEPK3JciQ7ZRloLJeHuCNIJs9MidnH7Xk8zveju mab6HmfIzvMJAAm88OYWMFQRiYe1ggJEHMe7yYPQbtXwTqWDYdWmjPPma3Ujqqmb hmVX2rsYILD7cUjS+e0Ucfqx3QODQj/aujTt1rS0gFhJ0soY5m+C6VimPCx4Bjyw 5rhtskJDRrfXxrIhVXOvSPFRyxDSfjt3win8vjhhZ3oFPWgrl9lVhn0zaB5hjDsd -----END PRIVATE KEY----- )
  --validate-root-ca: string@bool-completer # Defines whether to check the SSL certificate for a signature from a trusted certificate authority.  Possible values:  - **true** - SSL certificate must be verified to be signed by a trusted certificate authority. - **false** - SSL certificate will not be verified to be signed by a trusted certificate authority. (e.g. true)
  --automated: string@bool-completer # Must be **true** to issue certificate automatically. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/sslData")
  let body = {name: $name, sslCertificate: $sslCertificate, sslPrivateKey: $sslPrivateKey, validate_root_ca: $validate_root_ca, automated: $automated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get SSL certificate details
#
# GET /cdn/sslData/{ssl_id}
# operationId: get-ssl-certificate-details
export def "cdn-ssl-data get-ssl-certificate-details" [
  ssl_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, deleted: bool, cert_issuer: string, cert_subject_cn: string, cert_subject_alt: string, validity_not_before: string, validity_not_after: string, sslCertificateChain: string, hasRelatedResources: bool, name: string, automated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/sslData/($ssl_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change SSL certificate
#
# PUT /cdn/sslData/{ssl_id}
# operationId: change-ssl-certificate
export def "cdn-ssl-data change-ssl-certificate" [
  ssl_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # SSL certificate name.  It must be unique. (e.g. New certificate)
  sslCertificate: string # Public part of the SSL certificate.  All chain of the SSL certificate should be added. (e.g. -----BEGIN CERTIFICATE----- MIIFWzCCBEOgAwIBAgISBK6qoNitg//89H/YJamujpWlMA0GCSqGSIb3DQEBCwUA MEoxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MSMwIQYDVQQD ExpMZXQncyBFbmNyeXB0IEF1dGhvcml0eSBYMzAeFw0xODExMTMxMjQwMDJaFw0x OTAyMTExMjQwMDJaMBwxGjAYBgNVBAMTEWNkbjIudG50LWNsdWIuY29tMIIBIjAN BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzaHExDEXNSf6ELS0WUR7qq8gs9cc xx99sM2zs3Jld0twPmuldkVNe5xte/Hj03r4SesfOBczR7pn+t60YujPvUQDN8lx WYpvRuetOneyf4gNPatwzR/W1GWGlahet1xPVYGrttqL4gCJeShIXvU4aCyzW941 Pt0wCs+bg9u+59fXFkigWrWJPkwbR7bJ14XTStYynMbYLfCg+VPeGWj3d8wOhQcf AD86o8TLTbVfK2BDXwS5S8Dgf5u8g+WvmVHYDIkYKCxcLj0jP61Y7uHoFbSg41oN A9yPOa+0cYxA7U702V2WjxbfIeATYtNLZvH17lk+DYlQl8q3MLwguqZdgwIDAQAB iIqI2xquGONtHFDOKJvy1O2qYTVRtNRVZqhc1ol+mw== -----END CERTIFICATE----- -----BEGIN CERTIFICATE----- MIIEkjCCA3qgAwIBAgIQCgFBQgAAAVOFc2oLheynCDANBgkqhkiG9w0BAQsFADA/ MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT DkRTVCBSb290IENBIFgzMB4XDTE2MDMxNzE2NDA0NloXDTIxMDMxNzE2NDA0Nlow SjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUxldCdzIEVuY3J5cHQxIzAhBgNVBAMT GkxldCdzIEVuY3J5cHQgQXV0aG9yaXR5IFgzMIIBIjANBgkqhkiG9w0BAQEFAAOC AQ8AMIIBCgKCAQEAnNMM8FrlLke3cl03g7NoYzDq1zUmGSXhvb418XCSL7e4S0EF q6meNQhY7LEqxGiHC6PjdeTm86dicbp5gWAf15Gan/PQeGdxyGkOlZHP/uaZ6WA8 SMx+yk13EiSdRxta67nsHjcAHJyse6cF6s5K671B5TaYucv9bTyWaN8jKkKQDIZ0 KOqkqm57TH2H3eDJAkSnh6/DNFu0Qg== -----END CERTIFICATE----- )
  sslPrivateKey: string # Private key of the SSL certificate. (e.g. -----BEGIN PRIVATE KEY----- MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDZcNCZiNNHfX2O dZpf12mv2rAZwqGZBAdpox0wntEPK3JciQ7ZRloLJeHuCNIJs9MidnH7Xk8zveju mab6HmfIzvMJAAm88OYWMFQRiYe1ggJEHMe7yYPQbtXwTqWDYdWmjPPma3Ujqqmb hmVX2rsYILD7cUjS+e0Ucfqx3QODQj/aujTt1rS0gFhJ0soY5m+C6VimPCx4Bjyw 5rhtskJDRrfXxrIhVXOvSPFRyxDSfjt3win8vjhhZ3oFPWgrl9lVhn0zaB5hjDsd -----END PRIVATE KEY----- )
  --validate-root-ca: string@bool-completer # Defines whether to check the SSL certificate for a signature from a trusted certificate authority.  Possible values:  - **true** - SSL certificate must be verified to be signed by a trusted certificate authority. - **false** - SSL certificate will not be verified to be signed by a trusted certificate authority. (e.g. true)
]: any -> record<id: int, deleted: bool, cert_issuer: string, cert_subject_cn: string, cert_subject_alt: string, validity_not_before: string, validity_not_after: string, sslCertificateChain: string, hasRelatedResources: bool, name: string, automated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/sslData/($ssl_id)")
  let body = {name: $name, sslCertificate: $sslCertificate, sslPrivateKey: $sslPrivateKey, validate_root_ca: $validate_root_ca} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete SSL certificate
#
# DELETE /cdn/sslData/{ssl_id}
# operationId: delete-ssl-certificate
export def "cdn-ssl-data delete-ssl-certificate" [
  ssl_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/sslData/($ssl_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trusted CA certificates list
#
# GET /cdn/sslCertificates
# operationId: get-trusted-ca-certificates-list
export def "cdn-ssl-certificates get-trusted-ca-certificates-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --automated: string@bool-completer # How the certificate was issued.  Possible values: - **true** – Certificate was issued automatically. - **false** – Certificate was added by a user.
  --validity-not-after-lte: string # Date and time when the certificate become untrusted (ISO 8601/RFC 3339 format, UTC.)  Response will contain certificates valid until the specified time.
  --resource-id: int # CDN resource ID for which the certificates are requested.
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "automated" $automated "scalar") (serialize-qp "validity_not_after_lte" $validity_not_after_lte "scalar") (serialize-qp "resource_id" $resource_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/sslCertificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add trusted CA certificate
#
# POST /cdn/sslCertificates
# operationId: add-trusted-ca-certificate
export def "cdn-ssl-certificates add-trusted-ca-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # CA certificate name.  It must be unique. (e.g. Example CA cert)
  sslCertificate: string # Public part of the CA certificate.  It must be in the PEM format. (e.g. -----BEGIN CERTIFICATE----- MIIC0zCCAbugAwIBAgICA+gwDQYJKoZIhvcNAQELBQAwFjEUMBIGA1UEAwwLZXhh bXBsZS5jb20wHhcNMjAwNjI2MTIwMzUzWhcNMjEwNjI2MTIwMzUzWjAWMRQwEgYD VQQDDAtleGFtcGxlLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB AN4nnSfTsMEnfPgL7rkbImxZAQoND+bpPoX8q16iXZz3fFfqdRk+uEIpU3Brleeg p0zrrT2eI3+c2h/PRod0Fam4TO6EcfwuboUFzV3j6yw6aWdfBjWZsWBR/FoqWLYq b3UejN7yiTYNSiIy3zVpi9pnFM8N8qT+VGBrRDGef2v9JCzhsSSU7wAYM5HKZTp+ WHojjiyB2hOYqft7A2WlTEDmHFa5UcPHMRZKATUYI1T2TRVqLlSiE2mJ3dFRXGM2 ZAS33J0NVUjkx3w8RmJ7DNflEFJt/6IXdfaokVgfza7LFarrQFQP/YURXEeJT7jm DvKpZ/a8wu3ve6N4ykC+CBsCAwEAAaMrMCkwDwYDVR0TBAgwBgEB/wIBADAWBgNV HREEDzANggtleGFtcGxlLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEAovxY5lm89Eod L8CH3dZzIH7nv8MXtwgpv2vth4PDq2btLS8xrqm2SsA/cV+DsbDjh5CxQLoDX+8V g8NtY+ipOE0hdJAUo7UVlsxuAY4frkmLL1/RwpjZg+Z2NAxpR7xGWgoMn7CH481w AOBypAuCxcfcyyAOttdS+YMRJnpL6z8/C3W0LGkNOs26Qhu1/U8lfz1f9F4XummD u2SCmJsAd1PrL1shsyh4HtmFjuY698aTjYUDUleAnx7ytrGlZuLOIeoQi7tcsLJJ TPMbxTLgGN2HEkdJerFRBNViuWvqioEyYlzZ3MshOCR2wsL4wrXrCF0Y3cNOYcIh Z8z+wUAP2g== -----END CERTIFICATE----- )
]: any -> record<id: int, name: string, deleted: bool, cert_issuer: string, cert_subject_cn: string, cert_subject_alt: string, validity_not_before: string, validity_not_after: string, sslCertificateChain: string, hasRelatedResources: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/sslCertificates")
  let body = {name: $name, sslCertificate: $sslCertificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get trusted CA certificate details
#
# GET /cdn/sslCertificates/{id}
# operationId: get-trusted-ca-certificate-details
export def "cdn-ssl-certificates get-trusted-ca-certificate-details" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, deleted: bool, cert_issuer: string, cert_subject_cn: string, cert_subject_alt: string, validity_not_before: string, validity_not_after: string, sslCertificateChain: string, hasRelatedResources: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/sslCertificates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change trusted CA certificate
#
# PUT /cdn/sslCertificates/{id}
# operationId: change-trusted-ca-certificate
export def "cdn-ssl-certificates change-trusted-ca-certificate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # CA certificate name.  It must be unique. (e.g. Example CA cert 2)
]: any -> record<id: int, name: string, deleted: bool, cert_issuer: string, cert_subject_cn: string, cert_subject_alt: string, validity_not_before: string, validity_not_after: string, sslCertificateChain: string, hasRelatedResources: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/sslCertificates/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete trusted CA certificate
#
# DELETE /cdn/sslCertificates/{id}
# operationId: delete-trusted-ca-certificate
export def "cdn-ssl-certificates delete-trusted-ca-certificate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/sslCertificates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CDN resource statistics
#
# GET /cdn/statistics/series
# operationId: cdn-resource-statistics
export def "cdn-statistics-series cdn-resource-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --service: string # Service name.  Possible value: - CDN
  --qp-from: string # Beginning of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --qp-to: string # End of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --granularity: string # Duration of the time blocks into which the data will be divided.  Possible values: - **1m** - available only for up to 1 month in the past. - **5m** - **15m** - **1h** - **1d**
  --metrics: string # Types of statistics data.  Possible values: - **`upstream_bytes`** – Traffic in bytes from an origin server to CDN servers or to origin shielding when used. - **`sent_bytes`** – Traffic in bytes from CDN servers to clients. - **`shield_bytes`** – Traffic in bytes from origin shielding to CDN servers. - **`backblaze_bytes`** - Traffic in bytes from Backblaze origin. - **`total_bytes`** – `shield_bytes`, `upstream_bytes` and `sent_bytes` combined. - **`cdn_bytes`** – `sent_bytes` and `shield_bytes` combined. - **requests** – Number of requests to edge servers. - **`responses_2xx`** – Number of 2xx response codes. - **`responses_3xx`** – Number of 3xx response codes. - **`responses_4xx`** – Number of 4xx response codes. - **`responses_5xx`** – Number of 5xx response codes. - **`responses_hit`** – Number of responses with the header Cache: HIT. - **`responses_miss`** – Number of responses with the header Cache: MISS. - **`response_types`** – Statistics by content type. It returns a number of responses for content with different MIME types. - **`cache_hit_traffic_ratio`** – Formula: 1 - `upstream_bytes` / `sent_bytes`. We deduct the non-cached traffic from the total traffic amount. - **`cache_hit_requests_ratio`** – Formula: `responses_hit` / requests. The share of sending cached content. - **`shield_traffic_ratio`** – Formula: (`shield_bytes` - `upstream_bytes`) / `shield_bytes`. The efficiency of the Origin Shielding: how much more traffic is sent from the Origin Shielding than from the origin. - **`image_processed`** - Number of images transformed on the Image optimization service. - **`request_time`** - Time elapsed between the first bytes of a request were processed and logging after the last bytes were sent to a user. - **`upstream_response_time`** - Number of milliseconds it took to receive a response from an origin. If upstream `response_time_` contains several indications for one request (in case of more than 1 origin), we summarize them. In case of aggregating several queries, the average of this amount is calculated.  Metrics **`upstream_response_time`** and **`request_time`** should be requested separately from other metrics
  --group-by: string # Output data grouping.  Possible values: - **resource** – Data is grouped by CDN resources IDs. - **region** – Data is grouped by regions of CDN edge servers. - **country** – Data is grouped by countries of CDN edge servers. - **vhost** – Data is grouped by resources CNAMEs. - **`client_country`** - Data is grouped by countries, based on end-users' location. - **protocol** - Data is grouped by http protocol version.  To request multiple values, use: - &`group_by`=region&`group_by`=resource
  --countries: string # Names of countries for which data should be displayed. English short name from [ISO 3166 standard][1] without the definite article ("the") should be used.   [1]: https://www.iso.org/obp/ui/#search/code/  To request multiple values, use: - &countries=france&countries=denmark
  --regions: string # Regions for which data is displayed.  Possible values: - **na** – North America - **eu** – Europe - **cis** – Commonwealth of Independent States - **asia** – Asia - **au** – Australia - **latam** – Latin America - **me** – Middle East - **africa** - Africa - **sa** - South America
  --resource: int # CDN resources IDs by that statistics data is grouped.  To request multiple values, use: - &resource=1&resource=2  If CDN resource ID is not specified, data related to all CDN resources is returned.
]: nothing -> record<resource: record, 1__example_: record, region: record, metrics: record, upstream_bytes: list<int>, sent_bytes: list<int>, total_bytes: list<int>, backblaze_bytes: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "service" $service "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "metrics" $metrics "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "countries" $countries "scalar") (serialize-qp "regions" $regions "scalar") (serialize-qp "resource" $resource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/statistics/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Aggregated statistics
#
# GET /cdn/statistics/aggregate/stats
# operationId: aggregated-statistics
export def "cdn-statistics-aggregate-stats aggregated-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --service: string # Service name.  Possible value: - CDN
  --qp-from: string # Beginning of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --qp-to: string # End of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --metrics: string # Types of statistics data.  Possible values: - **`upstream_bytes`** – Traffic in bytes from an origin server to CDN servers or to origin shielding when used. - **`sent_bytes`** – Traffic in bytes from CDN servers to clients. - **`shield_bytes`** – Traffic in bytes from origin shielding to CDN servers. - **`backblaze_bytes`** - Traffic in bytes from Backblaze origin. - **`total_bytes`** – `shield_bytes`, `upstream_bytes` and `sent_bytes` combined. - **`cdn_bytes`** – `sent_bytes` and `shield_bytes` combined. - **requests** – Number of requests to edge servers. - **`responses_2xx`** – Number of 2xx response codes. - **`responses_3xx`** – Number of 3xx response codes. - **`responses_4xx`** – Number of 4xx response codes. - **`responses_5xx`** – Number of 5xx response codes. - **`responses_hit`** – Number of responses with the header Cache: HIT. - **`responses_miss`** – Number of responses with the header Cache: MISS. - **`response_types`** – Statistics by content type. It returns a number of responses for content with different MIME types. - **`cache_hit_traffic_ratio`** – Formula: 1 - `upstream_bytes` / `sent_bytes`. We deduct the non-cached traffic from the total traffic amount. - **`cache_hit_requests_ratio`** – Formula: `responses_hit` / requests. The share of sending cached content. - **`shield_traffic_ratio`** – Formula: (`shield_bytes` - `upstream_bytes`) / `shield_bytes`. The efficiency of the Origin Shielding: how much more traffic is sent from the Origin Shielding than from the origin. - **`image_processed`** - Number of images transformed on the Image optimization service. - **`request_time`** - Time elapsed between the first bytes of a request were processed and logging after the last bytes were sent to a user. - **`upstream_response_time`** - Number of milliseconds it took to receive a response from an origin. If upstream `response_time_` contains several indications for one request (in case of more than 1 origin), we summarize them. In case of aggregating several queries, the average of this amount is calculated. - **`95_percentile`** - Represents the 95th percentile of network bandwidth usage in bytes per second. This means that 95% of the time, the network resource usage was below this value. - **`max_bandwidth`** - The maximum network bandwidth that was used during the selected time represented in bytes per second. - **`min_bandwidth`** - The minimum network bandwidth that was used during the selected time represented in bytes per second.  Metrics **`upstream_response_time`** and **`request_time`** should be requested separately from other metrics
  --group-by: string # Output data grouping.  Possible values: - **resource** – Data is grouped by CDN resources IDs. - **region** – Data is grouped by regions of CDN edge servers. - **country** – Data is grouped by countries of CDN edge servers. - **vhost** – Data is grouped by resources CNAMEs. - **`client_country`** - Data is grouped by countries, based on end-users' location. - **protocol** - Data is grouped by http protocol version.  To request multiple values, use: - &`group_by`=region&`group_by`=resource
  --regions: string # Regions for which data is displayed.  Possible values: - **na** – North America - **eu** – Europe - **cis** – Commonwealth of Independent States - **asia** – Asia - **au** – Australia - **latam** – Latin America - **me** – Middle East - **africa** - Africa - **sa** - South America
  --countries: string # Names of countries for which data should be displayed. English short name from [ISO 3166 standard][1] without the definite article ("the") should be used.   [1]: https://www.iso.org/obp/ui/#search/code/  To request multiple values, use: - &countries=france&countries=denmark
  --resource: int # CDN resources IDs by that statistics data is grouped.  To request multiple values, use: - &resource=1&resource=2  If CDN resource ID is not specified, data related to all CDN resources is returned.
  --flat: string@bool-completer # The way the parameters are arranged in the response.  Possible values: - **true** – Flat structure is used. - **false** – Embedded structure is used (default.)
]: nothing -> record<resource: record, 1__example_: record, region: record, cis__example_: record, metrics: record, upstream_bytes: int, sent_bytes: int, total_bytes: int, backblaze_bytes: int, requests: int, responses_2xx: int, responses_3xx: int, responses_4xx: int, responses_5xx: int, responses_hit: int, responses_miss: int, response_types: record, cache_hit_traffic_ratio: int, 95_percentile: int, min_bandwidth: int, max_bandwidth: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "service" $service "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "metrics" $metrics "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "regions" $regions "scalar") (serialize-qp "countries" $countries "scalar") (serialize-qp "resource" $resource "scalar") (serialize-qp "flat" $flat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/statistics/aggregate/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Origin shielding usage statistics
#
# GET /cdn/statistics/shield_usage/series
# operationId: origin-shielding-usage-statistics
export def "cdn-statistics-shield-usage-series origin-shielding-usage-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Beginning of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --qp-to: string # End of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --resource: int # CDN resources IDs by that statistics data is grouped.  To request multiple values, use: - &resource=1&resource=2  If CDN resource ID is not specified, data related to all CDN resources is returned.
]: nothing -> table<active_from: string, active_to: string, client_id: int, resource_id: int, cname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "resource" $resource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/statistics/shield_usage/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Aggregated origin shielding usage statistics
#
# GET /cdn/statistics/shield_usage/aggregated
# operationId: aggregated-origin-shielding-usage-statistics
export def "cdn-statistics-shield-usage-aggregated aggregated-origin-shielding-usage-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Beginning of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --qp-to: string # End of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --group-by: string # Output data grouping.  Possible value: - **resource** - Data is grouped by CDN resources.
  --resource: int # CDN resources IDs by that statistics data is grouped.  To request multiple values, use: - &resource=1&resource=2  If CDN resource ID is not specified, data related to all CDN resources is returned.
  --flat: string@bool-completer # The way the parameters are arranged in the response.  Possible values: - **true** – Flat structure is used. - **false** – Embedded structure is used (default.)
]: nothing -> record<resource: record, 1__example_: record, metrics: record, shield_usage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "resource" $resource "scalar") (serialize-qp "flat" $flat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/statistics/shield_usage/aggregated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Logs uploader usage statistics
#
# GET /cdn/statistics/raw_logs_usage/series
# operationId: raw-logs-usage-statistics
export def "cdn-statistics-raw-logs-usage-series raw-logs-usage-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Beginning of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --qp-to: string # End of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --resource: int # CDN resources IDs by that statistics data is grouped.  To request multiple values, use: - &resource=1&resource=2  If CDN resource ID is not specified, data related to all CDN resources is returned.
]: nothing -> table<active_from: string, active_to: string, client_id: int, resource_id: int, cname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "resource" $resource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/statistics/raw_logs_usage/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Aggregated Logs uploader usage statistics
#
# GET /cdn/statistics/raw_logs_usage/aggregated
# operationId: aggregated-raw-logs-usage-statistics
export def "cdn-statistics-raw-logs-usage-aggregated aggregated-raw-logs-usage-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Beginning of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --qp-to: string # End of the requested time period (ISO 8601/RFC 3339 format, UTC.)
  --group-by: string # Output data grouping.  Possible value: - **resource** - Data is grouped by CDN resources.
  --resource: int # CDN resources IDs by that statistics data is grouped.  To request multiple values, use: - &resource=1&resource=2  If CDN resource ID is not specified, data related to all CDN resources is returned.
  --flat: string@bool-completer # The way the parameters are arranged in the response.  Possible values: - **true** – Flat structure is used. - **false** – Embedded structure is used (default.)
]: nothing -> record<resource: record, 1__example_: record, metrics: record, raw_logs_usage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "resource" $resource "scalar") (serialize-qp "flat" $flat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/statistics/raw_logs_usage/aggregated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get network capacity
#
# GET /cdn/advanced/v1/capacity
# operationId: get-network-capacity
export def "cdn-advanced-capacity get-network-capacity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<country_code: string, country: string, capacity: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/advanced/v1/capacity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CDN metrics
#
# POST /cdn/advanced/v1/metrics
# operationId: get-cdn-metrics
# --filter_by item shape: {field: string, op: string, values: list}
export def "cdn-advanced-metrics get-cdn-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  metrics: list # Possible values: - **`edge_bandwidth`** - Bandwidth from client to CDN (bit/s.) - **`edge_requests`** - Number of requests per interval (requests/s.) - **`edge_requests_total`** - Total number of requests per interval. - **`edge_status_1xx`** - Number of 1xx status codes from edge. - **`edge_status_200`** - Number of 200 status codes from edge. - **`edge_status_204`** - Number of 204 status codes from edge. - **`edge_status_206`** - Number of 206 status codes from edge. - **`edge_status_2xx`** - Number of 2xx status codes from edge. - **`edge_status_301`** - Number of 301 status codes from edge. - **`edge_status_302`** - Number of 302 status codes from edge. - **`edge_status_304`** - Number of 304 status codes from edge. - **`edge_status_3xx`** - Number of 3xx status codes from edge. - **`edge_status_400`** - Number of 400 status codes from edge. - **`edge_status_401`** - Number of 401 status codes from edge. - **`edge_status_403`** - Number of 403 status codes from edge. - **`edge_status_404`** - Number of 404 status codes from edge. - **`edge_status_416`** - Number of 416 status codes from edge. - **`edge_status_429`** - Number of 429 status codes from edge. - **`edge_status_4xx`** - Number of 4xx status codes from edge. - **`edge_status_500`** - Number of 500 status codes from edge. - **`edge_status_501`** - Number of 501 status codes from edge. - **`edge_status_502`** - Number of 502 status codes from edge. - **`edge_status_503`** - Number of 503 status codes from edge. - **`edge_status_504`** - Number of 504 status codes from edge. - **`edge_status_505`** - Number of 505 status codes from edge. - **`edge_status_5xx`** - Number of 5xx status codes from edge. - **`edge_hit_ratio`** - Percent of cache hits (0.0 - 1.0). - **`edge_hit_bytes`** - Number of bytes sent back when cache hits. - **`origin_bandwidth`** - Bandwidth from CDN to Origin (bit/s.) - **`origin_requests`** - Number of requests per interval (requests/s.) - **`origin_status_1xx`** - Number of 1xx status from origin. - **`origin_status_200`** - Number of 200 status from origin. - **`origin_status_204`** - Number of 204 status from origin. - **`origin_status_206`** - Number of 206 status from origin. - **`origin_status_2xx`** - Number of 2xx status from origin. - **`origin_status_301`** - Number of 301 status from origin. - **`origin_status_302`** - Number of 302 status from origin. - **`origin_status_304`** - Number of 304 status from origin. - **`origin_status_3xx`** - Number of 3xx status from origin. - **`origin_status_400`** - Number of 400 status from origin. - **`origin_status_401`** - Number of 401 status from origin. - **`origin_status_403`** - Number of 403 status from origin. - **`origin_status_404`** - Number of 404 status from origin. - **`origin_status_416`** - Number of 416 status from origin. - **`origin_status_429`** - Number of 426 status from origin. - **`origin_status_4xx`** - Number of 4xx status from origin. - **`origin_status_500`** - Number of 500 status from origin. - **`origin_status_501`** - Number of 501 status from origin. - **`origin_status_502`** - Number of 502 status from origin. - **`origin_status_503`** - Number of 503 status from origin. - **`origin_status_504`** - Number of 504 status from origin. - **`origin_status_505`** - Number of 505 status from origin. - **`origin_status_5xx`** - Number of 5xx status from origin. - **`edge_download_speed`** - Download speed from edge in KB/s (includes only requests that status was in the range [200, 300].) - **`origin_download_speed`** - Download speed from origin in KB/s (includes only requests that status was in the range [200, 300].) (e.g. [edge_status_2xx, edge_status_3xx, edge_status_4xx, edge_status_5xx])
  --body-from: string # Beginning period to fetch metrics (ISO 8601/RFC 3339 format, UTC.)  Examples: - 2021-06-14T00:00:00Z - 2021-06-14T00:00:00.000Z  The total number of points, which is determined as the difference between "from" and "to" divided by "granularity", cannot exceed 1440. Exception: "speed" metrics are limited to 72 points. (e.g. 2021-06-14T00:00:00Z)
  --body-to: string # Specifies ending period to fetch metrics (ISO 8601/RFC 3339 format, UTC)  Examples: - 2021-06-15T00:00:00Z - 2021-06-15T00:00:00.000Z  The total number of points, which is determined as the difference between "from" and "to" divided by "granularity", cannot exceed 1440. Exception: "speed" metrics are limited to 72 points. (e.g. 2021-06-15T00:00:00Z)
  --group-by: list # Output data grouping.  Possible values: - **resource** - Data is grouped by CDN resource. - **cname** - Data is grouped by common names. - **region** – Data is grouped by regions (continents.) Available for "speed" metrics only. - **isp** - Data is grouped by ISP names. Available for "speed" metrics only. (e.g. [cname])
  --granularity: string # Duration of the time blocks into which the data is divided. The value must correspond to the ISO 8601 period format.  Examples: - P1D - PT5M  Notes: - The total number of points, which is determined as the difference between "from" and "to" divided by "granularity", cannot exceed 1440. Exception: "speed" metrics are limited to 72 points. - For "speed" metrics the value must be a multiple of 5. (format: P(n)Y(n)M(n)DT(n)H(n)M), default: PT1M, e.g. P1D)
  --filter-by: list # Each item represents one filter statement. — item shape: {field: string, op: string, values: list}
]: any -> record<data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/advanced/v1/metrics")
  let body = {metrics: $metrics, from: $body_from, to: $body_to, group_by: $group_by, granularity: $granularity, filter_by: $filter_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Playground
#
# POST /cdn/advanced/v2/query
# operationId: playground
export def "cdn-advanced-query playground" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cdn/advanced/v2/query")
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get origin shielding details
#
# GET /cdn/resources/{resource_id}/shielding_v2
# operationId: get-origin-shielding-details
export def "cdn-resources-shielding-v2 get-origin-shielding-details" [
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<shielding_pop: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)/shielding_v2")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change origin shielding
#
# PUT /cdn/resources/{resource_id}/shielding_v2
# operationId: change-origin-shielding
export def "cdn-resources-shielding-v2 change-origin-shielding" [
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --shielding-pop: int # Shielding location ID.  If origin shielding is disabled, the parameter value is **null**. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)/shielding_v2")
  let body = {shielding_pop: $shielding_pop} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get origin shielding locations
#
# GET /cdn/shieldingpop_v2
# operationId: get-origin-shielding-locations
export def "cdn-shieldingpop-v2 get-origin-shielding-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of items to return in the response. Cannot exceed 1000.
  --offset: int # Number of items to skip from the beginning of the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cdn/shieldingpop_v2" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pre-validate CDN resource before issuing Let's Encrypt certificate
#
# POST /cdn/resources/{resource_id}/ssl/le/pre-validate
# operationId: pre-validate-cdn-resources-before-issuing-lets-encrypt-certificate
export def "cdn-resources-ssl-le-pre-validate pre-validate-cdn-resources-before-issuing-lets-encrypt-certificate" [
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($resource_id)/ssl/le/pre-validate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Force retry issuance of Let's Encrypt certificate
#
# POST /cdn/sslData/{cert_id}/force-retry
# operationId: force-retry-issuance-of-lets-encrypt-certificate
export def "cdn-ssl-data-force-retry force-retry-issuance-of-lets-encrypt-certificate" [
  cert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/sslData/($cert_id)/force-retry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Renew Let's Encrypt certificate
#
# POST /cdn/sslData/{cert_id}/renew
# operationId: renew-lets-encrypt-certificate
export def "cdn-ssl-data-renew renew-lets-encrypt-certificate" [
  cert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/sslData/($cert_id)/renew")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Let's Encrypt certificate issuing details
#
# GET /cdn/sslData/{cert_id}/status
# operationId: get-lets-encrypt-certificate-issuing-details
export def "cdn-ssl-data-status get-lets-encrypt-certificate-issuing-details" [
  cert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exclude: list # Listed fields will be excluded from the response.
]: nothing -> record<id: int, statuses: table<id: int, status: string, error: string, details: string, created: string, retry_after: string>, latest_status: record<id: int, status: string, error: string, details: string, created: string, retry_after: string>, started: string, finished: string, active: bool, attempts_count: int, next_attempt_time: string, resource: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exclude" $exclude "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/cdn/sslData/($cert_id)/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SSL certificate usage
#
# GET /cdn/sslData/{cert_id}/usage
# operationId: get-ssl-certificate-usage
export def "cdn-ssl-data-usage get-ssl-certificate-usage" [
  cert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<resources: table<id: int, cname: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/sslData/($cert_id)/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Issue Let's Encrypt certificate
#
# PATCH /cdn/resources/{id}
# operationId: issue-lets-encrypt-certificate
export def "cdn-resources issue-lets-encrypt-certificate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sslData: int # ID of Let's Encrypt certificate obtained [here](/docs/api-reference/cdn/ssl-certificates/add-ssl-certificate).  It can be used only with "sslEnabled": true. (e.g. 192)
  --sslEnabled: string@bool-completer # Defines whether the HTTPS protocol is enabled for CDN resource.  Possible values: - **true** — HTTPS is enabled for the CDN resource. Certificate can be linked. - **false** — HTTPS is disabled for the CDN resource. Certificate cannot be linked. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($id)")
  let body = {sslData: $sslData, sslEnabled: $sslEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke Let's Encrypt certificate
#
# PATCH /cdn/resources/{res_id}
# operationId: revoke-lets-encrypt-certificate
export def "cdn-resources revoke-lets-encrypt-certificate" [
  res_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sslData: int # ID of Let's Encrypt certificate linked to the CDN resource.  It must be **null** to revoke Let's Encrypt certificate. (nullable)
  --sslEnabled: string@bool-completer # Defines whether the HTTPS protocol is enabled for CDN resource.  Possible values: - **true** — HTTPS is enabled for the CDN resource. SSL certificate can be linked. - **false** — HTTPS is disabled for the CDN resource. SSL certificate cannot be linked.  It must be **false** to revoke the Let's Encrypt certificate. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cdn/resources/($res_id)")
  let body = {sslData: $sslData, sslEnabled: $sslEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
