# Auto-generated client for BC Geographical Names Web Service - REST API v3.x.x
# Source: https://api.apis.guru/v2/specs/gov.bc.ca/bcgnws/3.x.x/openapi.json
# Auth: --token flag or $env.BC_GEOGRAPHICAL_NAMES_WEB_SERVICE_REST_API_TOKEN

const BASE_URL = "https://apps.gov.bc.ca/pub/bcgnws"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BC_GEOGRAPHICAL_NAMES_WEB_SERVICE_REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://apps.gov.bc.ca/pub/bcgnws" "https://test.apps.gov.bc.ca/pub/bcgnws" "https://delivery.apps.gov.bc.ca/pub/bcgnws"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def outputFormat-completer [] { ["json" "xml"] }
def outputFormat-completer-1 [] { ["csv" "json" "kml" "xml"] }
def sortBy-completer [] { ["decisionDate" "featureType" "name"] }
def outputSRS-completer [] { ["26907" "26908" "26909" "26910" "26911" "3005" "3857" "4269" "4326"] }
def embed-completer [] { ["0" "1"] }
def outputStyle-completer [] { ["detail" "summary"] }
def exactSpelling-completer [] { ["0" "1"] }
def sortBy-completer-1 [] { ["decisionDate" "featureType" "name" "relevance"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer # The format of the output. (default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/featureCategories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer # The format of the output. (default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/featureClasses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer # The format of the output. (default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/featureTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a feature by its featureId
#
# GET /features/{featureId}
export def "features get" [
  featureId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/features/($featureId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer # The format of the output. (default: json, e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nameAuthorities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer-1 # The format of the output. (default: json, e.g. json)
  --fromDate: int # Defines the earliest date (YYYY-MM-DD format) of the change time window for the search (e.g. 2017-01-01)
  --toDate: int # Defines the latest date (YYYY-MM-DD format) of the change time window for the search (e.g. 2017-06-30)
  --featureClass: string # A filter to limit the search to names associated with features of a certain 'class'  The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --featureCategory: string # A filter to limit the search to names associated with features of a certain 'category'  The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --featureType: string # A filter to limit the search to names associated with features of a certain 'type'  The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sortBy: string@sortBy-completer # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: name)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --outputStyle: string@outputStyle-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --itemsPerPage: int # The number of search results to return (1-200) (default: 20)
  --startIndex: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar") (serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "featureClass" $featureClass "scalar") (serialize-qp "featureCategory" $featureCategory "scalar") (serialize-qp "featureType" $featureType "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $outputStyle "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/changes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer-1 # The format of the output. (default: json, e.g. json)
  --days: int # The number of days used to define the time window of naming decisions to search.  The number is interpreted as searching for 'names affected by decisions within the last X days'. (default: 30, e.g. 30)
  --featureClass: string # A filter to limit the search to names associated with features of a certain 'class'  The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --featureCategory: string # A filter to limit the search to names associated with features of a certain 'category'  The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --featureType: string # A filter to limit the search to names associated with features of a certain 'type'  The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sortBy: string@sortBy-completer # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: name)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --outputStyle: string@outputStyle-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --itemsPerPage: int # The number of search results to return (1-200) (default: 20)
  --startIndex: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "featureClass" $featureClass "scalar") (serialize-qp "featureCategory" $featureCategory "scalar") (serialize-qp "featureType" $featureType "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $outputStyle "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/decisions/recent" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer-1 # The format of the output. (default: json, e.g. json)
  --year: int # The year in which to search for names affected by naming decisions'. (e.g. 2007)
  --featureClass: string # A filter to limit the search to names associated with features of a certain 'class'  The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --featureCategory: string # A filter to limit the search to names associated with features of a certain 'category'  The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --featureType: string # A filter to limit the search to names associated with features of a certain 'type'  The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sortBy: string@sortBy-completer # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: name)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --outputStyle: string@outputStyle-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --itemsPerPage: int # The number of search results to return (1-200) (default: 20)
  --startIndex: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "featureClass" $featureClass "scalar") (serialize-qp "featureCategory" $featureCategory "scalar") (serialize-qp "featureType" $featureType "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $outputStyle "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/decisions/year" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer-1 # The format of the output. (default: json, e.g. json)
  --bbox: string # A geographic bounding box defining the search area.  Must be specified as a string of the form 'minLongitude,minLatitude,maxLongitude,maxLatitude' (WGS84). e.g. -119,49,-118,50 (e.g. -119,49,-118,50)
  --featureClass: string # A filter to limit the search to names associated with features of a certain 'class'  The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --featureCategory: string # A filter to limit the search to names associated with features of a certain 'category'  The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --featureType: string # A filter to limit the search to names associated with features of a certain 'type'  The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sortBy: string@sortBy-completer # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: name)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --outputStyle: string@outputStyle-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --itemsPerPage: int # The number of search results to return (1-200) (default: 20)
  --startIndex: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "featureClass" $featureClass "scalar") (serialize-qp "featureCategory" $featureCategory "scalar") (serialize-qp "featureType" $featureType "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $outputStyle "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/inside" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer-1 # The format of the output. (default: json, e.g. -119,49,-118,50)
  --featurePoint: string # A geographic coordinate specifying the centre point of the search area.  Must be specified as a string of the form 'longitude,latitude' (WGS84).  e.g. -120,51 (e.g. -120,51)
  --distance: string # A radius (in kilometres) around the centre point.
  --featureClass: string # A filter to limit the search to names associated with features of a certain 'class'  The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --featureCategory: string # A filter to limit the search to names associated with features of a certain 'category'  The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --featureType: string # A filter to limit the search to names associated with features of a certain 'type'  The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sortBy: string@sortBy-completer # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: name)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --outputStyle: string@outputStyle-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --itemsPerPage: int # The number of search results to return (1-200) (default: 20)
  --startIndex: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar") (serialize-qp "featurePoint" $featurePoint "scalar") (serialize-qp "distance" $distance "scalar") (serialize-qp "featureClass" $featureClass "scalar") (serialize-qp "featureCategory" $featureCategory "scalar") (serialize-qp "featureType" $featureType "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $outputStyle "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/near" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer-1 # The format of the output. (default: json, e.g. json)
  --name: string # A filter to search based on the the text of the name itself.  Use the asterisk (*) as a wildcard character.  For example 'vancouv*' (e.g. Victoria)
  --exactSpelling: int@exactSpelling-completer # If the 'name' parameter is specified, 'exactSpelling' specifies whether to include only names that exactly match the search text (exactSpelling=1), or whether to also include names with similar spellings (exactSpelling=0) (default: 0)
  --featureClass: string # A filter to limit the search to names associated with features of a certain 'class'  The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --featureCategory: string # A filter to limit the search to names associated with features of a certain 'category'  The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --featureType: string # A filter to limit the search to names associated with features of a certain 'type'  The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sortBy: string@sortBy-completer-1 # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: relevance)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --outputStyle: string@outputStyle-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --itemsPerPage: int # The number of search results to return (1-200) (default: 20)
  --startIndex: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exactSpelling" $exactSpelling "scalar") (serialize-qp "featureClass" $featureClass "scalar") (serialize-qp "featureCategory" $featureCategory "scalar") (serialize-qp "featureType" $featureType "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $outputStyle "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/notOfficial/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer-1 # The format of the output. (default: json, e.g. json)
  --name: string # A filter to search based on the the text of the name itself.  Use the asterisk (*) as a wildcard character.  For example 'vancouv*' (e.g. Victoria)
  --exactSpelling: int@exactSpelling-completer # If the 'name' parameter is specified, 'exactSpelling' specifies whether to include only names that exactly match the search text (exactSpelling=1), or whether to also include names with similar spellings (exactSpelling=0) (default: 0)
  --featureClass: string # A filter to limit the search to names associated with features of a certain 'class'  The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --featureCategory: string # A filter to limit the search to names associated with features of a certain 'category'  The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --featureType: string # A filter to limit the search to names associated with features of a certain 'type'  The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sortBy: string@sortBy-completer-1 # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: relevance)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --outputStyle: string@outputStyle-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --itemsPerPage: int # The number of search results to return (1-200) (default: 20)
  --startIndex: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exactSpelling" $exactSpelling "scalar") (serialize-qp "featureClass" $featureClass "scalar") (serialize-qp "featureCategory" $featureCategory "scalar") (serialize-qp "featureType" $featureType "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $outputStyle "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/official/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputFormat: string@outputFormat-completer-1 # The format of the output. (default: json, e.g. json)
  --name: string # A filter to search based on the the text of the name itself.  Use the asterisk (*) as a wildcard character.  For example 'vancouv*' (e.g. Victoria)
  --exactSpelling: int@exactSpelling-completer # If the 'name' parameter is specified, 'exactSpelling' specifies whether to include only names that exactly match the search text (exactSpelling=1), or whether to also include names with similar spellings (exactSpelling=0) (default: 0)
  --featureClass: string # A filter to limit the search to names associated with features of a certain 'class'  The value of this parameter should be a 'featureClassCode' value returned by the /featureClasses resource, or an asterisk (*) to request that all feature classes be included. (default: *)
  --featureCategory: string # A filter to limit the search to names associated with features of a certain 'category'  The value of this parameter should be a 'featureCategoryCode' value returned by the /featureCategories resource, or an asterisk (*) to request that all feature categories be included. (default: *)
  --featureType: string # A filter to limit the search to names associated with features of a certain 'type'  The value of this parameter should be a 'featureTypeCode' value returned by the /featureTypes resource, or an asterisk (*) to request that all feature types be included (default: *)
  --sortBy: string@sortBy-completer-1 # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: relevance)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. (default: 4326)
  --embed: int@embed-completer # A flag to indicate whether to embed the corresponding 'feature' into each matching name
  --outputStyle: string@outputStyle-completer # A flag indicating whether to include with each matching name a succinct list of attributes (summary), or a comprehensive list of attributes (detail) (default: summary)
  --itemsPerPage: int # The number of search results to return (1-200) (default: 20)
  --startIndex: int # The index of the first record to be returned (>= 1) (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputFormat" $outputFormat "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exactSpelling" $exactSpelling "scalar") (serialize-qp "featureClass" $featureClass "scalar") (serialize-qp "featureCategory" $featureCategory "scalar") (serialize-qp "featureType" $featureType "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "outputStyle" $outputStyle "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/names/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a name by its nameId
#
# GET /names/{nameId}.{outputFormat}
export def "names get" [
  nameId: int
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/names/($nameId).($outputFormat)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
