# Auto-generated client for ShipEngine API v1.1.202604070904
# Source: https://raw.githubusercontent.com/ShipEngine/shipengine-openapi/master/openapi.yaml
# Auth: --token flag or $env.SHIPENGINE_API_TOKEN

const BASE_URL = "https://api.shipengine.com"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SHIPENGINE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-key" => { {headers: {API-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.shipengine.com"] }
def auth-scheme-completer [] { ["api-key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/plain"] }
def status-completer [] { ["archived" "completed" "completed_with_errors" "invalid" "notifying" "open" "processing" "queued"] }
def sort-by-completer [] { ["created_at" "processed_at" "ship_date"] }
def label-format-completer [] { ["pdf"] }
def accept-completer-1 [] { ["application/pdf" "application/zpl" "image/png"] }
def label-status-completer [] { ["completed" "error" "processing" "voided"] }
def sort-by-completer-1 [] { ["created_at" "modified_at" "voided_at"] }
def label-download-type-completer [] { ["inline" "url"] }
def shipment-status-completer [] { ["cancelled" "label_purchased" "pending" "processing"] }
def sort-by-completer-2 [] { ["created_at" "modified_at"] }
def redirect-completer [] { ["shipengine-dashboard"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-settings settings" } } | get name | first)
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

# List Account Settings
#
# GET /v1/account/settings
# operationId: list_account_settings
export def "account-settings settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Account Images
#
# GET /v1/account/settings/images
# operationId: list_account_images
export def "account-settings-images images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<images: table<label_image_id: record, name: string, is_default: bool, image_content_type: record, image_data: string, created_at: record, modified_at: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/settings/images")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Account Image
#
# POST /v1/account/settings/images
# operationId: create_account_image
export def "account-settings-images image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A human readable name for the image.  (e.g. My logo)
  --is-default: oneof<nothing, bool> # Indicates whether this image is set as default.  (e.g. false)
  image_content_type: any # The file type of the image.
  image_data: string # A base64 encoded string representation of the image.  (e.g. iVBORw0KGgoAAAANSUhEUgAAABkAAAAZCAYAAADE6YVjAAAAAXNSR0IArs4c6QAAAiVJREFUSEu91j3IeVEcB/CvSTIoBrFSikEZMdjsjExeUspgUEp5SUpeshrIgEFJJmWwMZHJQGHDhJSXTPfpnH/8ebzd56HnN93u7ZzP/f1+55x7Ob1ejxEKheByufh0HI9HrFYrcKbTKUMu5HI5BALBx5zNZoPxeAySAGc2mzF8Pp/e+BR0Ash8u93uHyKVSnH54J2Mvs8zn8//I6RO70L3xt8g70CPXvAu8hvoWQUeIj+BXpX4KcIGegWQOV4izyA2AGvkHsQW+BFyCUkkEiwWC9Ybl1W5Ls8ZMoAABCIbmE3cINFoFMFgEEajEeVyGSKRCJ1OB3q9ns5nMpmQTCaxXq9/l8loNEKj0YDX66UACYvFQq9brRYcDgdUKhU9RD/SEwLm83lEIhGUSiX0+33E4/GrU5otRMs1mUyYbDYLu90OhUJBMzhlZbPZ4Pf7odFo4HQ6b1rABqJIvV5nttstLc0pSIn2+z0tTy6XQ6FQoI/a7TZ0Ot0V9gqiiMFgYKrVKm0yieVyCZ/PB6vVSpF0Ok2zJHEqIY/HYw1RxOfzMYlE4jwoEAhAJpPBbDZf9eBwOCCVSsHtdp9f6FJ6egorlUqmVqvRfjSbTXS7XXg8nptP8Svk0RF01ROtVguSUTgchlgsPpeOZBaLxTAcDlEsFpHJZPC9XM8yoshgMGBCoRBdQWTCU7hcLjohWb5kM6rValQqlfMKfLbbb77xf/K38hf/XV9ilOpnLqvnogAAAABJRU5ErkJggg==)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/settings/images")
  let body = {name: $name, is_default: $is_default, image_content_type: $image_content_type, image_data: $image_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Account Image By ID
#
# GET /v1/account/settings/images/{label_image_id}
# operationId: get_account_settings_images_by_id
export def "account-settings-images id-by-label_image_id" [
  label_image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/account/settings/images/($label_image_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Account Image By ID
#
# PUT /v1/account/settings/images/{label_image_id}
# operationId: update_account_settings_images_by_id
export def "account-settings-images id-by-label_image_id-1" [
  label_image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A human readable name for the image.  (e.g. My logo)
  --is-default: oneof<nothing, bool> # Indicates whether this image is set as default.  (e.g. false)
  --image-content-type: any # The file type of the image.
  --image-data: string # A base64 encoded string representation of the image.  (e.g. iVBORw0KGgoAAAANSUhEUgAAABkAAAAZCAYAAADE6YVjAAAAAXNSR0IArs4c6QAAAiVJREFUSEu91j3IeVEcB/CvSTIoBrFSikEZMdjsjExeUspgUEp5SUpeshrIgEFJJmWwMZHJQGHDhJSXTPfpnH/8ebzd56HnN93u7ZzP/f1+55x7Ob1ejxEKheByufh0HI9HrFYrcKbTKUMu5HI5BALBx5zNZoPxeAySAGc2mzF8Pp/e+BR0Ash8u93uHyKVSnH54J2Mvs8zn8//I6RO70L3xt8g70CPXvAu8hvoWQUeIj+BXpX4KcIGegWQOV4izyA2AGvkHsQW+BFyCUkkEiwWC9Ybl1W5Ls8ZMoAABCIbmE3cINFoFMFgEEajEeVyGSKRCJ1OB3q9ns5nMpmQTCaxXq9/l8loNEKj0YDX66UACYvFQq9brRYcDgdUKhU9RD/SEwLm83lEIhGUSiX0+33E4/GrU5otRMs1mUyYbDYLu90OhUJBMzhlZbPZ4Pf7odFo4HQ6b1rABqJIvV5nttstLc0pSIn2+z0tTy6XQ6FQoI/a7TZ0Ot0V9gqiiMFgYKrVKm0yieVyCZ/PB6vVSpF0Ok2zJHEqIY/HYw1RxOfzMYlE4jwoEAhAJpPBbDZf9eBwOCCVSsHtdp9f6FJ6egorlUqmVqvRfjSbTXS7XXg8nptP8Svk0RF01ROtVguSUTgchlgsPpeOZBaLxTAcDlEsFpHJZPC9XM8yoshgMGBCoRBdQWTCU7hcLjohWb5kM6rValQqlfMKfLbbb77xf/K38hf/XV9ilOpnLqvnogAAAABJRU5ErkJggg==)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/account/settings/images/($label_image_id)")
  let body = {name: $name, is_default: $is_default, image_content_type: $image_content_type, image_data: $image_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Account Image By Id
#
# DELETE /v1/account/settings/images/{label_image_id}
# operationId: delete_account_image_by_id
export def "account-settings-images id-by-label_image_id-2" [
  label_image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/account/settings/images/($label_image_id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Parse an address
#
# PUT /v1/addresses/recognize
# operationId: parse_address
export def "addresses-recognize address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # The unstructured text that contains address-related entities (e.g. Margie McMiller at 3800 North Lamar suite 200 in austin, tx.  The zip code there is 78652.)
  --address: any # You can optionally provide any already-known address values. For example, you may already know the recipient's name, city, and country, and only want to parse the street address into separate lines.
]: any -> record<score: float, address: record<name: string, phone: string, email: string, company_name: string, address_line1: string, address_line2: string, address_line3: string, city_locality: string, state_province: string, postal_code: record, country_code: record, address_residential_indicator: record>, entities: table<type: string, score: float, text: string, start_index: int, end_index: int, result: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/addresses/recognize")
  let body = {text: $text, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validate An Address
#
# POST /v1/addresses/validate
# operationId: validate_address
export def "addresses-validate address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<status: record, original_address: record, matched_address: record, messages: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/addresses/validate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Batches
#
# GET /v1/batches
# operationId: list_batches
export def "batches batches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned.  (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --sort-dir: string # Controls the sort order of the query. (default: desc)
  --batch-number: string # Batch Number
  --created-at-start: string # Only return batches that were created on or after a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Only return batches that were created on or before a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --processed-at-start: string # Only return batches that were processed on or after a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --processed-at-end: string # Only return batches that were processed on or before a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --sort-by: string@sort-by-completer
]: nothing -> record<batches: table<label_layout: record, label_format: record, batch_id: record, batch_number: string, external_batch_id: string, batch_notes: string, created_at: record, processed_at: record, errors: int, process_errors: list, warnings: int, completed: int, forms: int, count: int, batch_shipments_url: record, batch_labels_url: record, batch_errors_url: record, label_download: record, form_download: record, paperless_download: record, status: record>, total: int, page: int, pages: int, links: record<first: record, last: record, prev: record<href: record, type: string>, next: record<href: record, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "batch_number" $batch_number "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "processed_at_start" $processed_at_start "scalar") (serialize-qp "processed_at_end" $processed_at_end "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/batches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create A Batch
#
# POST /v1/batches
# operationId: create_batch
# --process_labels shape: {create_batch_and_process_labels?: bool, ship_date?: any, label_layout?: string, label_format?: any, display_scheme?: any}
export def "batches batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-batch-id: any # A string that uniquely identifies the external batch
  --batch-notes: string # Add custom messages for a particular batch (e.g. This is my batch)
  --shipment-ids: list # Array of shipment IDs used in the batch
  --rate-ids: list # Array of rate IDs used in the batch
  --process-labels: record # The information used to process the batch — shape: {create_batch_and_process_labels?: bool, ship_date?: any, label_layout?: string, label_format?: any, display_scheme?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batches")
  let body = {external_batch_id: $external_batch_id, batch_notes: $batch_notes, shipment_ids: $shipment_ids, rate_ids: $rate_ids, process_labels: $process_labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Batch By External ID
#
# GET /v1/batches/external_batch_id/{external_batch_id}
# operationId: get_batch_by_external_id
export def "batches-external-batch-id id" [
  external_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batches/external_batch_id/($external_batch_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Batch By Id
#
# DELETE /v1/batches/{batch_id}
# operationId: delete_batch
export def "batches batch-by-batch_id" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batches/($batch_id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Batch By ID
#
# GET /v1/batches/{batch_id}
# operationId: get_batch_by_id
export def "batches id" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batches/($batch_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Batch By Id
#
# PUT /v1/batches/{batch_id}
# operationId: update_batch
export def "batches batch-by-batch_id-1" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batches/($batch_id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to a Batch
#
# POST /v1/batches/{batch_id}/add
# operationId: add_to_batch
export def "batches-add batch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --shipment-ids: list # The Shipment Ids to be modified on the batch
  --rate-ids: list # Array of Rate IDs to be modifed on the batch
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batches/($batch_id)/add")
  let body = {shipment_ids: $shipment_ids, rate_ids: $rate_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Batch Errors
#
# GET /v1/batches/{batch_id}/errors
# operationId: list_batch_errors
export def "batches-errors errors" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned.  (format: int32, default: 1, e.g. 2)
  --pagesize: int # format: int32
]: nothing -> record<errors: table<error: string, shipment_id: record, external_shipment_id: string>, links: record<first: record, last: record, prev: record<href: record, type: string>, next: record<href: record, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/batches/($batch_id)/errors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Process Batch ID Labels
#
# POST /v1/batches/{batch_id}/process/labels
# operationId: process_batch
export def "batches-process-labels batch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ship-date: any # The Ship date the batch is being processed for
  --label-layout: string # default: 4x6
  --label-format: any # default: pdf
  --display-scheme: any # The display format that the label should be shown in. (default: label)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batches/($batch_id)/process/labels")
  let body = {ship_date: $ship_date, label_layout: $label_layout, label_format: $label_format, display_scheme: $display_scheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove From Batch
#
# POST /v1/batches/{batch_id}/remove
# operationId: remove_from_batch
export def "batches-remove batch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --shipment-ids: list # The Shipment Ids to be modified on the batch
  --rate-ids: list # Array of Rate IDs to be modifed on the batch
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batches/($batch_id)/remove")
  let body = {shipment_ids: $shipment_ids, rate_ids: $rate_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Carriers
#
# GET /v1/carriers
# operationId: list_carriers
export def "carriers carriers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<carriers: table<carrier_id: record, carrier_code: record, account_number: string, requires_funded_amount: bool, balance: float, nickname: string, friendly_name: string, funding_source_id: record, primary: bool, has_multi_package_supporting_services: bool, allows_returns: bool, supports_label_messages: bool, disabled_by_billing_plan: bool, services: list, packages: list, options: list, send_rates: bool, supports_user_managed_rates: bool, connection_status: string>, request_id: record, errors: table<error_source: record, error_type: record, error_code: record, message: string, carrier_id: record, carrier_code: record, field_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/carriers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Carrier By ID
#
# GET /v1/carriers/{carrier_id}
# operationId: get_carrier_by_id
export def "carriers id-by-carrier_id" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/carriers/($carrier_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disconnect Carrier by ID
#
# DELETE /v1/carriers/{carrier_id}
# operationId: disconnect_carrier_by_id
export def "carriers id-by-carrier_id-1" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/carriers/($carrier_id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Funds To Carrier
#
# PUT /v1/carriers/{carrier_id}/add_funds
# operationId: add_funds_to_carrier
export def "carriers-add-funds carrier" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  currency: any
  amount: float # The monetary amount, in the specified currency.
]: any -> record<balance: record<currency: record, amount: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/carriers/($carrier_id)/add_funds")
  let body = {currency: $currency, amount: $amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Carrier Options
#
# GET /v1/carriers/{carrier_id}/options
# operationId: get_carrier_options
export def "carriers-options options" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<options: table<name: string, default_value: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/carriers/($carrier_id)/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Carrier Package Types
#
# GET /v1/carriers/{carrier_id}/packages
# operationId: list_carrier_package_types
export def "carriers-packages types" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<packages: table<package_id: record, package_code: record, name: string, dimensions: record, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/carriers/($carrier_id)/packages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Carrier Services
#
# GET /v1/carriers/{carrier_id}/services
# operationId: list_carrier_services
export def "carriers-services services" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<services: table<carrier_id: record, carrier_code: record, service_code: string, name: string, domestic: bool, international: bool, is_multi_package_supported: bool, is_return_supported: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/carriers/($carrier_id)/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Connect a carrier account
#
# POST /v1/connections/carriers/{carrier_name}
# operationId: connect_carrier
@deprecated --flag ftp-username
@deprecated --flag ftp-password
export def "connections-carriers carrier-by-carrier_name" [
  carrier_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nickname: string # The nickname associated with the carrier connection (e.g. Stamps.com)
  --username: string # Access Worldwide Username
  --password: string # Access Worldwide Password
  --merchant-seller-id: string
  --mws-auth-token: string
  --email: any
  --auth-code: string # Amazon UK Shipping auth code.
  --account-number: string # Asendia account number
  --api-key: string # Asendia api_key
  --processing-location: string # Asendia processing location, one of: 'MIA', 'JFK', 'ORD', 'PHL', 'SFO', 'LAX', 'SLC', 'TOR', 'BUF', 'CAL'
  --sub-account-number: string # Asendia sub account number
  --api-secret: string # API secret
  --contract-id: string # Canada Post Account Contract ID
  --client-id: string # The client id
  --pickup-number: string # The pickup number
  --distribution-center: string # The distribution center
  --ancillary-endorsement: any
  --ftp-username: string # FTP username (DEPRECATED)
  --ftp-password: string # FTP password (DEPRECATED)
  --sold-to: string # Sold To field
  --registration-id: string
  --software-name: string
  --site-id: string # Required if password is provided
  --country-code: any
  --account: string # Account
  --passphrase: string # Passphrase
  --address1: string # Address
  --address2: string # Address
  --city: string # The city
  --company: string # The company
  --first-name: string # First name
  --last-name: string # Last name
  --phone: string # Phone number
  --postal-code: string # Postal Code
  --state: string # State
  --agree-to-eula: oneof<nothing, bool> # Boolean signaling agreement to the Fedex End User License Agreement
  --meter-number: string # Meter number
  --mailer-id: any # A string that uniquely identifies the mailer
  --profile-name: string # Profile name
  --web-services-id: string # Web Service ID (WSID)
  --web-services-key: string # Web Service Key (WSKey)
  --customer-branch: string # Customer Branch
  --Address: any # Address
  --Address2: any # Address2
  --PostalCode: any # PostalCode
  --City: any # City
  --State: any # State
  --country: any # Country
  --Phone: any # Phone
  --Email: any # Email
  --instructions: any # Instructions
  --facility-code: any # Facility Code
  --lasership-critical-pull-time: any # Critical Pull Time (local time)
  --lasership-critical-entry-time: any # Critical Entry Time (local time)
  --declare-piece-attributes-separately-for-every-shipment: any # Declare piece attributes separately for every shipment, overrides individual attribute below. (default: false)
  --AttrAlcohol: any # Set this to true if your shipments will always contain Alcohol
  --AttrDryIce: any # Set this to true if your shipments will always contain DryIce
  --AttrHazmat: any # Set this to true if your shipments will always contain Hazmat
  --AttrTwoPersons: any # Set this to true if your shipments will always require Two Persons
  --AttrExplosive: any # Set this to true if your shipments will always contain Explosives
  --AttrControlledSubstance: any # Set this to true if your shipments will always contain Controlled Substances
  --AttrRefrigerated: any # Set this to true if your shipments will always require Refrigeration
  --AttrPerishable: any # Set this to true if your shipments will always be Perishable
  --AttrNoRTS: any # Set this to true if your shipments will always use "No Return To Sender"
  --merchant-id: int # Merchant id (format: int32)
  --induction-site: string # Induction site
  --activation-key: string # Activation key
  --oba-email: any # The oba email address
  --contact-name: string # Contact name
  --company-name: string # Company name
  --street-line1: string # Street line1
  --street-line2: string # Street line2
  --street-line3: string # Street line3
  --access-key: string # Seko Account Access Key
  --sendle-id: any # A string that uniquely identifies the sendle
  --account-postal-code: string # Account Postal Code
  --account-country-code: string # Account Country Code
]: any -> record<carrier_id: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connections/carriers/($carrier_name)")
  let body = {nickname: $nickname, username: $username, password: $password, merchant_seller_id: $merchant_seller_id, mws_auth_token: $mws_auth_token, email: $email, auth_code: $auth_code, account_number: $account_number, api_key: $api_key, processing_location: $processing_location, sub_account_number: $sub_account_number, api_secret: $api_secret, contract_id: $contract_id, client_id: $client_id, pickup_number: $pickup_number, distribution_center: $distribution_center, ancillary_endorsement: $ancillary_endorsement, ftp_username: $ftp_username, ftp_password: $ftp_password, sold_to: $sold_to, registration_id: $registration_id, software_name: $software_name, site_id: $site_id, country_code: $country_code, account: $account, passphrase: $passphrase, address1: $address1, address2: $address2, city: $city, company: $company, first_name: $first_name, last_name: $last_name, phone: $phone, postal_code: $postal_code, state: $state, agree_to_eula: $agree_to_eula, meter_number: $meter_number, mailer_id: $mailer_id, profile_name: $profile_name, web_services_id: $web_services_id, web_services_key: $web_services_key, customer_branch: $customer_branch, Address: $Address, Address2: $Address2, PostalCode: $PostalCode, City: $City, State: $State, country: $country, Phone: $Phone, Email: $Email, instructions: $instructions, facility_code: $facility_code, lasership_critical_pull_time: $lasership_critical_pull_time, lasership_critical_entry_time: $lasership_critical_entry_time, declare_piece_attributes_separately_for_every_shipment: $declare_piece_attributes_separately_for_every_shipment, AttrAlcohol: $AttrAlcohol, AttrDryIce: $AttrDryIce, AttrHazmat: $AttrHazmat, AttrTwoPersons: $AttrTwoPersons, AttrExplosive: $AttrExplosive, AttrControlledSubstance: $AttrControlledSubstance, AttrRefrigerated: $AttrRefrigerated, AttrPerishable: $AttrPerishable, AttrNoRTS: $AttrNoRTS, merchant_id: $merchant_id, induction_site: $induction_site, activation_key: $activation_key, oba_email: $oba_email, contact_name: $contact_name, company_name: $company_name, street_line1: $street_line1, street_line2: $street_line2, street_line3: $street_line3, access_key: $access_key, sendle_id: $sendle_id, account_postal_code: $account_postal_code, account_country_code: $account_country_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disconnect a carrier
#
# DELETE /v1/connections/carriers/{carrier_name}/{carrier_id}
# operationId: disconnect_carrier
export def "connections-carriers carrier-by-carrier_name-carrier_id" [
  carrier_name: string
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connections/carriers/($carrier_name)/($carrier_id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get carrier settings
#
# GET /v1/connections/carriers/{carrier_name}/{carrier_id}/settings
# operationId: get_carrier_settings
export def "connections-carriers-settings settings-by-carrier_name-carrier_id" [
  carrier_name: string
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connections/carriers/($carrier_name)/($carrier_id)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update carrier settings
#
# PUT /v1/connections/carriers/{carrier_name}/{carrier_id}/settings
# operationId: update_carrier_settings
export def "connections-carriers-settings settings-by-carrier_name-carrier_id-1" [
  carrier_name: string
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-barcode-with-order-number: oneof<nothing, bool>
  --receive-email-on-manifest-processing: oneof<nothing, bool>
  --email: string # Email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connections/carriers/($carrier_name)/($carrier_id)/settings")
  let body = {include_barcode_with_order_number: $include_barcode_with_order_number, receive_email_on_manifest_processing: $receive_email_on_manifest_processing, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disconnect a Shipsurance Account
#
# DELETE /v1/connections/insurance/shipsurance
# operationId: disconnect_insurer
export def "connections-insurance-shipsurance insurer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/insurance/shipsurance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Connect a Shipsurance Account
#
# POST /v1/connections/insurance/shipsurance
# operationId: connect_insurer
export def "connections-insurance-shipsurance insurer-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: any
  policy_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/insurance/shipsurance")
  let body = {email: $email, policy_id: $policy_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Created Combined Label Document
#
# POST /v1/documents/combined_labels
# operationId: create_combined_label_document
export def "documents-combined-labels document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-ids: list # The list of up to 30 label ids to include in the combined label document. Note that to avoid response size limits, you should only expect to be able to combine 30 single page labels similar in size to that of USPS labels.
  --label-format: string@label-format-completer # The file format for the combined label document; note that currently only `"pdf"` is supported.
  --label-download-type: any # default: inline
]: any -> record<label_download: record<href: record, pdf: record, png: record, zpl: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/documents/combined_labels")
  let body = {label_ids: $label_ids, label_format: $label_format, label_download_type: $label_download_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download File
#
# GET /v1/downloads/{dir}/{subdir}/{filename}
# operationId: download_file
export def "downloads file" [
  subdir: string
  filename: string
  dir: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --download: string
  --rotation: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "rotation" $rotation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/downloads/($dir)/($subdir)/($filename)" $qp)
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Webhooks
#
# GET /v1/environment/webhooks
# operationId: list_webhooks
export def "environment-webhooks webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<webhook_id: record, url: record, event: record, headers: list<record>, name: string, store_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environment/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Webhook
#
# POST /v1/environment/webhooks
# operationId: create_webhook
# --headers item shape: {key: string, value: string}
export def "environment-webhooks webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  event: any
  --body-url: any # The url that the webhook sends the request to (e.g. https://[YOUR ENDPOINT ID].x.requestbin.com)
  --headers: list # Array of custom webhook headers — item shape: {key: string, value: string}
  --name: string # The name of the webhook (e.g. My New Webhook)
  --store-id: int # Store ID (format: int32, e.g. 123456)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environment/webhooks")
  let body = {event: $event, url: $body_url, headers: $headers, name: $name, store_id: $store_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Webhook By ID
#
# GET /v1/environment/webhooks/{webhook_id}
# operationId: get_webhook_by_id
export def "environment-webhooks id" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environment/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Webhook
#
# PUT /v1/environment/webhooks/{webhook_id}
# operationId: update_webhook
# --headers item shape: {key: string, value: string}
export def "environment-webhooks webhook-by-webhook_id" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-url: any # The url that the wehbook sends the request (e.g. https://[YOUR ENDPOINT ID].x.requestbin.com)
  --headers: list # Array of custom webhook headers — item shape: {key: string, value: string}
  --name: string # The name of the webhook (e.g. My Updated Webhook)
  --store-id: int # Store ID (format: int32, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environment/webhooks/($webhook_id)")
  let body = {url: $body_url, headers: $headers, name: $name, store_id: $store_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Webhook By ID
#
# DELETE /v1/environment/webhooks/{webhook_id}
# operationId: delete_webhook
export def "environment-webhooks webhook-by-webhook_id-1" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environment/webhooks/($webhook_id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Funds To Insurance
#
# PATCH /v1/insurance/shipsurance/add_funds
# operationId: add_funds_to_insurance
export def "insurance-shipsurance-add-funds insurance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  currency: any
  amount: float # The monetary amount, in the specified currency.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/insurance/shipsurance/add_funds")
  let body = {currency: $currency, amount: $amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Insurance Funds Balance
#
# GET /v1/insurance/shipsurance/balance
# operationId: get_insurance_balance
export def "insurance-shipsurance-balance balance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/insurance/shipsurance/balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List labels
#
# GET /v1/labels
# operationId: list_labels
export def "labels labels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --refund-status: list # Only return labels with specific refund status/es. (e.g. pending,approved)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned.  (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --sort-dir: string # Controls the sort order of the query. (default: desc)
  --sort-by: string@sort-by-completer-1 # Controls which field the query is sorted by. (default: created_at)
]: nothing -> record<labels: table<label_id: record, status: record, shipment_id: record, external_shipment_id: string, external_order_id: string, shipment: record, ship_date: record, created_at: record, shipment_cost: record, insurance_cost: record, requested_comparison_amount: record, rate_details: list, tracking_number: string, is_return_label: bool, rma_number: string, is_international: bool, batch_id: record, carrier_id: record, charge_event: record, outbound_label_id: record, service_code: record, test_label: bool, package_code: record, validate_address: record, voided: bool, voided_at: record, label_download_type: record, label_format: record, display_scheme: record, label_layout: record, trackable: bool, label_image_id: record, carrier_code: record, tracking_status: record, confirmation: record, label_download: record, form_download: record, qr_code_download: record, paperless_download: record, insurance_claim: record, packages: list, alternative_identifiers: list, tracking_url: string, ship_to: record, void_type: record, refund_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label_status" $label_status "scalar") (serialize-qp "service_code" $service_code "scalar") (serialize-qp "carrier_id" $carrier_id "scalar") (serialize-qp "tracking_number" $tracking_number "scalar") (serialize-qp "batch_id" $batch_id "scalar") (serialize-qp "rate_id" $rate_id "scalar") (serialize-qp "shipment_id" $shipment_id "scalar") (serialize-qp "warehouse_id" $warehouse_id "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "refund_status" $refund_status "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Purchase Label
#
# POST /v1/labels
# operationId: create_label
@deprecated --flag test-label
export def "labels label" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ship-to-service-point-id: string # A unique identifier for a carrier service point where the shipment will be delivered by the carrier. This will take precedence over a shipment's ship to address. (nullable, e.g. 614940)
  --ship-from-service-point-id: string # A unique identifier for a carrier drop off point where a merchant plans to deliver packages. This will take precedence over a shipment's ship from address. (nullable, e.g. 614940)
  shipment: any # The shipment information used to generate the label
  --is-return-label: oneof<nothing, bool> # Indicates whether this is a return label.  You may also want to set the `rma_number` so you know what is being returned.
  --rma-number: string # An optional Return Merchandise Authorization number.  This field is useful for return labels.  You can set it to any string value.  (nullable)
  --charge-event: any # The label charge event.
  --outbound-label-id: any # The `label_id` of the original (outgoing) label that the return label is for. This associates the two labels together, which is required by some carriers.
  --test-label: oneof<nothing, bool> # Indicate if this label is being used only for testing purposes. If true, then no charge will be added to your account. (DEPRECATED, default: false)
  --validate-address: any # default: no_validation
  --label-download-type: any # default: url
  --label-format: any # The file format that you want the label to be in.  We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats.  (default: pdf)
  --display-scheme: any # The display format that the label should be shown in. (default: label)
  --label-layout: any # The layout (size) that you want the label to be in.  The `label_format` determines which sizes are allowed.  `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format.  (default: 4x6)
  --label-image-id: any # The label image resource that was used to create a custom label image. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/labels")
  let body = {ship_to_service_point_id: $ship_to_service_point_id, ship_from_service_point_id: $ship_from_service_point_id, shipment: $shipment, is_return_label: $is_return_label, rma_number: $rma_number, charge_event: $charge_event, outbound_label_id: $outbound_label_id, test_label: $test_label, validate_address: $validate_address, label_download_type: $label_download_type, label_format: $label_format, display_scheme: $display_scheme, label_layout: $label_layout, label_image_id: $label_image_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Label By External Shipment ID
#
# GET /v1/labels/external_shipment_id/{external_shipment_id}
# operationId: get_label_by_external_shipment_id
export def "labels-external-shipment-id id" [
  external_shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-download-type: string@label-download-type-completer # e.g. url
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label_download_type" $label_download_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/labels/external_shipment_id/($external_shipment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Purchase Label with Rate ID
#
# POST /v1/labels/rates/{rate_id}
# operationId: create_label_from_rate
export def "labels-rates rate" [
  rate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-field1: string # Optional - Value will be saved in the shipment's advanced_options > custom_field1
  --custom-field2: string # Optional - Value will be saved in the shipment's advanced_options > custom_field2
  --custom-field3: string # Optional - Value will be saved in the shipment's advanced_options > custom_field3
  --validate-address: any
  --label-layout: any # default: 4x6
  --label-format: any # default: pdf
  --label-download-type: any # default: url
  --display-scheme: any # The display format that the label should be shown in. (default: label)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/labels/rates/($rate_id)")
  let body = {custom_field1: $custom_field1, custom_field2: $custom_field2, custom_field3: $custom_field3, validate_address: $validate_address, label_layout: $label_layout, label_format: $label_format, label_download_type: $label_download_type, display_scheme: $display_scheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Purchase Label from Rate Shopper
#
# POST /v1/labels/rate_shopper_id/{rate_shopper_id}
# operationId: create_label_from_rate_shopper
@deprecated --flag test-label
export def "labels-rate-shopper-id shopper" [
  rate_shopper_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  shipment: any # The shipment details for which to create a label. Must be provided inline. The carrier_id, service_code, and shipping_rule_id are not included as these will be automatically determined by the Rate Shopper based on your strategy.
  --is-return-label: oneof<nothing, bool> # Indicates whether this is a return label.  You may also want to set the `rma_number` so you know what is being returned.
  --rma-number: string # An optional Return Merchandise Authorization number.  This field is useful for return labels.  You can set it to any string value.  (nullable)
  --charge-event: any # The label charge event.
  --outbound-label-id: any # The `label_id` of the original (outgoing) label that the return label is for. This associates the two labels together, which is required by some carriers.
  --test-label: oneof<nothing, bool> # Indicate if this label is being used only for testing purposes. If true, then no charge will be added to your account. (DEPRECATED, default: false)
  --validate-address: any # default: no_validation
  --label-download-type: any # default: url
  --label-format: any # The file format that you want the label to be in.  We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats.  (default: pdf)
  --display-scheme: any # The display format that the label should be shown in. (default: label)
  --label-layout: any # The layout (size) that you want the label to be in.  The `label_format` determines which sizes are allowed.  `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format.  (default: 4x6)
  --label-image-id: any # The label image resource that was used to create a custom label image. (nullable)
]: any -> record<rate_shopper_id: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/labels/rate_shopper_id/($rate_shopper_id)")
  let body = {shipment: $shipment, is_return_label: $is_return_label, rma_number: $rma_number, charge_event: $charge_event, outbound_label_id: $outbound_label_id, test_label: $test_label, validate_address: $validate_address, label_download_type: $label_download_type, label_format: $label_format, display_scheme: $display_scheme, label_layout: $label_layout, label_image_id: $label_image_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Purchase Label with Shipment ID
#
# POST /v1/labels/shipment/{shipment_id}
# operationId: create_label_from_shipment
export def "labels-shipment shipment" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate-address: any
  --label-layout: any # default: 4x6
  --label-format: any # default: pdf
  --label-download-type: any # default: url
  --display-scheme: any # The display format that the label should be shown in. (default: label)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/labels/shipment/($shipment_id)")
  let body = {validate_address: $validate_address, label_layout: $label_layout, label_format: $label_format, label_download_type: $label_download_type, display_scheme: $display_scheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Label By ID
#
# GET /v1/labels/{label_id}
# operationId: get_label_by_id
export def "labels id" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label-download-type: string@label-download-type-completer # e.g. url
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label_download_type" $label_download_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/labels/($label_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a return label
#
# POST /v1/labels/{label_id}/return
# operationId: create_return_label
export def "labels-return label" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --charge-event: any # The label charge event.
  --label-layout: any # The layout (size) that you want the label to be in.  The `label_format` determines which sizes are allowed.  `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format.  (default: 4x6)
  --label-format: any # The file format that you want the label to be in.  We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats.  (default: pdf)
  --label-download-type: any # default: url
  --display-scheme: any # The display format that the label should be shown in. (default: label)
  --label-image-id: any # The label image resource that was used to create a custom label image. (nullable)
  --rma-number: string # An optional Return Merchandise Authorization number. If provided, this value will be used as the return label's RMA number. If omitted, the system will auto-generate an RMA number (current default behavior). You can set it to any string value.  (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/labels/($label_id)/return")
  let body = {charge_event: $charge_event, label_layout: $label_layout, label_format: $label_format, label_download_type: $label_download_type, display_scheme: $display_scheme, label_image_id: $label_image_id, rma_number: $rma_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Label Tracking Information
#
# GET /v1/labels/{label_id}/track
# operationId: get_tracking_log_from_label
export def "labels-track label" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/labels/($label_id)/track")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Void a Label By ID
#
# PUT /v1/labels/{label_id}/void
# operationId: void_label
export def "labels-void label" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<approved: bool, message: string, reason_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/labels/($label_id)/void")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a label refund request
#
# POST /v1/labels/{label_id}/cancel_refund
# operationId: cancel_label_refund
export def "labels-cancel-refund refund" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/labels/($label_id)/cancel_refund")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Manifests
#
# GET /v1/manifests
# operationId: list_manifests
export def "manifests manifests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --warehouse-id: string # Warehouse ID (e.g. se-28529731)
  --ship-date-start: string # ship date start range (format: date-time, e.g. 2018-09-23T15:00:00.000Z)
  --ship-date-end: string # ship date end range (format: date-time, e.g. 2018-09-23T15:00:00.000Z)
  --created-at-start: string # Used to create a filter for when a resource was created (ex. A shipment that was created after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Used to create a filter for when a resource was created, (ex. A shipment that was created before a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --carrier-id: string # Carrier ID (e.g. se-28529731)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned.  (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --label-ids: list
]: nothing -> record<manifests: table<manifest_id: record, form_id: record, created_at: string, ship_date: string, shipments: int, label_ids: list, warehouse_id: record, submission_id: string, carrier_id: record, manifest_download: record>, total: int, page: int, pages: int, links: record<first: record, last: record, prev: record<href: record, type: string>, next: record<href: record, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "warehouse_id" $warehouse_id "scalar") (serialize-qp "ship_date_start" $ship_date_start "scalar") (serialize-qp "ship_date_end" $ship_date_end "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "carrier_id" $carrier_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "label_ids" $label_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/manifests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Manifest
#
# POST /v1/manifests
# operationId: create_manifest
export def "manifests manifest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-id: any # A string that uniquely identifies the carrier
  --excluded-label-ids: list # The list of label ids to exclude from the manifest
  --label-ids: list # The list of label ids to include for the manifest
  --warehouse-id: any # A string that uniquely identifies the warehouse
  --ship-date: string # The ship date that the shipment will be sent out on (format: date-time, e.g. 2018-09-23T15:00:00.000Z)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/manifests")
  let body = {carrier_id: $carrier_id, excluded_label_ids: $excluded_label_ids, label_ids: $label_ids, warehouse_id: $warehouse_id, ship_date: $ship_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Manifest By Id
#
# GET /v1/manifests/{manifest_id}
# operationId: get_manifest_by_id
export def "manifests id" [
  manifest_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/manifests/($manifest_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Manifest Request By Id
#
# GET /v1/manifests/requests/{manifest_request_id}
# operationId: get_manifest_request_by_id
export def "manifests-requests id" [
  manifest_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/manifests/requests/($manifest_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Custom Package Types
#
# GET /v1/packages
# operationId: list_package_types
export def "packages types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<packages: table<package_id: record, package_code: record, name: string, dimensions: record, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/packages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Custom Package Type
#
# POST /v1/packages
# operationId: create_package_type
export def "packages type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --package-id: any # A string that uniquely identifies the package.
  package_code: any
  name: string # e.g. laptop_box
  --dimensions: any # The custom dimensions for the package.
  --description: string # Provides a helpful description for the custom package. (nullable, e.g. Packaging for laptops)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/packages")
  let body = {package_id: $package_id, package_code: $package_code, name: $name, dimensions: $dimensions, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Custom Package Type By ID
#
# GET /v1/packages/{package_id}
# operationId: get_package_type_by_id
export def "packages id" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/packages/($package_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Custom Package Type By ID
#
# PUT /v1/packages/{package_id}
# operationId: update_package_type
export def "packages type-by-package_id" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-package-id: any # A string that uniquely identifies the package.
  package_code: any
  name: string # e.g. laptop_box
  --dimensions: any # The custom dimensions for the package.
  --description: string # Provides a helpful description for the custom package. (nullable, e.g. Packaging for laptops)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/packages/($package_id)")
  let body = {package_id: $body_package_id, package_code: $package_code, name: $name, dimensions: $dimensions, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete A Custom Package By ID
#
# DELETE /v1/packages/{package_id}
# operationId: delete_package_type
export def "packages type-by-package_id-1" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/packages/($package_id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Scheduled Pickups
#
# GET /v1/pickups
# operationId: list_scheduled_pickups
export def "pickups pickups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-id: string # Carrier ID (e.g. se-28529731)
  --warehouse-id: string # Warehouse ID (e.g. se-28529731)
  --created-at-start: string # Only return scheduled pickups that were created on or after a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Only return scheduled pickups that were created on or before a specific date/time (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned.  (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
]: nothing -> record<pickups: table<pickup_id: record, label_ids: list, created_at: record, cancelled_at: record, carrier_id: record, confirmation_number: string, warehouse_id: record, pickup_address: record, contact_details: record, pickup_notes: string, pickup_window: record, pickup_windows: list>, total: int, page: int, pages: int, links: record<first: record, last: record, prev: record<href: record, type: string>, next: record<href: record, type: string>>, request_id: record, errors: table<error_source: record, error_type: record, error_code: record, message: string, carrier_id: record, carrier_code: record, field_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_id" $carrier_id "scalar") (serialize-qp "warehouse_id" $warehouse_id "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/pickups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Schedule a Pickup
#
# POST /v1/pickups
# operationId: schedule_pickup
# --contact_details shape: {name: string, email: any, phone: string}
# --pickup_window shape: {start_at: any, end_at: any}
# --pickup_windows item shape: {start_at?: any, end_at?: any}
export def "pickups pickup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label_ids: list # Label IDs that will be included in the pickup request
  contact_details: record # shape: {name: string, email: any, phone: string}
  --pickup-notes: string # Used by some carriers to give special instructions for a package pickup
  pickup_window: record # The desired time range for the package pickup. — shape: {start_at: any, end_at: any}
]: any -> record<pickup_id: record, label_ids: list<record>, created_at: record, cancelled_at: record, carrier_id: record, confirmation_number: string, warehouse_id: record, pickup_address: record, contact_details: record<name: string, email: record, phone: string>, pickup_notes: string, pickup_window: record<start_at: record, end_at: record>, pickup_windows: table<start_at: record, end_at: record>, request_id: record, errors: table<error_source: record, error_type: record, error_code: record, message: string, carrier_id: record, carrier_code: record, field_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/pickups")
  let body = {label_ids: $label_ids, contact_details: $contact_details, pickup_notes: $pickup_notes, pickup_window: $pickup_window} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Pickup By ID
#
# GET /v1/pickups/{pickup_id}
# operationId: get_pickup_by_id
export def "pickups id" [
  pickup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<request_id: record, errors: table<error_source: record, error_type: record, error_code: record, message: string, carrier_id: record, carrier_code: record, field_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pickups/($pickup_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Scheduled Pickup
#
# DELETE /v1/pickups/{pickup_id}
# operationId: delete_scheduled_pickup
export def "pickups pickup-by-pickup_id" [
  pickup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<request_id: record, errors: table<error_source: record, error_type: record, error_code: record, message: string, carrier_id: record, carrier_code: record, field_name: string>, pickup_id: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pickups/($pickup_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Shipping Rates
#
# POST /v1/rates
# operationId: calculate_rates
export def "rates rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ship-to-service-point-id: string # A unique identifier for a carrier service point where the shipment will be delivered by the carrier. This will take precedence over a shipment's ship to address. (nullable, e.g. 614940)
  --ship-from-service-point-id: string # A unique identifier for a carrier drop off point where a merchant plans to deliver packages. This will take precedence over a shipment's ship from address. (nullable, e.g. 614940)
  --rate-options: any # The rate options
  shipment_id: any # A string that uniquely identifies the shipment
  shipment: any # The shipment object
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rates")
  let body = {ship_to_service_point_id: $ship_to_service_point_id, ship_from_service_point_id: $ship_from_service_point_id, rate_options: $rate_options, shipment_id: $shipment_id, shipment: $shipment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Bulk Rates
#
# POST /v1/rates/bulk
# operationId: compare_bulk_rates
export def "rates-bulk rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ship-to-service-point-id: string # A unique identifier for a carrier service point where the shipment will be delivered by the carrier. This will take precedence over a shipment's ship to address. (nullable, e.g. 614940)
  --ship-from-service-point-id: string # A unique identifier for a carrier drop off point where a merchant plans to deliver packages. This will take precedence over a shipment's ship from address. (nullable, e.g. 614940)
  rate_options: any # The rate options
  --shipment-ids: list # The array of shipment IDs
  --shipments: list # The array of shipments to get bulk rate estimates for
]: any -> table<rate_request_id: record, shipment_id: record, created_at: string, status: record, errors: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rates/bulk")
  let body = {ship_to_service_point_id: $ship_to_service_point_id, ship_from_service_point_id: $ship_from_service_point_id, rate_options: $rate_options, shipment_ids: $shipment_ids, shipments: $shipments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Estimate Rates
#
# POST /v1/rates/estimate
# operationId: estimate_rates
@deprecated --flag carrier-id
export def "rates-estimate rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  from_country_code: any
  from_postal_code: any
  from_city_locality: string # from postal code (e.g. Austin)
  from_state_province: string # From state province (e.g. Austin)
  to_country_code: any
  to_postal_code: any
  to_city_locality: string # The city locality the package is being shipped to (e.g. Austin)
  to_state_province: string # To state province (e.g. Houston)
  weight: any # The weight of the package
  --dimensions: any # The dimensions of the package
  --confirmation: any
  --address-residential-indicator: any
  ship_date: string # ship date
  --carrier-id: any # A string that uniquely identifies the carrier (DEPRECATED)
  --carrier-ids: list # Array of Carrier Ids
]: any -> table<rate_type: record, carrier_id: record, shipping_amount: record<currency: record, amount: float>, insurance_amount: record<currency: record, amount: float>, confirmation_amount: record<currency: record, amount: float>, other_amount: record<currency: record, amount: float>, tax_amount: record<currency: record, amount: float>, zone: int, package_type: string, delivery_days: int, guaranteed_service: bool, estimated_delivery_date: record, carrier_delivery_days: string, ship_date: string, negotiated_rate: bool, service_type: string, service_code: string, trackable: bool, carrier_code: string, carrier_nickname: string, carrier_friendly_name: string, validation_status: record, warning_messages: list<string>, error_messages: list<string>, rate_attributes: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rates/estimate")
  let body = {from_country_code: $from_country_code, from_postal_code: $from_postal_code, from_city_locality: $from_city_locality, from_state_province: $from_state_province, to_country_code: $to_country_code, to_postal_code: $to_postal_code, to_city_locality: $to_city_locality, to_state_province: $to_state_province, weight: $weight, dimensions: $dimensions, confirmation: $confirmation, address_residential_indicator: $address_residential_indicator, ship_date: $ship_date, carrier_id: $carrier_id, carrier_ids: $carrier_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Rate By ID
#
# GET /v1/rates/{rate_id}
# operationId: get_rate_by_id
export def "rates id" [
  rate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/rates/($rate_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Service Points
#
# POST /v1/service_points/list
# operationId: service_points_list
# --address shape: {address_line1?: string, address_line2?: string, address_line3?: string, city_locality?: string, state_province?: string, postal_code?: string, country_code: string}
# --providers item shape: {carrier_id?: string, service_code?: list}
# --shipment shape: {total_weight?: any, packages?: list}
export def "service-points-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-query: string # Unstructured text to search for service points by. (e.g. 177A Bleecker Street New York)
  --address: record # Structured address to search by. — shape: {address_line1?: string, address_line2?: string, address_line3?: string, city_locality?: string, state_province?: string, postal_code?: string, country_code: string}
  --providers: list # An array of shipping service providers and service codes — item shape: {carrier_id?: string, service_code?: list}
  --lat: float # The latitude of the point. Represented as signed degrees. Required if long is provided. http://www.geomidpoint.com/latlon.html (format: double, e.g. 48.874518928233094)
  --long: float # The longitude of the point. Represented as signed degrees. Required if lat is provided. http://www.geomidpoint.com/latlon.html (format: double, e.g. 2.3591775711639404)
  --radius: int # Search radius in kilometers (format: int32, e.g. 500)
  --max-results: int # The maximum number of service points to return (format: int32, e.g. 25)
  --shipment: record # Shipment information to be used for service point selection — shape: {total_weight?: any, packages?: list}
]: any -> record<lat: float, long: float, service_points: table<carrier_code: record, service_codes: list, service_point_id: string, company_name: string, address_line1: string, city_locality: string, state_province: string, postal_code: record, country_code: record, phone_number: string, lat: float, long: float, distance_in_meters: float, hours_of_operation: record, features: list, type: string>, errors: table<error_source: record, error_type: record, error_code: record, message: string, carrier_id: record, carrier_code: record, field_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/service_points/list")
  let body = {address_query: $address_query, address: $address, providers: $providers, lat: $lat, long: $long, radius: $radius, max_results: $max_results, shipment: $shipment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Service Point By ID
#
# GET /v1/service_points/{carrier_code}/{country_code}/{service_point_id}
# operationId: service_points_get_by_id
export def "service-points id" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<service_point: record<carrier_code: record, service_codes: list<string>, service_point_id: string, company_name: string, address_line1: string, city_locality: string, state_province: string, postal_code: record, country_code: record, phone_number: string, lat: float, long: float, hours_of_operation: record<monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, sunday: list>, features: list<string>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/service_points/($carrier_code)/($country_code)/($service_point_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Shipments
#
# GET /v1/shipments
# operationId: list_shipments
export def "shipments shipments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shipment-status: string@shipment-status-completer
  --batch-id: string # Batch ID (e.g. se-28529731)
  --tag: string # Search for shipments based on the custom tag added to the shipment object (e.g. Letters_to_santa)
  --created-at-start: string # Used to create a filter for when a resource was created (ex. A shipment that was created after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --created-at-end: string # Used to create a filter for when a resource was created, (ex. A shipment that was created before a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --modified-at-start: string # Used to create a filter for when a resource was modified (ex. A shipment that was modified after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --modified-at-end: string # Used to create a filter for when a resource was modified (ex. A shipment that was modified before a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
  --page: int # Return a specific page of results. Defaults to the first page. If set to a number that's greater than the number of pages of results, an empty page is returned.  (format: int32, default: 1, e.g. 2)
  --page-size: int # The number of results to return per response. (format: int32, default: 25, e.g. 50)
  --sales-order-id: string # Sales Order ID
  --sort-dir: string # Controls the sort order of the query. (default: desc)
  --sort-by: string@sort-by-completer-2 # e.g. modified_at
]: nothing -> record<shipments: list<record>, total: int, page: int, pages: int, links: record<first: record, last: record, prev: record<href: record, type: string>, next: record<href: record, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shipment_status" $shipment_status "scalar") (serialize-qp "batch_id" $batch_id "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "modified_at_start" $modified_at_start "scalar") (serialize-qp "modified_at_end" $modified_at_end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sales_order_id" $sales_order_id "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/shipments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Shipments
#
# POST /v1/shipments
# operationId: create_shipments
export def "shipments shipments-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  shipments: list # An array of shipments to be created.
]: any -> record<has_errors: bool, shipments: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/shipments")
  let body = {shipments: $shipments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Shipment By External ID
#
# GET /v1/shipments/external_shipment_id/{external_shipment_id}
# operationId: get_shipment_by_external_id
export def "shipments-external-shipment-id id" [
  external_shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/external_shipment_id/($external_shipment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Parse shipping info
#
# PUT /v1/shipments/recognize
# operationId: parse_shipment
export def "shipments-recognize shipment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # The unstructured text that contains shipping-related entities (e.g. I have a 4oz package that's 5x10x14in, and I need to ship it to Margie McMiller at 3800 North Lamar suite 200 in austin, tx 78652. Please send it via USPS first class and require an adult signature. It also needs to be insured for $400. )
  --shipment: any # You can optionally provide a `shipment` object containing any already-known values. For example, you probably already know the `ship_from` address, and you may also already know what carrier and service you want to use.
]: any -> record<score: float, shipment: record<shipment_id: record, carrier_id: record, service_code: record, shipping_rule_id: record, external_order_id: string, items: list<record>, tax_identifiers: list<record>, external_shipment_id: string, shipment_number: string, ship_date: record, created_at: record, modified_at: record, shipment_status: record, ship_to: record, ship_from: record, warehouse_id: record, return_to: record, is_return: bool, confirmation: record, customs: record<contents: record, contents_explanation: string, non_delivery: record, terms_of_trade_code: string, declaration: string, invoice_additional_details: record, importer_of_record: record, license_number: string, certificate_number: string, customs_items: list>, advanced_options: record<bill_to_account: string, bill_to_country_code: record, bill_to_party: record, bill_to_postal_code: string, contains_alcohol: bool, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, non_machinable: bool, saturday_delivery: bool, fedex_freight: record, use_ups_ground_freight_pricing: bool, freight_class: string, custom_field1: string, custom_field2: string, custom_field3: string, origin_type: record, additional_handling: bool, shipper_release: bool, collect_on_delivery: record, third_party_consignee: bool, dangerous_goods: bool, dangerous_goods_contact: record, windsor_framework_details: record, license_number: string, invoice_number: string, certificate_number: string, fragile: bool, delivery_as_addressed: bool, return_after_first_attempt: bool, regulated_content_type: record>, insurance_provider: record, tags: list<record>, order_source_code: record, packages: list<record>, total_weight: record<value: float, unit: record>, comparison_rate_type: string, zone: int>, entities: table<type: string, score: float, text: string, start_index: int, end_index: int, result: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/shipments/recognize")
  let body = {text: $text, shipment: $shipment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Shipment By ID
#
# GET /v1/shipments/{shipment_id}
# operationId: get_shipment_by_id
export def "shipments id" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($shipment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Shipment By ID
#
# PUT /v1/shipments/{shipment_id}
# operationId: update_shipment
# --items item shape: {name?: string, sales_order_id?: string, sales_order_item_id?: string, quantity?: int, sku?: string, external_order_id?: string, external_order_item_id?: string, asin?: string, order_source_code?: any}
# --tax_identifiers item shape: {taxable_entity_type: any, identifier_type: any, issuing_authority: string, value: string}
# --tags item shape: {name: string, color?: string}
# --packages item shape: {package_id?: any, package_code?: any, package_name?: string, weight: any, dimensions?: any, insured_value?: any, label_messages?: any, external_package_id?: string, content_description?: string, products?: list}
export def "shipments shipment" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-id: any # The carrier account that is billed for the shipping charges
  --service-code: any # The [carrier service](https://www.shipengine.com/docs/shipping/use-a-carrier-service/) used to ship the package, such as `fedex_ground`, `usps_first_class_mail`, `flat_rate_envelope`, etc.
  --shipping-rule-id: any # ID of the shipping rule, which you want to use to automate carrier/carrier service selection for the shipment
  --external-order-id: string # ID that the Order Source assigned (nullable)
  --items: list # Describe the packages included in this shipment as related to potential metadata that was imported from external order sources  (default: []) — item shape: {name?: string, sales_order_id?: string, sales_order_item_id?: string, quantity?: int, sku?: string, external_order_id?: string, external_order_item_id?: string, asin?: string, order_source_code?: any}
  --tax-identifiers: list # nullable — item shape: {taxable_entity_type: any, identifier_type: any, issuing_authority: string, value: string}
  --external-shipment-id: string # A unique user-defined key to identify a shipment.  This can be used to retrieve the shipment.  > **Warning:** The `external_shipment_id` is limited to 50 characters. Any additional characters will be truncated.  (nullable)
  --shipment-number: string # A non-unique user-defined number used to identify a shipment.  If undefined, this will match the external_shipment_id of the shipment.  > **Warning:** The `shipment_number` is limited to 50 characters. Any additional characters will be truncated.  (nullable)
  --ship-date: any # The date that the shipment was (or will be) shipped.  ShipEngine will take the day of week into consideration. For example, if the carrier does not operate on Sundays, then a package that would have shipped on Sunday will ship on Monday instead.
  ship_to: any # The recipient's mailing address
  ship_from: any # The shipment's origin address. If you frequently ship from the same location, consider [creating a warehouse](https://www.shipengine.com/docs/reference/create-warehouse/). Then you can simply specify the `warehouse_id` rather than the complete address each time.
  --warehouse-id: any # The [warehouse](https://www.shipengine.com/docs/shipping/ship-from-a-warehouse/) that the shipment is being shipped from.  Either `warehouse_id` or `ship_from` must be specified.  (nullable)
  --return-to: any # The return address for this shipment.  Defaults to the `ship_from` address.
  --is-return: oneof<nothing, bool> # An optional indicator if the shipment is intended to be a return. Defaults to false if not provided.  (nullable, default: false)
  --confirmation: any # The type of delivery confirmation that is required for this shipment. (default: none)
  --customs: any # Customs information.  This is usually only needed for international shipments.  (nullable)
  --advanced-options: any # Advanced shipment options.  These are entirely optional.
  --insurance-provider: any # The insurance provider to use for any insured packages in the shipment.  (default: none)
  --order-source-code: any
  --packages: list # The packages in the shipment.  > **Note:** Some carriers only allow one package per shipment.  If you attempt to create a multi-package shipment for a carrier that doesn't allow it, an error will be returned. — item shape: {package_id?: any, package_code?: any, package_name?: string, weight: any, dimensions?: any, insured_value?: any, label_messages?: any, external_package_id?: string, content_description?: string, products?: list}
  --comparison-rate-type: string # Calculate a rate for this shipment with the requested carrier using a ratecard that differs from the default.  Only supported for UPS and USPS. (nullable, e.g. retail)
  --validate-address: any # default: no_validation
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($shipment_id)")
  let body = {carrier_id: $carrier_id, service_code: $service_code, shipping_rule_id: $shipping_rule_id, external_order_id: $external_order_id, items: $items, tax_identifiers: $tax_identifiers, external_shipment_id: $external_shipment_id, shipment_number: $shipment_number, ship_date: $ship_date, ship_to: $ship_to, ship_from: $ship_from, warehouse_id: $warehouse_id, return_to: $return_to, is_return: $is_return, confirmation: $confirmation, customs: $customs, advanced_options: $advanced_options, insurance_provider: $insurance_provider, order_source_code: $order_source_code, packages: $packages, comparison_rate_type: $comparison_rate_type, validate_address: $validate_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a Shipment
#
# PUT /v1/shipments/{shipment_id}/cancel
# operationId: cancel_shipments
export def "shipments-cancel shipments" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($shipment_id)/cancel")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Shipment Rates
#
# GET /v1/shipments/{shipment_id}/rates
# operationId: list_shipment_rates
export def "shipments-rates rates" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at-start: string # Used to create a filter for when a resource was created (ex. A shipment that was created after a certain time) (format: date-time, e.g. 2019-03-12T19:24:13.657Z)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "created_at_start" $created_at_start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/shipments/($shipment_id)/rates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Shipments Tags
#
# PUT /v1/shipments/tags
# operationId: shipments_update_tags
# --shipments_tags item shape: {shipment_id?: string, tags?: list}
export def "shipments-tags tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shipments-tags: list # item shape: {shipment_id?: string, tags?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/shipments/tags")
  let body = {shipments_tags: $shipments_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Shipment Tags
#
# GET /v1/shipments/{shipment_id}/tags
# operationId: shipments_list_tags
export def "shipments-tags tags-by-shipment_id" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($shipment_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Tag to Shipment
#
# POST /v1/shipments/{shipment_id}/tags/{tag_name}
# operationId: tag_shipment
export def "shipments-tags shipment-by-shipment_id-tag_name" [
  shipment_id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($shipment_id)/tags/($tag_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove Tag from Shipment
#
# DELETE /v1/shipments/{shipment_id}/tags/{tag_name}
# operationId: untag_shipment
export def "shipments-tags shipment-by-shipment_id-tag_name-1" [
  shipment_id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shipments/($shipment_id)/tags/($tag_name)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tags
#
# GET /v1/tags
# operationId: list_tags
export def "tags tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tags: table<tag_id: int, name: string, color: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Tag
#
# POST /v1/tags
# operationId: create_tag
export def "tags tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The tag name. (e.g. Fragile)
  --color: string # A hex-coded string identifying the color of the tag. (e.g. #FF0000)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tags")
  let body = {name: $name, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a New Tag
#
# POST /v1/tags/{tag_name}
# operationId: create_tag
export def "tags tag-by-tag_name" [
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tags/($tag_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Tag
#
# DELETE /v1/tags/{tag_name}
# operationId: delete_tag
export def "tags tag-by-tag_name-1" [
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tags/($tag_name)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Tag Name
#
# PUT /v1/tags/{tag_name}/{new_tag_name}
# operationId: rename_tag
export def "tags tag-by-tag_name-new_tag_name" [
  tag_name: string
  new_tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tags/($tag_name)/($new_tag_name)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Ephemeral Token
#
# POST /v1/tokens/ephemeral
# operationId: tokens_get_ephemeral_token
export def "tokens-ephemeral token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirect: string@redirect-completer # Include a redirect url to the application formatted with the ephemeral token.
]: nothing -> record<token: string, redirect_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirect" $redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tokens/ephemeral" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tracking Information
#
# GET /v1/tracking
# operationId: get_tracking_log
export def "tracking log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-code: string # A [shipping carrier](https://www.shipengine.com/docs/carriers/setup/), such as `fedex`, `dhl_express`, `stamps_com`, etc.  (e.g. stamps_com)
  --tracking-number: string # The tracking number associated with a shipment (e.g. 9405511899223197428490)
  --carrier-id: string # Carrier ID (e.g. se-28529731)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_code" $carrier_code "scalar") (serialize-qp "tracking_number" $tracking_number "scalar") (serialize-qp "carrier_id" $carrier_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tracking" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start Tracking a Package
#
# POST /v1/tracking/start
# operationId: start_tracking
export def "tracking-start tracking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --carrier-code: string # A [shipping carrier](https://www.shipengine.com/docs/carriers/setup/), such as `fedex`, `dhl_express`, `stamps_com`, etc.  (e.g. stamps_com)
  --tracking-number: string # The tracking number associated with a shipment (e.g. 9405511899223197428490)
  --carrier-id: string # Carrier ID (e.g. se-28529731)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_code" $carrier_code "scalar") (serialize-qp "tracking_number" $tracking_number "scalar") (serialize-qp "carrier_id" $carrier_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tracking/start" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop Tracking a Package
#
# POST /v1/tracking/stop
# operationId: stop_tracking
export def "tracking-stop tracking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --carrier-code: string # A [shipping carrier](https://www.shipengine.com/docs/carriers/setup/), such as `fedex`, `dhl_express`, `stamps_com`, etc.  (e.g. stamps_com)
  --tracking-number: string # The tracking number associated with a shipment (e.g. 9405511899223197428490)
  --carrier-id: string # Carrier ID (e.g. se-28529731)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_code" $carrier_code "scalar") (serialize-qp "tracking_number" $tracking_number "scalar") (serialize-qp "carrier_id" $carrier_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tracking/stop" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Warehouses
#
# GET /v1/warehouses
# operationId: list_warehouses
export def "warehouses warehouses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<warehouses: table<warehouse_id: record, is_default: bool, name: string, created_at: string, origin_address: record, return_address: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/warehouses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Warehouse
#
# POST /v1/warehouses
# operationId: create_warehouse
export def "warehouses warehouse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {is_default: $is_default, name: $name, origin_address: $origin_address, return_address: $return_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Warehouse By Id
#
# GET /v1/warehouses/{warehouse_id}
# operationId: get_warehouse_by_id
export def "warehouses id" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/warehouses/($warehouse_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Warehouse By Id
#
# PUT /v1/warehouses/{warehouse_id}
# operationId: update_warehouse
export def "warehouses warehouse-by-warehouse_id" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base $"/v1/warehouses/($warehouse_id)")
  let body = {is_default: $is_default, name: $name, origin_address: $origin_address, return_address: $return_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Warehouse By ID
#
# DELETE /v1/warehouses/{warehouse_id}
# operationId: delete_warehouse
export def "warehouses warehouse-by-warehouse_id-1" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/warehouses/($warehouse_id)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Warehouse Settings
#
# PUT /v1/warehouses/{warehouse_id}/settings
# operationId: update_warehouse_settings
export def "warehouses-settings settings" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --is-default: oneof<nothing, bool> # The default property on the warehouse. (nullable, e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/warehouses/($warehouse_id)/settings")
  let body = {is_default: $is_default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
