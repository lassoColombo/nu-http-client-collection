# Auto-generated client for Learnifier v1.1.0
# Source: https://api.apis.guru/v2/specs/learnifier.com/1.1.0/swagger.json
# Auth: --token flag or $env.LEARNIFIER_TOKEN

const BASE_URL = "http://learnifier.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o LEARNIFIER_TOKEN | default "" }
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

def base-url-completer [] { ["http://learnifier.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["ACTIVATED" "DISABLED" "NEW"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "coursedesigns get" } } | get name | first)
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

# Lists all global course design templates
#
# GET /coursedesigns
export def "coursedesigns get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created: string, createdBy: string, description: string, enabled: bool, locale: string, locked: string, lockedBy: string, lockedDesign: bool, name: string, softid: string, sticky: bool, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/coursedesigns" $auth.query)
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

# Get Organization Unit with External Id
#
# GET /extorgunit
export def "extorgunit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extid: string # The external id of the organization unit (format: extid)
]: nothing -> record<externalId: string, id: int, name: string, parentId: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extid" $extid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extorgunit" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"extid": $extid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a participation by external id
#
# GET /extparticipation
export def "extparticipation get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extid: string # The external id of the participation (format: extid)
]: nothing -> record<accessLink: string, activated: bool, activitiesCompleted: float, activitiesTotal: float, errorMessage: string, expiration: string, externalId: string, firstAccess: string, firstActivation: string, firstMail: string, id: int, inError: bool, lastAccess: string, lastActivation: string, lastMail: string, projectId: int, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extid" $extid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extparticipation" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"extid": $extid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets Organization Unit by external id
#
# GET /extproject
export def "extproject get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extid: string # The external id of the organization unit (format: extid)
]: nothing -> record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extid" $extid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extproject" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"extid": $extid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a user by external id
#
# GET /extuser
export def "extuser get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extid: string # The external id of the user (format: extid)
]: nothing -> record<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extid" $extid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extuser" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"extid": $extid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Global User Groups.
#
# GET /globalusergroups
export def "globalusergroups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created: string, createdBy: string, id: int, name: string, parent: int, softiId: string, updated: string, updatedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/globalusergroups" $auth.query)
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

# List of all users in group.
#
# GET /globalusergroups/{groupid}/members
export def "globalusergroups-members get" [
  groupid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($groupid | is-empty) { error make --unspanned { msg: "path parameter 'groupid' must be non-empty" } }
  let full_url = (build-url $base ({groupid: (encode-path-segment $groupid)} | format pattern "/globalusergroups/{groupid}/members") $auth.query)
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

# Organization Units
#
# GET /orgunits
export def "orgunits list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<orgUnits: table<externalId: string, id: int, name: string, parentId: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orgunits" $auth.query)
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

# Adds an Organization Unit
#
# POST /orgunits
export def "orgunits create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --caller: string # The id of the user that initiated this operation (format: uuid, e.g. 81590981-1e05-4fd5-aa15-15bc4b06cf7f)
  --client-number: string # A client number. Sometimes used when communicating with external system. Must be unique if specified. (e.g. X-1234)
  --country: string # The country code that best matches the organization unit. If unspecified the platform default will be set. (format: locale, e.g. se)
  display_name: string # The name shown for the organization unit (e.g. Sample Corp)
  --external-id: string # The external id (foreign key). Must not exceed 255 characters.
  --parent: float # A Organization Unit id of the parent Organization Unit (optional). (format: id64, e.g. 1234)
]: any -> record<ouId: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orgunits" $auth.query)
  let req_body = {"caller": $caller, "clientNumber": $client_number, "country": $country, "displayName": $display_name, "externalId": $external_id, "parent": $parent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get Organization Unit
#
# GET /orgunits/{orgid}
export def "orgunits get" [
  orgid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<externalId: string, id: int, name: string, parentId: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid)} | format pattern "/orgunits/{orgid}") $auth.query)
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

# Updates an Organization Unit
#
# PATCH /orgunits/{orgid}
export def "orgunits update" [
  orgid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --caller: string # The id of the user that initiated this operation (format: uuid, e.g. 81590981-1e05-4fd5-aa15-15bc4b06cf7f)
  --client-number: string # A client number. Sometimes used when communicating with external system. Must be unique if specified. (e.g. X-1234)
  --country: string # The country code that best matches the organization unit. If unspecified the platform default will be set. (format: locale, e.g. se)
  --display-name: string # The name shown for the organization unit (e.g. Sample Corp)
  --external-id: string # The external id (foreign key). Must not exceed 255 characters.
  --parent: float # A Organization Unit id of the parent Organization Unit (optional). (format: id64, e.g. 1234)
]: any -> record<code: int, field: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid)} | format pattern "/orgunits/{orgid}") $auth.query)
  let req_body = {"caller": $caller, "clientNumber": $client_number, "country": $country, "displayName": $display_name, "externalId": $external_id, "parent": $parent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Organization Unit Projects
#
# GET /orgunits/{orgid}/projects
export def "orgunits-projects list" [
  orgid: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid)} | format pattern "/orgunits/{orgid}/projects") $auth.query)
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

# Create project
#
# POST /orgunits/{orgid}/projects
export def "orgunits-projects create" [
  orgid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # The country code. Default value will be used if not specified (format: countrycode, e.g. SE)
  --created-by: string # The id of the user that created the project. If the creator is not known this value can be *null* or not specified (format: uuid, e.g. 8c102c8e-fabd-4c8a-b245-4d2d2f77fc4b)
  design_id: int # The id of the design this project should be based on (format: int64)
  --locale: string # The primary locale for this project. Default value will be used if not specified (format: locale, e.g. en-US)
  name: string # The internal name of the project
  --note: string # The internal note field
  --timezone: string # The main timezone for the project. Do not specify for default timezone (format: timezone, e.g. Europe/Stockholm)
  --user-description: string # The description presented to participants. Do not specify for default value from design
  --user-title: string # The title presented to participants. Do not specify for default value from design
]: any -> record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid)} | format pattern "/orgunits/{orgid}/projects") $auth.query)
  let req_body = {"country": $country, "createdBy": $created_by, "designId": $design_id, "locale": $locale, "name": $name, "note": $note, "timezone": $timezone, "userDescription": $user_description, "userTitle": $user_title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Deletes the project
#
# DELETE /orgunits/{orgid}/projects/{projectid}
export def "orgunits-projects delete" [
  orgid: int
  projectid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, field: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($projectid | is-empty) { error make --unspanned { msg: "path parameter 'projectid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), projectid: (encode-path-segment $projectid)} | format pattern "/orgunits/{orgid}/projects/{projectid}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Project information
#
# GET /orgunits/{orgid}/projects/{projectid}
export def "orgunits-projects get" [
  orgid: int
  projectid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($projectid | is-empty) { error make --unspanned { msg: "path parameter 'projectid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), projectid: (encode-path-segment $projectid)} | format pattern "/orgunits/{orgid}/projects/{projectid}") $auth.query)
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

# Update project information
#
# PATCH /orgunits/{orgid}/projects/{projectid}
export def "orgunits-projects update" [
  orgid: int
  projectid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # The country code (format: countrycode, e.g. SE)
  --locale: string # The primary locale for this project (format: locale, e.g. en-US)
  --name: string # The internal name of the project
  --note: string # The internal note field
  --status: string@status-completer # Project status. Can be either ACTIVATED, NEW or DISABLED (e.g. ACTIVATED)
  --timezone: string # The main timezone for the project (format: timezone, e.g. Europe/Stockholm)
  --user-description: string # The description presented to participants. This value can be *null*.
  --user-title: string # The title presented to participants
]: any -> record<adminUrl: string, country: string, created: string, createdBy: string, designId: int, externalId: string, id: int, locale: string, name: string, note: string, orgId: int, status: string, timezone: string, userDescription: string, userTitle: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($projectid | is-empty) { error make --unspanned { msg: "path parameter 'projectid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), projectid: (encode-path-segment $projectid)} | format pattern "/orgunits/{orgid}/projects/{projectid}") $auth.query)
  let req_body = {"country": $country, "locale": $locale, "name": $name, "note": $note, "status": $status, "timezone": $timezone, "userDescription": $user_description, "userTitle": $user_title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Project participants
#
# GET /orgunits/{orgid}/projects/{projectid}/participants
export def "orgunits-projects-participants get" [
  orgid: int
  projectid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<accessLink: string, activated: bool, activitiesCompleted: float, activitiesTotal: float, errorMessage: string, expiration: string, externalId: string, firstAccess: string, firstActivation: string, firstMail: string, id: int, inError: bool, lastAccess: string, lastActivation: string, lastMail: string, projectId: int, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($projectid | is-empty) { error make --unspanned { msg: "path parameter 'projectid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), projectid: (encode-path-segment $projectid)} | format pattern "/orgunits/{orgid}/projects/{projectid}/participants") $auth.query)
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

# Add participant
#
# POST /orgunits/{orgid}/projects/{projectid}/participants
export def "orgunits-projects-participants create" [
  orgid: int
  projectid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the user. If no user exists with the specified email a user will be created with default values and the specified email. (format: email, e.g. user@example.com)
  --extid: string # An optional external id for the participation
  --userid: string # format: uuid, e.g. 81590981-1e05-4fd5-aa15-15bc4b06cf7f
]: any -> record<code: int, field: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($projectid | is-empty) { error make --unspanned { msg: "path parameter 'projectid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), projectid: (encode-path-segment $projectid)} | format pattern "/orgunits/{orgid}/projects/{projectid}/participants") $auth.query)
  let req_body = {"email": $email, "extid": $extid, "userid": $userid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Deletes a participant
#
# DELETE /orgunits/{orgid}/projects/{projectid}/participants/${participantId}
export def "orgunits-projects-participants-participant-id delete" [
  orgid: int
  projectid: int
  participant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, field: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($projectid | is-empty) { error make --unspanned { msg: "path parameter 'projectid' must be non-empty" } }
  if ($participant_id | is-empty) { error make --unspanned { msg: "path parameter 'participantId' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), projectid: (encode-path-segment $projectid), participant_id: (encode-path-segment $participant_id)} | format pattern "/orgunits/{orgid}/projects/{projectid}/participants/${participant_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Activate participant
#
# POST /orgunits/{orgid}/projects/{projectid}/participants/${participantId}/activate
export def "orgunits-projects-participants-participant-id-activate create" [
  orgid: int
  projectid: int
  participant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, field: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($projectid | is-empty) { error make --unspanned { msg: "path parameter 'projectid' must be non-empty" } }
  if ($participant_id | is-empty) { error make --unspanned { msg: "path parameter 'participantId' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), projectid: (encode-path-segment $projectid), participant_id: (encode-path-segment $participant_id)} | format pattern "/orgunits/{orgid}/projects/{projectid}/participants/${participant_id}/activate") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Participant login link
#
# POST /orgunits/{orgid}/projects/{projectid}/participants/${participantId}/loginlink
export def "orgunits-projects-participants-participant-id-loginlink create" [
  orgid: int
  projectid: int
  participant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<link: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($projectid | is-empty) { error make --unspanned { msg: "path parameter 'projectid' must be non-empty" } }
  if ($participant_id | is-empty) { error make --unspanned { msg: "path parameter 'participantId' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), projectid: (encode-path-segment $projectid), participant_id: (encode-path-segment $participant_id)} | format pattern "/orgunits/{orgid}/projects/{projectid}/participants/${participant_id}/loginlink") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Project team members
#
# GET /orgunits/{orgid}/projects/{projectid}/teammembers
export def "orgunits-projects-teammembers get" [
  orgid: int
  projectid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<roles: record<name: string, roleid: string>, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($projectid | is-empty) { error make --unspanned { msg: "path parameter 'projectid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), projectid: (encode-path-segment $projectid)} | format pattern "/orgunits/{orgid}/projects/{projectid}/teammembers") $auth.query)
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

# List User Groups.
#
# GET /orgunits/{orgid}/usergroups
export def "orgunits-usergroups list" [
  orgid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<children: list<any>, globalId: int, groupId: int, name: string, parent: int, userGroup: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid)} | format pattern "/orgunits/{orgid}/usergroups") $auth.query)
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

# Create a User Group.
#
# POST /orgunits/{orgid}/usergroups
export def "orgunits-usergroups create" [
  orgid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of group. (e.g. Foo)
  --parent: int # Optional ID of parent group. (format: int64, e.g. 1010)
]: any -> table<groupId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid)} | format pattern "/orgunits/{orgid}/usergroups") $auth.query)
  let req_body = {"name": $name, "parent": $parent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get user group
#
# GET /orgunits/{orgid}/usergroups/{groupid}
export def "orgunits-usergroups get" [
  orgid: int
  groupid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<children: list<any>, globalId: int, groupId: int, name: string, parent: int, userGroup: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($groupid | is-empty) { error make --unspanned { msg: "path parameter 'groupid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), groupid: (encode-path-segment $groupid)} | format pattern "/orgunits/{orgid}/usergroups/{groupid}") $auth.query)
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

# List of all users in group.
#
# GET /orgunits/{orgid}/usergroups/{groupid}/members
export def "orgunits-usergroups-members get" [
  orgid: int
  groupid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($groupid | is-empty) { error make --unspanned { msg: "path parameter 'groupid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), groupid: (encode-path-segment $groupid)} | format pattern "/orgunits/{orgid}/usergroups/{groupid}/members") $auth.query)
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

# Add user group member.
#
# POST /orgunits/{orgid}/usergroups/{groupid}/members
export def "orgunits-usergroups-members create" [
  orgid: int
  groupid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  uuid: string # UUID of user to add to this group. (format: uuid)
]: any -> record<uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($groupid | is-empty) { error make --unspanned { msg: "path parameter 'groupid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), groupid: (encode-path-segment $groupid)} | format pattern "/orgunits/{orgid}/usergroups/{groupid}/members") $auth.query)
  let req_body = {"uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Remove user group member.
#
# DELETE /orgunits/{orgid}/usergroups/{groupid}/members/{uuid}
export def "orgunits-usergroups-members delete" [
  orgid: int
  groupid: int
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, field: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($orgid | is-empty) { error make --unspanned { msg: "path parameter 'orgid' must be non-empty" } }
  if ($groupid | is-empty) { error make --unspanned { msg: "path parameter 'groupid' must be non-empty" } }
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let full_url = (build-url $base ({orgid: (encode-path-segment $orgid), groupid: (encode-path-segment $groupid), uuid: (encode-path-segment $uuid)} | format pattern "/orgunits/{orgid}/usergroups/{groupid}/members/{uuid}") $auth.query)
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

# Lists all users
#
# GET /users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of users to return (format: integer, default: 5000)
  --offset: int # The offset to start listing users from (format: integer, default: 0)
]: nothing -> table<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string, backOfficeRoles: list<record>, clientRoles: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a user
#
# POST /users
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The name shown when the user is listed (e.g. Jane Doe)
  --external-id: string # The external id (foreign key). Must not exceed 255 characters.
  --first-name: string # The first (given) name of the user (e.g. Jane)
  --hard-lock: oneof<nothing, bool> # True if the user should be locked from the system
  --home-org: int # The primary organization for the user. Must match the id of an Organization Unit. (format: int64, e.g. 1234)
  --last-name: any # The last name (surname) of the user (format: string, e.g. Doe)
  --locale: string # The user's preferred language/locale setting. Affects date and number formatting. (format: locale, e.g. en-US)
  --primary-email: string # The primary email for the user. Used for communication from the platform. (e.g. jane.doe@example.com)
]: any -> record<userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users" $auth.query)
  let req_body = {"displayName": $display_name, "externalId": $external_id, "firstName": $first_name, "hardLock": $hard_lock, "homeOrg": $home_org, "lastName": $last_name, "locale": $locale, "primaryEmail": $primary_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# User information
#
# GET /users/{userid}
export def "users get" [
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorizationPossible: bool, displayName: string, externalId: string, firstLogin: string, firstName: string, hardLock: bool, homeOrg: int, id: string, lastLogin: string, lastName: string, locked: bool, prefs: record<locale: string>, primaryEmail: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({userid: (encode-path-segment $userid)} | format pattern "/users/{userid}") $auth.query)
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

# Updates user information
#
# PATCH /users/{userid}
export def "users update" [
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The name shown when the user is listed (e.g. Jane Doe)
  --external-id: string # The external id (foreign key). Must not exceed 255 characters.
  --first-name: string # The first (given) name of the user (e.g. Jane)
  --hard-lock: oneof<nothing, bool> # True if the user should be locked from the system
  --home-org: int # The primary organization for the user. Must match the id of an Organization Unit. (format: int64, e.g. 1234)
  --last-name: any # The last name (surname) of the user (format: string, e.g. Doe)
  --locale: string # The user's preferred language/locale setting. Affects date and number formatting. (format: locale, e.g. en-US)
  --primary-email: string # The primary email for the user. Used for communication from the platform. (e.g. jane.doe@example.com)
]: any -> record<code: int, field: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({userid: (encode-path-segment $userid)} | format pattern "/users/{userid}") $auth.query)
  let req_body = {"displayName": $display_name, "externalId": $external_id, "firstName": $first_name, "hardLock": $hard_lock, "homeOrg": $home_org, "lastName": $last_name, "locale": $locale, "primaryEmail": $primary_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# User profile picture
#
# GET /users/{userid}/pic?key={APIKEY}
export def "users-pic-key-apikey get" [
  userid: string
  apikey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, field: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  if ($apikey | is-empty) { error make --unspanned { msg: "path parameter 'APIKEY' must be non-empty" } }
  let full_url = (build-url $base ({userid: (encode-path-segment $userid), apikey: (encode-path-segment $apikey)} | format pattern "/users/{userid}/pic?key={apikey}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [200 302]
}

# Returns information about the projects the user is a participant in.
#
# GET /users/{userid}/projectParticipations
export def "users-project-participations get" [
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accessLink: string, activated: bool, activitiesCompleted: float, activitiesTotal: float, errorMessage: string, expiration: string, externalId: string, firstAccess: string, firstActivation: string, firstMail: string, id: int, inError: bool, lastAccess: string, lastActivation: string, lastMail: string, projectId: int, projectName: string, projectOrgId: int, projectStatus: string, projectThumbnail: string, projectUserTitle: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({userid: (encode-path-segment $userid)} | format pattern "/users/{userid}/projectParticipations") $auth.query)
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
