# Auto-generated client for Inventory Management v1.0.0
# Source: https://api.apis.guru/v2/specs/walmart.com/inventory/1.0.0/openapi.json
# Auth: --token flag or $env.INVENTORY_MANAGEMENT_TOKEN

const BASE_URL = "https://marketplace.walmartapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o INVENTORY_MANAGEMENT_TOKEN | default "" }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://marketplace.walmartapis.com" "https://sandbox.walmartapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def feed-type-completer [] { ["MP_INVENTORY" "inventory"] }
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "feeds update-bulk-inventory" } } | get name | first)
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

# Bulk Item Inventory Update
#
# POST /v3/feeds
# operationId: updateBulkInventory
export def "feeds update-bulk-inventory" [
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
  --feed-type: string@feed-type-completer # The feed Type
  --ship-node: string # The shipNode for which the inventory is to be updated. Not required in case of Multi Node Inventory Update Feed (feedType=MP_INVENTORY)
  --wm-sec-access-token: string # The access token retrieved in the Token API call (e.g. eyJraWQiOiIzZjVhYTFmNS1hYWE5LTQzM.....)
  --wm-consumer-channel-type: string # A unique ID to track the consumer request by channel. Use the Consumer Channel Type received during onboarding
  --wm-qos-correlation-id: string # A unique ID which identifies each API call and used to track and debug issues; use a random generated GUID for this ID (e.g. b3261d2d-028a-4ef7-8602-633c23200af6)
  --wm-svc-name: string # Walmart Service Name (e.g. Walmart Service Name)
  file: string # Feed file to upload (format: binary)
]: any -> record<additionalAttributes: record, errors: record, feedId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feedType" $feed_type "scalar") (serialize-qp "shipNode" $ship_node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/feeds" $qp $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: ({"feedType": $feed_type, "shipNode": $ship_node} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# WFS Inventory
#
# GET /v3/fulfillment/inventory
# operationId: getWFSInventory
export def "fulfillment-inventory get-wfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku: string # An arbitrary alphanumeric unique ID, specified by the seller, which identifies each item. This will be used by the seller in the XSD file to refer to each item. Special characters in the sku needing encoding are: ':', '/', '?', '#', '[', ']', '@', '!', '$', '&', "'", '(', ')', '*', '+', ',', ';', '=', ‘ ’ as well as '%' itself if it's a part of sku. Make sure to encode space with %20. Other characters don't need to be encoded.
  --from-modified-date: string # last inventory modified date - starting range.
  --to-modified-date: string # last inventory modified date - starting range.
  --limit: string # Number of Sku to be returned. Cannot be larger than 300. (default: 10)
  --offset: string # Offset is the number of records you wish to skip before selecting records. (default: 0)
  --wm-sec-access-token: string # The access token retrieved in the Token API call (e.g. eyJraWQiOiIzZjVhYTFmNS1hYWE5LTQzM.....)
  --wm-consumer-channel-type: string # A unique ID to track the consumer request by channel. Use the Consumer Channel Type received during onboarding
  --wm-qos-correlation-id: string # A unique ID which identifies each API call and used to track and debug issues; use a random generated GUID for this ID (e.g. b3261d2d-028a-4ef7-8602-633c23200af6)
  --wm-svc-name: string # Walmart Service Name (e.g. Walmart Service Name)
]: nothing -> record<headers: record<limit: int, offset: int, totalCount: int>, payload: record<inventory: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sku" $sku "scalar") (serialize-qp "fromModifiedDate" $from_modified_date "scalar") (serialize-qp "toModifiedDate" $to_modified_date "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/fulfillment/inventory" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sku": $sku, "fromModifiedDate": $from_modified_date, "toModifiedDate": $to_modified_date, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Multiple Item Inventory for All Ship Nodes
#
# GET /v3/inventories
# operationId: getMultiNodeInventoryForAllSkuAndAllShipNodes
export def "inventories get-multi-node-inventory-for-list-sku-and-ship-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # The number of items returned. Cannot be more than 50. (default: 10)
  --next-cursor: string # String returned from initial API call to indicate pagination. Specify nextCursor value to retrieve the next 50 items.
  --wm-sec-access-token: string # The access token retrieved in the Token API call (e.g. eyJraWQiOiIzZjVhYTFmNS1hYWE5LTQzM.....)
  --wm-consumer-channel-type: string # A unique ID to track the consumer request by channel. Use the Consumer Channel Type received during onboarding
  --wm-qos-correlation-id: string # A unique ID which identifies each API call and used to track and debug issues; use a random generated GUID for this ID (e.g. b3261d2d-028a-4ef7-8602-633c23200af6)
  --wm-svc-name: string # Walmart Service Name (e.g. Walmart Service Name)
]: nothing -> record<elements: record<inventories: list<record>>, meta: record<nextCursor: string, totalCount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "nextCursor" $next_cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/inventories" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "nextCursor": $next_cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Single Item Inventory by Ship Node
#
# GET /v3/inventories/{sku}
# operationId: getMultiNodeInventoryForSkuAndAllShipnodes
export def "inventories get-multi-node-inventory-for-and-list-shipnodes" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ship-node: string # ShipNode Id of the ship node for which the inventory is requested
  --wm-sec-access-token: string # The access token retrieved in the Token API call (e.g. eyJraWQiOiIzZjVhYTFmNS1hYWE5LTQzM.....)
  --wm-consumer-channel-type: string # A unique ID to track the consumer request by channel. Use the Consumer Channel Type received during onboarding
  --wm-qos-correlation-id: string # A unique ID which identifies each API call and used to track and debug issues; use a random generated GUID for this ID (e.g. b3261d2d-028a-4ef7-8602-633c23200af6)
  --wm-svc-name: string # Walmart Service Name (e.g. Walmart Service Name)
]: nothing -> record<nodes: table<availToSellQty: record, errors: list, inputQty: record, reservedQty: record, shipNode: string>, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sku | is-empty) { error make --unspanned { msg: "path parameter 'sku' must be non-empty" } }
  let qp = [(serialize-qp "shipNode" $ship_node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/v3/inventories/{sku}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"shipNode": $ship_node} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Item Inventory per Ship Node
#
# PUT /v3/inventories/{sku}
# operationId: updateMultiNodeInventory
# --inventories shape: {nodes: list}
export def "inventories update-multi-node-inventory" [
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --wm-sec-access-token: string # The access token retrieved in the Token API call (e.g. eyJraWQiOiIzZjVhYTFmNS1hYWE5LTQzM.....)
  --wm-consumer-channel-type: string # A unique ID to track the consumer request by channel. Use the Consumer Channel Type received during onboarding
  --wm-qos-correlation-id: string # A unique ID which identifies each API call and used to track and debug issues; use a random generated GUID for this ID (e.g. b3261d2d-028a-4ef7-8602-633c23200af6)
  --wm-svc-name: string # Walmart Service Name (e.g. Walmart Service Name)
  inventories: record # shape: {nodes: list}
]: any -> record<nodes: table<errors: list, shipNode: string, status: string>, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sku | is-empty) { error make --unspanned { msg: "path parameter 'sku' must be non-empty" } }
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/v3/inventories/{sku}") $auth.query)
  let req_body = {"inventories": $inventories} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
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

# Inventory
#
# GET /v3/inventory
# operationId: getInventory
export def "inventory get" [
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
  --sku: string # An arbitrary alphanumeric unique ID, specified by the seller, which identifies each item. This will be used by the seller in the XSD file to refer to each item. Special characters in the sku needing encoding are: ':', '/', '?', '#', '[', ']', '@', '!', '$', '&', "'", '(', ')', '*', '+', ',', ';', '=', ‘ ’, '{', '}' as well as '%' itself if it's a part of sku. Make sure to encode space with %20. Other characters don't need to be encoded.
  --ship-node: string # The shipNode for which the inventory is requested
  --wm-sec-access-token: string # The access token retrieved in the Token API call (e.g. eyJraWQiOiIzZjVhYTFmNS1hYWE5LTQzM.....)
  --wm-consumer-channel-type: string # A unique ID to track the consumer request by channel. Use the Consumer Channel Type received during onboarding
  --wm-qos-correlation-id: string # A unique ID which identifies each API call and used to track and debug issues; use a random generated GUID for this ID (e.g. b3261d2d-028a-4ef7-8602-633c23200af6)
  --wm-svc-name: string # Walmart Service Name (e.g. Walmart Service Name)
]: nothing -> record<quantity: record<amount: float, unit: string>, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sku" $sku "scalar") (serialize-qp "shipNode" $ship_node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/inventory" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sku": $sku, "shipNode": $ship_node} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update inventory
#
# PUT /v3/inventory
# operationId: updateInventoryForAnItem
# --quantity shape: {amount: float, unit: "EACH"}
export def "inventory update-for-item" [
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
  --sku: string # An arbitrary alphanumeric unique ID, specified by the seller, which identifies each item. This will be used by the seller in the XSD file to refer to each item. Special characters in the sku needing encoding are: ':', '/', '?', '#', '[', ']', '@', '!', '$', '&', "'", '(', ')', '*', '+', ',', ';', '=', ‘ ’, '{', '}' as well as '%' itself if it's a part of sku. Make sure to encode space with %20. Other characters don't need to be encoded.
  --ship-node: string # The shipNode for which the inventory is to be updated.
  --wm-sec-access-token: string # The access token retrieved in the Token API call (e.g. eyJraWQiOiIzZjVhYTFmNS1hYWE5LTQzM.....)
  --wm-consumer-channel-type: string # A unique ID to track the consumer request by channel. Use the Consumer Channel Type received during onboarding
  --wm-qos-correlation-id: string # A unique ID which identifies each API call and used to track and debug issues; use a random generated GUID for this ID (e.g. b3261d2d-028a-4ef7-8602-633c23200af6)
  --wm-svc-name: string # Walmart Service Name (e.g. Walmart Service Name)
  quantity: record # Quantity that has been ordered by the customers but not yet shipped — shape: {amount: float, unit: "EACH"}
  --sku-body: string # A seller-provided Product ID. Response will have decoded value. (body field)
]: any -> record<quantity: record<amount: float, unit: string>, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sku" $sku "scalar") (serialize-qp "shipNode" $ship_node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/inventory" $qp $auth.query)
  let req_body = {"quantity": $quantity, "sku": $sku_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"sku": $sku, "shipNode": $ship_node} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}
