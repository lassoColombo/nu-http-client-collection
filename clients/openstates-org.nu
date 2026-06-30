# Auto-generated client for Open States API v3 v2021.11.12
# Source: https://api.apis.guru/v2/specs/openstates.org/2021.11.12/openapi.json
# Auth: --token flag or $env.OPEN_STATES_API_V3_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o OPEN_STATES_API_V3_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def classification-completer [] { ["committee" "subcommittee"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bills list-get" } } | get name | first)
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

# Bills Search
#
# GET /bills
# operationId: bills_search_bills_get
export def "bills list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jurisdiction: string # Filter by jurisdiction name or ID.
  --session: string # Filter by session identifier.
  --chamber: string # Filter by chamber of origination.
  --identifier: list<string> # Filter to only include bills with this identifier. (default: [])
  --classification: string # Filter by classification, e.g. bill or resolution
  --subject: list<string> # Filter by one or more subjects. (default: [])
  --updated-since: string # Filter to only include bills with updates since a given date.
  --created-since: string # Filter to only include bills created since a given date.
  --action-since: string # Filter to only include bills with an action since a given date.
  --qp-sort: string # Desired sort order for bill results. (default: updated_desc)
  --sponsor: string # Filter to only include bills sponsored by a given name or person ID.
  --sponsor-classification: string # Filter matched sponsors to only include particular types of sponsorships.
  --q: string # Filter by full text search term.
  --include: list # Additional information to include in response. (default: [])
  --page: int # default: 1
  --per-page: int # default: 10
  --apikey: string
  --x-api-key: string
]: nothing -> record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<abstracts: list, actions: list, classification: list, created_at: string, documents: list, extras: record, first_action_date: string, from_organization: record, id: string, identifier: string, jurisdiction: record, latest_action_date: string, latest_action_description: string, latest_passage_date: string, openstates_url: string, other_identifiers: list, other_titles: list, related_bills: list, session: string, sources: list, sponsorships: list, subject: list, title: string, updated_at: string, versions: list, votes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jurisdiction" $jurisdiction "scalar") (serialize-qp "session" $session "scalar") (serialize-qp "chamber" $chamber "scalar") (serialize-qp "identifier" $identifier "multi") (serialize-qp "classification" $classification "scalar") (serialize-qp "subject" $subject "multi") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "created_since" $created_since "scalar") (serialize-qp "action_since" $action_since "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sponsor" $sponsor "scalar") (serialize-qp "sponsor_classification" $sponsor_classification "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bills" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jurisdiction": $jurisdiction, "session": $session, "chamber": $chamber, "identifier": $identifier, "classification": $classification, "subject": $subject, "updated_since": $updated_since, "created_since": $created_since, "action_since": $action_since, "sort": $qp_sort, "sponsor": $sponsor, "sponsor_classification": $sponsor_classification, "q": $q, "include": $include, "page": $page, "per_page": $per_page, "apikey": $apikey} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Bill Detail By Id
#
# GET /bills/ocd-bill/{openstates_bill_id}
# operationId: bill_detail_by_id_bills_ocd_bill__openstates_bill_id__get
export def "bills-ocd-bill get-detail-by" [
  openstates_bill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # default: []
  --apikey: string
  --x-api-key: string
]: nothing -> record<abstracts: table<abstract: string, note: string>, actions: table<classification: list, date: string, description: string, order: int, organization: record>, classification: list<string>, created_at: string, documents: table<date: string, links: list, note: string>, extras: record, first_action_date: string, from_organization: record<classification: string, id: string, name: string>, id: string, identifier: string, jurisdiction: record<classification: record, id: string, name: string>, latest_action_date: string, latest_action_description: string, latest_passage_date: string, openstates_url: string, other_identifiers: table<identifier: string>, other_titles: table<note: string, title: string>, related_bills: table<identifier: string, legislative_session: string, relation_type: string>, session: string, sources: table<note: string, url: string>, sponsorships: table<classification: string, entity_type: string, name: string, organization: record, person: record, primary: bool>, subject: list<string>, title: string, updated_at: string, versions: table<date: string, links: list, note: string>, votes: table<counts: list, extras: record, id: string, identifier: string, motion_classification: list, motion_text: string, organization: record, result: string, sources: list, start_date: string, votes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($openstates_bill_id | is-empty) { error make --unspanned { msg: "path parameter 'openstates_bill_id' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({openstates_bill_id: (encode-path-segment $openstates_bill_id)} | format pattern "/bills/ocd-bill/{openstates_bill_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include": $include, "apikey": $apikey} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Bill Detail
#
# GET /bills/{jurisdiction}/{session}/{bill_id}
# operationId: bill_detail_bills__jurisdiction___session___bill_id__get
export def "bills get-detail" [
  jurisdiction: string
  session: string
  bill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # default: []
  --apikey: string
  --x-api-key: string
]: nothing -> record<abstracts: table<abstract: string, note: string>, actions: table<classification: list, date: string, description: string, order: int, organization: record>, classification: list<string>, created_at: string, documents: table<date: string, links: list, note: string>, extras: record, first_action_date: string, from_organization: record<classification: string, id: string, name: string>, id: string, identifier: string, jurisdiction: record<classification: record, id: string, name: string>, latest_action_date: string, latest_action_description: string, latest_passage_date: string, openstates_url: string, other_identifiers: table<identifier: string>, other_titles: table<note: string, title: string>, related_bills: table<identifier: string, legislative_session: string, relation_type: string>, session: string, sources: table<note: string, url: string>, sponsorships: table<classification: string, entity_type: string, name: string, organization: record, person: record, primary: bool>, subject: list<string>, title: string, updated_at: string, versions: table<date: string, links: list, note: string>, votes: table<counts: list, extras: record, id: string, identifier: string, motion_classification: list, motion_text: string, organization: record, result: string, sources: list, start_date: string, votes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jurisdiction | is-empty) { error make --unspanned { msg: "path parameter 'jurisdiction' must be non-empty" } }
  if ($session | is-empty) { error make --unspanned { msg: "path parameter 'session' must be non-empty" } }
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'bill_id' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({jurisdiction: (encode-path-segment $jurisdiction), session: (encode-path-segment $session), bill_id: (encode-path-segment $bill_id)} | format pattern "/bills/{jurisdiction}/{session}/{bill_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include": $include, "apikey": $apikey} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Committee List
#
# GET /committees
# operationId: committee_list_committees_get
export def "committees list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jurisdiction: string # Filter by jurisdiction name or ID.
  --classification: string@classification-completer
  --parent: string # ocd-organization ID of parent committee.
  --chamber: string # Chamber of committee, generally upper or lower.
  --include: list # Additional includes for the Committee response. (default: [])
  --apikey: string
  --page: int # default: 1
  --per-page: int # default: 20
  --x-api-key: string
]: nothing -> record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<classification: string, extras: record, id: string, links: list, memberships: list, name: string, other_names: list, parent_id: string, sources: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jurisdiction" $jurisdiction "scalar") (serialize-qp "classification" $classification "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "chamber" $chamber "scalar") (serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/committees" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jurisdiction": $jurisdiction, "classification": $classification, "parent": $parent, "chamber": $chamber, "include": $include, "apikey": $apikey, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Committee Detail
#
# GET /committees/{committee_id}
# operationId: committee_detail_committees__committee_id__get
export def "committees get-detail" [
  committee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Additional includes for the Committee response. (default: [])
  --apikey: string
  --x-api-key: string
]: nothing -> record<classification: string, extras: record, id: string, links: table<note: string, url: string>, memberships: table<person: record, person_name: string, role: string>, name: string, other_names: table<name: string, note: string>, parent_id: string, sources: table<note: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($committee_id | is-empty) { error make --unspanned { msg: "path parameter 'committee_id' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({committee_id: (encode-path-segment $committee_id)} | format pattern "/committees/{committee_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include": $include, "apikey": $apikey} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Event List
#
# GET /events
# operationId: event_list_events_get
export def "events list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jurisdiction: string # Filter by jurisdiction name or ID.
  --deleted: oneof<nothing, bool> # Return events marked as deleted? (default: false)
  --before: string # Limit results to those starting before a given datetime.
  --after: string # Limit results to those starting before a given datetime.
  --require-bills: oneof<nothing, bool> # Limit results to events with associated bills. (default: false)
  --include: list # Additional includes for the Event response. (default: [])
  --apikey: string
  --page: int # default: 1
  --per-page: int # default: 20
  --x-api-key: string
]: nothing -> record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<agenda: list, all_day: bool, classification: string, deleted: bool, description: string, documents: list, end_date: string, id: string, jurisdiction: record, links: list, location: record, media: list, name: string, participants: list, sources: list, start_date: string, status: string, upstream_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jurisdiction" $jurisdiction "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "require_bills" $require_bills "scalar") (serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jurisdiction": $jurisdiction, "deleted": $deleted, "before": $before, "after": $after, "require_bills": $require_bills, "include": $include, "apikey": $apikey, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Event Detail
#
# GET /events/{event_id}
# operationId: event_detail_events__event_id__get
export def "events get-detail" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Additional includes for the Event response. (default: [])
  --apikey: string
  --x-api-key: string
]: nothing -> record<agenda: table<classification: list, description: string, extras: record, media: list, notes: list, order: int, related_entities: list, subjects: list>, all_day: bool, classification: string, deleted: bool, description: string, documents: table<classification: string, date: string, links: list, note: string>, end_date: string, id: string, jurisdiction: record<classification: record, id: string, name: string>, links: table<note: string, url: string>, location: record<name: string, url: string>, media: table<classification: string, date: string, links: list, note: string, offset: int>, name: string, participants: table<entity_type: string, name: string, note: string, organization: record, person: record>, sources: table<note: string, url: string>, start_date: string, status: string, upstream_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include": $include, "apikey": $apikey} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Jurisdiction List
#
# GET /jurisdictions
# operationId: jurisdiction_list_jurisdictions_get
export def "jurisdictions list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --classification: string # Filter returned jurisdictions by type.
  --include: list # Additional information to include in response. (default: [])
  --page: int # default: 1
  --per-page: int # default: 52
  --apikey: string
  --x-api-key: string
]: nothing -> record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<classification: record, division_id: string, id: string, latest_bill_update: string, latest_people_update: string, latest_runs: list, legislative_sessions: list, name: string, organizations: list, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "classification" $classification "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jurisdictions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"classification": $classification, "include": $include, "page": $page, "per_page": $per_page, "apikey": $apikey} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Jurisdiction Detail
#
# GET /jurisdictions/{jurisdiction_id}
# operationId: jurisdiction_detail_jurisdictions__jurisdiction_id__get
export def "jurisdictions get-detail" [
  jurisdiction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Additional includes for the Jurisdiction response. (default: [])
  --apikey: string
  --x-api-key: string
]: nothing -> record<classification: record, division_id: string, id: string, latest_bill_update: string, latest_people_update: string, latest_runs: table<end_time: string, start_time: string, success: bool>, legislative_sessions: table<classification: string, downloads: list, end_date: string, identifier: string, name: string, start_date: string>, name: string, organizations: table<classification: string, districts: list, id: string, name: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jurisdiction_id | is-empty) { error make --unspanned { msg: "path parameter 'jurisdiction_id' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({jurisdiction_id: (encode-path-segment $jurisdiction_id)} | format pattern "/jurisdictions/{jurisdiction_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include": $include, "apikey": $apikey} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Metrics
#
# GET /metrics
# operationId: metrics_metrics_get
export def "metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics" $auth.query)
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

# People Search
#
# GET /people
# operationId: people_search_people_get
export def "people list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jurisdiction: string # Filter by jurisdiction name or id.
  --name: string # Filter by name, case-insensitive match.
  --id: list<string> # Filter by id, can be specified multiple times for multiple people. (default: [])
  --org-classification: string # Filter by current role.
  --district: string # Filter by district name.
  --include: list # Additional information to include in response. (default: [])
  --page: int # default: 1
  --per-page: int # default: 10
  --apikey: string
  --x-api-key: string
]: nothing -> record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<birth_date: string, created_at: string, current_role: record, death_date: string, email: string, extras: record, family_name: string, gender: string, given_name: string, id: string, image: string, jurisdiction: record, links: list, name: string, offices: list, openstates_url: string, other_identifiers: list, other_names: list, party: string, sources: list, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jurisdiction" $jurisdiction "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "id" $id "multi") (serialize-qp "org_classification" $org_classification "scalar") (serialize-qp "district" $district "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/people" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jurisdiction": $jurisdiction, "name": $name, "id": $id, "org_classification": $org_classification, "district": $district, "include": $include, "page": $page, "per_page": $per_page, "apikey": $apikey} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# People Geo
#
# GET /people.geo
# operationId: people_geo_people_geo_get
export def "people-geo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # Latitude of point.
  --lng: float # Longitude of point.
  --include: list # Additional information to include in the response. (default: [])
  --apikey: string
  --x-api-key: string
]: nothing -> record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<birth_date: string, created_at: string, current_role: record, death_date: string, email: string, extras: record, family_name: string, gender: string, given_name: string, id: string, image: string, jurisdiction: record, links: list, name: string, offices: list, openstates_url: string, other_identifiers: list, other_names: list, party: string, sources: list, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/people.geo" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lat": $lat, "lng": $lng, "include": $include, "apikey": $apikey} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
