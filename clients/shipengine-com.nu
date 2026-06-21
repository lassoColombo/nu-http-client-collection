# Auto-generated client for ShipEngine API v1.1.202303022103
# Source: https://api.apis.guru/v2/specs/shipengine.com/1.1.202303022103/openapi.json
# Auth: --token flag or $env.SHIPENGINE_API_TOKEN

const BASE_URL = "https://api.shipengine.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SHIPENGINE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "api-key" => { {scheme: $scheme, headers: {API-Key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.shipengine.com"] }
def auth-scheme-completer [] { ["api-key"] }

# Completers for enum parameters
def status-completer [] { ["archived" "completed" "completed_with_errors" "invalid" "notifying" "open" "processing" "queued"] }
def sort-by-completer [] { ["created_at" "processed_at" "ship_date"] }
def accept-completer [] { ["application/json" "text/plain"] }
def accept-completer-1 [] { ["application/pdf" "application/zpl" "image/png"] }
def label-status-completer [] { ["completed" "error" "processing" "voided"] }
def sort-by-completer-1 [] { ["created_at" "modified_at"] }
def label-download-type-completer [] { ["inline" "url"] }
def shipment-status-completer [] { ["cancelled" "label_purchased" "pending" "processing"] }
def redirect-completer [] { ["shipengine-dashboard"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "addresses-recognize update-parse-address" } } | get name | first)
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

# Parse an address
#
# PUT /v1/addresses/recognize
# operationId: parse_address
export def "addresses-recognize update-parse-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: any # You can optionally provide any already-known address values. For example, you may already know the recipient's name, city, and country, and only want to parse the street address into separate lines.
  text: string # The unstructured text that contains address-related entities (e.g. Margie McMiller at 3800 North Lamar suite 200 in austin, tx.  The zip code there is 78652.)
]: any -> record<address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: record, city_locality: string, company_name: string, country_code: record, email: string, name: string, phone: string, postal_code: record, state_province: string>, entities: table<end_index: int, result: record, score: float, start_index: int, text: string, type: string>, score: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/addresses/recognize")
  let req_body = {"address": $address, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Validate An Address
#
# POST /v1/addresses/validate
# operationId: validate_address
export def "addresses-validate validate-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> table<matched_address: record, messages: list<record>, original_address: record, status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/addresses/validate")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Batches
#
# GET /v1/batches
# operationId: list_batches
export def "batches list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --sort-dir: string # Controls the sort order of the query. (default: desc)
  --batch-number: string # Batch Number
  --sort-by: string@sort-by-completer
]: nothing -> record<batches: table<batch_errors_url: record, batch_id: record, batch_labels_url: record, batch_notes: string, batch_number: string, batch_shipments_url: record, completed: int, count: int, created_at: record, errors: int, external_batch_id: string, form_download: record, forms: int, label_download: record, label_format: record, label_layout: record, processed_at: record, status: record, warnings: int>, links: record<first: record, last: record, next: record<href: record, type: string>, prev: record<href: record, type: string>>, page: int, pages: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "batch_number" $batch_number "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/batches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"status": $status, "page": $page, "page_size": $page_size, "sort_dir": $sort_dir, "batch_number": $batch_number, "sort_by": $sort_by} | compact), body: null}
}

# Create A Batch
#
# POST /v1/batches
# operationId: create_batch
export def "batches create-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --batch-notes: string # Add custom messages for a particular batch (e.g. This is my batch)
  --external-batch-id: any # A string that uniquely identifies the external batch
  --rate-ids: list<string> # Array of rate IDs used in the batch
  --shipment-ids: list # Array of shipment IDs used in the batch
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batches")
  let req_body = {"batch_notes": $batch_notes, "external_batch_id": $external_batch_id, "rate_ids": $rate_ids, "shipment_ids": $shipment_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Batch By External ID
#
# GET /v1/batches/external_batch_id/{external_batch_id}
# operationId: get_batch_by_external_id
export def "batches-external-batch-id get" [
  external_batch_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($external_batch_id | is-empty) { error make --unspanned { msg: "path parameter 'external_batch_id' must be non-empty" } }
  let full_url = (build-url $base ({external_batch_id: (encode-path-segment $external_batch_id)} | format pattern "/v1/batches/external_batch_id/{external_batch_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete Batch By Id
#
# DELETE /v1/batches/{batch_id}
# operationId: delete_batch
export def "batches delete" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Batch By ID
#
# GET /v1/batches/{batch_id}
# operationId: get_batch_by_id
export def "batches get" [
  batch_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Batch By Id
#
# PUT /v1/batches/{batch_id}
# operationId: update_batch
export def "batches update" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add to a Batch
#
# POST /v1/batches/{batch_id}/add
# operationId: add_to_batch
export def "batches-add create" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --rate-ids: list # Array of Rate IDs to be modifed on the batch
  --shipment-ids: list # The Shipment Ids to be modified on the batch
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}/add"))
  let req_body = {"rate_ids": $rate_ids, "shipment_ids": $shipment_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Batch Errors
#
# GET /v1/batches/{batch_id}/errors
# operationId: list_batch_errors
export def "batches-errors list" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --pagesize: int # format: int32
]: nothing -> record<errors: table<error: string, external_shipment_id: string, shipment_id: record>, links: record<first: record, last: record, next: record<href: record, type: string>, prev: record<href: record, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}/errors") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pagesize": $pagesize} | compact), body: null}
}

# Process Batch ID Labels
#
# POST /v1/batches/{batch_id}/process/labels
# operationId: process_batch
export def "batches-process-labels create" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --display-scheme: any # The display format that the label should be shown in. (default: label)
  --label-format: any # default: pdf
  --label-layout: string # default: 4x6
  --ship-date: any # The Ship date the batch is being processed for
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}/process/labels"))
  let req_body = {"display_scheme": $display_scheme, "label_format": $label_format, "label_layout": $label_layout, "ship_date": $ship_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove From Batch
#
# POST /v1/batches/{batch_id}/remove
# operationId: remove_from_batch
export def "batches-remove delete" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --rate-ids: list # Array of Rate IDs to be modifed on the batch
  --shipment-ids: list # The Shipment Ids to be modified on the batch
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}/remove"))
  let req_body = {"rate_ids": $rate_ids, "shipment_ids": $shipment_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Carriers
#
# GET /v1/carriers
# operationId: list_carriers
export def "carriers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<carriers: table<account_number: string, balance: float, carrier_code: record, carrier_id: record, friendly_name: string, has_multi_package_supporting_services: bool, nickname: string, options: list, packages: list, primary: bool, requires_funded_amount: bool, services: list, supports_label_messages: bool>, errors: table<error_code: record, error_source: record, error_type: record, message: string>, request_id: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/carriers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Carrier By ID
#
# GET /v1/carriers/{carrier_id}
# operationId: get_carrier_by_id
export def "carriers get" [
  carrier_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/carriers/{carrier_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add Funds To Carrier
#
# PUT /v1/carriers/{carrier_id}/add_funds
# operationId: add_funds_to_carrier
export def "carriers-add-funds create" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The monetary amount, in the specified currency. (format: double)
  currency: any
]: any -> record<balance: record<amount: float, currency: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/carriers/{carrier_id}/add_funds"))
  let req_body = {"amount": $amount, "currency": $currency} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Carrier Options
#
# GET /v1/carriers/{carrier_id}/options
# operationId: get_carrier_options
export def "carriers-options get" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<options: table<default_value: string, description: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/carriers/{carrier_id}/options"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Carrier Package Types
#
# GET /v1/carriers/{carrier_id}/packages
# operationId: list_carrier_package_types
export def "carriers-packages list-types" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<packages: table<description: string, dimensions: record, name: string, package_code: record, package_id: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/carriers/{carrier_id}/packages"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Carrier Services
#
# GET /v1/carriers/{carrier_id}/services
# operationId: list_carrier_services
export def "carriers-services list" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<services: table<carrier_code: record, carrier_id: record, domestic: bool, international: bool, is_multi_package_supported: bool, name: string, service_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/carriers/{carrier_id}/services"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Connect a carrier account
#
# POST /v1/connections/carriers/{carrier_name}
# operationId: connect_carrier
export def "connections-carriers create-connect" [
  carrier_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --nickname: string # The nickname associated with the carrier connection (e.g. Stamps.com)
  --password: string # Access Worldwide Password
  --username: string # Access Worldwide Username
  --email: any
  --merchant-seller-id: string
  --mws-auth-token: string
  --auth-code: string # Amazon UK Shipping auth code.
  --account-number: string # Asendia account number
  --ftp-password: string # FTP password
  --ftp-username: string # FTP username
  --api-key: string # API key
  --api-secret: string # API secret
  --contract-id: string # Canada Post Account Contract ID
  --ancillary-endorsement: any
  --client-id: string # The client id
  --distribution-center: string # The distribution center
  --pickup-number: string # The pickup number
  --registration-id: string
  --software-name: string
  --sold-to: string # Sold To field
  --country-code: any
  --site-id: string # Required if password is provided
  --account: string # Account
  --passphrase: string # Passphrase
  --address1: string # Address
  --address2: string # Address
  --agree-to-eula: oneof<nothing, bool> # Boolean signaling agreement to the Fedex End User License Agreement
  --city: string # The city
  --company: string # The company
  --first-name: string # First name
  --last-name: string # Last name
  --meter-number: string # Meter number
  --phone: string # Phone number
  --postal-code: string # Postal Code
  --state: string # State
  --mailer-id: any # A string that uniquely identifies the mailer
  --profile-name: string # Profile name
  --induction-site: string # Induction site
  --merchant-id: int # Merchant id (format: int32)
  --activation-key: string # Activation key
  --company-name: string # Company name
  --contact-name: string # Contact name
  --oba-email: any # The oba email address
  --street-line1: string # Street line1
  --street-line2: string # Street line2
  --street-line3: string # Street line3
  --access-key: string # Seko Account Access Key
  --sendle-id: any # A string that uniquely identifies the sendle
  --account-country-code: string # Account country code
  --account-postal-code: string # Account postal code
  --agree-to-technology-agreement: oneof<nothing, bool> # The Agreement to the [UPS Technology Agreement](https://www.ups.com/assets/resources/media/UTA_with_EUR.pdf)
  --invoice: any # The UPS invoice
  --invoice-amount: float # The invoice amount (format: double)
  --invoice-currency-code: string # The invoice currency code
  --title: string # Title
]: any -> record<carrier_id: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_name | is-empty) { error make --unspanned { msg: "path parameter 'carrier_name' must be non-empty" } }
  let full_url = (build-url $base ({carrier_name: (encode-path-segment $carrier_name)} | format pattern "/v1/connections/carriers/{carrier_name}"))
  let req_body = {"nickname": $nickname, "password": $password, "username": $username, "email": $email, "merchant_seller_id": $merchant_seller_id, "mws_auth_token": $mws_auth_token, "auth_code": $auth_code, "account_number": $account_number, "ftp_password": $ftp_password, "ftp_username": $ftp_username, "api_key": $api_key, "api_secret": $api_secret, "contract_id": $contract_id, "ancillary_endorsement": $ancillary_endorsement, "client_id": $client_id, "distribution_center": $distribution_center, "pickup_number": $pickup_number, "registration_id": $registration_id, "software_name": $software_name, "sold_to": $sold_to, "country_code": $country_code, "site_id": $site_id, "account": $account, "passphrase": $passphrase, "address1": $address1, "address2": $address2, "agree_to_eula": $agree_to_eula, "city": $city, "company": $company, "first_name": $first_name, "last_name": $last_name, "meter_number": $meter_number, "phone": $phone, "postal_code": $postal_code, "state": $state, "mailer_id": $mailer_id, "profile_name": $profile_name, "induction_site": $induction_site, "merchant_id": $merchant_id, "activation_key": $activation_key, "company_name": $company_name, "contact_name": $contact_name, "oba_email": $oba_email, "street_line1": $street_line1, "street_line2": $street_line2, "street_line3": $street_line3, "access_key": $access_key, "sendle_id": $sendle_id, "account_country_code": $account_country_code, "account_postal_code": $account_postal_code, "agree_to_technology_agreement": $agree_to_technology_agreement, "invoice": $invoice, "invoice_amount": $invoice_amount, "invoice_currency_code": $invoice_currency_code, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disconnect a carrier
#
# DELETE /v1/connections/carriers/{carrier_name}/{carrier_id}
# operationId: disconnect_carrier
export def "connections-carriers delete-disconnect" [
  carrier_name: string
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_name | is-empty) { error make --unspanned { msg: "path parameter 'carrier_name' must be non-empty" } }
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_name: (encode-path-segment $carrier_name), carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/connections/carriers/{carrier_name}/{carrier_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get carrier settings
#
# GET /v1/connections/carriers/{carrier_name}/{carrier_id}/settings
# operationId: get_carrier_settings
export def "connections-carriers-settings get" [
  carrier_name: string
  carrier_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_name | is-empty) { error make --unspanned { msg: "path parameter 'carrier_name' must be non-empty" } }
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_name: (encode-path-segment $carrier_name), carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/connections/carriers/{carrier_name}/{carrier_id}/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update carrier settings
#
# PUT /v1/connections/carriers/{carrier_name}/{carrier_id}/settings
# operationId: update_carrier_settings
export def "connections-carriers-settings update" [
  carrier_name: string
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-barcode-with-order-number: oneof<nothing, bool>
  --receive-email-on-manifest-processing: oneof<nothing, bool>
  --email: string # Email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_name | is-empty) { error make --unspanned { msg: "path parameter 'carrier_name' must be non-empty" } }
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_name: (encode-path-segment $carrier_name), carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/connections/carriers/{carrier_name}/{carrier_id}/settings"))
  let req_body = {"include_barcode_with_order_number": $include_barcode_with_order_number, "receive_email_on_manifest_processing": $receive_email_on_manifest_processing, "email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disconnect a Shipsurance Account
#
# DELETE /v1/connections/insurance/shipsurance
# operationId: disconnect_insurer
export def "connections-insurance-shipsurance delete-disconnect-insurer" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/insurance/shipsurance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Connect a Shipsurance Account
#
# POST /v1/connections/insurance/shipsurance
# operationId: connect_insurer
export def "connections-insurance-shipsurance create-connect-insurer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: any
  policy_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/insurance/shipsurance")
  let req_body = {"email": $email, "policy_id": $policy_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Download File
#
# GET /v1/downloads/{dir}/{subdir}/{filename}
# operationId: download_file
export def "downloads download-file" [
  dir: string
  subdir: string
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --download: string
  --rotation: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($dir | is-empty) { error make --unspanned { msg: "path parameter 'dir' must be non-empty" } }
  if ($subdir | is-empty) { error make --unspanned { msg: "path parameter 'subdir' must be non-empty" } }
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "rotation" $rotation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dir: (encode-path-segment $dir), subdir: (encode-path-segment $subdir), filename: (encode-path-segment $filename)} | format pattern "/v1/downloads/{dir}/{subdir}/{filename}") $qp)
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"download": $download, "rotation": $rotation} | compact), body: null}
}

# List Webhooks
#
# GET /v1/environment/webhooks
# operationId: list_webhooks
export def "environment-webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<event: record, url: record, webhook_id: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environment/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a Webhook
#
# POST /v1/environment/webhooks
# operationId: create_webhook
export def "environment-webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: any
  url: any # The url that the webhook sends the request to (e.g. https://[YOUR ENDPOINT ID].x.requestbin.com)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environment/webhooks")
  let req_body = {"event": $event, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Webhook By ID
#
# DELETE /v1/environment/webhooks/{webhook_id}
# operationId: delete_webhook
export def "environment-webhooks delete" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($webhook_id | is-empty) { error make --unspanned { msg: "path parameter 'webhook_id' must be non-empty" } }
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/v1/environment/webhooks/{webhook_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Webhook By ID
#
# GET /v1/environment/webhooks/{webhook_id}
# operationId: get_webhook_by_id
export def "environment-webhooks get" [
  webhook_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($webhook_id | is-empty) { error make --unspanned { msg: "path parameter 'webhook_id' must be non-empty" } }
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/v1/environment/webhooks/{webhook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a Webhook
#
# PUT /v1/environment/webhooks/{webhook_id}
# operationId: update_webhook
export def "environment-webhooks update" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --url: any # The url that the wehbook sends the request (e.g. https://[YOUR ENDPOINT ID].x.requestbin.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($webhook_id | is-empty) { error make --unspanned { msg: "path parameter 'webhook_id' must be non-empty" } }
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/v1/environment/webhooks/{webhook_id}"))
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add Funds To Insurance
#
# PATCH /v1/insurance/shipsurance/add_funds
# operationId: add_funds_to_insurance
export def "insurance-shipsurance-add-funds create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The monetary amount, in the specified currency. (format: double)
  currency: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/insurance/shipsurance/add_funds")
  let req_body = {"amount": $amount, "currency": $currency} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Insurance Funds Balance
#
# GET /v1/insurance/shipsurance/balance
# operationId: get_insurance_balance
export def "insurance-shipsurance-balance get" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/insurance/shipsurance/balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List labels
#
# GET /v1/labels
# operationId: list_labels
export def "labels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-status: string@label-status-completer # Only return labels that are currently in the specified status
  --service-code: string # Only return labels for a specific [carrier service](https://www.shipengine.com/docs/shipping/use-a-carrier-service/) (e.g. usps_first_class_mail)
  --carrier-id: string # Only return labels for a specific [carrier account](https://www.shipengine.com/docs/carriers/setup/) (e.g. se-28529731)
  --tracking-number: string # Only return labels with a specific tracking number (e.g. 9405511899223197428490)
  --batch-id: string # Only return labels that were created in a specific [batch](https://www.shipengine.com/docs/labels/bulk/) (e.g. se-28529731)
  --rate-id: string # Rate ID (e.g. se-28529731)
  --shipment-id: string # Shipment ID (e.g. se-28529731)
  --warehouse-id: string # Only return labels that originate from a specific [warehouse](https://www.shipengine.com/docs/shipping/ship-from-a-warehouse/) (e.g. se-28529731)
  --created-at-start: string # Only return labels that were created on or after a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Only return labels that were created on or before a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --sort-dir: string # Controls the sort order of the query. (default: desc)
  --sort-by: string@sort-by-completer-1 # Controls which field the query is sorted by. (default: created_at)
]: nothing -> record<labels: table<alternative_identifiers: list, batch_id: record, carrier_code: record, carrier_id: record, charge_event: record, created_at: record, display_scheme: record, form_download: record, insurance_claim: record, insurance_cost: record, is_international: bool, is_return_label: bool, label_download: record, label_download_type: record, label_format: record, label_id: record, label_image_id: record, label_layout: record, outbound_label_id: record, package_code: record, packages: list, rma_number: string, service_code: record, ship_date: record, shipment: record, shipment_cost: record, shipment_id: record, status: record, test_label: bool, trackable: bool, tracking_number: string, tracking_status: record, validate_address: record, voided: bool, voided_at: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label_status" $label_status "scalar") (serialize-qp "service_code" $service_code "scalar") (serialize-qp "carrier_id" $carrier_id "scalar") (serialize-qp "tracking_number" $tracking_number "scalar") (serialize-qp "batch_id" $batch_id "scalar") (serialize-qp "rate_id" $rate_id "scalar") (serialize-qp "shipment_id" $shipment_id "scalar") (serialize-qp "warehouse_id" $warehouse_id "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label_status": $label_status, "service_code": $service_code, "carrier_id": $carrier_id, "tracking_number": $tracking_number, "batch_id": $batch_id, "rate_id": $rate_id, "shipment_id": $shipment_id, "warehouse_id": $warehouse_id, "created_at_start": $created_at_start, "created_at_end": $created_at_end, "page": $page, "page_size": $page_size, "sort_dir": $sort_dir, "sort_by": $sort_by} | compact), body: null}
}

# Purchase Label
#
# POST /v1/labels
# operationId: create_label
# --alternative_identifiers item shape: {type?: string, value?: string}
# --packages item shape: {content_description?: string, dimensions?: any, external_package_id?: string, insured_value?: any, label_messages?: any, package_code?: any, package_id?: any, weight: any}
@deprecated --flag test-label
export def "labels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ship-from-service-point-id: string # A unique identifier for a carrier drop off point where a merchant plans to deliver packages. This will take precedence over a shipment's ship from address. (nullable, e.g. 614940)
  --ship-to-service-point-id: string # A unique identifier for a carrier service point where the shipment will be delivered by the carrier. This will take precedence over a shipment's ship to address. (nullable, e.g. 614940)
  --charge-event: any # The label charge event.
  --display-scheme: any # The display format that the label should be shown in. (default: label)
  --is-return-label: oneof<nothing, bool> # Indicates whether this is a return label. You may also want to set the `rma_number` so you know what is being returned.
  --label-download-type: any # default: url
  --label-format: any # The file format that you want the label to be in. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. (default: pdf)
  --label-image-id: any # The label image resource that was used to create a custom label image. (nullable)
  --label-layout: any # The layout (size) that you want the label to be in. The `label_format` determines which sizes are allowed. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
  --outbound-label-id: any # The `label_id` of the original (outgoing) label that the return label is for. This associates the two labels together, which is required by some carriers.
  --rma-number: string # An optional Return Merchandise Authorization number. This field is useful for return labels. You can set it to any string value. (nullable)
  shipment: any # The shipment information used to generate the label
  --test-label: oneof<nothing, bool> # Indicate if this label is being used only for testing purposes. If true, then no charge will be added to your account. (DEPRECATED, default: false)
  --validate-address: any # default: validate_and_clean
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/labels")
  let req_body = {"ship_from_service_point_id": $ship_from_service_point_id, "ship_to_service_point_id": $ship_to_service_point_id, "charge_event": $charge_event, "display_scheme": $display_scheme, "is_return_label": $is_return_label, "label_download_type": $label_download_type, "label_format": $label_format, "label_image_id": $label_image_id, "label_layout": $label_layout, "outbound_label_id": $outbound_label_id, "rma_number": $rma_number, "shipment": $shipment, "test_label": $test_label, "validate_address": $validate_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Label By External Shipment ID
#
# GET /v1/labels/external_shipment_id/{external_shipment_id}
# operationId: get_label_by_external_shipment_id
export def "labels-external-shipment-id get" [
  external_shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-download-type: string@label-download-type-completer # e.g. url
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($external_shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'external_shipment_id' must be non-empty" } }
  let qp = [(serialize-qp "label_download_type" $label_download_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_shipment_id: (encode-path-segment $external_shipment_id)} | format pattern "/v1/labels/external_shipment_id/{external_shipment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label_download_type": $label_download_type} | compact), body: null}
}

# Purchase Label with Rate ID
#
# POST /v1/labels/rates/{rate_id}
# operationId: create_label_from_rate
export def "labels-rates create" [
  rate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-scheme: any # The display format that the label should be shown in. (default: label)
  --label-download-type: any
  --label-format: any # default: pdf
  --label-layout: any # default: 4x6
  --validate-address: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($rate_id | is-empty) { error make --unspanned { msg: "path parameter 'rate_id' must be non-empty" } }
  let full_url = (build-url $base ({rate_id: (encode-path-segment $rate_id)} | format pattern "/v1/labels/rates/{rate_id}"))
  let req_body = {"display_scheme": $display_scheme, "label_download_type": $label_download_type, "label_format": $label_format, "label_layout": $label_layout, "validate_address": $validate_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Purchase Label with Shipment ID
#
# POST /v1/labels/shipment/{shipment_id}
# operationId: create_label_from_shipment
export def "labels-shipment create" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-scheme: any # The display format that the label should be shown in. (default: label)
  --label-download-type: any
  --label-format: any # default: pdf
  --label-layout: any # default: 4x6
  --validate-address: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/v1/labels/shipment/{shipment_id}"))
  let req_body = {"display_scheme": $display_scheme, "label_download_type": $label_download_type, "label_format": $label_format, "label_layout": $label_layout, "validate_address": $validate_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Label By ID
#
# GET /v1/labels/{label_id}
# operationId: get_label_by_id
export def "labels get" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-download-type: string@label-download-type-completer # e.g. url
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($label_id | is-empty) { error make --unspanned { msg: "path parameter 'label_id' must be non-empty" } }
  let qp = [(serialize-qp "label_download_type" $label_download_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({label_id: (encode-path-segment $label_id)} | format pattern "/v1/labels/{label_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"label_download_type": $label_download_type} | compact), body: null}
}

# Create a return label
#
# POST /v1/labels/{label_id}/return
# operationId: create_return_label
export def "labels-return create" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --charge-event: any # The label charge event.
  --display-scheme: any # The display format that the label should be shown in. (default: label)
  --label-download-type: any # default: url
  --label-format: any # The file format that you want the label to be in. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. (default: pdf)
  --label-image-id: any # The label image resource that was used to create a custom label image. (nullable)
  --label-layout: any # The layout (size) that you want the label to be in. The `label_format` determines which sizes are allowed. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($label_id | is-empty) { error make --unspanned { msg: "path parameter 'label_id' must be non-empty" } }
  let full_url = (build-url $base ({label_id: (encode-path-segment $label_id)} | format pattern "/v1/labels/{label_id}/return"))
  let req_body = {"charge_event": $charge_event, "display_scheme": $display_scheme, "label_download_type": $label_download_type, "label_format": $label_format, "label_image_id": $label_image_id, "label_layout": $label_layout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Label Tracking Information
#
# GET /v1/labels/{label_id}/track
# operationId: get_tracking_log_from_label
export def "labels-track get-tracking-log" [
  label_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($label_id | is-empty) { error make --unspanned { msg: "path parameter 'label_id' must be non-empty" } }
  let full_url = (build-url $base ({label_id: (encode-path-segment $label_id)} | format pattern "/v1/labels/{label_id}/track"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Void a Label By ID
#
# PUT /v1/labels/{label_id}/void
# operationId: void_label
export def "labels-void update" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<approved: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($label_id | is-empty) { error make --unspanned { msg: "path parameter 'label_id' must be non-empty" } }
  let full_url = (build-url $base ({label_id: (encode-path-segment $label_id)} | format pattern "/v1/labels/{label_id}/void"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Manifests
#
# GET /v1/manifests
# operationId: list_manifests
export def "manifests list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --warehouse-id: string # Warehouse ID (e.g. se-28529731)
  --ship-date-start: string # ship date start range (format: date-time, e.g. 2018-09-23T15:00:00.000Z)
  --ship-date-end: string # ship date end range (format: date-time, e.g. 2018-09-23T15:00:00.000Z)
  --created-at-start: string # Used to create a filter for when a resource was created (ex. A shipment that was created after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Used to create a filter for when a resource was created, (ex. A shipment that was created before a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --carrier-id: string # Carrier ID (e.g. se-28529731)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --label-ids: list<string>
]: nothing -> record<links: record<first: record, last: record, next: record<href: record, type: string>, prev: record<href: record, type: string>>, manifests: table<carrier_id: record, created_at: string, form_id: record, label_ids: list, manifest_download: record, manifest_id: record, ship_date: string, shipments: int, submission_id: string, warehouse_id: record>, page: int, pages: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "warehouse_id" $warehouse_id "scalar") (serialize-qp "ship_date_start" $ship_date_start "scalar") (serialize-qp "ship_date_end" $ship_date_end "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "carrier_id" $carrier_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "label_ids" $label_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/manifests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"warehouse_id": $warehouse_id, "ship_date_start": $ship_date_start, "ship_date_end": $ship_date_end, "created_at_start": $created_at_start, "created_at_end": $created_at_end, "carrier_id": $carrier_id, "page": $page, "page_size": $page_size, "label_ids": $label_ids} | compact), body: null}
}

# Create Manifest
#
# POST /v1/manifests
# operationId: create_manifest
export def "manifests create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-id: any # A string that uniquely identifies the carrier
  --excluded-label-ids: list # The list of label ids to exclude from the manifest
  --label-ids: list # The list of label ids to include for the manifest
  --ship-date: string # The ship date that the shipment will be sent out on (format: date-time, e.g. 2018-09-23T15:00:00.000Z)
  --warehouse-id: any # A string that uniquely identifies the warehouse
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/manifests")
  let req_body = {"carrier_id": $carrier_id, "excluded_label_ids": $excluded_label_ids, "label_ids": $label_ids, "ship_date": $ship_date, "warehouse_id": $warehouse_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Manifest Request By Id
#
# GET /v1/manifests/requests/{manifest_request_id}
# operationId: get_manifest_request_by_id
export def "manifests-requests get" [
  manifest_request_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($manifest_request_id | is-empty) { error make --unspanned { msg: "path parameter 'manifest_request_id' must be non-empty" } }
  let full_url = (build-url $base ({manifest_request_id: (encode-path-segment $manifest_request_id)} | format pattern "/v1/manifests/requests/{manifest_request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Manifest By Id
#
# GET /v1/manifests/{manifest_id}
# operationId: get_manifest_by_id
export def "manifests get" [
  manifest_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($manifest_id | is-empty) { error make --unspanned { msg: "path parameter 'manifest_id' must be non-empty" } }
  let full_url = (build-url $base ({manifest_id: (encode-path-segment $manifest_id)} | format pattern "/v1/manifests/{manifest_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Custom Package Types
#
# GET /v1/packages
# operationId: list_package_types
export def "packages list-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<packages: table<description: string, dimensions: record, name: string, package_code: record, package_id: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/packages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Custom Package Type
#
# POST /v1/packages
# operationId: create_package_type
export def "packages create-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Provides a helpful description for the custom package. (nullable, e.g. Packaging for laptops)
  --dimensions: any # The custom dimensions for the package.
  name: string # e.g. laptop_box
  package_code: any
  --package-id: any # A string that uniquely identifies the package.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/packages")
  let req_body = {"description": $description, "dimensions": $dimensions, "name": $name, "package_code": $package_code, "package_id": $package_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete A Custom Package By ID
#
# DELETE /v1/packages/{package_id}
# operationId: delete_package_type
export def "packages delete-type" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'package_id' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/v1/packages/{package_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Custom Package Type By ID
#
# GET /v1/packages/{package_id}
# operationId: get_package_type_by_id
export def "packages get-type" [
  package_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'package_id' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/v1/packages/{package_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Custom Package Type By ID
#
# PUT /v1/packages/{package_id}
# operationId: update_package_type
export def "packages update-type" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Provides a helpful description for the custom package. (nullable, e.g. Packaging for laptops)
  --dimensions: any # The custom dimensions for the package.
  name: string # e.g. laptop_box
  package_code: any
  --body-package-id: any # A string that uniquely identifies the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'package_id' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/v1/packages/{package_id}"))
  let req_body = {"description": $description, "dimensions": $dimensions, "name": $name, "package_code": $package_code, "package_id": $body_package_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Scheduled Pickups
#
# GET /v1/pickups
# operationId: list_scheduled_pickups
export def "pickups list-scheduled" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-id: string # Carrier ID (e.g. se-28529731)
  --warehouse-id: string # Warehouse ID (e.g. se-28529731)
  --created-at-start: string # Only return scheduled pickups that were created on or after a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Only return scheduled pickups that were created on or before a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
]: nothing -> record<links: record<first: record, last: record, next: record<href: record, type: string>, prev: record<href: record, type: string>>, page: int, pages: int, pickups: table<cancelled_at: record, carrier_id: record, confirmation_number: string, contact_details: record, created_at: record, label_ids: list, pickup_address: record, pickup_id: record, pickup_notes: string, pickup_window: record, pickup_windows: list, warehouse_id: record>, total: int, errors: table<error_code: record, error_source: record, error_type: record, message: string>, request_id: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_id" $carrier_id "scalar") (serialize-qp "warehouse_id" $warehouse_id "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/pickups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"carrier_id": $carrier_id, "warehouse_id": $warehouse_id, "created_at_start": $created_at_start, "created_at_end": $created_at_end, "page": $page, "page_size": $page_size} | compact), body: null}
}

# Schedule a Pickup
#
# POST /v1/pickups
# operationId: schedule_pickup
# --contact_details shape: {email: any, name: string, phone: string}
# --pickup_window shape: {end_at: any, start_at: any}
# --pickup_windows item shape: {end_at?: any, start_at?: any}
export def "pickups create-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  contact_details: record # shape: {email: any, name: string, phone: string}
  label_ids: list # Label IDs that will be included in the pickup request
  --pickup-notes: string # Used by some carriers to give special instructions for a package pickup
  pickup_window: record # The desired time range for the package pickup. — shape: {end_at: any, start_at: any}
]: any -> record<cancelled_at: record, carrier_id: record, confirmation_number: string, contact_details: record<email: record, name: string, phone: string>, created_at: record, label_ids: list<record>, pickup_address: record, pickup_id: record, pickup_notes: string, pickup_window: record<end_at: record, start_at: record>, pickup_windows: table<end_at: record, start_at: record>, warehouse_id: record, errors: table<error_code: record, error_source: record, error_type: record, message: string>, request_id: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/pickups")
  let req_body = {"contact_details": $contact_details, "label_ids": $label_ids, "pickup_notes": $pickup_notes, "pickup_window": $pickup_window} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Scheduled Pickup
#
# DELETE /v1/pickups/{pickup_id}
# operationId: delete_scheduled_pickup
export def "pickups delete-scheduled" [
  pickup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<error_code: record, error_source: record, error_type: record, message: string>, request_id: record, pickup_id: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($pickup_id | is-empty) { error make --unspanned { msg: "path parameter 'pickup_id' must be non-empty" } }
  let full_url = (build-url $base ({pickup_id: (encode-path-segment $pickup_id)} | format pattern "/v1/pickups/{pickup_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Pickup By ID
#
# GET /v1/pickups/{pickup_id}
# operationId: get_pickup_by_id
export def "pickups get" [
  pickup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<error_code: record, error_source: record, error_type: record, message: string>, request_id: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($pickup_id | is-empty) { error make --unspanned { msg: "path parameter 'pickup_id' must be non-empty" } }
  let full_url = (build-url $base ({pickup_id: (encode-path-segment $pickup_id)} | format pattern "/v1/pickups/{pickup_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Shipping Rates
#
# POST /v1/rates
# operationId: calculate_rates
export def "rates create-calculate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rate-options: any # The rate options
  shipment_id: any # A string that uniquely identifies the shipment
  shipment: any # The shipment object
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rates")
  let req_body = {"rate_options": $rate_options, "shipment_id": $shipment_id, "shipment": $shipment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Bulk Rates
#
# POST /v1/rates/bulk
# operationId: compare_bulk_rates
export def "rates-bulk create-compare" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rate_options: any # The rate options
  --shipment-ids: list # The array of shipment IDs
  --shipments: list # The array of shipments to get bulk rate estimates for
]: any -> table<created_at: string, errors: list<record>, rate_request_id: record, shipment_id: record, status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rates/bulk")
  let req_body = {"rate_options": $rate_options, "shipment_ids": $shipment_ids, "shipments": $shipments} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Estimate Rates
#
# POST /v1/rates/estimate
# operationId: estimate_rates
@deprecated --flag carrier-id
export def "rates-estimate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-residential-indicator: any
  --confirmation: any
  --dimensions: any # The dimensions of the package
  from_city_locality: string # from postal code (e.g. Austin)
  from_country_code: any
  from_postal_code: any
  from_state_province: string # From state province (e.g. Austin)
  ship_date: string # ship date
  to_city_locality: string # The city locality the package is being shipped to (e.g. Austin)
  to_country_code: any
  to_postal_code: any
  to_state_province: string # To state province (e.g. Houston)
  weight: any # The weight of the package
  --carrier-id: any # A string that uniquely identifies the carrier (DEPRECATED)
  --carrier-ids: list<string> # Array of Carrier Ids
]: any -> table<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: record, carrier_nickname: string, confirmation_amount: record<amount: float, currency: record>, delivery_days: int, error_messages: list<string>, estimated_delivery_date: record, guaranteed_service: bool, insurance_amount: record<amount: float, currency: record>, negotiated_rate: bool, other_amount: record<amount: float, currency: record>, package_type: string, rate_type: record, service_code: string, service_type: string, ship_date: string, shipping_amount: record<amount: float, currency: record>, tax_amount: record<amount: float, currency: record>, trackable: bool, validation_status: record, warning_messages: list<string>, zone: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rates/estimate")
  let req_body = {"address_residential_indicator": $address_residential_indicator, "confirmation": $confirmation, "dimensions": $dimensions, "from_city_locality": $from_city_locality, "from_country_code": $from_country_code, "from_postal_code": $from_postal_code, "from_state_province": $from_state_province, "ship_date": $ship_date, "to_city_locality": $to_city_locality, "to_country_code": $to_country_code, "to_postal_code": $to_postal_code, "to_state_province": $to_state_province, "weight": $weight, "carrier_id": $carrier_id, "carrier_ids": $carrier_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Rate By ID
#
# GET /v1/rates/{rate_id}
# operationId: get_rate_by_id
export def "rates get" [
  rate_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($rate_id | is-empty) { error make --unspanned { msg: "path parameter 'rate_id' must be non-empty" } }
  let full_url = (build-url $base ({rate_id: (encode-path-segment $rate_id)} | format pattern "/v1/rates/{rate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Service Points
#
# POST /v1/service_points/list
# operationId: service_points_list
# --address shape: {address_line1?: string, address_line2?: string, address_line3?: string, city_locality?: string, country_code: string, postal_code?: string, state_province?: string}
# --providers item shape: {carrier_id?: string, service_code?: list<string>}
export def "service-points-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # Structured address to search by. — shape: {address_line1?: string, address_line2?: string, address_line3?: string, city_locality?: string, country_code: string, postal_code?: string, state_province?: string}
  --address-query: string # Unstructured text to search for service points by. (e.g. 177A Bleecker Street New York)
  --lat: float # The latitude of the point. Represented as signed degrees. Required if long is provided. http://www.geomidpoint.com/latlon.html (format: double, e.g. 48.874518928233094)
  --long: float # The longitude of the point. Represented as signed degrees. Required if lat is provided. http://www.geomidpoint.com/latlon.html (format: double, e.g. 2.3591775711639404)
  --max-results: int # The maximum number of service points to return (format: int32, e.g. 25)
  --providers: list # An array of shipping service providers and service codes — item shape: {carrier_id?: string, service_code?: list<string>}
  --radius: int # Search radius in kilometers (format: int32, e.g. 500)
]: any -> record<errors: table<error_code: record, error_source: record, error_type: record, message: string>, lat: float, long: float, service_points: table<address_line1: string, carrier_code: string, city_locality: string, company_name: string, country_code: string, distance_in_meters: float, features: list, hours_of_operation: record, lat: float, long: float, phone_number: string, postal_code: string, service_codes: list, service_point_id: string, state_province: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/service_points/list")
  let req_body = {"address": $address, "address_query": $address_query, "lat": $lat, "long": $long, "max_results": $max_results, "providers": $providers, "radius": $radius} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Service Point By ID
#
# GET /v1/service_points/{carrier_code}/{country_code}/{service_point_id}
# operationId: service_points_get_by_id
export def "service-points get" [
  carrier_code: string
  country_code: string
  service_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<service_point: record<address_line1: string, carrier_code: string, city_locality: string, company_name: string, country_code: string, features: list<string>, hours_of_operation: record<friday: list, monday: list, saturday: list, sunday: list, thursday: list, tuesday: list, wednesday: list>, lat: float, long: float, phone_number: string, postal_code: string, service_codes: list<string>, service_point_id: string, state_province: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_code | is-empty) { error make --unspanned { msg: "path parameter 'carrier_code' must be non-empty" } }
  if ($country_code | is-empty) { error make --unspanned { msg: "path parameter 'country_code' must be non-empty" } }
  if ($service_point_id | is-empty) { error make --unspanned { msg: "path parameter 'service_point_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_code: (encode-path-segment $carrier_code), country_code: (encode-path-segment $country_code), service_point_id: (encode-path-segment $service_point_id)} | format pattern "/v1/service_points/{carrier_code}/{country_code}/{service_point_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Shipments
#
# GET /v1/shipments
# operationId: list_shipments
export def "shipments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shipment-status: string@shipment-status-completer
  --batch-id: string # Batch ID (e.g. se-28529731)
  --tag: string # Search for shipments based on the custom tag added to the shipment object (e.g. Letters_to_santa)
  --created-at-start: string # Used to create a filter for when a resource was created (ex. A shipment that was created after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Used to create a filter for when a resource was created, (ex. A shipment that was created before a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --modified-at-start: string # Used to create a filter for when a resource was modified (ex. A shipment that was modified after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --modified-at-end: string # Used to create a filter for when a resource was modified (ex. A shipment that was modified before a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned. (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --sales-order-id: string # Sales Order ID
  --sort-dir: string # Controls the sort order of the query. (default: desc)
  --sort-by: string@sort-by-completer-1 # e.g. modified_at
]: nothing -> record<links: record<first: record, last: record, next: record<href: record, type: string>, prev: record<href: record, type: string>>, page: int, pages: int, shipments: list<record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shipment_status" $shipment_status "scalar") (serialize-qp "batch_id" $batch_id "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "modified_at_start" $modified_at_start "scalar") (serialize-qp "modified_at_end" $modified_at_end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sales_order_id" $sales_order_id "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/shipments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"shipment_status": $shipment_status, "batch_id": $batch_id, "tag": $tag, "created_at_start": $created_at_start, "created_at_end": $created_at_end, "modified_at_start": $modified_at_start, "modified_at_end": $modified_at_end, "page": $page, "page_size": $page_size, "sales_order_id": $sales_order_id, "sort_dir": $sort_dir, "sort_by": $sort_by} | compact), body: null}
}

# Create Shipments
#
# POST /v1/shipments
# operationId: create_shipments
export def "shipments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  shipments: list # An array of shipments to be created.
]: any -> record<has_errors: bool, shipments: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/shipments")
  let req_body = {"shipments": $shipments} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Shipment By External ID
#
# GET /v1/shipments/external_shipment_id/{external_shipment_id}
# operationId: get_shipment_by_external_id
export def "shipments-external-shipment-id get" [
  external_shipment_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($external_shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'external_shipment_id' must be non-empty" } }
  let full_url = (build-url $base ({external_shipment_id: (encode-path-segment $external_shipment_id)} | format pattern "/v1/shipments/external_shipment_id/{external_shipment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Parse shipping info
#
# PUT /v1/shipments/recognize
# operationId: parse_shipment
export def "shipments-recognize update-parse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shipment: any # You can optionally provide a `shipment` object containing any already-known values. For example, you probably already know the `ship_from` address, and you may also already know what carrier and service you want to use.
  text: string # The unstructured text that contains shipping-related entities (e.g. I have a 4oz package that's 5x10x14in, and I need to ship it to Margie McMiller at 3800 North Lamar suite 200 in austin, tx 78652. Please send it via USPS first class and require an adult signature. It also needs to be insured for $400. )
]: any -> record<entities: table<end_index: int, result: record, score: float, start_index: int, text: string, type: string>, score: float, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: record, bill_to_party: record, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: record, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: record, confirmation: record, created_at: record, customs: record<contents: record, customs_items: list, non_delivery: record>, external_order_id: string, external_shipment_id: string, insurance_provider: record, items: list<record>, modified_at: record, order_source_code: record, origin_type: record, packages: list<record>, return_to: record, service_code: record, ship_date: record, ship_from: record, ship_to: record, shipment_id: record, shipment_number: string, shipment_status: record, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: record, value: float>, warehouse_id: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/shipments/recognize")
  let req_body = {"shipment": $shipment, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Shipment By ID
#
# GET /v1/shipments/{shipment_id}
# operationId: get_shipment_by_id
export def "shipments get" [
  shipment_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/v1/shipments/{shipment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Shipment By ID
#
# PUT /v1/shipments/{shipment_id}
# operationId: update_shipment
# --items item shape: {asin?: string, external_order_id?: string, external_order_item_id?: string, name?: string, order_source_code?: any, quantity?: int, sales_order_id?: string, sales_order_item_id?: string, sku?: string}
# --packages item shape: {content_description?: string, dimensions?: any, external_package_id?: string, insured_value?: any, label_messages?: any, package_code?: any, package_id?: any, weight: any}
# --tags item shape: {name: string}
# --tax_identifiers item shape: {identifier_type: any, issuing_authority: string, taxable_entity_type: any, value: string}
export def "shipments update" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --advanced-options: any # Advanced shipment options. These are entirely optional.
  --carrier-id: any # The carrier account that is billed for the shipping charges
  --confirmation: any # The type of delivery confirmation that is required for this shipment. (default: none)
  --customs: any # Customs information. This is usually only needed for international shipments. (nullable)
  --external-order-id: string # ID that the Order Source assigned (nullable)
  --external-shipment-id: string # A unique user-defined key to identify a shipment. This can be used to retrieve the shipment. > **Warning:** The `external_shipment_id` is limited to 50 characters. Any additional characters will be truncated. (nullable)
  --insurance-provider: any # The insurance provider to use for any insured packages in the shipment. (default: none)
  --items: list # Describe the packages included in this shipment as related to potential metadata that was imported from external order sources (default: []) — item shape: {asin?: string, external_order_id?: string, external_order_item_id?: string, name?: string, order_source_code?: any, quantity?: int, sales_order_id?: string, sales_order_item_id?: string, sku?: string}
  --order-source-code: any
  --origin-type: any # Indicates if the package will be picked up or dropped off by the carrier (nullable)
  --packages: list # The packages in the shipment. > **Note:** Some carriers only allow one package per shipment. If you attempt to create a multi-package shipment for a carrier that doesn't allow it, an error will be returned. — item shape: {content_description?: string, dimensions?: any, external_package_id?: string, insured_value?: any, label_messages?: any, package_code?: any, package_id?: any, weight: any}
  --return-to: any # The return address for this shipment. Defaults to the `ship_from` address.
  --service-code: any # The [carrier service](https://www.shipengine.com/docs/shipping/use-a-carrier-service/) used to ship the package, such as `fedex_ground`, `usps_first_class_mail`, `flat_rate_envelope`, etc.
  --ship-date: any # The date that the shipment was (or will be) shippped. ShipEngine will take the day of week into consideration. For example, if the carrier does not operate on Sundays, then a package that would have shipped on Sunday will ship on Monday instead.
  ship_from: any # The shipment's origin address. If you frequently ship from the same location, consider [creating a warehouse](https://www.shipengine.com/docs/reference/create-warehouse/). Then you can simply specify the `warehouse_id` rather than the complete address each time.
  ship_to: any # The recipient's mailing address
  --shipment-number: string # A non-unique user-defined number used to identify a shipment. If undefined, this will match the external_shipment_id of the shipment. > **Warning:** The `shipment_number` is limited to 50 characters. Any additional characters will be truncated. (nullable)
  --tax-identifiers: list # nullable — item shape: {identifier_type: any, issuing_authority: string, taxable_entity_type: any, value: string}
  --warehouse-id: any # The [warehouse](https://www.shipengine.com/docs/shipping/ship-from-a-warehouse/) that the shipment is being shipped from. Either `warehouse_id` or `ship_from` must be specified. (nullable)
  --validate-address: any # default: no_validation
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/v1/shipments/{shipment_id}"))
  let req_body = {"advanced_options": $advanced_options, "carrier_id": $carrier_id, "confirmation": $confirmation, "customs": $customs, "external_order_id": $external_order_id, "external_shipment_id": $external_shipment_id, "insurance_provider": $insurance_provider, "items": $items, "order_source_code": $order_source_code, "origin_type": $origin_type, "packages": $packages, "return_to": $return_to, "service_code": $service_code, "ship_date": $ship_date, "ship_from": $ship_from, "ship_to": $ship_to, "shipment_number": $shipment_number, "tax_identifiers": $tax_identifiers, "warehouse_id": $warehouse_id, "validate_address": $validate_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Cancel a Shipment
#
# PUT /v1/shipments/{shipment_id}/cancel
# operationId: cancel_shipments
export def "shipments-cancel cancel" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/v1/shipments/{shipment_id}/cancel"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Shipment Rates
#
# GET /v1/shipments/{shipment_id}/rates
# operationId: list_shipment_rates
export def "shipments-rates list" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at-start: string # Used to create a filter for when a resource was created (ex. A shipment that was created after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  let qp = [(serialize-qp "created_at_start" $created_at_start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/v1/shipments/{shipment_id}/rates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"created_at_start": $created_at_start} | compact), body: null}
}

# Remove Tag from Shipment
#
# DELETE /v1/shipments/{shipment_id}/tags/{tag_name}
# operationId: untag_shipment
export def "shipments-tags untag" [
  shipment_id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag_name' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id), tag_name: (encode-path-segment $tag_name)} | format pattern "/v1/shipments/{shipment_id}/tags/{tag_name}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add Tag to Shipment
#
# POST /v1/shipments/{shipment_id}/tags/{tag_name}
# operationId: tag_shipment
export def "shipments-tags tag" [
  shipment_id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<shipment_id: record, tag: record<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag_name' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id), tag_name: (encode-path-segment $tag_name)} | format pattern "/v1/shipments/{shipment_id}/tags/{tag_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Tags
#
# GET /v1/tags
# operationId: list_tags
export def "tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tags: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete Tag
#
# DELETE /v1/tags/{tag_name}
# operationId: delete_tag
export def "tags delete" [
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag_name' must be non-empty" } }
  let full_url = (build-url $base ({tag_name: (encode-path-segment $tag_name)} | format pattern "/v1/tags/{tag_name}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a New Tag
#
# POST /v1/tags/{tag_name}
# operationId: create_tag
export def "tags create" [
  tag_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag_name' must be non-empty" } }
  let full_url = (build-url $base ({tag_name: (encode-path-segment $tag_name)} | format pattern "/v1/tags/{tag_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Tag Name
#
# PUT /v1/tags/{tag_name}/{new_tag_name}
# operationId: rename_tag
export def "tags rename" [
  tag_name: string
  new_tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag_name' must be non-empty" } }
  if ($new_tag_name | is-empty) { error make --unspanned { msg: "path parameter 'new_tag_name' must be non-empty" } }
  let full_url = (build-url $base ({tag_name: (encode-path-segment $tag_name), new_tag_name: (encode-path-segment $new_tag_name)} | format pattern "/v1/tags/{tag_name}/{new_tag_name}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Ephemeral Token
#
# POST /v1/tokens/ephemeral
# operationId: tokens_get_ephemeral_token
export def "tokens-ephemeral get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirect: string@redirect-completer # Include a redirect url to the application formatted with the ephemeral token.
]: nothing -> record<redirect_url: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirect" $redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tokens/ephemeral" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"redirect": $redirect} | compact), body: null}
}

# Get Tracking Information
#
# GET /v1/tracking
# operationId: get_tracking_log
export def "tracking get-log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-code: string # Carrier code used to retrieve tracking information (e.g. stamps_com)
  --tracking-number: string # The tracking number associated with a shipment (e.g. 9405511899223197428490)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_code" $carrier_code "scalar") (serialize-qp "tracking_number" $tracking_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tracking" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"carrier_code": $carrier_code, "tracking_number": $tracking_number} | compact), body: null}
}

# Start Tracking a Package
#
# POST /v1/tracking/start
# operationId: start_tracking
export def "tracking-start start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --carrier-code: string # Carrier code used to retrieve tracking information (e.g. stamps_com)
  --tracking-number: string # The tracking number associated with a shipment (e.g. 9405511899223197428490)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_code" $carrier_code "scalar") (serialize-qp "tracking_number" $tracking_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tracking/start" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"carrier_code": $carrier_code, "tracking_number": $tracking_number} | compact), body: null}
}

# Stop Tracking a Package
#
# POST /v1/tracking/stop
# operationId: stop_tracking
export def "tracking-stop stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --carrier-code: string # Carrier code used to retrieve tracking information (e.g. stamps_com)
  --tracking-number: string # The tracking number associated with a shipment (e.g. 9405511899223197428490)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_code" $carrier_code "scalar") (serialize-qp "tracking_number" $tracking_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tracking/stop" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"carrier_code": $carrier_code, "tracking_number": $tracking_number} | compact), body: null}
}

# List Warehouses
#
# GET /v1/warehouses
# operationId: list_warehouses
export def "warehouses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<warehouses: table<created_at: string, is_default: bool, name: string, origin_address: record, return_address: record, warehouse_id: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/warehouses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Warehouse
#
# POST /v1/warehouses
# operationId: create_warehouse
export def "warehouses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-default: oneof<nothing, bool> # Designates which single warehouse is the default on the account (nullable, default: false)
  name: string # Name of the warehouse (e.g. Zero Cool HQ)
  origin_address: any # The origin address of the warehouse
  --return-address: any # The return address associated with the warehouse
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/warehouses")
  let req_body = {"is_default": $is_default, "name": $name, "origin_address": $origin_address, "return_address": $return_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Warehouse By ID
#
# DELETE /v1/warehouses/{warehouse_id}
# operationId: delete_warehouse
export def "warehouses delete" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouse_id' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/v1/warehouses/{warehouse_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Warehouse By Id
#
# GET /v1/warehouses/{warehouse_id}
# operationId: get_warehouse_by_id
export def "warehouses get" [
  warehouse_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouse_id' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/v1/warehouses/{warehouse_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Warehouse By Id
#
# PUT /v1/warehouses/{warehouse_id}
# operationId: update_warehouse
export def "warehouses update" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-default: oneof<nothing, bool> # Designates which single warehouse is the default on the account (nullable, default: false)
  name: string # Name of the warehouse (e.g. Zero Cool HQ)
  origin_address: any # The origin address of the warehouse
  --return-address: any # The return address associated with the warehouse
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouse_id' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/v1/warehouses/{warehouse_id}"))
  let req_body = {"is_default": $is_default, "name": $name, "origin_address": $origin_address, "return_address": $return_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Warehouse Settings
#
# PUT /v1/warehouses/{warehouse_id}/settings
# operationId: update_warehouse_settings
export def "warehouses-settings update" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-default: oneof<nothing, bool> # The default property on the warehouse. (nullable, e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouse_id' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/v1/warehouses/{warehouse_id}/settings"))
  let req_body = {"is_default": $is_default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
