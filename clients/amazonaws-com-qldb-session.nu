# Auto-generated client for Amazon QLDB Session v2019-07-11
# Source: https://api.apis.guru/v2/specs/amazonaws.com/qldb-session/2019-07-11/openapi.json
# Auth: --token flag or $env.AMAZON_QLDB_SESSION_TOKEN

const BASE_URL = "http://session.qldb.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_QLDB_SESSION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://session.qldb.us-east-1.amazonaws.com" "http://session.qldb.us-east-2.amazonaws.com" "http://session.qldb.us-west-1.amazonaws.com" "http://session.qldb.us-west-2.amazonaws.com" "http://session.qldb.us-gov-west-1.amazonaws.com" "http://session.qldb.us-gov-east-1.amazonaws.com" "http://session.qldb.ca-central-1.amazonaws.com" "http://session.qldb.eu-north-1.amazonaws.com" "http://session.qldb.eu-west-1.amazonaws.com" "http://session.qldb.eu-west-2.amazonaws.com" "http://session.qldb.eu-west-3.amazonaws.com" "http://session.qldb.eu-central-1.amazonaws.com" "http://session.qldb.eu-south-1.amazonaws.com" "http://session.qldb.af-south-1.amazonaws.com" "http://session.qldb.ap-northeast-1.amazonaws.com" "http://session.qldb.ap-northeast-2.amazonaws.com" "http://session.qldb.ap-northeast-3.amazonaws.com" "http://session.qldb.ap-southeast-1.amazonaws.com" "http://session.qldb.ap-southeast-2.amazonaws.com" "http://session.qldb.ap-east-1.amazonaws.com" "http://session.qldb.ap-south-1.amazonaws.com" "http://session.qldb.sa-east-1.amazonaws.com" "http://session.qldb.me-south-1.amazonaws.com" "https://session.qldb.us-east-1.amazonaws.com" "https://session.qldb.us-east-2.amazonaws.com" "https://session.qldb.us-west-1.amazonaws.com" "https://session.qldb.us-west-2.amazonaws.com" "https://session.qldb.us-gov-west-1.amazonaws.com" "https://session.qldb.us-gov-east-1.amazonaws.com" "https://session.qldb.ca-central-1.amazonaws.com" "https://session.qldb.eu-north-1.amazonaws.com" "https://session.qldb.eu-west-1.amazonaws.com" "https://session.qldb.eu-west-2.amazonaws.com" "https://session.qldb.eu-west-3.amazonaws.com" "https://session.qldb.eu-central-1.amazonaws.com" "https://session.qldb.eu-south-1.amazonaws.com" "https://session.qldb.af-south-1.amazonaws.com" "https://session.qldb.ap-northeast-1.amazonaws.com" "https://session.qldb.ap-northeast-2.amazonaws.com" "https://session.qldb.ap-northeast-3.amazonaws.com" "https://session.qldb.ap-southeast-1.amazonaws.com" "https://session.qldb.ap-southeast-2.amazonaws.com" "https://session.qldb.ap-east-1.amazonaws.com" "https://session.qldb.ap-south-1.amazonaws.com" "https://session.qldb.sa-east-1.amazonaws.com" "https://session.qldb.me-south-1.amazonaws.com" "http://session.qldb.cn-north-1.amazonaws.com.cn" "http://session.qldb.cn-northwest-1.amazonaws.com.cn" "https://session.qldb.cn-north-1.amazonaws.com.cn" "https://session.qldb.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["QLDBSession.SendCommand"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["send-command" "commands"] | sort) } | get name | first)
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

# Sends a command to an Amazon QLDB ledger. Instead of interacting directly with this API, we recommend using the QLDB driver or the QLDB shell to execute data transactions on a ledger. If you are working with an AWS SDK, use the QLDB driver. The driver provides a high-level abstraction layer above this QLDB Session data plane and manages SendCommand API calls for you. For information and a list of supported programming languages, see Getting started with the driver (https://docs.aws.amazon.com/qldb/latest/developerguide/getting-started-driver.html) in the Amazon QLDB Developer Guide. If you are working with the AWS Command Line Interface (AWS CLI), use the QLDB shell. The shell is a command line interface that uses the QLDB driver to interact with a ledger. For information, see Accessing Amazon QLDB using the QLDB shell (https://docs.aws.amazon.com/qldb/latest/developerguide/data-shell.html).
#
# POST /
# operationId: SendCommand
export def "send-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer # required
  --session-token: string # Specifies the session token for the current command. A session token is constant throughout the life of the session. To obtain a session token, run the StartSession command. This SessionToken is required for every subsequent command that is issued during the current session.
  --start-session: record # Specifies a request to start a new session. — shape: {LedgerName: string}
  --start-transaction: record # Specifies a request to start a transaction.
  --end-session: record # Specifies a request to end the session.
  --commit-transaction: record # Contains the details of the transaction to commit. — shape: {TransactionId: string, CommitDigest: string}
  --abort-transaction: record # Contains the details of the transaction to abort.
  --execute-statement: record # Specifies a request to execute a statement. — shape: {TransactionId: string, Statement: string, Parameters?: list}
  --fetch-page: record # Specifies the details of the page to be fetched. — shape: {TransactionId: string, NextPageToken: string}
]: any -> oneof<record<StartSession: record<SessionToken: string, TimingInformation: record<ProcessingTimeMilliseconds: int>>, StartTransaction: record<TransactionId: string, TimingInformation: record<ProcessingTimeMilliseconds: int>>, EndSession: record<TimingInformation: record<ProcessingTimeMilliseconds: int>>, CommitTransaction: record<TransactionId: string, CommitDigest: string, TimingInformation: record<ProcessingTimeMilliseconds: int>, ConsumedIOs: record<ReadIOs: int, WriteIOs: int>>, AbortTransaction: record<TimingInformation: record<ProcessingTimeMilliseconds: int>>, ExecuteStatement: record<FirstPage: record<Values: list, NextPageToken: string>, TimingInformation: record<ProcessingTimeMilliseconds: int>, ConsumedIOs: record<ReadIOs: int, WriteIOs: int>>, FetchPage: record<Page: record<Values: list, NextPageToken: string>, TimingInformation: record<ProcessingTimeMilliseconds: int>, ConsumedIOs: record<ReadIOs: int, WriteIOs: int>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "QLDBSession.SendCommand")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SessionToken": $session_token, "StartSession": $start_session, "StartTransaction": $start_transaction, "EndSession": $end_session, "CommitTransaction": $commit_transaction, "AbortTransaction": $abort_transaction, "ExecuteStatement": $execute_statement, "FetchPage": $fetch_page} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
