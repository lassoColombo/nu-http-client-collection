# Auto-generated client for Business Registries v0.0.6
# Source: https://api.apis.guru/v2/specs/ato.gov.au/0.0.6/openapi.json
# Auth: --token flag or $env.BUSINESS_REGISTRIES_TOKEN

const BASE_URL = "http://localhost//api.abr.ato.gov.au"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o BUSINESS_REGISTRIES_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["http://localhost//api.abr.ato.gov.au" "http://localhost//api.sandbox.abr.ato.gov.au"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def gender-completer [] { ["Female" "Male" "Not Applicable" "Not Known"] }
def lifecycle-state-completer [] { ["Approved" "Expired" "Issued" "Pending Approval" "Suspended"] }
def electronic-address-type-completer [] { ["Email" "Fax" "Landline" "Mobile" "Website"] }
def license-type-completer [] { ["Australian Financial Services License" "License 2B"] }
def party-role-type-completer [] { ["Director" "Employee" "Member" "Partner" "Trustee"] }
def related-party-role-type-completer [] { ["Association" "Company" "Employer" "Organisation" "Partnership" "Trust"] }
def relationship-type-completer [] { ["Directorship" "Employment" "Membership" "Partnership" "Trusteeship"] }
def legal-entity-type-completer [] { ["Company" "Joint Venture" "Partnership" "Trust"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "business-names get" } } | get name | first)
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

# Retrieve a list of business names
#
# GET /business-names
export def "business-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business-names" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of address types
#
# GET /classifications/address-types
export def "classifications-address-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/address-types" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of business name lifecycle states
#
# GET /classifications/business-name-lifecycle-states
export def "classifications-business-name-lifecycle-states get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/business-name-lifecycle-states" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of electronic address types
#
# GET /classifications/electronic-address-types
export def "classifications-electronic-address-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/electronic-address-types" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of genders
#
# GET /classifications/genders
export def "classifications-genders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<gender: string, id: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/genders" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of legal entity types
#
# GET /classifications/legal-entity-types
export def "classifications-legal-entity-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/legal-entity-types" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of license lifecycle states
#
# GET /classifications/license-lifecycle-states
export def "classifications-license-lifecycle-states get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/license-lifecycle-states" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of license types
#
# GET /classifications/license-types
export def "classifications-license-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/license-types" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of name directions
#
# GET /classifications/name-directions
export def "classifications-name-directions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/name-directions" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of name prefixes
#
# GET /classifications/name-prefixes
export def "classifications-name-prefixes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/name-prefixes" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of name types
#
# GET /classifications/name-types
export def "classifications-name-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/name-types" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of registered identifier types
#
# GET /classifications/registered-identifier-types
export def "classifications-registered-identifier-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/registered-identifier-types" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of roles
#
# GET /classifications/roles
export def "classifications-roles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<id: record, reciprocalRole: string, reciprocalRoleDescription: string, relationship: string, role: string, roleDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/roles" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of individuals
#
# GET /individuals
export def "individuals list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-of-birth: string # The individual's date of birth, for example, `1979-01-13` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format).
  --place-of-birth: string # The individual's place of birth, for example, `Tamworth`.
  --api-key: string # The API key.
]: nothing -> table<addresses: list<record>, dateOfBirth: string, electronicAddresses: list<record>, fromDate: string, gender: string, id: record, names: list<record>, placeOfBirth: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateOfBirth" $date_of_birth "scalar") (serialize-qp "placeOfBirth" $place_of_birth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/individuals" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"dateOfBirth": $date_of_birth, "placeOfBirth": $place_of_birth} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an individual
#
# POST /individuals
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"|"Principal Place of Residence"}
# --electronicAddresses item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
# --names item shape: {direction?: "left-to-right"|"right-to-left", familyName?: string, formalSalutation?: string, givenName?: string, informalSalutation?: string, middleName?: string, namePrefix?: "Mr"|"Ms", nameSuffix?: string, nameType?: "Alias"|"Principal Name"}
export def "individuals create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"|"Principal Place of Residence"}
  date_of_birth: string # The individual's date of birth, for example, `1979-01-13` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1979-01-13)
  --electronic-addresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  --gender: string@gender-completer # The individual's gender. (default: Male)
  --names: list # item shape: {direction?: "left-to-right"|"right-to-left", familyName?: string, formalSalutation?: string, givenName?: string, informalSalutation?: string, middleName?: string, namePrefix?: "Mr"|"Ms", nameSuffix?: string, nameType?: "Alias"|"Principal Name"}
  place_of_birth: string # The individual's place of birth, for example, `Tamworth`. (e.g. Tamworth)
]: any -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: record, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: record, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/individuals" $auth.query)
  let req_body = {"addresses": $addresses, "dateOfBirth": $date_of_birth, "electronicAddresses": $electronic_addresses, "gender": $gender, "names": $names, "placeOfBirth": $place_of_birth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an individual
#
# DELETE /individuals/{partyId}
export def "individuals delete" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve an individual
#
# GET /individuals/{partyId}
export def "individuals get" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: record, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: record, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update an individual
#
# PUT /individuals/{partyId}
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"|"Principal Place of Residence"}
# --electronicAddresses item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
# --names item shape: {direction?: "left-to-right"|"right-to-left", familyName?: string, formalSalutation?: string, givenName?: string, informalSalutation?: string, middleName?: string, namePrefix?: "Mr"|"Ms", nameSuffix?: string, nameType?: "Alias"|"Principal Name"}
export def "individuals update" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"|"Principal Place of Residence"}
  date_of_birth: string # The individual's date of birth, for example, `1979-01-13` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1979-01-13)
  --electronic-addresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  --gender: string@gender-completer # The individual's gender. (default: Male)
  --names: list # item shape: {direction?: "left-to-right"|"right-to-left", familyName?: string, formalSalutation?: string, givenName?: string, informalSalutation?: string, middleName?: string, namePrefix?: "Mr"|"Ms", nameSuffix?: string, nameType?: "Alias"|"Principal Name"}
  place_of_birth: string # The individual's place of birth, for example, `Tamworth`. (e.g. Tamworth)
]: any -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: record, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: record, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}") $auth.query)
  let req_body = {"addresses": $addresses, "dateOfBirth": $date_of_birth, "electronicAddresses": $electronic_addresses, "gender": $gender, "names": $names, "placeOfBirth": $place_of_birth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of addresses
#
# GET /individuals/{partyId}/addresses
export def "individuals-addresses list" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}/addresses") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create an address
#
# POST /individuals/{partyId}/addresses
export def "individuals-addresses create" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postal-code: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}/addresses") $auth.query)
  let req_body = {"city": $city, "country": $country, "line1": $line1, "line2": $line2, "line3": $line3, "name": $name, "postalCode": $postal_code, "suburb": $suburb} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an address
#
# DELETE /individuals/{partyId}/addresses/{addressId}
export def "individuals-addresses delete" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/individuals/{party_id}/addresses/{address_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve an address
#
# GET /individuals/{partyId}/addresses/{addressId}
export def "individuals-addresses get" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/individuals/{party_id}/addresses/{address_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update an address
#
# PUT /individuals/{partyId}/addresses/{addressId}
export def "individuals-addresses update" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postal-code: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/individuals/{party_id}/addresses/{address_id}") $auth.query)
  let req_body = {"city": $city, "country": $country, "line1": $line1, "line2": $line2, "line3": $line3, "name": $name, "postalCode": $postal_code, "suburb": $suburb} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of business names
#
# GET /individuals/{partyId}/business-names
export def "individuals-business-names list" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}/business-names") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create a business name
#
# POST /individuals/{partyId}/business-names
export def "individuals-business-names create" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}/business-names") $auth.query)
  let req_body = {"lifecycleState": $lifecycle_state, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a business name
#
# DELETE /individuals/{partyId}/business-names/{productId}
export def "individuals-business-names delete" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/individuals/{party_id}/business-names/{product_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a business name
#
# GET /individuals/{partyId}/business-names/{productId}
export def "individuals-business-names get" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/individuals/{party_id}/business-names/{product_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a business name
#
# PUT /individuals/{partyId}/business-names/{productId}
export def "individuals-business-names update" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/individuals/{party_id}/business-names/{product_id}") $auth.query)
  let req_body = {"lifecycleState": $lifecycle_state, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of electronic addresses
#
# GET /individuals/{partyId}/electronic-addresses
export def "individuals-electronic-addresses list" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}/electronic-addresses") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create an electronic address
#
# POST /individuals/{partyId}/electronic-addresses
export def "individuals-electronic-addresses create" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --area-code: string # The area code, for example, "02". (e.g. 02)
  --country-prefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronic-address-type: string@electronic-address-type-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}/electronic-addresses") $auth.query)
  let req_body = {"areaCode": $area_code, "countryPrefix": $country_prefix, "electronicAddressType": $electronic_address_type, "email": $email, "extension": $extension, "number": $number, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an electronic address
#
# DELETE /individuals/{partyId}/electronic-addresses/{addressId}
export def "individuals-electronic-addresses delete" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/individuals/{party_id}/electronic-addresses/{address_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve an electronic address
#
# GET /individuals/{partyId}/electronic-addresses/{addressId}
export def "individuals-electronic-addresses get" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/individuals/{party_id}/electronic-addresses/{address_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update an electronic address
#
# PUT /individuals/{partyId}/electronic-addresses/{addressId}
export def "individuals-electronic-addresses update" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --area-code: string # The area code, for example, "02". (e.g. 02)
  --country-prefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronic-address-type: string@electronic-address-type-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/individuals/{party_id}/electronic-addresses/{address_id}") $auth.query)
  let req_body = {"areaCode": $area_code, "countryPrefix": $country_prefix, "electronicAddressType": $electronic_address_type, "email": $email, "extension": $extension, "number": $number, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of licenses
#
# GET /individuals/{partyId}/licenses
export def "individuals-licenses list" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}/licenses") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create a license
#
# POST /individuals/{partyId}/licenses
export def "individuals-licenses create" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --license-type: string@license-type-completer # The license type. (default: Australian Financial Services License)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}/licenses") $auth.query)
  let req_body = {"licenseType": $license_type, "lifecycleState": $lifecycle_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a license
#
# DELETE /individuals/{partyId}/licenses/{productId}
export def "individuals-licenses delete" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/individuals/{party_id}/licenses/{product_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a license
#
# GET /individuals/{partyId}/licenses/{productId}
export def "individuals-licenses get" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/individuals/{party_id}/licenses/{product_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a license
#
# PUT /individuals/{partyId}/licenses/{productId}
export def "individuals-licenses update" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --license-type: string@license-type-completer # The license type. (default: Australian Financial Services License)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/individuals/{party_id}/licenses/{product_id}") $auth.query)
  let req_body = {"licenseType": $license_type, "lifecycleState": $lifecycle_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of roles
#
# GET /individuals/{partyId}/roles
export def "individuals-roles list" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}/roles") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create a role
#
# POST /individuals/{partyId}/roles
export def "individuals-roles create" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --party-role-type: string@party-role-type-completer # The party's role type. (default: Employee)
  related_party_id: any # The related party's unique identifier.
  --related-party-role-type: string@related-party-role-type-completer # The related party's role type. (default: Employer)
  relationship_type: string@relationship-type-completer # The relationship type. (default: Employment)
]: any -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/individuals/{party_id}/roles") $auth.query)
  let req_body = {"partyRoleType": $party_role_type, "relatedPartyId": $related_party_id, "relatedPartyRoleType": $related_party_role_type, "relationshipType": $relationship_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a role
#
# DELETE /individuals/{partyId}/roles/{roleId}
export def "individuals-roles delete" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), role_id: (encode-path-segment $role_id)} | format pattern "/individuals/{party_id}/roles/{role_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a role
#
# GET /individuals/{partyId}/roles/{roleId}
export def "individuals-roles get" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), role_id: (encode-path-segment $role_id)} | format pattern "/individuals/{party_id}/roles/{role_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a role
#
# PUT /individuals/{partyId}/roles/{roleId}
export def "individuals-roles update" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --party-role-type: string@party-role-type-completer # The party's role type. (default: Employee)
  related_party_id: any # The related party's unique identifier.
  --related-party-role-type: string@related-party-role-type-completer # The related party's role type. (default: Employer)
  relationship_type: string@relationship-type-completer # The relationship type. (default: Employment)
]: any -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), role_id: (encode-path-segment $role_id)} | format pattern "/individuals/{party_id}/roles/{role_id}") $auth.query)
  let req_body = {"partyRoleType": $party_role_type, "relatedPartyId": $related_party_id, "relatedPartyRoleType": $related_party_role_type, "relationshipType": $relationship_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of licenses
#
# GET /licenses
export def "licenses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licenses" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of organisations
#
# GET /organisations
export def "organisations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --registered-identifier: string # The registered identifier, for example, `ACN` or `ABN`.
  --identifier: string # The identifier, for example, `123456789`.
  --api-key: string # The API key.
]: nothing -> table<addresses: list<record>, electronicAddresses: list<record>, establishmentDate: string, fromDate: string, id: record, legalEntityType: string, names: list<record>, registeredIdentifiers: list<record>, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "registeredIdentifier" $registered_identifier "scalar") (serialize-qp "identifier" $identifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organisations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"registeredIdentifier": $registered_identifier, "identifier": $identifier} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an organisation
#
# POST /organisations
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"}
# --electronicAddresses item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
# --names item shape: {name?: string}
# --registeredIdentifiers item shape: {identifier?: string, identifierType?: "ACN"|"ABN"}
export def "organisations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"}
  --electronic-addresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  establishment_date: string # The organisation's establishment date, for example, `1928-03-03` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1928-03-03)
  legal_entity_type: string@legal-entity-type-completer # The organisation's legal entity type. (default: Company)
  --names: list # item shape: {name?: string}
  --registered-identifiers: list # item shape: {identifier?: string, identifierType?: "ACN"|"ABN"}
]: any -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: record, legalEntityType: string, names: table<fromDate: string, id: record, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: record, identifier: string, identifierType: string, toDate: string>, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations" $auth.query)
  let req_body = {"addresses": $addresses, "electronicAddresses": $electronic_addresses, "establishmentDate": $establishment_date, "legalEntityType": $legal_entity_type, "names": $names, "registeredIdentifiers": $registered_identifiers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an organisation
#
# DELETE /organisations/{partyId}
export def "organisations delete" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve an organisation
#
# GET /organisations/{partyId}
export def "organisations get" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: record, legalEntityType: string, names: table<fromDate: string, id: record, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: record, identifier: string, identifierType: string, toDate: string>, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update an organisation
#
# PUT /organisations/{partyId}
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"}
# --electronicAddresses item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
# --names item shape: {name?: string}
# --registeredIdentifiers item shape: {identifier?: string, identifierType?: "ACN"|"ABN"}
export def "organisations update" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"}
  --electronic-addresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  establishment_date: string # The organisation's establishment date, for example, `1928-03-03` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1928-03-03)
  legal_entity_type: string@legal-entity-type-completer # The organisation's legal entity type. (default: Company)
  --names: list # item shape: {name?: string}
  --registered-identifiers: list # item shape: {identifier?: string, identifierType?: "ACN"|"ABN"}
]: any -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: record, legalEntityType: string, names: table<fromDate: string, id: record, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: record, identifier: string, identifierType: string, toDate: string>, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}") $auth.query)
  let req_body = {"addresses": $addresses, "electronicAddresses": $electronic_addresses, "establishmentDate": $establishment_date, "legalEntityType": $legal_entity_type, "names": $names, "registeredIdentifiers": $registered_identifiers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of addresses
#
# GET /organisations/{partyId}/addresses
export def "organisations-addresses list" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}/addresses") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create an address
#
# POST /organisations/{partyId}/addresses
export def "organisations-addresses create" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postal-code: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}/addresses") $auth.query)
  let req_body = {"city": $city, "country": $country, "line1": $line1, "line2": $line2, "line3": $line3, "name": $name, "postalCode": $postal_code, "suburb": $suburb} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an address
#
# DELETE /organisations/{partyId}/addresses/{addressId}
export def "organisations-addresses delete" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/organisations/{party_id}/addresses/{address_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve an address
#
# GET /organisations/{partyId}/addresses/{addressId}
export def "organisations-addresses get" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/organisations/{party_id}/addresses/{address_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update an address
#
# PUT /organisations/{partyId}/addresses/{addressId}
export def "organisations-addresses update" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postal-code: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/organisations/{party_id}/addresses/{address_id}") $auth.query)
  let req_body = {"city": $city, "country": $country, "line1": $line1, "line2": $line2, "line3": $line3, "name": $name, "postalCode": $postal_code, "suburb": $suburb} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of business names
#
# GET /organisations/{partyId}/business-names
export def "organisations-business-names list" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}/business-names") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create a business name
#
# POST /organisations/{partyId}/business-names
export def "organisations-business-names create" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}/business-names") $auth.query)
  let req_body = {"lifecycleState": $lifecycle_state, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a business name
#
# DELETE /organisations/{partyId}/business-names/{productId}
export def "organisations-business-names delete" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/organisations/{party_id}/business-names/{product_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a business name
#
# GET /organisations/{partyId}/business-names/{productId}
export def "organisations-business-names get" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/organisations/{party_id}/business-names/{product_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a business name
#
# PUT /organisations/{partyId}/business-names/{productId}
export def "organisations-business-names update" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/organisations/{party_id}/business-names/{product_id}") $auth.query)
  let req_body = {"lifecycleState": $lifecycle_state, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of electronic addresses
#
# GET /organisations/{partyId}/electronic-addresses
export def "organisations-electronic-addresses list" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}/electronic-addresses") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create an electronic address
#
# POST /organisations/{partyId}/electronic-addresses
export def "organisations-electronic-addresses create" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --area-code: string # The area code, for example, "02". (e.g. 02)
  --country-prefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronic-address-type: string@electronic-address-type-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}/electronic-addresses") $auth.query)
  let req_body = {"areaCode": $area_code, "countryPrefix": $country_prefix, "electronicAddressType": $electronic_address_type, "email": $email, "extension": $extension, "number": $number, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an electronic address
#
# DELETE /organisations/{partyId}/electronic-addresses/{addressId}
export def "organisations-electronic-addresses delete" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/organisations/{party_id}/electronic-addresses/{address_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve an electronic address
#
# GET /organisations/{partyId}/electronic-addresses/{addressId}
export def "organisations-electronic-addresses get" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/organisations/{party_id}/electronic-addresses/{address_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update an electronic address
#
# PUT /organisations/{partyId}/electronic-addresses/{addressId}
export def "organisations-electronic-addresses update" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --area-code: string # The area code, for example, "02". (e.g. 02)
  --country-prefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronic-address-type: string@electronic-address-type-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($address_id | is-empty) { error make --unspanned { msg: "path parameter 'addressId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), address_id: (encode-path-segment $address_id)} | format pattern "/organisations/{party_id}/electronic-addresses/{address_id}") $auth.query)
  let req_body = {"areaCode": $area_code, "countryPrefix": $country_prefix, "electronicAddressType": $electronic_address_type, "email": $email, "extension": $extension, "number": $number, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of licenses
#
# GET /organisations/{partyId}/licenses
export def "organisations-licenses list" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}/licenses") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create a license
#
# POST /organisations/{partyId}/licenses
export def "organisations-licenses create" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --license-type: string@license-type-completer # The license type. (default: Australian Financial Services License)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}/licenses") $auth.query)
  let req_body = {"licenseType": $license_type, "lifecycleState": $lifecycle_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a license
#
# DELETE /organisations/{partyId}/licenses/{productId}
export def "organisations-licenses delete" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/organisations/{party_id}/licenses/{product_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a license
#
# GET /organisations/{partyId}/licenses/{productId}
export def "organisations-licenses get" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/organisations/{party_id}/licenses/{product_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a license
#
# PUT /organisations/{partyId}/licenses/{productId}
export def "organisations-licenses update" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --license-type: string@license-type-completer # The license type. (default: Australian Financial Services License)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), product_id: (encode-path-segment $product_id)} | format pattern "/organisations/{party_id}/licenses/{product_id}") $auth.query)
  let req_body = {"licenseType": $license_type, "lifecycleState": $lifecycle_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of roles
#
# GET /organisations/{partyId}/roles
export def "organisations-roles list" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> table<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}/roles") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create a role
#
# POST /organisations/{partyId}/roles
export def "organisations-roles create" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --party-role-type: string@party-role-type-completer # The party's role type. (default: Employee)
  related_party_id: any # The related party's unique identifier.
  --related-party-role-type: string@related-party-role-type-completer # The related party's role type. (default: Employer)
  relationship_type: string@relationship-type-completer # The relationship type. (default: Employment)
]: any -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/organisations/{party_id}/roles") $auth.query)
  let req_body = {"partyRoleType": $party_role_type, "relatedPartyId": $related_party_id, "relatedPartyRoleType": $related_party_role_type, "relationshipType": $relationship_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a role
#
# DELETE /organisations/{partyId}/roles/{roleId}
export def "organisations-roles delete" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), role_id: (encode-path-segment $role_id)} | format pattern "/organisations/{party_id}/roles/{role_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a role
#
# GET /organisations/{partyId}/roles/{roleId}
export def "organisations-roles get" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
]: nothing -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), role_id: (encode-path-segment $role_id)} | format pattern "/organisations/{party_id}/roles/{role_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a role
#
# PUT /organisations/{partyId}/roles/{roleId}
export def "organisations-roles update" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key.
  --party-role-type: string@party-role-type-completer # The party's role type. (default: Employee)
  related_party_id: any # The related party's unique identifier.
  --related-party-role-type: string@related-party-role-type-completer # The related party's role type. (default: Employer)
  relationship_type: string@relationship-type-completer # The relationship type. (default: Employment)
]: any -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id), role_id: (encode-path-segment $role_id)} | format pattern "/organisations/{party_id}/roles/{role_id}") $auth.query)
  let req_body = {"partyRoleType": $party_role_type, "relatedPartyId": $related_party_id, "relatedPartyRoleType": $related_party_role_type, "relationshipType": $relationship_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}
