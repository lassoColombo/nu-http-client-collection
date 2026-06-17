# Auto-generated client for Amazon Mobile Analytics v2014-06-05
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mobileanalytics/2014-06-05/openapi.json
# Auth: --token flag or $env.AMAZON_MOBILE_ANALYTICS_TOKEN

const BASE_URL = "http://mobileanalytics.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_MOBILE_ANALYTICS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["http://mobileanalytics.us-east-1.amazonaws.com" "http://mobileanalytics.us-east-2.amazonaws.com" "http://mobileanalytics.us-west-1.amazonaws.com" "http://mobileanalytics.us-west-2.amazonaws.com" "http://mobileanalytics.us-gov-west-1.amazonaws.com" "http://mobileanalytics.us-gov-east-1.amazonaws.com" "http://mobileanalytics.ca-central-1.amazonaws.com" "http://mobileanalytics.eu-north-1.amazonaws.com" "http://mobileanalytics.eu-west-1.amazonaws.com" "http://mobileanalytics.eu-west-2.amazonaws.com" "http://mobileanalytics.eu-west-3.amazonaws.com" "http://mobileanalytics.eu-central-1.amazonaws.com" "http://mobileanalytics.eu-south-1.amazonaws.com" "http://mobileanalytics.af-south-1.amazonaws.com" "http://mobileanalytics.ap-northeast-1.amazonaws.com" "http://mobileanalytics.ap-northeast-2.amazonaws.com" "http://mobileanalytics.ap-northeast-3.amazonaws.com" "http://mobileanalytics.ap-southeast-1.amazonaws.com" "http://mobileanalytics.ap-southeast-2.amazonaws.com" "http://mobileanalytics.ap-east-1.amazonaws.com" "http://mobileanalytics.ap-south-1.amazonaws.com" "http://mobileanalytics.sa-east-1.amazonaws.com" "http://mobileanalytics.me-south-1.amazonaws.com" "https://mobileanalytics.us-east-1.amazonaws.com" "https://mobileanalytics.us-east-2.amazonaws.com" "https://mobileanalytics.us-west-1.amazonaws.com" "https://mobileanalytics.us-west-2.amazonaws.com" "https://mobileanalytics.us-gov-west-1.amazonaws.com" "https://mobileanalytics.us-gov-east-1.amazonaws.com" "https://mobileanalytics.ca-central-1.amazonaws.com" "https://mobileanalytics.eu-north-1.amazonaws.com" "https://mobileanalytics.eu-west-1.amazonaws.com" "https://mobileanalytics.eu-west-2.amazonaws.com" "https://mobileanalytics.eu-west-3.amazonaws.com" "https://mobileanalytics.eu-central-1.amazonaws.com" "https://mobileanalytics.eu-south-1.amazonaws.com" "https://mobileanalytics.af-south-1.amazonaws.com" "https://mobileanalytics.ap-northeast-1.amazonaws.com" "https://mobileanalytics.ap-northeast-2.amazonaws.com" "https://mobileanalytics.ap-northeast-3.amazonaws.com" "https://mobileanalytics.ap-southeast-1.amazonaws.com" "https://mobileanalytics.ap-southeast-2.amazonaws.com" "https://mobileanalytics.ap-east-1.amazonaws.com" "https://mobileanalytics.ap-south-1.amazonaws.com" "https://mobileanalytics.sa-east-1.amazonaws.com" "https://mobileanalytics.me-south-1.amazonaws.com" "http://mobileanalytics.cn-north-1.amazonaws.com.cn" "http://mobileanalytics.cn-northwest-1.amazonaws.com.cn" "https://mobileanalytics.cn-north-1.amazonaws.com.cn" "https://mobileanalytics.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2014-06-05-eventsx-amz-client-context update-events" } } | get name | first)
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

# The PutEvents operation records one or more events. You can have up to 1,500 unique custom events per app, any combination of up to 40 attributes and metrics per custom event, and any number of attribute or metric values.
#
# POST /2014-06-05/events#x-amz-Client-Context
# operationId: PutEvents
# --events item shape: {eventType: any, timestamp: any, session?: any, version?: any, attributes?: any, metrics?: any}
export def "2014-06-05-eventsx-amz-client-context update-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-client-context: string # The client context including the client ID, app title, app version and package name.
  --x-amz-client-context-encoding: string # The encoding used for the client context.
  events: list # An array of Event JSON objects — item shape: {eventType: any, timestamp: any, session?: any, version?: any, attributes?: any, metrics?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2014-06-05/events#x-amz-Client-Context")
  let body = {"events": $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-Client-Context": $x_amz_client_context, "x-amz-Client-Context-Encoding": $x_amz_client_context_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
