# Auto-generated client for Gateway REST API v1.9
# Source: https://api.apis.guru/v2/specs/tyk.com/1.9/swagger.json
# Auth: --token flag or $env.GATEWAY_REST_API_TOKEN

const BASE_URL = "https://tyk.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GATEWAY_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://tyk.local"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "tyk-apis list" } } | get name | first)
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

# Gets a list of *API Definition* objects that are currently live on the gateway
#
# GET /tyk/apis/
export def "tyk-apis list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret
]: nothing -> table<api_id: string, auth: record<auth_header_name: string, use_cookie: bool, use_param: bool>, definition: record<key: string, location: string>, enable_jwt: bool, enable_signature_checking: bool, hmac_allowed_clock_skew: float, id: string, jwt_identity_base_field: string, jwt_policy_field_name: string, jwt_signing_method: string, jwt_source: string, name: string, notifications: record<oauth_on_keychange_url: string, shared_secret: string>, oauth_meta: record<allowed_access_types: list, allowed_authorize_types: list, auth_login_redirect: string>, org_id: string, slug: string, uptime_tests: record<CORS: record, active: bool, allowed_ips: list, cache_options: record, check_list: list, config: record, custom_middleware: record, do_not_track: string, domain: string, dont_set_quota_on_create: bool, enable_batch_request_support: bool, enable_ip_whitelisting: bool, event_handlers: record, expire_analytics_after: float, proxy: record, response_processors: list, session_lifetime: float, tags: list>, use_basic_auth: bool, use_keyless: bool, use_oauth2: bool, version_data: record<not_versioned: bool, versions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tyk/apis/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create an *API Definition* object
#
# POST /tyk/apis/
# --auth shape: {auth_header_name?: string, use_cookie?: bool, use_param?: bool}
# --definition shape: {key?: string, location?: string}
# --notifications shape: {oauth_on_keychange_url?: string, shared_secret?: string}
# --oauth_meta shape: {allowed_access_types?: list<string>, allowed_authorize_types?: list<string>, auth_login_redirect?: string}
# --uptime_tests shape: {CORS?: record, active?: bool, allowed_ips?: list<string>, cache_options?: record, check_list?: list, config?: record, custom_middleware?: record, do_not_track?: string, domain?: string, dont_set_quota_on_create?: bool, enable_batch_request_support?: bool, enable_ip_whitelisting?: bool, event_handlers?: record, expire_analytics_after?: float, proxy?: record, response_processors?: list, session_lifetime?: float, tags?: list<string>}
# --version_data shape: {not_versioned?: bool, versions?: record}
export def "tyk-apis create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string
  --body-auth: record # shape: {auth_header_name?: string, use_cookie?: bool, use_param?: bool}
  --definition: record # shape: {key?: string, location?: string}
  --enable-jwt: oneof<nothing, bool>
  --enable-signature-checking: oneof<nothing, bool>
  --hmac-allowed-clock-skew: float
  --id: string
  --jwt-identity-base-field: string
  --jwt-policy-field-name: string
  --jwt-signing-method: string
  --jwt-source: string
  --name: string
  --notifications: record # shape: {oauth_on_keychange_url?: string, shared_secret?: string}
  --oauth-meta: record # shape: {allowed_access_types?: list<string>, allowed_authorize_types?: list<string>, auth_login_redirect?: string}
  --org-id: string
  --slug: string
  --uptime-tests: record # shape: {CORS?: record, active?: bool, allowed_ips?: list<string>, cache_options?: record, check_list?: list, config?: record, custom_middleware?: record, do_not_track?: string, domain?: string, dont_set_quota_on_create?: bool, enable_batch_request_support?: bool, enable_ip_whitelisting?: bool, event_handlers?: record, expire_analytics_after?: float, proxy?: record, response_processors?: list, session_lifetime?: float, tags?: list<string>}
  --use-basic-auth: oneof<nothing, bool>
  --use-keyless: oneof<nothing, bool>
  --use-oauth2: oneof<nothing, bool>
  --version-data: record # shape: {not_versioned?: bool, versions?: record}
]: any -> record<action: string, key: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tyk/apis/")
  let req_body = {"api_id": $api_id, "auth": $body_auth, "definition": $definition, "enable_jwt": $enable_jwt, "enable_signature_checking": $enable_signature_checking, "hmac_allowed_clock_skew": $hmac_allowed_clock_skew, "id": $id, "jwt_identity_base_field": $jwt_identity_base_field, "jwt_policy_field_name": $jwt_policy_field_name, "jwt_signing_method": $jwt_signing_method, "jwt_source": $jwt_source, "name": $name, "notifications": $notifications, "oauth_meta": $oauth_meta, "org_id": $org_id, "slug": $slug, "uptime_tests": $uptime_tests, "use_basic_auth": $use_basic_auth, "use_keyless": $use_keyless, "use_oauth2": $use_oauth2, "version_data": $version_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes an *API Definition* object, if it exists
#
# DELETE /tyk/apis/{apiID}
export def "tyk-apis delete" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret
]: nothing -> record<action: string, key: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/tyk/apis/{api_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets an *API Definition* object, if it exists
#
# GET /tyk/apis/{apiID}
export def "tyk-apis get" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret
]: nothing -> record<api_id: string, auth: record<auth_header_name: string, use_cookie: bool, use_param: bool>, definition: record<key: string, location: string>, enable_jwt: bool, enable_signature_checking: bool, hmac_allowed_clock_skew: float, id: string, jwt_identity_base_field: string, jwt_policy_field_name: string, jwt_signing_method: string, jwt_source: string, name: string, notifications: record<oauth_on_keychange_url: string, shared_secret: string>, oauth_meta: record<allowed_access_types: list<string>, allowed_authorize_types: list<string>, auth_login_redirect: string>, org_id: string, slug: string, uptime_tests: record<CORS: record<allow_credentials: bool, allowed_headers: list, allowed_methods: list, allowed_origins: list, debug: bool, enable: bool, exposed_headers: list, max_age: float, options_passthrough: bool>, active: bool, allowed_ips: list<string>, cache_options: record<cache_all_safe_requests: bool, cache_timeout: float, enable_cache: bool, enable_upstream_cache_control: bool>, check_list: list<record>, config: record<expire_utime_after: float, recheck_wait: float, service_discovery: record>, custom_middleware: record<post: list, pre: list, response: list>, do_not_track: string, domain: string, dont_set_quota_on_create: bool, enable_batch_request_support: bool, enable_ip_whitelisting: bool, event_handlers: record, expire_analytics_after: float, proxy: record<check_host_against_uptime_tests: bool, enable_load_balancing: bool, listen_path: string, preserve_host_header: bool, service_discovery: record, strip_listen_path: bool, target_list: list, target_url: string>, response_processors: list<record>, session_lifetime: float, tags: list<string>>, use_basic_auth: bool, use_keyless: bool, use_oauth2: bool, version_data: record<not_versioned: bool, versions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/tyk/apis/{api_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an *API Definition* object, if it exists
#
# PUT /tyk/apis/{apiID}
# --auth shape: {auth_header_name?: string, use_cookie?: bool, use_param?: bool}
# --definition shape: {key?: string, location?: string}
# --notifications shape: {oauth_on_keychange_url?: string, shared_secret?: string}
# --oauth_meta shape: {allowed_access_types?: list<string>, allowed_authorize_types?: list<string>, auth_login_redirect?: string}
# --uptime_tests shape: {CORS?: record, active?: bool, allowed_ips?: list<string>, cache_options?: record, check_list?: list, config?: record, custom_middleware?: record, do_not_track?: string, domain?: string, dont_set_quota_on_create?: bool, enable_batch_request_support?: bool, enable_ip_whitelisting?: bool, event_handlers?: record, expire_analytics_after?: float, proxy?: record, response_processors?: list, session_lifetime?: float, tags?: list<string>}
# --version_data shape: {not_versioned?: bool, versions?: record}
export def "tyk-apis update" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret
  --body-api-id: string
  --body-auth: record # shape: {auth_header_name?: string, use_cookie?: bool, use_param?: bool}
  --definition: record # shape: {key?: string, location?: string}
  --enable-jwt: oneof<nothing, bool>
  --enable-signature-checking: oneof<nothing, bool>
  --hmac-allowed-clock-skew: float
  --id: string
  --jwt-identity-base-field: string
  --jwt-policy-field-name: string
  --jwt-signing-method: string
  --jwt-source: string
  --name: string
  --notifications: record # shape: {oauth_on_keychange_url?: string, shared_secret?: string}
  --oauth-meta: record # shape: {allowed_access_types?: list<string>, allowed_authorize_types?: list<string>, auth_login_redirect?: string}
  --org-id: string
  --slug: string
  --uptime-tests: record # shape: {CORS?: record, active?: bool, allowed_ips?: list<string>, cache_options?: record, check_list?: list, config?: record, custom_middleware?: record, do_not_track?: string, domain?: string, dont_set_quota_on_create?: bool, enable_batch_request_support?: bool, enable_ip_whitelisting?: bool, event_handlers?: record, expire_analytics_after?: float, proxy?: record, response_processors?: list, session_lifetime?: float, tags?: list<string>}
  --use-basic-auth: oneof<nothing, bool>
  --use-keyless: oneof<nothing, bool>
  --use-oauth2: oneof<nothing, bool>
  --version-data: record # shape: {not_versioned?: bool, versions?: record}
]: any -> record<action: string, key: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/tyk/apis/{api_id}"))
  let req_body = {"api_id": $body_api_id, "auth": $body_auth, "definition": $definition, "enable_jwt": $enable_jwt, "enable_signature_checking": $enable_signature_checking, "hmac_allowed_clock_skew": $hmac_allowed_clock_skew, "id": $id, "jwt_identity_base_field": $jwt_identity_base_field, "jwt_policy_field_name": $jwt_policy_field_name, "jwt_signing_method": $jwt_signing_method, "jwt_source": $jwt_source, "name": $name, "notifications": $notifications, "oauth_meta": $oauth_meta, "org_id": $org_id, "slug": $slug, "uptime_tests": $uptime_tests, "use_basic_auth": $use_basic_auth, "use_keyless": $use_keyless, "use_oauth2": $use_oauth2, "version_data": $version_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets the health check values for an API if it is being recorded
#
# GET /tyk/health/
export def "tyk-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # API ID to query (format: string)
  --x-tyk-authorization: string # tyk gateway shared secret
]: nothing -> record<average_requests_per_second: float, average_upstream_latency: float, key_failures_per_second: float, quota_violations_per_second: float, throttle_requests_per_second: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_id" $api_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tyk/health/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a list of *key* IDs (will only work with non-hashed installations)
#
# GET /tyk/keys/
export def "tyk-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # Back-end to target (format: string)
  --x-tyk-authorization: string # tyk gateway shared secret
]: nothing -> record<keys: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_id" $api_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tyk/keys/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new *API token* with the *session object* defined in the body
#
# POST /tyk/keys/create
# --basic_auth_data shape: {hash_type?: ""|"bcrypt", password?: string}
# --jwt_data shape: {secret?: string}
# --monitor shape: {trigger_limits?: list<string>}
export def "tyk-keys-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --suppress-reset: float # Adding the `suppress_reset` parameter and setting it to `1`, will cause Tyk to not reset the quota limit that is in the current live quota manager. By default Tyk will reset the quota in the live quota manager (initialising it) when ADDing a key. Adding the `suppress_reset` flag to the URL parameters will avoid this behaviour. (format: integer)
  --x-tyk-authorization: string # tyk gateway shared secret
  --access-rights: record
  --allowance: float
  --apply-policy-id: string
  --basic-auth-data: record # shape: {hash_type?: ""|"bcrypt", password?: string}
  --expires: float
  --hmac-enabled: oneof<nothing, bool>
  --hmac-string: string
  --is-inactive: oneof<nothing, bool>
  --jwt-data: record # shape: {secret?: string}
  --meta-data: record
  --monitor: record # shape: {trigger_limits?: list<string>}
  --oauth-client-id: string
  --org-id: string
  --per: float
  --quota-max: float
  --quota-remaining: float
  --quota-renewal-rate: string
  --quota-renews: float
  --rate: float
  --tags: list<string>
]: any -> record<action: string, key: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "suppress_reset" $suppress_reset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tyk/keys/create" $qp)
  let req_body = {"access_rights": $access_rights, "allowance": $allowance, "apply_policy_id": $apply_policy_id, "basic_auth_data": $basic_auth_data, "expires": $expires, "hmac_enabled": $hmac_enabled, "hmac_string": $hmac_string, "is_inactive": $is_inactive, "jwt_data": $jwt_data, "meta_data": $meta_data, "monitor": $monitor, "oauth_client_id": $oauth_client_id, "org_id": $org_id, "per": $per, "quota_max": $quota_max, "quota_remaining": $quota_remaining, "quota_renewal_rate": $quota_renewal_rate, "quota_renews": $quota_renews, "rate": $rate, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Remove this *API token* from the gateway, this will completely destroy the token and metadata associated with the token and instantly stop access from being granted
#
# DELETE /tyk/keys/{keyId}
export def "tyk-keys delete" [
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
  --api-id: string # Back-end to target (format: string)
  --x-tyk-authorization: string # tyk gateway shared secret
]: nothing -> record<action: string, key: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_id" $api_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_id: (encode-path-segment $key_id)} | format pattern "/tyk/keys/{key_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add a pre-specified *API token* with the *session object* defined in the body, this operatin creates a custom token that dsoes not use the gateway naming convention for tokens
#
# POST /tyk/keys/{keyId}
# --basic_auth_data shape: {hash_type?: ""|"bcrypt", password?: string}
# --jwt_data shape: {secret?: string}
# --monitor shape: {trigger_limits?: list<string>}
export def "tyk-keys create" [
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
  --x-tyk-authorization: string # tyk gateway shared secret
  --access-rights: record
  --allowance: float
  --apply-policy-id: string
  --basic-auth-data: record # shape: {hash_type?: ""|"bcrypt", password?: string}
  --expires: float
  --hmac-enabled: oneof<nothing, bool>
  --hmac-string: string
  --is-inactive: oneof<nothing, bool>
  --jwt-data: record # shape: {secret?: string}
  --meta-data: record
  --monitor: record # shape: {trigger_limits?: list<string>}
  --oauth-client-id: string
  --org-id: string
  --per: float
  --quota-max: float
  --quota-remaining: float
  --quota-renewal-rate: string
  --quota-renews: float
  --rate: float
  --tags: list<string>
]: any -> record<action: string, key: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({key_id: (encode-path-segment $key_id)} | format pattern "/tyk/keys/{key_id}"))
  let req_body = {"access_rights": $access_rights, "allowance": $allowance, "apply_policy_id": $apply_policy_id, "basic_auth_data": $basic_auth_data, "expires": $expires, "hmac_enabled": $hmac_enabled, "hmac_string": $hmac_string, "is_inactive": $is_inactive, "jwt_data": $jwt_data, "meta_data": $meta_data, "monitor": $monitor, "oauth_client_id": $oauth_client_id, "org_id": $org_id, "per": $per, "quota_max": $quota_max, "quota_remaining": $quota_remaining, "quota_renewal_rate": $quota_renewal_rate, "quota_renews": $quota_renews, "rate": $rate, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update an *API token* with the *session object* defined in the body, this operatin overwrites the existing object
#
# PUT /tyk/keys/{keyId}
# --basic_auth_data shape: {hash_type?: ""|"bcrypt", password?: string}
# --jwt_data shape: {secret?: string}
# --monitor shape: {trigger_limits?: list<string>}
export def "tyk-keys update" [
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
  --suppress-reset: float # Adding the `suppress_reset` parameter and setting it to `1`, will cause Tyk to not reset the quota limit that is in the current live quota manager. By default Tyk will reset the quota in the live quota manager (initialising it) when ADDing a key. Adding the `suppress_reset` flag to the URL parameters will avoid this behaviour. (format: integer)
  --api-id: string # Back-end to target (format: string)
  --x-tyk-authorization: string # tyk gateway shared secret
  --access-rights: record
  --allowance: float
  --apply-policy-id: string
  --basic-auth-data: record # shape: {hash_type?: ""|"bcrypt", password?: string}
  --expires: float
  --hmac-enabled: oneof<nothing, bool>
  --hmac-string: string
  --is-inactive: oneof<nothing, bool>
  --jwt-data: record # shape: {secret?: string}
  --meta-data: record
  --monitor: record # shape: {trigger_limits?: list<string>}
  --oauth-client-id: string
  --org-id: string
  --per: float
  --quota-max: float
  --quota-remaining: float
  --quota-renewal-rate: string
  --quota-renews: float
  --rate: float
  --tags: list<string>
]: any -> record<action: string, key: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "suppress_reset" $suppress_reset "scalar") (serialize-qp "api_id" $api_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_id: (encode-path-segment $key_id)} | format pattern "/tyk/keys/{key_id}") $qp)
  let req_body = {"access_rights": $access_rights, "allowance": $allowance, "apply_policy_id": $apply_policy_id, "basic_auth_data": $basic_auth_data, "expires": $expires, "hmac_enabled": $hmac_enabled, "hmac_string": $hmac_string, "is_inactive": $is_inactive, "jwt_data": $jwt_data, "meta_data": $meta_data, "monitor": $monitor, "oauth_client_id": $oauth_client_id, "org_id": $org_id, "per": $per, "quota_max": $quota_max, "quota_remaining": $quota_remaining, "quota_renewal_rate": $quota_renewal_rate, "quota_renews": $quota_renews, "rate": $rate, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# The final request from an authorising party for a redirect URI during the Tyk OAuth flow
#
# POST /tyk/oauth/authorize-client/
export def "tyk-oauth-authorize-client create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret
  response_type: string # Should be provided by requesting client as part of authorisation request, this should be either `code` or `token` depending on the methods you have specified for the API
  client_id: string # Should be provided by requesting client as part of authorisation request. The Client ID that is making the request
  redirect_uri: string # Should be provided by requesting client as part of authorisation request. Must match with the record stored with Tyk
  key_rules: string # A string representation of a *Session Object (form-encoded)*. This should be provided by your application in order to apply any quotas or rules to the key
]: any -> record<access_token: string, code: string, expires_in: float, redirect_to: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tyk/oauth/authorize-client/")
  let req_body = {"response_type": $response_type, "client_id": $client_id, "redirect_uri": $redirect_uri, "key_rules": $key_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Create a new OAuth client
#
# POST /tyk/oauth/clients/create
export def "tyk-oauth-clients-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret
  --api-id: string
  --redirect-uri: string
]: any -> record<client_id: string, redirect_uri: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tyk/oauth/clients/create")
  let req_body = {"api_id": $api_id, "redirect_uri": $redirect_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a list of OAuth clients bound to this back end
#
# GET /tyk/oauth/clients/{apiId}
export def "tyk-oauth-clients get" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret
]: nothing -> table<client_id: string, redirect_uri: string, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/tyk/oauth/clients/{api_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete the OAuth client
#
# DELETE /tyk/oauth/clients/{apiId}/{clientId}
export def "tyk-oauth-clients delete" [
  api_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret
]: nothing -> record<action: string, key: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), client_id: (encode-path-segment $client_id)} | format pattern "/tyk/oauth/clients/{api_id}/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Invalidate a refresh token
#
# DELETE /tyk/oauth/refresh/{keyId}
export def "tyk-oauth-refresh delete" [
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
  --api-id: string # API ID
  --x-tyk-authorization: string # tyk gateway shared secret
]: nothing -> record<action: string, key: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiID" $api_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key_id: (encode-path-segment $key_id)} | format pattern "/tyk/oauth/refresh/{key_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Will reload the targetted gateway
#
# GET /tyk/reload/
export def "tyk-reload get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret
]: nothing -> record<error: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tyk/reload/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Will reload the cluster via the targeted gateway
#
# GET /tyk/reload/group
export def "tyk-reload-group get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret
]: nothing -> record<error: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tyk/reload/group")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-tyk-authorization": $x_tyk_authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
