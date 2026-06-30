# Auto-generated client for Logistics API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Logistics-API/1.0/openapi.json
# Auth: --token flag or $env.LOGISTICS_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o LOGISTICS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {X-VTEX-API-AppKey: $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {X-VTEX-API-AppToken: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "logistics-capacity-resources-carriercapacity-typeshipping-policy-id-time-frames get-by-capacity-type-shipping-policy-id" } } | get name | first)
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

# Search capacity reservations in time range
#
# GET /api/logistics-capacity/resources/carrier@{capacityType}@{shippingPolicyId}/time-frames
export def "logistics-capacity-resources-carriercapacity-typeshipping-policy-id-time-frames get-by-capacity-type-shipping-policy-id" [
  capacity_type: string
  shipping_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --range-start: string # Starting date of time range (e.g. yyyy-mm-dd)
  --range-end: string # End date of time range. (e.g. yyyy-mm-dd)
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (e.g. application/vnd.vtex.availability.v1+json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($capacity_type | is-empty) { error make --unspanned { msg: "path parameter 'capacityType' must be non-empty" } }
  if ($shipping_policy_id | is-empty) { error make --unspanned { msg: "path parameter 'shippingPolicyId' must be non-empty" } }
  let qp = [(serialize-qp "rangeStart" $range_start "scalar") (serialize-qp "rangeEnd" $range_end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({capacity_type: (encode-path-segment $capacity_type), shipping_policy_id: (encode-path-segment $shipping_policy_id)} | format pattern "/api/logistics-capacity/resources/carrier@{capacity_type}@{shipping_policy_id}/time-frames") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rangeStart": $range_start, "rangeEnd": $range_end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get capacity reservation usage by window
#
# GET /api/logistics-capacity/resources/carrier@{capacityType}@{shippingPolicyId}/time-frames/{windowDay}F{windowStartTime}T{windowEndTime}
export def "logistics-capacity-resources-carriercapacity-typeshipping-policy-id-time-frames get-by-capacity-type-shipping-policy-id-window-day-window-start-time-window-end-time" [
  capacity_type: string
  shipping_policy_id: string
  window_day: string
  window_start_time: string
  window_end_time: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand (e.g. application/vnd.vtex.availability.v1+json)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($capacity_type | is-empty) { error make --unspanned { msg: "path parameter 'capacityType' must be non-empty" } }
  if ($shipping_policy_id | is-empty) { error make --unspanned { msg: "path parameter 'shippingPolicyId' must be non-empty" } }
  if ($window_day | is-empty) { error make --unspanned { msg: "path parameter 'windowDay' must be non-empty" } }
  if ($window_start_time | is-empty) { error make --unspanned { msg: "path parameter 'windowStartTime' must be non-empty" } }
  if ($window_end_time | is-empty) { error make --unspanned { msg: "path parameter 'windowEndTime' must be non-empty" } }
  let full_url = (build-url $base ({capacity_type: (encode-path-segment $capacity_type), shipping_policy_id: (encode-path-segment $shipping_policy_id), window_day: (encode-path-segment $window_day), window_start_time: (encode-path-segment $window_start_time), window_end_time: (encode-path-segment $window_end_time)} | format pattern "/api/logistics-capacity/resources/carrier@{capacity_type}@{shipping_policy_id}/time-frames/{window_day}F{window_start_time}T{window_end_time}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Add blocked delivery windows
#
# POST /api/logistics/pvt/configuration/carriers/{carrierId}/adddayofweekblocked
# operationId: AddBlockedDeliveryWindows
export def "logistics-pvt-configuration-carriers-adddayofweekblocked create-blocked-delivery-windows" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --body: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrierId' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/api/logistics/pvt/configuration/carriers/{carrier_id}/adddayofweekblocked") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve blocked delivery windows
#
# GET /api/logistics/pvt/configuration/carriers/{carrierId}/getdayofweekblocked
# operationId: RetrieveBlockedDeliveryWindows
export def "logistics-pvt-configuration-carriers-get-dayofweekblocked get-blocked-delivery-windows" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrierId' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/api/logistics/pvt/configuration/carriers/{carrier_id}/getdayofweekblocked") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Remove blocked delivery windows
#
# POST /api/logistics/pvt/configuration/carriers/{carrierId}/removedayofweekblocked
# operationId: RemoveBlockedDeliveryWindows
export def "logistics-pvt-configuration-carriers-remove-dayofweekblocked delete-blocked-delivery-windows" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --body: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrierId' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/api/logistics/pvt/configuration/carriers/{carrier_id}/removedayofweekblocked") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List all docks
#
# GET /api/logistics/pvt/configuration/docks
# operationId: AllDocks
export def "logistics-pvt-configuration-docks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<dockTimeFake: string, freightTableIds: list<string>, id: string, name: string, pickupStoreInfo: record<additionalInfo: string, address: string, dockId: string, friendlyName: string, isPickupStore: bool, storeId: string>, priority: int, salesChannel: string, salesChannels: list<string>, timeFakeOverhead: string, wmsEndPoint: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/docks" $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create/update dock
#
# POST /api/logistics/pvt/configuration/docks
# operationId: Create/UpdateDock
# --address shape: {city: string, complement: string, coordinates: list, country: record, neighborhood: string, number: string, postalCode: string, state: string, street: string}
export def "logistics-pvt-configuration-docks create-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  address: record # e.g. {city: Rio de Janeiro, complement: , coordinates: [[-43.18228090000002, -22.9460398]], country: {acronym: BRA, name: Brazil}, neighborhood: Catete, number: 100, postalCode: 22220070, state: RJ, street: Artur Bernardes Street} — shape: {city: string, complement: string, coordinates: list, country: record, neighborhood: string, number: string, postalCode: string, state: string, street: string}
  dock_time_fake: string
  freight_table_ids: list<string>
  id: string
  name: string
  priority: int # format: int32
  --sales-channel: string # nullable
  sales_channels: list<string>
  time_fake_overhead: string
  wms_end_point: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/docks" $auth.query)
  let req_body = {"address": $address, "dockTimeFake": $dock_time_fake, "freightTableIds": $freight_table_ids, "id": $id, "name": $name, "priority": $priority, "salesChannel": $sales_channel, "salesChannels": $sales_channels, "timeFakeOverhead": $time_fake_overhead, "wmsEndPoint": $wms_end_point} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete dock
#
# DELETE /api/logistics/pvt/configuration/docks/{dockId}
# operationId: Dock
export def "logistics-pvt-configuration-docks delete" [
  dock_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($dock_id | is-empty) { error make --unspanned { msg: "path parameter 'dockId' must be non-empty" } }
  let full_url = (build-url $base ({dock_id: (encode-path-segment $dock_id)} | format pattern "/api/logistics/pvt/configuration/docks/{dock_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List dock by ID
#
# GET /api/logistics/pvt/configuration/docks/{dockId}
# operationId: DockById
export def "logistics-pvt-configuration-docks get" [
  dock_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> record<dockTimeFake: string, freightTableIds: list<string>, id: string, name: string, pickupStoreInfo: record<additionalInfo: string, address: string, dockId: string, friendlyName: string, isPickupStore: bool, storeId: string>, priority: int, salesChannel: string, salesChannels: list<string>, timeFakeOverhead: string, wmsEndPoint: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($dock_id | is-empty) { error make --unspanned { msg: "path parameter 'dockId' must be non-empty" } }
  let full_url = (build-url $base ({dock_id: (encode-path-segment $dock_id)} | format pattern "/api/logistics/pvt/configuration/docks/{dock_id}") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Activate dock
#
# POST /api/logistics/pvt/configuration/docks/{dockId}/activation
# operationId: ActivateDock
export def "logistics-pvt-configuration-docks-activation create-activate" [
  dock_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($dock_id | is-empty) { error make --unspanned { msg: "path parameter 'dockId' must be non-empty" } }
  let full_url = (build-url $base ({dock_id: (encode-path-segment $dock_id)} | format pattern "/api/logistics/pvt/configuration/docks/{dock_id}/activation") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deactivate dock
#
# POST /api/logistics/pvt/configuration/docks/{dockId}/deactivation
# operationId: DeactivateDock
export def "logistics-pvt-configuration-docks-deactivation create-deactivate" [
  dock_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($dock_id | is-empty) { error make --unspanned { msg: "path parameter 'dockId' must be non-empty" } }
  let full_url = (build-url $base ({dock_id: (encode-path-segment $dock_id)} | format pattern "/api/logistics/pvt/configuration/docks/{dock_id}/deactivation") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create/update freight values
#
# POST /api/logistics/pvt/configuration/freights/{carrierId}/values/update
# operationId: Create/UpdateFreightValues
export def "logistics-pvt-configuration-freights-values-update create" [
  carrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --body: list
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrierId' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id)} | format pattern "/api/logistics/pvt/configuration/freights/{carrier_id}/values/update") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List freight values
#
# GET /api/logistics/pvt/configuration/freights/{carrierId}/{cep}/values
# operationId: FreightValues
export def "logistics-pvt-configuration-freights-values get" [
  carrier_id: string
  cep: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<absoluteMoneyCost: float, country: string, maxVolume: float, minimumValueInsurance: float, operationType: int, polygon: string, pricePercent: float, pricePercentByWeight: float, restrictedFreights: list<string>, timeCost: string, weightEnd: float, weightStart: float, zipCodeEnd: string, zipCodeStart: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($carrier_id | is-empty) { error make --unspanned { msg: "path parameter 'carrierId' must be non-empty" } }
  if ($cep | is-empty) { error make --unspanned { msg: "path parameter 'cep' must be non-empty" } }
  let full_url = (build-url $base ({carrier_id: (encode-path-segment $carrier_id), cep: (encode-path-segment $cep)} | format pattern "/api/logistics/pvt/configuration/freights/{carrier_id}/{cep}/values") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List paged polygons
#
# GET /api/logistics/pvt/configuration/geoshape
# operationId: PagedPolygons
export def "logistics-pvt-configuration-geoshape get-paged-polygons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # e.g. {{page}}
  --per-page: string # e.g. {{perPage}}
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/logistics/pvt/configuration/geoshape" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "perPage": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create/update polygon
#
# PUT /api/logistics/pvt/configuration/geoshape
# operationId: CreateUpdatePolygon
# --geoShape shape: {coordinates: list}
export def "logistics-pvt-configuration-geoshape create-update-polygon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  geo_shape: record # shape: {coordinates: list}
  name: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/geoshape" $auth.query)
  let req_body = {"geoShape": $geo_shape, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete polygon
#
# DELETE /api/logistics/pvt/configuration/geoshape/{polygonName}
# operationId: DeletePolygon
export def "logistics-pvt-configuration-geoshape delete-polygon" [
  polygon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($polygon_name | is-empty) { error make --unspanned { msg: "path parameter 'polygonName' must be non-empty" } }
  let full_url = (build-url $base ({polygon_name: (encode-path-segment $polygon_name)} | format pattern "/api/logistics/pvt/configuration/geoshape/{polygon_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List polygon by ID
#
# GET /api/logistics/pvt/configuration/geoshape/{polygonName}
# operationId: PolygonbyId
export def "logistics-pvt-configuration-geoshape get-polygonby" [
  polygon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($polygon_name | is-empty) { error make --unspanned { msg: "path parameter 'polygonName' must be non-empty" } }
  let full_url = (build-url $base ({polygon_name: (encode-path-segment $polygon_name)} | format pattern "/api/logistics/pvt/configuration/geoshape/{polygon_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List all holidays
#
# GET /api/logistics/pvt/configuration/holidays
# operationId: AllHolidays
export def "logistics-pvt-configuration-holidays list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/holidays" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete holiday
#
# DELETE /api/logistics/pvt/configuration/holidays/{holidayId}
# operationId: Holiday
export def "logistics-pvt-configuration-holidays delete" [
  holiday_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($holiday_id | is-empty) { error make --unspanned { msg: "path parameter 'holidayId' must be non-empty" } }
  let full_url = (build-url $base ({holiday_id: (encode-path-segment $holiday_id)} | format pattern "/api/logistics/pvt/configuration/holidays/{holiday_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List holiday by ID
#
# GET /api/logistics/pvt/configuration/holidays/{holidayId}
# operationId: HolidayById
export def "logistics-pvt-configuration-holidays get" [
  holiday_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($holiday_id | is-empty) { error make --unspanned { msg: "path parameter 'holidayId' must be non-empty" } }
  let full_url = (build-url $base ({holiday_id: (encode-path-segment $holiday_id)} | format pattern "/api/logistics/pvt/configuration/holidays/{holiday_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create/update holiday
#
# PUT /api/logistics/pvt/configuration/holidays/{holidayId}
# operationId: Create/UpdateHoliday
export def "logistics-pvt-configuration-holidays create-update" [
  holiday_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
  name: string
  start_date: string
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($holiday_id | is-empty) { error make --unspanned { msg: "path parameter 'holidayId' must be non-empty" } }
  let full_url = (build-url $base ({holiday_id: (encode-path-segment $holiday_id)} | format pattern "/api/logistics/pvt/configuration/holidays/{holiday_id}") $auth.query)
  let req_body = {"name": $name, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List all pickup points
#
# GET /api/logistics/pvt/configuration/pickuppoints
# operationId: ListAllPickupPpoints
export def "logistics-pvt-configuration-pickuppoints list-pickup-ppoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<accountGroupId: string, accountOwnerId: string, accountOwnerName: string, address: record<city: string, complement: string, country: record, location: record, neighborhood: string, number: string, postalCode: string, state: string, street: string>, businessHours: list<record>, description: string, distance: float, formatted_address: string, id: string, instructions: string, isActive: bool, isThirdPartyPickup: bool, name: string, originalId: string, parentAccountName: string, pickupHolidays: list<string>, seller: string, tagsLabel: list<string>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/pickuppoints" $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List paged Pickup Points
#
# GET /api/logistics/pvt/configuration/pickuppoints/_search
# operationId: Getpaged
export def "logistics-pvt-configuration-pickuppoints-search get-paged" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # e.g. {{pageNumber}}
  --page-size: string # e.g. {{pageSize}}
  --keyword: string # e.g. 
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "keyword" $keyword "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/logistics/pvt/configuration/pickuppoints/_search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "keyword": $keyword} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Pickup Point
#
# DELETE /api/logistics/pvt/configuration/pickuppoints/{pickupPointId}
# operationId: Delete
export def "logistics-pvt-configuration-pickuppoints delete" [
  pickup_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($pickup_point_id | is-empty) { error make --unspanned { msg: "path parameter 'pickupPointId' must be non-empty" } }
  let full_url = (build-url $base ({pickup_point_id: (encode-path-segment $pickup_point_id)} | format pattern "/api/logistics/pvt/configuration/pickuppoints/{pickup_point_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List Pickup Point By ID
#
# GET /api/logistics/pvt/configuration/pickuppoints/{pickupPointId}
# operationId: GetById
export def "logistics-pvt-configuration-pickuppoints get" [
  pickup_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> record<address: record<city: string, complement: string, country: record<acronym: string, name: string>, location: record<latitude: float, longitude: float>, neighborhood: string, number: string, postalCode: string, state: string, street: string>, businessHours: table<closingTime: string, dayOfWeek: int, openingTime: string>, description: string, formatted_address: string, id: string, instructions: string, isActive: bool, name: string, warehouseId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($pickup_point_id | is-empty) { error make --unspanned { msg: "path parameter 'pickupPointId' must be non-empty" } }
  let full_url = (build-url $base ({pickup_point_id: (encode-path-segment $pickup_point_id)} | format pattern "/api/logistics/pvt/configuration/pickuppoints/{pickup_point_id}") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create/Update Pickup Point
#
# PUT /api/logistics/pvt/configuration/pickuppoints/{pickupPointId}
# operationId: CreateUpdatePickupPoint
# --address shape: {city: string, complement: string, country: record, location: record, neighborhood: string, number: string, postalCode: string, reference: string, state: string, street: string}
# --businessHours item shape: {closingTime: string, dayOfWeek: int, openingTime: string}
export def "logistics-pvt-configuration-pickuppoints create-update-pickup-point" [
  pickup_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  address: record # e.g. {city: Rio de Janeiro, complement: , country: {acronym: BRA, name: Brazil}, location: {latitude: -22.974477767944336, longitude: -43.18672561645508}, neighborhood: Copacabana, number: , postalCode: 22070002, reference: Grey building, state: RJ, street: Avenida Atl├óntica} — shape: {city: string, complement: string, country: record, location: record, neighborhood: string, number: string, postalCode: string, reference: string, state: string, street: string}
  business_hours: list # item shape: {closingTime: string, dayOfWeek: int, openingTime: string}
  description: string # Pickup point description. (e.g. Pickup your items in our store.)
  formatted_address: string # Formated address.
  id: string # Pickup Point ID. Cannot contain spaces. (e.g. 123456789)
  instructions: string # Pickup point instructions. (e.g. Bring your ID in order to pickup your order.)
  --is-active: oneof<nothing, bool>
  --is-third-party-pickup: oneof<nothing, bool>
  name: string # Pickup point name. (e.g. Pickup store.)
  tags_label: list<string>
]: any -> record<address: record<city: string, complement: string, country: record<acronym: string, name: string>, location: record<latitude: float, longitude: float>, neighborhood: string, number: string, postalCode: string, reference: string, state: string, street: string>, businessHours: table<closingTime: string, dayOfWeek: int, openingTime: string>, description: string, formatted_address: string, id: string, instructions: string, isActive: bool, name: string, pickupHolidays: list<string>, tagsLabel: list<string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($pickup_point_id | is-empty) { error make --unspanned { msg: "path parameter 'pickupPointId' must be non-empty" } }
  let full_url = (build-url $base ({pickup_point_id: (encode-path-segment $pickup_point_id)} | format pattern "/api/logistics/pvt/configuration/pickuppoints/{pickup_point_id}") $auth.query)
  let req_body = {"address": $address, "businessHours": $business_hours, "description": $description, "formatted_address": $formatted_address, "id": $id, "instructions": $instructions, "isActive": $is_active, "isThirdPartyPickup": $is_third_party_pickup, "name": $name, "tagsLabel": $tags_label} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List all warehouses
#
# GET /api/logistics/pvt/configuration/warehouses
# operationId: AllWarehouses
export def "logistics-pvt-configuration-warehouses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<id: string, isActive: bool, name: string, pickupPointIds: list<any>, priority: int, warehouseDocks: list<record>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/warehouses" $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create/update warehouse
#
# POST /api/logistics/pvt/configuration/warehouses
# operationId: Create/UpdateWarehouse
# --warehouseDocks item shape: {cost: string, costToDisplay: string, dockId: string, name: string, time: string, translateDays: string}
export def "logistics-pvt-configuration-warehouses create-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
  id: string
  name: string
  warehouse_docks: list # item shape: {cost: string, costToDisplay: string, dockId: string, name: string, time: string, translateDays: string}
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/configuration/warehouses" $auth.query)
  let req_body = {"id": $id, "name": $name, "warehouseDocks": $warehouse_docks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Remove warehouse
#
# DELETE /api/logistics/pvt/configuration/warehouses/{warehouseId}
# operationId: RemoveWarehouse
export def "logistics-pvt-configuration-warehouses delete" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/api/logistics/pvt/configuration/warehouses/{warehouse_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List warehouse by ID
#
# GET /api/logistics/pvt/configuration/warehouses/{warehouseId}
# operationId: WarehouseById
export def "logistics-pvt-configuration-warehouses get" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> record<id: string, isActive: bool, name: string, pickupPointIds: list<any>, priority: int, warehouseDocks: table<cost: float, dockId: string, time: string>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/api/logistics/pvt/configuration/warehouses/{warehouse_id}") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Activate warehouse
#
# POST /api/logistics/pvt/configuration/warehouses/{warehouseId}/activation
# operationId: ActivateWarehouse
export def "logistics-pvt-configuration-warehouses-activation create-activate" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/api/logistics/pvt/configuration/warehouses/{warehouse_id}/activation") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deactivate warehouse
#
# POST /api/logistics/pvt/configuration/warehouses/{warehouseId}/deactivation
# operationId: DeactivateWarehouse
export def "logistics-pvt-configuration-warehouses-deactivation create-deactivate" [
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/api/logistics/pvt/configuration/warehouses/{warehouse_id}/deactivation") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List inventory with dispatched reservations
#
# GET /api/logistics/pvt/inventory/items/{itemId}/warehouses/{warehouseId}/dispatched
# operationId: Getinventorywithdispatchedreservations
export def "logistics-pvt-inventory-items-warehouses-dispatched get-inventorywithdispatchedreservations" [
  item_id: string
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<availableQuantity: int, dispatchedReservationsQuantity: int, isUnlimitedQuantity: bool, quantity: int, skuId: string, totalReservedQuantity: int, warehouseId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id), warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/api/logistics/pvt/inventory/items/{item_id}/warehouses/{warehouse_id}/dispatched") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List inventory per dock
#
# GET /api/logistics/pvt/inventory/items/{skuId}/docks/{dockId}
# operationId: Inventoryperdock
export def "logistics-pvt-inventory-items-docks get-inventoryperdock" [
  sku_id: string
  dock_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  if ($dock_id | is-empty) { error make --unspanned { msg: "path parameter 'dockId' must be non-empty" } }
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), dock_id: (encode-path-segment $dock_id)} | format pattern "/api/logistics/pvt/inventory/items/{sku_id}/docks/{dock_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List inventory per dock and warehouse
#
# GET /api/logistics/pvt/inventory/items/{skuId}/docks/{dockId}/warehouses/{warehouseId}
# operationId: Inventoryperdockandwarehouse
export def "logistics-pvt-inventory-items-docks-warehouses get-inventoryperdockandwarehouse" [
  sku_id: string
  dock_id: string
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  if ($dock_id | is-empty) { error make --unspanned { msg: "path parameter 'dockId' must be non-empty" } }
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), dock_id: (encode-path-segment $dock_id), warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/api/logistics/pvt/inventory/items/{sku_id}/docks/{dock_id}/warehouses/{warehouse_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List inventory per warehouse
#
# GET /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}
# operationId: Inventoryperwarehouse
export def "logistics-pvt-inventory-items-warehouses get-inventoryperwarehouse" [
  sku_id: string
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<availableQuantity: int, dateOfSupplyUtc: string, deliveryChannel: list<string>, dockId: string, isUnlimited: bool, keepSellingAfterExpiration: bool, reservedQuantity: int, salesChannel: list<string>, skuId: string, timeToRefill: string, totalQuantity: int, transfer: string, warehouseId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/api/logistics/pvt/inventory/items/{sku_id}/warehouses/{warehouse_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List supply lots
#
# GET /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots
# operationId: GetSupplyLots
export def "logistics-pvt-inventory-items-warehouses-supply-lots get" [
  sku_id: string
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Type of the content being sent. (e.g. application/json; charset=utf-8)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/api/logistics/pvt/inventory/items/{sku_id}/warehouses/{warehouse_id}/supplyLots") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Save supply lot
#
# PUT /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots/{supplyLotId}
# operationId: SaveSupplyLot
export def "logistics-pvt-inventory-items-warehouses-supply-lots update-save" [
  sku_id: string
  warehouse_id: string
  supply_lot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
  date_of_supply_utc: string
  --keep-selling-after-expiration: oneof<nothing, bool>
  quantity: float
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  if ($supply_lot_id | is-empty) { error make --unspanned { msg: "path parameter 'supplyLotId' must be non-empty" } }
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), warehouse_id: (encode-path-segment $warehouse_id), supply_lot_id: (encode-path-segment $supply_lot_id)} | format pattern "/api/logistics/pvt/inventory/items/{sku_id}/warehouses/{warehouse_id}/supplyLots/{supply_lot_id}") $auth.query)
  let req_body = {"dateOfSupplyUtc": $date_of_supply_utc, "keepSellingAfterExpiration": $keep_selling_after_expiration, "quantity": $quantity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Transfer supply lot
#
# POST /api/logistics/pvt/inventory/items/{skuId}/warehouses/{warehouseId}/supplyLots/{supplyLotId}/transfer
# operationId: TransferSupplyLot
export def "logistics-pvt-inventory-items-warehouses-supply-lots-transfer create" [
  sku_id: string
  warehouse_id: string
  supply_lot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  if ($supply_lot_id | is-empty) { error make --unspanned { msg: "path parameter 'supplyLotId' must be non-empty" } }
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), warehouse_id: (encode-path-segment $warehouse_id), supply_lot_id: (encode-path-segment $supply_lot_id)} | format pattern "/api/logistics/pvt/inventory/items/{sku_id}/warehouses/{warehouse_id}/supplyLots/{supply_lot_id}/transfer") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Create reservation
#
# POST /api/logistics/pvt/inventory/reservations
# operationId: CreateReservation
# --deliveryItemOptions item shape: {aditionalTimeBlockedDays: string, deliveryWindows: list<string>, dockId: string, dockTime: string, item: record, listPrice: float, location: record, promotionalPrice: float, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string}
export def "logistics-pvt-inventory-reservations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
  autorization_expiration_ttl: string
  delivery_item_options: list # item shape: {aditionalTimeBlockedDays: string, deliveryWindows: list<string>, dockId: string, dockTime: string, item: record, listPrice: float, location: record, promotionalPrice: float, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string}
  --lock-id: string # nullable
  sales_channel: string
]: any -> record<AuthorizedDateUtc: string, CanceledDateUtc: string, ConfirmedDateUtc: string, Errors: list<string>, IsSucess: bool, LastUpdateDateUtc: string, LockId: string, MaximumConfirmationDateUtc: string, PickupPointItemOptions: string, ReservationDateUtc: string, SalesChannel: string, SlaRequest: table<deliveryWindows: string, dockId: string, dockTime: string, freightTableId: string, freightTableName: string, item: record, listPrice: float, location: record, pickupStoreInfo: string, promotionalPrice: float, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string, wmsEndPoint: string>, Status: int> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/inventory/reservations" $auth.query)
  let req_body = {"autorizationExpirationTTL": $autorization_expiration_ttl, "deliveryItemOptions": $delivery_item_options, "lockId": $lock_id, "salesChannel": $sales_channel} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List reservation by ID
#
# GET /api/logistics/pvt/inventory/reservations/{reservationId}
# operationId: ReservationById
export def "logistics-pvt-inventory-reservations get" [
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> record<AuthorizedDateUtc: string, CanceledDateUtc: string, ConfirmedDateUtc: string, Errors: list<string>, IsSucess: bool, LastUpdateDateUtc: string, LockId: string, MaximumConfirmationDateUtc: string, PickupPointItemOptions: string, ReservationDateUtc: string, SalesChannel: string, SlaRequest: table<deliveryWindows: string, dockId: string, dockTime: string, freightTableId: string, freightTableName: string, item: record, listPrice: float, location: record, pickupStoreInfo: string, promotionalPrice: float, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string, wmsEndPoint: string>, Status: int> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationId' must be non-empty" } }
  let full_url = (build-url $base ({reservation_id: (encode-path-segment $reservation_id)} | format pattern "/api/logistics/pvt/inventory/reservations/{reservation_id}") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Acknowledgment reservation
#
# POST /api/logistics/pvt/inventory/reservations/{reservationId}/acknowledge
# operationId: AcknowledgmentReservation
export def "logistics-pvt-inventory-reservations-acknowledge create-acknowledgment" [
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationId' must be non-empty" } }
  let full_url = (build-url $base ({reservation_id: (encode-path-segment $reservation_id)} | format pattern "/api/logistics/pvt/inventory/reservations/{reservation_id}/acknowledge") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Cancel reservation
#
# POST /api/logistics/pvt/inventory/reservations/{reservationId}/cancel
# operationId: CancelReservation
export def "logistics-pvt-inventory-reservations-cancel cancel" [
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationId' must be non-empty" } }
  let full_url = (build-url $base ({reservation_id: (encode-path-segment $reservation_id)} | format pattern "/api/logistics/pvt/inventory/reservations/{reservation_id}/cancel") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Confirm reservation
#
# POST /api/logistics/pvt/inventory/reservations/{reservationId}/confirm
# operationId: ConfirmReservation
export def "logistics-pvt-inventory-reservations-confirm confirm" [
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationId' must be non-empty" } }
  let full_url = (build-url $base ({reservation_id: (encode-path-segment $reservation_id)} | format pattern "/api/logistics/pvt/inventory/reservations/{reservation_id}/confirm") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List reservation by warehouse and SKU
#
# GET /api/logistics/pvt/inventory/reservations/{warehouseId}/{skuId}
# operationId: ReservationbyWarehouseandSku
export def "logistics-pvt-inventory-reservations get-reservationby-warehouseand-sku" [
  warehouse_id: string
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  let full_url = (build-url $base ({warehouse_id: (encode-path-segment $warehouse_id), sku_id: (encode-path-segment $sku_id)} | format pattern "/api/logistics/pvt/inventory/reservations/{warehouse_id}/{sku_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List inventory by SKU
#
# GET /api/logistics/pvt/inventory/skus/{skuId}
# operationId: InventoryBySku
export def "logistics-pvt-inventory-skus get" [
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> record<balance: table<hasUnlimitedQuantity: bool, reservedQuantity: int, totalQuantity: int, warehouseId: string, warehouseName: string>, skuId: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/logistics/pvt/inventory/skus/{sku_id}") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update inventory by SKU and warehouse
#
# PUT /api/logistics/pvt/inventory/skus/{skuId}/warehouses/{warehouseId}
# operationId: UpdateInventoryBySkuandWarehouse
export def "logistics-pvt-inventory-skus-warehouses update-by-skuand" [
  sku_id: string
  warehouse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
  --date-utc-on-balance-system: string # Defines the corresponding moment to the informed warehouse. It is useful due to the liberation of handling order reservations. When requested as `null`, this value will be the date/time of the request. Its format is `DateTimeOffset`, as in `yyyy-mm-dd-Thh:mm:ss`. For example: `2022-03-15T00:52:16`. (e.g. null)
  quantity: int # format: int32
  time_to_refill_deprecated: string
  --unlimited-quantity: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  if ($warehouse_id | is-empty) { error make --unspanned { msg: "path parameter 'warehouseId' must be non-empty" } }
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), warehouse_id: (encode-path-segment $warehouse_id)} | format pattern "/api/logistics/pvt/inventory/skus/{sku_id}/warehouses/{warehouse_id}") $auth.query)
  let req_body = {"dateUtcOnBalanceSystem": $date_utc_on_balance_system, "quantity": $quantity, "timeToRefill (deprecated)": $time_to_refill_deprecated, "unlimitedQuantity": $unlimited_quantity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List shipping policies
#
# GET /api/logistics/pvt/shipping-policies
export def "logistics-pvt-shipping-policies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Desired number of pages to retrieve information from your Shipping Policies. (e.g. page)
  --per-page: string # Desired number of items per page, to retrieve information from your Shipping Policies. (e.g. perPage)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/logistics/pvt/shipping-policies" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "perPage": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create shipping policy
#
# POST /api/logistics/pvt/shipping-policies
# --businessHourSettings shape: {carrierBusinessHours: list, isOpenOutsideBusinessHours: bool}
# --carrierSchedule item shape: {dayOfWeek?: int, timeLimit?: string}
# --cubicWeightSettings shape: {minimunAcceptableVolumetricWeight: float, volumetricFactor: float}
# --deliveryScheduleSettings shape: {dayOfWeekForDelivery: list, maxRangeDelivery: float, useDeliverySchedule: bool}
# --maxDimension shape: {largestMeasure: float, maxMeasureSum: float}
# --modalSettings shape: {modals: list, useOnlyItemsWithDefinedModal: bool}
# --pickupPointsSettings shape: {pickupPointIds: list, pickupPointTags: list, sellers: list}
# --weekendAndHolidays shape: {holiday: bool, saturday: bool, sunday: bool}
export def "logistics-pvt-shipping-policies create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
  business_hour_settings: record # Business hour configuration. (e.g. {carrierBusinessHours: [{closingTime: 18:59:59, dayOfWeek: 0, openingTime: 09:00:00}], isOpenOutsideBusinessHours: true}) — shape: {carrierBusinessHours: list, isOpenOutsideBusinessHours: bool}
  --carrier-schedule: list # Schedule sent by the carrier, to configure Shipping policy — item shape: {dayOfWeek?: int, timeLimit?: string}
  cubic_weight_settings: record # Measure that accounts package's volume, and not only weight. (e.g. {minimunAcceptableVolumetricWeight: 5, volumetricFactor: 3}) — shape: {minimunAcceptableVolumetricWeight: float, volumetricFactor: float}
  delivery_schedule_settings: record # Settings for the Scheduled Delivery feature. (e.g. {dayOfWeekForDelivery: [{dayOfWeek: 2, deliveryRanges: [{endTime: 12:00:00, listPrice: 5, startTime: 08:00:00}, {endTime: 18:00:00, listPrice: 10, startTime: 12:01:00}]}], maxRangeDelivery: 5, useDeliverySchedule: true}) — shape: {dayOfWeekForDelivery: list, maxRangeDelivery: float, useDeliverySchedule: bool}
  id: string # ID of the shipping policy. (e.g. 123)
  --is-active: oneof<nothing, bool> # Indicates whether shipping policy is active or not. (e.g. false)
  max_dimension: record # Object containing attributes of maximum dimension permitted by the shipping policy (carrier). (e.g. {largestMeasure: 15, maxMeasureSum: 25}) — shape: {largestMeasure: float, maxMeasureSum: float}
  maximum_value_aceptable: float # Maximum value accepted by the carrier, to realize the shipping. (e.g. 0)
  minimum_value_aceptable: float # Minimum value accepted by the carrier, to realize the shipping. (e.g. 0)
  modal_settings: record # Configurations for the [modal](https://help.vtex.com/en/tutorial/how-does-the-modal-work--tutorials_125), which is the attachement of a specific product to a carrier specialized in delivering that type of product. (e.g. {modals: [Modal1], useOnlyItemsWithDefinedModal: false}) — shape: {modals: list, useOnlyItemsWithDefinedModal: bool}
  name: string # Name of the shipping policy. (e.g. Normal)
  number_of_items_per_shipment: int # Capacity of your store's logistics of shipment, determines number of items permitted per shipment. (e.g. 5)
  pickup_points_settings: record # Configuration for Pickup Points. (e.g. {pickupPointIds: [null], pickupPointTags: [null], sellers: [cosmetics2]}) — shape: {pickupPointIds: list, pickupPointTags: list, sellers: list}
  shipping_method: string # Type of shipping available for this shipping policy (carrier). Options shown on freight simulation (e.g. Normal)
  weekend_and_holidays: record # If the shipping policy includes deliveries on weekends and holidays. (e.g. {holiday: false, saturday: false, sunday: false}) — shape: {holiday: bool, saturday: bool, sunday: bool}
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/shipping-policies" $auth.query)
  let req_body = {"businessHourSettings": $business_hour_settings, "carrierSchedule": $carrier_schedule, "cubicWeightSettings": $cubic_weight_settings, "deliveryScheduleSettings": $delivery_schedule_settings, "id": $id, "isActive": $is_active, "maxDimension": $max_dimension, "maximumValueAceptable": $maximum_value_aceptable, "minimumValueAceptable": $minimum_value_aceptable, "modalSettings": $modal_settings, "name": $name, "numberOfItemsPerShipment": $number_of_items_per_shipment, "pickupPointsSettings": $pickup_points_settings, "shippingMethod": $shipping_method, "weekendAndHolidays": $weekend_and_holidays} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete shipping policies by ID
#
# DELETE /api/logistics/pvt/shipping-policies/{id}
export def "logistics-pvt-shipping-policies delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/logistics/pvt/shipping-policies/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve shipping policy by ID
#
# GET /api/logistics/pvt/shipping-policies/{id}
export def "logistics-pvt-shipping-policies get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/logistics/pvt/shipping-policies/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update shipping policy
#
# PUT /api/logistics/pvt/shipping-policies/{id}
# --deliveryScheduleSettings shape: {dayOfWeekForDelivery: list, maxRangeDelivery: float, useDeliverySchedule: bool}
# --maxDimension shape: {largestMeasure: float, maxMeasureSum: float}
export def "logistics-pvt-shipping-policies update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
  --delivery-on-weekends: oneof<nothing, bool> # If the shipping policy (carrier) delivers on weekends (e.g. false)
  --delivery-schedule-settings: record # Settings for the Scheduled Delivery feature. — shape: {dayOfWeekForDelivery: list, maxRangeDelivery: float, useDeliverySchedule: bool}
  --is-active: oneof<nothing, bool> # If the shipping policy is active or not. (e.g. true)
  max_dimension: record # Object containing attributes of maximum dimension permitted by the shipping policy (carrier). (e.g. {largestMeasure: 10, maxMeasureSum: 30}) — shape: {largestMeasure: float, maxMeasureSum: float}
  name: string # Name of the shipping policy (e.g. Correios PAC)
  shipping_method: string # Type of shipping available for this shipping policy (carrier). Options shown on freight simulation. (e.g. Normal)
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/logistics/pvt/shipping-policies/{id}") $auth.query)
  let req_body = {"deliveryOnWeekends": $delivery_on_weekends, "deliveryScheduleSettings": $delivery_schedule_settings, "isActive": $is_active, "maxDimension": $max_dimension, "name": $name, "shippingMethod": $shipping_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Calculate SLA
#
# POST /api/logistics/pvt/shipping/calculate
# operationId: CalculateSLA
export def "logistics-pvt-shipping-calculate create-sla" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --body: list
]: any -> list<table<aditionalTimeBlockedDays: string, availabilityQuantity: int, carrierSchedule: list, coordinates: string, deliveryOnWeekends: bool, deliveryWindows: list, dockId: string, dockTime: string, freightTableId: string, freightTableName: string, itemId: string, listPrice: float, location: record, pickupStoreInfo: string, quantity: int, restrictedFreight: string, salesChannel: string, slaType: string, slaTypeName: string, timeToDockPlusDockTime: string, totalTime: string, transitTime: string, wareHouseId: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o LOGISTICS_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o LOGISTICS_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/logistics/pvt/shipping/calculate" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json; charset=utf-8")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}
