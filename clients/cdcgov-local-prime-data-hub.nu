# Auto-generated client for Prime ReportStream v0.2.0-oas3
# Source: https://api.apis.guru/v2/specs/cdcgov.local/prime-data-hub/0.2.0-oas3/openapi.json
# Auth: --token flag or $env.PRIME_REPORTSTREAM_TOKEN

const BASE_URL = "http://cdcgov.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PRIME_REPORTSTREAM_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-functions-key" => { {scheme: $scheme, headers: {x-functions-key: $token_val}, query: "", location: "header"} }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# HEAD — bodyless; default surfaces just the headers on success
def send-head [req: record, insecure: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = (http head --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure $req.url)
  if (not $full) and (not $allow_errors) and (status-ok $resp.status $ok_codes) { return $resp.headers }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://cdcgov.local"] }
def auth-scheme-completer [] { ["x-functions-key" "bearer"] }

# Completers for enum parameters
def option-completer [] { ["CheckConnections" "SendImmediately" "SkipInvalidItems" "SkipSend" "ValidatePayload"] }
def jurisdiction-completer [] { ["County" "National" "State"] }
def format-completer [] { ["CSV"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "reports create" } } | get name | first)
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

# Post a report to the data hub
#
# POST /reports
export def "reports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client: string # The client's name that matches the client name in metadata (e.g. simple_report)
  --option: string@option-completer # Optional ways to process the request (e.g. ValidatePayload)
  --default: list<string> # Dynamic default values for an element. ':' or %3A is used to seperate element name and value (e.g. processing_mode_code%3AD)
  --route-to: list<string> # A comma speparated list of receiver names. Limit the list of possible receivers to these receivers. (e.g. fl-phd.elr,fl-phd.download)
  --body: string
]: any -> record<destinationCount: int, destinations: table<itemCount: int, organization: string, organization_id: string, sending_at: string, service: string>, errorCount: int, errors: table<detail: string, id: string, scope: string>, id: string, reportItemCount: int, routing: table<destinations: list, reportIndex: int, trackingId: string>, timestamp: string, topic: string, warningCount: int, warnings: table<detail: string, id: string, scope: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-functions-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client" $client "scalar") (serialize-qp "option" $option "scalar") (serialize-qp "default" $default "csv") (serialize-qp "routeTo" $route_to "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/reports" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"client": $client, "option": $option, "default": $default, "routeTo": $route_to} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/csv"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# The settings for all organizations of the system. Must have admin access.
#
# GET /settings/organizations
export def "settings-organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<countyName: string, description: string, jurisdiction: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, stateCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/organizations" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Retrived the last modified for all settings of the system. Must have admin access.
#
# HEAD /settings/organizations
export def "settings-organizations head" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/organizations" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "head"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full [200]
}

# Delete an organization (and the associated receivers and senders)
#
# DELETE /settings/organizations/{organizationName}
export def "settings-organizations delete" [
  organization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countyName: string, description: string, jurisdiction: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, stateCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_name | is-empty) { error make --unspanned { msg: "path parameter 'organizationName' must be non-empty" } }
  let full_url = (build-url $base ({organization_name: (encode-path-segment $organization_name)} | format pattern "/settings/organizations/{organization_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# A single organization settings
#
# GET /settings/organizations/{organizationName}
export def "settings-organizations get" [
  organization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countyName: string, description: string, jurisdiction: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, stateCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_name | is-empty) { error make --unspanned { msg: "path parameter 'organizationName' must be non-empty" } }
  let full_url = (build-url $base ({organization_name: (encode-path-segment $organization_name)} | format pattern "/settings/organizations/{organization_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Create or update the direct settings associated with an organization
#
# PUT /settings/organizations/{organizationName}
export def "settings-organizations update" [
  organization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --county-name: string # the county name (must match FIPS name) (e.g. Pima)
  description: string # the displayable description of the organization (e.g. Arizona PHD)
  jurisdiction: string@jurisdiction-completer
  --meta: record # The metadata associated with an setting
  name: string # the unique id for the organization (e.g. az-phd)
  --state-code: string # the two letter code for the organization (e.g. AZ)
]: any -> record<countyName: string, description: string, jurisdiction: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, stateCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_name | is-empty) { error make --unspanned { msg: "path parameter 'organizationName' must be non-empty" } }
  let full_url = (build-url $base ({organization_name: (encode-path-segment $organization_name)} | format pattern "/settings/organizations/{organization_name}") $auth.query)
  let req_body = {"countyName": $county_name, "description": $description, "jurisdiction": $jurisdiction, "meta": $meta, "name": $name, "stateCode": $state_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# A list of receivers and their current settings
#
# GET /settings/organizations/{organizationName}/receivers
export def "settings-organizations-receivers list" [
  organization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, jurisdictionalFilters: list<record>, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, timing: record<dailyAt: float, frequency: string>, topic: string, translations: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_name | is-empty) { error make --unspanned { msg: "path parameter 'organizationName' must be non-empty" } }
  let full_url = (build-url $base ({organization_name: (encode-path-segment $organization_name)} | format pattern "/settings/organizations/{organization_name}/receivers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Delete a receiver
#
# DELETE /settings/organizations/{organizationName}/receivers/{receiverName}
export def "settings-organizations-receivers delete" [
  organization_name: string
  receiver_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, jurisdictionalFilters: table<doesNotMatch: bool, matchFields: string, matchValues: list>, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, timing: record<dailyAt: float, frequency: string>, topic: string, translations: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_name | is-empty) { error make --unspanned { msg: "path parameter 'organizationName' must be non-empty" } }
  if ($receiver_name | is-empty) { error make --unspanned { msg: "path parameter 'receiverName' must be non-empty" } }
  let full_url = (build-url $base ({organization_name: (encode-path-segment $organization_name), receiver_name: (encode-path-segment $receiver_name)} | format pattern "/settings/organizations/{organization_name}/receivers/{receiver_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# The settings of a single of receiver
#
# GET /settings/organizations/{organizationName}/receivers/{receiverName}
export def "settings-organizations-receivers get" [
  organization_name: string
  receiver_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, jurisdictionalFilters: table<doesNotMatch: bool, matchFields: string, matchValues: list>, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, timing: record<dailyAt: float, frequency: string>, topic: string, translations: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_name | is-empty) { error make --unspanned { msg: "path parameter 'organizationName' must be non-empty" } }
  if ($receiver_name | is-empty) { error make --unspanned { msg: "path parameter 'receiverName' must be non-empty" } }
  let full_url = (build-url $base ({organization_name: (encode-path-segment $organization_name), receiver_name: (encode-path-segment $receiver_name)} | format pattern "/settings/organizations/{organization_name}/receivers/{receiver_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Update a single reciever
#
# PUT /settings/organizations/{organizationName}/receivers/{receiverName}
# --jurisdictionalFilters item shape: {doesNotMatch?: bool, matchFields?: "FACILITY_OR_PATIENT_ADDRESS"|"FACILITY_ADDRESS"|"FACILITY_NAME"|"ABNORMAL_VALUE", matchValues?: list<string>}
# --timing shape: {dailyAt?: float, frequency: "REAL_TIME"|"HOURLY"|"DAILY"}
export def "settings-organizations-receivers update" [
  organization_name: string
  receiver_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Display ready description of the receiver (e.g. Arizona PHD ELR feed)
  --jurisdictional-filters: list # What items to include in the report. — item shape: {doesNotMatch?: bool, matchFields?: "FACILITY_OR_PATIENT_ADDRESS"|"FACILITY_ADDRESS"|"FACILITY_NAME"|"ABNORMAL_VALUE", matchValues?: list<string>}
  --meta: record # The metadata associated with an setting
  name: string # The unique name for the receiver. Should include the organization name as a prefix. (e.g. az-phd.elr)
  timing: record # When the report is sent if not immediately — shape: {dailyAt?: float, frequency: "REAL_TIME"|"HOURLY"|"DAILY"}
  topic: string # The topic of for this receiver. Must match the supported topics. (e.g. covid-19)
  --translations: list # How the report is translated from the sender. A report can be sent in multiple ways.
]: any -> record<description: string, jurisdictionalFilters: table<doesNotMatch: bool, matchFields: string, matchValues: list>, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, timing: record<dailyAt: float, frequency: string>, topic: string, translations: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_name | is-empty) { error make --unspanned { msg: "path parameter 'organizationName' must be non-empty" } }
  if ($receiver_name | is-empty) { error make --unspanned { msg: "path parameter 'receiverName' must be non-empty" } }
  let full_url = (build-url $base ({organization_name: (encode-path-segment $organization_name), receiver_name: (encode-path-segment $receiver_name)} | format pattern "/settings/organizations/{organization_name}/receivers/{receiver_name}") $auth.query)
  let req_body = {"description": $description, "jurisdictionalFilters": $jurisdictional_filters, "meta": $meta, "name": $name, "timing": $timing, "topic": $topic, "translations": $translations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# A list of senders
#
# GET /settings/organizations/{organizationName}/senders
export def "settings-organizations-senders list" [
  organization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, format: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, schema: string, topic: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_name | is-empty) { error make --unspanned { msg: "path parameter 'organizationName' must be non-empty" } }
  let full_url = (build-url $base ({organization_name: (encode-path-segment $organization_name)} | format pattern "/settings/organizations/{organization_name}/senders") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Delete a sender
#
# DELETE /settings/organizations/{organizationName}/senders/{senderName}
export def "settings-organizations-senders delete" [
  organization_name: string
  sender_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, format: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, schema: string, topic: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_name | is-empty) { error make --unspanned { msg: "path parameter 'organizationName' must be non-empty" } }
  if ($sender_name | is-empty) { error make --unspanned { msg: "path parameter 'senderName' must be non-empty" } }
  let full_url = (build-url $base ({organization_name: (encode-path-segment $organization_name), sender_name: (encode-path-segment $sender_name)} | format pattern "/settings/organizations/{organization_name}/senders/{sender_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# The settings of a single of sender
#
# GET /settings/organizations/{organizationName}/senders/{senderName}
export def "settings-organizations-senders get" [
  organization_name: string
  sender_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, format: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, schema: string, topic: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_name | is-empty) { error make --unspanned { msg: "path parameter 'organizationName' must be non-empty" } }
  if ($sender_name | is-empty) { error make --unspanned { msg: "path parameter 'senderName' must be non-empty" } }
  let full_url = (build-url $base ({organization_name: (encode-path-segment $organization_name), sender_name: (encode-path-segment $sender_name)} | format pattern "/settings/organizations/{organization_name}/senders/{sender_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Update a single sender
#
# PUT /settings/organizations/{organizationName}/senders/{senderName}
export def "settings-organizations-senders update" [
  organization_name: string
  sender_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Display ready description of the sender
  format: string@format-completer # the payload format
  --meta: record # The metadata associated with an setting
  name: string # Unique name for the senders, includes the orgninzation name (e.g. simple_report.default)
  schema: string # the schema name for this sender (e.g. az-phd-covid-19)
  topic: string # Topic of for this sender. Must match the supported topics. (e.g. covid-19)
]: any -> table<description: string, format: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, schema: string, topic: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_name | is-empty) { error make --unspanned { msg: "path parameter 'organizationName' must be non-empty" } }
  if ($sender_name | is-empty) { error make --unspanned { msg: "path parameter 'senderName' must be non-empty" } }
  let full_url = (build-url $base ({organization_name: (encode-path-segment $organization_name), sender_name: (encode-path-segment $sender_name)} | format pattern "/settings/organizations/{organization_name}/senders/{sender_name}") $auth.query)
  let req_body = {"description": $description, "format": $format, "meta": $meta, "name": $name, "schema": $schema, "topic": $topic} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}
