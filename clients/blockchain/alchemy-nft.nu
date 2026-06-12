# Auto-generated client for 🎨 NFT API v1.0
# Source: https://raw.githubusercontent.com/alchemyplatform/docs-openapi-specs/main/nft/nfts.yaml
# Auth: --token flag or $env.NFT_API_TOKEN

const BASE_URL = "https://eth-mainnet.g.alchemy.com/nft"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NFT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://eth-mainnet.g.alchemy.com/nft" "https://eth-sepolia.g.alchemy.com/nft" "https://eth-holesky.g.alchemy.com/nft" "https://avax-mainnet.g.alchemy.com/nft" "https://avax-fuji.g.alchemy.com/nft" "https://zksync-mainnet.g.alchemy.com/nft" "https://opt-mainnet.g.alchemy.com/nft" "https://polygon-mainnet.g.alchemy.com/nft" "https://polygon-amoy.g.alchemy.com/nft" "https://arb-mainnet.g.alchemy.com/nft" "https://arb-sepolia.g.alchemy.com/nft" "https://fantom-mainnet.g.alchemy.com/nft" "https://fantom-testnet.g.alchemy.com/nft" "https://blast-mainnet.g.alchemy.com/nft" "https://blast-sepolia.g.alchemy.com/nft" "https://base-mainnet.g.alchemy.com/nft" "https://base-sepolia.g.alchemy.com/nft" "https://soneium-mainnet.g.alchemy.com/nft" "https://soneium-minato.g.alchemy.com/nft" "https://scroll-mainnet.g.alchemy.com/nft" "https://scroll-sepolia.g.alchemy.com/nft" "https://shape-mainnet.g.alchemy.com/nft" "https://shape-sepolia.g.alchemy.com/nft" "https://lens-sepolia.g.alchemy.com/nft" "https://starknet-mainnet.g.alchemy.com/nft" "https://starknet-sepolia.g.alchemy.com/nft" "https://rootstock-mainnet.g.alchemy.com/nft" "https://rootstock-testnet.g.alchemy.com/nft" "https://linea-mainnet.g.alchemy.com/nft" "https://linea-sepolia.g.alchemy.com/nft" "https://settlus-septestnet.g.alchemy.com/nft" "https://abstract-mainnet.g.alchemy.com/nft" "https://abstract-testnet.g.alchemy.com/nft" "https://apechain-mainnet.g.alchemy.com/nft" "https://unichain-mainnet.g.alchemy.com/nft" "https://unichain-sepolia.g.alchemy.com/nft" "https://zora-mainnet.g.alchemy.com/nft" "https://zora-sepolia.g.alchemy.com/nft" "https://berachain-mainnet.g.alchemy.com/nft" "https://monad-testnet.g.alchemy.com/nft" "https://ronin-mainnet.g.alchemy.com/nft" "https://ronin-saigon.g.alchemy.com/nft" "https://{network}.g.alchemy.com/nft"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def orderBy-completer [] { ["" "transferTime"] }
def spamConfidenceLevel-completer [] { ["HIGH" "LOW" "MEDIUM" "VERY_HIGH"] }
def order-completer [] { ["asc" "desc"] }
def marketplace-completer [] { ["blur" "cryptopunks" "looksrare" "seaport" "wyvern" "x2y2"] }
def taker-completer [] { ["BUYER" "SELLER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "get-nf-ts-for-owner get" } } | get name | first)
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

# NFTs By Owner
#
# GET /v3/{apiKey}/getNFTsForOwner
# operationId: getNFTsForOwner-v3
export def "get-nf-ts-for-owner get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string # String - Address for NFT owner (can be in ENS format for Eth Mainnet). (default: 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045)
  --contractAddresses: list # Array of contract addresses to filter the responses with. Max limit 45 contracts.
  --withMetadata: oneof<nothing, bool> # Boolean - if set to `true`, returns NFT metadata. Setting this to false will reduce payload size and may result in a faster API call. Defaults to `true`. (default: true)
  --orderBy: string@orderBy-completer # Enum - ordering scheme to use for ordering NFTs in the response. If unspecified, NFTs will be ordered by contract address and token ID.   - transferTime: NFTs will be ordered by the time they were transferred into the wallet, with newest NFTs first. NOTE: this ordering is only supported on Ethereum Mainnet and Polygon Mainnet.
  --excludeFilters: list # Array of filters (as ENUMS) that will be applied to the query. NFTs that match one or more of these filters will be excluded from the response. May not be used in conjunction with includeFilters[]. Filter Options:   - SPAM: NFTs that have been classified as spam. Spam classification has a wide range of criteria that includes but is not limited to emitting fake events and copying other well-known NFTs. Please note that this filter is **available exclusively on paid tiers**.   - AIRDROPS: NFTs that have were airdropped to the user. Airdrops are defined as NFTs that were minted to a user address in a transaction sent by a different address. NOTE: this filter is currently supported on Ethereum Mainnet, Ethereum Goerli, and Matic Mainnet only.   - To learn more about spam, you can refer to this: <span class="custom-style"><a href="https://www.alchemy.com/overviews/spam-nfts" target="_blank">Spam NFTs and how to fix them</a></span>
  --includeFilters: list # Array of filters (as ENUMS) that will be applied to the query. Only NFTs that match one or more of these filters will be included in the response. May not be used in conjunction with excludeFilters[]. Filter Options:   - SPAM: NFTs that have been classified as spam. Spam classification has a wide range of criteria that includes but is not limited to emitting fake events and copying other well-known NFTs. Please note that this filter is **available exclusively on paid tiers**.   - AIRDROPS: NFTs that have were airdropped to the user. Airdrops are defined as NFTs that were minted to a user address in a transaction sent by a different address. NOTE: this filter is currently supported on Ethereum Mainnet, Ethereum Goerli, and Matic Mainnet only.   - To learn more about spam, you can refer to this: <span class="custom-style"><a href="https://www.alchemy.com/overviews/spam-nfts" target="_blank">Spam NFTs and how to fix them</a></span>
  --spamConfidenceLevel: string@spamConfidenceLevel-completer # Enum - the confidence level at which to filter spam at.  Confidence Levels:   - VERY_HIGH   - HIGH   - MEDIUM   - LOW  The confidence level set means that any spam that is at that confidence level or higher will be filtered out. For example, if the confidence level is HIGH, contracts that we have HIGH or VERY_HIGH confidence in being spam will be filtered out from the response.  Defaults to VERY_HIGH for Ethereum Mainnet and MEDIUM for other networks.  **Please note that this filter is only available on paid tiers. Upgrade your account [here](https://dashboard.alchemyapi.io/settings/billing/).**
  --tokenUriTimeoutInMs: int # No set timeout by default - When metadata is requested, this parameter is the timeout (in milliseconds) for the website hosting the metadata to respond. If you want to _only_ access the cache and not live fetch any metadata for cache misses then set this value to 0.
  --pageKey: string # String - key for pagination. If more results are available, a pageKey will be returned in the response. Pass back the pageKey as a param to fetch the next page of results.
  --pageSize: int # Number of NFTs to be returned per page. Defaults to 100. Max is 100. (default: 100)
]: nothing -> record<ownedNfts: table<contract: record, tokenId: any, tokenType: any, name: string, description: string, image: record, raw: record, collection: record, tokenUri: string, timeLastUpdated: string, acquiredAt: record>, totalCount: int, pageKey: any, validAt: record<blockNumber: int, blockHash: string, blockTimestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "contractAddresses[]" $contractAddresses "multi") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "excludeFilters[]" $excludeFilters "multi") (serialize-qp "includeFilters[]" $includeFilters "multi") (serialize-qp "spamConfidenceLevel" $spamConfidenceLevel "scalar") (serialize-qp "tokenUriTimeoutInMs" $tokenUriTimeoutInMs "scalar") (serialize-qp "pageKey" $pageKey "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getNFTsForOwner" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NFTs By Contract
#
# GET /v3/{apiKey}/getNFTsForContract
# operationId: getNFTsForContract-v3
export def "get-nf-ts-for-contract get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --withMetadata: oneof<nothing, bool> # Boolean - if set to `true`, returns NFT metadata. Setting this to false will reduce payload size and may result in a faster API call. Defaults to `true`. (default: true)
  --startToken: string # String - A tokenID offset used for pagination. Can be a hex string, or a decimal. Users can specify the offset themselves to start from a custom offset, or to fetch multiple token ranges in parallel.
  --limit: int # Integer - Sets the total number of NFTs returned in the response. Defaults to 100.
  --tokenUriTimeoutInMs: int # No set timeout by default - When metadata is requested, this parameter is the timeout (in milliseconds) for the website hosting the metadata to respond. If you want to _only_ access the cache and not live fetch any metadata for cache misses then set this value to 0.
]: nothing -> record<nfts: table<contract: record, tokenId: any, tokenType: any, name: string, description: string, image: record, raw: record, collection: record, tokenUri: string, timeLastUpdated: string, acquiredAt: record>, pageKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "startToken" $startToken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "tokenUriTimeoutInMs" $tokenUriTimeoutInMs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getNFTsForContract" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NFTs By Collection
#
# GET /v3/{apiKey}/getNFTsForCollection
# operationId: getNFTsForCollection-v3
export def "get-nf-ts-for-collection get-by-apiKey" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --collectionSlug: string # String - OpenSea slug for the NFT collection. (default: boredapeyachtclub)
  --withMetadata: oneof<nothing, bool> # Boolean - if set to `true`, returns NFT metadata. Setting this to false will reduce payload size and may result in a faster API call. Defaults to `true`. (default: true)
  --startToken: string # String - A tokenID offset used for pagination. Can be a hex string, or a decimal. Users can specify the offset themselves to start from a custom offset, or to fetch multiple token ranges in parallel.
  --limit: int # Integer - Sets the total number of NFTs returned in the response. Defaults to 100.
  --tokenUriTimeoutInMs: int # No set timeout by default - When metadata is requested, this parameter is the timeout (in milliseconds) for the website hosting the metadata to respond. If you want to _only_ access the cache and not live fetch any metadata for cache misses then set this value to 0.
]: nothing -> record<nfts: table<id: record, tokenUri: record, metadata: record, timeLastUpdated: string, contractMetadata: record>, nextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "collectionSlug" $collectionSlug "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "startToken" $startToken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "tokenUriTimeoutInMs" $tokenUriTimeoutInMs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getNFTsForCollection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NFT Metadata By Token ID
#
# GET /v3/{apiKey}/getNFTMetadata
# operationId: getNFTMetadata-v3
export def "get-nft-metadata get-by-apiKey" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --tokenId: string # String - The ID of the token. Can be in hex or decimal format. (default: 44)
  --tokenType: string # String - 'ERC721' or 'ERC1155'; specifies type of token to query for. API requests will perform faster if this is specified.
  --tokenUriTimeoutInMs: int # No set timeout by default - When metadata is requested, this parameter is the timeout (in milliseconds) for the website hosting the metadata to respond. If you want to _only_ access the cache and not live fetch any metadata for cache misses then set this value to 0.
  --refreshCache: oneof<nothing, bool> # Defaults to false for faster response times.  If true will refresh metadata for given token. If false will check the cache and use it or refresh if cache doesn't exist. (default: false)
]: nothing -> record<contract: record<address: string, name: string, symbol: string, totalSupply: string, tokenType: string, contractDeployer: string, deployedBlockNumber: float, openseaMetadata: record<floorPrice: float, collectionName: string, safelistRequestStatus: string, imageUrl: string, description: string, externalUrl: string, twitterUsername: string, discordUrl: string, lastIngestedAt: string>, isSpam: string, spamClassifications: list<string>>, tokenId: any, tokenType: any, name: string, description: string, image: record<cachedUrl: string, thumbnailUrl: string, pngUrl: string, contentType: string, size: int, originalUrl: string>, raw: record<tokenUri: string, metadata: record<image: string, name: string, description: string, attributes: list>, error: string>, collection: record<name: any, slug: any, externalUrl: any, bannerImageUrl: any>, tokenUri: string, timeLastUpdated: string, acquiredAt: record<blockTimestamp: string, blockNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "tokenId" $tokenId "scalar") (serialize-qp "tokenType" $tokenType "scalar") (serialize-qp "tokenUriTimeoutInMs" $tokenUriTimeoutInMs "scalar") (serialize-qp "refreshCache" $refreshCache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getNFTMetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NFT Metadata By Token ID [Batch]
#
# POST /v3/{apiKey}/getNFTMetadataBatch
# operationId: getNFTMetadataBatch-v3
# --tokens item shape: {contractAddress?: any, tokenId?: any, tokenType?: any}
export def "get-nft-metadata-batch post-by-apiKey" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tokens: list # List of token objects to batch request NFT metadata for. Maximum 100. (default: [{contractAddress: 0xe785E82358879F061BC3dcAC6f0444462D4b5330, tokenId: 44, tokenType: ERC721}, {contractAddress: 0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d, tokenId: 888, tokenType: ERC721}]) — item shape: {contractAddress?: any, tokenId?: any, tokenType?: any}
  --tokenUriTimeoutInMs: any # No set timeout by default - When metadata is requested, this parameter is the timeout (in milliseconds) for the website hosting the metadata to respond. If you want to _only_ access the cache and not live fetch any metadata for cache misses then set this value to 0.
  --refreshCache: any # Defaults to false for faster response times.  If true will refresh metadata for given token. If false will check the cache and use it or refresh if cache doesn't exist.
]: any -> table<contract: record<address: string, name: string, symbol: string, totalSupply: string, tokenType: string, contractDeployer: string, deployedBlockNumber: float, openseaMetadata: record, isSpam: string, spamClassifications: list>, tokenId: any, tokenType: any, name: string, description: string, image: record<cachedUrl: string, thumbnailUrl: string, pngUrl: string, contentType: string, size: int, originalUrl: string>, raw: record<tokenUri: string, metadata: record, error: string>, collection: record<name: any, slug: any, externalUrl: any, bannerImageUrl: any>, tokenUri: string, timeLastUpdated: string, acquiredAt: record<blockTimestamp: string, blockNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($apiKey)/getNFTMetadataBatch")
  let body = {tokens: $tokens, tokenUriTimeoutInMs: $tokenUriTimeoutInMs, refreshCache: $refreshCache} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Contract Metadata By Address
#
# GET /v3/{apiKey}/getContractMetadata
# operationId: getContractMetadata-v3
export def "get-contract-metadata get-by-apiKey" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> record<address: string, name: string, symbol: string, totalSupply: string, tokenType: string, contractDeployer: string, deployedBlockNumber: float, openseaMetadata: record<floorPrice: float, collectionName: string, safelistRequestStatus: string, imageUrl: string, description: string, externalUrl: string, twitterUsername: string, discordUrl: string, lastIngestedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getContractMetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Collection Metadata By Slug
#
# GET /v3/{apiKey}/getCollectionMetadata
# operationId: getCollectionMetadata-v3
export def "get-collection-metadata get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --collectionSlug: string # String - OpenSea slug for the NFT collection. (default: boredapeyachtclub)
]: nothing -> record<name: string, slug: string, floorPrice: record<marketplace: string, floorPrice: float, priceCurrency: string>, description: string, externalUrl: string, twitterUsername: string, discordUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collectionSlug" $collectionSlug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getCollectionMetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invalidate Contract Cache
#
# GET /v3/{apiKey}/invalidateContract
# operationId: invalidateContract-v3
export def "invalidate-contract invalidateContract-v3" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> record<success: string, numTokensInvalidated: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/invalidateContract" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Contract Metadata By Address [Batch]
#
# POST /v3/{apiKey}/getContractMetadataBatch
# operationId: getContractMetadataBatch-v3
export def "get-contract-metadata-batch post-by-apiKey" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddresses: list # List of contract addresses to batch metadata requests for. (default: [0xe785E82358879F061BC3dcAC6f0444462D4b5330, 0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d])
]: any -> table<address: string, name: string, symbol: string, totalSupply: string, tokenType: string, contractDeployer: string, deployedBlockNumber: float, openseaMetadata: record<floorPrice: float, collectionName: string, safelistRequestStatus: string, imageUrl: string, description: string, externalUrl: string, twitterUsername: string, discordUrl: string, lastIngestedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($apiKey)/getContractMetadataBatch")
  let body = {contractAddresses: $contractAddresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Owners By NFT
#
# GET /v3/{apiKey}/getOwnersForNFT
# operationId: getOwnersForNFT-v3
export def "get-owners-for-nft get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --tokenId: string # String - The ID of the token. Can be in hex or decimal format. (default: 44)
]: nothing -> record<owners: list<string>, pageKey: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "tokenId" $tokenId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getOwnersForNFT" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Owners By Contract
#
# GET /v3/{apiKey}/getOwnersForContract
# operationId: getOwnersForContract-v3
export def "get-owners-for-contract get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --withTokenBalances: oneof<nothing, bool> # Boolean - If set to `true` the query will include the token balances per token id for each owner. `false` by default. (default: false)
  --pageKey: string # String - key for pagination. If more results are available, a pageKey will be returned in the response. Pass back the pageKey as a param to fetch the next page of results.
]: nothing -> record<owners: table<ownerAddress: any, tokenBalances: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "withTokenBalances" $withTokenBalances "scalar") (serialize-qp "pageKey" $pageKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getOwnersForContract" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Spam Contracts
#
# GET /v3/{apiKey}/getSpamContracts
# operationId: getSpamContracts-v3
export def "get-spam-contracts get-by-apiKey" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contractAddresses: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let full_url = (build-url $base $"/v3/($apiKey)/getSpamContracts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Is Spam Contract
#
# GET /v3/{apiKey}/isSpamContract
# operationId: isSpamContract-v3
export def "is-spam-contract isSpamContract-v3" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> record<isSpamContract: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/isSpamContract" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Is Airdrop NFT
#
# GET /v3/{apiKey}/isAirdropNFT
# operationId: isAirdropNFT-v3
export def "is-airdrop-nft isAirdropNFT-v3" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --tokenId: string # String - The ID of the token. Can be in hex or decimal format. (default: 44)
]: nothing -> record<isAirdrop: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "tokenId" $tokenId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/isAirdropNFT" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attributes Summary By Contract
#
# GET /v3/{apiKey}/summarizeNFTAttributes
# operationId: summarizeNFTAttributes-v3
export def "summarize-nft-attributes summarizeNFTAttributes-v3" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> record<totalSupply: string, summary: record, contractAddress: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/summarizeNFTAttributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Floor Prices By Slug
#
# GET /v3/{apiKey}/getFloorPrice
# operationId: getFloorPrice-v3
export def "get-floor-price get-by-apiKey" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --collectionSlug: string # String - OpenSea slug for the NFT collection. (default: boredapeyachtclub)
]: nothing -> record<nftMarketplaceName: record<floorPrice: float, priceCurrency: string, collectionUrl: string, retrievedAt: string, error: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "collectionSlug" $collectionSlug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getFloorPrice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Contract Metadata
#
# GET /v3/{apiKey}/searchContractMetadata
# operationId: searchContractMetadata-v3
export def "search-contract-metadata searchContractMetadata-v3" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # String - The search string that you want to search for in contract metadata (default: bored)
]: nothing -> table<address: string, name: string, symbol: string, totalSupply: string, tokenType: string, contractDeployer: string, deployedBlockNumber: float, openseaMetadata: record<floorPrice: float, collectionName: string, safelistRequestStatus: string, imageUrl: string, description: string, externalUrl: string, twitterUsername: string, discordUrl: string, lastIngestedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/searchContractMetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Is Holder Of Contract
#
# GET /v3/{apiKey}/isHolderOfContract
# operationId: isHolderOfContract-v3
export def "is-holder-of-contract isHolderOfContract-v3" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --wallet: string # String - Wallet address to check for contract ownership. (default: 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045)
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> record<isHolderOfContract: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wallet" $wallet "scalar") (serialize-qp "contractAddress" $contractAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/isHolderOfContract" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attribute Rarity By NFT
#
# GET /v3/{apiKey}/computeRarity
# operationId: computeRarity-v3
export def "compute-rarity computeRarity-v3" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --tokenId: string # String - The ID of the token. Can be in hex or decimal format. (default: 44)
]: nothing -> record<rarities: table<trait_type: string, value: string, prevalence: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "tokenId" $tokenId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/computeRarity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NFT Sales
#
# GET /v3/{apiKey}/getNFTSales
# operationId: getNFTSales-v3
export def "get-nft-sales get-by-apiKey" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromBlock: string # String - The block number to start fetching NFT sales data from. Allowed values are decimal and hex integers, and "latest". Defaults to "0". (default: 0)
  --toBlock: string # String - The block number to start fetching NFT sales data from. Allowed values are decimal and hex integers, and "latest". Defaults to "latest". (default: latest)
  --order: string@order-completer # Enum - Whether to return the results ascending from startBlock or descending from startBlock. Defaults to descending (false). (default: asc)
  --marketplace: string@marketplace-completer # Enum - The name of the NFT marketplace to filter sales by. The endpoint currently supports "seaport", "wyvern", "looksrare", "x2y2", "blur", and "cryptopunks". Defaults to returning sales from all supported marketplaces.
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --tokenId: string # String - The ID of the token. Can be in hex or decimal format. (default: 44)
  --buyerAddress: string # String - The address of the NFT buyer to filter sales by. Defaults to returning sales involving any buyer.
  --sellerAddress: string # String - The address of the NFT seller to filter sales by. Defaults to returning sales involving any seller.
  --taker: string@taker-completer # Enum - Filter by whether the buyer or seller was the taker in the NFT trade. Allowed filter values are "BUYER" and "SELLER". Defaults to returning both buyer and seller taker trades.
  --limit: int # Integer - Sets the total number of NFTs returned in the response. Defaults to 100.
  --pageKey: string # String - key for pagination. If more results are available, a pageKey will be returned in the response. Pass back the pageKey as a param to fetch the next page of results.
]: nothing -> record<nftSales: table<marketplace: string, marketplaceAddress: string, contractAddress: string, tokenId: string, quantity: string, buyerAddress: string, sellerAddress: string, taker: string, sellerFee: record, protocolFee: record, royaltyFee: record, blockNumber: int, logIndex: int, bundleIndex: int, transactionHash: string>, pageKey: string, validAt: record<blockNumber: int, blockHash: string, blockTimestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let qp = [(serialize-qp "fromBlock" $fromBlock "scalar") (serialize-qp "toBlock" $toBlock "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "marketplace" $marketplace "scalar") (serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "tokenId" $tokenId "scalar") (serialize-qp "buyerAddress" $buyerAddress "scalar") (serialize-qp "sellerAddress" $sellerAddress "scalar") (serialize-qp "taker" $taker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageKey" $pageKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getNFTSales" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Contracts By Owner
#
# GET /v3/{apiKey}/getContractsForOwner
# operationId: getContractsForOwner-v3
export def "get-contracts-for-owner get-by-apiKey" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string # String - Address for NFT owner (can be in ENS format for Eth Mainnet). (default: 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045)
  --pageKey: string # String - key for pagination. If more results are available, a pageKey will be returned in the response. Pass back the pageKey as a param to fetch the next page of results.
  --pageSize: int # Number of NFTs to be returned per page. Defaults to 100. Max is 100. (default: 100)
  --withMetadata: oneof<nothing, bool> # Boolean - if set to `true`, returns NFT metadata. Setting this to false will reduce payload size and may result in a faster API call. Defaults to `true`. (default: true)
  --includeFilters: list # Array of filters (as ENUMS) that will be applied to the query. Only NFTs that match one or more of these filters will be included in the response. May not be used in conjunction with excludeFilters[]. Filter Options:   - SPAM: NFTs that have been classified as spam. Spam classification has a wide range of criteria that includes but is not limited to emitting fake events and copying other well-known NFTs. Please note that this filter is **available exclusively on paid tiers**.   - AIRDROPS: NFTs that have were airdropped to the user. Airdrops are defined as NFTs that were minted to a user address in a transaction sent by a different address. NOTE: this filter is currently supported on Ethereum Mainnet, Ethereum Goerli, and Matic Mainnet only.   - To learn more about spam, you can refer to this: <span class="custom-style"><a href="https://www.alchemy.com/overviews/spam-nfts" target="_blank">Spam NFTs and how to fix them</a></span>
  --excludeFilters: list # Array of filters (as ENUMS) that will be applied to the query. NFTs that match one or more of these filters will be excluded from the response. May not be used in conjunction with includeFilters[]. Filter Options:   - SPAM: NFTs that have been classified as spam. Spam classification has a wide range of criteria that includes but is not limited to emitting fake events and copying other well-known NFTs. Please note that this filter is **available exclusively on paid tiers**.   - AIRDROPS: NFTs that have were airdropped to the user. Airdrops are defined as NFTs that were minted to a user address in a transaction sent by a different address. NOTE: this filter is currently supported on Ethereum Mainnet, Ethereum Goerli, and Matic Mainnet only.   - To learn more about spam, you can refer to this: <span class="custom-style"><a href="https://www.alchemy.com/overviews/spam-nfts" target="_blank">Spam NFTs and how to fix them</a></span>
  --orderBy: string@orderBy-completer # Enum - ordering scheme to use for ordering NFTs in the response. If unspecified, NFTs will be ordered by contract address and token ID.   - transferTime: NFTs will be ordered by the time they were transferred into the wallet, with newest NFTs first. NOTE: this ordering is only supported on Ethereum Mainnet and Polygon Mainnet.
  --spamConfidenceLevel: string@spamConfidenceLevel-completer # Enum - the confidence level at which to filter spam at.  Confidence Levels:   - VERY_HIGH   - HIGH   - MEDIUM   - LOW  The confidence level set means that any spam that is at that confidence level or higher will be filtered out. For example, if the confidence level is HIGH, contracts that we have HIGH or VERY_HIGH confidence in being spam will be filtered out from the response.  Defaults to VERY_HIGH for Ethereum Mainnet and MEDIUM for other networks.  **Please note that this filter is only available on paid tiers. Upgrade your account [here](https://dashboard.alchemyapi.io/settings/billing/).**
]: nothing -> record<contracts: table<address: any, name: string, symbol: string, totalSupply: string, tokenType: any, contractDeployer: string, deployedBlockNumber: float, openseaMetadata: record, totalBalance: float, numDistinctTokensOwned: float, isSpam: bool, displayNft: record, image: record>, pageKey: any, totalCount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "pageKey" $pageKey "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "includeFilters[]" $includeFilters "multi") (serialize-qp "excludeFilters[]" $excludeFilters "multi") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "spamConfidenceLevel" $spamConfidenceLevel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getContractsForOwner" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Collections By Owner
#
# GET /v3/{apiKey}/getCollectionsForOwner
# operationId: getCollectionsForOwner-v3
export def "get-collections-for-owner get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string # String - Address for NFT owner (can be in ENS format for Eth Mainnet). (default: 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045)
  --pageKey: string # String - key for pagination. If more results are available, a pageKey will be returned in the response. Pass back the pageKey as a param to fetch the next page of results.
  --pageSize: int # Number of NFTs to be returned per page. Defaults to 100. Max is 100. (default: 100)
  --withMetadata: oneof<nothing, bool> # Boolean - if set to `true`, returns NFT metadata. Setting this to false will reduce payload size and may result in a faster API call. Defaults to `true`. (default: true)
  --includeFilters: list # Array of filters (as ENUMS) that will be applied to the query. Only NFTs that match one or more of these filters will be included in the response. May not be used in conjunction with excludeFilters[]. Filter Options:   - SPAM: NFTs that have been classified as spam. Spam classification has a wide range of criteria that includes but is not limited to emitting fake events and copying other well-known NFTs. Please note that this filter is **available exclusively on paid tiers**.   - AIRDROPS: NFTs that have were airdropped to the user. Airdrops are defined as NFTs that were minted to a user address in a transaction sent by a different address. NOTE: this filter is currently supported on Ethereum Mainnet, Ethereum Goerli, and Matic Mainnet only.   - To learn more about spam, you can refer to this: <span class="custom-style"><a href="https://www.alchemy.com/overviews/spam-nfts" target="_blank">Spam NFTs and how to fix them</a></span>
  --excludeFilters: list # Array of filters (as ENUMS) that will be applied to the query. NFTs that match one or more of these filters will be excluded from the response. May not be used in conjunction with includeFilters[]. Filter Options:   - SPAM: NFTs that have been classified as spam. Spam classification has a wide range of criteria that includes but is not limited to emitting fake events and copying other well-known NFTs. Please note that this filter is **available exclusively on paid tiers**.   - AIRDROPS: NFTs that have were airdropped to the user. Airdrops are defined as NFTs that were minted to a user address in a transaction sent by a different address. NOTE: this filter is currently supported on Ethereum Mainnet, Ethereum Goerli, and Matic Mainnet only.   - To learn more about spam, you can refer to this: <span class="custom-style"><a href="https://www.alchemy.com/overviews/spam-nfts" target="_blank">Spam NFTs and how to fix them</a></span>
]: nothing -> record<collections: table<name: string, slug: string, floorPrice: record, description: string, externalUrl: string, twitterUsername: string, discordUrl: string, contract: record, totalBalance: float, numDistinctTokensOwned: float, isSpam: string, displayNft: record, image: record>, pageKey: any, totalCount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "pageKey" $pageKey "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "includeFilters[]" $includeFilters "multi") (serialize-qp "excludeFilters[]" $excludeFilters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/getCollectionsForOwner" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Report Spam Address
#
# GET /v3/{apiKey}/reportSpam
# operationId: reportSpam-v3
export def "report-spam reportSpam-v3" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # String - any valid blockchain address for NFT collections, contracts, mints, etc. (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/($apiKey)/reportSpam" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refresh NFT Metadata
#
# POST /v3/{apiKey}/refreshNftMetadata
# operationId: refreshNftMetadata-v3
export def "refresh-nft-metadata refreshNftMetadata-v3" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: any # String - Contract address for the NFT contract (ERC721 and ERC1155 supported).
  --tokenId: any # String - The ID of the token. Can be in hex or decimal format.
]: any -> record<status: string, estimatedMsToRefresh: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/($apiKey)/refreshNftMetadata")
  let body = {contractAddress: $contractAddress, tokenId: $tokenId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getNFTs
#
# GET /v2/{apiKey}/getNFTs
# operationId: getNFTs
export def "get-nf-ts get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string # String - Address for NFT owner (can be in ENS format for Eth Mainnet). (default: 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045)
  --contractAddresses: list # Array of contract addresses to filter the responses with. Max limit 45 contracts.
  --withMetadata: oneof<nothing, bool> # Boolean - if set to `true`, returns NFT metadata. Setting this to false will reduce payload size and may result in a faster API call. Defaults to `true`. (default: true)
  --orderBy: string@orderBy-completer # Enum - ordering scheme to use for ordering NFTs in the response. If unspecified, NFTs will be ordered by contract address and token ID.   - transferTime: NFTs will be ordered by the time they were transferred into the wallet, with newest NFTs first. NOTE: this ordering is only supported on Ethereum Mainnet and Polygon Mainnet.
  --excludeFilters: list # Array of filters (as ENUMS) that will be applied to the query. NFTs that match one or more of these filters will be excluded from the response. May not be used in conjunction with includeFilters[]. Filter Options:   - SPAM: NFTs that have been classified as spam. Spam classification has a wide range of criteria that includes but is not limited to emitting fake events and copying other well-known NFTs. Please note that this filter is **available exclusively on paid tiers**.   - AIRDROPS: NFTs that have were airdropped to the user. Airdrops are defined as NFTs that were minted to a user address in a transaction sent by a different address. NOTE: this filter is currently supported on Ethereum Mainnet, Ethereum Goerli, and Matic Mainnet only.   - To learn more about spam, you can refer to this: <span class="custom-style"><a href="https://www.alchemy.com/overviews/spam-nfts" target="_blank">Spam NFTs and how to fix them</a></span>
  --includeFilters: list # Array of filters (as ENUMS) that will be applied to the query. Only NFTs that match one or more of these filters will be included in the response. May not be used in conjunction with excludeFilters[]. Filter Options:   - SPAM: NFTs that have been classified as spam. Spam classification has a wide range of criteria that includes but is not limited to emitting fake events and copying other well-known NFTs. Please note that this filter is **available exclusively on paid tiers**.   - AIRDROPS: NFTs that have were airdropped to the user. Airdrops are defined as NFTs that were minted to a user address in a transaction sent by a different address. NOTE: this filter is currently supported on Ethereum Mainnet, Ethereum Goerli, and Matic Mainnet only.   - To learn more about spam, you can refer to this: <span class="custom-style"><a href="https://www.alchemy.com/overviews/spam-nfts" target="_blank">Spam NFTs and how to fix them</a></span>
  --spamConfidenceLevel: string@spamConfidenceLevel-completer # Enum - the confidence level at which to filter spam at.  Confidence Levels:   - VERY_HIGH   - HIGH   - MEDIUM   - LOW  The confidence level set means that any spam that is at that confidence level or higher will be filtered out. For example, if the confidence level is HIGH, contracts that we have HIGH or VERY_HIGH confidence in being spam will be filtered out from the response.  Defaults to VERY_HIGH for Ethereum Mainnet and MEDIUM for other networks.  **Please note that this filter is only available on paid tiers. Upgrade your account [here](https://dashboard.alchemyapi.io/settings/billing/).**
  --tokenUriTimeoutInMs: int # No set timeout by default - When metadata is requested, this parameter is the timeout (in milliseconds) for the website hosting the metadata to respond. If you want to _only_ access the cache and not live fetch any metadata for cache misses then set this value to 0.
  --pageKey: string # String - key for pagination. If more results are available, a pageKey will be returned in the response. Pass back the pageKey as a param to fetch the next page of results.
  --pageSize: int # Number of NFTs to be returned per page. Defaults to 100. Max is 100. (default: 100)
]: nothing -> record<ownedNfts: table<contract: record, id: record, balance: string, title: string, description: string, tokenUri: record, media: record, metadata: record, timeLastUpdated: string, error: string, contractMetadata: record, spamInfo: record, acquiredAt: record>, pageKey: any, totalCount: int, blockHash: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "contractAddresses[]" $contractAddresses "multi") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "excludeFilters[]" $excludeFilters "multi") (serialize-qp "includeFilters[]" $includeFilters "multi") (serialize-qp "spamConfidenceLevel" $spamConfidenceLevel "scalar") (serialize-qp "tokenUriTimeoutInMs" $tokenUriTimeoutInMs "scalar") (serialize-qp "pageKey" $pageKey "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/getNFTs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNFTMetadata
#
# GET /v2/{apiKey}/getNFTMetadata
# operationId: getNFTMetadata
export def "get-nft-metadata get-by-apiKey-1" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --tokenId: string # String - The ID of the token. Can be in hex or decimal format. (default: 44)
  --tokenType: string # String - 'ERC721' or 'ERC1155'; specifies type of token to query for. API requests will perform faster if this is specified.
  --tokenUriTimeoutInMs: int # No set timeout by default - When metadata is requested, this parameter is the timeout (in milliseconds) for the website hosting the metadata to respond. If you want to _only_ access the cache and not live fetch any metadata for cache misses then set this value to 0.
  --refreshCache: oneof<nothing, bool> # Defaults to false for faster response times.  If true will refresh metadata for given token. If false will check the cache and use it or refresh if cache doesn't exist. (default: false)
]: nothing -> record<contract: record<address: string>, id: record<tokenId: any, tokenMetadata: record<tokenType: string>>, balance: string, title: string, description: string, tokenUri: record<raw: string, gateway: string>, media: record<raw: string, gateway: string, thumbnail: string, format: string, bytes: int>, metadata: record<image: string, external_url: string, background_color: string, name: string, description: string, attributes: list<record>, media: list<record>>, timeLastUpdated: string, error: string, contractMetadata: record<name: string, symbol: string, totalSupply: string, tokenType: string, contractDeployer: string, deployedBlockNumber: float, opensea: record<floorPrice: float, collectionName: string, safelistRequestStatus: string, imageUrl: string, description: string, externalUrl: string, twitterUsername: string, discordUrl: string, lastIngestedAt: string>>, spamInfo: record<description: any, isSpam: string, spamClassifications: list<string>>, acquiredAt: record<blockTimestamp: string, blockNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "tokenId" $tokenId "scalar") (serialize-qp "tokenType" $tokenType "scalar") (serialize-qp "tokenUriTimeoutInMs" $tokenUriTimeoutInMs "scalar") (serialize-qp "refreshCache" $refreshCache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/getNFTMetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNFTMetadataBatch
#
# POST /v2/{apiKey}/getNFTMetadataBatch
# operationId: getNFTMetadataBatch
# --tokens item shape: {contractAddress?: any, tokenId?: any, tokenType?: any}
export def "get-nft-metadata-batch post-by-apiKey-1" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tokens: list # List of token objects to batch request NFT metadata for. Maximum 100. — item shape: {contractAddress?: any, tokenId?: any, tokenType?: any}
  --tokenUriTimeoutInMs: any # No set timeout by default - When metadata is requested, this parameter is the timeout (in milliseconds) for the website hosting the metadata to respond. If you want to _only_ access the cache and not live fetch any metadata for cache misses then set this value to 0.
  --refreshCache: any # Defaults to false for faster response times.  If true will refresh metadata for given token. If false will check the cache and use it or refresh if cache doesn't exist.
]: any -> table<contract: record<address: string>, id: record<tokenId: any, tokenMetadata: record>, balance: string, title: string, description: string, tokenUri: record<raw: string, gateway: string>, media: record<raw: string, gateway: string, thumbnail: string, format: string, bytes: int>, metadata: record<image: string, external_url: string, background_color: string, name: string, description: string, attributes: list, media: list>, timeLastUpdated: string, error: string, contractMetadata: record<name: string, symbol: string, totalSupply: string, tokenType: string, contractDeployer: string, deployedBlockNumber: float, opensea: record>, spamInfo: record<description: any, isSpam: string, spamClassifications: list>, acquiredAt: record<blockTimestamp: string, blockNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($apiKey)/getNFTMetadataBatch")
  let body = {tokens: $tokens, tokenUriTimeoutInMs: $tokenUriTimeoutInMs, refreshCache: $refreshCache} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getContractMetadata
#
# GET /v2/{apiKey}/getContractMetadata
# operationId: getContractMetadata
export def "get-contract-metadata get-by-apiKey-1" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> record<address: string, contractMetadata: record<name: string, symbol: string, totalSupply: string, tokenType: string, contractDeployer: string, deployedBlockNumber: float, opensea: record<floorPrice: float, collectionName: string, safelistRequestStatus: string, imageUrl: string, description: string, externalUrl: string, twitterUsername: string, discordUrl: string, lastIngestedAt: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/getContractMetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getContractMetadataBatch
#
# POST /v2/{apiKey}/getContractMetadataBatch
# operationId: getContractMetadataBatch
export def "get-contract-metadata-batch post-by-apiKey-1" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddresses: list # list of contract addresses to batch metadata requests for (default: [0xe785E82358879F061BC3dcAC6f0444462D4b5330, 0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d])
]: any -> table<address: any, contractMetadata: record<address: string, totalBalance: float, numDistinctTokensOwned: float, isSpam: bool, tokenId: string, name: string, title: string, symbol: string, tokenType: string, contractDeployer: string, deployedBlockNumber: float, media: list, opensea: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($apiKey)/getContractMetadataBatch")
  let body = {contractAddresses: $contractAddresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getNFTsForCollection
#
# GET /v2/{apiKey}/getNFTsForCollection
# operationId: getNFTsForCollection
export def "get-nf-ts-for-collection get-by-apiKey-1" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --collectionSlug: string # String - OpenSea slug for the NFT collection. (default: boredapeyachtclub)
  --withMetadata: oneof<nothing, bool> # Boolean - if set to `true`, returns NFT metadata. Setting this to false will reduce payload size and may result in a faster API call. Defaults to `true`. (default: true)
  --startToken: string # String - A tokenID offset used for pagination. Can be a hex string, or a decimal. Users can specify the offset themselves to start from a custom offset, or to fetch multiple token ranges in parallel.
  --limit: int # Integer - Sets the total number of NFTs returned in the response. Defaults to 100.
  --tokenUriTimeoutInMs: int # No set timeout by default - When metadata is requested, this parameter is the timeout (in milliseconds) for the website hosting the metadata to respond. If you want to _only_ access the cache and not live fetch any metadata for cache misses then set this value to 0.
]: nothing -> record<nfts: table<id: record, tokenUri: record, metadata: record, timeLastUpdated: string, contractMetadata: record>, nextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "collectionSlug" $collectionSlug "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "startToken" $startToken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "tokenUriTimeoutInMs" $tokenUriTimeoutInMs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/getNFTsForCollection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getOwnersForToken
#
# GET /v2/{apiKey}/getOwnersForToken
# operationId: getOwnersForToken
export def "get-owners-for-token get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --tokenId: string # String - The ID of the token. Can be in hex or decimal format. (default: 44)
  --pageKey: string # String - key for pagination. If more results are available, a pageKey will be returned in the response. Pass back the pageKey as a param to fetch the next page of results.
  --pageSize: int # Number of owners to be returned per page.
]: nothing -> record<owners: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "tokenId" $tokenId "scalar") (serialize-qp "pageKey" $pageKey "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/getOwnersForToken" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getOwnersForCollection
#
# GET /v2/{apiKey}/getOwnersForCollection
# operationId: getOwnersForCollection
export def "get-owners-for-collection get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --withTokenBalances: oneof<nothing, bool> # Boolean - If set to `true` the query will include the token balances per token id for each owner. `false` by default. (default: false)
  --pageKey: string # String - key for pagination. If more results are available, a pageKey will be returned in the response. Pass back the pageKey as a param to fetch the next page of results.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "withTokenBalances" $withTokenBalances "scalar") (serialize-qp "pageKey" $pageKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/getOwnersForCollection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getSpamContracts
#
# GET /v2/{apiKey}/getSpamContracts
# operationId: getSpamContracts
export def "get-spam-contracts get-by-apiKey-1" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contractAddresses: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let full_url = (build-url $base $"/v2/($apiKey)/getSpamContracts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# isSpamContract
#
# GET /v2/{apiKey}/isSpamContract
# operationId: isSpamContract
export def "is-spam-contract isSpamContract" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/isSpamContract" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# isAirdrop
#
# GET /v2/{apiKey}/isAirdrop
# operationId: isAirdrop
export def "is-airdrop isAirdrop" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --tokenId: string # String - The ID of the token. Can be in hex or decimal format. (default: 44)
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "tokenId" $tokenId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/isAirdrop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invalidateContract
#
# GET /v2/{apiKey}/invalidateContract
# operationId: invalidateContract
export def "invalidate-contract invalidateContract" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> record<success: string, numTokensInvalidated: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/invalidateContract" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getFloorPrice
#
# GET /v2/{apiKey}/getFloorPrice
# operationId: getFloorPrice
export def "get-floor-price get-by-apiKey-1" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> record<nftMarketplace: record<floorPrice: float, priceCurrency: string, collectionUrl: string, retrievedAt: string, error: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/getFloorPrice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# computeRarity
#
# GET /v2/{apiKey}/computeRarity
# operationId: computeRarity
export def "compute-rarity computeRarity" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --tokenId: string # String - The ID of the token. Can be in hex or decimal format. (default: 44)
]: nothing -> record<rarities: table<trait_type: string, value: string, prevalence: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "tokenId" $tokenId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/computeRarity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# searchContractMetadata
#
# GET /v2/{apiKey}/searchContractMetadata
# operationId: searchContractMetadata
export def "search-contract-metadata searchContractMetadata" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # String - The search string that you want to search for in contract metadata (default: bored)
]: nothing -> table<address: any, contractMetadata: record<name: string, symbol: string, totalSupply: string, tokenType: string, contractDeployer: string, deployedBlockNumber: float, opensea: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/searchContractMetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# summarizeNFTAttributes
#
# GET /v2/{apiKey}/summarizeNFTAttributes
# operationId: summarizeNFTAttributes
export def "summarize-nft-attributes summarizeNFTAttributes" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> record<totalSupply: string, summary: record, contractAddress: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let qp = [(serialize-qp "contractAddress" $contractAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/summarizeNFTAttributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# isHolderOfCollection
#
# GET /v2/{apiKey}/isHolderOfCollection
# operationId: isHolderOfCollection
export def "is-holder-of-collection isHolderOfCollection" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --wallet: string # String - Wallet address to check for contract ownership. (default: 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045)
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> record<isHolderOfCollection: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wallet" $wallet "scalar") (serialize-qp "contractAddress" $contractAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/isHolderOfCollection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getNFTSales
#
# GET /v2/{apiKey}/getNFTSales
# operationId: getNFTSales
export def "get-nft-sales get-by-apiKey-1" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromBlock: string # String - The block number to start fetching NFT sales data from. Allowed values are decimal and hex integers, and "latest". Defaults to "0". (default: 0)
  --toBlock: string # String - The block number to start fetching NFT sales data from. Allowed values are decimal and hex integers, and "latest". Defaults to "latest". (default: latest)
  --order: string@order-completer # Enum - Whether to return the results ascending from startBlock or descending from startBlock. Defaults to descending (false). (default: asc)
  --marketplace: string@marketplace-completer # Enum - The name of the NFT marketplace to filter sales by. The endpoint currently supports "seaport", "wyvern", "looksrare", "x2y2", "blur", and "cryptopunks". Defaults to returning sales from all supported marketplaces.
  --contractAddress: string # String - Contract address for the NFT contract (ERC721 and ERC1155 supported). (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
  --tokenId: string # String - The ID of the token. Can be in hex or decimal format. (default: 44)
  --buyerAddress: string # String - The address of the NFT buyer to filter sales by. Defaults to returning sales involving any buyer.
  --sellerAddress: string # String - The address of the NFT seller to filter sales by. Defaults to returning sales involving any seller.
  --taker: string@taker-completer # Enum - Filter by whether the buyer or seller was the taker in the NFT trade. Allowed filter values are "BUYER" and "SELLER". Defaults to returning both buyer and seller taker trades.
  --limit: int # Integer - Sets the total number of NFTs returned in the response. Defaults to 100.
  --pageKey: string # String - key for pagination. If more results are available, a pageKey will be returned in the response. Pass back the pageKey as a param to fetch the next page of results.
]: nothing -> record<nftSales: table<marketplace: string, contractAddress: string, tokenId: string, quantity: string, buyerAddress: string, sellerAddress: string, taker: string, sellerFee: record, protocolFee: record, royaltyFee: record, blockNumber: int, logIndex: int, bundleIndex: int, transactionHash: string>, pageKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{network}.g.alchemy.com/nft")
  let qp = [(serialize-qp "fromBlock" $fromBlock "scalar") (serialize-qp "toBlock" $toBlock "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "marketplace" $marketplace "scalar") (serialize-qp "contractAddress" $contractAddress "scalar") (serialize-qp "tokenId" $tokenId "scalar") (serialize-qp "buyerAddress" $buyerAddress "scalar") (serialize-qp "sellerAddress" $sellerAddress "scalar") (serialize-qp "taker" $taker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageKey" $pageKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/getNFTSales" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getContractsForOwner
#
# GET /v2/{apiKey}/getContractsForOwner
# operationId: getContractsForOwner
export def "get-contracts-for-owner get-by-apiKey-1" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string # String - Address for NFT owner (can be in ENS format for Eth Mainnet). (default: 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045)
  --pageKey: string # String - key for pagination. If more results are available, a pageKey will be returned in the response. Pass back the pageKey as a param to fetch the next page of results.
  --pageSize: int # Number of NFTs to be returned per page. Defaults to 100. Max is 100. (default: 100)
  --withMetadata: oneof<nothing, bool> # Boolean - if set to `true`, returns NFT metadata. Setting this to false will reduce payload size and may result in a faster API call. Defaults to `true`. (default: true)
  --includeFilters: list # Array of filters (as ENUMS) that will be applied to the query. Only NFTs that match one or more of these filters will be included in the response. May not be used in conjunction with excludeFilters[]. Filter Options:   - SPAM: NFTs that have been classified as spam. Spam classification has a wide range of criteria that includes but is not limited to emitting fake events and copying other well-known NFTs. Please note that this filter is **available exclusively on paid tiers**.   - AIRDROPS: NFTs that have were airdropped to the user. Airdrops are defined as NFTs that were minted to a user address in a transaction sent by a different address. NOTE: this filter is currently supported on Ethereum Mainnet, Ethereum Goerli, and Matic Mainnet only.   - To learn more about spam, you can refer to this: <span class="custom-style"><a href="https://www.alchemy.com/overviews/spam-nfts" target="_blank">Spam NFTs and how to fix them</a></span>
  --excludeFilters: list # Array of filters (as ENUMS) that will be applied to the query. NFTs that match one or more of these filters will be excluded from the response. May not be used in conjunction with includeFilters[]. Filter Options:   - SPAM: NFTs that have been classified as spam. Spam classification has a wide range of criteria that includes but is not limited to emitting fake events and copying other well-known NFTs. Please note that this filter is **available exclusively on paid tiers**.   - AIRDROPS: NFTs that have were airdropped to the user. Airdrops are defined as NFTs that were minted to a user address in a transaction sent by a different address. NOTE: this filter is currently supported on Ethereum Mainnet, Ethereum Goerli, and Matic Mainnet only.   - To learn more about spam, you can refer to this: <span class="custom-style"><a href="https://www.alchemy.com/overviews/spam-nfts" target="_blank">Spam NFTs and how to fix them</a></span>
  --orderBy: string@orderBy-completer # Enum - ordering scheme to use for ordering NFTs in the response. If unspecified, NFTs will be ordered by contract address and token ID.   - transferTime: NFTs will be ordered by the time they were transferred into the wallet, with newest NFTs first. NOTE: this ordering is only supported on Ethereum Mainnet and Polygon Mainnet.
  --spamConfidenceLevel: string@spamConfidenceLevel-completer # Enum - the confidence level at which to filter spam at.  Confidence Levels:   - VERY_HIGH   - HIGH   - MEDIUM   - LOW  The confidence level set means that any spam that is at that confidence level or higher will be filtered out. For example, if the confidence level is HIGH, contracts that we have HIGH or VERY_HIGH confidence in being spam will be filtered out from the response.  Defaults to VERY_HIGH for Ethereum Mainnet and MEDIUM for other networks.  **Please note that this filter is only available on paid tiers. Upgrade your account [here](https://dashboard.alchemyapi.io/settings/billing/).**
]: nothing -> record<contracts: table<address: string, totalBalance: float, numDistinctTokensOwned: float, isSpam: bool, tokenId: string, name: string, title: string, symbol: string, tokenType: string, contractDeployer: string, deployedBlockNumber: float, media: list, opensea: record>, pageKey: any, totalCount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "pageKey" $pageKey "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "includeFilters[]" $includeFilters "multi") (serialize-qp "excludeFilters[]" $excludeFilters "multi") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "spamConfidenceLevel" $spamConfidenceLevel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/getContractsForOwner" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# reportSpam
#
# GET /v2/{apiKey}/reportSpam
# operationId: reportSpam
export def "report-spam reportSpam" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # String - any valid blockchain address for NFT collections, contracts, mints, etc. (default: 0xe785E82358879F061BC3dcAC6f0444462D4b5330)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($apiKey)/reportSpam" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
