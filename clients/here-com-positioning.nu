# Auto-generated client for HERE Network Positioning API v2 v2.1.1
# Source: https://api.apis.guru/v2/specs/here.com/positioning/2.1.1/openapi.json
# Auth: --token flag or $env.HERE_NETWORK_POSITIONING_API_V2_TOKEN

const BASE_URL = "https://positioning.hereapi.com/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HERE_NETWORK_POSITIONING_API_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-apiKey" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "apiKey")=(encode-path-segment $token_val)", location: "query"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://positioning.hereapi.com/v2" "https://az.positioning.hereapi.com/v2"] }
def auth-scheme-completer [] { ["query-apiKey" "bearer"] }

# Completers for enum parameters
def content-encoding-completer [] { ["gzip"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "health get" } } | get name | first)
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

# Service health
#
# GET /health
# operationId: getHealth
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Location query
#
# POST /locate
# operationId: postLocate
# --cdma item shape: {baseLat?: float, baseLng?: float, bsid: int, localId?: record, nid: int, nmr?: list, pilotPower?: int, rz?: int, sid: int}
# --client shape: {firmware?: string, manufacturer: string, model: string, name: string, platform?: string, version: string}
# --gsm item shape: {cid: int, lac: int, localId?: record, mcc: int, mnc: int, nmr?: list, rxLevel?: int, ta?: int}
# --lte item shape: {cid: int, localId?: record, mcc: int, mnc: int, nmr?: list, rsrp?: int, rsrq?: float, ta?: int, tac?: int}
# --tdscdma item shape: {cid: int, lac?: int, localId?: record, mcc: int, mnc: int, nmr?: list, pathloss?: int, rscp?: int, ta?: int}
# --wcdma item shape: {cid: int, lac?: int, localId?: record, mcc: int, mnc: int, nmr?: list, pathloss?: int, rscp?: int}
# --wlan item shape: {mac: string, rss?: int}
export def "locate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confidence: int # Confidence level in percent for the accuracy/uncertainty in the location estimate response. If not specified, the default is 68 (this corresponds to a 68% probability that the true position is within the accuracy/uncertainty radius of the location estimate: the higher the number, the greater the confidence level). (default: 68)
  --fallback: list<string> # Acceptable fallback options for cell and WLAN positioning. Values `area` and `any` apply to cell based positioning, and value `singleWifi` applies to WLAN based positioning. Both cell and WLAN options may be specified in the same request. If both `area` and `any` are specified, then `area` is ignored. By default, cell based positioning returns cell tower level location estimates only. If you allow a WGS-84 compliant geocoordinate location estimate based on LAC, RNC, TAC, NID, or RZ areas, use the `fallback=area` setting. If you use the `fallback=any` setting, the service uses all available cell fallback methods and therefore the location estimate in the response may be at the MNC, SID, or MCC level. For privacy reasons, the precise positioning based on a single WLAN AP is not possible. You can use the `fallback=singleWifi` setting to allow less accurate positioning based on a single WLAN AP. In that case, the center location of the position estimate will be deviated and the reported accuracy radius will be larger.
  --desired: list<string> # Comma-separated list of additional data fields that the service should include in the response if data is available. The query parameter supports the value `altitude`.
  --required: list<string> # Comma-separated list of additional data fields that the service should include in the response. If the data is not available, the response contains an error message. The query parameter supports the value `altitude`.
  --content-encoding: string@content-encoding-completer # Indicates that the data in the body is gzip-encoded.
  --x-request-id: string # ID used for correlating customer requests within HERE services. Used for logging and error reporting. Can be any string, but UUID is recommended. It will be echoed in the response.
  --cdma: list # CDMA cells (CDMA2000) — item shape: {baseLat?: float, baseLng?: float, bsid: int, localId?: record, nid: int, nmr?: list, pilotPower?: int, rz?: int, sid: int}
  --client: record # Information about the client (e.g. {manufacturer: Lemon, model: Flagship X1, name: FinderApp, version: 2.0.31}) — shape: {firmware?: string, manufacturer: string, model: string, name: string, platform?: string, version: string}
  --gsm: list # GSM cells (GERAN) — item shape: {cid: int, lac: int, localId?: record, mcc: int, mnc: int, nmr?: list, rxLevel?: int, ta?: int}
  --lte: list # LTE cells (E-UTRA, 4G) — item shape: {cid: int, localId?: record, mcc: int, mnc: int, nmr?: list, rsrp?: int, rsrq?: float, ta?: int, tac?: int}
  --tdscdma: list # TD-SCDMA cells (UTRA-TDD, 3G UMTS TDD) — item shape: {cid: int, lac?: int, localId?: record, mcc: int, mnc: int, nmr?: list, pathloss?: int, rscp?: int, ta?: int}
  --wcdma: list # WCDMA cells (UTRA-FDD, 3G UMTS) — item shape: {cid: int, lac?: int, localId?: record, mcc: int, mnc: int, nmr?: list, pathloss?: int, rscp?: int}
  --wlan: list # WLAN access positions. For privacy reasons positioning based on a single WLAN AP is not possible; there has to be at least one other matching wlan or cell. Alternatively, you can allow fallbacks to less accurate single WLAN AP location estimates by using the setting `fallback=singleWifi`. — item shape: {mac: string, rss?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confidence" $confidence "scalar") (serialize-qp "fallback" $fallback "csv") (serialize-qp "desired" $desired "csv") (serialize-qp "required" $required "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/locate" $qp)
  let req_body = {"cdma": $cdma, "client": $client, "gsm": $gsm, "lte": $lte, "tdscdma": $tdscdma, "wcdma": $wcdma, "wlan": $wlan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Encoding": $content_encoding, "X-Request-ID": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"confidence": $confidence, "fallback": $fallback, "desired": $desired, "required": $required} | compact), body: $req_body}
}

# API version
#
# GET /version
# operationId: getApiVersion
export def "version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiVersion: string, serviceVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
