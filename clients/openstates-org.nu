# Auto-generated client for Open States API v3 v2021.11.12
# Source: https://api.apis.guru/v2/specs/openstates.org/2021.11.12/openapi.json
# Auth: --token flag or $env.OPEN_STATES_API_V3_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPEN_STATES_API_V3_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def classification-completer [] { ["committee" "subcommittee"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  let full_url = (build-url $base "/bills" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # default: []
  --apikey: string
  --x-api-key: string
]: nothing -> record<abstracts: table<abstract: string, note: string>, actions: table<classification: list, date: string, description: string, order: int, organization: record>, classification: list<string>, created_at: string, documents: table<date: string, links: list, note: string>, extras: record, first_action_date: string, from_organization: record<classification: string, id: string, name: string>, id: string, identifier: string, jurisdiction: record<classification: record, id: string, name: string>, latest_action_date: string, latest_action_description: string, latest_passage_date: string, openstates_url: string, other_identifiers: table<identifier: string>, other_titles: table<note: string, title: string>, related_bills: table<identifier: string, legislative_session: string, relation_type: string>, session: string, sources: table<note: string, url: string>, sponsorships: table<classification: string, entity_type: string, name: string, organization: record, person: record, primary: bool>, subject: list<string>, title: string, updated_at: string, versions: table<date: string, links: list, note: string>, votes: table<counts: list, extras: record, id: string, identifier: string, motion_classification: list, motion_text: string, organization: record, result: string, sources: list, start_date: string, votes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({openstates_bill_id: (encode-path-segment $openstates_bill_id)} | format pattern "/bills/ocd-bill/{openstates_bill_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # default: []
  --apikey: string
  --x-api-key: string
]: nothing -> record<abstracts: table<abstract: string, note: string>, actions: table<classification: list, date: string, description: string, order: int, organization: record>, classification: list<string>, created_at: string, documents: table<date: string, links: list, note: string>, extras: record, first_action_date: string, from_organization: record<classification: string, id: string, name: string>, id: string, identifier: string, jurisdiction: record<classification: record, id: string, name: string>, latest_action_date: string, latest_action_description: string, latest_passage_date: string, openstates_url: string, other_identifiers: table<identifier: string>, other_titles: table<note: string, title: string>, related_bills: table<identifier: string, legislative_session: string, relation_type: string>, session: string, sources: table<note: string, url: string>, sponsorships: table<classification: string, entity_type: string, name: string, organization: record, person: record, primary: bool>, subject: list<string>, title: string, updated_at: string, versions: table<date: string, links: list, note: string>, votes: table<counts: list, extras: record, id: string, identifier: string, motion_classification: list, motion_text: string, organization: record, result: string, sources: list, start_date: string, votes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({jurisdiction: (encode-path-segment $jurisdiction), session: (encode-path-segment $session), bill_id: (encode-path-segment $bill_id)} | format pattern "/bills/{jurisdiction}/{session}/{bill_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/committees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Additional includes for the Committee response. (default: [])
  --apikey: string
  --x-api-key: string
]: nothing -> record<classification: string, extras: record, id: string, links: table<note: string, url: string>, memberships: table<person: record, person_name: string, role: string>, name: string, other_names: table<name: string, note: string>, parent_id: string, sources: table<note: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({committee_id: (encode-path-segment $committee_id)} | format pattern "/committees/{committee_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Additional includes for the Event response. (default: [])
  --apikey: string
  --x-api-key: string
]: nothing -> record<agenda: table<classification: list, description: string, extras: record, media: list, notes: list, order: int, related_entities: list, subjects: list>, all_day: bool, classification: string, deleted: bool, description: string, documents: table<classification: string, date: string, links: list, note: string>, end_date: string, id: string, jurisdiction: record<classification: record, id: string, name: string>, links: table<note: string, url: string>, location: record<name: string, url: string>, media: table<classification: string, date: string, links: list, note: string, offset: int>, name: string, participants: table<entity_type: string, name: string, note: string, organization: record, person: record>, sources: table<note: string, url: string>, start_date: string, status: string, upstream_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/jurisdictions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Additional includes for the Jurisdiction response. (default: [])
  --apikey: string
  --x-api-key: string
]: nothing -> record<classification: record, division_id: string, id: string, latest_bill_update: string, latest_people_update: string, latest_runs: table<end_time: string, start_time: string, success: bool>, legislative_sessions: table<classification: string, downloads: list, end_date: string, identifier: string, name: string, start_date: string>, name: string, organizations: table<classification: string, districts: list, id: string, name: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({jurisdiction_id: (encode-path-segment $jurisdiction_id)} | format pattern "/jurisdictions/{jurisdiction_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/people" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/people.geo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
