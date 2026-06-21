# Auto-generated client for Pims v1.0
# Source: https://api.apis.guru/v2/specs/pims.io/1.0/swagger.json
# Auth: --token flag or $env.PIMS_TOKEN

const BASE_URL = "https://demo.pims.io/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PIMS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://demo.pims.io/api/v1"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def sort-completer [] { ["-label" "-order" "label" "order"] }
def accept-language-completer [] { ["de" "en" "fr"] }
def sort-completer-1 [] { ["-city" "-datetime" "-label" "-venue_label" "city" "datetime" "label" "venue_label"] }
def sort-completer-2 [] { ["-date" "date"] }
def sort-completer-3 [] { ["-date" "-total_cost" "date" "total_cost"] }
def type-completer [] { ["LGS" "TOU"] }
def sort-completer-4 [] { ["-first_date" "-label" "-last_date" "first_date" "label" "last_date"] }
def type-completer-1 [] { ["FES" "SAL"] }
def sort-completer-5 [] { ["-city" "-country" "-label" "city" "country" "label"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "categories get-list" } } | get name | first)
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

# Find all categories
#
# GET /categories
# operationId: fetchAllCategories
export def "categories get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the categories whose label/short label contains this value.
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the categories which are not ignored. If set to `true`, show all categories. (default: false)
  --qp-sort: string@sort-completer # Sort the categories in the corresponding order. (default: order)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> table<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label" $label "scalar") (serialize-qp "show_ignored" $show_ignored "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label": $label, "show_ignored": $show_ignored, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Get one category by ID
#
# GET /categories/{category_id}
# operationId: fetchOneCategory
export def "categories get-one" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'category_id' must be non-empty" } }
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/categories/{category_id}"))
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find all channels
#
# GET /channels
# operationId: fetchAllChannels
export def "channels get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the channels whose label contains this value.
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the channels which are not ignored. If set to `true`, show all channels. (default: false)
  --qp-sort: string@sort-completer # Sort the channels in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> table<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label" $label "scalar") (serialize-qp "show_ignored" $show_ignored "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label": $label, "show_ignored": $show_ignored, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Get one channel by ID
#
# GET /channels/{channel_id}
# operationId: fetchOneChannel
export def "channels get-one" [
  channel_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}"))
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find all events
#
# GET /events
# operationId: fetchAllEvents
export def "events get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the events whose label contains this value.
  --from-datetime: string # Find only the events starting after this date. (format: date)
  --to-datetime: string # Find only the events starting before this date. (format: date)
  --city: string # Find only the events whose venue city (or metropolitan area) contains this value.
  --qp-sort: string@sort-completer-1 # Sort the events in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label" $label "scalar") (serialize-qp "from_datetime" $from_datetime "scalar") (serialize-qp "to_datetime" $to_datetime "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label": $label, "from_datetime": $from_datetime, "to_datetime": $to_datetime, "city": $city, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Get one event by ID
#
# GET /events/{event_id}
# operationId: fetchOneEvent
export def "events get-one" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> record<break_even: int, cancellation_date: string, contract: record<partner: record<id: int, label: string>, type: record<id: string, label: string>>, costing_capacity: int, creation_timestamp: int, currency: string, datetime: string, free: bool, general_sales_date: string, id: int, input_type: record<id: string, label: string>, label: string, last_update_timestamp: int, max_capacity: int, presales_date: string, series_id: int, sold_out_date: string, venue: record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}"))
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find all capacities for one event
#
# GET /events/{event_id}/capacities
# operationId: fetchAllEventsCapacities
export def "events-capacities get-list" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories which are not ignored. If set to `true`, show everything. (default: false)
  --qp-sort: string@sort-completer-2 # Sort the capacities in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
]: nothing -> table<date: string, event_categories: list<record>, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let qp = [(serialize-qp "show_ignored" $show_ignored "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}/capacities") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"show_ignored": $show_ignored, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Get one capacity by ID
#
# GET /events/{event_id}/capacities/{capacity_id}
# operationId: fetchOneEventCapacity
export def "events-capacities get-one" [
  event_id: int
  capacity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories which are not ignored. If set to `true`, show everything. (default: false)
]: nothing -> record<date: string, event_categories: table<comps: int, holds: int, id: int, kills: int, sellable_capacity: int, total_capacity: int>, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  if ($capacity_id | is-empty) { error make --unspanned { msg: "path parameter 'capacity_id' must be non-empty" } }
  let qp = [(serialize-qp "show_ignored" $show_ignored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id), capacity_id: (encode-path-segment $capacity_id)} | format pattern "/events/{event_id}/capacities/{capacity_id}") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"show_ignored": $show_ignored} | compact), body: null}
}

# Find all categories for one event
#
# GET /events/{event_id}/categories
# operationId: fetchAllEventsCategories
export def "events-categories get-list" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories/[event-]price ranges which are not ignored. If set to `true`, show everything. (default: false)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
]: nothing -> table<category: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, event_price_ranges: list<record>, id: int, ignored: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let qp = [(serialize-qp "show_ignored" $show_ignored "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}/categories") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"show_ignored": $show_ignored, "page_size": $page_size} | compact), body: null}
}

# Get one event category by ID
#
# GET /events/{event_id}/categories/{category_id}
# operationId: fetchOneEventCategory
export def "events-categories get-one" [
  event_id: int
  category_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the embedded [event-]price ranges which are not ignored. If set to `true`, show everything. (default: false)
]: nothing -> record<category: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, event_price_ranges: table<base_price: float, currency: string, id: int, ignored: bool, price_range: record, public_price: float>, id: int, ignored: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'category_id' must be non-empty" } }
  let qp = [(serialize-qp "show_ignored" $show_ignored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id), category_id: (encode-path-segment $category_id)} | format pattern "/events/{event_id}/categories/{category_id}") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"show_ignored": $show_ignored} | compact), body: null}
}

# Find all channels for one event
#
# GET /events/{event_id}/channels
# operationId: fetchAllEventsChannels
export def "events-channels get-list" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]channels which are not ignored. If set to `true`, show everything. (default: false)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
]: nothing -> table<channel: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, id: int, ignored: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let qp = [(serialize-qp "show_ignored" $show_ignored "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}/channels") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"show_ignored": $show_ignored, "page_size": $page_size} | compact), body: null}
}

# Get one event channel by ID
#
# GET /events/{event_id}/channels/{channel_id}
# operationId: fetchOneEventChannel
export def "events-channels get-one" [
  event_id: int
  channel_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<channel: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, id: int, ignored: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/events/{event_id}/channels/{channel_id}"))
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find all promotions for one event
#
# GET /events/{event_id}/promotions
# operationId: fetchAllEventsPromotions
export def "events-promotions get-list" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the promotions whose label contains this value.
  --from-date: string # Find only the promotions starting after this date. (format: date)
  --to-date: string # Find only the promotions ending before this date. (format: date)
  --type: string # Find only the promotions whose type is equal to this value.
  --family: string # Find only the promotions whose family is equal to this value.
  --qp-sort: string@sort-completer-3 # Sort the promotions in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let qp = [(serialize-qp "label" $label "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "family" $family "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}/promotions") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label": $label, "from_date": $from_date, "to_date": $to_date, "type": $type, "family": $family, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Find all ticket counts for one event
#
# GET /events/{event_id}/ticket-counts
# operationId: fetchAllTicketCounts
export def "events-ticket-counts get-list" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Find only the ticket counts after this date. (format: date)
  --to-date: string # Find only the ticket counts before this date. (format: date)
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories/[event-]price ranges/[event]channels which are not ignored. If set to `true`, show everything. (default: false)
  --show-not-approved: oneof<nothing, bool> # If set to `false`, show only the approved ticket counts. If set to `true`, show all the ticket counts. (default: false)
  --qp-sort: string@sort-completer-2 # Sort the ticket counts in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
]: nothing -> table<approved: bool, comment: string, currency: string, date: string, final: bool, gross: float, id: int, reservations: int, sales: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let qp = [(serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "show_ignored" $show_ignored "scalar") (serialize-qp "show_not_approved" $show_not_approved "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}/ticket-counts") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"from_date": $from_date, "to_date": $to_date, "show_ignored": $show_ignored, "show_not_approved": $show_not_approved, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Find all detailed ticket counts for one event
#
# GET /events/{event_id}/ticket-counts/detailed
# operationId: fetchAllDetailedTicketCounts
export def "events-ticket-counts-detailed get-list" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Find only the ticket counts after this date. (format: date)
  --to-date: string # Find only the ticket counts before this date. (format: date)
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories/[event-]price ranges/[event]channels which are not ignored. If set to `true`, show everything. (default: false)
  --show-not-approved: oneof<nothing, bool> # If set to `false`, show only the approved ticket counts. If set to `true`, show all the ticket counts. (default: false)
  --qp-sort: string@sort-completer-2 # Sort the ticket counts in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
]: nothing -> table<approved: bool, comment: string, date: string, event_channels: list<record>, final: bool, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let qp = [(serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "show_ignored" $show_ignored "scalar") (serialize-qp "show_not_approved" $show_not_approved "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}/ticket-counts/detailed") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"from_date": $from_date, "to_date": $to_date, "show_ignored": $show_ignored, "show_not_approved": $show_not_approved, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Get one detailed ticket count by ID
#
# GET /events/{event_id}/ticket-counts/detailed/{ticket_count_id}
# operationId: fetchOneDetailedTicketCount
export def "events-ticket-counts-detailed get-one" [
  event_id: int
  ticket_count_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories/[event-]price ranges/[event]channels which are not ignored. If set to `true`, show everything. (default: false)
]: nothing -> record<approved: bool, comment: string, date: string, event_channels: table<event_categories: list, id: int>, final: bool, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  if ($ticket_count_id | is-empty) { error make --unspanned { msg: "path parameter 'ticket_count_id' must be non-empty" } }
  let qp = [(serialize-qp "show_ignored" $show_ignored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id), ticket_count_id: (encode-path-segment $ticket_count_id)} | format pattern "/events/{event_id}/ticket-counts/detailed/{ticket_count_id}") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"show_ignored": $show_ignored} | compact), body: null}
}

# Get one ticket count by ID
#
# GET /events/{event_id}/ticket-counts/{ticket_count_id}
# operationId: fetchOneTicketCount
export def "events-ticket-counts get-one" [
  event_id: int
  ticket_count_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories/[event-]price ranges/[event]channels which are not ignored. If set to `true`, show everything. (default: false)
]: nothing -> record<approved: bool, comment: string, currency: string, date: string, final: bool, gross: float, id: int, reservations: int, sales: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  if ($ticket_count_id | is-empty) { error make --unspanned { msg: "path parameter 'ticket_count_id' must be non-empty" } }
  let qp = [(serialize-qp "show_ignored" $show_ignored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id), ticket_count_id: (encode-path-segment $ticket_count_id)} | format pattern "/events/{event_id}/ticket-counts/{ticket_count_id}") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"show_ignored": $show_ignored} | compact), body: null}
}

# Find all price ranges
#
# GET /price-ranges
# operationId: fetchAllPriceRanges
export def "price-ranges get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the price ranges whose label contains this value.
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the price ranges which are not ignored. If set to `true`, show all price ranges. (default: false)
  --qp-sort: string@sort-completer # Sort the price ranges in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> table<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label" $label "scalar") (serialize-qp "show_ignored" $show_ignored "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/price-ranges" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label": $label, "show_ignored": $show_ignored, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Get one price range by ID
#
# GET /price-ranges/{price_range_id}
# operationId: fetchOnePriceRange
export def "price-ranges get-one" [
  price_range_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($price_range_id | is-empty) { error make --unspanned { msg: "path parameter 'price_range_id' must be non-empty" } }
  let full_url = (build-url $base ({price_range_id: (encode-path-segment $price_range_id)} | format pattern "/price-ranges/{price_range_id}"))
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find all promotions
#
# GET /promotions
# operationId: fetchAllPromotions
export def "promotions get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the promotions whose label contains this value.
  --from-date: string # Find only the promotions starting after this date. (format: date)
  --to-date: string # Find only the promotions ending before this date. (format: date)
  --type: string # Find only the promotions whose type is equal to this value.
  --family: string # Find only the promotions whose family is equal to this value.
  --qp-sort: string@sort-completer-3 # Sort the promotions in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label" $label "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "family" $family "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/promotions" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label": $label, "from_date": $from_date, "to_date": $to_date, "type": $type, "family": $family, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Get one promotion by ID
#
# GET /promotions/{promotion_id}
# operationId: fetchOnePromotion
export def "promotions get-one" [
  promotion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> record<applied_to: table<event_id: int, quantity: float, series_id: int, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, comments: string, cost: record<currency: string, exchange: string, quantity: float, state: record<id: string, label: string>, type: record<id: string, label: string>, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, end_date: string, file: string, id: int, label: string, start_date: string, supplier: record<id: int, label: string>, type: record<family: record<id: string, label: string>, id: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let full_url = (build-url $base ({promotion_id: (encode-path-segment $promotion_id)} | format pattern "/promotions/{promotion_id}"))
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find all series
#
# GET /series
# operationId: fetchAllSeries
export def "series get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the venues whose label contains this value.
  --from-date: string # Find only the series starting after this date. (format: date)
  --to-date: string # Find only the series ending before this date. (format: date)
  --type: string@type-completer # Find only the series whose type is equal to this value.
  --qp-sort: string@sort-completer-4 # Sort the series in the corresponding order. (default: first_date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> table<contract: record<partner: record, type: record>, costing_capacity: int, creation_timestamp: int, first_date: string, id: int, label: string, last_date: string, last_update_timestamp: int, type: record<id: string, label: string>, venue: record<alternative_labels: list, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record, zip_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label" $label "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/series" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label": $label, "from_date": $from_date, "to_date": $to_date, "type": $type, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Get one series by ID
#
# GET /series/{series_id}
# operationId: fetchOneSeries
export def "series get-one" [
  series_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> record<contract: record<partner: record<id: int, label: string>, type: record<id: string, label: string>>, costing_capacity: int, creation_timestamp: int, first_date: string, id: int, label: string, last_date: string, last_update_timestamp: int, type: record<id: string, label: string>, venue: record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($series_id | is-empty) { error make --unspanned { msg: "path parameter 'series_id' must be non-empty" } }
  let full_url = (build-url $base ({series_id: (encode-path-segment $series_id)} | format pattern "/series/{series_id}"))
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find all events for one series
#
# GET /series/{series_id}/events
# operationId: fetchAllSeriesEvents
export def "series-events get-list" [
  series_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-datetime: string # Find only the events starting after this date. (format: date)
  --to-datetime: string # Find only the events starting before this date. (format: date)
  --city: string # Find only the events whose venue city (or metropolitan area) contains this value.
  --qp-sort: string@sort-completer-1 # Sort the events in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($series_id | is-empty) { error make --unspanned { msg: "path parameter 'series_id' must be non-empty" } }
  let qp = [(serialize-qp "from_datetime" $from_datetime "scalar") (serialize-qp "to_datetime" $to_datetime "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({series_id: (encode-path-segment $series_id)} | format pattern "/series/{series_id}/events") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"from_datetime": $from_datetime, "to_datetime": $to_datetime, "city": $city, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Find all promotions for one series
#
# GET /series/{series_id}/promotions
# operationId: fetchAllSeriesPromotions
export def "series-promotions get-list" [
  series_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the promotions whose label contains this value.
  --from-date: string # Find only the promotions starting after this date. (format: date)
  --to-date: string # Find only the promotions ending before this date. (format: date)
  --type: string # Find only the promotions whose type is equal to this value.
  --family: string # Find only the promotions whose family is equal to this value.
  --qp-sort: string@sort-completer-3 # Sort the promotions in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($series_id | is-empty) { error make --unspanned { msg: "path parameter 'series_id' must be non-empty" } }
  let qp = [(serialize-qp "label" $label "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "family" $family "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({series_id: (encode-path-segment $series_id)} | format pattern "/series/{series_id}/promotions") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label": $label, "from_date": $from_date, "to_date": $to_date, "type": $type, "family": $family, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Find all venues
#
# GET /venues
# operationId: fetchAllVenues
export def "venues get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the venues whose label contains this value.
  --city: string # Find only the venues whose city contains this value.
  --country-code: string # Find only the venues whose country_code is equal to this value.
  --type: string@type-completer-1 # Find only the venues whose type is equal to this value.
  --qp-sort: string@sort-completer-5 # Sort the venues in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> table<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label" $label "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "country_code" $country_code "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/venues" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label": $label, "city": $city, "country_code": $country_code, "type": $type, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}

# Get one venue by ID
#
# GET /venues/{venue_id}
# operationId: fetchOneVenue
export def "venues get-one" [
  venue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($venue_id | is-empty) { error make --unspanned { msg: "path parameter 'venue_id' must be non-empty" } }
  let full_url = (build-url $base ({venue_id: (encode-path-segment $venue_id)} | format pattern "/venues/{venue_id}"))
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find all events for one venue
#
# GET /venues/{venue_id}/events
# operationId: fetchAllVenuesEvents
export def "venues-events get-list" [
  venue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-datetime: string # Find only the events starting after this date. (format: date)
  --to-datetime: string # Find only the events starting before this date. (format: date)
  --city: string # Find only the events whose venue city (or metropolitan area) contains this value.
  --qp-sort: string@sort-completer-1 # Sort the events in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($venue_id | is-empty) { error make --unspanned { msg: "path parameter 'venue_id' must be non-empty" } }
  let qp = [(serialize-qp "from_datetime" $from_datetime "scalar") (serialize-qp "to_datetime" $to_datetime "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({venue_id: (encode-path-segment $venue_id)} | format pattern "/venues/{venue_id}/events") $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"from_datetime": $from_datetime, "to_datetime": $to_datetime, "city": $city, "sort": $qp_sort, "page_size": $page_size} | compact), body: null}
}
