# Auto-generated client for 🔔 Webhooks v1.0
# Source: https://raw.githubusercontent.com/alchemyplatform/docs-openapi-specs/main/notify/notify.yaml
# Auth: --token flag or $env.WEBHOOKS_TOKEN

const BASE_URL = "https://dashboard.alchemy.com/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WEBHOOKS_TOKEN | default "" }
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
def base-url-completer [] { ["https://dashboard.alchemy.com/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def network-completer [] { ["APECHAIN_CURTIS" "APECHAIN_MAINNET" "ARBMAINNET" "ARBNOVA_MAINNET" "ARBSEPOLIA" "AVAX_FUJI" "AVAX_MAINNET" "BASE_MAINNET" "BASE_SEPOLIA" "BLAST_MAINNET" "BLAST_SEPOLIA" "BNB_MAINNET" "BNB_TESTNET" "ETH_HOLESKY" "ETH_MAINNET" "ETH_SEPOLIA" "FANTOM_MAINNET" "FANTOM_TESTNET" "GEIST_MAINNET" "GEIST_POLTER" "GNOSIS_CHIADO" "GNOSIS_MAINNET" "INK_MAINNET" "INK_SEPOLIA" "LINEA_MAINNET" "LINEA_MAINNET" "LINEA_SEPOLIA" "LINEA_SEPOLIA" "MATICMAINNET" "MATICMUMBAI" "METIS_MAINNET" "MONAD_TESTNET" "OPTGOERLI" "OPTMAINNET" "ROOTSTOCK_MAINNET" "ROOTSTOCK_TESTNET" "SCROLL_MAINNET" "SCROLL_SEPOLIA" "SETTLUS_SEPTESTNET" "SHAPE_MAINNET" "SHAPE_SEPOLIA" "SONEIUM_MAINNET" "SONEIUM_MINATO" "SONIC_MAINNET" "SONIC_TESTNET" "STARKNET_GOERLI" "STARKNET_MAINNET" "STARKNET_SEPOLIA" "WORLDCHAIN_MAINNET" "WORLDCHAIN_SEPOLIA" "ZETACHAIN_MAINNET" "ZETACHAIN_TESTNET" "ZKSYNC_MAINNET" "ZKSYNC_SEPOLIA"] }
def webhook-type-completer [] { ["ADDRESS_ACTIVITY" "DROPPED_TRANSACTION" "GRAPHQL" "MINED_TRANSACTION" "NFT_ACTIVITY" "NFT_METADATA_UPDATE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "graphql-variables read-custom-webhook-variable" } } | get name | first)
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

# Read Variable Elements
#
# GET /graphql/variables/{variable}
# operationId: read-custom-webhook-variable
export def "graphql-variables read-custom-webhook-variable" [
  variable: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 100
  --after: string # The cursor that points to the end of the current set of results.
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
]: nothing -> table<data: list<string>, pagination: record<cursors: record, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/variables/($variable)" $qp)
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Variable
#
# POST /graphql/variables/{variable}
# operationId: create-custom-webhook-variable
export def "graphql-variables create-custom-webhook-variable" [
  variable: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
  items: list # A variable defined as a set of addresses or byte32 elements. Must be a non-empty list. (default: [])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/graphql/variables/($variable)")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Variable
#
# DELETE /graphql/variables/{variable}
# operationId: delete-custom-webhook-variable
export def "graphql-variables delete-custom-webhook-variable" [
  variable: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/graphql/variables/($variable)")
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Variable
#
# PATCH /graphql/variables/{variable}
# operationId: update-custom-webhook-variable
export def "graphql-variables update-custom-webhook-variable" [
  variable: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
  --add: list # Set of addresses or byte32 elements to be ADDED to a given Custom Webhook variable (default: [])
  --delete: list # Set of addresses or byte32 elements to be DELETED for a given Custom Webhook variable (default: [])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/graphql/variables/($variable)")
  let body = {add: $add, delete: $delete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all webhooks
#
# GET /team-webhooks
# operationId: team-webhooks
export def "team-webhooks team-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
]: nothing -> table<data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team-webhooks")
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all addresses for an Address Activity webhook
#
# GET /webhook-addresses
# operationId: webhook-addresses
export def "webhook-addresses webhook-addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook-id: string # ID of the address activity webhook.
  --limit: int # default: 100
  --after: string # The cursor that points to the end of the current set of results.
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
]: nothing -> table<data: list<string>, pagination: record<cursors: record, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhook_id" $webhook_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook-addresses" $qp)
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create webhook
#
# POST /create-webhook
# operationId: create-webhook
# --nft_filters item shape: {contract_address?: string, token_id?: string}
# --nft_metadata_filters item shape: {contract_address?: string, token_id?: string}
export def "create-webhook create-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
  network: string@network-completer # Network of webhook (default: ETH_MAINNET)
  webhook_type: string@webhook-type-completer # Type of webhook.
  webhook_url: string # URL where requests are sent
  --graphql-query: any
  --app-id: string # Required for mined and dropped webhooks, optional for address activity or custom webhooks. Learn how to find your app ID [here](https://docs.alchemy.com/reference/notify-api-faq#where-can-i-find-the-app-id).
  --addresses: list # List of addresses you want to track. Required for address activity webhooks only.
  --nft-filters: list # list of nft filter objects to track transfer activity for — item shape: {contract_address?: string, token_id?: string}
  --nft-metadata-filters: list # list of nft metadata filter objects to track metadata updates for — item shape: {contract_address?: string, token_id?: string}
]: any -> record<data: record<id: string, network: string, webhook_type: string, webhook_url: string, is_active: bool, time_created: int, addresses: list<string>, version: string, signing_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/create-webhook")
  let body = {network: $network, webhook_type: $webhook_type, webhook_url: $webhook_url, graphql_query: $graphql_query, app_id: $app_id, addresses: $addresses, nft_filters: $nft_filters, nft_metadata_filters: $nft_metadata_filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add and remove webhook addresses
#
# PATCH /update-webhook-addresses
# operationId: update-webhook-addresses
export def "update-webhook-addresses update-webhook-addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
  webhook_id: string # ID of the address activity webhook
  --addresses-to-add: list # List of addresses to add, **use [] if none**. (default: [])
  --addresses-to-remove: list # List of addresses to remove, **use [] if none**. (default: [])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/update-webhook-addresses")
  let body = {webhook_id: $webhook_id, addresses_to_add: $addresses_to_add, addresses_to_remove: $addresses_to_remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace webhook addresses
#
# PUT /update-webhook-addresses
# operationId: replace-webhook-addresses
export def "update-webhook-addresses replace-webhook-addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
  --webhook-id: string # ID of the address activity webhook.
  --addresses: list # New list of addresses to track. This replaces any existing addresses.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/update-webhook-addresses")
  let body = {webhook_id: $webhook_id, addresses: $addresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update webhook status
#
# PUT /update-webhook
# operationId: update-webhook
export def "update-webhook update-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
  --webhook-id: string # ID of the address activity webhook
  --is-active: string@bool-completer # True - set webhook to active state False - set webhook to inactive state
]: any -> record<data: record<id: string, network: string, webhook_type: string, webhook_url: string, is_active: bool, time_created: int, addresses: list<string>, version: string, signing_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/update-webhook")
  let body = {webhook_id: $webhook_id, is_active: $is_active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update webhook NFT filters
#
# PATCH /update-webhook-nft-filters
# operationId: update-webhook-nft-filters
# --nft_filters_to_add item shape: {contract_address?: string, token_id?: string}
# --nft_filters_to_remove item shape: {contract_address?: string, token_id?: string}
export def "update-webhook-nft-filters update-webhook-nft-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
  webhook_id: string # ID of the address activity webhook
  --nft-filters-to-add: list # List of nft filters to add, use [] if none. (default: []) — item shape: {contract_address?: string, token_id?: string}
  --nft-filters-to-remove: list # List of addresses to remove, use [] if none. (default: []) — item shape: {contract_address?: string, token_id?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/update-webhook-nft-filters")
  let body = {webhook_id: $webhook_id, nft_filters_to_add: $nft_filters_to_add, nft_filters_to_remove: $nft_filters_to_remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update NFT metadata webhook filters
#
# PATCH /update-webhook-nft-metadata-filters
# operationId: update-webhook-nft-metadata-filters
# --nft_metadata_filters_to_add item shape: {contract_address?: string, token_id?: string}
# --nft_metadata_filters_to_remove item shape: {contract_address?: string, token_id?: string}
export def "update-webhook-nft-metadata-filters update-webhook-nft-metadata-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
  webhook_id: string # ID of the address activity webhook
  --nft-metadata-filters-to-add: list # List of nft metadata filters to add, **use [] if none**. — item shape: {contract_address?: string, token_id?: string}
  --nft-metadata-filters-to-remove: list # List of nft metadata filters to remove, **use [] if none**. — item shape: {contract_address?: string, token_id?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/update-webhook-nft-metadata-filters")
  let body = {webhook_id: $webhook_id, nft_metadata_filters_to_add: $nft_metadata_filters_to_add, nft_metadata_filters_to_remove: $nft_metadata_filters_to_remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all webhook NFT filters
#
# GET /webhook-nft-filters
# operationId: webhook-nft-filters
export def "webhook-nft-filters webhook-nft-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook-id: string # ID of the address activity webhook.
  --limit: int # default: 100
  --after: string # The cursor that points to the end of the current set of results.
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
]: nothing -> table<data: list<record>, pagination: record<cursors: record, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhook_id" $webhook_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook-nft-filters" $qp)
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete webhook
#
# DELETE /delete-webhook
# operationId: delete-webhook
export def "delete-webhook delete-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook-id: string # ID of the address activity webhook.
  --X-Alchemy-Token: string # Alchemy Auth token to use the Notify API. (e.g. your-X-Alchemy-Token)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhook_id" $webhook_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/delete-webhook" $qp)
  let extra_headers = {"X-Alchemy-Token": $X_Alchemy_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
