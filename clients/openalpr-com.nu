# Auto-generated client for OpenALPR CarCheck API v3.0.1
# Source: https://api.apis.guru/v2/specs/openalpr.com/3.0.1/swagger.json
# Auth: --token flag or $env.OPENALPR_CARCHECK_API_TOKEN

const BASE_URL = "https://api.openalpr.com/v3"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENALPR_CARCHECK_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.openalpr.com/v3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def recognize-vehicle-completer [] { ["0" "1"] }
def return-image-completer [] { ["0" "1"] }
def is-cropped-completer [] { ["0" "1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "config get" } } | get name | first)
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

# Get a list of available results for plate and vehicle recognition
#
# GET /config
# operationId: getConfig
export def "config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countries: table<code: string, name: string>, vehicle_labels: record<bodytype: list<string>, color: list<string>, make: list<string>, makemodel: list<string>, orientation: list<string>, year: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send an image for OpenALPR to analyze and provide metadata back The image is sent as a file using a form data POST
#
# POST /recognize
# operationId: recognizeFile
export def "recognize recognizeFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret-key: string # The secret key used to authenticate your account.  You can view your  secret key by visiting  https://cloud.openalpr.com/
  --recognize-vehicle: int@recognize-vehicle-completer # If set to 1, the vehicle will also be recognized in the image This requires an additional credit per request  (default: 0)
  --country: string # Defines the training data used by OpenALPR.  "us" analyzes  North-American style plates.  "eu" analyzes European-style plates.  This field is required if using the "plate" task
  --return-image: int@return-image-completer # If set to 1, the image you uploaded will be encoded in base64 and  sent back along with the response  (default: 0)
  --topn: int # The number of results you would like to be returned for plate  candidates and vehicle classifications  (default: 10)
  --is-cropped: int@is-cropped-completer # When providing a plate or vehicle that is already cropped,   this performs a recognition against the full crop and does not  attempt to localize the plate/vehicle  (default: 0)
  image: path # The image file that you wish to analyze
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "secret_key" $secret_key "scalar") (serialize-qp "recognize_vehicle" $recognize_vehicle "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "return_image" $return_image "scalar") (serialize-qp "topn" $topn "scalar") (serialize-qp "is_cropped" $is_cropped "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recognize" $qp)
  let body = {"image": $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($image | is-not-empty) { $body | upsert image (open -r $image) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Send an image for OpenALPR to analyze and provide metadata back The image is sent as base64 encoded bytes.
#
# POST /recognize_bytes
# operationId: recognizeBytes
export def "recognize-bytes recognizeBytes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret-key: string # The secret key used to authenticate your account.  You can view your  secret key by visiting  https://cloud.openalpr.com/
  --recognize-vehicle: int@recognize-vehicle-completer # If set to 1, the vehicle will also be recognized in the image This requires an additional credit per request  (default: 0)
  --country: string # Defines the training data used by OpenALPR.  "us" analyzes  North-American style plates.  "eu" analyzes European-style plates.  This field is required if using the "plate" task
  --return-image: int@return-image-completer # If set to 1, the image you uploaded will be encoded in base64 and  sent back along with the response  (default: 0)
  --topn: int # The number of results you would like to be returned for plate  candidates and vehicle classifications  (default: 10)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "secret_key" $secret_key "scalar") (serialize-qp "recognize_vehicle" $recognize_vehicle "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "return_image" $return_image "scalar") (serialize-qp "topn" $topn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recognize_bytes" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send an image for OpenALPR to analyze and provide metadata back The image is sent as a URL.  The OpenALPR service will download the image  and process it
#
# POST /recognize_url
# operationId: recognizeUrl
export def "recognize-url recognizeUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-url: string # A URL to an image that you wish to analyze
  --secret-key: string # The secret key used to authenticate your account.  You can view your  secret key by visiting  https://cloud.openalpr.com/
  --recognize-vehicle: int@recognize-vehicle-completer # If set to 1, the vehicle will also be recognized in the image This requires an additional credit per request  (default: 0)
  --country: string # Defines the training data used by OpenALPR.  "us" analyzes  North-American style plates.  "eu" analyzes European-style plates.  This field is required if using the "plate" task
  --return-image: int@return-image-completer # If set to 1, the image you uploaded will be encoded in base64 and  sent back along with the response  (default: 0)
  --topn: int # The number of results you would like to be returned for plate  candidates and vehicle classifications  (default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "image_url" $image_url "scalar") (serialize-qp "secret_key" $secret_key "scalar") (serialize-qp "recognize_vehicle" $recognize_vehicle "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "return_image" $return_image "scalar") (serialize-qp "topn" $topn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recognize_url" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
