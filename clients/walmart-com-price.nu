# Auto-generated client for Price Management v1.0.0
# Source: https://api.apis.guru/v2/specs/walmart.com/price/1.0.0/openapi.json
# Auth: --token flag or $env.PRICE_MANAGEMENT_TOKEN

const BASE_URL = "https://marketplace.walmartapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PRICE_MANAGEMENT_TOKEN | default "" }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
def build-multipart-body [parts: record, file_fields: list<string>]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | transpose k v | where {|p| $p.v != null} | each {|p|
    let name = $p.k
    let val = $p.v
    if $name in $file_fields {
      let filename = ($val | path basename)
      let bytes = (open --raw $val | into binary | collect)
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  })
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://marketplace.walmartapis.com" "https://sandbox.walmartapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def feed-type-completer [] { ["CPT_SELLER_ELIGIBILITY" "price"] }
def accept-completer [] { ["application/json" "application/xml"] }
def replace-all-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cppreference create-opt-cap-program-in-price" } } | get name | first)
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

# Set up CAP SKU All
#
# POST /v3/cppreference
# Docs: /doc/us/mp/us-mp-price/#1290 — View Guide
# operationId: optCapProgramInPrice
export def "cppreference create-opt-cap-program-in-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --wm-sec-access-token: string # The access token retrieved in the Token API call (e.g. eyJraWQiOiIzZjVhYTFmNS1hYWE5LTQzM.....)
  --wm-consumer-channel-type: string # A unique ID to track the consumer request by channel. Use the Consumer Channel Type received during onboarding
  --wm-qos-correlation-id: string # A unique ID which identifies each API call and used to track and debug issues; use a random generated GUID for this ID (e.g. b3261d2d-028a-4ef7-8602-633c23200af6)
  --wm-svc-name: string # Walmart Service Name (e.g. Walmart Service Name)
  --subsidy-enrolled: oneof<nothing, bool> # A Boolean parameter that allows all sellers to completely enroll in or out of the Competitive Price Adjustment program
  --subsidy-preference: oneof<nothing, bool> # A Boolean parameter that determines whether offer level subsidy setting override seller level subsidy setting
]: any -> record<martId: string, statusInfo: record<subsidyEnrolled: bool, subsidyPreference: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/cppreference")
  let req_body = {"subsidyEnrolled": $subsidy_enrolled, "subsidyPreference": $subsidy_preference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update bulk prices (Multiple)
#
# POST /v3/feeds
# operationId: priceBulkUploads
export def "feeds create-price-bulk-uploads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --feed-type: string@feed-type-completer # The feed Type
  --wm-sec-access-token: string # The access token retrieved in the Token API call (e.g. eyJraWQiOiIzZjVhYTFmNS1hYWE5LTQzM.....)
  --wm-consumer-channel-type: string # A unique ID to track the consumer request by channel. Use the Consumer Channel Type received during onboarding
  --wm-qos-correlation-id: string # A unique ID which identifies each API call and used to track and debug issues; use a random generated GUID for this ID (e.g. b3261d2d-028a-4ef7-8602-633c23200af6)
  --wm-svc-name: string # Walmart Service Name (e.g. Walmart Service Name)
  file: string # Feed file to upload (format: binary)
]: any -> record<additionalAttributes: record, errors: record, feedId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feedType" $feed_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/feeds" $qp)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let mp = (build-multipart-body $req_body ["file"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Update a price
#
# PUT /v3/price
# operationId: updatePrice
# --pricing item shape: {comparisonPrice?: record, comparisonPriceType?: "BASE", currentPrice: record, currentPriceType: "BASE"|"REDUCED"|"CLEARANCE", effectiveDate?: string, expirationDate?: string, priceDisplayCodes?: "CART"|"CHECKOUT", processMode?: "UPSERT"|"DELETE", promoId?: string}
export def "price update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --wm-sec-access-token: string # The access token retrieved in the Token API call (e.g. eyJraWQiOiIzZjVhYTFmNS1hYWE5LTQzM.....)
  --wm-consumer-channel-type: string # A unique ID to track the consumer request by channel. Use the Consumer Channel Type received during onboarding
  --wm-qos-correlation-id: string # A unique ID which identifies each API call and used to track and debug issues; use a random generated GUID for this ID (e.g. b3261d2d-028a-4ef7-8602-633c23200af6)
  --wm-svc-name: string # Walmart Service Name (e.g. Walmart Service Name)
  --definitions: record
  --offer-id: string # This is applicable only for promotions
  pricing: list # item shape: {comparisonPrice?: record, comparisonPriceType?: "BASE", currentPrice: record, currentPriceType: "BASE"|"REDUCED"|"CLEARANCE", effectiveDate?: string, expirationDate?: string, priceDisplayCodes?: "CART"|"CHECKOUT", processMode?: "UPSERT"|"DELETE", promoId?: string}
  --replace-all: string@replace-all-completer # This is applicable only for promotions
  sku: string
]: any -> record<errors: table<category: string, causes: list, code: string, component: string, description: string, errorIdentifiers: record, field: string, gatewayErrorCategory: string, info: string, serviceName: string, severity: string, type: string>, mart: string, message: string, sku: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/price")
  let req_body = {"definitions": $definitions, "offerId": $offer_id, "pricing": $pricing, "replaceAll": $replace_all, "sku": $sku} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"WM_SEC.ACCESS_TOKEN": $wm_sec_access_token, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id, "WM_SVC.NAME": $wm_svc_name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
