# Auto-generated client for Domains vv3
# Source: https://api.apis.guru/v2/specs/hubapi.com/cms/v3/openapi.json
# Auth: --token flag or $env.DOMAINS_TOKEN

const BASE_URL = "https://api.hubapi.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o DOMAINS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-hapikey" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "hapikey")=(encode-path-segment $token_val)", location: "query"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "private-app" => { {scheme: $scheme, headers: {private-app: $token_val}, query: "", location: "header"} }
    "private-app-legacy" => { {scheme: $scheme, headers: {private-app-legacy: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.hubapi.com"] }
def auth-scheme-completer [] { ["query-hapikey" "bearer" "private-app" "private-app-legacy"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cms-domains get-page" } } | get name | first)
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

# Get current domains
#
# GET /cms/v3/domains/
# operationId: get-/cms/v3/domains/_getPage
export def "cms-domains get-page" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # Only return domains created at this date. (format: date-time)
  --created-after: string # Only return domains created after this date. (format: date-time)
  --created-before: string # Only return domains created before this date. (format: date-time)
  --updated-at: string # Only return domains updated at this date. (format: date-time)
  --updated-after: string # Only return domains updated after this date. (format: date-time)
  --updated-before: string # Only return domains updated before this date. (format: date-time)
  --qp-sort: list<string>
  --after: string # The paging cursor token of the last successfully read resource will be returned as the `paging.next.after` JSON property of a paged response containing more results.
  --limit: int # Maximum number of results per page. (format: int32)
  --archived: oneof<nothing, bool> # Whether to return only results that have been archived.
]: nothing -> record<paging: record<next: record<after: string, link: string>>, results: table<correctCname: string, created: string, domain: string, id: string, isResolving: bool, isSslEnabled: bool, isSslOnly: bool, isUsedForBlogPost: bool, isUsedForEmail: bool, isUsedForKnowledge: bool, isUsedForLandingPage: bool, isUsedForSitePage: bool, manuallyMarkedAsResolving: bool, primaryBlogPost: bool, primaryEmail: bool, primaryKnowledge: bool, primaryLandingPage: bool, primarySitePage: bool, secondaryToDomain: string, updated: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "createdAt" $created_at "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar") (serialize-qp "updatedAt" $updated_at "scalar") (serialize-qp "updatedAfter" $updated_after "scalar") (serialize-qp "updatedBefore" $updated_before "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cms/v3/domains/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"createdAt": $created_at, "createdAfter": $created_after, "createdBefore": $created_before, "updatedAt": $updated_at, "updatedAfter": $updated_after, "updatedBefore": $updated_before, "sort": $qp_sort, "after": $after, "limit": $limit, "archived": $archived} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a single domain
#
# GET /cms/v3/domains/{domainId}
# operationId: get-/cms/v3/domains/{domainId}_getById
export def "cms-domains get" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<correctCname: string, created: string, domain: string, id: string, isResolving: bool, isSslEnabled: bool, isSslOnly: bool, isUsedForBlogPost: bool, isUsedForEmail: bool, isUsedForKnowledge: bool, isUsedForLandingPage: bool, isUsedForSitePage: bool, manuallyMarkedAsResolving: bool, primaryBlogPost: bool, primaryEmail: bool, primaryKnowledge: bool, primaryLandingPage: bool, primarySitePage: bool, secondaryToDomain: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_id | is-empty) { error make --unspanned { msg: "path parameter 'domainId' must be non-empty" } }
  let full_url = (build-url $base ({domain_id: (encode-path-segment $domain_id)} | format pattern "/cms/v3/domains/{domain_id}") $auth.query)
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
