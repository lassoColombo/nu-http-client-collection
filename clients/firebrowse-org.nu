# Auto-generated client for FireBrowse Beta API v1.1.38 (2018-02-26 11:01:29 484103261f6ef681a05cf163)
# Source: https://api.apis.guru/v2/specs/firebrowse.org/1.1.38/swagger.json
# Auth: --token flag or $env.FIREBROWSE_BETA_API_TOKEN

const BASE_URL = "http://firebrowse.org/api/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FIREBROWSE_BETA_API_TOKEN | default "" }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  let full_url = (build-url $base "/Analyses/CopyNumber/Genes/All" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Analyses/CopyNumber/Genes/Amplified" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Analyses/CopyNumber/Genes/Deleted" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Analyses/CopyNumber/Genes/Focal" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Analyses/CopyNumber/Genes/Thresholded" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Analyses/FeatureTable" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Analyses/Mutation/MAF" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Analyses/Mutation/SMG" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Analyses/Reports" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Analyses/mRNASeq/Quartiles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Archives/StandardData" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
  --center: list<string> # Narrow search to one or more TCGA centers from the scrollable list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "center" $center "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/Centers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/ClinicalNames" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/ClinicalNames_FH" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
  --cohort: list<string> # Narrow search to one or more TCGA disease cohorts from the scrollable list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "cohort" $cohort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/Cohorts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Metadata/Counts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/Dates" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/HeartBeat" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/MAFColNames" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Metadata/Patients" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
  --platform: list<string> # Narrow search to one or more TCGA data generation platforms from the scrollable list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "platform" $platform "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/Platforms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tcga_barcode: (encode-path-segment $tcga_barcode)} | format pattern "/Metadata/SampleType/Barcode/{tcga_barcode}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: (encode-path-segment $code)} | format pattern "/Metadata/SampleType/Code/{code}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_letter_code: (encode-path-segment $short_letter_code)} | format pattern "/Metadata/SampleType/ShortLetterCode/{short_letter_code}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/SampleTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of result. (default: json)
  --tss-code: list<string> # Narrow search to one or more TSS codes
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "tss_code" $tss_code "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Metadata/TSSites" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Samples/Clinical" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Samples/Clinical_FH" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Samples/mRNASeq" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/Samples/miRSeq" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
