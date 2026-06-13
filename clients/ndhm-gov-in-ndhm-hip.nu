# Auto-generated client for Health Repository Provider Specifications for HIP v0.5
# Source: https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-hip/0.5/openapi.json
# Auth: --token flag or $env.HEALTH_REPOSITORY_PROVIDER_SPECIFICATIONS_FOR_HIP_TOKEN

const BASE_URL = "https://dev.ndhm.gov.in/gateway"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HEALTH_REPOSITORY_PROVIDER_SPECIFICATIONS_FOR_HIP_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://dev.ndhm.gov.in/gateway" "https://your-hrp-server.com" "https://dev.ndhm.gov.in/patient-hiu"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def status-completer [] { ["ACKNOWLEDGED" "ERRORED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v05-well-known-openid-configuration get" } } | get name | first)
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

# Get openid configuration
#
# GET /v0.5/.well-known/openid-configuration
export def "v05-well-known-openid-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<jwks_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/.well-known/openid-configuration")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Discover patient's accounts
#
# POST /v0.5/care-contexts/discover
# --patient shape: {gender: "M"|"F"|"O"|"U", id: string, name: string, unverifiedIdentifiers?: list, verifiedIdentifiers: list, yearOfBirth: int}
export def "v05-care-contexts-discover post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  patient: record # shape: {gender: "M"|"F"|"O"|"U", id: string, name: string, unverifiedIdentifiers?: list, verifiedIdentifiers: list, yearOfBirth: int}
  requestId: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transactionId: string # correlation-Id for patient discovery and subsequent care context linkage (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://your-hrp-server.com")
  let full_url = (build-url $base "/v0.5/care-contexts/discover")
  let body = {patient: $patient, requestId: $requestId, timestamp: $timestamp, transactionId: $transactionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Response to patient's account discovery request
#
# POST /v0.5/care-contexts/on-discover
# --error shape: {code: "1000"|"10001", message: string}
# --patient shape: {careContexts: list, display: string, matchedBy?: list, referenceNumber: string}
# --resp shape: {requestId: string}
export def "v05-care-contexts-on-discover post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  --patient: record # shape: {careContexts: list, display: string, matchedBy?: list, referenceNumber: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transactionId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/care-contexts/on-discover")
  let body = {error: $body_error, patient: $patient, requestId: $requestId, resp: $resp, timestamp: $timestamp, transactionId: $transactionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get certs for JWT verification
#
# GET /v0.5/certs
export def "v05-certs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<keys: table<alg: string, e: string, kid: string, kty: string, n: string, use: string, x5c: list, x5t: string, x5t_S256: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/certs")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Consent notification
#
# POST /v0.5/consents/hip/notify
# --notification shape: {consentDetail: record, consentId: string, signature: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
export def "v05-consents-hip-notify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  notification: record # shape: {consentDetail: record, consentId: string, signature: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://your-hrp-server.com")
  let full_url = (build-url $base "/v0.5/consents/hip/notify")
  let body = {notification: $notification, requestId: $requestId, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Consent notification
#
# POST /v0.5/consents/hip/on-notify
# --acknowledgement shape: {consentId: string, status: "OK"|"UNKNOWN"}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v05-consents-hip-on-notify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  --acknowledgement: record # shape: {consentId: string, status: "OK"|"UNKNOWN"}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consents/hip/on-notify")
  let body = {acknowledgement: $acknowledgement, error: $body_error, requestId: $requestId, resp: $resp, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Health information data request
#
# POST /v0.5/health-information/hip/on-request
# --error shape: {code: "1000"|"10001", message: string}
# --hiRequest shape: {sessionStatus: "ACKNOWLEDGED", transactionId: string}
# --resp shape: {requestId: string}
export def "v05-health-information-hip-on-request post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  --hiRequest: record # shape: {sessionStatus: "ACKNOWLEDGED", transactionId: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/health-information/hip/on-request")
  let body = {error: $body_error, hiRequest: $hiRequest, requestId: $requestId, resp: $resp, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Health information data request
#
# POST /v0.5/health-information/hip/request
# --hiRequest shape: {consent: record, dataPushUrl: string, dateRange: record, keyMaterial: record}
export def "v05-health-information-hip-request post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  hiRequest: record # shape: {consent: record, dataPushUrl: string, dateRange: record, keyMaterial: record}
  requestId: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transactionId: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://your-hrp-server.com")
  let full_url = (build-url $base "/v0.5/health-information/hip/request")
  let body = {hiRequest: $hiRequest, requestId: $requestId, timestamp: $timestamp, transactionId: $transactionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Notifications corresponding to events during data flow
#
# POST /v0.5/health-information/notify
# --notification shape: {consentId: string, doneAt: string, notifier: record, statusNotification: record, transactionId: string}
export def "v05-health-information-notify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  notification: record # shape: {consentId: string, doneAt: string, notifier: record, statusNotification: record, transactionId: string}
  requestId: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/health-information/notify")
  let body = {notification: $notification, requestId: $requestId, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# health information transfer API
#
# POST /v0.5/health-information/transfer
# --keyMaterial shape: {cryptoAlg: string, curve: string, dhPublicKey: record, nonce: string}
export def "v05-health-information-transfer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  entries: list
  keyMaterial: record # shape: {cryptoAlg: string, curve: string, dhPublicKey: record, nonce: string}
  pageCount: int # Total number of pages.
  pageNumber: int # Current page number.
  transactionId: string # Transaction Id issued when data requested. (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://dev.ndhm.gov.in/patient-hiu")
  let full_url = (build-url $base "/v0.5/health-information/transfer")
  let body = {entries: $entries, keyMaterial: $keyMaterial, pageCount: $pageCount, pageNumber: $pageNumber, transactionId: $transactionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get consent request status
#
# GET /v0.5/heartbeat
export def "v05-heartbeat get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<error: record<code: int, message: string>, status: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://your-hrp-server.com")
  let full_url = (build-url $base "/v0.5/heartbeat")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# API for HIP initiated care-context linking for patient
#
# POST /v0.5/links/link/add-contexts
# --link shape: {accessToken: string, patient: record}
export def "v05-links-link-add-contexts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  link: record # shape: {accessToken: string, patient: record}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/add-contexts")
  let body = {link: $link, requestId: $requestId, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Token submission by Consent Manager for link confirmation
#
# POST /v0.5/links/link/confirm
# --confirmation shape: {linkRefNumber: string, token: string}
export def "v05-links-link-confirm post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  confirmation: record # shape: {linkRefNumber: string, token: string}
  requestId: string # format: uuid
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://your-hrp-server.com")
  let full_url = (build-url $base "/v0.5/links/link/confirm")
  let body = {confirmation: $confirmation, requestId: $requestId, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Link patient's care contexts
#
# POST /v0.5/links/link/init
# --patient shape: {careContexts: list, id: string, referenceNumber: string}
export def "v05-links-link-init post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  patient: record # shape: {careContexts: list, id: string, referenceNumber: string}
  requestId: string # format: uuid
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transactionId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://your-hrp-server.com")
  let full_url = (build-url $base "/v0.5/links/link/init")
  let body = {patient: $patient, requestId: $requestId, timestamp: $timestamp, transactionId: $transactionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# callback API for HIP initiated patient linking /link/add-context
#
# POST /v0.5/links/link/on-add-contexts
# --acknowledgement shape: {status: "SUCCESS"}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v05-links-link-on-add-contexts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  --acknowledgement: record # shape: {status: "SUCCESS"}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://your-hrp-server.com")
  let full_url = (build-url $base "/v0.5/links/link/on-add-contexts")
  let body = {acknowledgement: $acknowledgement, error: $body_error, requestId: $requestId, resp: $resp, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Token authenticated by HIP, indicating completion of linkage of care-contexts
#
# POST /v0.5/links/link/on-confirm
# --error shape: {code: "1000"|"10001", message: string}
# --patient shape: {careContexts: list, display: string, referenceNumber: string}
# --resp shape: {requestId: string}
export def "v05-links-link-on-confirm post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  --patient: record # shape: {careContexts: list, display: string, referenceNumber: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/on-confirm")
  let body = {error: $body_error, patient: $patient, requestId: $requestId, resp: $resp, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Response to patient's care context link request
#
# POST /v0.5/links/link/on-init
# --error shape: {code: "1000"|"10001", message: string}
# --link shape: {authenticationType: "DIRECT"|"MEDIATED", meta?: record, referenceNumber: string}
# --resp shape: {requestId: string}
export def "v05-links-link-on-init post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  --link: record # shape: {authenticationType: "DIRECT"|"MEDIATED", meta?: record, referenceNumber: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transactionId: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/on-init")
  let body = {error: $body_error, link: $link, requestId: $requestId, resp: $resp, timestamp: $timestamp, transactionId: $transactionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Response to patient's share profile request
#
# POST /v0.5/patients/profile/on-share
# --acknowledgement shape: {healthId: string, status: "SUCCESS"|"FAILURE"}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v05-patients-profile-on-share post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  acknowledgement: record # shape: {healthId: string, status: "SUCCESS"|"FAILURE"}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/patients/profile/on-share")
  let body = {acknowledgement: $acknowledgement, error: $body_error, requestId: $requestId, resp: $resp, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Share patient profile details
#
# POST /v0.5/patients/profile/share
# --patient shape: {hipCode?: string, userDemographics: record}
export def "v05-patients-profile-share post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  patient: record # shape: {hipCode?: string, userDemographics: record}
  requestId: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://your-hrp-server.com")
  let full_url = (build-url $base "/v0.5/patients/profile/share")
  let body = {patient: $patient, requestId: $requestId, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# API for HIP to send SMS notifications to patients
#
# POST /v0.5/patients/sms/notify
# --notification shape: {careContextInfo: string, deeplinkUrl?: string, hip: record, phoneNo: string, receiverName?: string}
export def "v05-patients-sms-notify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  notification: record # shape: {careContextInfo: string, deeplinkUrl?: string, hip: record, phoneNo: string, receiverName?: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/patients/sms/notify")
  let body = {notification: $notification, requestId: $requestId, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Acknowledgment response for SMS notification sent to patient by HIP
#
# POST /v0.5/patients/sms/on-notify
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v05-patients-sms-on-notify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  --status: string@status-completer
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/patients/sms/on-notify")
  let body = {error: $body_error, requestId: $requestId, resp: $resp, status: $status, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get access token
#
# POST /v0.5/sessions
export def "v05-sessions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  clientId: string
  clientSecret: string
]: any -> record<accessToken: string, expiresIn: int, refreshExpiresIn: int, refreshToken: string, tokenType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/sessions")
  let body = {clientId: $clientId, clientSecret: $clientSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Confirmation request sending token, otp or other authentication details from HIP/HIU for confirmation
#
# POST /v0.5/users/auth/confirm
# --credential shape: {authCode?: string, demographic?: record}
export def "v05-users-auth-confirm post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  credential: record # note, demographic details are only required for demographic auth at this point. — shape: {authCode?: string, demographic?: record}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transactionId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/confirm")
  let body = {credential: $credential, requestId: $requestId, timestamp: $timestamp, transactionId: $transactionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a patient's authentication modes relevant to specified purpose
#
# POST /v0.5/users/auth/fetch-modes
# --query shape: {id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
export def "v05-users-auth-fetch-modes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  --body-query: record # shape: {id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/fetch-modes")
  let body = {query: $body_query, requestId: $requestId, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Initialize authentication from HIP
#
# POST /v0.5/users/auth/init
# --query shape: {authMode?: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
export def "v05-users-auth-init post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  --body-query: record # shape: {authMode?: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/init")
  let body = {query: $body_query, requestId: $requestId, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# notification API in case of DIRECT mode of authentication by the CM
#
# POST /v0.5/users/auth/notify
# --auth shape: {accessToken?: string, patient?: record, status: "GRANTED"|"DENIED", transactionId: string, validity?: record}
export def "v05-users-auth-notify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  --X-HIU-ID: string # Identifier of the health information user to which the request was intended.
  --body-auth: record # depending on the purpose of auth, as specified in /auth/init, the response may include the following    1. LINK - only returns **accessToken**   2. KYC - only returns **patient**   3. KYC_AND_LINK - returns both **accessToken** and **patient** — shape: {accessToken?: string, patient?: record, status: "GRANTED"|"DENIED", transactionId: string, validity?: record}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/notify")
  let body = {auth: $body_auth, requestId: $requestId, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID, "X-HIU-ID": $X_HIU_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# callback API for /auth/confirm (in case of MEDIATED auth) to confirm user authentication or not
#
# POST /v0.5/users/auth/on-confirm
# --auth shape: {accessToken?: string, patient?: record, validity?: record}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v05-users-auth-on-confirm post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  --X-HIU-ID: string # Identifier of the health information user to which the request was intended.
  --body-auth: record # depending on the purpose of auth, as specified in /auth/init, the response may include the following    1. LINK - only returns **accessToken**   2. KYC - only returns **patient**   3. KYC_AND_LINK - returns both **accessToken** and **patient** — shape: {accessToken?: string, patient?: record, validity?: record}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://your-hrp-server.com")
  let full_url = (build-url $base "/v0.5/users/auth/on-confirm")
  let body = {auth: $body_auth, error: $body_error, requestId: $requestId, resp: $resp, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID, "X-HIU-ID": $X_HIU_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Identification result for a consent-manager user-id
#
# POST /v0.5/users/auth/on-fetch-modes
# --auth shape: {modes: list, purpose: "LINK"|"KYC"|"KYC_AND_LINK"}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v05-users-auth-on-fetch-modes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  --X-HIU-ID: string # Identifier of the health information user to which the request was intended.
  --body-auth: record # shape: {modes: list, purpose: "LINK"|"KYC"|"KYC_AND_LINK"}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/on-fetch-modes")
  let body = {auth: $body_auth, error: $body_error, requestId: $requestId, resp: $resp, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID, "X-HIU-ID": $X_HIU_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Response to user authentication initialization from HIP
#
# POST /v0.5/users/auth/on-init
# --auth shape: {meta?: record, mode: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", transactionId: string}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v05-users-auth-on-init post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-HIP-ID: string # Identifier of the health information provider to which the request was intended.
  --X-HIU-ID: string # Identifier of the health information user to which the request was intended.
  --body-auth: record # shape: {meta?: record, mode: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", transactionId: string}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://your-hrp-server.com")
  let full_url = (build-url $base "/v0.5/users/auth/on-init")
  let body = {auth: $body_auth, error: $body_error, requestId: $requestId, resp: $resp, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-HIP-ID": $X_HIP_ID, "X-HIU-ID": $X_HIU_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# callback API by HIU/HIPs as acknowledgement of auth notification
#
# POST /v0.5/users/auth/on-notify
# --acknowledgement shape: {status: "OK"}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v05-users-auth-on-notify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge.
  --X-CM-ID: string # Suffix of the consent manager to which the request was intended.
  --acknowledgement: record # shape: {status: "OK"}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  requestId: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/on-notify")
  let body = {acknowledgement: $acknowledgement, error: $body_error, requestId: $requestId, resp: $resp, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-CM-ID": $X_CM_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
