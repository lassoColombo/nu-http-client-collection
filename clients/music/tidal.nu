# Auto-generated client for TIDAL API v1.10.33
# Source: https://tidal-music.github.io/tidal-api-reference/tidal-api-oas.json
# Auth: --token flag or $env.TIDAL_API_TOKEN

const BASE_URL = "https://openapi.tidal.com/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TIDAL_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://openapi.tidal.com/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def collapseBy-completer [] { ["FINGERPRINT" "NONE"] }
def deviceType-completer [] { ["BROWSER" "CAR" "DESKTOP" "PHONE" "TABLET" "TV"] }
def systemType-completer [] { ["ANDROID" "DESKTOP" "IOS" "TESLA" "WEB"] }
def stats-completer [] { ["ALL" "COUNTS_BY_TYPE" "TOTAL_COUNT"] }
def explicitFilter-completer [] { ["EXCLUDE" "INCLUDE"] }
def usage-completer [] { ["DOWNLOAD" "PLAYBACK"] }
def manifestType-completer [] { ["HLS" "MPEG_DASH"] }
def uriScheme-completer [] { ["DATA" "HTTPS"] }
def collectionView-completer [] { ["FLAT" "FOLDERS"] }
def collectionView-completer-1 [] { ["FOLDERS"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accepted-terms get" } } | get name | first)
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

# Get multiple acceptedTerms.
#
# GET /acceptedTerms
export def "accepted-terms get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners, terms (e.g. owners)
  --filterownersid: list # User id. Use `me` for the authenticated user
  --filtertermsisLatestVersion: list # Filter by terms.isLatestVersion
  --filtertermstermsType: list # One of: DEVELOPER, UPLOAD_MARKETPLACE (e.g. `DEVELOPER`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi") (serialize-qp "filter[terms.isLatestVersion]" $filtertermsisLatestVersion "multi") (serialize-qp "filter[terms.termsType]" $filtertermstermsType "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/acceptedTerms" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single acceptedTerm.
#
# POST /acceptedTerms
export def "accepted-terms post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/acceptedTerms")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /acceptedTerms/{id}/relationships/owners
export def "accepted-terms-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/acceptedTerms/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get terms relationship ("to-one").
#
# GET /acceptedTerms/{id}/relationships/terms
export def "accepted-terms-relationships-terms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: terms (e.g. terms)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/acceptedTerms/($id)/relationships/terms" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single albumStatistic.
#
# GET /albumStatistics/{id}
export def "album-statistics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/albumStatistics/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /albumStatistics/{id}/relationships/owners
export def "album-statistics-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albumStatistics/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple albums.
#
# GET /albums
export def "albums list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albumStatistics, artists, coverArt, genres, items, owners, priceConfig, providers, replacement, shares, similarAlbums, suggestedCoverArts, usageRules (e.g. albumStatistics)
  --filterbarcodeId: list # List of barcode IDs (EAN-13 or UPC-A). NOTE: Supplying more than one barcode ID will currently only return one album per barcode ID. (e.g. `196589525444`)
  --filterid: list # List of album IDs (e.g. `251380836`)
  --filterownersid: list # User id. Use `me` for the authenticated user
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[barcodeId]" $filterbarcodeId "multi") (serialize-qp "filter[id]" $filterid "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/albums" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single album.
#
# POST /albums
export def "albums post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/albums")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete single album.
#
# DELETE /albums/{id}
export def "albums delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/albums/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single album.
#
# GET /albums/{id}
export def "albums get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albumStatistics, artists, coverArt, genres, items, owners, priceConfig, providers, replacement, shares, similarAlbums, suggestedCoverArts, usageRules (e.g. albumStatistics)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single album.
#
# PATCH /albums/{id}
export def "albums patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/albums/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get albumStatistics relationship ("to-one").
#
# GET /albums/{id}/relationships/albumStatistics
export def "albums-relationships-album-statistics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: albumStatistics (e.g. albumStatistics)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/albumStatistics" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get artists relationship ("to-many").
#
# GET /albums/{id}/relationships/artists
export def "albums-relationships-artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: artists (e.g. artists)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/artists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get coverArt relationship ("to-many").
#
# GET /albums/{id}/relationships/coverArt
export def "albums-relationships-cover-art get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: coverArt (e.g. coverArt)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/coverArt" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update coverArt relationship ("to-many").
#
# PATCH /albums/{id}/relationships/coverArt
export def "albums-relationships-cover-art patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/albums/($id)/relationships/coverArt")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get genres relationship ("to-many").
#
# GET /albums/{id}/relationships/genres
export def "albums-relationships-genres get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: genres (e.g. genres)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/genres" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get items relationship ("to-many").
#
# GET /albums/{id}/relationships/items
export def "albums-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update items relationship ("to-many").
#
# PATCH /albums/{id}/relationships/items
export def "albums-relationships-items patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/albums/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /albums/{id}/relationships/owners
export def "albums-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get priceConfig relationship ("to-one").
#
# GET /albums/{id}/relationships/priceConfig
export def "albums-relationships-price-config get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: priceConfig (e.g. priceConfig)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/priceConfig" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get providers relationship ("to-many").
#
# GET /albums/{id}/relationships/providers
export def "albums-relationships-providers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: providers (e.g. providers)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/providers" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get replacement relationship ("to-one").
#
# GET /albums/{id}/relationships/replacement
export def "albums-relationships-replacement get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: replacement (e.g. replacement)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/replacement" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get shares relationship ("to-many").
#
# GET /albums/{id}/relationships/shares
export def "albums-relationships-shares get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: shares (e.g. shares)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/shares" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get similarAlbums relationship ("to-many").
#
# GET /albums/{id}/relationships/similarAlbums
export def "albums-relationships-similar-albums get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: similarAlbums (e.g. similarAlbums)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/similarAlbums" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get suggestedCoverArts relationship ("to-many").
#
# GET /albums/{id}/relationships/suggestedCoverArts
export def "albums-relationships-suggested-cover-arts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: suggestedCoverArts (e.g. suggestedCoverArts)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/suggestedCoverArts" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get usageRules relationship ("to-one").
#
# GET /albums/{id}/relationships/usageRules
export def "albums-relationships-usage-rules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: usageRules (e.g. usageRules)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/albums/($id)/relationships/usageRules" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single appreciation.
#
# POST /appreciations
export def "appreciations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/appreciations")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single artistBiographie.
#
# GET /artistBiographies/{id}
export def "artist-biographies get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artistBiographies/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single artistBiographie.
#
# PATCH /artistBiographies/{id}
export def "artist-biographies patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artistBiographies/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /artistBiographies/{id}/relationships/owners
export def "artist-biographies-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artistBiographies/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple artistClaims.
#
# GET /artistClaims
export def "artist-claims list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: acceptedArtists, owners, recommendedArtists (e.g. acceptedArtists)
  --filterownersid: list # User id. Use `me` for the authenticated user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/artistClaims" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single artistClaim.
#
# POST /artistClaims
export def "artist-claims post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/artistClaims" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete single artistClaim.
#
# DELETE /artistClaims/{id}
export def "artist-claims delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artistClaims/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single artistClaim.
#
# GET /artistClaims/{id}
export def "artist-claims get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: acceptedArtists, owners, recommendedArtists (e.g. acceptedArtists)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artistClaims/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single artistClaim.
#
# PATCH /artistClaims/{id}
export def "artist-claims patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artistClaims/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get acceptedArtists relationship ("to-many").
#
# GET /artistClaims/{id}/relationships/acceptedArtists
export def "artist-claims-relationships-accepted-artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: acceptedArtists (e.g. acceptedArtists)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artistClaims/($id)/relationships/acceptedArtists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update acceptedArtists relationship ("to-many").
#
# PATCH /artistClaims/{id}/relationships/acceptedArtists
export def "artist-claims-relationships-accepted-artists patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artistClaims/($id)/relationships/acceptedArtists" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /artistClaims/{id}/relationships/owners
export def "artist-claims-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artistClaims/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get recommendedArtists relationship ("to-many").
#
# GET /artistClaims/{id}/relationships/recommendedArtists
export def "artist-claims-relationships-recommended-artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: recommendedArtists (e.g. recommendedArtists)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artistClaims/($id)/relationships/recommendedArtists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single artistRole.
#
# GET /artistRoles/{id}
export def "artist-roles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artistRoles/($id)")
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple artists.
#
# GET /artists
export def "artists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums, biography, followers, following, owners, profileArt, radio, roles, similarArtists, trackProviders, tracks, videos (e.g. albums)
  --filterhandle: list # Artist handle (e.g. `jayz`)
  --filterid: list # List of artist IDs (e.g. `1566`)
  --filterownersid: list # User id. Use `me` for the authenticated user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[handle]" $filterhandle "multi") (serialize-qp "filter[id]" $filterid "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/artists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single artist.
#
# POST /artists
export def "artists post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/artists")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single artist.
#
# GET /artists/{id}
export def "artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums, biography, followers, following, owners, profileArt, radio, roles, similarArtists, trackProviders, tracks, videos (e.g. albums)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single artist.
#
# PATCH /artists/{id}
export def "artists patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artists/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get albums relationship ("to-many").
#
# GET /artists/{id}/relationships/albums
export def "artists-relationships-albums get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums (e.g. albums)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/albums" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get biography relationship ("to-one").
#
# GET /artists/{id}/relationships/biography
export def "artists-relationships-biography get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: biography (e.g. biography)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/biography" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get followers relationship ("to-many").
#
# GET /artists/{id}/relationships/followers
export def "artists-relationships-followers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --viewerContext: string
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: followers (e.g. followers)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "viewerContext" $viewerContext "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/followers" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from following relationship ("to-many").
#
# DELETE /artists/{id}/relationships/following
export def "artists-relationships-following delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artists/($id)/relationships/following")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get following relationship ("to-many").
#
# GET /artists/{id}/relationships/following
export def "artists-relationships-following get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --viewerContext: string
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: following (e.g. following)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "viewerContext" $viewerContext "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/following" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to following relationship ("to-many").
#
# POST /artists/{id}/relationships/following
export def "artists-relationships-following post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/following" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /artists/{id}/relationships/owners
export def "artists-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get profileArt relationship ("to-many").
#
# GET /artists/{id}/relationships/profileArt
export def "artists-relationships-profile-art get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: profileArt (e.g. profileArt)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/profileArt" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update profileArt relationship ("to-many").
#
# PATCH /artists/{id}/relationships/profileArt
export def "artists-relationships-profile-art patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artists/($id)/relationships/profileArt")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get radio relationship ("to-many").
#
# GET /artists/{id}/relationships/radio
export def "artists-relationships-radio get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: radio (e.g. radio)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/radio" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get roles relationship ("to-many").
#
# GET /artists/{id}/relationships/roles
export def "artists-relationships-roles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: roles (e.g. roles)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/roles" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get similarArtists relationship ("to-many").
#
# GET /artists/{id}/relationships/similarArtists
export def "artists-relationships-similar-artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: similarArtists (e.g. similarArtists)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/similarArtists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get trackProviders relationship ("to-many").
#
# GET /artists/{id}/relationships/trackProviders
export def "artists-relationships-track-providers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: trackProviders (e.g. trackProviders)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/trackProviders" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tracks relationship ("to-many").
#
# GET /artists/{id}/relationships/tracks
export def "artists-relationships-tracks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --collapseBy: string@collapseBy-completer # Collapse by options for getting artist tracks. Available options: FINGERPRINT, ID. FINGERPRINT option might collapse similar tracks based entry fingerprints while collapsing by ID always returns all available items. (e.g. FINGERPRINT)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: tracks (e.g. tracks)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collapseBy" $collapseBy "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/tracks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get videos relationship ("to-many").
#
# GET /artists/{id}/relationships/videos
export def "artists-relationships-videos get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: videos (e.g. videos)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($id)/relationships/videos" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple artworks.
#
# GET /artworks
export def "artworks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --filterid: list # Artwork id (e.g. `a468bee88def`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[id]" $filterid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/artworks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single artwork.
#
# POST /artworks
export def "artworks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/artworks")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single artwork.
#
# GET /artworks/{id}
export def "artworks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/artworks/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /artworks/{id}/relationships/owners
export def "artworks-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artworks/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple clients.
#
# GET /clients
export def "clients list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --filterownersid: list # User id. Use `me` for the authenticated user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/clients" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single client.
#
# POST /clients
export def "clients post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clients")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete single client.
#
# DELETE /clients/{id}
export def "clients delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single client.
#
# GET /clients/{id}
export def "clients get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/clients/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single client.
#
# PATCH /clients/{id}
export def "clients patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /clients/{id}/relationships/owners
export def "clients-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/clients/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single collaborationInviteRedemption.
#
# POST /collaborationInviteRedemptions
export def "collaboration-invite-redemptions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaborationInviteRedemptions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get multiple collaborationInvites.
#
# GET /collaborationInvites
export def "collaboration-invites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners, subject (e.g. owners)
  --filtercode: list # Invite code
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[code]" $filtercode "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/collaborationInvites" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single collaborationInvite.
#
# POST /collaborationInvites
export def "collaboration-invites post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaborationInvites")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete single collaborationInvite.
#
# DELETE /collaborationInvites/{id}
export def "collaboration-invites delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collaborationInvites/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single collaborationInvite.
#
# GET /collaborationInvites/{id}
export def "collaboration-invites get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners, subject (e.g. owners)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/collaborationInvites/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /collaborationInvites/{id}/relationships/owners
export def "collaboration-invites-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collaborationInvites/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get subject relationship ("to-one").
#
# GET /collaborationInvites/{id}/relationships/subject
export def "collaboration-invites-relationships-subject get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: subject (e.g. subject)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/collaborationInvites/($id)/relationships/subject" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple comments.
#
# GET /comments
export def "comments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --include: list # Allows the client to customize which related resources should be returned. Available options: ownerProfiles, owners, parentComment (e.g. ownerProfiles)
  --filterparentCommentid: list # Filter by parent comment ID to get replies (e.g. `550e8400-e29b-41d4-a716-446655440000`)
  --filtersubjectid: list # Filter by subject resource ID (e.g. `12345`)
  --filtersubjecttype: list # Filter by subject resource type (e.g. `albums`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "include" $include "multi") (serialize-qp "filter[parentComment.id]" $filterparentCommentid "multi") (serialize-qp "filter[subject.id]" $filtersubjectid "multi") (serialize-qp "filter[subject.type]" $filtersubjecttype "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/comments" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single comment.
#
# POST /comments
export def "comments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete single comment.
#
# DELETE /comments/{id}
export def "comments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single comment.
#
# GET /comments/{id}
export def "comments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: ownerProfiles, owners, parentComment (e.g. ownerProfiles)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/comments/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single comment.
#
# PATCH /comments/{id}
export def "comments patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get ownerProfiles relationship ("to-many").
#
# GET /comments/{id}/relationships/ownerProfiles
export def "comments-relationships-owner-profiles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: ownerProfiles (e.g. ownerProfiles)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/comments/($id)/relationships/ownerProfiles" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /comments/{id}/relationships/owners
export def "comments-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/comments/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get parentComment relationship ("to-one").
#
# GET /comments/{id}/relationships/parentComment
export def "comments-relationships-parent-comment get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: parentComment (e.g. parentComment)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/comments/($id)/relationships/parentComment" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple contentClaims.
#
# GET /contentClaims
export def "content-claims list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: claimedResource, claimingArtist, owners (e.g. claimedResource)
  --filterownersid: list # User id. Use `me` for the authenticated user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/contentClaims" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single contentClaim.
#
# POST /contentClaims
export def "content-claims post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentClaims")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single contentClaim.
#
# GET /contentClaims/{id}
export def "content-claims get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: claimedResource, claimingArtist, owners (e.g. claimedResource)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/contentClaims/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get claimedResource relationship ("to-one").
#
# GET /contentClaims/{id}/relationships/claimedResource
export def "content-claims-relationships-claimed-resource get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: claimedResource (e.g. claimedResource)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/contentClaims/($id)/relationships/claimedResource" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get claimingArtist relationship ("to-one").
#
# GET /contentClaims/{id}/relationships/claimingArtist
export def "content-claims-relationships-claiming-artist get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: claimingArtist (e.g. claimingArtist)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/contentClaims/($id)/relationships/claimingArtist" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /contentClaims/{id}/relationships/owners
export def "content-claims-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contentClaims/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single credit.
#
# GET /credits/{id}
export def "credits get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: artist, category (e.g. artist)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/credits/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get artist relationship ("to-one").
#
# GET /credits/{id}/relationships/artist
export def "credits-relationships-artist get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: artist (e.g. artist)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/credits/($id)/relationships/artist" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get category relationship ("to-one").
#
# GET /credits/{id}/relationships/category
export def "credits-relationships-category get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: category (e.g. category)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/credits/($id)/relationships/category" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple downloads.
#
# GET /downloads
export def "downloads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --filterid: list # Download id (e.g. `VFJBQ0tTOjEyMzQ1`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[id]" $filterid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/downloads" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single download.
#
# GET /downloads/{id}
export def "downloads get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/downloads/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /downloads/{id}/relationships/owners
export def "downloads-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/downloads/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple dspSharingLinks.
#
# GET /dspSharingLinks
export def "dsp-sharing-links get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: subject (e.g. subject)
  --filtersubjectid: list # The id of the subject resource
  --filtersubjecttype: list # The type of the subject resource (e.g., albums, tracks, artists) (e.g. `tracks`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[subject.id]" $filtersubjectid "multi") (serialize-qp "filter[subject.type]" $filtersubjecttype "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/dspSharingLinks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get subject relationship ("to-one").
#
# GET /dspSharingLinks/{id}/relationships/subject
export def "dsp-sharing-links-relationships-subject get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: subject (e.g. subject)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/dspSharingLinks/($id)/relationships/subject" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get items relationship ("to-many").
#
# GET /dynamicModules/{id}/relationships/items
export def "dynamic-modules-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --refreshId: string
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --deviceType: string@deviceType-completer # The type of device making the request (e.g. PHONE)
  --systemType: string@systemType-completer # The system type of the device making the request (e.g. IOS)
  --clientVersion: string # Client version number (e.g. 2026.0.1)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refreshId" $refreshId "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "deviceType" $deviceType "scalar") (serialize-qp "systemType" $systemType "scalar") (serialize-qp "clientVersion" $clientVersion "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/dynamicModules/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple dynamicPages.
#
# GET /dynamicPages
export def "dynamic-pages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --refreshId: string
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --deviceType: string@deviceType-completer # The type of device making the request (e.g. PHONE)
  --systemType: string@systemType-completer # The system type of the device making the request (e.g. IOS)
  --clientVersion: string # Client version number (e.g. 2026.0.1)
  --include: list # Allows the client to customize which related resources should be returned. Available options: dynamicModules, subject (e.g. dynamicModules)
  --filterpageType: list # type of the page (e.g. `ARTIST`)
  --filtersubjectid: list # the subject id, eg. artistId (e.g. `67890`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refreshId" $refreshId "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "deviceType" $deviceType "scalar") (serialize-qp "systemType" $systemType "scalar") (serialize-qp "clientVersion" $clientVersion "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[pageType]" $filterpageType "multi") (serialize-qp "filter[subject.id]" $filtersubjectid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/dynamicPages" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get dynamicModules relationship ("to-many").
#
# GET /dynamicPages/{id}/relationships/dynamicModules
export def "dynamic-pages-relationships-dynamic-modules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --refreshId: string
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --deviceType: string@deviceType-completer # The type of device making the request (e.g. PHONE)
  --systemType: string@systemType-completer # The system type of the device making the request (e.g. IOS)
  --clientVersion: string # Client version number (e.g. 2026.0.1)
  --include: list # Allows the client to customize which related resources should be returned. Available options: dynamicModules (e.g. dynamicModules)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refreshId" $refreshId "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "deviceType" $deviceType "scalar") (serialize-qp "systemType" $systemType "scalar") (serialize-qp "clientVersion" $clientVersion "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/dynamicPages/($id)/relationships/dynamicModules" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get subject relationship ("to-one").
#
# GET /dynamicPages/{id}/relationships/subject
export def "dynamic-pages-relationships-subject get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: subject (e.g. subject)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/dynamicPages/($id)/relationships/subject" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple genres.
#
# GET /genres
export def "genres list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --filterid: list # Allows filtering by genre id(s). USER_SELECTABLE is special value used to return specific genres which users can select from (e.g. `'1,2,3' or 'USER_SELECTABLE'`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "filter[id]" $filterid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/genres" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single genre.
#
# GET /genres/{id}
export def "genres get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/genres/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple installations.
#
# GET /installations
export def "installations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: offlineInventory, owners (e.g. offlineInventory)
  --filterclientProvidedInstallationId: list # Client-provided installation identifier to filter by (e.g. `a468bee88def`)
  --filterownersid: list # User ID to filter by. Use `me` for the authenticated user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[clientProvidedInstallationId]" $filterclientProvidedInstallationId "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/installations" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single installation.
#
# POST /installations
export def "installations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/installations")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single installation.
#
# GET /installations/{id}
export def "installations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: offlineInventory, owners (e.g. offlineInventory)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/installations/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from offlineInventory relationship ("to-many").
#
# DELETE /installations/{id}/relationships/offlineInventory
export def "installations-relationships-offline-inventory delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installations/($id)/relationships/offlineInventory")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get offlineInventory relationship ("to-many").
#
# GET /installations/{id}/relationships/offlineInventory
export def "installations-relationships-offline-inventory get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: offlineInventory (e.g. offlineInventory)
  --filterid: list # Offline item id (e.g. `1234`)
  --filterstate: list # One of: PENDING, STORED (e.g. `PENDING`)
  --filtertype: list # One of: tracks, videos, albums, playlists, userCollectionTracks (e.g. `tracks`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[id]" $filterid "multi") (serialize-qp "filter[state]" $filterstate "multi") (serialize-qp "filter[type]" $filtertype "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/installations/($id)/relationships/offlineInventory" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to offlineInventory relationship ("to-many").
#
# POST /installations/{id}/relationships/offlineInventory
export def "installations-relationships-offline-inventory post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installations/($id)/relationships/offlineInventory")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /installations/{id}/relationships/owners
export def "installations-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/installations/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single lyric.
#
# POST /lyrics
export def "lyrics post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lyrics")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete single lyric.
#
# DELETE /lyrics/{id}
export def "lyrics delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lyrics/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single lyric.
#
# GET /lyrics/{id}
export def "lyrics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners, track (e.g. owners)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/lyrics/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single lyric.
#
# PATCH /lyrics/{id}
export def "lyrics patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lyrics/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /lyrics/{id}/relationships/owners
export def "lyrics-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lyrics/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get track relationship ("to-one").
#
# GET /lyrics/{id}/relationships/track
export def "lyrics-relationships-track get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: track (e.g. track)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/lyrics/($id)/relationships/track" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single manualArtistClaim.
#
# POST /manualArtistClaims
export def "manual-artist-claims post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/manualArtistClaims")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get multiple offlineTasks.
#
# GET /offlineTasks
export def "offline-tasks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: collection, item, owners (e.g. collection)
  --filterinstallationid: list # List of offline task IDs (e.g. `a468bee88def`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[installation.id]" $filterinstallationid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/offlineTasks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single offlineTask.
#
# GET /offlineTasks/{id}
export def "offline-tasks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: collection, item, owners (e.g. collection)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/offlineTasks/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single offlineTask.
#
# PATCH /offlineTasks/{id}
export def "offline-tasks patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/offlineTasks/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get collection relationship ("to-one").
#
# GET /offlineTasks/{id}/relationships/collection
export def "offline-tasks-relationships-collection get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: collection (e.g. collection)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/offlineTasks/($id)/relationships/collection" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item relationship ("to-one").
#
# GET /offlineTasks/{id}/relationships/item
export def "offline-tasks-relationships-item get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: item (e.g. item)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/offlineTasks/($id)/relationships/item" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /offlineTasks/{id}/relationships/owners
export def "offline-tasks-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/offlineTasks/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple playQueues.
#
# GET /playQueues
export def "play-queues list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: current, future, owners, past (e.g. current)
  --filterownersid: list # User id. Use `me` for the authenticated user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/playQueues" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single playQueue.
#
# POST /playQueues
export def "play-queues post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/playQueues")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete single playQueue.
#
# DELETE /playQueues/{id}
export def "play-queues delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playQueues/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single playQueue.
#
# GET /playQueues/{id}
export def "play-queues get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: current, future, owners, past (e.g. current)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/playQueues/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single playQueue.
#
# PATCH /playQueues/{id}
export def "play-queues patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playQueues/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get current relationship ("to-one").
#
# GET /playQueues/{id}/relationships/current
export def "play-queues-relationships-current get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: current (e.g. current)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/playQueues/($id)/relationships/current" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update current relationship ("to-one").
#
# PATCH /playQueues/{id}/relationships/current
export def "play-queues-relationships-current patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playQueues/($id)/relationships/current")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete from future relationship ("to-many").
#
# DELETE /playQueues/{id}/relationships/future
export def "play-queues-relationships-future delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playQueues/($id)/relationships/future")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get future relationship ("to-many").
#
# GET /playQueues/{id}/relationships/future
export def "play-queues-relationships-future get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: future (e.g. future)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/playQueues/($id)/relationships/future" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update future relationship ("to-many").
#
# PATCH /playQueues/{id}/relationships/future
export def "play-queues-relationships-future patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playQueues/($id)/relationships/future")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Add to future relationship ("to-many").
#
# POST /playQueues/{id}/relationships/future
export def "play-queues-relationships-future post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playQueues/($id)/relationships/future")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /playQueues/{id}/relationships/owners
export def "play-queues-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/playQueues/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get past relationship ("to-many").
#
# GET /playQueues/{id}/relationships/past
export def "play-queues-relationships-past get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: past (e.g. past)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/playQueues/($id)/relationships/past" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple playlists.
#
# GET /playlists
export def "playlists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: collaboratorProfiles, collaborators, coverArt, items, ownerProfiles, owners (e.g. collaboratorProfiles)
  --filterid: list # List of playlist IDs (e.g. `550e8400-e29b-41d4-a716-446655440000`)
  --filterownersid: list # User id. Use `me` for the authenticated user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[id]" $filterid "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/playlists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single playlist.
#
# POST /playlists
export def "playlists post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playlists" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete single playlist.
#
# DELETE /playlists/{id}
export def "playlists delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playlists/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single playlist.
#
# GET /playlists/{id}
export def "playlists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: collaboratorProfiles, collaborators, coverArt, items, ownerProfiles, owners (e.g. collaboratorProfiles)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single playlist.
#
# PATCH /playlists/{id}
export def "playlists patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete from collaboratorProfiles relationship ("to-many").
#
# DELETE /playlists/{id}/relationships/collaboratorProfiles
export def "playlists-relationships-collaborator-profiles delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playlists/($id)/relationships/collaboratorProfiles")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get collaboratorProfiles relationship ("to-many").
#
# GET /playlists/{id}/relationships/collaboratorProfiles
export def "playlists-relationships-collaborator-profiles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: collaboratorProfiles (e.g. collaboratorProfiles)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($id)/relationships/collaboratorProfiles" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to collaboratorProfiles relationship ("to-many").
#
# POST /playlists/{id}/relationships/collaboratorProfiles
export def "playlists-relationships-collaborator-profiles post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playlists/($id)/relationships/collaboratorProfiles")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get collaborators relationship ("to-many").
#
# GET /playlists/{id}/relationships/collaborators
export def "playlists-relationships-collaborators get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: collaborators (e.g. collaborators)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($id)/relationships/collaborators" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get coverArt relationship ("to-many").
#
# GET /playlists/{id}/relationships/coverArt
export def "playlists-relationships-cover-art get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: coverArt (e.g. coverArt)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($id)/relationships/coverArt" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update coverArt relationship ("to-many").
#
# PATCH /playlists/{id}/relationships/coverArt
export def "playlists-relationships-cover-art patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playlists/($id)/relationships/coverArt")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete from items relationship ("to-many").
#
# DELETE /playlists/{id}/relationships/items
export def "playlists-relationships-items delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playlists/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get items relationship ("to-many").
#
# GET /playlists/{id}/relationships/items
export def "playlists-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update items relationship ("to-many").
#
# PATCH /playlists/{id}/relationships/items
export def "playlists-relationships-items patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playlists/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Add to items relationship ("to-many").
#
# POST /playlists/{id}/relationships/items
export def "playlists-relationships-items post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($id)/relationships/items" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get ownerProfiles relationship ("to-many").
#
# GET /playlists/{id}/relationships/ownerProfiles
export def "playlists-relationships-owner-profiles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: ownerProfiles (e.g. ownerProfiles)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($id)/relationships/ownerProfiles" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /playlists/{id}/relationships/owners
export def "playlists-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple priceConfigurations.
#
# GET /priceConfigurations
export def "price-configurations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filterid: list # List of price configurations IDs (e.g. `cHJpY2UtY29uZmlnLTEyMzpVUw`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[id]" $filterid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/priceConfigurations" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single priceConfiguration.
#
# POST /priceConfigurations
export def "price-configurations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/priceConfigurations")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single priceConfiguration.
#
# GET /priceConfigurations/{id}
export def "price-configurations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/priceConfigurations/($id)")
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple providerOwners.
#
# GET /providerOwners
export def "provider-owners get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners, provider (e.g. owners)
  --filterownersid: list # User id. Use `me` for the authenticated user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/providerOwners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /providerOwners/{id}/relationships/owners
export def "provider-owners-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providerOwners/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get provider relationship ("to-one").
#
# GET /providerOwners/{id}/relationships/provider
export def "provider-owners-relationships-provider get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: provider (e.g. provider)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/providerOwners/($id)/relationships/provider" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple providerProductInfos.
#
# GET /providerProductInfos
export def "provider-product-infos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: provider, subject (e.g. provider)
  --filterbarcodeId: list # List of barcode IDs (EAN-13 or UPC-A) (e.g. `00602527336510`)
  --filterproviderid: list # Content provider ID (e.g. `50`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[barcodeId]" $filterbarcodeId "multi") (serialize-qp "filter[provider.id]" $filterproviderid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/providerProductInfos" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get provider relationship ("to-one").
#
# GET /providerProductInfos/{id}/relationships/provider
export def "provider-product-infos-relationships-provider get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: provider (e.g. provider)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/providerProductInfos/($id)/relationships/provider" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get subject relationship ("to-one").
#
# GET /providerProductInfos/{id}/relationships/subject
export def "provider-product-infos-relationships-subject get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: subject (e.g. subject)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/providerProductInfos/($id)/relationships/subject" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single provider.
#
# GET /providers/{id}
export def "providers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/providers/($id)")
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple purchases.
#
# GET /purchases
export def "purchases get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners, subject (e.g. owners)
  --filterownersid: list # User id. Use `me` for the authenticated user
  --filtersubjecttype: list # The type of purchased content (e.g. `albums`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi") (serialize-qp "filter[subject.type]" $filtersubjecttype "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/purchases" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /purchases/{id}/relationships/owners
export def "purchases-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/purchases/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get subject relationship ("to-one").
#
# GET /purchases/{id}/relationships/subject
export def "purchases-relationships-subject get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: subject (e.g. subject)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/purchases/($id)/relationships/subject" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple reactions.
#
# GET /reactions
export def "reactions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stats: string@stats-completer
  --statsOnly: oneof<nothing, bool>
  --viewerContext: string
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: ownerProfiles, owners (e.g. ownerProfiles)
  --filteremoji: list # Filter by emoji (e.g. `👍`)
  --filtersubjectid: list # Filter by subject resource ID (e.g. `12345`)
  --filtersubjecttype: list # Filter by subject resource type (e.g. `albums`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stats" $stats "scalar") (serialize-qp "statsOnly" $statsOnly "scalar") (serialize-qp "viewerContext" $viewerContext "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[emoji]" $filteremoji "multi") (serialize-qp "filter[subject.id]" $filtersubjectid "multi") (serialize-qp "filter[subject.type]" $filtersubjecttype "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/reactions" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single reaction.
#
# POST /reactions
export def "reactions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reactions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete single reaction.
#
# DELETE /reactions/{id}
export def "reactions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reactions/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get ownerProfiles relationship ("to-many").
#
# GET /reactions/{id}/relationships/ownerProfiles
export def "reactions-relationships-owner-profiles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: ownerProfiles (e.g. ownerProfiles)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reactions/($id)/relationships/ownerProfiles" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /reactions/{id}/relationships/owners
export def "reactions-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reactions/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single savedShare.
#
# POST /savedShares
export def "saved-shares post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/savedShares")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get multiple scopes.
#
# GET /scopes
export def "scopes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filterrequiredAccessTier: list # Filters scopes by their `requiredAccessTier`. (e.g. `THIRD_PARTY`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[requiredAccessTier]" $filterrequiredAccessTier "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/scopes" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete single searchHistoryEntrie.
#
# DELETE /searchHistoryEntries/{id}
export def "search-history-entries delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/searchHistoryEntries/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single searchResult.
#
# GET /searchResults/{id}
export def "search-results get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitFilter: string@explicitFilter-completer # Explicit filter. Valid values: INCLUDE or EXCLUDE (default: INCLUDE, e.g. INCLUDE)
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums, artists, playlists, topHits, tracks, videos (e.g. albums)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "explicitFilter" $explicitFilter "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/searchResults/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get albums relationship ("to-many").
#
# GET /searchResults/{id}/relationships/albums
export def "search-results-relationships-albums get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitFilter: string@explicitFilter-completer # Explicit filter. Valid values: INCLUDE or EXCLUDE (default: INCLUDE, e.g. INCLUDE)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums (e.g. albums)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "explicitFilter" $explicitFilter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/searchResults/($id)/relationships/albums" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get artists relationship ("to-many").
#
# GET /searchResults/{id}/relationships/artists
export def "search-results-relationships-artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitFilter: string@explicitFilter-completer # Explicit filter. Valid values: INCLUDE or EXCLUDE (default: INCLUDE, e.g. INCLUDE)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: artists (e.g. artists)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "explicitFilter" $explicitFilter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/searchResults/($id)/relationships/artists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get playlists relationship ("to-many").
#
# GET /searchResults/{id}/relationships/playlists
export def "search-results-relationships-playlists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitFilter: string@explicitFilter-completer # Explicit filter. Valid values: INCLUDE or EXCLUDE (default: INCLUDE, e.g. INCLUDE)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: playlists (e.g. playlists)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "explicitFilter" $explicitFilter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/searchResults/($id)/relationships/playlists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get topHits relationship ("to-many").
#
# GET /searchResults/{id}/relationships/topHits
export def "search-results-relationships-top-hits get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitFilter: string@explicitFilter-completer # Explicit filter. Valid values: INCLUDE or EXCLUDE (default: INCLUDE, e.g. INCLUDE)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: topHits (e.g. topHits)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "explicitFilter" $explicitFilter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/searchResults/($id)/relationships/topHits" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tracks relationship ("to-many").
#
# GET /searchResults/{id}/relationships/tracks
export def "search-results-relationships-tracks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitFilter: string@explicitFilter-completer # Explicit filter. Valid values: INCLUDE or EXCLUDE (default: INCLUDE, e.g. INCLUDE)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: tracks (e.g. tracks)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "explicitFilter" $explicitFilter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/searchResults/($id)/relationships/tracks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get videos relationship ("to-many").
#
# GET /searchResults/{id}/relationships/videos
export def "search-results-relationships-videos get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitFilter: string@explicitFilter-completer # Explicit filter. Valid values: INCLUDE or EXCLUDE (default: INCLUDE, e.g. INCLUDE)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: videos (e.g. videos)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "explicitFilter" $explicitFilter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/searchResults/($id)/relationships/videos" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single searchSuggestion.
#
# GET /searchSuggestions/{id}
export def "search-suggestions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitFilter: string@explicitFilter-completer # Explicit filter. Valid values: INCLUDE or EXCLUDE (default: INCLUDE, e.g. INCLUDE)
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: directHits, history (e.g. directHits)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "explicitFilter" $explicitFilter "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/searchSuggestions/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get directHits relationship ("to-many").
#
# GET /searchSuggestions/{id}/relationships/directHits
export def "search-suggestions-relationships-direct-hits get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitFilter: string@explicitFilter-completer # Explicit filter. Valid values: INCLUDE or EXCLUDE (default: INCLUDE, e.g. INCLUDE)
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: directHits (e.g. directHits)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "explicitFilter" $explicitFilter "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/searchSuggestions/($id)/relationships/directHits" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get history relationship ("to-many").
#
# GET /searchSuggestions/{id}/relationships/history
export def "search-suggestions-relationships-history get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitFilter: string@explicitFilter-completer # Explicit filter. Valid values: INCLUDE or EXCLUDE (default: INCLUDE, e.g. INCLUDE)
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: history (e.g. history)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "explicitFilter" $explicitFilter "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/searchSuggestions/($id)/relationships/history" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple shares.
#
# GET /shares
export def "shares list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners, sharedResources (e.g. owners)
  --filtercode: list # A share code (e.g. `xyz`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[code]" $filtercode "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/shares" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single share.
#
# POST /shares
export def "shares post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shares")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single share.
#
# GET /shares/{id}
export def "shares get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners, sharedResources (e.g. owners)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/shares/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /shares/{id}/relationships/owners
export def "shares-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shares/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sharedResources relationship ("to-many").
#
# GET /shares/{id}/relationships/sharedResources
export def "shares-relationships-shared-resources get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: sharedResources (e.g. sharedResources)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/shares/($id)/relationships/sharedResources" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single squareConnection.
#
# POST /squareConnections
@deprecated --flag countryCode
export def "square-connections post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (DEPRECATED, e.g. US)
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/squareConnections" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single squareConnection.
#
# GET /squareConnections/{id}
export def "square-connections get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/squareConnections/($id)")
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple stripeConnections.
#
# GET /stripeConnections
export def "stripe-connections get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --filterownersid: list # User id. Use `me` for the authenticated user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/stripeConnections" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single stripeConnection.
#
# POST /stripeConnections
export def "stripe-connections post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stripeConnections" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /stripeConnections/{id}/relationships/owners
export def "stripe-connections-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stripeConnections/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple stripeDashboardLinks.
#
# GET /stripeDashboardLinks
export def "stripe-dashboard-links get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --filterownersid: list # User id. Use `me` for the authenticated user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/stripeDashboardLinks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /stripeDashboardLinks/{id}/relationships/owners
export def "stripe-dashboard-links-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stripeDashboardLinks/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single temporaryUserToken.
#
# POST /temporaryUserTokens
export def "temporary-user-tokens post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/temporaryUserTokens")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single temporaryUserToken.
#
# GET /temporaryUserTokens/{id}
export def "temporary-user-tokens get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/temporaryUserTokens/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /temporaryUserTokens/{id}/relationships/owners
export def "temporary-user-tokens-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/temporaryUserTokens/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple terms.
#
# GET /terms
export def "terms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filtercountryCode: list # Filter by countryCode
  --filterisLatestVersion: list # Filter by isLatestVersion
  --filtertermsType: list # One of: DEVELOPER, UPLOAD_MARKETPLACE (e.g. `DEVELOPER`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[countryCode]" $filtercountryCode "multi") (serialize-qp "filter[isLatestVersion]" $filterisLatestVersion "multi") (serialize-qp "filter[termsType]" $filtertermsType "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/terms" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single term.
#
# GET /terms/{id}
export def "terms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terms/($id)")
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single trackFile.
#
# GET /trackFiles/{id}
export def "track-files get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --formats: list
  --usage: string@usage-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "formats" $formats "multi") (serialize-qp "usage" $usage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackFiles/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single trackManifest.
#
# GET /trackManifests/{id}
export def "track-manifests get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --manifestType: string@manifestType-completer
  --formats: list
  --uriScheme: string@uriScheme-completer
  --usage: string@usage-completer
  --adaptive: oneof<nothing, bool>
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "manifestType" $manifestType "scalar") (serialize-qp "formats" $formats "multi") (serialize-qp "uriScheme" $uriScheme "scalar") (serialize-qp "usage" $usage "scalar") (serialize-qp "adaptive" $adaptive "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackManifests/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single trackSourceFile.
#
# POST /trackSourceFiles
export def "track-source-files post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/trackSourceFiles")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single trackSourceFile.
#
# GET /trackSourceFiles/{id}
export def "track-source-files get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackSourceFiles/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /trackSourceFiles/{id}/relationships/owners
export def "track-source-files-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackSourceFiles/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single trackStatistic.
#
# GET /trackStatistics/{id}
export def "track-statistics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackStatistics/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /trackStatistics/{id}/relationships/owners
export def "track-statistics-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackStatistics/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple tracks.
#
# GET /tracks
export def "tracks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums, artists, credits, download, genres, lyrics, metadataStatus, owners, priceConfig, providers, radio, replacement, shares, similarTracks, sourceFile, suggestedTracks, trackStatistics, usageRules (e.g. albums)
  --filterid: list # List of track IDs (e.g. `75413016`)
  --filterisrc: list # List of ISRCs. When a single ISRC is provided, pagination is supported and multiple tracks may be returned. When multiple ISRCs are provided, one track per ISRC is returned without pagination. (e.g. `QMJMT1701237`)
  --filterownersid: list # User id. Use `me` for the authenticated user
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[id]" $filterid "multi") (serialize-qp "filter[isrc]" $filterisrc "multi") (serialize-qp "filter[owners.id]" $filterownersid "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tracks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single track.
#
# POST /tracks
export def "tracks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracks")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete single track.
#
# DELETE /tracks/{id}
export def "tracks delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracks/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single track.
#
# GET /tracks/{id}
export def "tracks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums, artists, credits, download, genres, lyrics, metadataStatus, owners, priceConfig, providers, radio, replacement, shares, similarTracks, sourceFile, suggestedTracks, trackStatistics, usageRules (e.g. albums)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single track.
#
# PATCH /tracks/{id}
export def "tracks patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracks/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get albums relationship ("to-many").
#
# GET /tracks/{id}/relationships/albums
export def "tracks-relationships-albums get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums (e.g. albums)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/albums" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update albums relationship ("to-many").
#
# PATCH /tracks/{id}/relationships/albums
export def "tracks-relationships-albums patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracks/($id)/relationships/albums")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get artists relationship ("to-many").
#
# GET /tracks/{id}/relationships/artists
export def "tracks-relationships-artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: artists (e.g. artists)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/artists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get credits relationship ("to-many").
#
# GET /tracks/{id}/relationships/credits
export def "tracks-relationships-credits get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: credits (e.g. credits)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/credits" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get download relationship ("to-one").
#
# GET /tracks/{id}/relationships/download
export def "tracks-relationships-download get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: download (e.g. download)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/download" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get genres relationship ("to-many").
#
# GET /tracks/{id}/relationships/genres
export def "tracks-relationships-genres get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: genres (e.g. genres)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/genres" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lyrics relationship ("to-many").
#
# GET /tracks/{id}/relationships/lyrics
export def "tracks-relationships-lyrics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: lyrics (e.g. lyrics)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/lyrics" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metadataStatus relationship ("to-one").
#
# GET /tracks/{id}/relationships/metadataStatus
export def "tracks-relationships-metadata-status get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: metadataStatus (e.g. metadataStatus)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/metadataStatus" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners relationship ("to-many").
#
# GET /tracks/{id}/relationships/owners
export def "tracks-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get priceConfig relationship ("to-one").
#
# GET /tracks/{id}/relationships/priceConfig
export def "tracks-relationships-price-config get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: priceConfig (e.g. priceConfig)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/priceConfig" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get providers relationship ("to-many").
#
# GET /tracks/{id}/relationships/providers
export def "tracks-relationships-providers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: providers (e.g. providers)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/providers" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get radio relationship ("to-many").
#
# GET /tracks/{id}/relationships/radio
export def "tracks-relationships-radio get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: radio (e.g. radio)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/radio" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get replacement relationship ("to-one").
#
# GET /tracks/{id}/relationships/replacement
export def "tracks-relationships-replacement get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: replacement (e.g. replacement)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/replacement" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get shares relationship ("to-many").
#
# GET /tracks/{id}/relationships/shares
export def "tracks-relationships-shares get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: shares (e.g. shares)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/shares" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get similarTracks relationship ("to-many").
#
# GET /tracks/{id}/relationships/similarTracks
export def "tracks-relationships-similar-tracks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: similarTracks (e.g. similarTracks)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/similarTracks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sourceFile relationship ("to-one").
#
# GET /tracks/{id}/relationships/sourceFile
export def "tracks-relationships-source-file get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: sourceFile (e.g. sourceFile)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/sourceFile" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get suggestedTracks relationship ("to-many").
#
# GET /tracks/{id}/relationships/suggestedTracks
export def "tracks-relationships-suggested-tracks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: suggestedTracks (e.g. suggestedTracks)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/suggestedTracks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get trackStatistics relationship ("to-one").
#
# GET /tracks/{id}/relationships/trackStatistics
export def "tracks-relationships-track-statistics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: trackStatistics (e.g. trackStatistics)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/trackStatistics" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get usageRules relationship ("to-one").
#
# GET /tracks/{id}/relationships/usageRules
export def "tracks-relationships-usage-rules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: usageRules (e.g. usageRules)
  --shareCode: string # Share code that grants access to UNLISTED resources. When provided, allows non-owners to access resources that would otherwise be restricted. (e.g. xyz)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "shareCode" $shareCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($id)/relationships/usageRules" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single tracksMetadataStatu.
#
# GET /tracksMetadataStatus/{id}
export def "tracks-metadata-status get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracksMetadataStatus/($id)")
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single usageRule.
#
# POST /usageRules
export def "usage-rules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usageRules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single usageRule.
#
# GET /usageRules/{id}
export def "usage-rules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usageRules/($id)")
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single userCollectionAlbum.
#
# GET /userCollectionAlbums/{id}
export def "user-collection-albums get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items, owners (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionAlbums/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from items relationship ("to-many").
#
# DELETE /userCollectionAlbums/{id}/relationships/items
export def "user-collection-albums-relationships-items delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionAlbums/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get items relationship ("to-many").
#
# GET /userCollectionAlbums/{id}/relationships/items
export def "user-collection-albums-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionAlbums/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to items relationship ("to-many").
#
# POST /userCollectionAlbums/{id}/relationships/items
export def "user-collection-albums-relationships-items post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionAlbums/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /userCollectionAlbums/{id}/relationships/owners
export def "user-collection-albums-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionAlbums/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single userCollectionArtist.
#
# GET /userCollectionArtists/{id}
export def "user-collection-artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items, owners (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionArtists/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from items relationship ("to-many").
#
# DELETE /userCollectionArtists/{id}/relationships/items
export def "user-collection-artists-relationships-items delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionArtists/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get items relationship ("to-many").
#
# GET /userCollectionArtists/{id}/relationships/items
export def "user-collection-artists-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionArtists/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to items relationship ("to-many").
#
# POST /userCollectionArtists/{id}/relationships/items
export def "user-collection-artists-relationships-items post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionArtists/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /userCollectionArtists/{id}/relationships/owners
export def "user-collection-artists-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionArtists/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple userCollectionFolders.
#
# GET /userCollectionFolders
export def "user-collection-folders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: items, owners, userCollection (e.g. items)
  --filterid: list # Folder Id (e.g. `CBMHXUOuJZgroV2kWpeVLL1I7xdgvF6ocDEGCXov8SZq3WVhrOcOq5pjnGawKX`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "filter[id]" $filterid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/userCollectionFolders" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single userCollectionFolder.
#
# POST /userCollectionFolders
export def "user-collection-folders post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/userCollectionFolders")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete single userCollectionFolder.
#
# DELETE /userCollectionFolders/{id}
export def "user-collection-folders delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionFolders/($id)")
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single userCollectionFolder.
#
# GET /userCollectionFolders/{id}
export def "user-collection-folders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: items, owners, userCollection (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionFolders/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update single userCollectionFolder.
#
# PATCH /userCollectionFolders/{id}
export def "user-collection-folders patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionFolders/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete from items relationship ("to-many").
#
# DELETE /userCollectionFolders/{id}/relationships/items
export def "user-collection-folders-relationships-items delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionFolders/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get items relationship ("to-many").
#
# GET /userCollectionFolders/{id}/relationships/items
export def "user-collection-folders-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionFolders/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to items relationship ("to-many").
#
# POST /userCollectionFolders/{id}/relationships/items
export def "user-collection-folders-relationships-items post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionFolders/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /userCollectionFolders/{id}/relationships/owners
export def "user-collection-folders-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionFolders/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get userCollection relationship ("to-one").
#
# GET /userCollectionFolders/{id}/relationships/userCollection
export def "user-collection-folders-relationships-user-collection get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: userCollection (e.g. userCollection)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionFolders/($id)/relationships/userCollection" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single userCollectionPlaylist.
#
# GET /userCollectionPlaylists/{id}
export def "user-collection-playlists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items, owners (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionPlaylists/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from items relationship ("to-many").
#
# DELETE /userCollectionPlaylists/{id}/relationships/items
export def "user-collection-playlists-relationships-items delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionPlaylists/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get items relationship ("to-many").
#
# GET /userCollectionPlaylists/{id}/relationships/items
export def "user-collection-playlists-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --collectionView: string@collectionView-completer
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collectionView" $collectionView "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionPlaylists/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to items relationship ("to-many").
#
# POST /userCollectionPlaylists/{id}/relationships/items
export def "user-collection-playlists-relationships-items post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionPlaylists/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /userCollectionPlaylists/{id}/relationships/owners
export def "user-collection-playlists-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionPlaylists/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single userCollectionSaveForLater.
#
# GET /userCollectionSaveForLaters/{id}
export def "user-collection-save-for-laters get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: items, owners (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionSaveForLaters/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from items relationship ("to-many").
#
# DELETE /userCollectionSaveForLaters/{id}/relationships/items
export def "user-collection-save-for-laters-relationships-items delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionSaveForLaters/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get items relationship ("to-many").
#
# GET /userCollectionSaveForLaters/{id}/relationships/items
export def "user-collection-save-for-laters-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionSaveForLaters/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to items relationship ("to-many").
#
# POST /userCollectionSaveForLaters/{id}/relationships/items
export def "user-collection-save-for-laters-relationships-items post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionSaveForLaters/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /userCollectionSaveForLaters/{id}/relationships/owners
export def "user-collection-save-for-laters-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionSaveForLaters/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single userCollectionTrack.
#
# GET /userCollectionTracks/{id}
export def "user-collection-tracks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items, owners (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionTracks/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from items relationship ("to-many").
#
# DELETE /userCollectionTracks/{id}/relationships/items
export def "user-collection-tracks-relationships-items delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionTracks/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get items relationship ("to-many").
#
# GET /userCollectionTracks/{id}/relationships/items
export def "user-collection-tracks-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionTracks/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to items relationship ("to-many").
#
# POST /userCollectionTracks/{id}/relationships/items
export def "user-collection-tracks-relationships-items post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionTracks/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /userCollectionTracks/{id}/relationships/owners
export def "user-collection-tracks-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionTracks/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single userCollectionVideo.
#
# GET /userCollectionVideos/{id}
export def "user-collection-videos get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items, owners (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionVideos/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from items relationship ("to-many").
#
# DELETE /userCollectionVideos/{id}/relationships/items
export def "user-collection-videos-relationships-items delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionVideos/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get items relationship ("to-many").
#
# GET /userCollectionVideos/{id}/relationships/items
export def "user-collection-videos-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionVideos/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to items relationship ("to-many").
#
# POST /userCollectionVideos/{id}/relationships/items
export def "user-collection-videos-relationships-items post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollectionVideos/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /userCollectionVideos/{id}/relationships/owners
export def "user-collection-videos-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollectionVideos/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single userCollection.
#
# GET /userCollections/{id}
# DEPRECATED
@deprecated
export def "user-collections get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums, artists, owners, playlists, tracks, videos (e.g. albums)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollections/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from albums relationship ("to-many").
#
# DELETE /userCollections/{id}/relationships/albums
# DEPRECATED
@deprecated
export def "user-collections-relationships-albums delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollections/($id)/relationships/albums")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get albums relationship ("to-many").
#
# GET /userCollections/{id}/relationships/albums
# DEPRECATED
@deprecated
export def "user-collections-relationships-albums get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums (e.g. albums)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollections/($id)/relationships/albums" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to albums relationship ("to-many").
#
# POST /userCollections/{id}/relationships/albums
# DEPRECATED
@deprecated
export def "user-collections-relationships-albums post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollections/($id)/relationships/albums")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete from artists relationship ("to-many").
#
# DELETE /userCollections/{id}/relationships/artists
# DEPRECATED
@deprecated
export def "user-collections-relationships-artists delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollections/($id)/relationships/artists")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get artists relationship ("to-many").
#
# GET /userCollections/{id}/relationships/artists
# DEPRECATED
@deprecated
export def "user-collections-relationships-artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: artists (e.g. artists)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollections/($id)/relationships/artists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to artists relationship ("to-many").
#
# POST /userCollections/{id}/relationships/artists
# DEPRECATED
@deprecated
export def "user-collections-relationships-artists post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollections/($id)/relationships/artists")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /userCollections/{id}/relationships/owners
export def "user-collections-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollections/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from playlists relationship ("to-many").
#
# DELETE /userCollections/{id}/relationships/playlists
# DEPRECATED
@deprecated
export def "user-collections-relationships-playlists delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollections/($id)/relationships/playlists")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get playlists relationship ("to-many").
#
# GET /userCollections/{id}/relationships/playlists
# DEPRECATED
@deprecated
export def "user-collections-relationships-playlists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --collectionView: string@collectionView-completer-1
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --include: list # Allows the client to customize which related resources should be returned. Available options: playlists (e.g. playlists)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collectionView" $collectionView "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollections/($id)/relationships/playlists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to playlists relationship ("to-many").
#
# POST /userCollections/{id}/relationships/playlists
# DEPRECATED
@deprecated
export def "user-collections-relationships-playlists post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollections/($id)/relationships/playlists")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete from tracks relationship ("to-many").
#
# DELETE /userCollections/{id}/relationships/tracks
# DEPRECATED
@deprecated
export def "user-collections-relationships-tracks delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollections/($id)/relationships/tracks")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get tracks relationship ("to-many").
#
# GET /userCollections/{id}/relationships/tracks
# DEPRECATED
@deprecated
export def "user-collections-relationships-tracks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: tracks (e.g. tracks)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollections/($id)/relationships/tracks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to tracks relationship ("to-many").
#
# POST /userCollections/{id}/relationships/tracks
# DEPRECATED
@deprecated
export def "user-collections-relationships-tracks post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollections/($id)/relationships/tracks")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete from videos relationship ("to-many").
#
# DELETE /userCollections/{id}/relationships/videos
# DEPRECATED
@deprecated
export def "user-collections-relationships-videos delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollections/($id)/relationships/videos")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get videos relationship ("to-many").
#
# GET /userCollections/{id}/relationships/videos
# DEPRECATED
@deprecated
export def "user-collections-relationships-videos get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --qp-sort: list # Values prefixed with "-" are sorted descending; values without it are sorted ascending.
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: videos (e.g. videos)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userCollections/($id)/relationships/videos" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to videos relationship ("to-many").
#
# POST /userCollections/{id}/relationships/videos
# DEPRECATED
@deprecated
export def "user-collections-relationships-videos post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userCollections/($id)/relationships/videos")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single userDailyMixe.
#
# GET /userDailyMixes/{id}
export def "user-daily-mixes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userDailyMixes/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get items relationship ("to-many").
#
# GET /userDailyMixes/{id}/relationships/items
export def "user-daily-mixes-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userDailyMixes/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single userDataExportRequest.
#
# POST /userDataExportRequests
export def "user-data-export-requests post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/userDataExportRequests")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single userDiscoveryMixe.
#
# GET /userDiscoveryMixes/{id}
export def "user-discovery-mixes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userDiscoveryMixes/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get items relationship ("to-many").
#
# GET /userDiscoveryMixes/{id}/relationships/items
export def "user-discovery-mixes-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userDiscoveryMixes/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single userNewReleaseMixe.
#
# GET /userNewReleaseMixes/{id}
export def "user-new-release-mixes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userNewReleaseMixes/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get items relationship ("to-many").
#
# GET /userNewReleaseMixes/{id}/relationships/items
export def "user-new-release-mixes-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userNewReleaseMixes/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single userOfflineMixe.
#
# GET /userOfflineMixes/{id}
export def "user-offline-mixes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userOfflineMixes/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get items relationship ("to-many").
#
# GET /userOfflineMixes/{id}/relationships/items
export def "user-offline-mixes-relationships-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: items (e.g. items)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userOfflineMixes/($id)/relationships/items" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single userRecommendationBlock.
#
# GET /userRecommendationBlocks/{id}
export def "user-recommendation-blocks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: artists, owners, tracks, videos (e.g. artists)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userRecommendationBlocks/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from artists relationship ("to-many").
#
# DELETE /userRecommendationBlocks/{id}/relationships/artists
export def "user-recommendation-blocks-relationships-artists delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userRecommendationBlocks/($id)/relationships/artists")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get artists relationship ("to-many").
#
# GET /userRecommendationBlocks/{id}/relationships/artists
export def "user-recommendation-blocks-relationships-artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: artists (e.g. artists)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userRecommendationBlocks/($id)/relationships/artists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to artists relationship ("to-many").
#
# POST /userRecommendationBlocks/{id}/relationships/artists
export def "user-recommendation-blocks-relationships-artists post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userRecommendationBlocks/($id)/relationships/artists")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get owners relationship ("to-many").
#
# GET /userRecommendationBlocks/{id}/relationships/owners
export def "user-recommendation-blocks-relationships-owners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Allows the client to customize which related resources should be returned. Available options: owners (e.g. owners)
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/userRecommendationBlocks/($id)/relationships/owners" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete from tracks relationship ("to-many").
#
# DELETE /userRecommendationBlocks/{id}/relationships/tracks
export def "user-recommendation-blocks-relationships-tracks delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userRecommendationBlocks/($id)/relationships/tracks")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get tracks relationship ("to-many").
#
# GET /userRecommendationBlocks/{id}/relationships/tracks
export def "user-recommendation-blocks-relationships-tracks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: tracks (e.g. tracks)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userRecommendationBlocks/($id)/relationships/tracks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to tracks relationship ("to-many").
#
# POST /userRecommendationBlocks/{id}/relationships/tracks
export def "user-recommendation-blocks-relationships-tracks post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userRecommendationBlocks/($id)/relationships/tracks")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete from videos relationship ("to-many").
#
# DELETE /userRecommendationBlocks/{id}/relationships/videos
export def "user-recommendation-blocks-relationships-videos delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userRecommendationBlocks/($id)/relationships/videos")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get videos relationship ("to-many").
#
# GET /userRecommendationBlocks/{id}/relationships/videos
export def "user-recommendation-blocks-relationships-videos get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: videos (e.g. videos)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userRecommendationBlocks/($id)/relationships/videos" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add to videos relationship ("to-many").
#
# POST /userRecommendationBlocks/{id}/relationships/videos
export def "user-recommendation-blocks-relationships-videos post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/userRecommendationBlocks/($id)/relationships/videos")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single userRecommendation.
#
# GET /userRecommendations/{id}
# DEPRECATED
@deprecated
export def "user-recommendations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: discoveryMixes, myMixes, newArrivalMixes, offlineMixes (e.g. discoveryMixes)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userRecommendations/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get discoveryMixes relationship ("to-many").
#
# GET /userRecommendations/{id}/relationships/discoveryMixes
# DEPRECATED
@deprecated
export def "user-recommendations-relationships-discovery-mixes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: discoveryMixes (e.g. discoveryMixes)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userRecommendations/($id)/relationships/discoveryMixes" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get myMixes relationship ("to-many").
#
# GET /userRecommendations/{id}/relationships/myMixes
# DEPRECATED
@deprecated
export def "user-recommendations-relationships-my-mixes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: myMixes (e.g. myMixes)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userRecommendations/($id)/relationships/myMixes" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get newArrivalMixes relationship ("to-many").
#
# GET /userRecommendations/{id}/relationships/newArrivalMixes
# DEPRECATED
@deprecated
export def "user-recommendations-relationships-new-arrival-mixes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: newArrivalMixes (e.g. newArrivalMixes)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userRecommendations/($id)/relationships/newArrivalMixes" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get offlineMixes relationship ("to-many").
#
# GET /userRecommendations/{id}/relationships/offlineMixes
# DEPRECATED
@deprecated
export def "user-recommendations-relationships-offline-mixes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --locale: string # BCP 47 locale (e.g., en-US, nb-NO, pt-BR). Defaults to en-US if not provided or unsupported. (default: en-US, e.g. en-US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: offlineMixes (e.g. offlineMixes)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/userRecommendations/($id)/relationships/offlineMixes" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create single userReport.
#
# POST /userReports
export def "user-reports post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # Unique idempotency key for safe retry of mutation requests. If a duplicate key is sent with the same payload, the original response is replayed. If the payload differs, a 422 error is returned. (e.g. 79e1f37e-3e84-4c51-b5e2-7d9e1a2b3c4d)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/userReports")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get single user.
#
# GET /users/{id}
export def "users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single videoManifest.
#
# GET /videoManifests/{id}
export def "video-manifests get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --uriScheme: string@uriScheme-completer
  --usage: string@usage-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uriScheme" $uriScheme "scalar") (serialize-qp "usage" $usage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videoManifests/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple videos.
#
# GET /videos
export def "videos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums, artists, credits, providers, replacement, similarVideos, suggestedVideos, thumbnailArt, usageRules (e.g. albums)
  --filterid: list # List of video IDs (e.g. `75623239`)
  --filterisrc: list # List of ISRCs (e.g. `QMJMT1701237`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter[id]" $filterid "multi") (serialize-qp "filter[isrc]" $filterisrc "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/videos" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single video.
#
# GET /videos/{id}
export def "videos get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums, artists, credits, providers, replacement, similarVideos, suggestedVideos, thumbnailArt, usageRules (e.g. albums)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get albums relationship ("to-many").
#
# GET /videos/{id}/relationships/albums
export def "videos-relationships-albums get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: albums (e.g. albums)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($id)/relationships/albums" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get artists relationship ("to-many").
#
# GET /videos/{id}/relationships/artists
export def "videos-relationships-artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: artists (e.g. artists)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($id)/relationships/artists" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get credits relationship ("to-many").
#
# GET /videos/{id}/relationships/credits
export def "videos-relationships-credits get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --include: list # Allows the client to customize which related resources should be returned. Available options: credits (e.g. credits)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($id)/relationships/credits" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get providers relationship ("to-many").
#
# GET /videos/{id}/relationships/providers
export def "videos-relationships-providers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: providers (e.g. providers)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($id)/relationships/providers" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get replacement relationship ("to-one").
#
# GET /videos/{id}/relationships/replacement
export def "videos-relationships-replacement get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: replacement (e.g. replacement)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($id)/relationships/replacement" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get similarVideos relationship ("to-many").
#
# GET /videos/{id}/relationships/similarVideos
export def "videos-relationships-similar-videos get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: similarVideos (e.g. similarVideos)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($id)/relationships/similarVideos" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get suggestedVideos relationship ("to-many").
#
# GET /videos/{id}/relationships/suggestedVideos
export def "videos-relationships-suggested-videos get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: suggestedVideos (e.g. suggestedVideos)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($id)/relationships/suggestedVideos" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get thumbnailArt relationship ("to-many").
#
# GET /videos/{id}/relationships/thumbnailArt
export def "videos-relationships-thumbnail-art get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # Server-generated cursor value pointing a certain page of items. Optional, targets first page if not specified
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: thumbnailArt (e.g. thumbnailArt)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($id)/relationships/thumbnailArt" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get usageRules relationship ("to-one").
#
# GET /videos/{id}/relationships/usageRules
export def "videos-relationships-usage-rules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --countryCode: string # ISO 3166-1 alpha-2 country code (e.g. US)
  --include: list # Allows the client to customize which related resources should be returned. Available options: usageRules (e.g. usageRules)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($id)/relationships/usageRules" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
