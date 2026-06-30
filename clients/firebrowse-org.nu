# Auto-generated client for FireBrowse Beta API v1.1.38 (2018-02-26 11:01:29 484103261f6ef681a05cf163)
# Source: https://api.apis.guru/v2/specs/firebrowse.org/1.1.38/swagger.json
# Auth: --token flag or $env.FIREBROWSE_BETA_API_TOKEN

const BASE_URL = "http://firebrowse.org/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o FIREBROWSE_BETA_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://firebrowse.org/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def format-completer [] { ["csv" "json" "tsv"] }
def sort-by-completer [] { ["cohort" "gene" "tcga_participant_barcode"] }
def accept-completer [] { ["application/json" "text/plain" "text/tab-separated-values"] }
def sort-by-completer-1 [] { ["cohort" "gene" "q"] }
def format-completer-1 [] { ["csv" "tsv"] }
def sort-by-completer-2 [] { ["cohort" "gene" "tcga_participant_barcode" "tool"] }
def sort-by-completer-3 [] { ["cohort" "gene" "q" "rank" "tool"] }
def sort-by-completer-4 [] { ["cohort" "date" "name" "type"] }
def sort-by-completer-5 [] { ["center" "cohort" "data_type" "date" "level" "platform" "protocol" "tool"] }
def sort-by-completer-6 [] { ["cohort"] }
def sort-by-completer-7 [] { ["cde_name" "cohort" "tcga_participant_barcode"] }
def sort-by-completer-8 [] { ["cohort" "fh_cde_name" "tcga_participant_barcode"] }
def sort-by-completer-9 [] { ["cohort" "gene" "protocol" "sample_type" "tcga_participant_barcode"] }
def sort-by-completer-10 [] { ["cohort" "mir" "sample_type" "tcga_participant_barcode" "tool"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "analyses-copy-number-genes-all list" } } | get name | first)
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

# Retrieve all data by genes Gistic2 results.
#
# GET /Analyses/CopyNumber/Genes/All
# operationId: All
export def "analyses-copy-number-genes-all list" [
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
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --gene: list<string> # Comma separated list of gene name(s).
  --tcga-participant-barcode: list<string> # Comma separated list of TCGA participant barcodes (e.g. TCGA-GF-A4EO).
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "gene" $gene "csv") (serialize-qp "tcga_participant_barcode" $tcga_participant_barcode "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Analyses/CopyNumber/Genes/All" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort, "gene": $gene, "tcga_participant_barcode": $tcga_participant_barcode, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve Gistic2 significantly amplified genes results.
#
# GET /Analyses/CopyNumber/Genes/Amplified
# operationId: Amplified
export def "analyses-copy-number-genes-amplified get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --gene: list<string> # Comma separated list of gene name(s).
  --q: float # Only return results with Q-value <= given threshold.
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer-1 # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "gene" $gene "csv") (serialize-qp "q" $q "scalar") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Analyses/CopyNumber/Genes/Amplified" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort, "gene": $gene, "q": $q, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve Gistic2 significantly deleted genes results.
#
# GET /Analyses/CopyNumber/Genes/Deleted
# operationId: Deleted
export def "analyses-copy-number-genes-deleted get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --gene: list<string> # Comma separated list of gene name(s).
  --q: float # Only return results with Q-value <= given threshold.
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer-1 # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "gene" $gene "csv") (serialize-qp "q" $q "scalar") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Analyses/CopyNumber/Genes/Deleted" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort, "gene": $gene, "q": $q, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve focal data by genes Gistic2 results.
#
# GET /Analyses/CopyNumber/Genes/Focal
# operationId: Focal
export def "analyses-copy-number-genes-focal get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --gene: list<string> # Comma separated list of gene name(s).
  --tcga-participant-barcode: list<string> # Comma separated list of TCGA participant barcodes (e.g. TCGA-GF-A4EO).
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "gene" $gene "csv") (serialize-qp "tcga_participant_barcode" $tcga_participant_barcode "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Analyses/CopyNumber/Genes/Focal" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort, "gene": $gene, "tcga_participant_barcode": $tcga_participant_barcode, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve all thresholded by genes Gistic2 results.
#
# GET /Analyses/CopyNumber/Genes/Thresholded
# operationId: Thresholded
export def "analyses-copy-number-genes-thresholded get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --gene: list<string> # Comma separated list of gene name(s).
  --tcga-participant-barcode: list<string> # Comma separated list of TCGA participant barcodes (e.g. TCGA-GF-A4EO).
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "gene" $gene "csv") (serialize-qp "tcga_participant_barcode" $tcga_participant_barcode "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Analyses/CopyNumber/Genes/Thresholded" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort, "gene": $gene, "tcga_participant_barcode": $tcga_participant_barcode, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve aggregated analysis features table.
#
# GET /Analyses/FeatureTable
# operationId: FeatureTable
export def "analyses-feature-table get" [
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
  --format: string@format-completer-1 # Format of result. (default: tsv)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --date: list<string> # Select one or more date stamps.
  --column: list<string> # Comma separated list of which data columns/fields to return.
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "date" $date "csv") (serialize-qp "column" $column "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Analyses/FeatureTable" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort, "date": $date, "column": $column, "page": $page, "page_size": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve MutSig final analysis MAF.
#
# GET /Analyses/Mutation/MAF
# operationId: MAF
export def "analyses-mutation-maf get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --tool: list<string> # Narrow search to include only data/results produced by the selected Firehose tool.
  --gene: list<string> # Comma separated list of gene name(s).
  --tcga-participant-barcode: list<string> # Comma separated list of TCGA participant barcodes (e.g. TCGA-GF-A4EO).
  --column: list<string> # Comma separated list of which data columns/fields to return.
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer-2 # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "tool" $tool "csv") (serialize-qp "gene" $gene "csv") (serialize-qp "tcga_participant_barcode" $tcga_participant_barcode "csv") (serialize-qp "column" $column "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Analyses/Mutation/MAF" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort, "tool": $tool, "gene": $gene, "tcga_participant_barcode": $tcga_participant_barcode, "column": $column, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve Significantly Mutated Genes (SMG).
#
# GET /Analyses/Mutation/SMG
# operationId: SMG
export def "analyses-mutation-smg get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --tool: list<string> # Narrow search to include only data/results produced by the selected Firehose tool.
  --rank: int # Number of significant genes to return. (format: int32)
  --gene: list<string> # Comma separated list of gene name(s).
  --q: float # Only return results with Q-value <= given threshold.
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer-3 # Which column in the results should be used for sorting paginated results? (default: rank)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "tool" $tool "csv") (serialize-qp "rank" $rank "scalar") (serialize-qp "gene" $gene "csv") (serialize-qp "q" $q "scalar") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Analyses/Mutation/SMG" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort, "tool": $tool, "rank": $rank, "gene": $gene, "q": $q, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve links to summary reports from Firehose analysis runs.
#
# GET /Analyses/Reports
# operationId: Reports
export def "analyses-reports get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --date: list<string> # Select one or more date stamps.
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --name: list<string> # Narrow search to one or more report names.
  --type: list<string> # Narrow search to one or more report types.
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer-4 # Which column in the results should be used for sorting paginated results? (default: date)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "date" $date "csv") (serialize-qp "cohort" $cohort "csv") (serialize-qp "name" $name "csv") (serialize-qp "type" $type "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Analyses/Reports" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "date": $date, "cohort": $cohort, "name": $name, "type": $type, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns RNASeq expression quartiles, e.g. suitable for drawing a boxplot.
#
# GET /Analyses/mRNASeq/Quartiles
# operationId: mRNASeq/Quartiles
export def "analyses-m-rna-seq-quartiles get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --gene: string # Enter a single gene name.
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --protocol: list<string> # Narrow search to one or more sample characterization protocols from the scrollable list.
  --sample-type: list<string> # For which type of sample(s) should quartiles be computed?
  --exclude: list<string> # Comma separated list of TCGA participants, identified by barcodes such as TCGA-GF-A4EO, denoting samples to exclude from computation.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "gene" $gene "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "protocol" $protocol "csv") (serialize-qp "sample_type" $sample_type "csv") (serialize-qp "Exclude" $exclude "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Analyses/mRNASeq/Quartiles" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "gene": $gene, "cohort": $cohort, "protocol": $protocol, "sample_type": $sample_type, "Exclude": $exclude} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve standard data archives.
#
# GET /Archives/StandardData
# operationId: StandardData
export def "archives-standard-data get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --date: list<string> # Select one or more date stamps.
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --data-type: list<string> # Narrow search to one or more TCGA data types from the scrollable list.
  --tool: list<string> # Narrow search to include only data/results produced by the selected Firehose tool.
  --platform: list<string> # Narrow search to one or more TCGA data generation platforms from the scrollable list.
  --center: list<string> # Narrow search to one or more TCGA centers from the scrollable list.
  --level: list<int> # Narrow search to one or more TCGA data levels.
  --protocol: list<string> # Narrow search to one or more sample characterization protocols from the scrollable list.
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer-5 # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "date" $date "csv") (serialize-qp "cohort" $cohort "csv") (serialize-qp "data_type" $data_type "csv") (serialize-qp "tool" $tool "csv") (serialize-qp "platform" $platform "csv") (serialize-qp "center" $center "csv") (serialize-qp "level" $level "csv") (serialize-qp "protocol" $protocol "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Archives/StandardData" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "date": $date, "cohort": $cohort, "data_type": $data_type, "tool": $tool, "platform": $platform, "center": $center, "level": $level, "protocol": $protocol, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Obtain identities of TCGA consortium member centers.
#
# GET /Metadata/Centers
# operationId: Centers
export def "metadata-centers get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --center: list<string> # Narrow search to one or more TCGA centers from the scrollable list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "center" $center "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/Centers" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "center": $center} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve names of all TCGA clinical data elements (CDEs).
#
# GET /Metadata/ClinicalNames
# operationId: ClinicalNames
export def "metadata-clinical-names get" [
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
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/ClinicalNames" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve names of CDEs normalized by Firehose and selected for analyses.
#
# GET /Metadata/ClinicalNames_FH
# operationId: ClinicalNames_FH
export def "metadata-clinical-names-fh get" [
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
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/ClinicalNames_FH" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Translate TCGA cohort abbreviations to full disease names.
#
# GET /Metadata/Cohorts
# operationId: Cohorts
export def "metadata-cohorts get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/Cohorts" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve sample counts.
#
# GET /Metadata/Counts
# operationId: Counts
export def "metadata-counts get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --date: list<string> # Select one or more date stamps.
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --sample-type: list<string> # Narrow search to one or more TCGA sample types from the scrollable list.
  --data-type: list<string> # Narrow search to one or more TCGA data types from the scrollable list.
  --totals: oneof<nothing, bool> # Output an entry providing the totals for each data type. (default: true)
  --sort-by: string@sort-by-completer-6 # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "date" $date "csv") (serialize-qp "cohort" $cohort "csv") (serialize-qp "sample_type" $sample_type "csv") (serialize-qp "data_type" $data_type "csv") (serialize-qp "totals" $totals "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/Counts" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "date": $date, "cohort": $cohort, "sample_type": $sample_type, "data_type": $data_type, "totals": $totals, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve dates of all GDAC Firehose stddata & analyses runs that have been ingested into FireBrowse.
#
# GET /Metadata/Dates
# operationId: Dates
export def "metadata-dates get" [
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
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/Dates" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Simple way to discern whether API server is up and running
#
# GET /Metadata/HeartBeat
# operationId: HeartBeat
export def "metadata-heart-beat get" [
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
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/HeartBeat" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve names of all columns in the mutation annotation files (MAFs) served by FireBrowse.
#
# GET /Metadata/MAFColNames
# operationId: MAFColNames
export def "metadata-maf-col-names get" [
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
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/MAFColNames" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve list of all TCGA patients.
#
# GET /Metadata/Patients
# operationId: Patients
export def "metadata-patients get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer-6 # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/Patients" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Translate TCGA platform codes to full platform names.
#
# GET /Metadata/Platforms
# operationId: Platforms
export def "metadata-platforms get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --platform: list<string> # Narrow search to one or more TCGA data generation platforms from the scrollable list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "platform" $platform "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/Platforms" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "platform": $platform} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Given a TCGA barcode, return its short letter sample type code.
#
# GET /Metadata/SampleType/Barcode/{TCGA_Barcode}
# operationId: Barcode
export def "metadata-sample-type-barcode get" [
  tcga_barcode: string
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
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tcga_barcode | is-empty) { error make --unspanned { msg: "path parameter 'TCGA_Barcode' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tcga_barcode: (encode-path-segment $tcga_barcode)} | format pattern "/Metadata/SampleType/Barcode/{tcga_barcode}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Translate from numeric to symbolic TCGA sample codes.
#
# GET /Metadata/SampleType/Code/{code}
# operationId: Code
export def "metadata-sample-type-code get" [
  code: list
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
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($code | is-empty) { error make --unspanned { msg: "path parameter 'code' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: (encode-path-array $code)} | format pattern "/Metadata/SampleType/Code/{code}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Translate from symbolic to numeric TCGA sample codes.
#
# GET /Metadata/SampleType/ShortLetterCode/{short_letter_code}
# operationId: ShortLetterCode
export def "metadata-sample-type-short-letter-code get" [
  short_letter_code: list
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
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($short_letter_code | is-empty) { error make --unspanned { msg: "path parameter 'short_letter_code' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_letter_code: (encode-path-array $short_letter_code)} | format pattern "/Metadata/SampleType/ShortLetterCode/{short_letter_code}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return all TCGA sample type codes, both numeric and symbolic.
#
# GET /Metadata/SampleTypes
# operationId: SampleTypes
export def "metadata-sample-types get" [
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
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/SampleTypes" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Obtain identities of tissue source sites in TCGA.
#
# GET /Metadata/TSSites
# operationId: TSSites
export def "metadata-ts-sites get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --tss-code: list<string> # Narrow search to one or more TSS codes
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "tss_code" $tss_code "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/TSSites" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "tss_code": $tss_code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve TCGA CDEs verbatim, i.e. not normalized by Firehose.
#
# GET /Samples/Clinical
# operationId: Clinical
export def "samples-clinical get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --tcga-participant-barcode: list<string> # Comma separated list of TCGA participant barcodes (e.g. TCGA-GF-A4EO).
  --cde-name: list<string> # Retrieve results only for specified CDEs, per the Metadata/ClinicalNames function
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer-7 # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "tcga_participant_barcode" $tcga_participant_barcode "csv") (serialize-qp "cde_name" $cde_name "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Samples/Clinical" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort, "tcga_participant_barcode": $tcga_participant_barcode, "cde_name": $cde_name, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve CDEs normalized by Firehose and selected for analyses.
#
# GET /Samples/Clinical_FH
# operationId: Clinical_FH
export def "samples-clinical-fh get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --tcga-participant-barcode: list<string> # Comma separated list of TCGA participant barcodes (e.g. TCGA-GF-A4EO).
  --fh-cde-name: list<string> # Retrieve results only for the CDEs specified from the scrollable list.
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer-8 # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv") (serialize-qp "tcga_participant_barcode" $tcga_participant_barcode "csv") (serialize-qp "fh_cde_name" $fh_cde_name "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Samples/Clinical_FH" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "cohort": $cohort, "tcga_participant_barcode": $tcga_participant_barcode, "fh_cde_name": $fh_cde_name, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve mRNASeq data.
#
# GET /Samples/mRNASeq
# operationId: mRNASeq
export def "samples-m-rna-seq get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --gene: list<string> # Comma separated list of gene name(s).
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --tcga-participant-barcode: list<string> # Comma separated list of TCGA participant barcodes (e.g. TCGA-GF-A4EO).
  --sample-type: list<string> # Narrow search to one or more TCGA sample types from the scrollable list.
  --protocol: list<string> # Narrow search to one or more sample characterization protocols from the scrollable list.
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer-9 # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "gene" $gene "csv") (serialize-qp "cohort" $cohort "csv") (serialize-qp "tcga_participant_barcode" $tcga_participant_barcode "csv") (serialize-qp "sample_type" $sample_type "csv") (serialize-qp "protocol" $protocol "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Samples/mRNASeq" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "gene": $gene, "cohort": $cohort, "tcga_participant_barcode": $tcga_participant_barcode, "sample_type": $sample_type, "protocol": $protocol, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve miRSeq data.
#
# GET /Samples/miRSeq
# operationId: miRSeq
export def "samples-mi-r-seq get" [
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
  --format: string@format-completer # Format of result. (default: json)
  --mir: list<string> # Comma separated list of miR names (e.g. hsa-let-7b-5p,hsa-let-7a-1).
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
  --tcga-participant-barcode: list<string> # Comma separated list of TCGA participant barcodes (e.g. TCGA-GF-A4EO).
  --tool: list<string> # Narrow search to include only data/results produced by the selected Firehose tool.
  --sample-type: list<string> # Narrow search to one or more TCGA sample types from the scrollable list.
  --page: list<int> # Which page (slice) of entire results set should be returned.
  --page-size: list<int> # Number of records per page of results. Max is 2000.
  --sort-by: string@sort-by-completer-10 # Which column in the results should be used for sorting paginated results? (default: cohort)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "mir" $mir "csv") (serialize-qp "cohort" $cohort "csv") (serialize-qp "tcga_participant_barcode" $tcga_participant_barcode "csv") (serialize-qp "tool" $tool "csv") (serialize-qp "sample_type" $sample_type "csv") (serialize-qp "page" $page "csv") (serialize-qp "page_size" $page_size "csv") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Samples/miRSeq" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "mir": $mir, "cohort": $cohort, "tcga_participant_barcode": $tcga_participant_barcode, "tool": $tool, "sample_type": $sample_type, "page": $page, "page_size": $page_size, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
