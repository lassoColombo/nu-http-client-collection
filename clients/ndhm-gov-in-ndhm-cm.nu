# Auto-generated client for Health Data Consent Manager v0.5
# Source: https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-cm/0.5/openapi.json
# Auth: --token flag or $env.HEALTH_DATA_CONSENT_MANAGER_TOKEN

const BASE_URL = "https://dev.ndhm.gov.in/cm"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HEALTH_DATA_CONSENT_MANAGER_TOKEN | default "" }
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

def base-url-completer [] { ["https://dev.ndhm.gov.in/cm"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v0-5-care-contexts-on-discover create" } } | get name | first)
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

# Response to patient's account discovery request
#
# POST /v0.5/care-contexts/on-discover
# --error shape: {code: "1000"|"10001", message: string}
# --patient shape: {careContexts: list, display: string, matchedBy?: list<string>, referenceNumber: string}
# --resp shape: {requestId: string}
export def "v0-5-care-contexts-on-discover create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  --patient: record # shape: {careContexts: list, display: string, matchedBy?: list<string>, referenceNumber: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transaction_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/care-contexts/on-discover")
  let req_body = {"error": $body_error, "patient": $patient, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create consent request
#
# POST /v0.5/consent-requests/init
# --consent shape: {careContexts?: list, hiTypes: list<string>, hip?: record, hiu: record, patient: record, permission: record, purpose: record, requester: record}
export def "v0-5-consent-requests-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  consent: record # shape: {careContexts?: list, hiTypes: list<string>, hip?: record, hiu: record, patient: record, permission: record, purpose: record, requester: record}
  request_id: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consent-requests/init")
  let req_body = {"consent": $consent, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get consent request status
#
# POST /v0.5/consent-requests/status
export def "v0-5-consent-requests-status create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  consent_request_id: string
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consent-requests/status")
  let req_body = {"consentRequestId": $consent_request_id, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get consent artefact
#
# POST /v0.5/consents/fetch
export def "v0-5-consents-fetch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  consent_id: string
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consents/fetch")
  let req_body = {"consentId": $consent_id, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Consent notification
#
# POST /v0.5/consents/hip/on-notify
# --acknowledgement shape: {consentId: string, status: "OK"|"UNKNOWN"}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v0-5-consents-hip-on-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --acknowledgement: record # shape: {consentId: string, status: "OK"|"UNKNOWN"}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consents/hip/on-notify")
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Consent notification
#
# POST /v0.5/consents/hiu/on-notify
# --acknowledgement item shape: {consentId: string, status: "OK"|"UNKNOWN"}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v0-5-consents-hiu-on-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --acknowledgement: list # item shape: {consentId: string, status: "OK"|"UNKNOWN"}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consents/hiu/on-notify")
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Notifications corresponding to events during data flow
#
# POST /v0.5/health-information/notify
# --notification shape: {consentId: string, doneAt: string, notifier: record, statusNotification: record, transactionId: string}
export def "v0-5-health-information-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  notification: record # shape: {consentId: string, doneAt: string, notifier: record, statusNotification: record, transactionId: string}
  request_id: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/health-information/notify")
  let req_body = {"notification": $notification, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Health information data request acknowledgement from HIP
#
# POST /v0.5/health-information/on-request
# --error shape: {code: "1000"|"10001", message: string}
# --hiRequest shape: {sessionStatus: "ACKNOWLEDGED", transactionId: string}
# --resp shape: {requestId: string}
export def "v0-5-health-information-on-request create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  --hi-request: record # shape: {sessionStatus: "ACKNOWLEDGED", transactionId: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/health-information/on-request")
  let req_body = {"error": $body_error, "hiRequest": $hi_request, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Health information data request from HIU
#
# POST /v0.5/health-information/request
# --hiRequest shape: {consent: record, dataPushUrl: string, dateRange: record, keyMaterial: record}
export def "v0-5-health-information-request create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  hi_request: record # shape: {consent: record, dataPushUrl: string, dateRange: record, keyMaterial: record}
  request_id: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/health-information/request")
  let req_body = {"hiRequest": $hi_request, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get consent request status
#
# GET /v0.5/heartbeat
export def "v0-5-heartbeat get" [
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/heartbeat")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# API for HIP initiated care-context linking for patient
#
# POST /v0.5/links/link/add-contexts
# --link shape: {accessToken: string, patient: record}
export def "v0-5-links-link-add-contexts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  link: record # shape: {accessToken: string, patient: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/add-contexts")
  let req_body = {"link": $link, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Token authenticated by HIP, indicating completion of linkage of care-contexts
#
# POST /v0.5/links/link/on-confirm
# --error shape: {code: "1000"|"10001", message: string}
# --patient shape: {careContexts: list, display: string, referenceNumber: string}
# --resp shape: {requestId: string}
export def "v0-5-links-link-on-confirm create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  --patient: record # shape: {careContexts: list, display: string, referenceNumber: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/on-confirm")
  let req_body = {"error": $body_error, "patient": $patient, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Response to patient's care context link request
#
# POST /v0.5/links/link/on-init
# --error shape: {code: "1000"|"10001", message: string}
# --link shape: {authenticationType: "DIRECT"|"MEDIATED", meta?: record, referenceNumber: string}
# --resp shape: {requestId: string}
export def "v0-5-links-link-on-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  --link: record # shape: {authenticationType: "DIRECT"|"MEDIATED", meta?: record, referenceNumber: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transaction_id: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/on-init")
  let req_body = {"error": $body_error, "link": $link, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Identify a patient by her consent-manager user-id
#
# POST /v0.5/patients/find
# --query shape: {patient: record, requester: record}
export def "v0-5-patients-find create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  query: record # shape: {patient: record, requester: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/patients/find")
  let req_body = {"query": $query, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Response to patient's share profile request
#
# POST /v0.5/patients/profile/on-share
# --acknowledgement shape: {healthId: string, status: "SUCCESS"|"FAILURE"}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v0-5-patients-profile-on-share create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  acknowledgement: record # shape: {healthId: string, status: "SUCCESS"|"FAILURE"}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/patients/profile/on-share")
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Request for subscription
#
# POST /v0.5/subscription-requests/cm/init
# --subscription shape: {categories: list<string>, hips?: list, hiu: record, patient: record, period: record, purpose: record}
export def "v0-5-subscription-requests-cm-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  request_id: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  subscription: record # shape: {categories: list<string>, hips?: list, hiu: record, patient: record, period: record, purpose: record}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/subscription-requests/cm/init")
  let req_body = {"requestId": $request_id, "subscription": $subscription, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Callback API for /subscription-requests/hiu/notify to acknowledge receipt of notification.
#
# POST /v0.5/subscription-requests/hiu/on-notify
# --acknowledgement shape: {status: "OK", subscriptionRequestId: string}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v0-5-subscription-requests-hiu-on-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --acknowledgement: record # shape: {status: "OK", subscriptionRequestId: string}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/subscription-requests/hiu/on-notify")
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Callback API for /subscriptions/hiu/notify to acknowledge receipt of notification.
#
# POST /v0.5/subscriptions/hiu/on-notify
# --acknowledgement shape: {eventId: string, status: "OK"}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v0-5-subscriptions-hiu-on-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --acknowledgement: record # shape: {eventId: string, status: "OK"}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/subscriptions/hiu/on-notify")
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Confirmation request sending token, otp or other authentication details from HIP/HIU for confirmation
#
# POST /v0.5/users/auth/confirm
# --credential shape: {authCode?: string, demographic?: record}
export def "v0-5-users-auth-confirm create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  credential: record # note, demographic details are only required for demographic verfication. — shape: {authCode?: string, demographic?: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transaction_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/confirm")
  let req_body = {"credential": $credential, "requestId": $request_id, "timestamp": $timestamp, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get a patient's authentication modes relevant to specified purpose
#
# POST /v0.5/users/auth/fetch-modes
# --query shape: {id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
export def "v0-5-users-auth-fetch-modes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  query: record # shape: {id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/fetch-modes")
  let req_body = {"query": $query, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Initialize authentication from HIP
#
# POST /v0.5/users/auth/init
# --query shape: {authMode?: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
export def "v0-5-users-auth-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  query: record # shape: {authMode?: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/init")
  let req_body = {"query": $query, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# callback API from HIU/HIPs as acknowledgement of auth notification (in case of DIRECT auth)
#
# POST /v0.5/users/auth/on-notify
# --acknowledgement shape: {status: "OK"}
# --error shape: {code: "1000"|"10001", message: string}
# --resp shape: {requestId: string}
export def "v0-5-users-auth-on-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --acknowledgement: record # shape: {status: "OK"}
  --body-error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/on-notify")
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
