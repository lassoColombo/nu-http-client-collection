# Auto-generated client for Item API v3.0.1
# Source: https://api.apis.guru/v2/specs/walmart.com/item/3.0.1/swagger.json
# Auth: --token flag or $env.ITEM_API_TOKEN

const BASE_URL = "https://developer.walmart.com/proxy/item-api-doc-app/rest"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ITEM_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://developer.walmart.com/proxy/item-api-doc-app/rest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def wm-consumer-channel-type-completer [] { ["SWAGGER_CHANNEL_TYPE"] }
def feed-type-completer [] { ["item"] }
def feed-type-completer-1 [] { ["CONTENT_PRODUCT" "SUPPLIER_FULL_ITEM" "item"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "feeds get-v2get-item-status" } } | get name | first)
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

# Get status of an item feed
#
# GET /v2/feeds
# operationId: v2getFeedItemStatus
export def "feeds get-v2get-item-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-id: string # The feed ID.
  --include-details: string # Includes the status details for each item in the feed. Do not set this parameter to true as discrepancies may appear between the header and the item details (the item details may be incorrect). Instead, use the Get a feedItems status. (default: false)
  --offset: string # The object response to start with, where 0 is the first entity that can be requested. It can only be used when includeDetails is set to true. (default: 0)
  --limit: string # The number of items to be returned. Cannot be more than 50 items. Use it only when the includeDetails is set to true. (default: 50)
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feedId" $feed_id "scalar") (serialize-qp "includeDetails" $include_details "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/feeds" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"feedId": $feed_id, "includeDetails": $include_details, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Upload an item feed
#
# POST /v2/feeds
# operationId: v2doPostMultiPart
export def "feeds create-v2do-multi-part" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string@feed-type-completer # Feed Type (default: item)
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
  file: path # Feed File to upload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feedType" $feed_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/feeds" $qp)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: ({"feedType": $feed_type} | compact), body: $req_body}
}

# Get status of an item within a feed
#
# GET /v2/feeds/{feedId}
# operationId: v2getAllItemsStatus
export def "feeds list-v2get-items-status" [
  feed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-details: string # Includes details of each entity in the feed. Do not set this parameter to true. (default: false)
  --offset: string # The object response to start with, where 0 is the first entity that can be requested. It can only be used when includeDetails is set to true. (default: 0)
  --limit: string # The number of entities to be returned. It cannot be more than 50 entities. Use it only when the includeDetails is set to true. (default: 50)
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($feed_id | is-empty) { error make --unspanned { msg: "path parameter 'feedId' must be non-empty" } }
  let qp = [(serialize-qp "includeDetails" $include_details "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({feed_id: (encode-path-segment $feed_id)} | format pattern "/v2/feeds/{feed_id}") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeDetails": $include_details, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Get status of an item feed
#
# GET /v3/feeds
# operationId: v3getFeedItemStatus
export def "feeds get-v3get-item-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-id: string # The feed ID.
  --include-details: string # Includes the status details for each item in the feed. Do not set this parameter to true as discrepancies may appear between the header and the item details (the item details may be incorrect). Instead, use the Get a feedItems status. (default: false)
  --offset: string # The object response to start with, where 0 is the first entity that can be requested. It can only be used when includeDetails is set to true. (default: 0)
  --limit: string # The number of items to be returned. Cannot be more than 50 items. Use it only when the includeDetails is set to true. (default: 50)
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feedId" $feed_id "scalar") (serialize-qp "includeDetails" $include_details "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/feeds" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"feedId": $feed_id, "includeDetails": $include_details, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Upload an item feed
#
# POST /v3/feeds
# operationId: v3doPostMultiPart
export def "feeds create-v3do-multi-part" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string@feed-type-completer-1 # Feed Type (default: item)
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
  file: path # Feed File to upload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feedType" $feed_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/feeds" $qp)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: ({"feedType": $feed_type} | compact), body: $req_body}
}

# Get status of an item within a feed
#
# GET /v3/feeds/{feedId}
# operationId: v3getAllItemsStatus
export def "feeds list-v3get-items-status" [
  feed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-details: string # Includes details of each entity in the feed. Do not set this parameter to true. (default: false)
  --offset: string # The object response to start with, where 0 is the first entity that can be requested. It can only be used when includeDetails is set to true. (default: 0)
  --limit: string # The number of entities to be returned. It cannot be more than 50 entities. Use it only when the includeDetails is set to true. (default: 50)
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($feed_id | is-empty) { error make --unspanned { msg: "path parameter 'feedId' must be non-empty" } }
  let qp = [(serialize-qp "includeDetails" $include_details "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({feed_id: (encode-path-segment $feed_id)} | format pattern "/v3/feeds/{feed_id}") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeDetails": $include_details, "offset": $offset, "limit": $limit} | compact), body: null}
}
