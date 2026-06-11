# Auto-generated client for Discogs API vv2.0.0
# Source: https://raw.githubusercontent.com/wyattowalsh/discogs-api-spec/main/discogs.json
# Auth: --token flag or $env.DISCOGS_API_TOKEN

const BASE_URL = "https://api.discogs.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DISCOGS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "oauth" => { {headers: {Authorization: $"Oauth ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://api.discogs.com"] }
def auth-scheme-completer [] { ["bearer" "oauth"] }

# Completers for enum parameters
def type-completer [] { ["artist" "label" "master" "release"] }
def sort-completer [] { ["catno" "country" "format" "label" "released" "title"] }
def sort-order-completer [] { ["asc" "desc"] }
def sort-completer-1 [] { ["format" "title" "year"] }
def condition-completer [] { ["Fair (F)" "Good (G)" "Good Plus (G+)" "Mint (M)" "Near Mint (NM or M-)" "Poor (P)" "Very Good (VG)" "Very Good Plus (VG+)"] }
def sleeve-condition-completer [] { ["Fair (F)" "Generic" "Good (G)" "Good Plus (G+)" "Mint (M)" "Near Mint (NM or M-)" "No Cover" "Not Graded" "Poor (P)" "Very Good (VG)" "Very Good Plus (VG+)"] }
def status-completer [] { ["Draft" "For Sale"] }
def status-completer-1 [] { ["All" "Deleted" "Draft" "Expired" "For Sale" "Sold" "Suspended" "Violation"] }
def sort-completer-2 [] { ["artist" "audio" "catno" "item" "label" "listed" "location" "price" "status"] }
def curr-abbr-completer [] { ["AUD" "BRL" "CAD" "CHF" "EUR" "GBP" "JPY" "MXN" "NZD" "SEK" "USD" "ZAR"] }
def sort-completer-3 [] { ["added" "artist" "catno" "format" "label" "rating" "title" "year"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "database-search searchDatabase" } } | get name | first)
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

# Search the database
#
# GET /database/search
# operationId: searchDatabase
export def "database-search searchDatabase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Your search query. (e.g. The Cure)
  --type: string@type-completer # The type of resource to search for.
  --title: string # Search by combined "Artist Name - Release Title" field. (e.g. The Cure - Disintegration)
  --release-title: string # Search release titles. (e.g. Disintegration)
  --credit: string # Search release credits. (e.g. Robert Smith)
  --artist: string # Search artist names. (e.g. The Cure)
  --anv: string # Search an "Artist Name Variation" (ANV).
  --label: string # Search label names. (e.g. Fiction Records)
  --genre: string # Search genres. (e.g. Rock)
  --style: string # Search styles. (e.g. Gothic Rock)
  --country: string # Search release country. (e.g. UK)
  --year: string # Search release year. (e.g. 1989)
  --format: string # Search formats. (e.g. Vinyl)
  --catno: string # Search catalog number. (e.g. FIXH 14)
  --barcode: string # Search barcodes. (e.g. 042283923518)
  --track: string # Search track titles. (e.g. Lovesong)
  --submitter: string # Search by submitter username.
  --contributor: string # Search by contributor username.
  --page: int # The page number to return. (default: 1)
  --per-page: int # The number of items to return per page. (default: 50)
]: nothing -> record<pagination: record<page: int, pages: int, per_page: int, items: int, urls: record<first: string, prev: string, next: string, last: string>>, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "release_title" $release_title "scalar") (serialize-qp "credit" $credit "scalar") (serialize-qp "artist" $artist "scalar") (serialize-qp "anv" $anv "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "genre" $genre "scalar") (serialize-qp "style" $style "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "catno" $catno "scalar") (serialize-qp "barcode" $barcode "scalar") (serialize-qp "track" $track "scalar") (serialize-qp "submitter" $submitter "scalar") (serialize-qp "contributor" $contributor "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/database/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a release
#
# GET /releases/{release_id}
# operationId: getRelease
export def "releases get" [
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --curr-abbr: string # Currency for marketplace data.
]: nothing -> record<id: int, title: string, resource_url: string, uri: string, status: string, data_quality: string, thumb: string, country: string, year: int, notes: string, released: string, released_formatted: string, date_added: string, date_changed: string, lowest_price: float, num_for_sale: int, estimated_weight: int, format_quantity: int, master_id: int, master_url: string, artists: table<id: int, name: string, resource_url: string, anv: string, join: string, role: string, tracks: string>, labels: table<id: int, name: string, resource_url: string, catno: string, entity_type: string>, extraartists: table<id: int, name: string, resource_url: string, anv: string, join: string, role: string, tracks: string>, formats: table<name: string, qty: string, text: string, descriptions: list>, genres: list<string>, styles: list<string>, community: record<have: int, want: int, rating: record<count: int, average: float>, submitter: record<id: int, username: string, resource_url: string>, contributors: list<record>, data_quality: string, status: string>, companies: table<id: int, name: string, resource_url: string, catno: string, entity_type: string>, tracklist: table<position: string, type_: string, title: string, duration: string, extraartists: list>, videos: table<uri: string, duration: int, title: string, description: string, embed: bool>, identifiers: table<type: string, value: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "curr_abbr" $curr_abbr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/releases/($release_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a master release
#
# GET /masters/{master_id}
# operationId: getMasterRelease
export def "masters get" [
  master_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masters/($master_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get master release versions
#
# GET /masters/{master_id}/versions
# operationId: getMasterReleaseVersions
export def "masters-versions get" [
  master_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. (default: 1)
  --per-page: int # The number of items to return per page. (default: 50)
  --format: string # Filter by format.
  --label: string # Filter by label.
  --released: string # Filter by release year.
  --country: string # Filter by country.
  --qp-sort: string@sort-completer # The field to sort the results by. (default: released)
  --sort-order: string@sort-order-completer # The order to sort the results. (default: desc)
]: nothing -> record<pagination: record<page: int, pages: int, per_page: int, items: int, urls: record<first: string, prev: string, next: string, last: string>>, versions: table<id: int, resource_url: string, status: string, thumb: string, format: string, country: string, title: string, label: string, released: string, major_formats: list, catno: string, stats: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "released" $released "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/masters/($master_id)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an artist
#
# GET /artists/{artist_id}
# operationId: getArtist
export def "artists get" [
  artist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, realname: string, resource_url: string, uri: string, releases_url: string, profile: string, urls: list<string>, namevariations: list<string>, members: table<id: int, name: string, resource_url: string, anv: string, join: string, role: string, tracks: string>, images: table<type: string, uri: string, resource_url: string, uri150: string, width: int, height: int>, data_quality: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artists/($artist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get artist releases
#
# GET /artists/{artist_id}/releases
# operationId: getArtistReleases
export def "artists-releases get" [
  artist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. (default: 1)
  --per-page: int # The number of items to return per page. (default: 50)
  --qp-sort: string@sort-completer-1 # The field to sort the results by. (default: year)
  --sort-order: string@sort-order-completer # The order to sort the results. (default: desc)
]: nothing -> record<pagination: record<page: int, pages: int, per_page: int, items: int, urls: record<first: string, prev: string, next: string, last: string>>, releases: table<id: int, resource_url: string, type: string, title: string, thumb: string, artist: string, role: string, year: int, format: string, label: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artists/($artist_id)/releases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a label
#
# GET /labels/{label_id}
# operationId: getLabel
export def "labels get" [
  label_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, resource_url: string, uri: string, releases_url: string, profile: string, contact_info: string, parent_label: record<id: int, name: string, resource_url: string, catno: string, entity_type: string>, sublabels: table<id: int, name: string, resource_url: string, catno: string, entity_type: string>, urls: list<string>, images: table<type: string, uri: string, resource_url: string, uri150: string, width: int, height: int>, data_quality: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($label_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all label releases
#
# GET /labels/{label_id}/releases
# operationId: getLabelReleases
export def "labels-releases get" [
  label_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. (default: 1)
  --per-page: int # The number of items to return per page. (default: 50)
]: nothing -> record<pagination: record<page: int, pages: int, per_page: int, items: int, urls: record<first: string, prev: string, next: string, last: string>>, releases: table<id: int, resource_url: string, thumb: string, artist: string, title: string, format: string, catno: string, status: string, year: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/labels/($label_id)/releases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a listing
#
# GET /marketplace/listings/{listing_id}
# operationId: getListing
export def "marketplace-listings get" [
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --curr-abbr: string # Currency for marketplace data.
]: nothing -> record<id: int, resource_url: string, uri: string, status: string, price: record<currency: string, value: float>, allow_offers: bool, sleeve_condition: string, condition: string, posted: string, ships_from: string, comments: string, seller: record<id: int, username: string, resource_url: string>, release: record<id: int, resource_url: string, description: string, thumbnail: string, artist: string, title: string, year: int, format: string, catalog_number: string>, audio: bool, weight: int, format_quantity: int, external_id: string, location: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "curr_abbr" $curr_abbr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketplace/listings/($listing_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a listing
#
# POST /marketplace/listings/{listing_id}
# operationId: editListing
export def "marketplace-listings editListing" [
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  release_id: int # The ID of the release.
  condition: string@condition-completer
  --sleeve-condition: string@sleeve-condition-completer
  price: float # The price of the item in the seller's currency. (format: float)
  --comments: string # Any remarks about the item.
  --allow-offers: string@bool-completer # default: false
  status: string@status-completer # The status of the listing. (default: For Sale)
  --external-id: string # Private comments for the seller.
  --location: string # Physical location of the item.
  --weight: int # The weight in grams.
  --format-quantity: int # How many units this item counts as for shipping.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "oauth"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketplace/listings/($listing_id)")
  let body = {release_id: $release_id, condition: $condition, sleeve_condition: $sleeve_condition, price: $price, comments: $comments, allow_offers: $allow_offers, status: $status, external_id: $external_id, location: $location, weight: $weight, format_quantity: $format_quantity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a listing
#
# DELETE /marketplace/listings/{listing_id}
# operationId: deleteListing
export def "marketplace-listings delete" [
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "oauth"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketplace/listings/($listing_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new listing
#
# POST /marketplace/listings
# operationId: createListing
export def "marketplace-listings createListing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  release_id: int # The ID of the release.
  condition: string@condition-completer
  --sleeve-condition: string@sleeve-condition-completer
  price: float # The price of the item in the seller's currency. (format: float)
  --comments: string # Any remarks about the item.
  --allow-offers: string@bool-completer # default: false
  status: string@status-completer # The status of the listing. (default: For Sale)
  --external-id: string # Private comments for the seller.
  --location: string # Physical location of the item.
  --weight: int # The weight in grams.
  --format-quantity: int # How many units this item counts as for shipping.
]: any -> record<listing_id: int, resource_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "oauth"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketplace/listings")
  let body = {release_id: $release_id, condition: $condition, sleeve_condition: $sleeve_condition, price: $price, comments: $comments, allow_offers: $allow_offers, status: $status, external_id: $external_id, location: $location, weight: $weight, format_quantity: $format_quantity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user inventory
#
# GET /users/{username}/inventory
# operationId: getUserInventory
export def "users-inventory get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # Only show items with this status. (default: For Sale)
  --page: int # The page number to return. (default: 1)
  --per-page: int # The number of items to return per page. (default: 50)
  --qp-sort: string@sort-completer-2 # Sort items by this field. (default: listed)
  --sort-order: string@sort-order-completer # The order to sort the results. (default: desc)
]: nothing -> record<pagination: record<page: int, pages: int, per_page: int, items: int, urls: record<first: string, prev: string, next: string, last: string>>, listings: table<id: int, resource_url: string, uri: string, status: string, price: record, allow_offers: bool, sleeve_condition: string, condition: string, posted: string, ships_from: string, comments: string, seller: record, release: record, audio: bool, weight: int, format_quantity: int, external_id: string, location: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/inventory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user identity
#
# GET /oauth/identity
# operationId: getUserIdentity
export def "oauth-identity get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, username: string, resource_url: string, consumer_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "oauth"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/identity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user profile
#
# GET /users/{username}
# operationId: getUserProfile
export def "users get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, username: string, resource_url: string, uri: string, name: string, home_page: string, location: string, profile: string, registered: string, rank: float, num_pending: int, num_for_sale: int, num_collection: int, num_wantlist: int, num_lists: int, releases_contributed: int, releases_rated: int, rating_avg: float, inventory_url: string, collection_folders_url: string, collection_fields_url: string, wantlist_url: string, avatar_url: string, banner_url: string, curr_abbr: string, seller_rating: float, seller_num_ratings: int, buyer_rating: float, buyer_num_ratings: int, email: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a user profile
#
# POST /users/{username}
# operationId: editUserProfile
export def "users editUserProfile" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The real name of the user.
  --home-page: string # The user's website. (format: uri)
  --location: string # The geographical location of the user.
  --profile: string # Biographical information about the user. Supports Discogs markup.
  --curr-abbr: string@curr-abbr-completer
]: any -> record<id: int, username: string, resource_url: string, uri: string, name: string, home_page: string, location: string, profile: string, registered: string, rank: float, num_pending: int, num_for_sale: int, num_collection: int, num_wantlist: int, num_lists: int, releases_contributed: int, releases_rated: int, rating_avg: float, inventory_url: string, collection_folders_url: string, collection_fields_url: string, wantlist_url: string, avatar_url: string, banner_url: string, curr_abbr: string, seller_rating: float, seller_num_ratings: int, buyer_rating: float, buyer_num_ratings: int, email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "oauth"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)")
  let body = {name: $name, home_page: $home_page, location: $location, profile: $profile, curr_abbr: $curr_abbr} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get collection folders
#
# GET /users/{username}/collection/folders
# operationId: getCollectionFolders
export def "users-collection-folders get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<folders: table<id: int, name: string, count: int, resource_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)/collection/folders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a collection folder
#
# POST /users/{username}/collection/folders
# operationId: createCollectionFolder
export def "users-collection-folders createCollectionFolder" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the new folder. (e.g. My Favorites)
]: any -> record<id: int, name: string, count: int, resource_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "oauth"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)/collection/folders")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get collection items by folder
#
# GET /users/{username}/collection/folders/{folder_id}/releases
# operationId: getCollectionItemsByFolder
export def "users-collection-folders-releases get" [
  username: string
  folder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. (default: 1)
  --per-page: int # The number of items to return per page. (default: 50)
  --qp-sort: string@sort-completer-3 # The field to sort the results by. (default: added)
  --sort-order: string@sort-order-completer # The order to sort the results. (default: desc)
]: nothing -> record<pagination: record<page: int, pages: int, per_page: int, items: int, urls: record<first: string, prev: string, next: string, last: string>>, releases: table<id: int, instance_id: int, folder_id: int, rating: int, date_added: string, basic_information: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/collection/folders/($folder_id)/releases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add release to collection folder
#
# POST /users/{username}/collection/folders/{folder_id}/releases/{release_id}
# operationId: addReleaseToCollectionFolder
export def "users-collection-folders-releases addReleaseToCollectionFolder" [
  username: string
  folder_id: int
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<instance_id: int, resource_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "oauth"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)/collection/folders/($folder_id)/releases/($release_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user wantlist
#
# GET /users/{username}/wants
# operationId: getUserWantlist
export def "users-wants get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. (default: 1)
  --per-page: int # The number of items to return per page. (default: 50)
]: nothing -> record<pagination: record<page: int, pages: int, per_page: int, items: int, urls: record<first: string, prev: string, next: string, last: string>>, wants: table<id: int, resource_url: string, rating: int, notes: string, basic_information: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/wants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add release to wantlist
#
# PUT /users/{username}/wants/{release_id}
# operationId: addReleaseToWantlist
export def "users-wants addReleaseToWantlist" [
  username: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notes: string # User notes for this item.
  --rating: int # User's rating for the release (0-5). (default: 0)
]: any -> record<id: int, resource_url: string, rating: int, notes: string, basic_information: record<id: int, title: string, year: int, resource_url: string, thumb: string, cover_image: string, formats: list<record>, labels: list<record>, artists: list<record>, genres: list<string>, styles: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "oauth"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)/wants/($release_id)")
  let body = {notes: $notes, rating: $rating} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete release from wantlist
#
# DELETE /users/{username}/wants/{release_id}
# operationId: deleteReleaseFromWantlist
export def "users-wants delete" [
  username: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "oauth"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)/wants/($release_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
