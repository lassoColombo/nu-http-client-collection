# Auto-generated client for EVM API v2.2
# Source: https://deep-index.moralis.io/api-docs-2.2/v2.2/swagger.json
# Auth: --token flag or $env.EVM_API_TOKEN

const BASE_URL = "https://deep-index.moralis.io/api/v2.2"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EVM_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://deep-index.moralis.io/api/v2.2"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def chain-completer [] { ["0x1" "0x106a" "0x13882" "0x14a34" "0x15b32" "0x15b38" "0x171" "0x19" "0x2105" "0x221" "0x27d8" "0x2eb" "0x31769" "0x38" "0x46f" "0x504" "0x505" "0x507" "0x530" "0x531" "0x61" "0x64" "0x7e4" "0x89" "0x8f" "0xa" "0xa4b1" "0xa86a" "0xaa36a7" "0xe705" "0xe708" "arbitrum" "avalanche" "base" "base sepolia" "bsc" "bsc testnet" "chiliz" "chiliz testnet" "cronos" "eth" "flow" "flow-testnet" "gnosis" "gnosis testnet" "linea" "linea sepolia" "lisk" "lisk-sepolia" "monad" "moonbase" "moonbeam" "moonriver" "optimism" "polygon" "polygon amoy" "pulse" "ronin" "ronin-testnet" "sei" "sei-testnet" "sepolia"] }
def format-completer [] { ["decimal" "hex"] }
def order-completer [] { ["ASC" "DESC"] }
def marketplace-completer [] { ["0xprotocol" "blur" "looksrare" "opensea" "x2y2"] }
def flag-completer [] { ["metadata" "uri"] }
def mode-completer [] { ["async" "sync"] }
def timeFrame-completer [] { ["10min" "12h" "1d" "1h" "1m" "1min" "1w" "30min" "4h" "5min"] }
def include-completer [] { ["internal_transactions"] }
def currency-completer [] { ["0x1" "eth"] }
def interval-completer [] { ["1d" "1y" "30d" "60d" "7d" "90d" "all"] }
def sortBy-completer [] { ["liquidityDesc" "marketCapDesc" "volume1hDesc" "volume24hDesc"] }
def timeframe-completer [] { ["10min" "10s" "12h" "1M" "1d" "1h" "1min" "1s" "1w" "30min" "30s" "4h" "5min"] }
def currency-completer-1 [] { ["native" "usd"] }
def timeframe-completer-1 [] { ["1d" "30d" "7d"] }
def chain-completer-1 [] { ["0x1" "0x106a" "0x13882" "0x14a34" "0x15b32" "0x15b38" "0x171" "0x19" "0x2105" "0x221" "0x27d8" "0x2eb" "0x31769" "0x38" "0x46f" "0x504" "0x505" "0x507" "0x530" "0x531" "0x61" "0x64" "0x7e4" "0x89" "0x8f" "0xa" "0xa4b1" "0xa86a" "0xaa36a7" "0xe705" "0xe708" "arbitrum" "avalanche" "base" "base sepolia" "bsc" "bsc testnet" "chiliz" "chiliz testnet" "cronos" "eth" "flow" "flow-testnet" "gnosis" "gnosis testnet" "linea" "linea sepolia" "lisk" "lisk-sepolia" "monad" "moonbase" "moonbeam" "moonriver" "optimism" "polygon" "polygon amoy" "pulse" "ronin" "ronin-testnet" "sei" "sei-testnet" "sepolia" "solana"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "nft get-by-address" } } | get name | first)
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

# Get NFTs by wallet address
#
# GET /{address}/nft
# operationId: getWalletNFTs
export def "nft get-by-address" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --format: string@format-completer # The format of the token ID (default: decimal, e.g. decimal)
  --limit: int # The desired page size of the result.
  --exclude-spam: string@bool-completer # Should spam NFTs be excluded from the result? (default: false)
  --token-addresses: list # The addresses to get balances for (optional)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --normalizeMetadata: string@bool-completer # Should normalized metadata be returned? (default: true)
  --media-items: string@bool-completer # Should preview media data be returned? (default: false)
  --include-prices: string@bool-completer # Should NFT last sale prices be included in the result? (default: false)
]: nothing -> record<status: string, page: int, page_size: int, cursor: string, result: table<token_address: string, token_id: string, contract_type: string, owner_of: string, block_number: string, block_number_minted: string, token_uri: string, metadata: string, normalized_metadata: record, media: record, amount: string, name: string, symbol: string, token_hash: string, rarity_rank: float, rarity_percentage: float, rarity_label: string, last_token_uri_sync: string, last_metadata_sync: string, possible_spam: bool, verified_collection: bool, floor_price: string, floor_price_usd: string, floor_price_currency: string, last_sale: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "exclude_spam" $exclude_spam "scalar") (serialize-qp "token_addresses" $token_addresses "multi") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "normalizeMetadata" $normalizeMetadata "scalar") (serialize-qp "media_items" $media_items "scalar") (serialize-qp "include_prices" $include_prices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($address)/nft" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Metadata for NFTs
#
# POST /nft/getMultipleNFTs
# operationId: getMultipleNFTs
# --tokens item shape: {token_address?: string, token_id?: string}
export def "nft-get-multiple-nf-ts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  tokens: list # The tokens to be fetched (max 25 tokens) (e.g. [{token_address: 0xa4991609c508b6d4fb7156426db0bd49fe298bd8, token_id: 12}, {token_address: 0x3c64dc415ebb4690d1df2b6216148c8de6dd29f7, token_id: 1}, {token_address: 0x3c64dc415ebb4690d1df2b6216148c8de6dd29f7, token_id: 200}]) — item shape: {token_address?: string, token_id?: string}
  --normalizeMetadata: string@bool-completer # Should normalized metadata be returned? (e.g. false)
  --media-items: string@bool-completer # Should preview media data be returned? (e.g. false)
]: any -> table<token_address: string, token_id: string, contract_type: string, owner_of: string, block_number: string, block_number_minted: string, token_uri: string, metadata: string, normalized_metadata: record<name: string, description: string, image: string, external_link: string, external_url: string, animation_url: string, attributes: list>, media: record<mimetype: string, category: any, status: any, original_media_url: string, updatedAt: string, parent_hash: string, media_collection: record>, amount: string, name: string, symbol: string, token_hash: string, rarity_rank: float, rarity_percentage: float, rarity_label: string, last_token_uri_sync: string, last_metadata_sync: string, possible_spam: bool, verified_collection: bool, floor_price: string, floor_price_usd: string, floor_price_currency: string, last_sale: record<transaction_hash: string, block_timestamp: string, buyer_address: string, seller_address: string, price: string, price_formatted: string, usd_price_at_sale: string, current_usd_value: string, token_address: string, token_id: string, payment_token: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nft/getMultipleNFTs" $qp)
  let body = {tokens: $tokens, normalizeMetadata: $normalizeMetadata, media_items: $media_items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get NFT Transfers by wallet address
#
# GET /{address}/nft/transfers
# operationId: getWalletNFTTransfers
export def "nft-transfers get-by-address" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --contract-addresses: list # List of contract addresses of transfers
  --format: string@format-completer # The format of the token ID (default: decimal, e.g. decimal)
  --from-block: int # The minimum block number from which to get the transfers * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-block: string # To get the reserves at this block number
  --from-date: string # The date from where to get the transfers (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-date: string # Get transfers up until this date (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --include-prices: string@bool-completer # Should NFT last sale prices be included in the result? (default: false)
  --limit: int # The desired page size of the result.
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<token_address: string, token_id: string, token_name: string, token_symbol: string, from_address_entity: string, from_address_entity_logo: string, from_address: string, from_address_label: string, to_address_entity: string, to_address_entity_logo: string, to_address: string, to_address_label: string, value: string, amount: string, contract_type: string, block_number: string, block_timestamp: string, block_hash: string, transaction_hash: string, transaction_type: string, transaction_index: int, log_index: int, operator: string, possible_spam: bool, verified_collection: bool, last_sale: record>, block_exists: bool, index_complete: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "contract_addresses" $contract_addresses "multi") (serialize-qp "format" $format "scalar") (serialize-qp "from_block" $from_block "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "include_prices" $include_prices "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($address)/nft/transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT collections by wallet address
#
# GET /{address}/nft/collections
# operationId: getWalletNFTCollections
export def "nft-collections get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --include-prices: string@bool-completer # Should NFT last sale prices be included in the result? (default: false)
  --limit: int # The desired page size of the result.
  --exclude-spam: string@bool-completer # Should spam NFTs be excluded from the result? (default: false)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --token-counts: string@bool-completer # Should token counts per collection be included in the response? (default: false)
]: nothing -> record<status: string, page: int, page_size: int, cursor: string, result: table<token_address: string, contract_type: string, name: string, symbol: string, possible_spam: bool, verified_collection: bool, count: int, collection_logo: string, collection_banner_image: string, floor_price: string, floor_price_usd: string, floor_price_currency: string, last_sale: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "include_prices" $include_prices "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "exclude_spam" $exclude_spam "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "token_counts" $token_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($address)/nft/collections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFTs by contract address
#
# GET /nft/{address}
# operationId: getContractNFTs
export def "nft get-by-address-1" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --format: string@format-completer # The format of the token ID (default: decimal, e.g. decimal)
  --limit: int # The desired page size of the result.
  --totalRanges: int # The number of subranges to split the results into
  --range: int # The desired subrange to query
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --normalizeMetadata: string@bool-completer # Should normalized metadata be returned? (default: true)
  --media-items: string@bool-completer # Should preview media data be returned? (default: false)
  --include-prices: string@bool-completer # Should NFT last sale prices be included in the result? (default: false)
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<token_address: string, token_id: string, owner_of: string, token_hash: string, block_number: string, block_number_minted: string, contract_type: string, token_uri: string, metadata: string, normalized_metadata: record, media: record, minter_address: string, last_token_uri_sync: string, last_metadata_sync: string, amount: string, name: string, symbol: string, possible_spam: bool, verified_collection: bool, rarity_rank: float, rarity_percentage: float, rarity_label: string, last_sale: record, list_price: record, floor_price: string, floor_price_usd: string, floor_price_currency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "totalRanges" $totalRanges "scalar") (serialize-qp "range" $range "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "normalizeMetadata" $normalizeMetadata "scalar") (serialize-qp "media_items" $media_items "scalar") (serialize-qp "include_prices" $include_prices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get unique wallet addresses owning NFTs from a contract.
#
# GET /nft/{address}/unique-owners
# operationId: getUniqueOwnersByCollection
export def "nft-unique-owners get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --limit: int # The desired page size of the result.
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
]: nothing -> record<page: int, pageSize: int, cursor: string, walletAddresses: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/unique-owners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT owners by contract address
#
# GET /nft/{address}/owners
# operationId: getNFTOwners
export def "nft-owners list" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --format: string@format-completer # The format of the token ID (default: decimal, e.g. decimal)
  --limit: int # The desired page size of the result.
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --normalizeMetadata: string@bool-completer # Should normalized metadata be returned? (default: false)
  --media-items: string@bool-completer # Should preview media data be returned? (default: false)
]: nothing -> record<status: string, page: int, page_size: int, cursor: string, result: table<token_address: string, token_id: string, contract_type: string, owner_of: string, block_number: string, block_number_minted: string, token_uri: string, metadata: string, normalized_metadata: record, media: record, amount: string, name: string, symbol: string, token_hash: string, rarity_rank: float, rarity_percentage: float, rarity_label: string, last_token_uri_sync: string, last_metadata_sync: string, possible_spam: bool, verified_collection: bool, floor_price: string, floor_price_usd: string, floor_price_currency: string, last_sale: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "normalizeMetadata" $normalizeMetadata "scalar") (serialize-qp "media_items" $media_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/owners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT transfers by contract address
#
# GET /nft/{address}/transfers
# operationId: getNFTContractTransfers
export def "nft-transfers get-by-address-1" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --from-block: int # The minimum block number from where to get the transfers * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-block: int # The maximum block number from where to get the transfers. * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --from-date: string # The date from where to get the transfers (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-date: string # Get transfers up until this date (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --format: string@format-completer # The format of the token ID (default: decimal, e.g. decimal)
  --include-prices: string@bool-completer # Should NFT last sale prices be included in the result? (default: false)
  --limit: int # The desired page size of the result.
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<token_address: string, token_id: string, token_name: string, token_symbol: string, from_address_entity: string, from_address_entity_logo: string, from_address: string, from_address_label: string, to_address_entity: string, to_address_entity_logo: string, to_address: string, to_address_label: string, value: string, amount: string, contract_type: string, block_number: string, block_timestamp: string, block_hash: string, transaction_hash: string, transaction_type: string, transaction_index: int, log_index: int, operator: string, possible_spam: bool, verified_collection: bool, last_sale: record>, block_exists: bool, index_complete: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "from_block" $from_block "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "include_prices" $include_prices "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFTs by traits
#
# POST /nft/{address}/nfts-by-traits
# operationId: getNFTByContractTraits
export def "nft-nfts-by-traits post" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --limit: int # The desired page size of the result. (default: 100)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --format: string@format-completer # The format of the token ID (default: decimal, e.g. decimal)
  --normalizeMetadata: string@bool-completer # Should normalized metadata be returned? (default: false)
  --media-items: string@bool-completer # Should preview media data be returned? (default: false)
  traits: record
]: any -> record<page: int, page_size: int, cursor: string, result: table<token_address: string, token_id: string, owner_of: string, token_hash: string, block_number: string, block_number_minted: string, contract_type: string, token_uri: string, metadata: string, normalized_metadata: record, media: record, minter_address: string, last_token_uri_sync: string, last_metadata_sync: string, amount: string, name: string, symbol: string, possible_spam: bool, verified_collection: bool, rarity_rank: float, rarity_percentage: float, rarity_label: string, last_sale: record, list_price: record, floor_price: string, floor_price_usd: string, floor_price_currency: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "normalizeMetadata" $normalizeMetadata "scalar") (serialize-qp "media_items" $media_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/nfts-by-traits" $qp)
  let body = {traits: $traits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get NFT traits by collection
#
# GET /nft/{address}/traits
# operationId: getNFTTraitsByCollection
export def "nft-traits get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<traits: table<trait_type: string, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/traits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT traits by collection paginate
#
# GET /nft/{address}/traits/paginate
# operationId: getNFTTraitsByCollectionPaginate
export def "nft-traits-paginate get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --limit: int # The desired page size of the result.
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<trait_type: string, trait_value: string, count: float, percentage: float, rarity_label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/traits/paginate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resync NFT Trait
#
# GET /nft/{address}/traits/resync
# operationId: resyncNFTRarity
export def "nft-traits-resync resyncNFTRarity" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/traits/resync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT trades by collection
#
# GET /nft/{address}/trades
# operationId: getNFTTrades
export def "nft-trades list" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --from-block: int # The minimum block number from which to get the transfers * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-block: string # The block number to get the trades from
  --from-date: string # The start date from which to get the transfers (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-date: string # The end date from which to get the transfers (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --marketplace: string@marketplace-completer # Marketplace from which to get the trades. See [supported Marketplaces](https://docs.moralis.io/web3-data-api/evm/nft-marketplaces). (default: opensea, e.g. opensea)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --limit: int # The desired page size of the result.
  --nft-metadata: string@bool-completer # Include the NFT Metadata of the NFT Token (default: true)
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<transaction_hash: string, transaction_index: string, token_ids: list, seller_address: string, buyer_address: string, token_address: string, marketplace_address: string, price_token_address: string, price: string, block_timestamp: string, block_number: string, block_hash: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "from_block" $from_block "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "marketplace" $marketplace "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nft_metadata" $nft_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/trades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT trades by token
#
# GET /nft/{address}/{token_id}/trades
# operationId: getNFTTradesByToken
export def "nft-trades get" [
  address: string
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --from-block: int # The minimum block number from which to get the transfers * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-block: string # The block number to get the trades from
  --from-date: string # The start date from which to get the transfers (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-date: string # The end date from which to get the transfers (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --limit: int # The desired page size of the result.
  --nft-metadata: string@bool-completer # Include the NFT Metadata of the NFT Token (default: true)
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<transaction_hash: string, transaction_index: string, token_ids: list, seller_address: string, buyer_address: string, token_address: string, marketplace_address: string, price_token_address: string, price: string, block_timestamp: string, block_number: string, block_hash: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "from_block" $from_block "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nft_metadata" $nft_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/($token_id)/trades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT trades by wallet address
#
# GET /wallets/{address}/nfts/trades
# operationId: getNFTTradesByWallet
export def "wallets-nfts-trades get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --from-block: int # The minimum block number from which to get the transfers * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-block: string # The block number to get the trades from
  --from-date: string # The start date from which to get the transfers (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-date: string # The end date from which to get the transfers (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --limit: int # The desired page size of the result.
  --nft-metadata: string@bool-completer # Include the NFT Metadata of the NFT Token (default: true)
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<transaction_hash: string, transaction_index: string, token_ids: list, seller_address: string, buyer_address: string, token_address: string, marketplace_address: string, price_token_address: string, price: string, block_timestamp: string, block_number: string, block_hash: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "from_block" $from_block "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nft_metadata" $nft_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/nfts/trades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT collection metadata
#
# GET /nft/{address}/metadata
# operationId: getNFTContractMetadata
export def "nft-metadata get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --include-prices: string@bool-completer # Should NFT last sale prices be included in the result? (default: false)
]: nothing -> record<token_address: string, name: string, synced_at: string, symbol: string, contract_type: string, possible_spam: bool, verified_collection: bool, collection_logo: string, collection_banner_image: string, collection_category: string, project_url: string, wiki_url: string, discord_url: string, telegram_url: string, twitter_username: string, instagram_username: string, floor_price: string, floor_price_usd: string, floor_price_currency: string, last_sale: record<transaction_hash: string, block_timestamp: string, buyer_address: string, seller_address: string, price: string, price_formatted: string, usd_price_at_sale: string, current_usd_value: string, token_address: string, token_id: string, payment_token: record<token_name: string, token_symbol: string, token_logo: string, token_decimals: string, token_address: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "include_prices" $include_prices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metadata for multiple NFT contracts
#
# POST /nft/metadata
# operationId: getNFTBulkContractMetadata
export def "nft-metadata post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --include-prices: string@bool-completer # Should NFT last sale prices be included in the result? (default: false)
  addresses: list
]: any -> table<token_address: string, name: string, synced_at: string, symbol: string, contract_type: string, possible_spam: bool, verified_collection: bool, collection_logo: string, collection_banner_image: string, collection_category: string, project_url: string, wiki_url: string, discord_url: string, telegram_url: string, twitter_username: string, instagram_username: string, floor_price: string, floor_price_usd: string, floor_price_currency: string, last_sale: record<transaction_hash: string, block_timestamp: string, buyer_address: string, seller_address: string, price: string, price_formatted: string, usd_price_at_sale: string, current_usd_value: string, token_address: string, token_id: string, payment_token: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "include_prices" $include_prices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nft/metadata" $qp)
  let body = {addresses: $addresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get NFT metadata
#
# GET /nft/{address}/{token_id}
# operationId: getNFTMetadata
export def "nft get-by-address-token_id" [
  address: string
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --format: string@format-completer # The format of the token ID (default: decimal, e.g. decimal)
  --normalizeMetadata: string@bool-completer # Should normalized metadata be returned? (default: true)
  --media-items: string@bool-completer # Should preview media data be returned? (default: false)
  --include-prices: string@bool-completer # Should NFT last sale prices be included in the result? (default: false)
]: nothing -> record<token_address: string, token_id: string, owner_of: string, token_hash: string, block_number: string, block_number_minted: string, contract_type: string, token_uri: string, metadata: string, normalized_metadata: record<name: string, description: string, image: string, external_link: string, external_url: string, animation_url: string, attributes: list<record>>, media: record<mimetype: string, category: any, status: any, original_media_url: string, updatedAt: string, parent_hash: string, media_collection: record<low: record, medium: record, high: record>>, minter_address: string, last_token_uri_sync: string, last_metadata_sync: string, amount: string, name: string, symbol: string, possible_spam: bool, verified_collection: bool, rarity_rank: float, rarity_percentage: float, rarity_label: string, last_sale: record<transaction_hash: string, block_timestamp: string, buyer_address: string, seller_address: string, price: string, price_formatted: string, usd_price_at_sale: string, current_usd_value: string, token_address: string, token_id: string, payment_token: record<token_name: string, token_symbol: string, token_logo: string, token_decimals: string, token_address: string>>, list_price: record<listed: bool, price: string, price_currency: string, price_usd: string, marketplace: string>, floor_price: string, floor_price_usd: string, floor_price_currency: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "normalizeMetadata" $normalizeMetadata "scalar") (serialize-qp "media_items" $media_items "scalar") (serialize-qp "include_prices" $include_prices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/($token_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT transfers by token ID
#
# GET /nft/{address}/{token_id}/transfers
# operationId: getNFTTransfers
export def "nft-transfers get-by-address-token_id" [
  address: string
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --format: string@format-completer # The format of the token ID (default: decimal, e.g. decimal)
  --include-prices: string@bool-completer # Should NFT last sale prices be included in the result? (default: false)
  --limit: int # The desired page size of the result.
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<token_address: string, token_id: string, token_name: string, token_symbol: string, from_address_entity: string, from_address_entity_logo: string, from_address: string, from_address_label: string, to_address_entity: string, to_address_entity_logo: string, to_address: string, to_address_label: string, value: string, amount: string, contract_type: string, block_number: string, block_timestamp: string, block_hash: string, transaction_hash: string, transaction_type: string, transaction_index: int, log_index: int, operator: string, possible_spam: bool, verified_collection: bool, last_sale: record>, block_exists: bool, index_complete: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "include_prices" $include_prices "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/($token_id)/transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT owners by token ID
#
# GET /nft/{address}/{token_id}/owners
# operationId: getNFTTokenIdOwners
export def "nft-owners get" [
  address: string
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --format: string@format-completer # The format of the token ID (default: decimal, e.g. decimal)
  --limit: int # The desired page size of the result.
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --normalizeMetadata: string@bool-completer # Should normalized metadata be returned? (default: false)
  --media-items: string@bool-completer # Should preview media data be returned? (default: false)
]: nothing -> record<status: string, page: int, page_size: int, cursor: string, result: table<token_address: string, token_id: string, contract_type: string, owner_of: string, block_number: string, block_number_minted: string, token_uri: string, metadata: string, normalized_metadata: record, media: record, amount: string, name: string, symbol: string, token_hash: string, rarity_rank: float, rarity_percentage: float, rarity_label: string, last_token_uri_sync: string, last_metadata_sync: string, possible_spam: bool, verified_collection: bool, floor_price: string, floor_price_usd: string, floor_price_currency: string, last_sale: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "normalizeMetadata" $normalizeMetadata "scalar") (serialize-qp "media_items" $media_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/($token_id)/owners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resync NFT Contract
#
# PUT /nft/{address}/sync
# operationId: syncNFTContract
export def "nft-sync syncNFTContract" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resync NFT metadata
#
# GET /nft/{address}/{token_id}/metadata/resync
# operationId: reSyncMetadata
export def "nft-metadata-resync reSyncMetadata" [
  address: string
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --flag: string@flag-completer # The type of resync to operate (default: uri, e.g. uri)
  --mode: string@mode-completer # To define the behaviour of the endpoint (default: async, e.g. sync)
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "flag" $flag "scalar") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/($token_id)/metadata/resync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT sale prices by collection
#
# GET /nft/{address}/price
# operationId: getNFTContractSalePrices
export def "nft-price list" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --days: int # The number of days to look back to find the lowest price If not provided 7 days will be the default and 365 is the maximum
]: nothing -> record<last_sale: record<transaction_hash: string, block_timestamp: string, buyer_address: string, seller_address: string, price: string, price_formatted: string, usd_price_at_sale: string, current_usd_value: string, token_id: string, payment_token: record<token_name: string, token_symbol: string, token_logo: string, token_decimals: string, token_address: string>>, lowest_sale: record<transaction_hash: string, block_timestamp: string, buyer_address: string, seller_address: string, price: string, price_formatted: string, usd_price_at_sale: string, current_usd_value: string, token_id: string, payment_token: record<token_name: string, token_symbol: string, token_logo: string, token_decimals: string, token_address: string>>, highest_sale: record<transaction_hash: string, block_timestamp: string, buyer_address: string, seller_address: string, price: string, price_formatted: string, usd_price_at_sale: string, current_usd_value: string, token_id: string, payment_token: record<token_name: string, token_symbol: string, token_logo: string, token_decimals: string, token_address: string>>, average_sale: record<price: string, price_formatted: string, current_usd_value: string>, total_trades: float, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "days" $days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT sale prices by token
#
# GET /nft/{address}/{token_id}/price
# operationId: getNFTSalePrices
export def "nft-price get" [
  address: string
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --days: int # The number of days to look back to find the lowest price If not provided 7 days will be the default and 365 is the maximum
]: nothing -> record<last_sale: record<transaction_hash: string, block_timestamp: string, buyer_address: string, seller_address: string, price: string, price_formatted: string, usd_price_at_sale: string, current_usd_value: string, token_id: string, payment_token: record<token_name: string, token_symbol: string, token_logo: string, token_decimals: string, token_address: string>>, lowest_sale: record<transaction_hash: string, block_timestamp: string, buyer_address: string, seller_address: string, price: string, price_formatted: string, usd_price_at_sale: string, current_usd_value: string, token_id: string, payment_token: record<token_name: string, token_symbol: string, token_logo: string, token_decimals: string, token_address: string>>, highest_sale: record<transaction_hash: string, block_timestamp: string, buyer_address: string, seller_address: string, price: string, price_formatted: string, usd_price_at_sale: string, current_usd_value: string, token_id: string, payment_token: record<token_name: string, token_symbol: string, token_logo: string, token_decimals: string, token_address: string>>, average_sale: record<price: string, price_formatted: string, current_usd_value: string>, total_trades: float, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "days" $days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/($token_id)/price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ERC20 token price
#
# GET /erc20/{address}/price
# operationId: getTokenPrice
export def "erc20-price get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --exchange: string # The factory name or address of the token exchange
  --to-block: int # The block number from which the token price should be checked
  --max-token-inactivity: float # Exclude tokens inactive for more than the given amount of days
  --min-pair-side-liquidity-usd: float # Exclude tokens with liquidity less than the specified amount in USD. This parameter refers to the liquidity on a single side of the pair.
]: nothing -> record<tokenName: string, tokenSymbol: string, tokenLogo: string, tokenDecimals: string, nativePrice: record<value: string, decimals: int, name: string, symbol: string, address: string>, usdPrice: float, usdPriceFormatted: string, 24hrPercentChange: string, exchangeAddress: string, exchangeName: string, tokenAddress: string, toBlock: string, possibleSpam: bool, verifiedContract: bool, pairAddress: string, pairTotalLiquidityUsd: string, usdPrice24h: float, usdPrice24hrUsdChange: float, usdPrice24hrPercentChange: float, securityScore: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "exchange" $exchange "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "max_token_inactivity" $max_token_inactivity "scalar") (serialize-qp "min_pair_side_liquidity_usd" $min_pair_side_liquidity_usd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/erc20/($address)/price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get swap transactions by token address
#
# GET /erc20/{address}/swaps
# operationId: getSwapsByTokenAddress
export def "erc20-swaps get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --limit: int # The desired page size of the result.
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
  --fromBlock: int # The minimum block number from which to get the token transactions * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --toBlock: string # The block number to get the token transactions from
  --fromDate: string # The start date from which to get the token transactions (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --toDate: string # The end date from which to get the token transactions (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --transactionTypes: string # Array of transaction types. Allowed values are 'buy', 'sell'.
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<transactionHash: string, transactionIndex: int, transactionType: string, blockTimestamp: string, blockNumber: float, subCategory: string, walletAddress: string, walletAddressLabel: string, entity: string, entityLogo: string, pairAddress: string, pairLabel: string, exchangeAddress: string, exchangeName: string, exchangeLogo: string, bought: record, sold: record, baseQuotePrice: string, totalValueUsd: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "fromBlock" $fromBlock "scalar") (serialize-qp "toBlock" $toBlock "scalar") (serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "transactionTypes" $transactionTypes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/erc20/($address)/swaps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a holders summary by token address
#
# GET /erc20/{tokenAddress}/holders
# operationId: getTokenHolders
export def "erc20-holders get" [
  tokenAddress: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<totalHolders: float, holderSupply: record<top10: record<supply: string, supplyPercent: float>, top25: record<supply: string, supplyPercent: float>, top50: record<supply: string, supplyPercent: float>, top100: record<supply: string, supplyPercent: float>, top250: record<supply: string, supplyPercent: float>, top500: record<supply: string, supplyPercent: float>>, holderChange: record<5min: record<change: float, changePercent: float>, 1h: record<change: float, changePercent: float>, 6h: record<change: float, changePercent: float>, 24h: record<change: float, changePercent: float>, 3d: record<change: float, changePercent: float>, 7d: record<change: float, changePercent: float>, 30d: record<change: float, changePercent: float>>, holdersByAcquisition: record<swap: float, transfer: float, airdrop: float>, holderDistribution: record<whales: int, sharks: int, dolphins: int, fish: int, octopus: int, crabs: int, shrimps: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/erc20/($tokenAddress)/holders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get timeseries holders data
#
# GET /erc20/{tokenAddress}/holders/historical
# operationId: getHistoricalTokenHolders
export def "erc20-holders-historical get" [
  tokenAddress: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --fromDate: string # The starting date (format in seconds or datestring accepted by momentjs)  (e.g. 2025-01-01T10:00:00)
  --toDate: string # The ending date (format in seconds or datestring accepted by momentjs)  (e.g. 2025-02-01T11:00:00)
  --limit: int # The number of results to return
  --cursor: string # The cursor returned in the previous response (used for getting the next page)
  --timeFrame: string@timeFrame-completer # The time frame to group the data by (default: 1min, e.g. 1d)
]: nothing -> record<page: int, pageSize: int, cursor: string, result: table<timestamp: string, totalHolders: int, netHolderChange: int, holderPercentChange: int, newHoldersByAcquisition: record, holdersIn: record, holdersOut: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "timeFrame" $timeFrame "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/erc20/($tokenAddress)/holders/historical" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Multiple ERC20 token prices
#
# POST /erc20/prices
# operationId: getMultipleTokenPrices
# --tokens item shape: {token_address: string, exchange?: string, to_block?: string}
export def "erc20-prices post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --max-token-inactivity: float # Exclude tokens inactive for more than the given amount of days
  --min-pair-side-liquidity-usd: float # Exclude tokens with liquidity less than the specified amount in USD. This parameter refers to the liquidity on a single side of the pair.
  tokens: list # The tokens to be fetched (e.g. [{token_address: 0xdac17f958d2ee523a2206206994597c13d831ec7}, {token_address: 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48}, {token_address: 0xae7ab96520de3a18e5e111b5eaab095312d7fe84, exchange: uniswapv2, to_block: 16314545}, {token_address: 0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0}]) — item shape: {token_address: string, exchange?: string, to_block?: string}
]: any -> table<tokenName: string, tokenSymbol: string, tokenLogo: string, tokenDecimals: string, nativePrice: record<value: string, decimals: int, name: string, symbol: string, address: string>, usdPrice: float, usdPriceFormatted: string, 24hrPercentChange: string, exchangeAddress: string, exchangeName: string, tokenAddress: string, toBlock: string, possibleSpam: bool, verifiedContract: bool, pairAddress: string, pairTotalLiquidityUsd: string, usdPrice24h: float, usdPrice24hrUsdChange: float, usdPrice24hrPercentChange: float, securityScore: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "max_token_inactivity" $max_token_inactivity "scalar") (serialize-qp "min_pair_side_liquidity_usd" $min_pair_side_liquidity_usd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/erc20/prices" $qp)
  let body = {tokens: $tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get ERC20 token owners by contract
#
# GET /erc20/{token_address}/owners
# operationId: getTokenOwners
export def "erc20-owners get" [
  token_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --limit: int # The desired page size of the result.
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
]: nothing -> record<page: int, page_size: int, cursor: string, total_supply: string, result: table<owner_address: string, owner_address_label: string, balance: string, balance_formatted: string, usd_value: string, is_contract: bool, percentage_relative_to_total_supply: float, entity: string, entity_logo: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/erc20/($token_address)/owners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ERC20 token balances by wallet
#
# GET /{address}/erc20
# operationId: getWalletTokenBalances
export def "erc20 get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --to-block: float # The block number up to which the balances will be checked.
  --token-addresses: list # The addresses to get balances for (optional)
  --exclude-spam: string@bool-completer # Exclude spam tokens from the result (default: true)
]: nothing -> table<token_address: string, name: string, symbol: string, logo: string, thumbnail: string, decimals: int, balance: string, possible_spam: bool, verified_contract: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "token_addresses" $token_addresses "multi") (serialize-qp "exclude_spam" $exclude_spam "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($address)/erc20" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ERC20 token transfers by wallet address
#
# GET /{address}/erc20/transfers
# operationId: getWalletTokenTransfers
export def "erc20-transfers get-by-address" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --from-block: int # The minimum block number from which to get the transactions * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-block: int # The maximum block number from which to get the transactions. * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --from-date: string # The start date from which to get the transactions (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-date: string # Get the transactions up to this date (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --contract-addresses: list # List of contract addresses of transfers
  --limit: int # The desired page size of the result.
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<token_name: string, token_symbol: string, token_logo: string, token_decimals: string, transaction_hash: string, address: string, block_timestamp: string, block_number: string, block_hash: string, to_address_entity: string, to_address_entity_logo: string, to_address: string, to_address_label: string, from_address_entity: string, from_address_entity_logo: string, from_address: string, from_address_label: string, value: string, transaction_index: int, log_index: int, possible_spam: bool, verified_contract: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "from_block" $from_block "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "contract_addresses" $contract_addresses "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($address)/erc20/transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ERC20 token metadata by contract
#
# GET /erc20/metadata
# operationId: getTokenMetadata
export def "erc20-metadata get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --addresses: list # The addresses to get metadata for
]: nothing -> table<address: string, address_label: string, name: string, symbol: string, decimals: string, logo: string, logo_hash: string, thumbnail: string, total_supply: string, total_supply_formatted: string, implementations: list<record>, fully_diluted_valuation: string, block_number: string, validated: float, created_at: string, possible_spam: bool, verified_contract: bool, categories: list<string>, links: record<bitbucket: string, discord: string, facebook: string, github: string, instagram: string, linkedin: string, medium: string, reddit: string, telegram: string, tiktok: string, twitter: string, website: string, youtube: string>, circulating_supply: string, market_cap: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "addresses" $addresses "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/erc20/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ERC20 token categories
#
# GET /tokens/categories
# operationId: getTokenCategories
export def "tokens-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<categories: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ERC20 token transfers by contract address
#
# GET /erc20/{address}/transfers
# operationId: getTokenTransfers
export def "erc20-transfers get-by-address-1" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --from-block: int # The minimum block number from which to get the transfers * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-block: int # The maximum block number from which to get the transfers. * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --from-date: string # The start date from which to get the transfers (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-date: string # Get transfers up until this date (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --limit: int # The desired page size of the result.
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<token_name: string, token_symbol: string, token_logo: string, token_decimals: string, transaction_hash: string, address: string, block_timestamp: string, block_number: string, block_hash: string, to_address_entity: string, to_address_entity_logo: string, to_address: string, to_address_label: string, from_address_entity: string, from_address_entity_logo: string, from_address: string, from_address_label: string, value: string, transaction_index: int, log_index: int, possible_spam: bool, verified_contract: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "from_block" $from_block "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/erc20/($address)/transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get native balance by wallet
#
# GET /{address}/balance
# operationId: getNativeBalance
export def "balance get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --to-block: float # The block number up to which the balances will be checked.
]: nothing -> record<balance: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "to_block" $to_block "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($address)/balance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get native balance for a set of wallets
#
# GET /wallets/balances
# operationId: getNativeBalancesForAddresses
export def "wallets-balances get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --to-block: float # The block number on which the balances should be checked
  --wallet-addresses: list # The addresses to get metadata for
]: nothing -> table<chain: string, chain_id: string, total_balance: string, block_number: string, block_timestamp: string, total_balance_formatted: string, wallet_balances: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "wallet_addresses" $wallet_addresses "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/wallets/balances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ERC20 approvals by wallet
#
# GET /wallets/{address}/approvals
# operationId: getWalletApprovals
export def "wallets-approvals get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --limit: int # The desired page size of the result.
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<block_number: string, block_timestamp: string, transaction_hash: string, value: string, value_formatted: string, token: record, spender: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/approvals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the complete decoded transaction history of a wallet
#
# GET /wallets/{address}/history
# operationId: getWalletHistory
export def "wallets-history get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --from-block: int # The minimum block number from which to get the transactions * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-block: int # The maximum block number from which to get the transactions. * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --from-date: string # The start date from which to get the transactions (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-date: string # Get the transactions up to this date (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --include-internal-transactions: string@bool-completer # If the result should contain the internal transactions.
  --nft-metadata: string@bool-completer # If the result should contain the nft metadata.
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
  --limit: int # The desired page size of the result.
]: nothing -> record<synced_at: int, page: int, page_size: int, cursor: string, result: table<hash: string, nonce: string, transaction_index: string, from_address_entity: string, from_address_entity_logo: string, from_address: string, from_address_label: string, to_address_entity: string, to_address_entity_logo: string, to_address: string, to_address_label: string, value: string, gas: string, gas_price: string, input: string, receipt_cumulative_gas_used: string, receipt_gas_used: string, receipt_contract_address: string, receipt_status: string, transaction_fee: string, block_timestamp: string, block_number: string, block_hash: string, internal_transactions: list, category: string, contract_interactions: any, possible_spam: bool, method_label: string, summary: string, nft_transfers: list, erc20_transfers: list, native_transfers: list, logs: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "from_block" $from_block "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "include_internal_transactions" $include_internal_transactions "scalar") (serialize-qp "nft_metadata" $nft_metadata "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get token balances with prices by wallet address
#
# GET /wallets/{address}/tokens
# operationId: getWalletTokenBalancesPrice
export def "wallets-tokens get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --to-block: float # The block number up to which the balances will be checked.
  --token-addresses: list # The addresses to get balances for (optional)
  --exclude-spam: string@bool-completer # Exclude spam tokens from the result (default: false)
  --exclude-unverified-contracts: string@bool-completer # Exclude unverified contracts from the result (default: false)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --limit: int # The desired page size of the result.
  --exclude-native: string@bool-completer # Exclude native balance from the result (default: false)
  --max-token-inactivity: float # Exclude tokens inactive for more than the given amount of days
  --min-pair-side-liquidity-usd: float # Exclude tokens with liquidity less than the specified amount in USD. This parameter refers to the liquidity on a single side of the pair.
]: nothing -> record<page: int, page_size: int, block_number: string, cursor: string, result: table<token_address: string, name: string, symbol: string, logo: string, thumbnail: string, decimals: int, balance: string, possible_spam: bool, verified_contract: bool, usd_price: string, usd_price_24hr_percent_change: string, usd_price_24hr_usd_change: string, usd_value_24hr_usd_change: string, usd_value: float, portfolio_percentage: float, balance_formatted: string, native_token: bool, total_supply: string, total_supply_formatted: string, percentage_relative_to_total_supply: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "token_addresses" $token_addresses "multi") (serialize-qp "exclude_spam" $exclude_spam "scalar") (serialize-qp "exclude_unverified_contracts" $exclude_unverified_contracts "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "exclude_native" $exclude_native "scalar") (serialize-qp "max_token_inactivity" $max_token_inactivity "scalar") (serialize-qp "min_pair_side_liquidity_usd" $min_pair_side_liquidity_usd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get wallet net worth
#
# GET /wallets/{address}/net-worth
# operationId: getWalletNetWorth
export def "wallets-net-worth get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chains: list # The chains to query
  --exclude-spam: string@bool-completer # Exclude spam tokens from the result (default: false, e.g. true)
  --exclude-unverified-contracts: string@bool-completer # Exclude unverified contracts from the result (default: false, e.g. true)
  --max-token-inactivity: float # Exclude tokens inactive for more than the given amount of days (e.g. 1)
  --min-pair-side-liquidity-usd: float # Exclude tokens with liquidity less than the specified amount in USD. This parameter refers to the liquidity on a single side of the pair. (e.g. 1000)
]: nothing -> record<total_networth_usd: string, chains: table<chain: string, native_balance: string, native_balance_formatted: string, native_balance_usd: string, token_balance_usd: string, networth_usd: string>, unsupported_chain_ids: list<string>, unavailable_chains: table<chain_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chains" $chains "multi") (serialize-qp "exclude_spam" $exclude_spam "scalar") (serialize-qp "exclude_unverified_contracts" $exclude_unverified_contracts "scalar") (serialize-qp "max_token_inactivity" $max_token_inactivity "scalar") (serialize-qp "min_pair_side_liquidity_usd" $min_pair_side_liquidity_usd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/net-worth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get native transactions by wallet
#
# GET /{address}
# operationId: getWalletTransactions
export def "transaction get-by-address" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --from-block: int # The minimum block number from which to get the transactions * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-block: int # The maximum block number from which to get the transactions. * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --from-date: string # The start date from which to get the transactions (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-date: string # Get the transactions up to this date (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
  --limit: int # The desired page size of the result.
  --include: string@include-completer # If the result should contain the internal transactions. (default: , e.g. )
]: nothing -> record<cursor: string, page: int, page_size: int, result: table<hash: string, nonce: string, transaction_index: string, from_address_entity: string, from_address_entity_logo: string, from_address: string, from_address_label: string, to_address_entity: string, to_address_entity_logo: string, to_address: string, to_address_label: string, value: string, gas: string, gas_price: string, input: string, receipt_cumulative_gas_used: string, receipt_gas_used: string, receipt_contract_address: string, receipt_root: string, receipt_status: string, transaction_fee: string, block_timestamp: string, block_number: string, block_hash: string, internal_transactions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "from_block" $from_block "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($address)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get decoded transactions by wallet
#
# GET /{address}/verbose
# operationId: getWalletTransactionsVerbose
export def "verbose get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --from-block: int # The minimum block number from which to get the transactions * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-block: int # The maximum block number from which to get the transactions. * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --from-date: string # The start date from which to get the transactions (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --to-date: string # Get the transactions up to this date (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --include: string@include-completer # If the result should contain the internal transactions. (default: , e.g. )
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
  --limit: int # The desired page size of the result.
]: nothing -> record<cursor: string, page: int, page_size: int, result: table<hash: string, nonce: string, transaction_index: string, from_address_entity: string, from_address_entity_logo: string, from_address: string, from_address_label: string, to_address_entity: string, to_address_entity_logo: string, to_address: string, to_address_label: string, value: string, gas: string, gas_price: string, input: string, receipt_cumulative_gas_used: string, receipt_gas_used: string, receipt_contract_address: string, receipt_root: string, receipt_status: string, transaction_fee: string, block_timestamp: string, block_number: string, block_hash: string, logs: list, decoded_call: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "from_block" $from_block "scalar") (serialize-qp "to_block" $to_block "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($address)/verbose" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get transaction by hash
#
# GET /transaction/{transaction_hash}
# operationId: getTransaction
export def "transaction get-by-transaction_hash" [
  transaction_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --include: string@include-completer # If the result should contain the internal transactions. (default: , e.g. )
]: nothing -> record<hash: string, nonce: string, transaction_index: string, from_address_entity: string, from_address_entity_logo: string, from_address: string, from_address_label: string, to_address_entity: string, to_address_entity_logo: string, to_address: string, to_address_label: string, value: string, gas: string, gas_price: string, input: string, receipt_cumulative_gas_used: string, receipt_gas_used: string, receipt_contract_address: string, receipt_root: string, receipt_status: string, block_timestamp: string, block_number: string, block_hash: string, logs: table<log_index: string, transaction_hash: string, transaction_index: string, address: string, data: string, topic0: string, topic1: string, topic2: string, topic3: string, block_timestamp: string, block_number: string, block_hash: string>, internal_transactions: table<transaction_hash: string, block_number: string, block_hash: string, type: string, from: string, to: string, value: string, gas: string, gas_used: string, input: string, output: string, error: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/transaction/($transaction_hash)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get decoded transaction by hash
#
# GET /transaction/{transaction_hash}/verbose
# operationId: getTransactionVerbose
export def "transaction-verbose get" [
  transaction_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --include: string@include-completer # If the result should contain the internal transactions. (default: , e.g. )
]: nothing -> record<hash: string, nonce: string, transaction_index: string, from_address_entity: string, from_address_entity_logo: string, from_address: string, from_address_label: string, to_address_entity: string, to_address_entity_logo: string, to_address: string, to_address_label: string, value: string, gas: string, gas_price: string, input: string, receipt_cumulative_gas_used: string, receipt_gas_used: string, receipt_contract_address: string, receipt_root: string, receipt_status: string, transaction_fee: string, block_timestamp: string, block_number: string, block_hash: string, logs: table<log_index: string, transaction_hash: string, transaction_index: string, address: string, data: string, topic0: string, topic1: string, topic2: string, topic3: string, block_timestamp: string, block_number: string, block_hash: string, decoded_event: record>, decoded_call: record<signature: string, label: string, type: string, params: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/transaction/($transaction_hash)/verbose" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get block by hash
#
# GET /block/{block_number_or_hash}
# operationId: getBlock
export def "block get" [
  block_number_or_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --include: string@include-completer # If the result should contain the internal transactions. (default: , e.g. )
]: nothing -> record<timestamp: string, number: string, hash: string, parent_hash: string, nonce: string, sha3_uncles: string, logs_bloom: string, transactions_root: string, state_root: string, receipts_root: string, miner: string, difficulty: string, total_difficulty: string, size: string, extra_data: string, gas_limit: string, gas_used: string, transaction_count: string, transactions: table<hash: string, nonce: string, transaction_index: string, from_address_entity: string, from_address_entity_logo: string, from_address: string, from_address_label: string, to_address_entity: string, to_address_entity_logo: string, to_address: string, to_address_label: string, value: string, gas: string, gas_price: string, input: string, receipt_cumulative_gas_used: string, receipt_gas_used: string, receipt_contract_address: string, receipt_root: string, receipt_status: string, block_timestamp: string, block_number: string, block_hash: string, logs: list, internal_transactions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/block/($block_number_or_hash)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest block number
#
# GET /latestBlockNumber/{chain}
# operationId: getLatestBlockNumber
export def "latest-block-number get" [
  chain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/latestBlockNumber/($chain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get block by date
#
# GET /dateToBlock
# operationId: getDateToBlock
export def "date-to-block get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --date: string # Unix date in milliseconds or a datestring (format in seconds or datestring accepted by momentjs)
]: nothing -> record<date: string, block: float, timestamp: float, block_timestamp: string, hash: string, parent_hash: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dateToBlock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run contract function
#
# POST /{address}/function
# operationId: runContractFunction
export def "function runContractFunction" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --function-name: string # The function name of the contract
  abi: list # The contract ABI (e.g. [])
  --params: record # The params for the given function (e.g. {})
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "function_name" $function_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($address)/function" $qp)
  let body = {abi: $abi, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get API version
#
# GET /web3/version
# operationId: web3ApiVersion
export def "web3-version web3ApiVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/web3/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get weights of endpoints
#
# GET /info/endpointWeights
# operationId: endpointWeights
export def "info-endpoint-weights endpointWeights" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<endpoint: string, path: string, rateLimitCost: string, price: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/info/endpointWeights")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ENS lookup by address
#
# GET /resolve/{address}/reverse
# operationId: resolveAddress
export def "resolve-reverse resolveAddress" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/resolve/($address)/reverse")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve Unstoppable domain
#
# GET /resolve/{domain}
# operationId: resolveDomain
export def "resolve resolveDomain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currency: string@currency-completer # The currency to query (default: eth, e.g. eth)
]: nothing -> record<address: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency" $currency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/resolve/($domain)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve Address to Unstoppable domain
#
# GET /resolve/{address}/domain
# operationId: resolveAddressToDomain
export def "resolve-domain resolveAddressToDomain" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currency: string@currency-completer # The currency to query (default: eth, e.g. eth)
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency" $currency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/resolve/($address)/domain" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ENS lookup by domain
#
# GET /resolve/ens/{domain}
# operationId: resolveENSDomain
export def "resolve-ens resolveENSDomain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/resolve/ens/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Review contracts
#
# POST /contracts-review
# operationId: reviewContracts
# --contracts item shape: {contract_address: string, reason: string, report_type: "spam"|"not_spam", contract_type: "ERC20"|"NFT"}
export def "contracts-review reviewContracts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  contracts: list # The contracts to be reported (e.g. [{contract_address: 0xa4991609c508b6d4fb7156426db0bd49fe298bd8, report_type: spam, contract_type: ERC20, reason: The contract contains shady code}]) — item shape: {contract_address: string, reason: string, report_type: "spam"|"not_spam", contract_type: "ERC20"|"NFT"}
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contracts-review" $qp)
  let body = {contracts: $contracts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the DeFi summary of a wallet
#
# GET /wallets/{address}/defi/summary
# operationId: getDefiSummary
export def "wallets-defi-summary get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<active_protocols: float, total_positions: float, total_usd_value: float, total_unclaimed_usd_value: float, protocols: table<total_usd_value: float, total_unclaimed_usd_value: float, positions: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/defi/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get detailed DeFi positions by protocol for a wallet
#
# GET /wallets/{address}/defi/{protocol}/positions
# operationId: getDefiPositionsByProtocol
export def "wallets-defi-positions get" [
  address: string
  protocol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<protocol_name: string, protocol_id: string, protocol_url: string, protocol_logo: string, total_usd_value: float, total_unclaimed_usd_value: float, positions: table<label: string, tokens: list, address: string, balance_usd: float, total_unclaimed_usd_value: float, position_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/defi/($protocol)/positions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DeFi positions of a wallet
#
# GET /wallets/{address}/defi/positions
# operationId: getDefiPositionsSummary
export def "wallets-defi-positions list" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> table<protocol_name: string, protocol_id: string, protocol_url: string, protocol_logo: string, position: record<label: string, tokens: list, address: string, balance_usd: float, total_unclaimed_usd_value: float, position_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/defi/positions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get active chains by wallet address
#
# GET /wallets/{address}/chains
# operationId: getWalletActiveChains
export def "wallets-chains get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chains: list # The chains to query
]: nothing -> record<address: string, active_chains: table<chain: string, chain_id: string, first_transaction: record, last_transaction: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chains" $chains "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/chains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get summary stats by wallet address
#
# GET /wallets/{address}/stats
# operationId: getWalletStats
export def "wallets-stats get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<nfts: string, collections: string, transactions: record<total: string>, nft_transfers: record<total: string>, token_transfers: record<total: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get summary stats by NFT collection
#
# GET /nft/{address}/stats
# operationId: getNFTCollectionStats
export def "nft-stats get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<total_tokens: string, owners: record<current: string>, transfers: record<total: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT floor price by contract
#
# GET /nft/{address}/floor-price
# operationId: getNFTFloorPriceByContract
export def "nft-floor-price list" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<address: string, floor_price: string, floor_price_usd: string, currency: string, marketplace: record<name: string, logo: string>, last_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/floor-price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT floor price by token
#
# GET /nft/{address}/{token_id}/floor-price
# operationId: getNFTFloorPriceByToken
export def "nft-floor-price get" [
  address: string
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<address: string, token_id: string, floor_price: string, floor_price_usd: string, currency: string, marketplace: record<name: string, logo: string>, last_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/($token_id)/floor-price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical NFT floor price by contract
#
# GET /nft/{address}/floor-price/historical
# operationId: getNFTHistoricalFloorPriceByContract
export def "nft-floor-price-historical get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --interval: string@interval-completer # The duration to query (default: 1d, e.g. 1d)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<floor_price: string, floor_price_usd: string, currency: string, marketplace: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nft/($address)/floor-price/historical" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get profit and loss summary by wallet address
#
# GET /wallets/{address}/profitability/summary
# operationId: getWalletProfitabilitySummary
export def "wallets-profitability-summary get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: string # Timeframe in days for the profitability summary. Options include 'all', '7', '30', '60', '90' default is 'all'.
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<total_count_of_trades: float, total_trade_volume: string, total_realized_profit_usd: string, total_realized_profit_percentage: float, total_buys: float, total_sells: float, total_sold_volume_usd: string, total_bought_volume_usd: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar") (serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/profitability/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get detailed profit and loss by wallet address
#
# GET /wallets/{address}/profitability
# operationId: getWalletProfitability
export def "wallets-profitability get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: string # Timeframe in days for which profitability is calculated, Options include 'all', '7', '30', '60', '90' default is 'all'.
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --token-addresses: list # The token addresses list to filter the result with
]: nothing -> record<result: table<token_address: string, avg_buy_price_usd: string, avg_sell_price_usd: string, total_usd_invested: string, total_tokens_sold: string, total_tokens_bought: string, total_sold_usd: string, avg_cost_of_quantity_sold: string, count_of_trades: float, realized_profit_usd: string, realized_profit_percentage: float, total_buys: float, total_sells: float, name: string, symbol: string, decimals: string, logo: string, possible_spam: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar") (serialize-qp "chain" $chain "scalar") (serialize-qp "token_addresses" $token_addresses "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/profitability" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get top traders for a given ERC20 token
#
# GET /erc20/{address}/top-gainers
# operationId: getTopProfitableWalletPerToken
export def "erc20-top-gainers get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: string # Timeframe in days for which profitability is calculated, Options include 'all', '7', '30' default is 'all'.
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<name: string, symbol: string, decimals: int, logo: string, possible_spam: bool, result: table<avg_buy_price_usd: string, avg_cost_of_quantity_sold: string, avg_sell_price_usd: string, count_of_trades: float, realized_profit_percentage: float, realized_profit_usd: string, total_sold_usd: string, total_tokens_bought: string, total_tokens_sold: string, total_usd_invested: string, address: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar") (serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/erc20/($address)/top-gainers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for tokens based on contract address, pair address, token name or token symbol.
#
# GET /tokens/search
# operationId: searchTokens
export def "tokens-search searchTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chains: string # The chains to query
  --qp-query: string # The query to search (e.g. pepe)
  --limit: float # The desired page size of the result.
  --isVerifiedContract: string@bool-completer # True to include only verified contracts (default: false)
  --sortBy: string@sortBy-completer # Sort by volume1hDesc, volume24hDesc, liquidityDesc, marketCapDesc (default: volume1hDesc, e.g. volume1hDesc)
  --boostVerifiedContracts: string@bool-completer # True to boost verified contracts (default: true)
]: nothing -> record<total: int, result: table<tokenAddress: string, chainId: string, name: string, symbol: string, blockNumber: int, blockTimestamp: int, usdPrice: float, marketCap: float, experiencedNetBuyers: record, netVolumeUsd: record, liquidityChangeUSD: record, usdPricePercentChange: record, volumeUsd: record, securityScore: int, logo: string, isVerifiedContract: bool, fullyDilutedValuation: float, totalHolders: float, totalLiquidityUsd: float, implementations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chains" $chains "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "isVerifiedContract" $isVerifiedContract "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "boostVerifiedContracts" $boostVerifiedContracts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tokens/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Entities, Organizations or Wallets
#
# GET /entities/search
# operationId: searchEntities
export def "entities-search searchEntities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query (e.g. Doge)
  --limit: int # The desired page size of the result.
]: nothing -> record<page: int, page_size: int, result: record<entities: list<record>, addresses: list<record>, categories: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Entity Details By Id
#
# GET /entities/{entityId}
# operationId: getEntity
export def "entities get" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<addresses: table<additional_labels: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entities/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Entity Categories
#
# GET /entities/categories
# operationId: getEntityCategories
export def "entities-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The desired page size of the result.
]: nothing -> record<page: int, page_size: int, result: table<total_entities: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Entities By Category
#
# GET /entities/categories/{categoryId}
# operationId: getEntitiesByCategory
export def "entities-categories get" [
  categoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The desired page size of the result.
]: nothing -> record<page: int, page_size: int, result: table<total_addresses: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/categories/($categoryId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get OHLCV by pair address
#
# GET /pairs/{address}/ohlcv
# operationId: getPairCandlesticks
export def "pairs-ohlcv get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --timeframe: string@timeframe-completer # The timeframe (default: 1h, e.g. 1h)
  --currency: string@currency-completer-1 # The currency (default: usd, e.g. usd)
  --fromDate: string # The starting date (format in seconds or datestring accepted by momentjs) * Provide the param 'fromBlock' or 'fromDate' * If 'fromDate' and 'fromBlock' are provided, 'fromBlock' will be used.  (e.g. 2025-01-01T10:00:00.000)
  --toDate: string # The ending date (format in seconds or datestring accepted by momentjs) * Provide the param 'toBlock' or 'toDate' * If 'toDate' and 'toBlock' are provided, 'toBlock' will be used.  (e.g. 2025-01-02T10:00:00.000)
  --limit: int # The number of results to return
  --cursor: string # The cursor returned in the previous response (used for getting the next page)
]: nothing -> record<cursor: string, page: int, pairAddress: string, tokenAddress: string, timeframe: string, currency: string, result: table<timestamp: string, open: float, high: float, low: float, close: float, volume: float, trades: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pairs/($address)/ohlcv" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stats by pair address
#
# GET /pairs/{address}/stats
# operationId: getPairStats
export def "pairs-stats get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
]: nothing -> record<tokenAddress: string, tokenName: string, tokenSymbol: string, tokenLogo: string, pairCreated: string, pairLabel: string, pairAddress: string, exchange: string, exchangeAddress: string, exchangeLogo: string, exchangeUrl: string, currentUsdPrice: string, currentNativePrice: string, totalLiquidityUsd: string, pricePercentChange: record<5min: float, 1h: float, 4h: float, 24h: float>, liquidityPercentChange: record<5min: float, 1h: float, 4h: float, 24h: float>, buys: record<5min: float, 1h: float, 4h: float, 24h: float>, sells: record<5min: float, 1h: float, 4h: float, 24h: float>, totalVolume: record<5min: float, 1h: float, 4h: float, 24h: float>, buyVolume: record<5min: float, 1h: float, 4h: float, 24h: float>, sellVolume: record<5min: float, 1h: float, 4h: float, 24h: float>, buyers: record<5min: float, 1h: float, 4h: float, 24h: float>, sellers: record<5min: float, 1h: float, 4h: float, 24h: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pairs/($address)/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get token pairs by address
#
# GET /erc20/{token_address}/pairs
# operationId: getTokenPairs
export def "erc20-pairs get" [
  token_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --limit: int # The number of results to return
  --cursor: string # The cursor returned in the previous response (used for getting the next page)
]: nothing -> record<pairs: table<exchange_address: string, exchange_name: string, exchange_logo: string, pair_label: string, pair_address: string, usd_price: float, usd_price_24hr: float, usd_price_24hr_percent_change: float, usd_price_24hr_usd_change: float, liquidity_usd: float, liquidity_skew: float, inactive_pair: bool, base_token: string, quote_token: string, volume_24h_native: float, volume_24h_usd: float, pair: list>, cursor: string, page_size: int, page: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/erc20/($token_address)/pairs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get swap transactions by wallet address
#
# GET /wallets/{address}/swaps
# operationId: getSwapsByWalletAddress
export def "wallets-swaps get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --tokenAddress: string # The token address to get transaction for (optional)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --limit: int # The desired page size of the result.
  --fromBlock: int # The minimum block number from which to get the token transactions * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --toBlock: string # The block number to get the token transactions from
  --fromDate: string # The start date from which to get the token transactions (format in seconds or datestring accepted by momentjs) * Provide the param 'from_block' or 'from_date' * If 'from_date' and 'from_block' are provided, 'from_block' will be used.
  --toDate: string # The end date from which to get the token transactions (format in seconds or datestring accepted by momentjs) * Provide the param 'to_block' or 'to_date' * If 'to_date' and 'to_block' are provided, 'to_block' will be used.
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
  --transactionTypes: string # Array of transaction types. Allowed values are 'buy', 'sell'.
]: nothing -> record<page: int, page_size: int, cursor: string, result: table<transactionHash: string, transactionIndex: int, transactionType: string, blockTimestamp: string, blockNumber: float, subCategory: string, walletAddress: string, walletAddressLabel: string, entity: string, entityLogo: string, pairAddress: string, pairLabel: string, exchangeAddress: string, exchangeName: string, exchangeLogo: string, bought: record, sold: record, baseQuotePrice: string, totalValueUsd: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "tokenAddress" $tokenAddress "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fromBlock" $fromBlock "scalar") (serialize-qp "toBlock" $toBlock "scalar") (serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "transactionTypes" $transactionTypes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/swaps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get wallet insight metrics
#
# GET /wallets/{address}/insight
# operationId: getWalletInsight
export def "wallets-insight get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chains: list # The chains to query. If not provided, aggregates across all supported chains. (e.g. [0x1, 0x89])
  --includeChainBreakdown: string@bool-completer # When true, includes a per-chain breakdown array in the response with both native and USD values. (default: false)
]: nothing -> record<address: string, addressType: string, walletAgeDays: int, firstActivityAt: record<chain: string, blockNumber: string, blockTimestamp: string, transactionHash: string, type: string, direction: string>, lastActivityAt: record<chain: string, blockNumber: string, blockTimestamp: string, transactionHash: string, type: string, direction: string>, firstInitiatedAt: record<chain: string, blockNumber: string, blockTimestamp: string, transactionHash: string, type: string, direction: string>, lastInitiatedAt: record<chain: string, blockNumber: string, blockTimestamp: string, transactionHash: string, type: string, direction: string>, activeDays: int, activeChains: int, mostActiveChain: string, transactionsInitiated: int, transactionsInvolved: int, nativeTransfers: record<sent: int, received: int, total: int>, erc20Transfers: record<sent: int, received: int, total: int>, nftTransfers: record<sent: int, received: int, total: int>, uniqueCounterparties: record<sentTo: int, receivedFrom: int>, swapVolumeUsd: float, totalGasSpentUsd: string, avgGasPerTransactionUsd: string, nativeVolumeSentUsd: string, nativeVolumeReceivedUsd: string, nativeNetFlowUsd: string, uniqueTokensInteracted: int, contractsCreated: int, largestNativeTransferInUsd: string, largestNativeTransferOutUsd: string, chainBreakdown: table<chain: string, walletAgeDays: int, firstActivityAt: record, lastActivityAt: record, firstInitiatedAt: record, lastInitiatedAt: record, activeDays: int, transactionsInitiated: int, transactionsInvolved: int, nativeTransfers: record, erc20Transfers: record, nftTransfers: record, uniqueCounterparties: record, swapVolumeUsd: float, totalGasSpentNative: string, totalGasSpentUsd: string, avgGasPerTransactionNative: string, avgGasPerTransactionUsd: string, nativeVolumeSent: string, nativeVolumeSentUsd: string, nativeVolumeReceived: string, nativeVolumeReceivedUsd: string, nativeNetFlow: string, nativeNetFlowUsd: string, uniqueTokensInteracted: int, contractsCreated: int, largestNativeTransferIn: string, largestNativeTransferInUsd: string, largestNativeTransferOut: string, largestNativeTransferOutUsd: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chains" $chains "multi") (serialize-qp "includeChainBreakdown" $includeChainBreakdown "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wallets/($address)/insight" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get swap transactions by pair address
#
# GET /pairs/{address}/swaps
# operationId: getSwapsByPairAddress
export def "pairs-swaps get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer # The chain to query (default: eth, e.g. eth)
  --cursor: string # The cursor returned in the previous response (used for getting the next page).
  --limit: int # The desired page size of the result.
  --fromBlock: int # The minimum block number from which to get the token transactions * Provide the param 'fromBlock' or 'fromDate' * If 'fromDate' and 'fromBlock' are provided, 'fromBlock' will be used.
  --toBlock: string # The block number to get the token transactions from
  --fromDate: string # The start date from which to get the token transactions (format in seconds or datestring accepted by momentjs) * Provide the param 'fromBlock' or 'fromDate' * If 'fromDate' and 'fromBlock' are provided, 'fromBlock' will be used.
  --toDate: string # The end date from which to get the token transactions (format in seconds or datestring accepted by momentjs) * Provide the param 'toBlock' or 'toDate' * If 'toDate' and 'toBlock' are provided, 'toBlock' will be used.
  --order: string@order-completer # The order of the result, in ascending (ASC) or descending (DESC) (default: DESC, e.g. DESC)
  --transactionTypes: string # Array of transaction types. Allowed values are 'buy', 'sell', 'addLiquidity', 'removeLiquidity'.
]: nothing -> record<page: int, pageSize: int, cursor: string, exchangeAddress: string, exchangeName: string, exchangeLogo: string, pairLabel: string, pairAddress: string, baseToken: record<address: string, name: string, symbol: string, logo: string, amount: string, usdPrice: float, usdAmount: float>, quoteToken: record<address: string, name: string, symbol: string, logo: string, amount: string, usdPrice: float, usdAmount: float>, result: table<transactionHash: string, transactionIndex: int, transactionType: string, blockTimestamp: string, blockNumber: float, subCategory: string, walletAddress: string, baseTokenAmount: string, quoteTokenAmount: string, baseTokenPriceUsd: float, quoteTokenPriceUsd: float, baseQuotePrice: string, totalValueUsd: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fromBlock" $fromBlock "scalar") (serialize-qp "toBlock" $toBlock "scalar") (serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "transactionTypes" $transactionTypes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pairs/($address)/swaps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve timeseries trading stats by token addresses
#
# POST /tokens/analytics/timeseries
# operationId: getTimeSeriesTokenAnalytics
# --tokens item shape: {chain: "eth"|"0x1"|"sepolia"|"0xaa36a7"|"polygon"|"0x89"|"bsc"|"0x38"|"bsc testnet"|"0x61"|"avalanche"|"0xa86a"|"cronos"|"0x19"|"arbitrum"|"0xa4b1"|"chiliz"|"0x15b38"|"chiliz testnet"|"0x15b32"|"gnosis"|"0x64"|"gnosis testnet"|"0x27d8"|"base"|"0x2105"|"base sepolia"|"0x14a34"|"optimism"|"0xa"|"polygon amoy"|"0x13882"|"linea"|"0xe708"|"moonbeam"|"0x504"|"moonriver"|"0x505"|"moonbase"|"0x507"|"linea sepolia"|"0xe705"|"flow"|"0x2eb"|"flow-testnet"|"0x221"|"ronin"|"0x7e4"|"ronin-testnet"|"0x31769"|"lisk"|"0x46f"|"lisk-sepolia"|"0x106a"|"pulse"|"0x171"|"sei-testnet"|"0x530"|"sei"|"0x531"|"monad"|"0x8f", tokenAddress: string}
export def "tokens-analytics-timeseries post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeframe: string@timeframe-completer-1 # The timeframe to query (default: 1d, e.g. 1d)
  tokens: list # The tokens to be fetched (e.g. [{chain: 0x1, tokenAddress: 0xdac17f958d2ee523a2206206994597c13d831ec7}, {chain: solana, tokenAddress: EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v}]) — item shape: {chain: "eth"|"0x1"|"sepolia"|"0xaa36a7"|"polygon"|"0x89"|"bsc"|"0x38"|"bsc testnet"|"0x61"|"avalanche"|"0xa86a"|"cronos"|"0x19"|"arbitrum"|"0xa4b1"|"chiliz"|"0x15b38"|"chiliz testnet"|"0x15b32"|"gnosis"|"0x64"|"gnosis testnet"|"0x27d8"|"base"|"0x2105"|"base sepolia"|"0x14a34"|"optimism"|"0xa"|"polygon amoy"|"0x13882"|"linea"|"0xe708"|"moonbeam"|"0x504"|"moonriver"|"0x505"|"moonbase"|"0x507"|"linea sepolia"|"0xe705"|"flow"|"0x2eb"|"flow-testnet"|"0x221"|"ronin"|"0x7e4"|"ronin-testnet"|"0x31769"|"lisk"|"0x46f"|"lisk-sepolia"|"0x106a"|"pulse"|"0x171"|"sei-testnet"|"0x530"|"sei"|"0x531"|"monad"|"0x8f", tokenAddress: string}
]: any -> record<result: table<chainId: string, tokenAddress: string, timeseries: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeframe" $timeframe "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tokens/analytics/timeseries" $qp)
  let body = {tokens: $tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get trending tokens
#
# GET /tokens/trending
# operationId: getTrendingTokensV2
export def "tokens-trending get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer-1 # The chain to query (default: eth, e.g. eth)
  --limit: int # The desired page size of the result.
]: nothing -> table<chainId: string, tokenAddress: string, name: string, symbol: string, uniqueName: string, decimals: int, logo: string, usdPrice: float, createdAt: int, marketCap: int, liquidityUsd: int, holders: int, pricePercentChange: record<1h: float, 4h: float, 12h: float, 24h: float>, totalVolume: record<1h: int, 4h: int, 12h: int, 24h: int>, transactions: record<1h: int, 4h: int, 12h: int, 24h: int>, buyTransactions: record<1h: int, 4h: int, 12h: int, 24h: int>, sellTransactions: record<1h: int, 4h: int, 12h: int, 24h: int>, buyers: record<1h: int, 4h: int, 12h: int, 24h: int>, sellers: record<1h: int, 4h: int, 12h: int, 24h: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tokens/trending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get token analytics by token address
#
# GET /tokens/{tokenAddress}/analytics
# operationId: getTokenAnalytics
export def "tokens-analytics get" [
  tokenAddress: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer-1 # The chain to query (default: eth, e.g. eth)
]: nothing -> record<chainId: string, categoryId: string, totalBuyVolume: record<5m: float, 1h: float, 6h: float, 24h: float>, totalSellVolume: record<5m: float, 1h: float, 6h: float, 24h: float>, totalBuyers: record<5m: float, 1h: float, 6h: float, 24h: float>, totalSellers: record<5m: float, 1h: float, 6h: float, 24h: float>, totalBuys: record<5m: float, 1h: float, 6h: float, 24h: float>, totalSells: record<5m: float, 1h: float, 6h: float, 24h: float>, uniqueWallets: record<5m: float, 1h: float, 6h: float, 24h: float>, pricePercentChange: record<5m: float, 1h: float, 6h: float, 24h: float>, usdPrice: string, totalLiquidity: string, totalFullyDilutedValuation: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tokens/($tokenAddress)/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get token score by token address
#
# GET /tokens/{tokenAddress}/score
# operationId: getTokenScore
export def "tokens-score get" [
  tokenAddress: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer-1 # The chain to query (default: eth, e.g. eth)
]: nothing -> record<tokenAddress: string, chainId: string, score: int, updatedAt: string, metrics: record<usdPrice: float, liquidityUsd: float, volumeUsd: record<10m: float, 30m: float, 1h: float, 4h: float, 12h: float, 1d: float, 7d: float, 30d: float>, transactions: record<10m: float, 30m: float, 1h: float, 4h: float, 12h: float, 1d: float, 7d: float, 30d: float>, supply: record<total: float, top10Percent: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tokens/($tokenAddress)/score" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical token score by token address
#
# GET /tokens/{tokenAddress}/score/historical
# operationId: getHistoricalTokenScore
export def "tokens-score-historical get" [
  tokenAddress: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chain: string@chain-completer-1 # The chain to query (default: eth, e.g. eth)
  --timeframe: string@timeframe-completer-1 # The timeframe to query (default: 1d, e.g. 1d)
]: nothing -> record<chainId: string, tokenAddress: string, timeseries: table<timestamp: string, score: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chain" $chain "scalar") (serialize-qp "timeframe" $timeframe "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tokens/($tokenAddress)/score/historical" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get token analytics for a list of token addresses
#
# POST /tokens/analytics
# operationId: getMultipleTokenAnalytics
# --tokens item shape: {chain: "eth"|"0x1"|"sepolia"|"0xaa36a7"|"polygon"|"0x89"|"bsc"|"0x38"|"bsc testnet"|"0x61"|"avalanche"|"0xa86a"|"cronos"|"0x19"|"arbitrum"|"0xa4b1"|"chiliz"|"0x15b38"|"chiliz testnet"|"0x15b32"|"gnosis"|"0x64"|"gnosis testnet"|"0x27d8"|"base"|"0x2105"|"base sepolia"|"0x14a34"|"optimism"|"0xa"|"polygon amoy"|"0x13882"|"linea"|"0xe708"|"moonbeam"|"0x504"|"moonriver"|"0x505"|"moonbase"|"0x507"|"linea sepolia"|"0xe705"|"flow"|"0x2eb"|"flow-testnet"|"0x221"|"ronin"|"0x7e4"|"ronin-testnet"|"0x31769"|"lisk"|"0x46f"|"lisk-sepolia"|"0x106a"|"pulse"|"0x171"|"sei-testnet"|"0x530"|"sei"|"0x531"|"monad"|"0x8f", tokenAddress: string}
export def "tokens-analytics post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tokens: list # The tokens to be fetched (e.g. [{chain: 0x1, tokenAddress: 0xdac17f958d2ee523a2206206994597c13d831ec7}, {chain: solana, tokenAddress: EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v}]) — item shape: {chain: "eth"|"0x1"|"sepolia"|"0xaa36a7"|"polygon"|"0x89"|"bsc"|"0x38"|"bsc testnet"|"0x61"|"avalanche"|"0xa86a"|"cronos"|"0x19"|"arbitrum"|"0xa4b1"|"chiliz"|"0x15b38"|"chiliz testnet"|"0x15b32"|"gnosis"|"0x64"|"gnosis testnet"|"0x27d8"|"base"|"0x2105"|"base sepolia"|"0x14a34"|"optimism"|"0xa"|"polygon amoy"|"0x13882"|"linea"|"0xe708"|"moonbeam"|"0x504"|"moonriver"|"0x505"|"moonbase"|"0x507"|"linea sepolia"|"0xe705"|"flow"|"0x2eb"|"flow-testnet"|"0x221"|"ronin"|"0x7e4"|"ronin-testnet"|"0x31769"|"lisk"|"0x46f"|"lisk-sepolia"|"0x106a"|"pulse"|"0x171"|"sei-testnet"|"0x530"|"sei"|"0x531"|"monad"|"0x8f", tokenAddress: string}
]: any -> record<categories: table<chainId: string, categoryId: string, totalBuyVolume: record, totalSellVolume: record, totalBuyers: record, totalSellers: record, totalBuys: record, totalSells: record, uniqueWallets: record, pricePercentChange: record, usdPrice: string, totalLiquidity: string, totalFullyDilutedValuation: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens/analytics")
  let body = {tokens: $tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
