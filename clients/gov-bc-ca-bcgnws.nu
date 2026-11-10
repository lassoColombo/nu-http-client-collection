# Auto-generated client for BC Geographical Names Web Service - REST API v3.x.x
# Source: https://api.apis.guru/v2/specs/gov.bc.ca/bcgnws/3.x.x/openapi.json
# Auth: --token flag or $env.BC_GEOGRAPHICAL_NAMES_WEB_SERVICE_REST_API_TOKEN

const BASE_URL = "https://apps.gov.bc.ca/pub/bcgnws"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o BC_GEOGRAPHICAL_NAMES_WEB_SERVICE_REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://apps.gov.bc.ca/pub/bcgnws" "https://test.apps.gov.bc.ca/pub/bcgnws" "https://delivery.apps.gov.bc.ca/pub/bcgnws"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def output-format-completer [] { ["json" "xml"] }
def output-format-completer-1 [] { ["csv" "json" "kml" "xml"] }
def sort-by-completer [] { ["decisionDate" "featureType" "name"] }
def output-srs-completer [] { ["26907" "26908" "26909" "26910" "26911" "3005" "3857" "4269" "4326"] }
def embed-completer [] { ["0" "1"] }
def output-style-completer [] { ["detail" "summary"] }
def exact-spelling-completer [] { ["0" "1"] }
def sort-by-completer-1 [] { ["decisionDate" "featureType" "name" "relevance"] }
def output-format-completer-2 [] { ["csv" "html" "json" "kml" "xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-feature-categories" "get-feature-classes" "get-feature-types" "get-features-feature-id" "get-name-authorities" "get-names-changes" "get-names-decisions-recent" "get-names-decisions-year" "get-names-inside" "get-names-near" "get-names-not-official-search" "get-names-official-search" "get-names-search" "get-names-name-id-output-format" "commands"] | sort) } | get name | first)
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

# Get all feature categories
#
# GET /featureCategories
export def "get-feature-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer # The format of the output. (required, default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  let qp = [(serialize-qp "outputFormat" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/featureCategories" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all feature classes
#
# GET /featureClasses
export def "get-feature-classes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer # The format of the output. (required, default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  let qp = [(serialize-qp "outputFormat" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/featureClasses" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all feature types
#
# GET /featureTypes
export def "get-feature-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer # The format of the output. (required, default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  let qp = [(serialize-qp "outputFormat" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/featureTypes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a feature by its featureId
#
# GET /features/{featureId}
export def "get-features-feature-id" [
  feature_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($feature_id | is-empty) { error make --unspanned { msg: "path parameter 'featureId' must be non-empty" } }
  let full_url = (build-url $base ({feature_id: (encode-path-segment $feature_id)} | format pattern "/features/{feature_id}") $auth.query)
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

# Get all name authorities
#
# GET /nameAuthorities
export def "get-name-authorities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer # The format of the output. (required, default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  let qp = [(serialize-qp "outputFormat" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nameAuthorities" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search for names with metadata changes in a given period
#
# GET /names/changes
export def "get-names-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (required, default: json, e.g. json)
  --from-date: int # Defines the earliest date (YYYY-MM-DD format) of the change time window for the search (required, e.g. 2017-01-01)
  --to-date: int # Defines the latest date (YYYY-MM-DD format) of the change time window for the search (required, e.g. 2017-06-30)
  --feature-class: string # A filter to limit the search to names associated with features of a certain 'class' The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --feature-category: string # A filter to limit the search to names associated with features of a certain 'category' The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --feature-type: string # A filter to limit the search to names associated with features of a certain 'type' The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sort-by: string@sort-by-completer # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: name)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --output-style: string@output-style-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --items-per-page: int # The number of search results to return (1-200) (default: 20)
  --start-index: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  if ($from_date == null) { error make --unspanned { msg: "required query parameter 'fromDate' missing: pass --from-date" } }
  if ($to_date == null) { error make --unspanned { msg: "required query parameter 'toDate' missing: pass --to-date" } }
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/changes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format, "fromDate": $from_date, "toDate": $to_date, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search for names affected by recent naming decision
#
# GET /names/decisions/recent
export def "get-names-decisions-recent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (required, default: json, e.g. json)
  --days: int # The number of days used to define the time window of naming decisions to search. The number is interpreted as searching for 'names affected by decisions within the last X days'. (required, default: 30, e.g. 30)
  --feature-class: string # A filter to limit the search to names associated with features of a certain 'class' The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --feature-category: string # A filter to limit the search to names associated with features of a certain 'category' The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --feature-type: string # A filter to limit the search to names associated with features of a certain 'type' The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sort-by: string@sort-by-completer # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: name)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --output-style: string@output-style-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --items-per-page: int # The number of search results to return (1-200) (default: 20)
  --start-index: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  let days = ($days | default 30)
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/decisions/recent" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format, "days": $days, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search for names affected by naming decisions in a given year
#
# GET /names/decisions/year
export def "get-names-decisions-year" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (required, default: json, e.g. json)
  --year: int # The year in which to search for names affected by naming decisions'. (required, e.g. 2007)
  --feature-class: string # A filter to limit the search to names associated with features of a certain 'class' The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --feature-category: string # A filter to limit the search to names associated with features of a certain 'category' The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --feature-type: string # A filter to limit the search to names associated with features of a certain 'type' The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sort-by: string@sort-by-completer # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: name)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --output-style: string@output-style-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --items-per-page: int # The number of search results to return (1-200) (default: 20)
  --start-index: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  if ($year == null) { error make --unspanned { msg: "required query parameter 'year' missing: pass --year" } }
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/decisions/year" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format, "year": $year, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search in a geographic area
#
# GET /names/inside
export def "get-names-inside" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (required, default: json, e.g. json)
  --bbox: string # A geographic bounding box defining the search area. Must be specified as a string of the form 'minLongitude,minLatitude,maxLongitude,maxLatitude' (WGS84). e.g. -119,49,-118,50 (required, e.g. -119,49,-118,50)
  --feature-class: string # A filter to limit the search to names associated with features of a certain 'class' The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --feature-category: string # A filter to limit the search to names associated with features of a certain 'category' The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --feature-type: string # A filter to limit the search to names associated with features of a certain 'type' The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sort-by: string@sort-by-completer # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: name)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --output-style: string@output-style-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --items-per-page: int # The number of search results to return (1-200) (default: 20)
  --start-index: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  if ($bbox == null) { error make --unspanned { msg: "required query parameter 'bbox' missing: pass --bbox" } }
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/inside" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format, "bbox": $bbox, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search near to a geographic point
#
# GET /names/near
export def "get-names-near" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (required, default: json, e.g. -119,49,-118,50)
  --feature-point: string # A geographic coordinate specifying the centre point of the search area. Must be specified as a string of the form 'longitude,latitude' (WGS84). e.g. -120,51 (required, e.g. -120,51)
  --distance: string # A radius (in kilometres) around the centre point. (required)
  --feature-class: string # A filter to limit the search to names associated with features of a certain 'class' The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --feature-category: string # A filter to limit the search to names associated with features of a certain 'category' The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --feature-type: string # A filter to limit the search to names associated with features of a certain 'type' The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sort-by: string@sort-by-completer # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: name)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --output-style: string@output-style-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --items-per-page: int # The number of search results to return (1-200) (default: 20)
  --start-index: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  if ($feature_point == null) { error make --unspanned { msg: "required query parameter 'featurePoint' missing: pass --feature-point" } }
  if ($distance == null) { error make --unspanned { msg: "required query parameter 'distance' missing: pass --distance" } }
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "featurePoint" $feature_point "scalar") (serialize-qp "distance" $distance "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/near" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format, "featurePoint": $feature_point, "distance": $distance, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search by name, limit to unofficial names only
#
# GET /names/notOfficial/search
export def "get-names-not-official-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (required, default: json, e.g. json)
  --name: string # A filter to search based on the the text of the name itself. Use the asterisk (*) as a wildcard character. For example 'vancouv*' (required, e.g. Victoria)
  --exact-spelling: int@exact-spelling-completer # If the 'name' parameter is specified, 'exactSpelling' specifies whether to include only names that exactly match the search text (exactSpelling=1), or whether to also include names with similar spellings (exactSpelling=0) (default: 0)
  --feature-class: string # A filter to limit the search to names associated with features of a certain 'class' The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --feature-category: string # A filter to limit the search to names associated with features of a certain 'category' The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --feature-type: string # A filter to limit the search to names associated with features of a certain 'type' The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sort-by: string@sort-by-completer-1 # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: relevance)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --output-style: string@output-style-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --items-per-page: int # The number of search results to return (1-200) (default: 20)
  --start-index: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  if ($name == null) { error make --unspanned { msg: "required query parameter 'name' missing: pass --name" } }
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exactSpelling" $exact_spelling "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/notOfficial/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format, "name": $name, "exactSpelling": $exact_spelling, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search by name, limit to official names only
#
# GET /names/official/search
export def "get-names-official-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (required, default: json, e.g. json)
  --name: string # A filter to search based on the the text of the name itself. Use the asterisk (*) as a wildcard character. For example 'vancouv*' (required, e.g. Victoria)
  --exact-spelling: int@exact-spelling-completer # If the 'name' parameter is specified, 'exactSpelling' specifies whether to include only names that exactly match the search text (exactSpelling=1), or whether to also include names with similar spellings (exactSpelling=0) (default: 0)
  --feature-class: string # A filter to limit the search to names associated with features of a certain 'class' The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --feature-category: string # A filter to limit the search to names associated with features of a certain 'category' The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --feature-type: string # A filter to limit the search to names associated with features of a certain 'type' The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sort-by: string@sort-by-completer-1 # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: relevance)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --output-style: string@output-style-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --items-per-page: int # The number of search results to return (1-200) (default: 20)
  --start-index: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  if ($name == null) { error make --unspanned { msg: "required query parameter 'name' missing: pass --name" } }
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exactSpelling" $exact_spelling "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/official/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format, "name": $name, "exactSpelling": $exact_spelling, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search by name
#
# GET /names/search
export def "get-names-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (required, default: json, e.g. json)
  --name: string # A filter to search based on the the text of the name itself. Use the asterisk (*) as a wildcard character. For example 'vancouv*' (required, e.g. Victoria)
  --exact-spelling: int@exact-spelling-completer # If the 'name' parameter is specified, 'exactSpelling' specifies whether to include only names that exactly match the search text (exactSpelling=1), or whether to also include names with similar spellings (exactSpelling=0) (default: 0)
  --feature-class: string # A filter to limit the search to names associated with features of a certain 'class' The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --feature-category: string # A filter to limit the search to names associated with features of a certain 'category' The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --feature-type: string # A filter to limit the search to names associated with features of a certain 'type' The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sort-by: string@sort-by-completer-1 # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: relevance)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --output-style: string@output-style-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --items-per-page: int # The number of search results to return (1-200) (default: 20)
  --start-index: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let output_format = ($output_format | default "json")
  if ($name == null) { error make --unspanned { msg: "required query parameter 'name' missing: pass --name" } }
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exactSpelling" $exact_spelling "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"outputFormat": $output_format, "name": $name, "exactSpelling": $exact_spelling, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a name by its nameId
#
# GET /names/{nameId}.{outputFormat}
export def "get-names-name-id-output-format" [
  name_id: int
  output_format: string@output-format-completer-2
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_id | is-empty) { error make --unspanned { msg: "path parameter 'nameId' must be non-empty" } }
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let full_url = (build-url $base ({name_id: (encode-path-segment $name_id), output_format: (encode-path-segment $output_format)} | format pattern "/names/{name_id}.{output_format}") $auth.query)
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
