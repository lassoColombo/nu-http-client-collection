# Auto-generated client for OpenCage Geocoder v1
# Source: https://api.apis.guru/v2/specs/opencagedata.com/1/swagger.json
# Auth: --token flag or $env.OPENCAGE_GEOCODER_TOKEN

const BASE_URL = "https://api.opencagedata.com/geocode"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENCAGE_GEOCODER_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.opencagedata.com/geocode"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/html"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v-version get" } } | get name | first)
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

# geocode a query
#
# GET /v{version}/{format}
export def "v-version get" [
  version: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # string or lat,lng to be geocoded.
  --key: string # an application key.
  --abbrv: oneof<nothing, bool> # when true we attempt to abbreviate the formatted field of results.
  --address-only: oneof<nothing, bool> # when true we include only address details in the formatted field of results.
  --add-request: oneof<nothing, bool> # if true the request is included in the response.
  --bounds: string # four coordinate points forming the south-west and north-east corners of a bounding box (min long, min lat, max long, max lat).
  --countrycode: string # two letter code ISO 3166-1 Alpha 2 code to limit results to that country.
  --jsonp: string # wraps the returned JSON with a function name.
  --language: string # an IETF format language code (ex: 'es' or 'pt-BR').
  --limit: int # maximum number of results to return. Default is 10. Maximum is 100.
  --min-confidence: int # integer from 1-10. Only results with at least this confidence are returned.
  --no-annotations: oneof<nothing, bool> # when true annotations are not added to results.
  --no-dedupe: oneof<nothing, bool> # when true results are not deduplicated.
  --no-record: oneof<nothing, bool> # when true query content is not logged.
  --pretty: oneof<nothing, bool> # when true results are pretty printed. Useful for debugging.
  --proximity: string # lat,lng to bias results.
  --roadinfo: oneof<nothing, bool> # match nearest road, include roadinfo annotation
]: nothing -> record<documentation: string, licenses: table<name: string, url: string>, rate: record<limit: int, remaining: int, reset: int>, results: table<annotations: record, bounds: record, components: record, confidence: int, formatted: string, geometry: record>, status: record<code: int, message: string>, stay_informed: record<blog: string, twitter: string>, thanks: string, timestamp: record<created_http: string, created_unix: int>, total_results: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "abbrv" $abbrv "scalar") (serialize-qp "address_only" $address_only "scalar") (serialize-qp "add_request" $add_request "scalar") (serialize-qp "bounds" $bounds "scalar") (serialize-qp "countrycode" $countrycode "scalar") (serialize-qp "jsonp" $jsonp "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "min_confidence" $min_confidence "scalar") (serialize-qp "no_annotations" $no_annotations "scalar") (serialize-qp "no_dedupe" $no_dedupe "scalar") (serialize-qp "no_record" $no_record "scalar") (serialize-qp "pretty" $pretty "scalar") (serialize-qp "proximity" $proximity "scalar") (serialize-qp "roadinfo" $roadinfo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v($version)/($format)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
