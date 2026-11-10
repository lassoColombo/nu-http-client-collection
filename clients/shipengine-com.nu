# Auto-generated client for ShipEngine API v1.1.202303022103
# Source: https://api.apis.guru/v2/specs/shipengine.com/1.1.202303022103/openapi.json
# Auth: --token flag or $env.SHIPENGINE_API_TOKEN

const BASE_URL = "https://api.shipengine.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SHIPENGINE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "api-key" => { {scheme: $scheme, headers: {"API-Key": $token_val}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
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

def base-url-completer [] { ["https://api.shipengine.com"] }
def auth-scheme-completer [] { ["api-key"] }

# Completers for enum parameters
def status-completer [] { ["archived" "completed" "completed_with_errors" "invalid" "notifying" "open" "processing" "queued"] }
def sort-by-completer [] { ["created_at" "processed_at" "ship_date"] }
def accept-completer [] { ["application/json" "text/plain"] }
def display-scheme-completer [] { ["label" "label_and_qr_code" "qr_code"] }
def label-format-completer [] { ["pdf" "png" "zpl"] }
def label-layout-completer [] { ["4x6" "letter"] }
def carrier-name-completer [] { ["access_worldwide" "amazon_buy_shipping" "amazon_shipping_uk" "apc" "asendia" "australia_post" "canada_post" "dhl_ecommerce" "dhl_express" "dhl_express_au" "dhl_express_ca" "dhl_express_uk" "dpd" "endicia" "fedex" "fedex_uk" "firstmile" "imex" "newgistics" "ontrac" "purolator_canada" "royal_mail" "rr_donnelley" "seko" "sendle" "stamps_com" "ups"] }
def ancillary-endorsement-completer [] { ["address_service_requested" "change_service_requested" "forwarding_service_requested" "leave_if_no_response" "none" "return_service_requested"] }
def carrier-name-completer-1 [] { ["dhl_express" "fedex" "newgistics" "ups"] }
def pickup-type-completer [] { ["business_service_center" "drop_box" "none" "regular_pickup" "request_courier" "station"] }
def smart-post-endorsement-completer [] { ["address_service_requested" "change_service_requested" "forwarding_service_requested" "leave_if_no_response" "none" "return_service_requested"] }
def smart-post-hub-completer [] { ["allentown_pa" "atlanta_ga" "baltimore_md" "charlotte_nc" "chino_ca" "dallas_tx" "denver_co" "detroit_mi" "edison_nj" "grove_city_oh" "groveport_oh" "houston_tx" "indianapolis_in" "kansas_city_ks" "los_angeles_ca" "martinsburg_wv" "memphis_tn" "minneapolis_mn" "new_berlin_wi" "newark_ny" "none" "northborough_ma" "orlando_fl" "phoneix_az" "pittsburgh_pa" "reno_nv" "sacramento_ca" "salt_lake_city_ut" "scranton_pa" "seattle_wa" "south_brunswick_nj" "st_louis_mo" "wheeling_il" "windsor_ct"] }
def mail-innovations-endorsement-completer [] { ["address_service_requested" "change_service_requested" "forwarding_service_requested" "leave_if_no_response" "none" "return_service_requested"] }
def accept-completer-1 [] { ["application/pdf" "application/zpl" "image/png"] }
def event-completer [] { ["batch" "carrier_connected" "order_source_refresh_complete" "rate" "report_complete" "sales_orders_imported" "track"] }
def label-status-completer [] { ["completed" "error" "processing" "voided"] }
def sort-by-completer-1 [] { ["created_at" "modified_at"] }
def charge-event-completer [] { ["carrier_default" "on_carrier_acceptance" "on_creation"] }
def label-download-type-completer [] { ["inline" "url"] }
def validate-address-completer [] { ["no_validation" "validate_and_clean" "validate_only"] }
def address-residential-indicator-completer [] { ["no" "unknown" "yes"] }
def confirmation-completer [] { ["adult_signature" "delivery" "delivery_mailed" "direct_signature" "none" "signature" "verbal_confirmation"] }
def shipment-status-completer [] { ["cancelled" "label_purchased" "pending" "processing"] }
def insurance-provider-completer [] { ["carrier" "none" "shipsurance" "third_party"] }
def order-source-code-completer [] { ["amazon_ca" "amazon_us" "brightpearl" "channel_advisor" "cratejoy" "ebay" "etsy" "groupon_goods" "jane" "magento" "paypal" "seller_active" "shopify" "squarespace" "stitch_labs" "three_dcart" "tophatter" "volusion" "walmart" "woo_commerce"] }
def origin-type-completer [] { ["drop_off" "pickup"] }
def redirect-completer [] { ["shipengine-dashboard"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["parse-address" "validate-address" "list-batches" "create-batch" "get-batch-by-external-id" "delete-batch" "get-batch-by-id" "update-batch" "add-to-batch" "list-batch-errors" "process-batch" "remove-from-batch" "list-carriers" "get-carrier-by-id" "add-funds-to-carrier" "get-carrier-options" "list-carrier-package-types" "list-carrier-services" "connect-carrier" "disconnect-carrier" "get-carrier-settings" "update-carrier-settings" "disconnect-insurer" "connect-insurer" "download-file" "list-webhooks" "create-webhook" "delete-webhook" "get-webhook-by-id" "update-webhook" "add-funds-to-insurance" "get-insurance-balance" "list-labels" "create-label" "get-label-by-external-shipment-id" "create-label-from-rate" "create-label-from-shipment" "get-label-by-id" "create-return-label" "get-tracking-log-from-label" "void-label" "list-manifests" "create-manifest" "get-manifest-request-by-id" "get-manifest-by-id" "list-package-types" "create-package-type" "delete-package-type" "get-package-type-by-id" "update-package-type" "list-scheduled-pickups" "schedule-pickup" "delete-scheduled-pickup" "get-pickup-by-id" "calculate-rates" "compare-bulk-rates" "estimate-rates" "get-rate-by-id" "service-points-list" "service-points-get-by-id" "list-shipments" "create-shipments" "get-shipment-by-external-id" "parse-shipment" "get-shipment-by-id" "update-shipment" "cancel-shipments" "list-shipment-rates" "untag-shipment" "tag-shipment" "list-tags" "delete-tag" "create-tag" "rename-tag" "tokens-get-ephemeral-token" "get-tracking-log" "start-tracking" "stop-tracking" "list-warehouses" "create-warehouse" "delete-warehouse" "get-warehouse-by-id" "update-warehouse" "update-warehouse-settings" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "parse-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # You can optionally provide any already-known address values. For example, you may already know the recipient's name, city, and country, and only want to parse the street address into separate lines. — shape: {address_line1?: string, address_line2?: string, address_line3?: string, address_residential_indicator?: "unknown"|"yes"|"no", city_locality?: string, company_name?: string, country_code?: string, email?: string, name?: string, phone?: string, postal_code?: string, state_province?: string}
  text: string # The unstructured text that contains address-related entities (e.g. Margie McMiller at 3800 North Lamar suite 200 in austin, tx.  The zip code there is 78652.)
]: any -> oneof<record<address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, entities: table<end_index: int, result: record, score: float, start_index: int, text: string, type: string>, score: float>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/addresses/recognize" $auth.query)
  let req_body = {"address": $address, "text": $text} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Validate An Address
#
# POST /v1/addresses/validate
# operationId: validate_address
export def "validate-address" [
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
]: any -> oneof<table<matched_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, messages: list<record>, original_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, status: string>, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/addresses/validate" $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List Batches
#
# GET /v1/batches
# operationId: list_batches
export def "list-batches" [
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
]: nothing -> oneof<record<batches: table<batch_errors_url: record, batch_id: string, batch_labels_url: record, batch_notes: string, batch_number: string, batch_shipments_url: record, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record, forms: int, label_download: record, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>, links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, total: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "batch_number" $batch_number "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/batches" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "page": $page, "page_size": $page_size, "sort_dir": $sort_dir, "batch_number": $batch_number, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create A Batch
#
# POST /v1/batches
# operationId: create_batch
export def "create-batch" [
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
  --external-batch-id: string # A string that uniquely identifies the external batch
  --rate-ids: list<string> # Array of rate IDs used in the batch
  --shipment-ids: list # Array of shipment IDs used in the batch
]: any -> oneof<record<batch_errors_url: record<href: string, type: string>, batch_id: string, batch_labels_url: record<href: string, type: string>, batch_notes: string, batch_number: string, batch_shipments_url: record<href: string, type: string>, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record<href: string, type: string>, forms: int, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batches" $auth.query)
  let req_body = {"batch_notes": $batch_notes, "external_batch_id": $external_batch_id, "rate_ids": $rate_ids, "shipment_ids": $shipment_ids} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Batch By External ID
#
# GET /v1/batches/external_batch_id/{external_batch_id}
# operationId: get_batch_by_external_id
export def "get-batch-by-external-id" [
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
]: nothing -> oneof<record<batch_errors_url: record<href: string, type: string>, batch_id: string, batch_labels_url: record<href: string, type: string>, batch_notes: string, batch_number: string, batch_shipments_url: record<href: string, type: string>, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record<href: string, type: string>, forms: int, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($external_batch_id | is-empty) { error make --unspanned { msg: "path parameter 'external_batch_id' must be non-empty" } }
  let full_url = (build-url $base ({external_batch_id: (encode-path-segment $external_batch_id)} | format pattern "/v1/batches/external_batch_id/{external_batch_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Delete Batch By Id
#
# DELETE /v1/batches/{batch_id}
# operationId: delete_batch
export def "delete-batch" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Batch By ID
#
# GET /v1/batches/{batch_id}
# operationId: get_batch_by_id
export def "get-batch-by-id" [
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
]: nothing -> oneof<record<batch_errors_url: record<href: string, type: string>, batch_id: string, batch_labels_url: record<href: string, type: string>, batch_notes: string, batch_number: string, batch_shipments_url: record<href: string, type: string>, completed: int, count: int, created_at: string, errors: int, external_batch_id: string, form_download: record<href: string, type: string>, forms: int, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_format: string, label_layout: string, processed_at: string, status: string, warnings: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Update Batch By Id
#
# PUT /v1/batches/{batch_id}
# operationId: update_batch
export def "update-batch" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# Add to a Batch
#
# POST /v1/batches/{batch_id}/add
# operationId: add_to_batch
export def "add-to-batch" [
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
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}/add") $auth.query)
  let req_body = {"rate_ids": $rate_ids, "shipment_ids": $shipment_ids} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Batch Errors
#
# GET /v1/batches/{batch_id}/errors
# operationId: list_batch_errors
export def "list-batch-errors" [
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
]: nothing -> oneof<record<errors: table<error: string, external_shipment_id: string, shipment_id: string>, links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}/errors") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pagesize": $pagesize} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Process Batch ID Labels
#
# POST /v1/batches/{batch_id}/process/labels
# operationId: process_batch
export def "process-batch" [
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
  --display-scheme: string@display-scheme-completer # The display format that the label should be shown in. (default: label)
  --label-format: string@label-format-completer # The possible file formats in which shipping labels can be downloaded. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. |Label Format | Supported Carriers |--------------|----------------------------------- |`pdf` | All carriers |`png` | `fedex` `stamps_com` `ups` `usps` |`zpl` | `access_worldwide` `apc` `asendia` `dhl_global_mail` `dhl_express` `dhl_express_australia` `dhl_express_canada` `dhl_express_worldwide` `dhl_express_uk` `dpd` `endicia` `fedex` `fedex_uk` `firstmile` `imex` `newgistics` `ontrac` `rr_donnelley` `stamps_com` `ups` `usps` (default: pdf)
  --label-layout: string@label-layout-completer # The available layouts (sizes) in which shipping labels can be downloaded. The label format determines which sizes are supported. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
  --ship-date: string # The Ship date the batch is being processed for (format: date-time)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}/process/labels") $auth.query)
  let req_body = {"display_scheme": $display_scheme, "label_format": $label_format, "label_layout": $label_layout, "ship_date": $ship_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Remove From Batch
#
# POST /v1/batches/{batch_id}/remove
# operationId: remove_from_batch
export def "remove-from-batch" [
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
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batch_id' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v1/batches/{batch_id}/remove") $auth.query)
  let req_body = {"rate_ids": $rate_ids, "shipment_ids": $shipment_ids} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# List Carriers
#
# GET /v1/carriers
# operationId: list_carriers
export def "list-carriers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<carriers: table<account_number: string, balance: float, carrier_code: string, carrier_id: string, friendly_name: string, has_multi_package_supporting_services: bool, nickname: string, options: list, packages: list, primary: bool, requires_funded_amount: bool, services: list, supports_label_messages: bool>, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/carriers" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-get $req $insecure $raw $allow_errors $full [200 207]
}

# Get Carrier By ID
#
# GET /v1/carriers/{carrier_id}
# operationId: get_carrier_by_id
export def "get-carrier-by-id" [
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
]: nothing -> oneof<record<account_number: string, balance: float, carrier_code: string, carrier_id: string, friendly_name: string, has_multi_package_supporting_services: bool, nickname: string, options: table<default_value: string, description: string, name: string>, packages: table<description: string, dimensions: record, name: string, package_code: string, package_id: string>, primary: bool, requires_funded_amount: bool, services: table<carrier_code: string, carrier_id: string, domestic: bool, international: bool, is_multi_package_supported: bool, name: string, service_code: string>, supports_label_messages: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/carriers/{carrier_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Add Funds To Carrier
#
# PUT /v1/carriers/{carrier_id}/add_funds
# operationId: add_funds_to_carrier
export def "add-funds-to-carrier" [
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
  currency: string # The currencies that are supported by ShipEngine are the ones that specified by ISO 4217: https://www.iso.org/iso-4217-currency-codes.html
]: any -> oneof<record<balance: record<amount: float, currency: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/carriers/{carrier_id}/add_funds") $auth.query)
  let req_body = {"amount": $amount, "currency": $currency} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Carrier Options
#
# GET /v1/carriers/{carrier_id}/options
# operationId: get_carrier_options
export def "get-carrier-options" [
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
]: nothing -> oneof<record<options: table<default_value: string, description: string, name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/carriers/{carrier_id}/options") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List Carrier Package Types
#
# GET /v1/carriers/{carrier_id}/packages
# operationId: list_carrier_package_types
export def "list-carrier-package-types" [
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
]: nothing -> oneof<record<packages: table<description: string, dimensions: record, name: string, package_code: string, package_id: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/carriers/{carrier_id}/packages") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List Carrier Services
#
# GET /v1/carriers/{carrier_id}/services
# operationId: list_carrier_services
export def "list-carrier-services" [
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
]: nothing -> oneof<record<services: table<carrier_code: string, carrier_id: string, domestic: bool, international: bool, is_multi_package_supported: bool, name: string, service_code: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/carriers/{carrier_id}/services") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Connect a carrier account
#
# POST /v1/connections/carriers/{carrier_name}
# operationId: connect_carrier
export def "connect-carrier" [
  carrier_name: string@carrier-name-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  nickname: string # The nickname associated with the carrier connection (e.g. Stamps.com)
  --password: string # Access Worldwide Password
  --username: string # Access Worldwide Username
  --email: string # An email address. (format: email)
  --merchant-seller-id: string
  --mws-auth-token: string
  --auth-code: string # Amazon UK Shipping auth code.
  --account-number: string # Asendia account number
  --ftp-password: string # FTP password
  --ftp-username: string # FTP username
  --api-key: string # API key
  --api-secret: string # API secret
  --contract-id: string # Canada Post Account Contract ID
  --ancillary-endorsement: string@ancillary-endorsement-completer # [Ancillary service endorsements](https://pe.usps.com/text/qsg300/Q507.htm) are used by mailers to request an addressee's new address and to provide the carrier with instructions on how to handle packages that are undeliverable as addressed. | Ancillary Service Endorsement | Description |--------------------------------|----------------------------------------------------- | `none` | No ancillary service is requested. Depending on the carrier servive, the package may be forwarded, returned, or discarded. | `return_service_requested` | The package is returned to the sender. If possible, notification of the new address is is included with the returned package. | `forwarding_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. | `address_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. This is similar to `forwarding_service_requested`, but different restrictions and charges may apply. | `change_service_requested` | The package is discarded. If possible, notification of the new address is sent to the sender. | `leave_if_no_response` |
  --client-id: string # The client id
  --distribution-center: string # The distribution center
  --pickup-number: string # The pickup number
  --registration-id: string
  --software-name: string
  --sold-to: string # Sold To field
  --country-code: string # A two-letter [ISO 3166-1 country code](https://en.wikipedia.org/wiki/ISO_3166-1)
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
  --mailer-id: string # A string that uniquely identifies the mailer
  --profile-name: string # Profile name
  --induction-site: string # Induction site
  --merchant-id: int # Merchant id (format: int32)
  --activation-key: string # Activation key
  --company-name: string # Company name
  --contact-name: string # Contact name
  --oba-email: string # The oba email address (format: email)
  --street-line1: string # Street line1
  --street-line2: string # Street line2
  --street-line3: string # Street line3
  --access-key: string # Seko Account Access Key
  --sendle-id: string # A string that uniquely identifies the sendle
  --account-country-code: string # Account country code
  --account-postal-code: string # Account postal code
  --agree-to-technology-agreement: oneof<nothing, bool> # The Agreement to the [UPS Technology Agreement](https://www.ups.com/assets/resources/media/UTA_with_EUR.pdf)
  --invoice: record # The UPS invoice — shape: {control_id?: string, invoice_amount?: float, invoice_currency_code?: string, invoice_date?: string, invoice_number?: string}
  --invoice-amount: float # The invoice amount (format: double)
  --invoice-currency-code: string # The invoice currency code
  --title: string # Title
]: any -> oneof<record<carrier_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_name | is-empty) { error make --unspanned { msg: "path parameter 'carrier_name' must be non-empty" } }
  let full_url = (build-url $base ({carrier_name: (encode-path-segment $carrier_name)} | format pattern "/v1/connections/carriers/{carrier_name}") $auth.query)
  let req_body = {"nickname": $nickname, "password": $password, "username": $username, "email": $email, "merchant_seller_id": $merchant_seller_id, "mws_auth_token": $mws_auth_token, "auth_code": $auth_code, "account_number": $account_number, "ftp_password": $ftp_password, "ftp_username": $ftp_username, "api_key": $api_key, "api_secret": $api_secret, "contract_id": $contract_id, "ancillary_endorsement": $ancillary_endorsement, "client_id": $client_id, "distribution_center": $distribution_center, "pickup_number": $pickup_number, "registration_id": $registration_id, "software_name": $software_name, "sold_to": $sold_to, "country_code": $country_code, "site_id": $site_id, "account": $account, "passphrase": $passphrase, "address1": $address1, "address2": $address2, "agree_to_eula": $agree_to_eula, "city": $city, "company": $company, "first_name": $first_name, "last_name": $last_name, "meter_number": $meter_number, "phone": $phone, "postal_code": $postal_code, "state": $state, "mailer_id": $mailer_id, "profile_name": $profile_name, "induction_site": $induction_site, "merchant_id": $merchant_id, "activation_key": $activation_key, "company_name": $company_name, "contact_name": $contact_name, "oba_email": $oba_email, "street_line1": $street_line1, "street_line2": $street_line2, "street_line3": $street_line3, "access_key": $access_key, "sendle_id": $sendle_id, "account_country_code": $account_country_code, "account_postal_code": $account_postal_code, "agree_to_technology_agreement": $agree_to_technology_agreement, "invoice": $invoice, "invoice_amount": $invoice_amount, "invoice_currency_code": $invoice_currency_code, "title": $title} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Disconnect a carrier
#
# DELETE /v1/connections/carriers/{carrier_name}/{carrier_id}
# operationId: disconnect_carrier
export def "disconnect-carrier" [
  carrier_name: string@carrier-name-completer
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_name | is-empty) { error make --unspanned { msg: "path parameter 'carrier_name' must be non-empty" } }
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_name: (encode-path-segment $carrier_name), carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/connections/carriers/{carrier_name}/{carrier_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get carrier settings
#
# GET /v1/connections/carriers/{carrier_name}/{carrier_id}/settings
# operationId: get_carrier_settings
export def "get-carrier-settings" [
  carrier_name: string@carrier-name-completer-1
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
  let full_url = (build-url $base ({carrier_name: (encode-path-segment $carrier_name), carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/connections/carriers/{carrier_name}/{carrier_id}/settings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Update carrier settings
#
# PUT /v1/connections/carriers/{carrier_name}/{carrier_id}/settings
# operationId: update_carrier_settings
export def "update-carrier-settings" [
  carrier_name: string@carrier-name-completer-1
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
  --is-primary-account: oneof<nothing, bool> # Indicates if this is primary account
  --nickname: string # Account nickname
  --should-hide-account-number-on-archive-doc: oneof<nothing, bool> # Indicates if the account number should be hidden on the archive documentation
  --letterhead-image: string
  --pickup-type: string@pickup-type-completer # Determines how FedEx will pickup your packages |Pickup Type |Description |--------------------------|----------------------------------------- |`none` | Not specified |`regular_pickup` | You already have a daily pickup scheduled with FedEx |`request_courier` | You will call FedEx to request a courier |`drop_box` | You will drop-off packages in a FedEx drop box |`business_service_center` | You will drop-off packages at an authorized FedEx business service center |`station` | You will drop-off the package at a FedEx Station
  --signature-image: string
  --smart-post-endorsement: string@smart-post-endorsement-completer # [Ancillary service endorsements](https://pe.usps.com/text/qsg300/Q507.htm) are used by mailers to request an addressee's new address and to provide the carrier with instructions on how to handle packages that are undeliverable as addressed. | Ancillary Service Endorsement | Description |--------------------------------|----------------------------------------------------- | `none` | No ancillary service is requested. Depending on the carrier servive, the package may be forwarded, returned, or discarded. | `return_service_requested` | The package is returned to the sender. If possible, notification of the new address is is included with the returned package. | `forwarding_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. | `address_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. This is similar to `forwarding_service_requested`, but different restrictions and charges may apply. | `change_service_requested` | The package is discarded. If possible, notification of the new address is sent to the sender. | `leave_if_no_response` |
  --smart-post-hub: string@smart-post-hub-completer # The possible smart post hub values
  --include-barcode-with-order-number: oneof<nothing, bool>
  --receive-email-on-manifest-processing: oneof<nothing, bool>
  --account-postal-code: string # account postal code
  --invoice: record # The invoice — shape: {control_id?: string, invoice_amount?: float, invoice_currency_code?: string, invoice_date?: string, invoice_number?: string}
  --mail-innovations-cost-center: string # mail innovations cost center
  --mail-innovations-endorsement: string@mail-innovations-endorsement-completer # [Ancillary service endorsements](https://pe.usps.com/text/qsg300/Q507.htm) are used by mailers to request an addressee's new address and to provide the carrier with instructions on how to handle packages that are undeliverable as addressed. | Ancillary Service Endorsement | Description |--------------------------------|----------------------------------------------------- | `none` | No ancillary service is requested. Depending on the carrier servive, the package may be forwarded, returned, or discarded. | `return_service_requested` | The package is returned to the sender. If possible, notification of the new address is is included with the returned package. | `forwarding_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. | `address_service_requested` | Forward the package to the new address, if possible; otherwise, return it to the sender. This is similar to `forwarding_service_requested`, but different restrictions and charges may apply. | `change_service_requested` | The package is discarded. If possible, notification of the new address is sent to the sender. | `leave_if_no_response` |
  --use-carbon-neutral-shipping-program: oneof<nothing, bool> # The use carbon neutral shipping program
  --use-consolidation-services: oneof<nothing, bool> # The use consolidation services
  --use-ground-freight-pricing: oneof<nothing, bool> # The use ground freight pricing
  --use-negotiated-rates: oneof<nothing, bool> # The use negotiated rates
  --use-order-number-on-mail-innovations-labels: oneof<nothing, bool> # The use order number on mail innovations labels
  --email: string # Email
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_name | is-empty) { error make --unspanned { msg: "path parameter 'carrier_name' must be non-empty" } }
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrier_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_name: (encode-path-segment $carrier_name), carrier_id: (encode-path-segment $carrier_id)} | format pattern "/v1/connections/carriers/{carrier_name}/{carrier_id}/settings") $auth.query)
  let req_body = {"is_primary_account": $is_primary_account, "nickname": $nickname, "should_hide_account_number_on_archive_doc": $should_hide_account_number_on_archive_doc, "letterhead_image": $letterhead_image, "pickup_type": $pickup_type, "signature_image": $signature_image, "smart_post_endorsement": $smart_post_endorsement, "smart_post_hub": $smart_post_hub, "include_barcode_with_order_number": $include_barcode_with_order_number, "receive_email_on_manifest_processing": $receive_email_on_manifest_processing, "account_postal_code": $account_postal_code, "invoice": $invoice, "mail_innovations_cost_center": $mail_innovations_cost_center, "mail_innovations_endorsement": $mail_innovations_endorsement, "use_carbon_neutral_shipping_program": $use_carbon_neutral_shipping_program, "use_consolidation_services": $use_consolidation_services, "use_ground_freight_pricing": $use_ground_freight_pricing, "use_negotiated_rates": $use_negotiated_rates, "use_order_number_on_mail_innovations_labels": $use_order_number_on_mail_innovations_labels, "email": $email} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Disconnect a Shipsurance Account
#
# DELETE /v1/connections/insurance/shipsurance
# operationId: disconnect_insurer
export def "disconnect-insurer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/insurance/shipsurance" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Connect a Shipsurance Account
#
# POST /v1/connections/insurance/shipsurance
# operationId: connect_insurer
export def "connect-insurer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # An email address. (format: email)
  policy_id: string
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/insurance/shipsurance" $auth.query)
  let req_body = {"email": $email, "policy_id": $policy_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Download File
#
# GET /v1/downloads/{dir}/{subdir}/{filename}
# operationId: download_file
export def "download-file" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($dir | is-empty) { error make --unspanned { msg: "path parameter 'dir' must be non-empty" } }
  if ($subdir | is-empty) { error make --unspanned { msg: "path parameter 'subdir' must be non-empty" } }
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "rotation" $rotation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dir: (encode-path-segment $dir), subdir: (encode-path-segment $subdir), filename: (encode-path-segment $filename)} | format pattern "/v1/downloads/{dir}/{subdir}/{filename}") $qp $auth.query)
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"download": $download, "rotation": $rotation} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Webhooks
#
# GET /v1/environment/webhooks
# operationId: list_webhooks
export def "list-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<event: string, url: string, webhook_id: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environment/webhooks" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Create a Webhook
#
# POST /v1/environment/webhooks
# operationId: create_webhook
export def "create-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: string@event-completer # The possible webook event values
  url: string # The url that the webhook sends the request to (format: url, e.g. https://[YOUR ENDPOINT ID].x.requestbin.com)
]: any -> oneof<record<event: string, url: string, webhook_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environment/webhooks" $auth.query)
  let req_body = {"event": $event, "url": $url} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Delete Webhook By ID
#
# DELETE /v1/environment/webhooks/{webhook_id}
# operationId: delete_webhook
export def "delete-webhook" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($webhook_id | is-empty) { error make --unspanned { msg: "path parameter 'webhook_id' must be non-empty" } }
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/v1/environment/webhooks/{webhook_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Webhook By ID
#
# GET /v1/environment/webhooks/{webhook_id}
# operationId: get_webhook_by_id
export def "get-webhook-by-id" [
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
]: nothing -> oneof<record<event: string, url: string, webhook_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($webhook_id | is-empty) { error make --unspanned { msg: "path parameter 'webhook_id' must be non-empty" } }
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/v1/environment/webhooks/{webhook_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Update a Webhook
#
# PUT /v1/environment/webhooks/{webhook_id}
# operationId: update_webhook
export def "update-webhook" [
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
  --url: string # The url that the wehbook sends the request (format: url, e.g. https://[YOUR ENDPOINT ID].x.requestbin.com)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($webhook_id | is-empty) { error make --unspanned { msg: "path parameter 'webhook_id' must be non-empty" } }
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/v1/environment/webhooks/{webhook_id}") $auth.query)
  let req_body = {"url": $url} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Add Funds To Insurance
#
# PATCH /v1/insurance/shipsurance/add_funds
# operationId: add_funds_to_insurance
export def "add-funds-to-insurance" [
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
  currency: string # The currencies that are supported by ShipEngine are the ones that specified by ISO 4217: https://www.iso.org/iso-4217-currency-codes.html
]: any -> oneof<record<amount: float, currency: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/insurance/shipsurance/add_funds" $auth.query)
  let req_body = {"amount": $amount, "currency": $currency} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Insurance Funds Balance
#
# GET /v1/insurance/shipsurance/balance
# operationId: get_insurance_balance
export def "get-insurance-balance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<amount: float, currency: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/insurance/shipsurance/balance" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List labels
#
# GET /v1/labels
# operationId: list_labels
export def "list-labels" [
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
]: nothing -> oneof<record<labels: table<alternative_identifiers: list, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record, insurance_claim: record, insurance_cost: record, is_international: bool, is_return_label: bool, label_download: record, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: list, rma_number: string, service_code: string, ship_date: string, shipment: record, shipment_cost: record, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>, links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, total: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "label_status" $label_status "scalar") (serialize-qp "service_code" $service_code "scalar") (serialize-qp "carrier_id" $carrier_id "scalar") (serialize-qp "tracking_number" $tracking_number "scalar") (serialize-qp "batch_id" $batch_id "scalar") (serialize-qp "rate_id" $rate_id "scalar") (serialize-qp "shipment_id" $shipment_id "scalar") (serialize-qp "warehouse_id" $warehouse_id "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/labels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"label_status": $label_status, "service_code": $service_code, "carrier_id": $carrier_id, "tracking_number": $tracking_number, "batch_id": $batch_id, "rate_id": $rate_id, "shipment_id": $shipment_id, "warehouse_id": $warehouse_id, "created_at_start": $created_at_start, "created_at_end": $created_at_end, "page": $page, "page_size": $page_size, "sort_dir": $sort_dir, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Purchase Label
#
# POST /v1/labels
# operationId: create_label
@deprecated --flag test-label
export def "create-label" [
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
  --charge-event: string@charge-event-completer # The label charge event.
  --display-scheme: string@display-scheme-completer # The display format that the label should be shown in. (default: label)
  --is-return-label: oneof<nothing, bool> # Indicates whether this is a return label. You may also want to set the `rma_number` so you know what is being returned.
  --label-download-type: string@label-download-type-completer # There are two different ways to [download a label](https://www.shipengine.com/docs/labels/downloading/): |Label Download Type | Description |--------------------|------------------------------ |`url` |You will receive a URL, which you can use to download the label in a separate request. The URL will remain valid for 90 days.This is the default if `label_download_type` is unspecified. |`inline` |You will receive the Base64-encoded label as part of the response. No need for a second request to download the label. (default: url)
  --label-format: string@label-format-completer # The file format that you want the label to be in. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. (default: pdf)
  --label-image-id: string # The label image resource that was used to create a custom label image. (nullable)
  --label-layout: string@label-layout-completer # The layout (size) that you want the label to be in. The `label_format` determines which sizes are allowed. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
  --outbound-label-id: string # The `label_id` of the original (outgoing) label that the return label is for. This associates the two labels together, which is required by some carriers.
  --rma-number: string # An optional Return Merchandise Authorization number. This field is useful for return labels. You can set it to any string value. (nullable)
  shipment: record # The shipment information used to generate the label — shape: {advanced_options: record, carrier_id: string, confirmation: "none"|"delivery"|"signature"|"adult_signature"|"direct_signature"|"delivery_mailed"|"verbal_confirmation", customs: record, external_order_id?: string, external_shipment_id?: string, insurance_provider: "none"|"shipsurance"|"carrier"|"third_party", items?: list, ... (11 more fields)}
  --test-label: oneof<nothing, bool> # Indicate if this label is being used only for testing purposes. If true, then no charge will be added to your account. (DEPRECATED, default: false)
  --validate-address: string@validate-address-completer # The possible validate address values (default: validate_and_clean)
]: any -> oneof<record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/labels" $auth.query)
  let req_body = {"ship_from_service_point_id": $ship_from_service_point_id, "ship_to_service_point_id": $ship_to_service_point_id, "charge_event": $charge_event, "display_scheme": $display_scheme, "is_return_label": $is_return_label, "label_download_type": $label_download_type, "label_format": $label_format, "label_image_id": $label_image_id, "label_layout": $label_layout, "outbound_label_id": $outbound_label_id, "rma_number": $rma_number, "shipment": $shipment, "test_label": $test_label, "validate_address": $validate_address} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Label By External Shipment ID
#
# GET /v1/labels/external_shipment_id/{external_shipment_id}
# operationId: get_label_by_external_shipment_id
export def "get-label-by-external-shipment-id" [
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
]: nothing -> oneof<record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($external_shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'external_shipment_id' must be non-empty" } }
  let qp = [(serialize-qp "label_download_type" $label_download_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_shipment_id: (encode-path-segment $external_shipment_id)} | format pattern "/v1/labels/external_shipment_id/{external_shipment_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"label_download_type": $label_download_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Purchase Label with Rate ID
#
# POST /v1/labels/rates/{rate_id}
# operationId: create_label_from_rate
export def "create-label-from-rate" [
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
  --display-scheme: string@display-scheme-completer # The display format that the label should be shown in. (default: label)
  --label-download-type: string@label-download-type-completer # There are two different ways to [download a label](https://www.shipengine.com/docs/labels/downloading/): |Label Download Type | Description |--------------------|------------------------------ |`url` |You will receive a URL, which you can use to download the label in a separate request. The URL will remain valid for 90 days.This is the default if `label_download_type` is unspecified. |`inline` |You will receive the Base64-encoded label as part of the response. No need for a second request to download the label.
  --label-format: string@label-format-completer # The possible file formats in which shipping labels can be downloaded. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. |Label Format | Supported Carriers |--------------|----------------------------------- |`pdf` | All carriers |`png` | `fedex` `stamps_com` `ups` `usps` |`zpl` | `access_worldwide` `apc` `asendia` `dhl_global_mail` `dhl_express` `dhl_express_australia` `dhl_express_canada` `dhl_express_worldwide` `dhl_express_uk` `dpd` `endicia` `fedex` `fedex_uk` `firstmile` `imex` `newgistics` `ontrac` `rr_donnelley` `stamps_com` `ups` `usps` (default: pdf)
  --label-layout: string@label-layout-completer # The available layouts (sizes) in which shipping labels can be downloaded. The label format determines which sizes are supported. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
  --validate-address: string@validate-address-completer # The possible validate address values
]: any -> oneof<record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($rate_id | is-empty) { error make --unspanned { msg: "path parameter 'rate_id' must be non-empty" } }
  let full_url = (build-url $base ({rate_id: (encode-path-segment $rate_id)} | format pattern "/v1/labels/rates/{rate_id}") $auth.query)
  let req_body = {"display_scheme": $display_scheme, "label_download_type": $label_download_type, "label_format": $label_format, "label_layout": $label_layout, "validate_address": $validate_address} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Purchase Label with Shipment ID
#
# POST /v1/labels/shipment/{shipment_id}
# operationId: create_label_from_shipment
export def "create-label-from-shipment" [
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
  --display-scheme: string@display-scheme-completer # The display format that the label should be shown in. (default: label)
  --label-download-type: string@label-download-type-completer # There are two different ways to [download a label](https://www.shipengine.com/docs/labels/downloading/): |Label Download Type | Description |--------------------|------------------------------ |`url` |You will receive a URL, which you can use to download the label in a separate request. The URL will remain valid for 90 days.This is the default if `label_download_type` is unspecified. |`inline` |You will receive the Base64-encoded label as part of the response. No need for a second request to download the label.
  --label-format: string@label-format-completer # The possible file formats in which shipping labels can be downloaded. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. |Label Format | Supported Carriers |--------------|----------------------------------- |`pdf` | All carriers |`png` | `fedex` `stamps_com` `ups` `usps` |`zpl` | `access_worldwide` `apc` `asendia` `dhl_global_mail` `dhl_express` `dhl_express_australia` `dhl_express_canada` `dhl_express_worldwide` `dhl_express_uk` `dpd` `endicia` `fedex` `fedex_uk` `firstmile` `imex` `newgistics` `ontrac` `rr_donnelley` `stamps_com` `ups` `usps` (default: pdf)
  --label-layout: string@label-layout-completer # The available layouts (sizes) in which shipping labels can be downloaded. The label format determines which sizes are supported. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
  --validate-address: string@validate-address-completer # The possible validate address values
]: any -> oneof<record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/v1/labels/shipment/{shipment_id}") $auth.query)
  let req_body = {"display_scheme": $display_scheme, "label_download_type": $label_download_type, "label_format": $label_format, "label_layout": $label_layout, "validate_address": $validate_address} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Label By ID
#
# GET /v1/labels/{label_id}
# operationId: get_label_by_id
export def "get-label-by-id" [
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
]: nothing -> oneof<record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($label_id | is-empty) { error make --unspanned { msg: "path parameter 'label_id' must be non-empty" } }
  let qp = [(serialize-qp "label_download_type" $label_download_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({label_id: (encode-path-segment $label_id)} | format pattern "/v1/labels/{label_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"label_download_type": $label_download_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a return label
#
# POST /v1/labels/{label_id}/return
# operationId: create_return_label
export def "create-return-label" [
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
  --charge-event: string@charge-event-completer # The label charge event.
  --display-scheme: string@display-scheme-completer # The display format that the label should be shown in. (default: label)
  --label-download-type: string@label-download-type-completer # There are two different ways to [download a label](https://www.shipengine.com/docs/labels/downloading/): |Label Download Type | Description |--------------------|------------------------------ |`url` |You will receive a URL, which you can use to download the label in a separate request. The URL will remain valid for 90 days.This is the default if `label_download_type` is unspecified. |`inline` |You will receive the Base64-encoded label as part of the response. No need for a second request to download the label. (default: url)
  --label-format: string@label-format-completer # The file format that you want the label to be in. We recommend `pdf` format because it is supported by all carriers, whereas some carriers do not support the `png` or `zpl` formats. (default: pdf)
  --label-image-id: string # The label image resource that was used to create a custom label image. (nullable)
  --label-layout: string@label-layout-completer # The layout (size) that you want the label to be in. The `label_format` determines which sizes are allowed. `4x6` is supported for all label formats, whereas `letter` (8.5" x 11") is only supported for `pdf` format. (default: 4x6)
]: any -> oneof<record<alternative_identifiers: table<type: string, value: string>, batch_id: string, carrier_code: string, carrier_id: string, charge_event: string, created_at: string, display_scheme: string, form_download: record<href: string, type: string>, insurance_claim: record<href: string, type: string>, insurance_cost: record<amount: float, currency: string>, is_international: bool, is_return_label: bool, label_download: record<href: string, pdf: string, png: string, zpl: string>, label_download_type: string, label_format: string, label_id: string, label_image_id: string, label_layout: string, outbound_label_id: string, package_code: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, rma_number: string, service_code: string, ship_date: string, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>, shipment_cost: record<amount: float, currency: string>, shipment_id: string, status: string, test_label: bool, trackable: bool, tracking_number: string, tracking_status: string, validate_address: string, voided: bool, voided_at: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($label_id | is-empty) { error make --unspanned { msg: "path parameter 'label_id' must be non-empty" } }
  let full_url = (build-url $base ({label_id: (encode-path-segment $label_id)} | format pattern "/v1/labels/{label_id}/return") $auth.query)
  let req_body = {"charge_event": $charge_event, "display_scheme": $display_scheme, "label_download_type": $label_download_type, "label_format": $label_format, "label_image_id": $label_image_id, "label_layout": $label_layout} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Label Tracking Information
#
# GET /v1/labels/{label_id}/track
# operationId: get_tracking_log_from_label
export def "get-tracking-log-from-label" [
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
]: nothing -> oneof<record<actual_delivery_date: string, carrier_code: string, carrier_detail_code: string, carrier_id: string, carrier_status_code: string, carrier_status_description: string, estimated_delivery_date: string, events: table<carrier_detail_code: string, carrier_occurred_at: string, carrier_status_code: string, carrier_status_description: string, city_locality: string, company_name: string, country_code: string, description: string, event_code: string, latitude: float, longitude: float, occurred_at: string, postal_code: string, signer: string, state_province: string, status_code: string, status_description: string>, exception_description: string, ship_date: string, status_code: string, status_description: string, tracking_number: string, tracking_url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($label_id | is-empty) { error make --unspanned { msg: "path parameter 'label_id' must be non-empty" } }
  let full_url = (build-url $base ({label_id: (encode-path-segment $label_id)} | format pattern "/v1/labels/{label_id}/track") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Void a Label By ID
#
# PUT /v1/labels/{label_id}/void
# operationId: void_label
export def "void-label" [
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
]: nothing -> oneof<record<approved: bool, message: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($label_id | is-empty) { error make --unspanned { msg: "path parameter 'label_id' must be non-empty" } }
  let full_url = (build-url $base ({label_id: (encode-path-segment $label_id)} | format pattern "/v1/labels/{label_id}/void") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# List Manifests
#
# GET /v1/manifests
# operationId: list_manifests
export def "list-manifests" [
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
]: nothing -> oneof<record<links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, manifests: table<carrier_id: string, created_at: string, form_id: string, label_ids: list, manifest_download: record, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>, page: int, pages: int, total: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "warehouse_id" $warehouse_id "scalar") (serialize-qp "ship_date_start" $ship_date_start "scalar") (serialize-qp "ship_date_end" $ship_date_end "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "carrier_id" $carrier_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "label_ids" $label_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/manifests" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"warehouse_id": $warehouse_id, "ship_date_start": $ship_date_start, "ship_date_end": $ship_date_end, "created_at_start": $created_at_start, "created_at_end": $created_at_end, "carrier_id": $carrier_id, "page": $page, "page_size": $page_size, "label_ids": $label_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Manifest
#
# POST /v1/manifests
# operationId: create_manifest
export def "create-manifest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --carrier-id: string # A string that uniquely identifies the carrier
  --excluded-label-ids: list # The list of label ids to exclude from the manifest
  --label-ids: list # The list of label ids to include for the manifest
  --ship-date: string # The ship date that the shipment will be sent out on (format: date-time, e.g. 2018-09-23T15:00:00.000Z)
  --warehouse-id: string # A string that uniquely identifies the warehouse
]: any -> oneof<record<manifests: table<carrier_id: string, created_at: string, form_id: string, label_ids: list, manifest_download: record, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>, manifest_requests: table<manifest_request_id: string, status: string>, carrier_id: string, created_at: string, form_id: string, label_ids: list<string>, manifest_download: record<href: string>, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/manifests" $auth.query)
  let req_body = {"carrier_id": $carrier_id, "excluded_label_ids": $excluded_label_ids, "label_ids": $label_ids, "ship_date": $ship_date, "warehouse_id": $warehouse_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Manifest Request By Id
#
# GET /v1/manifests/requests/{manifest_request_id}
# operationId: get_manifest_request_by_id
export def "get-manifest-request-by-id" [
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
]: nothing -> oneof<record<manifests: table<carrier_id: string, created_at: string, form_id: string, label_ids: list, manifest_download: record, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>, manifest_requests: table<manifest_request_id: string, status: string>, carrier_id: string, created_at: string, form_id: string, label_ids: list<string>, manifest_download: record<href: string>, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($manifest_request_id | is-empty) { error make --unspanned { msg: "path parameter 'manifest_request_id' must be non-empty" } }
  let full_url = (build-url $base ({manifest_request_id: (encode-path-segment $manifest_request_id)} | format pattern "/v1/manifests/requests/{manifest_request_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Manifest By Id
#
# GET /v1/manifests/{manifest_id}
# operationId: get_manifest_by_id
export def "get-manifest-by-id" [
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
]: nothing -> oneof<record<carrier_id: string, created_at: string, form_id: string, label_ids: list<string>, manifest_download: record<href: string>, manifest_id: string, ship_date: string, shipments: int, submission_id: string, warehouse_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($manifest_id | is-empty) { error make --unspanned { msg: "path parameter 'manifest_id' must be non-empty" } }
  let full_url = (build-url $base ({manifest_id: (encode-path-segment $manifest_id)} | format pattern "/v1/manifests/{manifest_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List Custom Package Types
#
# GET /v1/packages
# operationId: list_package_types
export def "list-package-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<packages: table<description: string, dimensions: record, name: string, package_code: string, package_id: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/packages" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Create Custom Package Type
#
# POST /v1/packages
# operationId: create_package_type
export def "create-package-type" [
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
  --dimensions: record # The custom dimensions for the package. — shape: {height: float, length: float, unit: "inch"|"centimeter", width: float}
  name: string # e.g. laptop_box
  package_code: string # A [package type](https://www.shipengine.com/docs/reference/list-carrier-packages/), such as `thick_envelope`, `small_flat_rate_box`, `large_package`, etc. Use the code `package` for custom or unknown package types.
  --package-id: string # A string that uniquely identifies the package.
]: any -> oneof<record<description: string, dimensions: record<height: float, length: float, unit: string, width: float>, name: string, package_code: string, package_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/packages" $auth.query)
  let req_body = {"description": $description, "dimensions": $dimensions, "name": $name, "package_code": $package_code, "package_id": $package_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Delete A Custom Package By ID
#
# DELETE /v1/packages/{package_id}
# operationId: delete_package_type
export def "delete-package-type" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'package_id' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/v1/packages/{package_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Custom Package Type By ID
#
# GET /v1/packages/{package_id}
# operationId: get_package_type_by_id
export def "get-package-type-by-id" [
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
]: nothing -> oneof<record<description: string, dimensions: record<height: float, length: float, unit: string, width: float>, name: string, package_code: string, package_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'package_id' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/v1/packages/{package_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Update Custom Package Type By ID
#
# PUT /v1/packages/{package_id}
# operationId: update_package_type
export def "update-package-type" [
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
  --dimensions: record # The custom dimensions for the package. — shape: {height: float, length: float, unit: "inch"|"centimeter", width: float}
  name: string # e.g. laptop_box
  package_code: string # A [package type](https://www.shipengine.com/docs/reference/list-carrier-packages/), such as `thick_envelope`, `small_flat_rate_box`, `large_package`, etc. Use the code `package` for custom or unknown package types.
  --body-package-id: string # A string that uniquely identifies the package. (spec name: package_id)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'package_id' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/v1/packages/{package_id}") $auth.query)
  let req_body = {"description": $description, "dimensions": $dimensions, "name": $name, "package_code": $package_code, "package_id": $body_package_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List Scheduled Pickups
#
# GET /v1/pickups
# operationId: list_scheduled_pickups
export def "list-scheduled-pickups" [
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
]: nothing -> oneof<record<links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, pickups: table<cancelled_at: string, carrier_id: string, confirmation_number: string, contact_details: record, created_at: string, label_ids: list, pickup_address: record, pickup_id: string, pickup_notes: string, pickup_window: record, pickup_windows: list, warehouse_id: string>, total: int, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_id" $carrier_id "scalar") (serialize-qp "warehouse_id" $warehouse_id "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/pickups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"carrier_id": $carrier_id, "warehouse_id": $warehouse_id, "created_at_start": $created_at_start, "created_at_end": $created_at_end, "page": $page, "page_size": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Schedule a Pickup
#
# POST /v1/pickups
# operationId: schedule_pickup
export def "schedule-pickup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  contact_details: record # shape: {email: string, name: string, phone: string}
  label_ids: list # Label IDs that will be included in the pickup request
  --pickup-notes: string # Used by some carriers to give special instructions for a package pickup
  pickup_window: record # The desired time range for the package pickup. — shape: {end_at: string, start_at: string}
]: any -> oneof<record<cancelled_at: string, carrier_id: string, confirmation_number: string, contact_details: record<email: string, name: string, phone: string>, created_at: string, label_ids: list<string>, pickup_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, pickup_id: string, pickup_notes: string, pickup_window: record<end_at: string, start_at: string>, pickup_windows: table<end_at: string, start_at: string>, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/pickups" $auth.query)
  let req_body = {"contact_details": $contact_details, "label_ids": $label_ids, "pickup_notes": $pickup_notes, "pickup_window": $pickup_window} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Delete a Scheduled Pickup
#
# DELETE /v1/pickups/{pickup_id}
# operationId: delete_scheduled_pickup
export def "delete-scheduled-pickup" [
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
]: nothing -> oneof<record<errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string, pickup_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($pickup_id | is-empty) { error make --unspanned { msg: "path parameter 'pickup_id' must be non-empty" } }
  let full_url = (build-url $base ({pickup_id: (encode-path-segment $pickup_id)} | format pattern "/v1/pickups/{pickup_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Pickup By ID
#
# GET /v1/pickups/{pickup_id}
# operationId: get_pickup_by_id
export def "get-pickup-by-id" [
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
]: nothing -> oneof<record<cancelled_at: string, carrier_id: string, confirmation_number: string, contact_details: record<email: string, name: string, phone: string>, created_at: string, label_ids: list<string>, pickup_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, pickup_id: string, pickup_notes: string, pickup_window: record<end_at: string, start_at: string>, pickup_windows: table<end_at: string, start_at: string>, warehouse_id: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, request_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($pickup_id | is-empty) { error make --unspanned { msg: "path parameter 'pickup_id' must be non-empty" } }
  let full_url = (build-url $base ({pickup_id: (encode-path-segment $pickup_id)} | format pattern "/v1/pickups/{pickup_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Shipping Rates
#
# POST /v1/rates
# operationId: calculate_rates
export def "calculate-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rate-options: record # The rate options — shape: {calculate_tax_amount?: bool, carrier_ids: list, is_return?: bool, package_types?: list<string>, preferred_currency?: string, service_codes?: list<string>}
  shipment_id: string # A string that uniquely identifies the shipment
  shipment: record # The shipment object — shape: {validate_address?: "no_validation"|"validate_only"|"validate_and_clean", advanced_options?: record, carrier_id: string, confirmation?: "none"|"delivery"|"signature"|"adult_signature"|"direct_signature"|"delivery_mailed"|"verbal_confirmation", customs?: record, external_order_id?: string, external_shipment_id?: string, insurance_provider?: "none"|"shipsurance"|"carrier"|"third_party", items?: list, ... (11 more fields)}
]: any -> oneof<record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string, rate_response: record<created_at: string, errors: list<record>, invalid_rates: list<record>, rate_request_id: string, rates: list<record>, shipment_id: string, status: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rates" $auth.query)
  let req_body = {"rate_options": $rate_options, "shipment_id": $shipment_id, "shipment": $shipment} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Bulk Rates
#
# POST /v1/rates/bulk
# operationId: compare_bulk_rates
export def "compare-bulk-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rate_options: record # The rate options — shape: {calculate_tax_amount?: bool, carrier_ids: list, is_return?: bool, package_types?: list<string>, preferred_currency?: string, service_codes?: list<string>}
  --shipment-ids: list # The array of shipment IDs
  --shipments: list # The array of shipments to get bulk rate estimates for — item shape: {validate_address?: "no_validation"|"validate_only"|"validate_and_clean", advanced_options?: record, carrier_id: string, confirmation?: "none"|"delivery"|"signature"|"adult_signature"|"direct_signature"|"delivery_mailed"|"verbal_confirmation", customs?: record, external_order_id?: string, external_shipment_id?: string, insurance_provider?: "none"|"shipsurance"|"carrier"|"third_party", items?: list, ... (11 more fields)}
]: any -> oneof<table<created_at: string, errors: list<record>, rate_request_id: string, shipment_id: string, status: string>, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rates/bulk" $auth.query)
  let req_body = {"rate_options": $rate_options, "shipment_ids": $shipment_ids, "shipments": $shipments} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Estimate Rates
#
# POST /v1/rates/estimate
# operationId: estimate_rates
@deprecated --flag carrier-id
export def "estimate-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-residential-indicator: string@address-residential-indicator-completer # Indicates whether an address is residential.
  --confirmation: string@confirmation-completer # The possible delivery confirmation values
  --dimensions: record # The dimensions of the package — shape: {height: float, length: float, unit: "inch"|"centimeter", width: float}
  from_city_locality: string # from postal code (e.g. Austin)
  from_country_code: string # A two-letter [ISO 3166-1 country code](https://en.wikipedia.org/wiki/ISO_3166-1)
  from_postal_code: string # postal code
  from_state_province: string # From state province (e.g. Austin)
  ship_date: string # ship date (format: date-time)
  to_city_locality: string # The city locality the package is being shipped to (e.g. Austin)
  to_country_code: string # A two-letter [ISO 3166-1 country code](https://en.wikipedia.org/wiki/ISO_3166-1)
  to_postal_code: string # postal code
  to_state_province: string # To state province (e.g. Houston)
  weight: record # The weight of the package — shape: {unit: "pound"|"ounce"|"gram"|"kilogram", value: float}
  --carrier-id: string # A string that uniquely identifies the carrier (DEPRECATED)
  --carrier-ids: list<string> # Array of Carrier Ids
]: any -> oneof<table<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record<amount: float, currency: string>, delivery_days: int, error_messages: list<string>, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record<amount: float, currency: string>, negotiated_rate: bool, other_amount: record<amount: float, currency: string>, package_type: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record<amount: float, currency: string>, tax_amount: record<amount: float, currency: string>, trackable: bool, validation_status: string, warning_messages: list<string>, zone: int>, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rates/estimate" $auth.query)
  let req_body = {"address_residential_indicator": $address_residential_indicator, "confirmation": $confirmation, "dimensions": $dimensions, "from_city_locality": $from_city_locality, "from_country_code": $from_country_code, "from_postal_code": $from_postal_code, "from_state_province": $from_state_province, "ship_date": $ship_date, "to_city_locality": $to_city_locality, "to_country_code": $to_country_code, "to_postal_code": $to_postal_code, "to_state_province": $to_state_province, "weight": $weight, "carrier_id": $carrier_id, "carrier_ids": $carrier_ids} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Rate By ID
#
# GET /v1/rates/{rate_id}
# operationId: get_rate_by_id
export def "get-rate-by-id" [
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
]: nothing -> oneof<record<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record<amount: float, currency: string>, delivery_days: int, error_messages: list<string>, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record<amount: float, currency: string>, negotiated_rate: bool, other_amount: record<amount: float, currency: string>, package_type: string, rate_id: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record<amount: float, currency: string>, tax_amount: record<amount: float, currency: string>, trackable: bool, validation_status: string, warning_messages: list<string>, zone: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($rate_id | is-empty) { error make --unspanned { msg: "path parameter 'rate_id' must be non-empty" } }
  let full_url = (build-url $base ({rate_id: (encode-path-segment $rate_id)} | format pattern "/v1/rates/{rate_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List Service Points
#
# POST /v1/service_points/list
# operationId: service_points_list
export def "service-points-list" [
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
  providers: list # An array of shipping service providers and service codes — item shape: {carrier_id?: string, service_code?: list<string>}
  --radius: int # Search radius in kilometers (format: int32, e.g. 500)
]: any -> oneof<record<errors: table<error_code: string, error_source: string, error_type: string, message: string>, lat: float, long: float, service_points: table<address_line1: string, carrier_code: string, city_locality: string, company_name: string, country_code: string, distance_in_meters: float, features: list, hours_of_operation: record, lat: float, long: float, phone_number: string, postal_code: string, service_codes: list, service_point_id: string, state_province: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/service_points/list" $auth.query)
  let req_body = {"address": $address, "address_query": $address_query, "lat": $lat, "long": $long, "max_results": $max_results, "providers": $providers, "radius": $radius} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Service Point By ID
#
# GET /v1/service_points/{carrier_code}/{country_code}/{service_point_id}
# operationId: service_points_get_by_id
export def "service-points-get-by-id" [
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
]: nothing -> oneof<record<service_point: record<address_line1: string, carrier_code: string, city_locality: string, company_name: string, country_code: string, features: list<string>, hours_of_operation: record<friday: list, monday: list, saturday: list, sunday: list, thursday: list, tuesday: list, wednesday: list>, lat: float, long: float, phone_number: string, postal_code: string, service_codes: list<string>, service_point_id: string, state_province: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($carrier_code | is-empty) { error make --unspanned { msg: "path parameter 'carrier_code' must be non-empty" } }
  if ($country_code | is-empty) { error make --unspanned { msg: "path parameter 'country_code' must be non-empty" } }
  if ($service_point_id | is-empty) { error make --unspanned { msg: "path parameter 'service_point_id' must be non-empty" } }
  let full_url = (build-url $base ({carrier_code: (encode-path-segment $carrier_code), country_code: (encode-path-segment $country_code), service_point_id: (encode-path-segment $service_point_id)} | format pattern "/v1/service_points/{carrier_code}/{country_code}/{service_point_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List Shipments
#
# GET /v1/shipments
# operationId: list_shipments
export def "list-shipments" [
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
]: nothing -> oneof<record<links: record<first: record<href: string, type: string>, last: record<href: string, type: string>, next: record<href: string, type: string>, prev: record<href: string, type: string>>, page: int, pages: int, shipments: table<advanced_options: record, carrier_id: string, confirmation: string, created_at: string, customs: record, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list, modified_at: string, order_source_code: string, origin_type: string, packages: list, return_to: record, service_code: string, ship_date: string, ship_from: record, ship_to: record, shipment_id: string, shipment_number: string, shipment_status: string, tags: list, tax_identifiers: list, total_weight: record, warehouse_id: string>, total: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shipment_status" $shipment_status "scalar") (serialize-qp "batch_id" $batch_id "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "created_at_start" $created_at_start "scalar") (serialize-qp "created_at_end" $created_at_end "scalar") (serialize-qp "modified_at_start" $modified_at_start "scalar") (serialize-qp "modified_at_end" $modified_at_end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sales_order_id" $sales_order_id "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/shipments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"shipment_status": $shipment_status, "batch_id": $batch_id, "tag": $tag, "created_at_start": $created_at_start, "created_at_end": $created_at_end, "modified_at_start": $modified_at_start, "modified_at_end": $modified_at_end, "page": $page, "page_size": $page_size, "sales_order_id": $sales_order_id, "sort_dir": $sort_dir, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Shipments
#
# POST /v1/shipments
# operationId: create_shipments
export def "create-shipments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  shipments: list # An array of shipments to be created. — item shape: {validate_address?: "no_validation"|"validate_only"|"validate_and_clean", advanced_options?: record, carrier_id: string, confirmation?: "none"|"delivery"|"signature"|"adult_signature"|"direct_signature"|"delivery_mailed"|"verbal_confirmation", customs?: record, external_order_id?: string, external_shipment_id?: string, insurance_provider?: "none"|"shipsurance"|"carrier"|"third_party", items?: list, ... (11 more fields)}
]: any -> oneof<record<has_errors: bool, shipments: table<advanced_options: record, carrier_id: string, confirmation: string, created_at: string, customs: record, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list, modified_at: string, order_source_code: string, origin_type: string, packages: list, return_to: record, service_code: string, ship_date: string, ship_from: record, ship_to: record, shipment_id: string, shipment_number: string, shipment_status: string, tags: list, tax_identifiers: list, total_weight: record, warehouse_id: string, address_validation: record, errors: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/shipments" $auth.query)
  let req_body = {"shipments": $shipments} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Shipment By External ID
#
# GET /v1/shipments/external_shipment_id/{external_shipment_id}
# operationId: get_shipment_by_external_id
export def "get-shipment-by-external-id" [
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
]: nothing -> oneof<record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($external_shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'external_shipment_id' must be non-empty" } }
  let full_url = (build-url $base ({external_shipment_id: (encode-path-segment $external_shipment_id)} | format pattern "/v1/shipments/external_shipment_id/{external_shipment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Parse shipping info
#
# PUT /v1/shipments/recognize
# operationId: parse_shipment
export def "parse-shipment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shipment: record # You can optionally provide a `shipment` object containing any already-known values. For example, you probably already know the `ship_from` address, and you may also already know what carrier and service you want to use. — shape: {advanced_options?: record, carrier_id?: string, confirmation?: "none"|"delivery"|"signature"|"adult_signature"|"direct_signature"|"delivery_mailed"|"verbal_confirmation", customs?: record, external_order_id?: string, external_shipment_id?: string, insurance_provider?: "none"|"shipsurance"|"carrier"|"third_party", items?: list, ... (11 more fields)}
  text: string # The unstructured text that contains shipping-related entities (e.g. I have a 4oz package that's 5x10x14in, and I need to ship it to Margie McMiller at 3800 North Lamar suite 200 in austin, tx 78652. Please send it via USPS first class and require an adult signature. It also needs to be insured for $400. )
]: any -> oneof<record<entities: table<end_index: int, result: record, score: float, start_index: int, text: string, type: string>, score: float, shipment: record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record, fedex_freight: record, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: list<record>, modified_at: string, order_source_code: string, origin_type: string, packages: list<record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: list<record>, tax_identifiers: list<record>, total_weight: record<unit: string, value: float>, warehouse_id: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/shipments/recognize" $auth.query)
  let req_body = {"shipment": $shipment, "text": $text} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Shipment By ID
#
# GET /v1/shipments/{shipment_id}
# operationId: get_shipment_by_id
export def "get-shipment-by-id" [
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
]: nothing -> oneof<record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/v1/shipments/{shipment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Update Shipment By ID
#
# PUT /v1/shipments/{shipment_id}
# operationId: update_shipment
export def "update-shipment" [
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
  --advanced-options: record # Advanced shipment options. These are entirely optional. — shape: {bill_to_account?: string, bill_to_country_code?: string, bill_to_party?: "recipient"|"third_party", bill_to_postal_code?: string, collect_on_delivery?: record, contains_alcohol?: bool, custom_field1?: string, custom_field2?: string, custom_field3?: string, delivered_duty_paid?: bool, dry_ice?: bool, dry_ice_weight?: record, fedex_freight?: record, freight_class?: string, non_machinable?: bool, origin_type?: "pickup"|"drop_off", saturday_delivery?: bool, shipper_release?: bool, ... (2 more fields)}
  --carrier-id: string # The carrier account that is billed for the shipping charges
  --confirmation: string@confirmation-completer # The type of delivery confirmation that is required for this shipment. (default: none)
  --customs: record # Customs information. This is usually only needed for international shipments. (nullable) — shape: {contents: "merchandise"|"documents"|"gift"|"returned_goods"|"sample", customs_items?: list, non_delivery: "return_to_sender"|"treat_as_abandoned"}
  --external-order-id: string # ID that the Order Source assigned (nullable)
  --external-shipment-id: string # A unique user-defined key to identify a shipment. This can be used to retrieve the shipment. > **Warning:** The `external_shipment_id` is limited to 50 characters. Any additional characters will be truncated. (nullable)
  --insurance-provider: string@insurance-provider-completer # The insurance provider to use for any insured packages in the shipment. (default: none)
  --items: list # Describe the packages included in this shipment as related to potential metadata that was imported from external order sources (default: []) — item shape: {asin?: string, external_order_id?: string, external_order_item_id?: string, name?: string, order_source_code?: "amazon_ca"|"amazon_us"|"brightpearl"|"channel_advisor"|"cratejoy"|"ebay"|"etsy"|"jane"|"groupon_goods"|"magento"|"paypal"|"seller_active"|"shopify"|"stitch_labs"|"squarespace"|"three_dcart"|"tophatter"|"walmart"|"woo_commerce"|"volusion", quantity?: int, sales_order_id?: string, sales_order_item_id?: string, sku?: string}
  --order-source-code: string@order-source-code-completer # The order sources that are supported by ShipEngine
  --origin-type: string@origin-type-completer # Indicates if the package will be picked up or dropped off by the carrier (nullable)
  --packages: list # The packages in the shipment. > **Note:** Some carriers only allow one package per shipment. If you attempt to create a multi-package shipment for a carrier that doesn't allow it, an error will be returned. — item shape: {content_description?: string, dimensions?: record, external_package_id?: string, insured_value?: record, label_messages?: record, package_code?: string, package_id?: string, weight: record}
  --return-to: record # The return address for this shipment. Defaults to the `ship_from` address. — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string, instructions?: string}
  --service-code: string # The [carrier service](https://www.shipengine.com/docs/shipping/use-a-carrier-service/) used to ship the package, such as `fedex_ground`, `usps_first_class_mail`, `flat_rate_envelope`, etc.
  --ship-date: string # The date that the shipment was (or will be) shippped. ShipEngine will take the day of week into consideration. For example, if the carrier does not operate on Sundays, then a package that would have shipped on Sunday will ship on Monday instead. (format: date-time)
  ship_from: record # The shipment's origin address. If you frequently ship from the same location, consider [creating a warehouse](https://www.shipengine.com/docs/reference/create-warehouse/). Then you can simply specify the `warehouse_id` rather than the complete address each time. — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string, instructions?: string}
  ship_to: record # The recipient's mailing address — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string, instructions?: string}
  --shipment-number: string # A non-unique user-defined number used to identify a shipment. If undefined, this will match the external_shipment_id of the shipment. > **Warning:** The `shipment_number` is limited to 50 characters. Any additional characters will be truncated. (nullable)
  --tax-identifiers: list # nullable — item shape: {identifier_type: "vat"|"eori"|"ssn"|"ein"|"tin"|"ioss"|"pan"|"voec", issuing_authority: string, taxable_entity_type: "shipper"|"recipient", value: string}
  --warehouse-id: string # The [warehouse](https://www.shipengine.com/docs/shipping/ship-from-a-warehouse/) that the shipment is being shipped from. Either `warehouse_id` or `ship_from` must be specified. (nullable)
  --validate-address: string@validate-address-completer # The possible validate address values (default: no_validation)
]: any -> oneof<record<advanced_options: record<bill_to_account: string, bill_to_country_code: string, bill_to_party: string, bill_to_postal_code: string, collect_on_delivery: record<payment_amount: record, payment_type: string>, contains_alcohol: bool, custom_field1: string, custom_field2: string, custom_field3: string, delivered_duty_paid: bool, dry_ice: bool, dry_ice_weight: record<unit: string, value: float>, fedex_freight: record<booking_confirmation: string, shipper_load_and_count: string>, freight_class: string, non_machinable: bool, origin_type: string, saturday_delivery: bool, shipper_release: bool, third_party_consignee: bool, use_ups_ground_freight_pricing: bool>, carrier_id: string, confirmation: string, created_at: string, customs: record<contents: string, customs_items: list<record>, non_delivery: string>, external_order_id: string, external_shipment_id: string, insurance_provider: string, items: table<asin: string, external_order_id: string, external_order_item_id: string, name: string, order_source_code: string, quantity: int, sales_order_id: string, sales_order_item_id: string, sku: string>, modified_at: string, order_source_code: string, origin_type: string, packages: table<content_description: string, dimensions: record, external_package_id: string, form_download: record, insured_value: record, label_download: record, label_messages: record, package_code: string, package_id: string, sequence: int, tracking_number: string, weight: record>, return_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, service_code: string, ship_date: string, ship_from: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, ship_to: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string, instructions: string>, shipment_id: string, shipment_number: string, shipment_status: string, tags: table<name: string>, tax_identifiers: table<identifier_type: string, issuing_authority: string, taxable_entity_type: string, value: string>, total_weight: record<unit: string, value: float>, warehouse_id: string, address_validation: record<matched_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, messages: list<record>, original_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, status: string>, errors: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/v1/shipments/{shipment_id}") $auth.query)
  let req_body = {"advanced_options": $advanced_options, "carrier_id": $carrier_id, "confirmation": $confirmation, "customs": $customs, "external_order_id": $external_order_id, "external_shipment_id": $external_shipment_id, "insurance_provider": $insurance_provider, "items": $items, "order_source_code": $order_source_code, "origin_type": $origin_type, "packages": $packages, "return_to": $return_to, "service_code": $service_code, "ship_date": $ship_date, "ship_from": $ship_from, "ship_to": $ship_to, "shipment_number": $shipment_number, "tax_identifiers": $tax_identifiers, "warehouse_id": $warehouse_id, "validate_address": $validate_address} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Cancel a Shipment
#
# PUT /v1/shipments/{shipment_id}/cancel
# operationId: cancel_shipments
export def "cancel-shipments" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/v1/shipments/{shipment_id}/cancel") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# Get Shipment Rates
#
# GET /v1/shipments/{shipment_id}/rates
# operationId: list_shipment_rates
export def "list-shipment-rates" [
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
]: nothing -> oneof<record<created_at: string, errors: table<error_code: string, error_source: string, error_type: string, message: string>, invalid_rates: table<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record, delivery_days: int, error_messages: list, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record, negotiated_rate: bool, other_amount: record, package_type: string, rate_id: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record, tax_amount: record, trackable: bool, validation_status: string, warning_messages: list, zone: int>, rate_request_id: string, rates: table<carrier_code: string, carrier_delivery_days: string, carrier_friendly_name: string, carrier_id: string, carrier_nickname: string, confirmation_amount: record, delivery_days: int, error_messages: list, estimated_delivery_date: string, guaranteed_service: bool, insurance_amount: record, negotiated_rate: bool, other_amount: record, package_type: string, rate_id: string, rate_type: string, service_code: string, service_type: string, ship_date: string, shipping_amount: record, tax_amount: record, trackable: bool, validation_status: string, warning_messages: list, zone: int>, shipment_id: string, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  let qp = [(serialize-qp "created_at_start" $created_at_start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/v1/shipments/{shipment_id}/rates") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"created_at_start": $created_at_start} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove Tag from Shipment
#
# DELETE /v1/shipments/{shipment_id}/tags/{tag_name}
# operationId: untag_shipment
export def "untag-shipment" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag_name' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id), tag_name: (encode-path-segment $tag_name)} | format pattern "/v1/shipments/{shipment_id}/tags/{tag_name}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Add Tag to Shipment
#
# POST /v1/shipments/{shipment_id}/tags/{tag_name}
# operationId: tag_shipment
export def "tag-shipment" [
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
]: nothing -> oneof<record<shipment_id: string, tag: record<name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($shipment_id | is-empty) { error make --unspanned { msg: "path parameter 'shipment_id' must be non-empty" } }
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag_name' must be non-empty" } }
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id), tag_name: (encode-path-segment $tag_name)} | format pattern "/v1/shipments/{shipment_id}/tags/{tag_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Tags
#
# GET /v1/tags
# operationId: list_tags
export def "list-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<tags: table<name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tags" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Delete Tag
#
# DELETE /v1/tags/{tag_name}
# operationId: delete_tag
export def "delete-tag" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag_name' must be non-empty" } }
  let full_url = (build-url $base ({tag_name: (encode-path-segment $tag_name)} | format pattern "/v1/tags/{tag_name}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Create a New Tag
#
# POST /v1/tags/{tag_name}
# operationId: create_tag
export def "create-tag" [
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
]: nothing -> oneof<record<name: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag_name' must be non-empty" } }
  let full_url = (build-url $base ({tag_name: (encode-path-segment $tag_name)} | format pattern "/v1/tags/{tag_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Update Tag Name
#
# PUT /v1/tags/{tag_name}/{new_tag_name}
# operationId: rename_tag
export def "rename-tag" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_name | is-empty) { error make --unspanned { msg: "path parameter 'tag_name' must be non-empty" } }
  if ($new_tag_name | is-empty) { error make --unspanned { msg: "path parameter 'new_tag_name' must be non-empty" } }
  let full_url = (build-url $base ({tag_name: (encode-path-segment $tag_name), new_tag_name: (encode-path-segment $new_tag_name)} | format pattern "/v1/tags/{tag_name}/{new_tag_name}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# Get Ephemeral Token
#
# POST /v1/tokens/ephemeral
# operationId: tokens_get_ephemeral_token
export def "tokens-get-ephemeral-token" [
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
]: nothing -> oneof<record<redirect_url: string, token: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirect" $redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tokens/ephemeral" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"redirect": $redirect} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Get Tracking Information
#
# GET /v1/tracking
# operationId: get_tracking_log
export def "get-tracking-log" [
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
]: nothing -> oneof<record<actual_delivery_date: string, carrier_code: string, carrier_detail_code: string, carrier_id: string, carrier_status_code: string, carrier_status_description: string, estimated_delivery_date: string, events: table<carrier_detail_code: string, carrier_occurred_at: string, carrier_status_code: string, carrier_status_description: string, city_locality: string, company_name: string, country_code: string, description: string, event_code: string, latitude: float, longitude: float, occurred_at: string, postal_code: string, signer: string, state_province: string, status_code: string, status_description: string>, exception_description: string, ship_date: string, status_code: string, status_description: string, tracking_number: string, tracking_url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_code" $carrier_code "scalar") (serialize-qp "tracking_number" $tracking_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tracking" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"carrier_code": $carrier_code, "tracking_number": $tracking_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Start Tracking a Package
#
# POST /v1/tracking/start
# operationId: start_tracking
export def "start-tracking" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_code" $carrier_code "scalar") (serialize-qp "tracking_number" $tracking_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tracking/start" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"carrier_code": $carrier_code, "tracking_number": $tracking_number} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Stop Tracking a Package
#
# POST /v1/tracking/stop
# operationId: stop_tracking
export def "stop-tracking" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "carrier_code" $carrier_code "scalar") (serialize-qp "tracking_number" $tracking_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tracking/stop" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"carrier_code": $carrier_code, "tracking_number": $tracking_number} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# List Warehouses
#
# GET /v1/warehouses
# operationId: list_warehouses
export def "list-warehouses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<warehouses: table<created_at: string, is_default: bool, name: string, origin_address: record, return_address: record, warehouse_id: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/warehouses" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Create Warehouse
#
# POST /v1/warehouses
# operationId: create_warehouse
export def "create-warehouse" [
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
  origin_address: record # The origin address of the warehouse — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string}
  --return-address: record # The return address associated with the warehouse — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string}
]: any -> oneof<record<created_at: string, is_default: bool, name: string, origin_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, return_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, warehouse_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/warehouses" $auth.query)
  let req_body = {"is_default": $is_default, "name": $name, "origin_address": $origin_address, "return_address": $return_address} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Delete Warehouse By ID
#
# DELETE /v1/warehouses/{warehouse_id}
# operationId: delete_warehouse
export def "delete-warehouse" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouse_id' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/v1/warehouses/{warehouse_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get Warehouse By Id
#
# GET /v1/warehouses/{warehouse_id}
# operationId: get_warehouse_by_id
export def "get-warehouse-by-id" [
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
]: nothing -> oneof<record<created_at: string, is_default: bool, name: string, origin_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, return_address: record<address_line1: string, address_line2: string, address_line3: string, address_residential_indicator: string, city_locality: string, company_name: string, country_code: string, email: string, name: string, phone: string, postal_code: string, state_province: string>, warehouse_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouse_id' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/v1/warehouses/{warehouse_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Update Warehouse By Id
#
# PUT /v1/warehouses/{warehouse_id}
# operationId: update_warehouse
export def "update-warehouse" [
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
  origin_address: record # The origin address of the warehouse — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string}
  --return-address: record # The return address associated with the warehouse — shape: {address_line1: string, address_line2?: string, address_line3?: string, address_residential_indicator: "unknown"|"yes"|"no", city_locality: string, company_name?: string, country_code: string, email?: string, name: string, phone: string, postal_code: string, state_province: string}
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouse_id' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/v1/warehouses/{warehouse_id}") $auth.query)
  let req_body = {"is_default": $is_default, "name": $name, "origin_address": $origin_address, "return_address": $return_address} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Update Warehouse Settings
#
# PUT /v1/warehouses/{warehouse_id}/settings
# operationId: update_warehouse_settings
export def "update-warehouse-settings" [
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
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouse_id' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/v1/warehouses/{warehouse_id}/settings") $auth.query)
  let req_body = {"is_default": $is_default} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}
