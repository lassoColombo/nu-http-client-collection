# Auto-generated client for Inventory Management v1.0.0
# Source: https://api.apis.guru/v2/specs/walmart.com/inventory/1.0.0/openapi.json
# Auth: --token flag or $env.INVENTORY_MANAGEMENT_TOKEN

const BASE_URL = "https://marketplace.walmartapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o INVENTORY_MANAGEMENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
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
  let full_url = (build-url $base "/v3/feeds" $qp)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
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
  let full_url = (build-url $base "/v3/fulfillment/inventory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Multiple Item Inventory for All Ship Nodes
#
# GET /v3/inventories
# operationId: getMultiNodeInventoryForAllSkuAndAllShipNodes
export def "inventories get-multi-node-inventory-for-list-sku-and-list-ship-nodes" [
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
  let full_url = (build-url $base "/v3/inventories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let qp = [(serialize-qp "shipNode" $ship_node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/v3/inventories/{sku}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({sku: (encode-path-segment $sku)} | format pattern "/v3/inventories/{sku}"))
  let req_body = {"inventories": $inventories} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
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
  let full_url = (build-url $base "/v3/inventory" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  sku: string # A seller-provided Product ID. Response will have decoded value.
]: any -> record<quantity: record<amount: float, unit: string>, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sku" $sku "scalar") (serialize-qp "shipNode" $ship_node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/inventory" $qp)
  let req_body = {"quantity": $quantity, "sku": $sku} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
