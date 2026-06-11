# Auto-generated client for Water Quality Archive v1.3.0
# Source: https://environment.data.gov.uk/water-quality/openapi.json
# Auth: --token flag or $env.WATER_QUALITY_ARCHIVE_TOKEN

const BASE_URL = "https://environment.data.gov.uk/water-quality"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WATER_QUALITY_ARCHIVE_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://environment.data.gov.uk/water-quality"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Accept-Crs-completer [] { ["http://www.opengis.net/def/crs/EPSG/0/27700" "http://www.opengis.net/def/crs/EPSG/0/4326"] }
def accept-completer [] { ["application/geo+json" "application/ld+json"] }
def CSV-Header-completer [] { ["absent" "present"] }
def accept-completer-1 [] { ["application/ld+json" "application/x-jsonlines" "text/csv"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "sampling-point list" } } | get name | first)
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

# List and filter sampling points
#
# GET /sampling-point
# operationId: list_sampling_points_sampling_point_get
export def "sampling-point list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 100)
  --easting: string # OS Grid easting coordinate for radius-based search
  --northing: string # OS Grid northing coordinate for radius-based search
  --latitude: string # Latitude coordinate for radius-based search
  --longitude: string # Longitude coordinate for radius-based search
  --radius: string # Search radius in kilometers for geographic queries
  --precannedArea: string # Filter by pre-defined area using format area_type,area_notation (e.g. environment_agency,YOR)
  --pointNotation: string # Filter by exact notation, optionally as a comma-separated list of no more than 100 notations
  --prefLabel: string # Filter by prefLabel (contains)
  --region: string # Filter by region code
  --area: string # Filter by area code
  --subArea: string # Filter by subArea code
  --samplingPointStatus: string # Filter by status code
  --samplingPointType: string # Filter by single|multiple point type code e.g. 'FJ,SA'
  --Accept-Crs: string@Accept-Crs-completer # Coordinate Reference System URI for response, e.g. http://www.opengis.net/def/crs/EPSG/0/27700 or http://www.opengis.net/def/crs/EPSG/0/4326
  --API-Version: string # Content negotiation header to specify version of the API to use. (e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "easting" $easting "scalar") (serialize-qp "northing" $northing "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "precannedArea" $precannedArea "scalar") (serialize-qp "pointNotation" $pointNotation "scalar") (serialize-qp "prefLabel" $prefLabel "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "area" $area "scalar") (serialize-qp "subArea" $subArea "scalar") (serialize-qp "samplingPointStatus" $samplingPointStatus "scalar") (serialize-qp "samplingPointType" $samplingPointType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sampling-point" $qp)
  let extra_headers = {"Accept-Crs": $Accept_Crs, "API-Version": $API_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/ld+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a sampling point by its notation
#
# GET /sampling-point/{pointNotation}
# operationId: read_sampling_point_sampling_point__pointNotation__get
export def "sampling-point get" [
  pointNotation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Accept-Crs: string@Accept-Crs-completer # Coordinate Reference System URI for response, e.g. http://www.opengis.net/def/crs/EPSG/0/27700 or http://www.opengis.net/def/crs/EPSG/0/4326
  --API-Version: string # Content negotiation header to specify version of the API to use. (e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sampling-point/($pointNotation)")
  let extra_headers = {"Accept-Crs": $Accept_Crs, "API-Version": $API_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/ld+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List and filter sampling points (including GeoJSON Polygon or MultiPolygon)
#
# POST /data/sampling-point
# operationId: data_sampling_points_data_sampling_point_post
export def "data-sampling-point post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 100)
  --easting: string # OS Grid easting coordinate for radius-based search
  --northing: string # OS Grid northing coordinate for radius-based search
  --latitude: string # Latitude coordinate for radius-based search
  --longitude: string # Longitude coordinate for radius-based search
  --radius: string # Search radius in kilometers for geographic queries
  --precannedArea: string # Filter by pre-defined area using format area_type,area_notation (e.g. environment_agency,YOR)
  --pointNotation: string # Filter by exact notation, optionally as a comma-separated list of no more than 100 notations
  --prefLabel: string # Filter by prefLabel (contains)
  --region: string # Filter by region code
  --area: string # Filter by area code
  --subArea: string # Filter by subArea code
  --samplingPointStatus: string # Filter by status code
  --samplingPointType: string # Filter by single|multiple point type code e.g. 'FJ,SA'
  --Accept-Crs: string@Accept-Crs-completer # Coordinate Reference System URI for response, e.g. http://www.opengis.net/def/crs/EPSG/0/27700 or http://www.opengis.net/def/crs/EPSG/0/4326
  --API-Version: string # Content negotiation header to specify version of the API to use. (e.g. 1)
  --bbox: any
  --type: string
  --coordinates: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "easting" $easting "scalar") (serialize-qp "northing" $northing "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "precannedArea" $precannedArea "scalar") (serialize-qp "pointNotation" $pointNotation "scalar") (serialize-qp "prefLabel" $prefLabel "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "area" $area "scalar") (serialize-qp "subArea" $subArea "scalar") (serialize-qp "samplingPointStatus" $samplingPointStatus "scalar") (serialize-qp "samplingPointType" $samplingPointType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/sampling-point" $qp)
  let body = {bbox: $bbox, type: $type, coordinates: $coordinates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Crs": $Accept_Crs, "API-Version": $API_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/ld+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List and filter samplings for a specific sampling point by its notation
#
# GET /sampling-point/{pointNotation}/sampling
# operationId: list_sampling_point_sampling_sampling_point__pointNotation__sampling_get
export def "sampling-point-sampling list" [
  pointNotation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 100)
  --samplingPurpose: string # Filter by sampling purpose code(s), optionally as a comma-separated list
  --sampleSamplingNotation: string # Filter by Sample/Sampling notation
  --date: string # Filter by exact date (ISO format: YYYY-MM-DD), cannot be used with dateFrom/dateTo
  --dateFrom: string # Filter by date range start (ISO format: YYYY-MM-DD)
  --dateTo: string # Filter by date range end (ISO format: YYYY-MM-DD)
  --complianceOnly: string@bool-completer # Filter for compliance samples only (default: false, e.g. true)
  --sampleMaterialType: string # Filter by sample material type code(s), optionally as a comma-separated list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "samplingPurpose" $samplingPurpose "scalar") (serialize-qp "sampleSamplingNotation" $sampleSamplingNotation "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "complianceOnly" $complianceOnly "scalar") (serialize-qp "sampleMaterialType" $sampleMaterialType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sampling-point/($pointNotation)/sampling" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific sampling from its constituent notations
#
# GET /sampling-point/{pointNotation}/sampling/{samplingNotation}
# operationId: read_sampling_point_sampling_sampling_point__pointNotation__sampling__samplingNotation__get
export def "sampling-point-sampling get" [
  pointNotation: string
  samplingNotation: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sampling-point/($pointNotation)/sampling/($samplingNotation)")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List and filter samples for a specific sampling point by its notation
#
# GET /sampling-point/{pointNotation}/sample
# operationId: list_sampling_point_sample_sampling_point__pointNotation__sample_get
export def "sampling-point-sample list" [
  pointNotation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 100)
  --samplingPurpose: string # Filter by sampling purpose code(s), optionally as a comma-separated list
  --sampleSamplingNotation: string # Filter by Sample/Sampling notation
  --date: string # Filter by exact date (ISO format: YYYY-MM-DD), cannot be used with dateFrom/dateTo
  --dateFrom: string # Filter by date range start (ISO format: YYYY-MM-DD)
  --dateTo: string # Filter by date range end (ISO format: YYYY-MM-DD)
  --complianceOnly: string@bool-completer # Filter for compliance samples only (default: false, e.g. true)
  --sampleMaterialType: string # Filter by sample material type code(s), optionally as a comma-separated list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "samplingPurpose" $samplingPurpose "scalar") (serialize-qp "sampleSamplingNotation" $sampleSamplingNotation "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "complianceOnly" $complianceOnly "scalar") (serialize-qp "sampleMaterialType" $sampleMaterialType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sampling-point/($pointNotation)/sample" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific sample from its constituent notations
#
# GET /sampling-point/{pointNotation}/sample/{sampleNotation}
# operationId: read_sampling_point_sample_sampling_point__pointNotation__sample__sampleNotation__get
export def "sampling-point-sample get" [
  pointNotation: string
  sampleNotation: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sampling-point/($pointNotation)/sample/($sampleNotation)")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List and filter observations for a specific sampling point by its notation
#
# GET /sampling-point/{pointNotation}/observation
# operationId: list_sampling_point_observations_sampling_point__pointNotation__observation_get
export def "sampling-point-observation get" [
  pointNotation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 100)
  --determinand: string # Filter by determinand code(s), optionally as a comma-separated list
  --sampleMaterialType: string # Filter by sample material type code(s), optionally as a comma-separated list
  --sampleSamplingNotation: string # Filter by Sample/Sampling notation
  --samplingPurpose: string # Filter by sampling purpose code(s), optionally as a comma-separated list
  --date: string # Filter by exact date (ISO format: YYYY-MM-DD), cannot be used with dateFrom/dateTo
  --dateFrom: string # Filter by date range start (ISO format: YYYY-MM-DD) (e.g. 2020-01-01)
  --dateTo: string # Filter by date range end (ISO format: YYYY-MM-DD) (e.g. 2020-12-31)
  --complianceOnly: string@bool-completer # Filter for compliance samples only (default: false)
  --Accept-Crs: string@Accept-Crs-completer # Coordinate Reference System URI for response, e.g. http://www.opengis.net/def/crs/EPSG/0/27700 or http://www.opengis.net/def/crs/EPSG/0/4326
  --CSV-Header: string@CSV-Header-completer # Whether to include the CSV Header row in the response.
  --API-Version: string # Content negotiation header to specify version of the API to use. (e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "determinand" $determinand "scalar") (serialize-qp "sampleMaterialType" $sampleMaterialType "scalar") (serialize-qp "sampleSamplingNotation" $sampleSamplingNotation "scalar") (serialize-qp "samplingPurpose" $samplingPurpose "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "complianceOnly" $complianceOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sampling-point/($pointNotation)/observation" $qp)
  let extra_headers = {"Accept-Crs": $Accept_Crs, "CSV-Header": $CSV_Header, "API-Version": $API_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/ld+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific observation from its constituent notations
#
# GET /sampling-point/{pointNotation}/sample/{sampleNotation}/observation/{observationNotation}
# operationId: read_sampling_point_sample_observation_sampling_point__pointNotation__sample__sampleNotation__observation__observationNotation__get
export def "sampling-point-sample-observation get" [
  pointNotation: string
  sampleNotation: int
  observationNotation: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept-Crs: string@Accept-Crs-completer # Coordinate Reference System URI for response, e.g. http://www.opengis.net/def/crs/EPSG/0/27700 or http://www.opengis.net/def/crs/EPSG/0/4326
  --API-Version: string # Content negotiation header to specify version of the API to use. (e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sampling-point/($pointNotation)/sample/($sampleNotation)/observation/($observationNotation)")
  let extra_headers = {"Accept-Crs": $Accept_Crs, "API-Version": $API_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List and filter observations (including for multiple sampling points)
#
# POST /data/observation
# operationId: list_observations_data_observation_post
export def "data-observation post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 250)
  --determinand: string # Filter by determinand code(s), optionally as a comma-separated list
  --samplingPurpose: string # Filter by sampling purpose code(s), optionally as a comma-separated list
  --sampleSamplingNotation: string # Filter by Sample/Sampling notation
  --date: string # Filter by exact date (ISO format: YYYY-MM-DD), cannot be used with dateFrom/dateTo
  --dateFrom: string # Filter by date range start (ISO format: YYYY-MM-DD) (e.g. 2020-01-01)
  --dateTo: string # Filter by date range end (ISO format: YYYY-MM-DD) (e.g. 2020-12-31)
  --complianceOnly: string@bool-completer # Filter for compliance samples only (default: false)
  --sampleMaterialType: string # Filter by sample material type code(s), optionally as a comma-separated list
  --easting: string # OS Grid easting coordinate for radius-based search
  --northing: string # OS Grid northing coordinate for radius-based search
  --latitude: string # Latitude coordinate for radius-based search
  --longitude: string # Longitude coordinate for radius-based search
  --radius: string # Search radius in kilometers for geographic queries
  --precannedArea: string # Filter by pre-defined area using format area_type,area_notation (e.g. environment_agency,YOR)
  --pointNotation: string # Filter by exact notation, optionally as a comma-separated list of no more than 100 notations (e.g. AN-CORBY)
  --prefLabel: string # Filter by prefLabel (contains)
  --region: string # Filter by region code
  --area: string # Filter by area code
  --subArea: string # Filter by subArea code
  --samplingPointStatus: string # Filter by status code
  --samplingPointType: string # Filter by single|multiple point type code e.g. 'FJ,SA'
  --Accept-Crs: string@Accept-Crs-completer # Coordinate Reference System URI for response, e.g. http://www.opengis.net/def/crs/EPSG/0/27700 or http://www.opengis.net/def/crs/EPSG/0/4326
  --CSV-Header: string@CSV-Header-completer # Whether to include the CSV Header row in the response.
  --API-Version: string # Content negotiation header to specify version of the API to use. (e.g. 1)
  --bbox: any
  --type: string
  --coordinates: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "determinand" $determinand "scalar") (serialize-qp "samplingPurpose" $samplingPurpose "scalar") (serialize-qp "sampleSamplingNotation" $sampleSamplingNotation "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "complianceOnly" $complianceOnly "scalar") (serialize-qp "sampleMaterialType" $sampleMaterialType "scalar") (serialize-qp "easting" $easting "scalar") (serialize-qp "northing" $northing "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "precannedArea" $precannedArea "scalar") (serialize-qp "pointNotation" $pointNotation "scalar") (serialize-qp "prefLabel" $prefLabel "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "area" $area "scalar") (serialize-qp "subArea" $subArea "scalar") (serialize-qp "samplingPointStatus" $samplingPointStatus "scalar") (serialize-qp "samplingPointType" $samplingPointType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/observation" $qp)
  let body = {bbox: $bbox, type: $type, coordinates: $coordinates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Crs": $Accept_Crs, "CSV-Header": $CSV_Header, "API-Version": $API_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/ld+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Context File
#
# GET /context/{contextFilename}
# operationId: get_context_file_context__contextFilename__get
export def "context get" [
  contextFilename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/context/($contextFilename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List and filter sample materials
#
# GET /codelist/sample-material
# operationId: list_sample_materials_codelist_sample_material_get
export def "codelist-sample-material get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 100)
  --notation: string # (Codelist) Exact match for notation
  --prefLabel: string # (Codelist) A case-insensitive contains search
  --qp-sort: string # (Codelist) Sort by field,direction (e.g., `'prefLabel,ASC'`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "notation" $notation "scalar") (serialize-qp "prefLabel" $prefLabel "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/codelist/sample-material" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List and filter sampling point statuses
#
# GET /codelist/sampling-point-status
# operationId: list_sampling_point_statuses_codelist_sampling_point_status_get
export def "codelist-sampling-point-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 100)
  --notation: string # (Codelist) Exact match for notation
  --prefLabel: string # (Codelist) A case-insensitive contains search
  --qp-sort: string # (Codelist) Sort by field,direction (e.g., `'prefLabel,ASC'`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "notation" $notation "scalar") (serialize-qp "prefLabel" $prefLabel "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/codelist/sampling-point-status" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List and filter sampling point types
#
# GET /codelist/sampling-point-type
# operationId: list_sampling_point_types_codelist_sampling_point_type_get
export def "codelist-sampling-point-type get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 100)
  --notation: string # (Codelist) Exact match for notation
  --prefLabel: string # (Codelist) A case-insensitive contains search
  --qp-sort: string # (Codelist) Sort by field,direction (e.g., `'prefLabel,ASC'`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "notation" $notation "scalar") (serialize-qp "prefLabel" $prefLabel "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/codelist/sampling-point-type" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List and filter determinands
#
# GET /codelist/determinand
# operationId: list_determinands_codelist_determinand_get
export def "codelist-determinand get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 100)
  --notation: string # (Codelist) Exact match for notation
  --prefLabel: string # (Codelist) A case-insensitive contains search
  --qp-sort: string # (Codelist) Sort by field,direction (e.g., `'prefLabel,ASC'`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "notation" $notation "scalar") (serialize-qp "prefLabel" $prefLabel "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/codelist/determinand" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List and filter units
#
# GET /codelist/unit
# operationId: list_units_codelist_unit_get
export def "codelist-unit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 100)
  --notation: string # (Codelist) Exact match for notation
  --prefLabel: string # (Codelist) A case-insensitive contains search
  --qp-sort: string # (Codelist) Sort by field,direction (e.g., `'prefLabel,ASC'`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "notation" $notation "scalar") (serialize-qp "prefLabel" $prefLabel "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/codelist/unit" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List and filter sampling purposes
#
# GET /codelist/sampling-purpose
# operationId: list_sampling_purposes_codelist_sampling_purpose_get
export def "codelist-sampling-purpose get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip: int # (Pagination) Number of records to skip (default: 0)
  --limit: int # (Pagination) Maximum number of records to return (default: 100)
  --notation: string # (Codelist) Exact match for notation
  --prefLabel: string # (Codelist) A case-insensitive contains search
  --qp-sort: string # (Codelist) Sort by field,direction (e.g., `'prefLabel,ASC'`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "notation" $notation "scalar") (serialize-qp "prefLabel" $prefLabel "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/codelist/sampling-purpose" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
