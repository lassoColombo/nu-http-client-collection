# Auto-generated client for Neblio REST API Suite v1.3.0
# Source: https://api.apis.guru/v2/specs/nebl.io/1.3.0/openapi.json
# Auth: --token flag or $env.NEBLIO_REST_API_SUITE_TOKEN

const BASE_URL = "https://ntp1node.nebl.io"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NEBLIO_REST_API_SUITE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://ntp1node.nebl.io" "http://127.0.0.1:6326" "http://127.0.0.1:16326"] }
def auth-scheme-completer [] { ["basic"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "json-rpc rpc" } } | get name | first)
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
export def "json-rpc rpc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Identifier of RCP caller (default: neblio-apis, e.g. neblio-apis)
  jsonrpc: string # JSON-RPC version (default: 1.0, e.g. 1.0)
  method: string # Name of the Neblio RPC method to call (e.g. getstakinginfo)
  params: list # Array of string params that should be passed to the RPC method. (e.g. [])
]: any -> record<error: record, id: string, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "http://127.0.0.1:6326")
  let full_url = (build-url $base "/")
  let body = {id: $id, jsonrpc: $jsonrpc, method: $method, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addrStr: string, balance: float, balanceSat: float, totalReceived: float, totalReceivedSat: float, totalSent: float, totalSentSat: float, transactions: list<string>, txAppearances: float, unconfirmedBalance: float, unconfirmedBalanceSat: float, unconfirmedTxAppearances: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ins/addr/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ins/addr/($address)/balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ins/addr/($address)/totalReceived")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ins/addr/($address)/totalSent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ins/addr/($address)/unconfirmedBalance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<address: string, amount: float, confirmations: float, scriptPubKey: string, ts: float, txid: string, vout: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ins/addr/($address)/utxo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockHash: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ins/block-index/($blockindex)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bits: string, confirmations: float, difficulty: float, hash: string, height: float, merkleroot: string, nextblockhash: string, nonce: float, previousblockhash: string, reward: float, size: float, time: float, tx: list<string>, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ins/block/($blockhash)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns raw transaction hex
#
# GET /ins/rawtx/{txid}
# operationId: getRawTx
export def "ins-rawtx get" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rawtx: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ins/rawtx/($txid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Function to call, getInfo, getDifficulty, getBestBlockHash, or getLastBlockHash
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ins/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockChainHeight: float, error: string, height: float, status: string, syncPercentage: float, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ins/sync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Broadcasts a signed raw transaction to the network (not NTP1 specific)
#
# POST /ins/tx/send
# operationId: sendTx
export def "ins-tx-send sendTx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rawtx: string # Signed raw tx hex to broadcast
]: any -> record<txid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ins/tx/send")
  let body = {rawtx: $rawtx} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: table<n: float, scriptSig: record, sequence: float, txid: string, value: float, valueSat: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, used: bool, usedBlockheight: float, usedTxid: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ins/tx/($txid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Address
  --block: string # Block Hash
  --pageNum: float # Page number to display
]: nothing -> record<pagesTotal: float, txs: table<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: list, vout: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "block" $block "scalar") (serialize-qp "pageNum" $pageNum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ins/txs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, utxos: table<blockheight: float, blocktime: float, index: float, scriptPubKey: record, tokens: list, txid: string, used: bool, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ntp1/addressinfo/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Broadcasts a signed raw transaction to the network
#
# POST /ntp1/broadcast
# operationId: broadcastTx
export def "ntp1-broadcast broadcastTx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  txHex: string # Signed raw tx hex to broadcast
]: any -> record<txid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ntp1/broadcast")
  let body = {txHex: $txHex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Builds a transaction that burns an NTP1 Token
#
# POST /ntp1/burntoken
# operationId: burnToken
# --burn item shape: {amount?: float, tokenId?: string}
# --transfer item shape: {address?: string, amount?: float, tokenId?: string}
export def "ntp1-burntoken burnToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  burn: list # Array of objects representing tokens to be burned — item shape: {amount?: float, tokenId?: string}
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --body-from: list # Array of addresses to send the token from
  --transfer: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ntp1/burntoken")
  let body = {burn: $burn, fee: $fee, from: $body_from, transfer: $transfer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Builds a transaction that issues a new NTP1 Token
#
# POST /ntp1/issue
# operationId: issueToken
# --flags shape: {splitChange?: bool}
# --metadata shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
# --transfer item shape: {address?: string, amount?: float}
export def "ntp1-issue issueToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # Number of tokens to issue
  divisibility: float # Number of decimal places the token should be divisble by (0-7)
  fee: float # Fee in satoshi to include in the issuance transaction min 1000000000 (10 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  issueAddress: string # Address issuing the token
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --reissuable: oneof<nothing, bool> # whether the token should be reissuable
  transfer: list # item shape: {address?: string, amount?: float}
]: any -> record<tokenId: string, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ntp1/issue")
  let body = {amount: $amount, divisibility: $divisibility, fee: $fee, flags: $flags, issueAddress: $issueAddress, metadata: $metadata, reissuable: $reissuable, transfer: $transfer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Builds a transaction that sends an NTP1 Token
#
# POST /ntp1/sendtoken
# operationId: sendToken
# --flags shape: {splitChange?: bool}
# --metadata shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
# --to item shape: {address?: string, amount?: float, tokenId?: string}
export def "ntp1-sendtoken sendToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  --body-from: list # Array of addresses to send the token from
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --sendutxo: list # Array of UTXOs to send the token from
  --body-to: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ntp1/sendtoken")
  let body = {fee: $fee, flags: $flags, from: $body_from, metadata: $metadata, sendutxo: $sendutxo, to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Addresses Holding a Token
#
# GET /ntp1/stakeholders/{tokenid}
# operationId: getTokenHolders
export def "ntp1-stakeholders get" [
  tokenid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<aggregationPolicy: string, divibility: float, holders: table<address: string, amount: float>, lockStatus: bool, someUtxo: string, tokenId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ntp1/stakeholders/($tokenid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the tokenId representing a token
#
# GET /ntp1/tokenid/{tokensymbol}
# operationId: getTokenId
export def "ntp1-tokenid get" [
  tokensymbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tokenId: string, tokenName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ntp1/tokenid/($tokensymbol)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "verbosity" $verbosity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ntp1/tokenmetadata/($tokenid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get UTXO Metadata of Token
#
# GET /ntp1/tokenmetadata/{tokenid}/{utxo}
# operationId: getTokenMetadataOfUtxo
export def "ntp1-tokenmetadata get" [
  tokenid: string
  utxo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "verbosity" $verbosity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ntp1/tokenmetadata/($tokenid)/($utxo)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Information On an NTP1 Transaction
#
# GET /ntp1/transactioninfo/{txid}
# operationId: getTransactionInfo
export def "ntp1-transactioninfo get" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, hex: string, locktime: float, time: float, totalsent: float, txid: string, version: float, vin: table<previousOutput: record, scriptSig: record, sequence: float, tokens: list, txid: string, value: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, tokens: list, used: bool, usedBlockheight: float, usedTxid: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ntp1/transactioninfo/($txid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Your Neblio Testnet Address
  --amount: float # Amount of NEBL to withdrawal in satoshis
]: nothing -> record<data: record<txId: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "amount" $amount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/testnet/faucet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addrStr: string, balance: float, balanceSat: float, totalReceived: float, totalReceivedSat: float, totalSent: float, totalSentSat: float, transactions: list<string>, txAppearances: float, unconfirmedBalance: float, unconfirmedBalanceSat: float, unconfirmedTxAppearances: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ins/addr/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ins/addr/($address)/balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ins/addr/($address)/totalReceived")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ins/addr/($address)/totalSent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ins/addr/($address)/unconfirmedBalance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<address: string, amount: float, confirmations: float, scriptPubKey: string, ts: float, txid: string, vout: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ins/addr/($address)/utxo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockHash: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ins/block-index/($blockindex)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bits: string, confirmations: float, difficulty: float, hash: string, height: float, merkleroot: string, nextblockhash: string, nonce: float, previousblockhash: string, reward: float, size: float, time: float, tx: list<string>, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ins/block/($blockhash)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns raw transaction hex
#
# GET /testnet/ins/rawtx/{txid}
# operationId: testnet_getRawTx
export def "testnet-ins-rawtx get" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rawtx: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ins/rawtx/($txid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Function to call, getInfo, getDifficulty, getBestBlockHash, or getLastBlockHash
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/testnet/ins/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockChainHeight: float, error: string, height: float, status: string, syncPercentage: float, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ins/sync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Broadcasts a signed raw transaction to the network (not NTP1 specific)
#
# POST /testnet/ins/tx/send
# operationId: testnet_sendTx
export def "testnet-ins-tx-send sendTx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rawtx: string # Signed raw tx hex to broadcast
]: any -> record<txid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ins/tx/send")
  let body = {rawtx: $rawtx} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: table<n: float, scriptSig: record, sequence: float, txid: string, value: float, valueSat: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, used: bool, usedBlockheight: float, usedTxid: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ins/tx/($txid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Address
  --block: string # Block Hash
  --pageNum: float # Page number to display
]: nothing -> record<pagesTotal: float, txs: table<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, fees: float, locktime: float, size: float, time: float, totalsent: float, txid: string, valueIn: float, valueOut: float, version: float, vin: list, vout: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "block" $block "scalar") (serialize-qp "pageNum" $pageNum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/testnet/ins/txs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, utxos: table<blockheight: float, blocktime: float, index: float, scriptPubKey: record, tokens: list, txid: string, used: bool, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ntp1/addressinfo/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Broadcasts a signed raw transaction to the network
#
# POST /testnet/ntp1/broadcast
# operationId: testnet_broadcastTx
export def "testnet-ntp1-broadcast broadcastTx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  txHex: string # Signed raw tx hex to broadcast
]: any -> record<txid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ntp1/broadcast")
  let body = {txHex: $txHex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Builds a transaction that burns an NTP1 Token
#
# POST /testnet/ntp1/burntoken
# operationId: testnet_burnToken
# --burn item shape: {amount?: float, tokenId?: string}
# --transfer item shape: {address?: string, amount?: float, tokenId?: string}
export def "testnet-ntp1-burntoken burnToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  burn: list # Array of objects representing tokens to be burned — item shape: {amount?: float, tokenId?: string}
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --body-from: list # Array of addresses to send the token from
  --transfer: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ntp1/burntoken")
  let body = {burn: $burn, fee: $fee, from: $body_from, transfer: $transfer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Builds a transaction that issues a new NTP1 Token
#
# POST /testnet/ntp1/issue
# operationId: testnet_issueToken
# --flags shape: {splitChange?: bool}
# --metadata shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
# --transfer item shape: {address?: string, amount?: float}
export def "testnet-ntp1-issue issueToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # Number of tokens to issue
  divisibility: float # Number of decimal places the token should be divisble by (0-7)
  fee: float # Fee in satoshi to include in the issuance transaction min 1000000000 (10 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  issueAddress: string # Address issuing the token
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --reissuable: oneof<nothing, bool> # whether the token should be reissuable
  transfer: list # item shape: {address?: string, amount?: float}
]: any -> record<tokenId: string, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ntp1/issue")
  let body = {amount: $amount, divisibility: $divisibility, fee: $fee, flags: $flags, issueAddress: $issueAddress, metadata: $metadata, reissuable: $reissuable, transfer: $transfer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Builds a transaction that sends an NTP1 Token
#
# POST /testnet/ntp1/sendtoken
# operationId: testnet_sendToken
# --flags shape: {splitChange?: bool}
# --metadata shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
# --to item shape: {address?: string, amount?: float, tokenId?: string}
export def "testnet-ntp1-sendtoken sendToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fee: float # Fee in satoshi to include in the issuance transaction min 10000 (0.0001 NEBL)
  --flags: record # Object representing flags that potentialy modify this transaction — shape: {splitChange?: bool}
  --body-from: list # Array of addresses to send the token from
  --metadata: record # Object representing all metadata at token issuance — shape: {description?: string, encryptions?: list, issuer?: string, rules?: record, tokenName?: string, urls?: list, userData?: record}
  --sendutxo: list # Array of UTXOs to send the token from
  --body-to: list # item shape: {address?: string, amount?: float, tokenId?: string}
]: any -> record<multisigOutputs: list<float>, ntp1OutputIndexes: list<float>, txHex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testnet/ntp1/sendtoken")
  let body = {fee: $fee, flags: $flags, from: $body_from, metadata: $metadata, sendutxo: $sendutxo, to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Addresses Holding a Token
#
# GET /testnet/ntp1/stakeholders/{tokenid}
# operationId: testnet_getTokenHolders
export def "testnet-ntp1-stakeholders get" [
  tokenid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<aggregationPolicy: string, divibility: float, holders: table<address: string, amount: float>, lockStatus: bool, someUtxo: string, tokenId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ntp1/stakeholders/($tokenid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the tokenId representing a token
#
# GET /testnet/ntp1/tokenid/{tokensymbol}
# operationId: testnet_getTokenId
export def "testnet-ntp1-tokenid get" [
  tokensymbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tokenId: string, tokenName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ntp1/tokenid/($tokensymbol)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "verbosity" $verbosity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/testnet/ntp1/tokenmetadata/($tokenid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get UTXO Metadata of Token
#
# GET /testnet/ntp1/tokenmetadata/{tokenid}/{utxo}
# operationId: testnet_getTokenMetadataOfUtxo
export def "testnet-ntp1-tokenmetadata get" [
  tokenid: string
  utxo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbosity: float # 0 (Default) is fastest, 1 contains token stats, 2 contains token holding addresses
]: nothing -> record<aggregationPolicy: string, divisibility: float, firstBlock: float, initialIssuanceAmount: float, issuanceTxid: string, issueAddress: string, lockStatus: bool, metadataOfIssuance: record<data: record<description: string, issuer: string, tokenName: string, userData: record>>, metadataOfUtxo: record<userData: record<meta: list>>, numOfBurns: float, numOfHolders: float, numOfIssuance: float, numOfTransfers: float, someUtxo: string, tokenId: string, totalSupply: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "verbosity" $verbosity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/testnet/ntp1/tokenmetadata/($tokenid)/($utxo)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Information On an NTP1 Transaction
#
# GET /testnet/ntp1/transactioninfo/{txid}
# operationId: testnet_getTransactionInfo
export def "testnet-ntp1-transactioninfo get" [
  txid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blockhash: string, blockheight: float, blocktime: float, confirmations: float, fee: float, hex: string, locktime: float, time: float, totalsent: float, txid: string, version: float, vin: table<previousOutput: record, scriptSig: record, sequence: float, tokens: list, txid: string, value: float, vout: float>, vout: table<blockheight: float, n: float, scriptPubKey: record, tokens: list, used: bool, usedBlockheight: float, usedTxid: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testnet/ntp1/transactioninfo/($txid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
