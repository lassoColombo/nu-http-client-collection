# Auto-generated client for Neblio REST API Suite v1.3.0
# Source: https://api.apis.guru/v2/specs/nebl.io/1.3.0/openapi.json
# Auth: --token flag or $env.NEBLIO_REST_API_SUITE_TOKEN

const BASE_URL = "https://ntp1node.nebl.io"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o NEBLIO_REST_API_SUITE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://ntp1node.nebl.io" "http://127.0.0.1:6326" "http://127.0.0.1:16326"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "json-rpc create" } } | get name | first)
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

# Send a JSON-RPC call to a localhost neblio-Qt or nebliod node
#
# POST /
# operationId: json_rpc
export def "json-rpc create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Identifier of RCP caller (default: neblio-apis, e.g. neblio-apis)
  jsonrpc: string # JSON-RPC version (default: 1.0, e.g. 1.0)
  method: string # Name of the Neblio RPC method to call (e.g. getstakinginfo)
  params: list<string> # Array of string params that should be passed to the RPC method. (e.g. [])
]: any -> record<error: record, id: string, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "http://127.0.0.1:6326")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"id": $id, "jsonrpc": $jsonrpc, "method": $method, "params": $params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns address object
#
# GET /ins/addr/{address}
# operationId: getAddress
export def "ins-addr get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addrStr: string, balance: float, balanceSat: float, totalReceived: float, totalReceivedSat: float, totalSent: float, totalSentSat: float, transactions: list<string>, txAppearances: float, unconfirmedBalance: float, unconfirmedBalanceSat: float, unconfirmedTxAppearances: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/ins/addr/{address}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns address balance in sats
#
# GET /ins/addr/{address}/balance
# operationId: getAddressBalance
export def "ins-addr-balance get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<float, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/ins/addr/{address}/balance") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns total received by address in sats
#
# GET /ins/addr/{address}/totalReceived
# operationId: getAddressTotalReceived
export def "ins-addr-total-received get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<float, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/ins/addr/{address}/totalReceived") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns total sent by address in sats
#
# GET /ins/addr/{address}/totalSent
# operationId: getAddressTotalSent
export def "ins-addr-total-sent get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<float, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/ins/addr/{address}/totalSent") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns address unconfirmed balance in sats
#
# GET /ins/addr/{address}/unconfirmedBalance
# operationId: getAddressUnconfirmedBalance
export def "ins-addr-unconfirmed-balance get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<float, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/ins/addr/{address}/unconfirmedBalance") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns all UTXOs at a given address
#
# GET /ins/addr/{address}/utxo
# operationId: getAddressUtxos
export def "ins-addr-utxo get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<address: string, amount: float, confirmations: float, scriptPubKey: string, ts: float, txid: string, vout: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/ins/addr/{address}/utxo") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns block hash of block
#
# GET /ins/block-index/{blockindex}
# operationId: getBlockIndex
export def "ins-block-index get" [
  blockindex: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockHash: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($blockindex | is-empty) { error make --unspanned { msg: "path parameter 'blockindex' must be non-empty" } }
  let full_url = (build-url $base ({blockindex: (encode-path-segment $blockindex)} | format pattern "/ins/block-index/{blockindex}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information regarding a Neblio block
#
# GET /ins/block/{blockhash}
# operationId: getBlock
export def "ins-block get" [
  blockhash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bits: string, confirmations: float, difficulty: float, hash: string, height: float, merkleroot: string, nextblockhash: string, nonce: float, previousblockhash: string, reward: float, size: float, time: float, tx: list<string>, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($blockhash | is-empty) { error make --unspanned { msg: "path parameter 'blockhash' must be non-empty" } }
  let full_url = (build-url $base ({blockhash: (encode-path-segment $blockhash)} | format pattern "/ins/block/{blockhash}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns raw transaction hex
#
# GET /ins/rawtx/{txid}
# operationId: getRawTx
export def "ins-rawtx get-raw-tx" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rawtx: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($txid | is-empty) { error make --unspanned { msg: "path parameter 'txid' must be non-empty" } }
  let full_url = (build-url $base ({txid: (encode-path-segment $txid)} | format pattern "/ins/rawtx/{txid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Utility API for calling several blockchain node functions
#
# GET /ins/status
# operationId: getStatus
export def "ins-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Function to call, getInfo, getDifficulty, getBestBlockHash, or getLastBlockHash
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ins/status" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get node sync status
#
# GET /ins/sync
# operationId: getSync
export def "ins-sync get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockChainHeight: float, error: string, height: float, status: string, syncPercentage: float, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ins/sync" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Broadcasts a signed raw transaction to the network (not NTP1 specific)
#
# POST /ins/tx/send
# operationId: sendTx
export def "ins-tx-send send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rawtx: string # Signed raw tx hex to broadcast
]: any -> record<txid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ins/tx/send" $auth.query)
  let req_body = {"rawtx": $rawtx} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns transaction object
#
# GET /ins/tx/{txid}
# operationId: getTx
export def "ins-tx get" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: table<n: float, scriptSig: record, sequence: float, txid: string, value: float, valueSat: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, used: bool, usedBlockheight: float, usedTxid: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($txid | is-empty) { error make --unspanned { msg: "path parameter 'txid' must be non-empty" } }
  let full_url = (build-url $base ({txid: (encode-path-segment $txid)} | format pattern "/ins/tx/{txid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get transactions by block or address
#
# GET /ins/txs
# operationId: getTxs
export def "ins-txs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Address
  --block: string # Block Hash
  --page-num: float # Page number to display
]: nothing -> record<pagesTotal: float, txs: table<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: list, vout: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "block" $block "scalar") (serialize-qp "pageNum" $page_num "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ins/txs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"address": $address, "block": $block, "pageNum": $page_num} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Information On a Neblio Address
#
# GET /ntp1/addressinfo/{address}
# operationId: getAddressInfo
export def "ntp1-addressinfo get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, utxos: table<blockheight: float, blocktime: float, index: float, scriptPubKey: record, tokens: list, txid: string, used: bool, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/ntp1/addressinfo/{address}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Broadcasts a signed raw transaction to the network
#
# POST /ntp1/broadcast
# operationId: broadcastTx
export def "ntp1-broadcast create-tx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tx_hex: string # Signed raw tx hex to broadcast
]: any -> record<txid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ntp1/broadcast" $auth.query)
  let req_body = {"txHex": $tx_hex} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Builds a transaction that burns an NTP1 Token
#
# POST /ntp1/burntoken
# operationId: burnToken
# --burn item shape: {amount?: float, tokenId?: string}
# --transfer item shape: {address?: string, amount?: float, tokenId?: string}
export def "ntp1-burntoken create-burn-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  burn: list # Array of objects representing tokens to be burned — item shape: {amount?: float, tokenId?: string}
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --body-from: list<string> # Array of addresses to send the token from
  --transfer: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ntp1/burntoken" $auth.query)
  let req_body = {"burn": $burn, "fee": $fee, "from": $body_from, "transfer": $transfer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Builds a transaction that issues a new NTP1 Token
#
# POST /ntp1/issue
# operationId: issueToken
# --flags shape: {splitChange?: bool}
# --metadata shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
# --transfer item shape: {address?: string, amount?: float}
export def "ntp1-issue create-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # Number of tokens to issue
  divisibility: float # Number of decimal places the token should be divisble by (0-7)
  fee: float # Fee in satoshi to include in the issuance transaction min 1000000000 (10 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  issue_address: string # Address issuing the token
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --reissuable: oneof<nothing, bool> # whether the token should be reissuable
  transfer: list # item shape: {address?: string, amount?: float}
]: any -> record<tokenId: string, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ntp1/issue" $auth.query)
  let req_body = {"amount": $amount, "divisibility": $divisibility, "fee": $fee, "flags": $flags, "issueAddress": $issue_address, "metadata": $metadata, "reissuable": $reissuable, "transfer": $transfer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Builds a transaction that sends an NTP1 Token
#
# POST /ntp1/sendtoken
# operationId: sendToken
# --flags shape: {splitChange?: bool}
# --metadata shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
# --to item shape: {address?: string, amount?: float, tokenId?: string}
export def "ntp1-sendtoken send-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  --body-from: list<string> # Array of addresses to send the token from
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --sendutxo: list<string> # Array of UTXOs to send the token from
  --body-to: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ntp1/sendtoken" $auth.query)
  let req_body = {"fee": $fee, "flags": $flags, "from": $body_from, "metadata": $metadata, "sendutxo": $sendutxo, "to": $body_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get Addresses Holding a Token
#
# GET /ntp1/stakeholders/{tokenid}
# operationId: getTokenHolders
export def "ntp1-stakeholders get-token-holders" [
  tokenid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<aggregationPolicy: string, divibility: float, holders: table<address: string, amount: float>, lockStatus: bool, someUtxo: string, tokenId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($tokenid | is-empty) { error make --unspanned { msg: "path parameter 'tokenid' must be non-empty" } }
  let full_url = (build-url $base ({tokenid: (encode-path-segment $tokenid)} | format pattern "/ntp1/stakeholders/{tokenid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the tokenId representing a token
#
# GET /ntp1/tokenid/{tokensymbol}
# operationId: getTokenId
export def "ntp1-tokenid get-token" [
  tokensymbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tokenId: string, tokenName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($tokensymbol | is-empty) { error make --unspanned { msg: "path parameter 'tokensymbol' must be non-empty" } }
  let full_url = (build-url $base ({tokensymbol: (encode-path-segment $tokensymbol)} | format pattern "/ntp1/tokenid/{tokensymbol}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Metadata of Token
#
# GET /ntp1/tokenmetadata/{tokenid}
# operationId: getTokenMetadata
export def "ntp1-tokenmetadata list" [
  tokenid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($tokenid | is-empty) { error make --unspanned { msg: "path parameter 'tokenid' must be non-empty" } }
  let qp = [(serialize-qp "verbosity" $verbosity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tokenid: (encode-path-segment $tokenid)} | format pattern "/ntp1/tokenmetadata/{tokenid}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"verbosity": $verbosity} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get UTXO Metadata of Token
#
# GET /ntp1/tokenmetadata/{tokenid}/{utxo}
# operationId: getTokenMetadataOfUtxo
export def "ntp1-tokenmetadata get-token-metadata" [
  tokenid: string
  utxo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($tokenid | is-empty) { error make --unspanned { msg: "path parameter 'tokenid' must be non-empty" } }
  if ($utxo | is-empty) { error make --unspanned { msg: "path parameter 'utxo' must be non-empty" } }
  let qp = [(serialize-qp "verbosity" $verbosity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tokenid: (encode-path-segment $tokenid), utxo: (encode-path-segment $utxo)} | format pattern "/ntp1/tokenmetadata/{tokenid}/{utxo}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"verbosity": $verbosity} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Information On an NTP1 Transaction
#
# GET /ntp1/transactioninfo/{txid}
# operationId: getTransactionInfo
export def "ntp1-transactioninfo get-transaction" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, hex: string, locktime: float, time: float, totalsent: float, txid: string, version: float, vin: table<previousOutput: record, scriptSig: record, sequence: float, tokens: list, txid: string, value: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, tokens: list, used: bool, usedBlockheight: float, usedTxid: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($txid | is-empty) { error make --unspanned { msg: "path parameter 'txid' must be non-empty" } }
  let full_url = (build-url $base ({txid: (encode-path-segment $txid)} | format pattern "/ntp1/transactioninfo/{txid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Withdraws testnet NEBL to the specified address
#
# GET /testnet/faucet
# operationId: testnet_getFaucet
export def "testnet-faucet get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Your Neblio Testnet Address
  --amount: float # Amount of NEBL to withdrawal in satoshis
]: nothing -> record<data: record<txId: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "amount" $amount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/testnet/faucet" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"address": $address, "amount": $amount} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns address object
#
# GET /testnet/ins/addr/{address}
# operationId: testnet_getAddress
export def "testnet-ins-addr get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addrStr: string, balance: float, balanceSat: float, totalReceived: float, totalReceivedSat: float, totalSent: float, totalSentSat: float, transactions: list<string>, txAppearances: float, unconfirmedBalance: float, unconfirmedBalanceSat: float, unconfirmedTxAppearances: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/testnet/ins/addr/{address}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns address balance in sats
#
# GET /testnet/ins/addr/{address}/balance
# operationId: testnet_getAddressBalance
export def "testnet-ins-addr-balance get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<float, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/testnet/ins/addr/{address}/balance") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns total received by address in sats
#
# GET /testnet/ins/addr/{address}/totalReceived
# operationId: testnet_getAddressTotalReceived
export def "testnet-ins-addr-total-received get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<float, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/testnet/ins/addr/{address}/totalReceived") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns total sent by address in sats
#
# GET /testnet/ins/addr/{address}/totalSent
# operationId: testnet_getAddressTotalSent
export def "testnet-ins-addr-total-sent get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<float, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/testnet/ins/addr/{address}/totalSent") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns address unconfirmed balance in sats
#
# GET /testnet/ins/addr/{address}/unconfirmedBalance
# operationId: testnet_getAddressUnconfirmedBalance
export def "testnet-ins-addr-unconfirmed-balance get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<float, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/testnet/ins/addr/{address}/unconfirmedBalance") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns all UTXOs at a given address
#
# GET /testnet/ins/addr/{address}/utxo
# operationId: testnet_getAddressUtxos
export def "testnet-ins-addr-utxo get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<address: string, amount: float, confirmations: float, scriptPubKey: string, ts: float, txid: string, vout: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/testnet/ins/addr/{address}/utxo") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns block hash of block
#
# GET /testnet/ins/block-index/{blockindex}
# operationId: testnet_getBlockIndex
export def "testnet-ins-block-index get" [
  blockindex: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockHash: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($blockindex | is-empty) { error make --unspanned { msg: "path parameter 'blockindex' must be non-empty" } }
  let full_url = (build-url $base ({blockindex: (encode-path-segment $blockindex)} | format pattern "/testnet/ins/block-index/{blockindex}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information regarding a Neblio block
#
# GET /testnet/ins/block/{blockhash}
# operationId: testnet_getBlock
export def "testnet-ins-block get" [
  blockhash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bits: string, confirmations: float, difficulty: float, hash: string, height: float, merkleroot: string, nextblockhash: string, nonce: float, previousblockhash: string, reward: float, size: float, time: float, tx: list<string>, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($blockhash | is-empty) { error make --unspanned { msg: "path parameter 'blockhash' must be non-empty" } }
  let full_url = (build-url $base ({blockhash: (encode-path-segment $blockhash)} | format pattern "/testnet/ins/block/{blockhash}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns raw transaction hex
#
# GET /testnet/ins/rawtx/{txid}
# operationId: testnet_getRawTx
export def "testnet-ins-rawtx get-raw-tx" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rawtx: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($txid | is-empty) { error make --unspanned { msg: "path parameter 'txid' must be non-empty" } }
  let full_url = (build-url $base ({txid: (encode-path-segment $txid)} | format pattern "/testnet/ins/rawtx/{txid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Utility API for calling several blockchain node functions
#
# GET /testnet/ins/status
# operationId: testnet_getStatus
export def "testnet-ins-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Function to call, getInfo, getDifficulty, getBestBlockHash, or getLastBlockHash
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/testnet/ins/status" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get node sync status
#
# GET /testnet/ins/sync
# operationId: testnet_getSync
export def "testnet-ins-sync get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockChainHeight: float, error: string, height: float, status: string, syncPercentage: float, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ins/sync" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Broadcasts a signed raw transaction to the network (not NTP1 specific)
#
# POST /testnet/ins/tx/send
# operationId: testnet_sendTx
export def "testnet-ins-tx-send send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rawtx: string # Signed raw tx hex to broadcast
]: any -> record<txid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ins/tx/send" $auth.query)
  let req_body = {"rawtx": $rawtx} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns transaction object
#
# GET /testnet/ins/tx/{txid}
# operationId: testnet_getTx
export def "testnet-ins-tx get" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: table<n: float, scriptSig: record, sequence: float, txid: string, value: float, valueSat: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, used: bool, usedBlockheight: float, usedTxid: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($txid | is-empty) { error make --unspanned { msg: "path parameter 'txid' must be non-empty" } }
  let full_url = (build-url $base ({txid: (encode-path-segment $txid)} | format pattern "/testnet/ins/tx/{txid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get transactions by block or address
#
# GET /testnet/ins/txs
# operationId: testnet_getTxs
export def "testnet-ins-txs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Address
  --block: string # Block Hash
  --page-num: float # Page number to display
]: nothing -> record<pagesTotal: float, txs: table<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: list, vout: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "block" $block "scalar") (serialize-qp "pageNum" $page_num "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/testnet/ins/txs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"address": $address, "block": $block, "pageNum": $page_num} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Information On a Neblio Address
#
# GET /testnet/ntp1/addressinfo/{address}
# operationId: testnet_getAddressInfo
export def "testnet-ntp1-addressinfo get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, utxos: table<blockheight: float, blocktime: float, index: float, scriptPubKey: record, tokens: list, txid: string, used: bool, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($address | is-empty) { error make --unspanned { msg: "path parameter 'address' must be non-empty" } }
  let full_url = (build-url $base ({address: (encode-path-segment $address)} | format pattern "/testnet/ntp1/addressinfo/{address}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Broadcasts a signed raw transaction to the network
#
# POST /testnet/ntp1/broadcast
# operationId: testnet_broadcastTx
export def "testnet-ntp1-broadcast create-tx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tx_hex: string # Signed raw tx hex to broadcast
]: any -> record<txid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ntp1/broadcast" $auth.query)
  let req_body = {"txHex": $tx_hex} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Builds a transaction that burns an NTP1 Token
#
# POST /testnet/ntp1/burntoken
# operationId: testnet_burnToken
# --burn item shape: {amount?: float, tokenId?: string}
# --transfer item shape: {address?: string, amount?: float, tokenId?: string}
export def "testnet-ntp1-burntoken create-burn-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  burn: list # Array of objects representing tokens to be burned — item shape: {amount?: float, tokenId?: string}
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --body-from: list<string> # Array of addresses to send the token from
  --transfer: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ntp1/burntoken" $auth.query)
  let req_body = {"burn": $burn, "fee": $fee, "from": $body_from, "transfer": $transfer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Builds a transaction that issues a new NTP1 Token
#
# POST /testnet/ntp1/issue
# operationId: testnet_issueToken
# --flags shape: {splitChange?: bool}
# --metadata shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
# --transfer item shape: {address?: string, amount?: float}
export def "testnet-ntp1-issue create-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # Number of tokens to issue
  divisibility: float # Number of decimal places the token should be divisble by (0-7)
  fee: float # Fee in satoshi to include in the issuance transaction min 1000000000 (10 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  issue_address: string # Address issuing the token
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --reissuable: oneof<nothing, bool> # whether the token should be reissuable
  transfer: list # item shape: {address?: string, amount?: float}
]: any -> record<tokenId: string, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ntp1/issue" $auth.query)
  let req_body = {"amount": $amount, "divisibility": $divisibility, "fee": $fee, "flags": $flags, "issueAddress": $issue_address, "metadata": $metadata, "reissuable": $reissuable, "transfer": $transfer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Builds a transaction that sends an NTP1 Token
#
# POST /testnet/ntp1/sendtoken
# operationId: testnet_sendToken
# --flags shape: {splitChange?: bool}
# --metadata shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
# --to item shape: {address?: string, amount?: float, tokenId?: string}
export def "testnet-ntp1-sendtoken send-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  --body-from: list<string> # Array of addresses to send the token from
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --sendutxo: list<string> # Array of UTXOs to send the token from
  --body-to: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ntp1/sendtoken" $auth.query)
  let req_body = {"fee": $fee, "flags": $flags, "from": $body_from, "metadata": $metadata, "sendutxo": $sendutxo, "to": $body_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get Addresses Holding a Token
#
# GET /testnet/ntp1/stakeholders/{tokenid}
# operationId: testnet_getTokenHolders
export def "testnet-ntp1-stakeholders get-token-holders" [
  tokenid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<aggregationPolicy: string, divibility: float, holders: table<address: string, amount: float>, lockStatus: bool, someUtxo: string, tokenId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($tokenid | is-empty) { error make --unspanned { msg: "path parameter 'tokenid' must be non-empty" } }
  let full_url = (build-url $base ({tokenid: (encode-path-segment $tokenid)} | format pattern "/testnet/ntp1/stakeholders/{tokenid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the tokenId representing a token
#
# GET /testnet/ntp1/tokenid/{tokensymbol}
# operationId: testnet_getTokenId
export def "testnet-ntp1-tokenid get-token" [
  tokensymbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tokenId: string, tokenName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($tokensymbol | is-empty) { error make --unspanned { msg: "path parameter 'tokensymbol' must be non-empty" } }
  let full_url = (build-url $base ({tokensymbol: (encode-path-segment $tokensymbol)} | format pattern "/testnet/ntp1/tokenid/{tokensymbol}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Metadata of Token
#
# GET /testnet/ntp1/tokenmetadata/{tokenid}
# operationId: testnet_getTokenMetadata
export def "testnet-ntp1-tokenmetadata list" [
  tokenid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($tokenid | is-empty) { error make --unspanned { msg: "path parameter 'tokenid' must be non-empty" } }
  let qp = [(serialize-qp "verbosity" $verbosity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tokenid: (encode-path-segment $tokenid)} | format pattern "/testnet/ntp1/tokenmetadata/{tokenid}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"verbosity": $verbosity} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get UTXO Metadata of Token
#
# GET /testnet/ntp1/tokenmetadata/{tokenid}/{utxo}
# operationId: testnet_getTokenMetadataOfUtxo
export def "testnet-ntp1-tokenmetadata get-token-metadata" [
  tokenid: string
  utxo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($tokenid | is-empty) { error make --unspanned { msg: "path parameter 'tokenid' must be non-empty" } }
  if ($utxo | is-empty) { error make --unspanned { msg: "path parameter 'utxo' must be non-empty" } }
  let qp = [(serialize-qp "verbosity" $verbosity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tokenid: (encode-path-segment $tokenid), utxo: (encode-path-segment $utxo)} | format pattern "/testnet/ntp1/tokenmetadata/{tokenid}/{utxo}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"verbosity": $verbosity} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Information On an NTP1 Transaction
#
# GET /testnet/ntp1/transactioninfo/{txid}
# operationId: testnet_getTransactionInfo
export def "testnet-ntp1-transactioninfo get-transaction" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, hex: string, locktime: float, time: float, totalsent: float, txid: string, version: float, vin: table<previousOutput: record, scriptSig: record, sequence: float, tokens: list, txid: string, value: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, tokens: list, used: bool, usedBlockheight: float, usedTxid: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($txid | is-empty) { error make --unspanned { msg: "path parameter 'txid' must be non-empty" } }
  let full_url = (build-url $base ({txid: (encode-path-segment $txid)} | format pattern "/testnet/ntp1/transactioninfo/{txid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
