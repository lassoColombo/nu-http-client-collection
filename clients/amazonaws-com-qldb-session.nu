# Auto-generated client for Amazon QLDB Session v2019-07-11
# Source: https://api.apis.guru/v2/specs/amazonaws.com/qldb-session/2019-07-11/openapi.json
# Auth: --token flag or $env.AMAZON_QLDB_SESSION_TOKEN

const BASE_URL = "http://session.qldb.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_QLDB_SESSION_TOKEN | default "" }
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

def base-url-completer [] { ["http://session.qldb.us-east-1.amazonaws.com" "http://session.qldb.us-east-2.amazonaws.com" "http://session.qldb.us-west-1.amazonaws.com" "http://session.qldb.us-west-2.amazonaws.com" "http://session.qldb.us-gov-west-1.amazonaws.com" "http://session.qldb.us-gov-east-1.amazonaws.com" "http://session.qldb.ca-central-1.amazonaws.com" "http://session.qldb.eu-north-1.amazonaws.com" "http://session.qldb.eu-west-1.amazonaws.com" "http://session.qldb.eu-west-2.amazonaws.com" "http://session.qldb.eu-west-3.amazonaws.com" "http://session.qldb.eu-central-1.amazonaws.com" "http://session.qldb.eu-south-1.amazonaws.com" "http://session.qldb.af-south-1.amazonaws.com" "http://session.qldb.ap-northeast-1.amazonaws.com" "http://session.qldb.ap-northeast-2.amazonaws.com" "http://session.qldb.ap-northeast-3.amazonaws.com" "http://session.qldb.ap-southeast-1.amazonaws.com" "http://session.qldb.ap-southeast-2.amazonaws.com" "http://session.qldb.ap-east-1.amazonaws.com" "http://session.qldb.ap-south-1.amazonaws.com" "http://session.qldb.sa-east-1.amazonaws.com" "http://session.qldb.me-south-1.amazonaws.com" "https://session.qldb.us-east-1.amazonaws.com" "https://session.qldb.us-east-2.amazonaws.com" "https://session.qldb.us-west-1.amazonaws.com" "https://session.qldb.us-west-2.amazonaws.com" "https://session.qldb.us-gov-west-1.amazonaws.com" "https://session.qldb.us-gov-east-1.amazonaws.com" "https://session.qldb.ca-central-1.amazonaws.com" "https://session.qldb.eu-north-1.amazonaws.com" "https://session.qldb.eu-west-1.amazonaws.com" "https://session.qldb.eu-west-2.amazonaws.com" "https://session.qldb.eu-west-3.amazonaws.com" "https://session.qldb.eu-central-1.amazonaws.com" "https://session.qldb.eu-south-1.amazonaws.com" "https://session.qldb.af-south-1.amazonaws.com" "https://session.qldb.ap-northeast-1.amazonaws.com" "https://session.qldb.ap-northeast-2.amazonaws.com" "https://session.qldb.ap-northeast-3.amazonaws.com" "https://session.qldb.ap-southeast-1.amazonaws.com" "https://session.qldb.ap-southeast-2.amazonaws.com" "https://session.qldb.ap-east-1.amazonaws.com" "https://session.qldb.ap-south-1.amazonaws.com" "https://session.qldb.sa-east-1.amazonaws.com" "https://session.qldb.me-south-1.amazonaws.com" "http://session.qldb.cn-north-1.amazonaws.com.cn" "http://session.qldb.cn-northwest-1.amazonaws.com.cn" "https://session.qldb.cn-north-1.amazonaws.com.cn" "https://session.qldb.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["QLDBSession.SendCommand"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-qldb-session-send-command send" } } | get name | first)
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

# Sends a command to an Amazon QLDB ledger. Instead of interacting directly with this API, we recommend using the QLDB driver or the QLDB shell to execute data transactions on a ledger. If you are working with an AWS SDK, use the QLDB driver. The driver provides a high-level abstraction layer above this QLDB Session data plane and manages SendCommand API calls for you. For information and a list of supported programming languages, see Getting started with the driver (https://docs.aws.amazon.com/qldb/latest/developerguide/getting-started-driver.html) in the Amazon QLDB Developer Guide. If you are working with the AWS Command Line Interface (AWS CLI), use the QLDB shell. The shell is a command line interface that uses the QLDB driver to interact with a ledger. For information, see Accessing Amazon QLDB using the QLDB shell (https://docs.aws.amazon.com/qldb/latest/developerguide/data-shell.html).
#
# POST /#X-Amz-Target=QLDBSession.SendCommand
# operationId: SendCommand
export def "x-amz-target-qldb-session-send-command send" [
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
  --x-amz-target: string@x-amz-target-completer
  --session-token: any
  --start-session: any
  --start-transaction: any
  --end-session: any
  --commit-transaction: any
  --abort-transaction: any
  --execute-statement: any
  --fetch-page: any
]: any -> record<StartSession: record<SessionToken: record, TimingInformation: record<ProcessingTimeMilliseconds: record>>, StartTransaction: record<TransactionId: record, TimingInformation: record<ProcessingTimeMilliseconds: record>>, EndSession: record<TimingInformation: record<ProcessingTimeMilliseconds: record>>, CommitTransaction: record<TransactionId: record, CommitDigest: record, TimingInformation: record<ProcessingTimeMilliseconds: record>, ConsumedIOs: record<ReadIOs: record, WriteIOs: record>>, AbortTransaction: record<TimingInformation: record<ProcessingTimeMilliseconds: record>>, ExecuteStatement: record<FirstPage: record<Values: record, NextPageToken: record>, TimingInformation: record<ProcessingTimeMilliseconds: record>, ConsumedIOs: record<ReadIOs: record, WriteIOs: record>>, FetchPage: record<Page: record<Values: record, NextPageToken: record>, TimingInformation: record<ProcessingTimeMilliseconds: record>, ConsumedIOs: record<ReadIOs: record, WriteIOs: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=QLDBSession.SendCommand")
  let req_body = {"SessionToken": $session_token, "StartSession": $start_session, "StartTransaction": $start_transaction, "EndSession": $end_session, "CommitTransaction": $commit_transaction, "AbortTransaction": $abort_transaction, "ExecuteStatement": $execute_statement, "FetchPage": $fetch_page} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
