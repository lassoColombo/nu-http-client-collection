# Auto-generated client for CIS Automotive API v1.0
# Source: https://api.apis.guru/v2/specs/autodealerdata.com/1.0/openapi.json
# Auth: --token flag or $env.CIS_AUTOMOTIVE_API_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CIS_AUTOMOTIVE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["days-supply-days-supply-get" "days-to-sell-days-to-sell-get" "get-brand-names-get-brands-get" "get-dealers-get-dealers-get" "get-dealers-get-dealers-by-id-get" "get-dealers-get-dealers-by-region-get" "get-model-names-all-get-inactive-models-get" "get-model-names-get-models-get" "get-region-brand-market-share-get-region-brand-market-share-get" "get-region-market-share-get-region-market-share-get" "get-regions-get-regions-get" "get-sub-user-keys-get-sub-user-keys-get" "make-token-get-token-get" "make-token-get-token-post" "get-avg-list-price-list-price-get" "get-listings-by-dealer-listings-get" "get-listings2-listings2-get" "get-listings-by-dealer-listings-by-date-get" "get-listings-by-region-listings-by-region-get" "get-listings-by-region-and-date-listings-by-region-and-date-get" "listings-by-zip-code-listings-by-zip-code-get" "listings-by-zip-code-and-date-listings-by-zip-code-and-date-get" "make-sub-user-key-make-sub-user-key-post" "get-model-used-dist-model-year-dist-get" "get-dealer-sales-region-daily-sales-get" "get-dealer-sales-region-sales-get" "revoke-sub-user-key-revoke-sub-user-key-put" "get-avg-sale-price-sale-price-get" "get-model-sale-buckets-sale-price-histogram-get" "get-market3-similar-sale-price-get" "get-top-models-top-models-get" "get-market4-valuation-get" "get-history2-vehicle-history-get" "get-vehicle-seen-vehicle-seen-get" "vin-decode-vin-decode-get" "commands"] | sort) } | get name | first)
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

# Days worth of supply left on dealer lots
#
# GET /daysSupply
# operationId: daysSupply_daysSupply_get
export def "days-supply-days-supply-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --brand-name: string # required
  --region-name: string # default: REGION_STATE_CA
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($brand_name == null) { error make --unspanned { msg: "required query parameter 'brandName' missing: pass --brand-name" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/daysSupply" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Days a vehicle takes to sell
#
# GET /daysToSell
# operationId: daysToSell_daysToSell_get
export def "days-to-sell-days-to-sell-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --brand-name: string # required
  --region-name: string # default: REGION_STATE_CA
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($brand_name == null) { error make --unspanned { msg: "required query parameter 'brandName' missing: pass --brand-name" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/daysToSell" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of brand names
#
# GET /getBrands
# operationId: getBrandNames_getBrands_get
export def "get-brand-names-get-brands-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: list<string>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getBrands" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Premium. Dealers in a zip code.
#
# GET /getDealers
# operationId: getDealers_getDealers_get
export def "get-dealers-get-dealers-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --zip-code: int # required
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: table<address: string, dealerName: string, ids: list, state: string, zipCode: int>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($zip_code == null) { error make --unspanned { msg: "required query parameter 'zipCode' missing: pass --zip-code" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "zipCode" $zip_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getDealers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "zipCode": $zip_code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Premium. Dealers by ID
#
# GET /getDealersByID
# operationId: getDealers_getDealersByID_get
export def "get-dealers-get-dealers-by-id-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --dealer-id: int # required
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: table<address: string, dealerName: string, ids: list, state: string, zipCode: int>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($dealer_id == null) { error make --unspanned { msg: "required query parameter 'dealerID' missing: pass --dealer-id" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "dealerID" $dealer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getDealersByID" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "dealerID": $dealer_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Premium. Dealers in a region.
#
# GET /getDealersByRegion
# operationId: getDealers_getDealersByRegion_get
export def "get-dealers-get-dealers-by-region-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --region-name: string # default: REGION_STATE_CA
  --page: int # default: 1
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: record<dealers: list<record>, maxPages: int, page: int>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getDealersByRegion" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "regionName": $region_name, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of model names including discontinued models
#
# GET /getInactiveModels
# operationId: getModelNamesAll_getInactiveModels_get
export def "get-model-names-all-get-inactive-models-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --brand-name: string # required
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: table<modelName: string>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($brand_name == null) { error make --unspanned { msg: "required query parameter 'brandName' missing: pass --brand-name" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getInactiveModels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "brandName": $brand_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of model names
#
# GET /getModels
# operationId: getModelNames_getModels_get
export def "get-model-names-get-models-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --brand-name: string # required
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: table<modelName: string>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($brand_name == null) { error make --unspanned { msg: "required query parameter 'brandName' missing: pass --brand-name" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getModels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "brandName": $brand_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Market share of a brand in region
#
# GET /getRegionBrandMarketShare
# operationId: getRegionBrandMarketShare_getRegionBrandMarketShare_get
export def "get-region-brand-market-share-get-region-brand-market-share-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --brand-name: string # required
  --region-name: string # default: REGION_STATE_CA
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($brand_name == null) { error make --unspanned { msg: "required query parameter 'brandName' missing: pass --brand-name" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getRegionBrandMarketShare" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Market share of all brands in region
#
# GET /getRegionMarketShare
# operationId: getRegionMarketShare_getRegionMarketShare_get
export def "get-region-market-share-get-region-market-share-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --region-name: string # default: REGION_STATE_CA
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getRegionMarketShare" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "regionName": $region_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of region names
#
# GET /getRegions
# operationId: getRegions_getRegions_get
export def "get-regions-get-regions-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: list<string>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getRegions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all Sub User Keys associated with your account.
#
# GET /getSubUserKeys
# operationId: getSubUserKeys_getSubUserKeys_get
export def "get-sub-user-keys-get-sub-user-keys-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # required
  --api-key: string # required
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id == null) { error make --unspanned { msg: "required query parameter 'apiID' missing: pass --api-id" } }
  if ($api_key == null) { error make --unspanned { msg: "required query parameter 'apiKey' missing: pass --api-key" } }
  let qp = [(serialize-qp "apiID" $api_id "scalar") (serialize-qp "apiKey" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getSubUserKeys" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"apiID": $api_id, "apiKey": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a JWT from your API credentials
#
# GET /getToken
# operationId: makeToken_getToken_get
export def "make-token-get-token-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # required
  --api-key: string # required
]: nothing -> oneof<record<createdOn: int, expires: int, token: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id == null) { error make --unspanned { msg: "required query parameter 'apiID' missing: pass --api-id" } }
  if ($api_key == null) { error make --unspanned { msg: "required query parameter 'apiKey' missing: pass --api-key" } }
  let qp = [(serialize-qp "apiID" $api_id "scalar") (serialize-qp "apiKey" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getToken" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"apiID": $api_id, "apiKey": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a JWT from your API credentials
#
# POST /getToken
# operationId: makeToken_getToken_post
export def "make-token-get-token-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # required
  --api-key: string # required
]: nothing -> oneof<record<createdOn: int, expires: int, token: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id == null) { error make --unspanned { msg: "required query parameter 'apiID' missing: pass --api-id" } }
  if ($api_key == null) { error make --unspanned { msg: "required query parameter 'apiKey' missing: pass --api-key" } }
  let qp = [(serialize-qp "apiID" $api_id "scalar") (serialize-qp "apiKey" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getToken" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"apiID": $api_id, "apiKey": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Stats on ask price of new vehicles
#
# GET /listPrice
# operationId: getAvgListPrice_listPrice_get
export def "get-avg-list-price-list-price-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --brand-name: string # required
  --region-name: string # default: REGION_STATE_CA
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: table<average: float, median: float, name: string, pVariance: float, stdDev: float>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($brand_name == null) { error make --unspanned { msg: "required query parameter 'brandName' missing: pass --brand-name" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listPrice" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listings by Dealer ID
#
# GET /listings
# operationId: getListingsByDealer_listings_get
export def "get-listings-by-dealer-listings-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --dealer-id: int # required
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($dealer_id == null) { error make --unspanned { msg: "required query parameter 'dealerID' missing: pass --dealer-id" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "dealerID" $dealer_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "dealerID": $dealer_id, "page": $page, "newCars": $new_cars} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Flexible Listing Search
#
# GET /listings2
# operationId: getListings2_listings2_get
export def "get-listings2-listings2-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --dealer-id: int # default: 0
  --zip-code: int # default: 0
  --latitude: float # default: 0
  --longitude: float # default: 0
  --radius: float # default: 0
  --region-name: string
  --brand-name: string
  --model-name: string
  --model-year: int # default: 0
  --mileage-low: int # default: 0
  --mileage-high: int # default: 0
  --start-date: string # format: date
  --end-date: string # format: date
  --days-back: int # default: 45
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
  --extended-search: oneof<nothing, bool> # default: false
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "dealerID" $dealer_id "scalar") (serialize-qp "zipCode" $zip_code "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "modelName" $model_name "scalar") (serialize-qp "modelYear" $model_year "scalar") (serialize-qp "mileageLow" $mileage_low "scalar") (serialize-qp "mileageHigh" $mileage_high "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "daysBack" $days_back "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar") (serialize-qp "extendedSearch" $extended_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listings2" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "dealerID": $dealer_id, "zipCode": $zip_code, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "regionName": $region_name, "brandName": $brand_name, "modelName": $model_name, "modelYear": $model_year, "mileageLow": $mileage_low, "mileageHigh": $mileage_high, "startDate": $start_date, "endDate": $end_date, "daysBack": $days_back, "page": $page, "newCars": $new_cars, "extendedSearch": $extended_search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listings by Dealer ID and Date
#
# GET /listingsByDate
# operationId: getListingsByDealer_listingsByDate_get
export def "get-listings-by-dealer-listings-by-date-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --dealer-id: int # required
  --start-date: string # required, format: date
  --end-date: string # required, format: date
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($dealer_id == null) { error make --unspanned { msg: "required query parameter 'dealerID' missing: pass --dealer-id" } }
  if ($start_date == null) { error make --unspanned { msg: "required query parameter 'startDate' missing: pass --start-date" } }
  if ($end_date == null) { error make --unspanned { msg: "required query parameter 'endDate' missing: pass --end-date" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "dealerID" $dealer_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listingsByDate" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "dealerID": $dealer_id, "startDate": $start_date, "endDate": $end_date, "page": $page, "newCars": $new_cars} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listings by Region
#
# GET /listingsByRegion
# operationId: getListingsByRegion_listingsByRegion_get
export def "get-listings-by-region-listings-by-region-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --region-name: string # required
  --model-name: string # required
  --days-back: int # default: 10
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($region_name == null) { error make --unspanned { msg: "required query parameter 'regionName' missing: pass --region-name" } }
  if ($model_name == null) { error make --unspanned { msg: "required query parameter 'modelName' missing: pass --model-name" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "modelName" $model_name "scalar") (serialize-qp "daysBack" $days_back "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listingsByRegion" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "regionName": $region_name, "modelName": $model_name, "daysBack": $days_back, "page": $page, "newCars": $new_cars} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listings by Region and Date
#
# GET /listingsByRegionAndDate
# operationId: getListingsByRegionAndDate_listingsByRegionAndDate_get
export def "get-listings-by-region-and-date-listings-by-region-and-date-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --region-name: string # required
  --model-name: string # required
  --start-date: string # required, format: date
  --end-date: string # required, format: date
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($region_name == null) { error make --unspanned { msg: "required query parameter 'regionName' missing: pass --region-name" } }
  if ($model_name == null) { error make --unspanned { msg: "required query parameter 'modelName' missing: pass --model-name" } }
  if ($start_date == null) { error make --unspanned { msg: "required query parameter 'startDate' missing: pass --start-date" } }
  if ($end_date == null) { error make --unspanned { msg: "required query parameter 'endDate' missing: pass --end-date" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "modelName" $model_name "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listingsByRegionAndDate" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "regionName": $region_name, "modelName": $model_name, "startDate": $start_date, "endDate": $end_date, "page": $page, "newCars": $new_cars} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listings by ZipCode
#
# GET /listingsByZipCode
# operationId: listingsByZipCode_listingsByZipCode_get
export def "listings-by-zip-code-listings-by-zip-code-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --zip-code: int # required
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
  --model-name: string
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($zip_code == null) { error make --unspanned { msg: "required query parameter 'zipCode' missing: pass --zip-code" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "zipCode" $zip_code "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar") (serialize-qp "modelName" $model_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listingsByZipCode" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "zipCode": $zip_code, "page": $page, "newCars": $new_cars, "modelName": $model_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listings by ZipCode and Date
#
# GET /listingsByZipCodeAndDate
# operationId: listingsByZipCodeAndDate_listingsByZipCodeAndDate_get
export def "listings-by-zip-code-and-date-listings-by-zip-code-and-date-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --zip-code: int # required
  --start-date: string # required, format: date
  --end-date: string # required, format: date
  --page: int # default: 1
  --new-cars: oneof<nothing, bool> # default: true
  --model-name: string
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: record<listings: list<record>, maxPages: int, page: int>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($zip_code == null) { error make --unspanned { msg: "required query parameter 'zipCode' missing: pass --zip-code" } }
  if ($start_date == null) { error make --unspanned { msg: "required query parameter 'startDate' missing: pass --start-date" } }
  if ($end_date == null) { error make --unspanned { msg: "required query parameter 'endDate' missing: pass --end-date" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "zipCode" $zip_code "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "newCars" $new_cars "scalar") (serialize-qp "modelName" $model_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listingsByZipCodeAndDate" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "zipCode": $zip_code, "startDate": $start_date, "endDate": $end_date, "page": $page, "newCars": $new_cars, "modelName": $model_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Generate a Sub User Key that can be used by your users to make API calls in frontend applications.
#
# POST /makeSubUserKey
# operationId: makeSubUserKey_makeSubUserKey_post
export def "make-sub-user-key-make-sub-user-key-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # required
  --api-key: string # required
  --site-name: string # default: localhost
  --end-points: list<string> # default: [*]
]: any -> oneof<record<createdOn: int, domain: string, endPoints: list<string>, expires: int, token: string, uuid: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id == null) { error make --unspanned { msg: "required query parameter 'apiID' missing: pass --api-id" } }
  if ($api_key == null) { error make --unspanned { msg: "required query parameter 'apiKey' missing: pass --api-key" } }
  let qp = [(serialize-qp "apiID" $api_id "scalar") (serialize-qp "apiKey" $api_key "scalar") (serialize-qp "siteName" $site_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/makeSubUserKey" $qp $auth.query)
  let req_body = {"endPoints": $end_points} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"apiID": $api_id, "apiKey": $api_key, "siteName": $site_name} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Used market share of model year by model
#
# GET /modelYearDist
# operationId: getModelUsedDist_modelYearDist_get
export def "get-model-used-dist-model-year-dist-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --model-name: string # required
  --brand-name: string # required
  --region-name: string # default: REGION_STATE_CA
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: table<brandName: string, modelName: string, percentOfMarket: float, year: int>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($model_name == null) { error make --unspanned { msg: "required query parameter 'modelName' missing: pass --model-name" } }
  if ($brand_name == null) { error make --unspanned { msg: "required query parameter 'brandName' missing: pass --brand-name" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "modelName" $model_name "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/modelYearDist" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "modelName": $model_name, "brandName": $brand_name, "regionName": $region_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Brand sales by region and Day
#
# GET /regionDailySales
# operationId: getDealerSales_regionDailySales_get
export def "get-dealer-sales-region-daily-sales-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --brand-name: string # required
  --region-name: string # required
  --day: string # required, format: date
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($brand_name == null) { error make --unspanned { msg: "required query parameter 'brandName' missing: pass --brand-name" } }
  if ($region_name == null) { error make --unspanned { msg: "required query parameter 'regionName' missing: pass --region-name" } }
  if ($day == null) { error make --unspanned { msg: "required query parameter 'day' missing: pass --day" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "day" $day "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/regionDailySales" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name, "day": $day} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Premium. Brand sales by region and month
#
# GET /regionSales
# operationId: getDealerSales_regionSales_get
export def "get-dealer-sales-region-sales-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --brand-name: string # required
  --region-name: string # required
  --month: string # required, format: date
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($brand_name == null) { error make --unspanned { msg: "required query parameter 'brandName' missing: pass --brand-name" } }
  if ($region_name == null) { error make --unspanned { msg: "required query parameter 'regionName' missing: pass --region-name" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'month' missing: pass --month" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "month" $month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/regionSales" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name, "month": $month} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Revoke a Sub User Key associated with your account.
#
# PUT /revokeSubUserKey
# operationId: revokeSubUserKey_revokeSubUserKey_put
export def "revoke-sub-user-key-revoke-sub-user-key-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # required
  --api-key: string # required
  --sub-user-key-uuid: string # required
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id == null) { error make --unspanned { msg: "required query parameter 'apiID' missing: pass --api-id" } }
  if ($api_key == null) { error make --unspanned { msg: "required query parameter 'apiKey' missing: pass --api-key" } }
  if ($sub_user_key_uuid == null) { error make --unspanned { msg: "required query parameter 'subUserKeyUUID' missing: pass --sub-user-key-uuid" } }
  let qp = [(serialize-qp "apiID" $api_id "scalar") (serialize-qp "apiKey" $api_key "scalar") (serialize-qp "subUserKeyUUID" $sub_user_key_uuid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/revokeSubUserKey" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"apiID": $api_id, "apiKey": $api_key, "subUserKeyUUID": $sub_user_key_uuid} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Stats on sale price of new vehicles
#
# GET /salePrice
# operationId: getAvgSalePrice_salePrice_get
export def "get-avg-sale-price-sale-price-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --brand-name: string # required
  --region-name: string # default: REGION_STATE_CA
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: table<average: float, median: float, name: string, pVariance: float, stdDev: float>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($brand_name == null) { error make --unspanned { msg: "required query parameter 'brandName' missing: pass --brand-name" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/salePrice" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "brandName": $brand_name, "regionName": $region_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Histogram of sales price of new vehicles by model
#
# GET /salePriceHistogram
# operationId: getModelSaleBuckets_salePriceHistogram_get
export def "get-model-sale-buckets-sale-price-histogram-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --model-name: string # required
  --brand-name: string # required
  --region-name: string # default: REGION_STATE_CA
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: table<bucket: float, modelName: string, percentOfMarket: float>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($model_name == null) { error make --unspanned { msg: "required query parameter 'modelName' missing: pass --model-name" } }
  if ($brand_name == null) { error make --unspanned { msg: "required query parameter 'brandName' missing: pass --brand-name" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "modelName" $model_name "scalar") (serialize-qp "brandName" $brand_name "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/salePriceHistogram" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "modelName": $model_name, "brandName": $brand_name, "regionName": $region_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Premium. Simple Vehicle Market Report
#
# GET /similarSalePrice
# operationId: getMarket3_similarSalePrice_get
export def "get-market3-similar-sale-price-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --vin: string # required
  --region-name: string # default: REGION_STATE_CA
  --days-back: int # default: 45
  --same-year: oneof<nothing, bool> # default: false
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: record<daysBack: int, mileCount: int, milesAvg: float, milesStdDev: float, newCount: int, newSaleAvg: float, newSaleStdDev: float, usedCount: int, usedSaleAvg: float, usedSaleStdDev: float>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($vin == null) { error make --unspanned { msg: "required query parameter 'vin' missing: pass --vin" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "daysBack" $days_back "scalar") (serialize-qp "sameYear" $same_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/similarSalePrice" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "vin": $vin, "regionName": $region_name, "daysBack": $days_back, "sameYear": $same_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Top models in a given region
#
# GET /topModels
# operationId: getTopModels_topModels_get
export def "get-top-models-top-models-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --region-name: string # default: REGION_STATE_CA
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: table<brandMarketShare: float, brandName: string, modelName: string, percentOfBrandSales: float, percentOfTopSales: float>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "regionName" $region_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/topModels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "regionName": $region_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Premium. Simple Vehicle Market Report Over Arbitrary Locations and Vehicles.
#
# GET /valuation
# operationId: getMarket4_valuation_get
export def "get-market4-valuation-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --vin: string # required
  --dealer-id: int # default: 0
  --zip-code: int # default: 0
  --latitude: float # default: 0
  --longitude: float # default: 0
  --radius: float # default: 0
  --region-name: string
  --mileage-low: int # default: 0
  --mileage-high: int # default: 0
  --start-date: string # format: date
  --end-date: string # format: date
  --days-back: int # default: 45
  --new-cars: oneof<nothing, bool> # default: false
  --extended-search: oneof<nothing, bool> # default: false
  --same-year: oneof<nothing, bool> # default: false
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: record<daysBack: int, mileCount: int, milesAvg: float, milesStdDev: float, newCount: int, newSaleAvg: float, newSaleStdDev: float, usedCount: int, usedSaleAvg: float, usedSaleStdDev: float>, endDate: string, modelName: string, msg: string, regionName: string, startDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($vin == null) { error make --unspanned { msg: "required query parameter 'vin' missing: pass --vin" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "dealerID" $dealer_id "scalar") (serialize-qp "zipCode" $zip_code "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "regionName" $region_name "scalar") (serialize-qp "mileageLow" $mileage_low "scalar") (serialize-qp "mileageHigh" $mileage_high "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "daysBack" $days_back "scalar") (serialize-qp "newCars" $new_cars "scalar") (serialize-qp "extendedSearch" $extended_search "scalar") (serialize-qp "sameYear" $same_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/valuation" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "vin": $vin, "dealerID": $dealer_id, "zipCode": $zip_code, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "regionName": $region_name, "mileageLow": $mileage_low, "mileageHigh": $mileage_high, "startDate": $start_date, "endDate": $end_date, "daysBack": $days_back, "newCars": $new_cars, "extendedSearch": $extended_search, "sameYear": $same_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Premium. Simple Vehicle History Report
#
# GET /vehicleHistory
# operationId: getHistory2_vehicleHistory_get
export def "get-history2-vehicle-history-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --vin: string # required
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: record<data: list<record>, vin: string>, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($vin == null) { error make --unspanned { msg: "required query parameter 'vin' missing: pass --vin" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "vin" $vin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vehicleHistory" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "vin": $vin} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Checks if a VIN appeared on the market on or after a given date.
#
# GET /vehicleSeen
# operationId: getVehicleSeen_vehicleSeen_get
export def "get-vehicle-seen-vehicle-seen-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --vin: string # required
  --after-date: string # required, format: date
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: bool, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($vin == null) { error make --unspanned { msg: "required query parameter 'vin' missing: pass --vin" } }
  if ($after_date == null) { error make --unspanned { msg: "required query parameter 'afterDate' missing: pass --after-date" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "afterDate" $after_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vehicleSeen" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "vin": $vin, "afterDate": $after_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Vin decoder and Recall Info
#
# GET /vinDecode
# operationId: vinDecode_vinDecode_get
export def "vin-decode-vin-decode-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string # required
  --vin: string # required
  --pass-empty: oneof<nothing, bool> # default: false
  --include-recall: oneof<nothing, bool> # default: true
]: nothing -> oneof<record<brandName: string, cacheTimeLimit: int, condition: string, data: any, modelName: string, msg: string, regionName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jwt == null) { error make --unspanned { msg: "required query parameter 'jwt' missing: pass --jwt" } }
  if ($vin == null) { error make --unspanned { msg: "required query parameter 'vin' missing: pass --vin" } }
  let qp = [(serialize-qp "jwt" $jwt "scalar") (serialize-qp "vin" $vin "scalar") (serialize-qp "passEmpty" $pass_empty "scalar") (serialize-qp "includeRecall" $include_recall "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vinDecode" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"jwt": $jwt, "vin": $vin, "passEmpty": $pass_empty, "includeRecall": $include_recall} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
