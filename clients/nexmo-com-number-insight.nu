# Auto-generated client for Number Insight API v1.2.1
# Source: https://api.apis.guru/v2/specs/nexmo.com/number-insight/1.2.1/openapi.json
# Auth (apiKey): --token-apikey flag or $env.NUMBER_INSIGHT_API_APIKEY_TOKEN
# Auth (apiSecret): --token-apisecret flag or $env.NUMBER_INSIGHT_API_APISECRET_TOKEN

const BASE_URL = "https://api.nexmo.com/ni"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o NUMBER_INSIGHT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
    "query-api_secret" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_secret")=(encode-path-segment $token_val)", location: "query"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| merge-headers $acc $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

def base-url-completer [] { ["https://api.nexmo.com/ni"] }
def auth-scheme-completer [] { ["query-api_key" "query-api_secret"] }

# Completers for enum parameters
def format-completer [] { ["json" "xml"] }
def accept-completer [] { ["application/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-apikey" "token-apisecret"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-number-insight-async" "get-number-insight-advanced" "get-number-insight-basic" "get-number-insight-standard" "commands"] | sort) } | get name | first)
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

# Advanced Number Insight (async)
#
# GET /advanced/async/{format}
# operationId: getNumberInsightAsync
@deprecated --flag ip
export def "get-number-insight-async" [
  format: string@format-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for apiKey (api_key)
  --token-apisecret: string # Auth token for apiSecret (api_secret)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --callback: string # The callback URL (required, format: uriref, e.g. https://example.com/callback)
  --number: string # A single phone number that you need insight about in national or international format. (required, e.g. 447700900000)
  --country: string # If a number does not have a country code or is uncertain, set the two-character country code. This code must be in ISO 3166-1 alpha-2 format and in upper case. For example, GB or US. If you set country and number is already in [E.164](https://en.wikipedia.org/wiki/E.164) format, country must match the country code in number. (e.g. GB)
  --cnam: oneof<nothing, bool> # Indicates if the name of the person who owns the phone number should be looked up and returned in the response. Set to true to receive phone number owner name in the response. This features is available for US numbers only and incurs an additional charge. (default: false, e.g. true)
  --ip: string # This parameter is deprecated as we are no longer able to retrieve reliable IP data globally from carriers. (DEPRECATED, e.g. 123.0.0.255)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_apikey | default ($env | get -o NUMBER_INSIGHT_API_APIKEY_TOKEN | default "")) "query-api_key") (build-auth ($token_apisecret | default ($env | get -o NUMBER_INSIGHT_API_APISECRET_TOKEN | default "")) "query-api_secret")])
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($callback == null) { error make --unspanned { msg: "required query parameter 'callback' missing: pass --callback" } }
  if ($number == null) { error make --unspanned { msg: "required query parameter 'number' missing: pass --number" } }
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "number" $number "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "cnam" $cnam "scalar") (serialize-qp "ip" $ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/advanced/async/{format}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"callback": $callback, "number": $number, "country": $country, "cnam": $cnam, "ip": $ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Advanced Number Insight (sync)
#
# GET /advanced/{format}
# operationId: getNumberInsightAdvanced
@deprecated --flag ip
export def "get-number-insight-advanced" [
  format: string@format-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for apiKey (api_key)
  --token-apisecret: string # Auth token for apiSecret (api_secret)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --real-time-data: oneof<nothing, bool> # A boolean to choose whether to get real time data back in the response. (e.g. true)
  --number: string # A single phone number that you need insight about in national or international format. (required, e.g. 447700900000)
  --country: string # If a number does not have a country code or is uncertain, set the two-character country code. This code must be in ISO 3166-1 alpha-2 format and in upper case. For example, GB or US. If you set country and number is already in [E.164](https://en.wikipedia.org/wiki/E.164) format, country must match the country code in number. (e.g. GB)
  --cnam: oneof<nothing, bool> # Indicates if the name of the person who owns the phone number should be looked up and returned in the response. Set to true to receive phone number owner name in the response. This features is available for US numbers only and incurs an additional charge. (default: false, e.g. true)
  --ip: string # This parameter is deprecated as we are no longer able to retrieve reliable IP data globally from carriers. (DEPRECATED, e.g. 123.0.0.255)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_apikey | default ($env | get -o NUMBER_INSIGHT_API_APIKEY_TOKEN | default "")) "query-api_key") (build-auth ($token_apisecret | default ($env | get -o NUMBER_INSIGHT_API_APISECRET_TOKEN | default "")) "query-api_secret")])
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($number == null) { error make --unspanned { msg: "required query parameter 'number' missing: pass --number" } }
  let qp = [(serialize-qp "real_time_data" $real_time_data "scalar") (serialize-qp "number" $number "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "cnam" $cnam "scalar") (serialize-qp "ip" $ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/advanced/{format}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"real_time_data": $real_time_data, "number": $number, "country": $country, "cnam": $cnam, "ip": $ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Basic Number Insight
#
# GET /basic/{format}
# operationId: getNumberInsightBasic
export def "get-number-insight-basic" [
  format: string@format-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for apiKey (api_key)
  --token-apisecret: string # Auth token for apiSecret (api_secret)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --number: string # A single phone number that you need insight about in national or international format. (required, e.g. 447700900000)
  --country: string # If a number does not have a country code or is uncertain, set the two-character country code. This code must be in ISO 3166-1 alpha-2 format and in upper case. For example, GB or US. If you set country and number is already in [E.164](https://en.wikipedia.org/wiki/E.164) format, country must match the country code in number. (e.g. GB)
]: nothing -> oneof<record<country_code: string, country_code_iso3: string, country_name: string, country_prefix: string, international_format_number: string, national_format_number: string, request_id: string, status: int, status_message: string>, string, nothing> {
  let auth = (merge-auth [(build-auth ($token_apikey | default ($env | get -o NUMBER_INSIGHT_API_APIKEY_TOKEN | default "")) "query-api_key") (build-auth ($token_apisecret | default ($env | get -o NUMBER_INSIGHT_API_APISECRET_TOKEN | default "")) "query-api_secret")])
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($number == null) { error make --unspanned { msg: "required query parameter 'number' missing: pass --number" } }
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/basic/{format}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"number": $number, "country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Standard Number Insight
#
# GET /standard/{format}
# operationId: getNumberInsightStandard
export def "get-number-insight-standard" [
  format: string@format-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for apiKey (api_key)
  --token-apisecret: string # Auth token for apiSecret (api_secret)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --number: string # A single phone number that you need insight about in national or international format. (required, e.g. 447700900000)
  --country: string # If a number does not have a country code or is uncertain, set the two-character country code. This code must be in ISO 3166-1 alpha-2 format and in upper case. For example, GB or US. If you set country and number is already in [E.164](https://en.wikipedia.org/wiki/E.164) format, country must match the country code in number. (e.g. GB)
  --cnam: oneof<nothing, bool> # Indicates if the name of the person who owns the phone number should be looked up and returned in the response. Set to true to receive phone number owner name in the response. This features is available for US numbers only and incurs an additional charge. (default: false, e.g. true)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_apikey | default ($env | get -o NUMBER_INSIGHT_API_APIKEY_TOKEN | default "")) "query-api_key") (build-auth ($token_apisecret | default ($env | get -o NUMBER_INSIGHT_API_APISECRET_TOKEN | default "")) "query-api_secret")])
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($number == null) { error make --unspanned { msg: "required query parameter 'number' missing: pass --number" } }
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "cnam" $cnam "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/standard/{format}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"number": $number, "country": $country, "cnam": $cnam} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
