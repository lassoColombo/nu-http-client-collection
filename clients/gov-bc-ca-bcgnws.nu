# Auto-generated client for BC Geographical Names Web Service - REST API v3.x.x
# Source: https://api.apis.guru/v2/specs/gov.bc.ca/bcgnws/3.x.x/openapi.json
# Auth: --token flag or $env.BC_GEOGRAPHICAL_NAMES_WEB_SERVICE_REST_API_TOKEN

const BASE_URL = "https://apps.gov.bc.ca/pub/bcgnws"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BC_GEOGRAPHICAL_NAMES_WEB_SERVICE_REST_API_TOKEN | default "" }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "feature-categories get" } } | get name | first)
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

# Get all feature categories
#
# GET /featureCategories
export def "feature-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer # The format of the output. (default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/featureCategories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format} | compact), body: null}
}

# Get all feature classes
#
# GET /featureClasses
export def "feature-classes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer # The format of the output. (default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/featureClasses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format} | compact), body: null}
}

# Get all feature types
#
# GET /featureTypes
export def "feature-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer # The format of the output. (default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/featureTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format} | compact), body: null}
}

# Get a feature by its featureId
#
# GET /features/{featureId}
export def "features get" [
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
  let full_url = (build-url $base ({feature_id: (encode-path-segment $feature_id)} | format pattern "/features/{feature_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all name authorities
#
# GET /nameAuthorities
export def "name-authorities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer # The format of the output. (default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nameAuthorities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format} | compact), body: null}
}

# Search for names with metadata changes in a given period
#
# GET /names/changes
export def "names-changes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (default: json, e.g. json)
  --from-date: int # Defines the earliest date (YYYY-MM-DD format) of the change time window for the search (e.g. 2017-01-01)
  --to-date: int # Defines the latest date (YYYY-MM-DD format) of the change time window for the search (e.g. 2017-06-30)
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
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/changes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format, "fromDate": $from_date, "toDate": $to_date, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact), body: null}
}

# Search for names affected by recent naming decision
#
# GET /names/decisions/recent
export def "names-decisions-recent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (default: json, e.g. json)
  --days: int # The number of days used to define the time window of naming decisions to search. The number is interpreted as searching for 'names affected by decisions within the last X days'. (default: 30, e.g. 30)
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
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/decisions/recent" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format, "days": $days, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact), body: null}
}

# Search for names affected by naming decisions in a given year
#
# GET /names/decisions/year
export def "names-decisions-year get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (default: json, e.g. json)
  --year: int # The year in which to search for names affected by naming decisions'. (e.g. 2007)
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
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/decisions/year" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format, "year": $year, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact), body: null}
}

# Search in a geographic area
#
# GET /names/inside
export def "names-inside get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (default: json, e.g. json)
  --bbox: string # A geographic bounding box defining the search area. Must be specified as a string of the form 'minLongitude,minLatitude,maxLongitude,maxLatitude' (WGS84). e.g. -119,49,-118,50 (e.g. -119,49,-118,50)
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
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/inside" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format, "bbox": $bbox, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact), body: null}
}

# Search near to a geographic point
#
# GET /names/near
export def "names-near get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (default: json, e.g. -119,49,-118,50)
  --feature-point: string # A geographic coordinate specifying the centre point of the search area. Must be specified as a string of the form 'longitude,latitude' (WGS84). e.g. -120,51 (e.g. -120,51)
  --distance: string # A radius (in kilometres) around the centre point.
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
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "featurePoint" $feature_point "scalar") (serialize-qp "distance" $distance "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/near" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format, "featurePoint": $feature_point, "distance": $distance, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact), body: null}
}

# Search by name, limit to unofficial names only
#
# GET /names/notOfficial/search
export def "names-not-official-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (default: json, e.g. json)
  --name: string # A filter to search based on the the text of the name itself. Use the asterisk (*) as a wildcard character. For example 'vancouv*' (e.g. Victoria)
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
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exactSpelling" $exact_spelling "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/notOfficial/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format, "name": $name, "exactSpelling": $exact_spelling, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact), body: null}
}

# Search by name, limit to official names only
#
# GET /names/official/search
export def "names-official-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (default: json, e.g. json)
  --name: string # A filter to search based on the the text of the name itself. Use the asterisk (*) as a wildcard character. For example 'vancouv*' (e.g. Victoria)
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
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exactSpelling" $exact_spelling "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/official/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format, "name": $name, "exactSpelling": $exact_spelling, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact), body: null}
}

# Search by name
#
# GET /names/search
export def "names-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-format: string@output-format-completer-1 # The format of the output. (default: json, e.g. json)
  --name: string # A filter to search based on the the text of the name itself. Use the asterisk (*) as a wildcard character. For example 'vancouv*' (e.g. Victoria)
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
  let qp = [(serialize-qp "outputFormat" $output_format "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exactSpelling" $exact_spelling "scalar") (serialize-qp "featureClass" $feature_class "scalar") (serialize-qp "featureCategory" $feature_category "scalar") (serialize-qp "featureType" $feature_type "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $output_style "scalar") (serialize-qp "itemsPerPage" $items_per_page "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputFormat": $output_format, "name": $name, "exactSpelling": $exact_spelling, "featureClass": $feature_class, "featureCategory": $feature_category, "featureType": $feature_type, "sortBy": $sort_by, "outputSRS": $output_srs, "embed": $embed, "outputStyle": $output_style, "itemsPerPage": $items_per_page, "startIndex": $start_index} | compact), body: null}
}

# Get a name by its nameId
#
# GET /names/{nameId}.{outputFormat}
export def "names get" [
  name_id: int
  output_format: string
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
  let full_url = (build-url $base ({name_id: (encode-path-segment $name_id), output_format: (encode-path-segment $output_format)} | format pattern "/names/{name_id}.{output_format}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
