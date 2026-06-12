# Auto-generated client for Getty Images v3
# Source: https://api.apis.guru/v2/specs/gettyimages.com/3/openapi.json
# Auth: --token flag or $env.GETTY_IMAGES_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GETTY_IMAGES_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-key" => { {headers: {Api-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["api-key" "bearer"] }

# Completers for enum parameters
def style-completer [] { ["photography" "vector"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def board-relationship-completer [] { ["invited" "owned"] }
def sort-order-completer [] { ["date_last_updated_ascending" "date_last_updated_descending" "name_ascending" "name_decending"] }
def product-type-completer [] { ["creditpack" "easyaccess" "editorialsubscription" "imagepack" "premiumaccess" "royaltyfreesubscription"] }
def file-type-completer [] { ["eps" "jpg"] }
def editorial-segment-completer [] { ["archival" "entertainment" "news" "publicity" "royalty" "sport"] }
def sort-order-completer-1 [] { ["newest" "oldest"] }
def collections-filter-type-completer [] { ["exclude" "include"] }
def graphical-styles-filter-type-completer [] { ["exclude" "include"] }
def minimum-size-completer [] { ["large" "medium" "small" "vector" "x_large" "x_small" "xx_large"] }
def sort-order-completer-2 [] { ["best_match" "most_popular" "newest" "random"] }
def sort-order-completer-3 [] { ["best_match" "most_popular" "newest" "oldest" "random"] }
def format-available-completer [] { ["4k" "hd" "hd_web" "sd"] }
def release-status-completer [] { ["fully_released" "release_not_important"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "affiliates-search-images get" } } | get name | first)
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

# GET /v3/affiliates/search/images
export def "affiliates-search-images get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --phrase: string # Search images using a search phrase. (nullable)
  --style: string@style-completer # Filter based on graphical style of the image.
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<auto_corrections: record<phrase: string>, images: table<caption: string, destination_url: string, id: string, preview_urls: record, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "phrase" $phrase "scalar") (serialize-qp "style" $style "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/affiliates/search/images" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v3/affiliates/search/videos
export def "affiliates-search-videos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --phrase: string # nullable
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<auto_corrections: record<phrase: string>, videos: table<caption: string, clip_length: string, destination_url: string, id: string, preview_urls: record, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "phrase" $phrase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/affiliates/search/videos" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for images by a photographer
#
# GET /v3/artists/images
export def "artists-images get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --artist-name: string # Name of artist for desired images (nullable)
  --qp-fields: list # Comma separated list of fields. Allows restricting which fields are returned. If no fields are selected, the summary_set of fields are returned. (nullable)
  --page: int # Identifies page to return. Default page is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default page_size is 10, maximum page_size is 100. (format: int32, default: 10)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "artist_name" $artist_name "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/artists/images" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for videos by a photographer
#
# GET /v3/artists/videos
export def "artists-videos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --artist-name: string # Name of artist for desired images (nullable)
  --qp-fields: list # Comma separated list of fields. Allows restricting which fields are returned. If no fields are selected, the summary_set of fields are returned. (nullable)
  --page: int # Identifies page to return. Default page is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default page_size is 10, maximum page_size is 100. (format: int32, default: 10)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "artist_name" $artist_name "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/artists/videos" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get asset change notifications.
#
# PUT /v3/asset-changes/change-sets
export def "asset-changes-change-sets put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-id: int # Specifies the id of the channel for the asset data. Valid channel ids can be found in the results of the Get Partner Channel query. (format: int32)
  --batch-size: int # Specifies the number of assets to return. The default is 2200; maximum is 2200. (nullable, format: int32)
]: nothing -> record<change_set_id: string, changed_assets: table<asset_changed_utc_datetime: string, asset_lifecycle: string, asset_type: string, id: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channel_id" $channel_id "scalar") (serialize-qp "batch_size" $batch_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/asset-changes/change-sets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Confirm asset change notifications.
#
# DELETE /v3/asset-changes/change-sets/{change-set-id}
export def "asset-changes-change-sets delete" [
  change_set_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/asset-changes/change-sets/($change_set_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of asset change notification channels.
#
# GET /v3/asset-changes/channels
export def "asset-changes-channels get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AssetChangeType: string, AssetFamily: string, AssetType: string, ChannelId: int, CreateDateUtc: string, Metadata: string, NotificationCount: int, OldestChangeNotificationDateUtc: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/asset-changes/channels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Endpoint for acquiring extended licenses with iStock credits for an asset.
#
# POST /v3/asset-licensing/{assetId}
export def "asset-licensing post" [
  assetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  extended_licenses: list
  --use-team-credits: oneof<nothing, bool> # Defaults to false.
]: any -> record<acquired_licenses: list<string>, credits_used: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/asset-licensing/($assetId)")
  let body = {extended_licenses: $extended_licenses, use_team_credits: $use_team_credits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v3/asset-management/assets/send-events
export def "asset-management-assets-send-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --last-offset: string # Specifies a date/time (with timezone information) for continuing retrieval of events. Events occuring _after_ the `last_offset` value provided will be returned. (nullable, format: date-time)
  --event-count: int # Specifies the number of events to return. Default is 50, maximum value is 100. (nullable, format: int32)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<asset_send_events: table<asset_id: string, email_address: string, timestamp: string>, last_offset: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_offset" $last_offset "scalar") (serialize-qp "event_count" $event_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/asset-management/assets/send-events" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all boards that the user participates in
#
# GET /v3/boards
export def "boards list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --board-relationship: string@board-relationship-completer # Search for boards the user owns or has been invited to as an editor.
  --sort-order: string@sort-order-completer # Sort the list of boards by last update date or name. Defaults to date_last_updated_descending.
  --pageSize: int # Request number of boards to return in each page. (default is 30). (format: int32, default: 30)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<board_count: int, boards: table<asset_count: int, board_relationship: string, date_created: string, date_last_updated: string, description: string, hero_asset: record, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "board_relationship" $board_relationship "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/boards" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new board
#
# POST /v3/boards
export def "boards post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --description: string # nullable
  name: string
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/boards")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a board
#
# DELETE /v3/boards/{board_id}
export def "boards delete" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/boards/($board_id)")
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get assets and metadata for a specific board
#
# GET /v3/boards/{board_id}
export def "boards get" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<asset_count: int, assets: table<asset_type: string, date_added: string, display_sizes: list, id: string>, comment_count: int, date_created: string, date_last_updated: string, description: string, id: string, links: record<invitation: string, share: string>, name: string, permissions: record<can_add_assets: bool, can_delete_board: bool, can_invite_to_board: bool, can_remove_assets: bool, can_update_description: bool, can_update_name: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/boards/($board_id)")
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a board
#
# PUT /v3/boards/{board_id}
export def "boards put" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --description: string # nullable
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/boards/($board_id)")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove assets from a board
#
# DELETE /v3/boards/{board_id}/assets
export def "boards-assets delete-by-board_id" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-ids: list # List the assets to be removed from the board. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset_ids" $asset_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/boards/($board_id)/assets" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add assets to a board
#
# PUT /v3/boards/{board_id}/assets
export def "boards-assets put-by-board_id" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --body: record
]: any -> record<assets_added: table<asset_id: string>, assets_not_added: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/boards/($board_id)/assets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an asset from a board
#
# DELETE /v3/boards/{board_id}/assets/{asset_id}
export def "boards-assets delete-by-board_id-asset_id" [
  board_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/boards/($board_id)/assets/($asset_id)")
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an asset to a board
#
# PUT /v3/boards/{board_id}/assets/{asset_id}
export def "boards-assets put-by-board_id-asset_id" [
  board_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/boards/($board_id)/assets/($asset_id)")
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get comments from a board
#
# GET /v3/boards/{board_id}/comments
export def "boards-comments get" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<comments: table<created_by: record, date_created: string, id: string, permissions: record, text: string>, permissions: record<can_add_comment: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/boards/($board_id)/comments")
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a comment to a board
#
# POST /v3/boards/{board_id}/comments
export def "boards-comments post" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --text: string # nullable
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/boards/($board_id)/comments")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a comment from a board
#
# DELETE /v3/boards/{board_id}/comments/{comment_id}
export def "boards-comments delete" [
  board_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/boards/($board_id)/comments/($comment_id)")
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets collections applicable for the customer.
#
# GET /v3/collections
export def "collections get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<collections: table<asset_family: string, code: string, id: int, license_model: string, name: string, product_types: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/collections")
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets countries codes and names.
#
# GET /v3/countries
export def "countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<countries: table<iso_alpha_2: string, iso_alpha_3: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/countries")
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about the current user.
#
# GET /v3/customers/current
export def "customers-current get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<first_name: string, last_name: string, middle_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/customers/current")
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a customer's downloaded assets.
#
# GET /v3/downloads
export def "downloads get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # If specified, selects assets downloaded on or after this date. Dates should be submitted in ISO 8601 format (i.e., YYYY-MM-DD).  Any hour, minute, second values in the request are not used, unless useTimePart parameter is included. Date/times in the response are UTC. Default is 30 days prior to date_to (nullable, format: date-time)
  --date-to: string # If specified, selects assets downloaded on or before this date. Dates should be submitted in ISO 8601 format (i.e., YYYY-MM-DD) Any hour, minute, second values in the request are not used, unless useTimePart parameter is included. Date/times in the response are UTC. Default is current date or 30 days after specified start date, whichever one is earlier. (nullable, format: date-time)
  --use-time: oneof<nothing, bool> # If specified, time values provided with date_to or date_from will be used. Time values should be appended to the date value in ISO 8601 format i.e.: 2019-09-19T19:30:37 or 2019-09-19 19:30:37.  Time zone can be specified as optional. Default value is false (default: false)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --product-type: string@product-type-completer # Specifies product type to be included in the previous download results. Product types easyaccess, editorialsubscription, imagepack, and premiumaccess are for GettyImages API keys. Product types royaltyfreesubscription and creditpack are for iStock API keys. To get previous iStockPhoto credit downloads, creditpack must be selected.
  --company-downloads: oneof<nothing, bool> # If specified, returns the list of previously downloaded images for all users in your company. Your account must be enabled for this functionality. Contact your Getty Images account rep for more information. Default is false. (default: false)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<downloads: table<agreement_name: string, asset_type: string, date_downloaded: string, dimensions: record, download_details: record, download_source: string, id: string, product_id: int, product_type: string, size_name: string, thumb_uri: string, user: record>, result_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "use_time" $use_time "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "product_type" $product_type "scalar") (serialize-qp "company_downloads" $company_downloads "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/downloads" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download an image
#
# POST /v3/downloads/images/{id}
export def "downloads-images post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-download: oneof<nothing, bool> # <remarks>                     Specifies whether to auto-download the image. If true is specified, a 303 SeeOther status is returned with a                     Location header set to the location of the image.                     If false is specified, the download URI will be returned in the response message. Default is true.                 </remarks> (default: true)
  --file-type: string@file-type-completer # <remarks>                     File Type expressed with three character file extension.                 </remarks>
  --height: string # <remarks>                     Specifies the pixel height of the particular image to download.                     Available heights can be found in the images/{ids} response for the specific image.                     If left blank, it will return the largest available size.                 </remarks> (nullable)
  --product-id: int # <remarks>                     Identifier of the instance for the selected product offering type.                 </remarks> (nullable, format: int32)
  --product-type: string@product-type-completer # <remarks>                     Product types easyaccess, editorialsubscription, imagepack, and premiumaccess are for GettyImages API keys. Product types royaltyfreesubscription and creditpack are for iStock API keys. Default product type for iStock API keys is creditpack.                 </remarks>
  --use-team-credits: oneof<nothing, bool> # Specifies whether to download the image with iStock Team Credits. Only applicable to iStock API keys authenticated with a user that has Team Credits. Blank is the same as False. (nullable, default: false)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --download-notes: string # nullable
  --project-code: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "auto_download" $auto_download "scalar") (serialize-qp "file_type" $file_type "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "product_type" $product_type "scalar") (serialize-qp "use_team_credits" $use_team_credits "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/downloads/images/($id)" $qp)
  let body = {download_notes: $download_notes, project_code: $project_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download a video
#
# POST /v3/downloads/videos/{id}
export def "downloads-videos post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-download: oneof<nothing, bool> # <remarks>                     Specifies whether to auto-download the video. If true is specified, a 303 SeeOther status is returned with a                     Location header set to the location of the video.                     If false is specified, the download URI will be returned in the response message. Default is false.                 </remarks> (default: false)
  --size: string # Specifies the size to be downloaded. (nullable)
  --product-id: int # <remarks>                     Identifier of the instance for the selected product offering type.                 </remarks> (nullable, format: int32)
  --product-type: string@product-type-completer # <remarks>                     Product types easyaccess, editorialsubscription, imagepack, and premiumaccess are for GettyImages API keys. Product types royaltyfreesubscription and creditpack are for iStock API keys. Default product type for iStock API keys is creditpack.                 </remarks>
  --use-team-credits: oneof<nothing, bool> # Specifies whether to download the image with iStock Team Credits. Only applicable to iStock API keys authenticated with a user that has Team Credits. Blank is the same as False. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --download-notes: string # nullable
  --project-code: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "auto_download" $auto_download "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "product_type" $product_type "scalar") (serialize-qp "use_team_credits" $use_team_credits "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/downloads/videos/($id)" $qp)
  let body = {download_notes: $download_notes, project_code: $project_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get metadata for multiple events
#
# GET /v3/events
export def "events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # A comma separated list of event ids. (nullable)
  --qp-fields: list # A comma separated list of fields to return in the response. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/events" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metadata for a single event
#
# GET /v3/events/{id}
export def "events get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # A comma separated list of fields to return in the response. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/events/($id)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metadata for multiple images by supplying multiple image ids
#
# GET /v3/images
export def "images list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # Specifies one or more image ids to return. Use comma delimiter when requesting multiple ids.  Maximum of 100 ids. (nullable)
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<images: any, images_not_found: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/images" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metadata for a single image by supplying one image id
#
# GET /v3/images/{id}
export def "images get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<images: any, images_not_found: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/images/($id)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a customer's download history for a specific asset
#
# GET /v3/images/{id}/downloadhistory
export def "images-downloadhistory get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-downloads: oneof<nothing, bool> # If specified, returns the list of previously downloaded images for all users in your company.             Your account must be enabled for this functionality. Contact your Getty Images account rep for more information. Default is false.
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<downloads: any, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_downloads" $company_downloads "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/images/($id)/downloadhistory" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve creative images from the same series
#
# GET /v3/images/{id}/same-series
export def "images-same-series get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, event_ids: list, graphical_style: string, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/images/($id)/same-series" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve similar images
#
# GET /v3/images/{id}/similar
export def "images-similar get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, event_ids: list, graphical_style: string, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/images/($id)/similar" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get order metadata
#
# GET /v3/orders/{id}
export def "orders get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<assets: table<id: string>, end_client: string, id: string, invoice_number: string, notes: record<licensee_name: string, ordered_by: string, project_title: string, purchase_order_number: string>, order_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/orders/($id)")
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Products
#
# GET /v3/products
export def "products get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Comma separated list of fields. Allows product download requirements to be returned. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<products: table<agreement_name: string, application_website: string, credits_remaining: int, download_limit: int, download_limit_duration: string, download_limit_reset_utc_date: string, download_requirements: record, downloads_remaining: int, expiration_utc_date: string, id: int, imagepack_resolution: string, name: string, overage: record, status: string, team_credits: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/products" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Previously Purchased Images and Video
#
# GET /v3/purchased-assets
export def "purchased-assets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-to: string # If specified, retrieves previous purchases on or before this date. Dates should be submitted in ISO 8601 format (i.e., YYYY-MM-DD). (nullable, format: date-time)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 75, maximum page_size is 100. (format: int32, default: 75)
  --date-from: string # If specified, retrieves previous purchases on or after this date. Dates should be submitted in ISO 8601 format (i.e., YYYY-MM-DD). (nullable, format: date-time)
  --company-purchases: oneof<nothing, bool> # If specified, returns the list of previously purchased assets for all users in your company. Your account must be enabled for this functionality. Contact your Getty Images account rep for more information. Default is false. (default: false)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<previous_purchases: table<asset_id: string, asset_type: string, date_purchased: string, download_uri: string, file_size_in_bytes: string, license_model: string, order_id: string, purchased_by: string, size_name: string, thumb_uri: string>, result_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_to" $date_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "company_purchases" $company_purchases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/purchased-assets" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload image for use by the search creative images/videos operations
#
# PUT /v3/search/by-image/uploads/{file-name}
export def "search-by-image-uploads put" [
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/search/by-image/uploads/($file_name)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "image/jpeg" $body
}

# Search for events
#
# GET /v3/search/events
export def "search-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --editorial-segment: string@editorial-segment-completer # Filters to events with a matching editorial segment.
  --date-from: string # Filters to events that start on or after this date. Use ISO 8601 format (e.g., 1999-12-31). Defaults to UTC unless otherwise specified. (nullable, format: date-time)
  --date-to: string # Filters to events that start on or before this date. Use ISO 8601 format (e.g., 1999-12-31). Defaults to UTC unless otherwise specified. (nullable, format: date-time)
  --qp-fields: list # Specifies fields to return. Default set is 'id','name','start_date'. (nullable)
  --page: int # Request results starting at a page number (default is 1, maximum is 50). (format: int32, default: 1)
  --page-size: int # Request number of events to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Filters to events related to this phrase (nullable, default: )
  --sort-order: string@sort-order-completer-1 # Specifies the order in which to sort the results. Default is `newest`.
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --GI-Country-Code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> record<events: table<child_event_count: int, editorial_segments: list, hero_image: record, id: int, image_count: int, location: record, name: string, start_date: string>, result_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "editorial_segment" $editorial_segment "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "phrase" $phrase "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/search/events" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language, "GI-Country-Code": $GI_Country_Code} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for both creative and editorial images - *** DEPRECATED ***
#
# GET /v3/search/images
export def "search-images get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-of-people: list # Filter based on the age of individuals in an image. (nullable)
  --artists: string # Search for images by specific artists (free-text, comma-separated list of artists). (nullable)
  --collection-codes: list # Filter by collection codes (comma-separated list). Include or exclude based on collections_filter_type. (nullable)
  --collections-filter-type: string@collections-filter-type-completer # Provides searching based on specified collection(s). The default is Include
  --color: string # Filter based on predominant color in an image. Use 6 character hexidecimal format (e.g., #002244). Note: when specified, results will not contain editorial images. (nullable)
  --compositions: list # Filter based on image composition. (nullable)
  --download-product: string # Filters based on which product the asset will download against.                     Allowed values are easyaccess, editorialsubscription, imagepack, premiumaccess and royaltyfreesubscription.                     If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on.                      For example, some users may have more than one premiumaccess product, so the download_product value would be premiumaccess:1234.                      Product ID can be obtained from the GET /products response. (nullable)
  --embed-content-only: oneof<nothing, bool> # Restrict search results to embeddable images. The default is false. (default: false)
  --event-ids: list # Filter based on specific events (nullable)
  --ethnicity: list # Filter search results based on the ethnicity of individuals in an image. (nullable)
  --exclude-nudity: oneof<nothing, bool> # Excludes images containing nudity. The default is false. (default: false)
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. (nullable)
  --file-types: list # Return only images having a specific file type. (nullable)
  --graphical-styles: list # Filter based on graphical style of the image. (nullable)
  --graphical-styles-filter-type: string@graphical-styles-filter-type-completer # Provides searching based on specified graphical style(s). The default is Include
  --include-related-searches: oneof<nothing, bool> # Specifies whether or not to include related searches in the response. The default is false. (default: false)
  --keyword-ids: list # Return only images tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those images matching the query phrase which also contain the requested keyword(s) are returned. (nullable)
  --minimum-size: string@minimum-size-completer # Filter based on minimum size requested. The default is x-small
  --number-of-people: list # Filter based on the number of people in the image. (nullable)
  --orientations: list # Return only images with selected aspect ratios. (nullable)
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --page-size: int # Request number of images to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Search images using a search phrase. (nullable)
  --sort-order: string@sort-order-completer-2 # Select sort order of results.  The default is best_match
  --specific-people: list # Return only images associated with specific people (using a comma-delimited list). (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --GI-Country-Code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, event_ids: list, graphical_style: string, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age_of_people" $age_of_people "csv") (serialize-qp "artists" $artists "scalar") (serialize-qp "collection_codes" $collection_codes "csv") (serialize-qp "collections_filter_type" $collections_filter_type "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "compositions" $compositions "csv") (serialize-qp "download_product" $download_product "scalar") (serialize-qp "embed_content_only" $embed_content_only "scalar") (serialize-qp "event_ids" $event_ids "csv") (serialize-qp "ethnicity" $ethnicity "csv") (serialize-qp "exclude_nudity" $exclude_nudity "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "file_types" $file_types "csv") (serialize-qp "graphical_styles" $graphical_styles "csv") (serialize-qp "graphical_styles_filter_type" $graphical_styles_filter_type "scalar") (serialize-qp "include_related_searches" $include_related_searches "scalar") (serialize-qp "keyword_ids" $keyword_ids "csv") (serialize-qp "minimum_size" $minimum_size "scalar") (serialize-qp "number_of_people" $number_of_people "csv") (serialize-qp "orientations" $orientations "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "phrase" $phrase "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "specific_people" $specific_people "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/search/images" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language, "GI-Country-Code": $GI_Country_Code} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for creative images only
#
# GET /v3/search/images/creative
export def "search-images-creative get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-of-people: list # Filter based on the age of individuals in an image. (nullable)
  --artists: string # Search for images by specific artists (free-text, comma-separated list of artists). (nullable)
  --collection-codes: list # Filter by collection codes (comma-separated list). Include or exclude based on collections_filter_type. (nullable)
  --collections-filter-type: string@collections-filter-type-completer # Use to include or exclude collections from search. The default is include
  --color: string # Filter based on predominant color in an image. Use 6 character hexadecimal format (e.g., #002244). (nullable)
  --compositions: list # Filter based on image composition. (nullable)
  --download-product: string # Filters based on which product the asset will download against.                     Allowed values are easyaccess, editorialsubscription, imagepack, premiumaccess and royaltyfreesubscription.                     If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on.                      For example, some users may have more than one premiumaccess product, so the download_product value would be premiumaccess:1234.                      Product ID can be obtained from the GET /products response. (nullable)
  --embed-content-only: oneof<nothing, bool> # Restrict search results to embeddable images. The default is false. (default: false)
  --ethnicity: list # Filter search results based on the ethnicity of individuals in an image. (nullable)
  --exclude-keyword-ids: list # Return only images not tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those images matching the query phrase which also do not contain the requested keyword(s) are returned. (nullable)
  --exclude-nudity: oneof<nothing, bool> # Excludes images containing nudity. The default is false. (default: false)
  --exclude-editorial-use-only: oneof<nothing, bool> # Exclude images that are only available for editorial (non-commercial) use. Default value is false. (nullable)
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --file-types: list # Return only images having a specific file type. (nullable)
  --graphical-styles: list # Filter based on graphical style of the image. (nullable)
  --graphical-styles-filter-type: string@graphical-styles-filter-type-completer # Provides searching based on specified graphical style(s). The default is include.
  --include-related-searches: oneof<nothing, bool> # Specifies whether or not to include related searches in the response. The default is false. (default: false)
  --keyword-ids: list # Return only images tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those images matching the query phrase which also contain the requested keyword(s) are returned. (nullable)
  --minimum-size: string@minimum-size-completer # Filter based on minimum size requested. The default is x-small.
  --number-of-people: list # Filter based on the number of people in the image. (nullable)
  --orientations: list # Return only images with selected aspect ratios. (nullable)
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --page-size: int # Request number of images to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Search images using a search phrase. (nullable, default: )
  --safe-search: oneof<nothing, bool> # Setting safe_search to "true" excludes images containing nudity, death, profanity, drugs and alcohol, suggestive content, and graphic content from the result set. The default is false. Because this is a keyword-based filter, it's possible that a small number of unsafe images may not be caught by the filter. Please direct feedback to your Getty Images Account or API support representative. (default: false)
  --sort-order: string@sort-order-completer-2 # Select sort order of results.  The default is best_match
  --facet-fields: list # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results.                    The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --GI-Country-Code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> record<auto_corrections: record<phrase: string>, images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, graphical_style: string, id: string, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age_of_people" $age_of_people "csv") (serialize-qp "artists" $artists "scalar") (serialize-qp "collection_codes" $collection_codes "csv") (serialize-qp "collections_filter_type" $collections_filter_type "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "compositions" $compositions "csv") (serialize-qp "download_product" $download_product "scalar") (serialize-qp "embed_content_only" $embed_content_only "scalar") (serialize-qp "ethnicity" $ethnicity "csv") (serialize-qp "exclude_keyword_ids" $exclude_keyword_ids "csv") (serialize-qp "exclude_nudity" $exclude_nudity "scalar") (serialize-qp "exclude_editorial_use_only" $exclude_editorial_use_only "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "file_types" $file_types "csv") (serialize-qp "graphical_styles" $graphical_styles "csv") (serialize-qp "graphical_styles_filter_type" $graphical_styles_filter_type "scalar") (serialize-qp "include_related_searches" $include_related_searches "scalar") (serialize-qp "keyword_ids" $keyword_ids "csv") (serialize-qp "minimum_size" $minimum_size "scalar") (serialize-qp "number_of_people" $number_of_people "csv") (serialize-qp "orientations" $orientations "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "phrase" $phrase "scalar") (serialize-qp "safe_search" $safe_search "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "facet_fields" $facet_fields "csv") (serialize-qp "include_facets" $include_facets "scalar") (serialize-qp "facet_max_count" $facet_max_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/search/images/creative" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language, "GI-Country-Code": $GI_Country_Code} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for creative images based on url
#
# GET /v3/search/images/creative/by-image
export def "search-images-creative-by-image get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # Specifies the Getty image id to use in the search. (nullable)
  --exclude-editorial-use-only: oneof<nothing, bool> # Exclude images that are only available for editorial (non-commercial) use. Default value is false. (nullable)
  --facet-fields: list # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results.                     The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --image-url: string # Specifies the location of the image to use in the search. (nullable)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --page-size: int # Request number of images to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --product-types: list # Filter images to those from one of your product types.                      Allowed values are easyaccess, imagepack, premiumaccess and royaltyfreesubscription.                      If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on.                      For example, some users may have more than one premiumaccess product, so the product_types value would be premiumaccess:1234.                      Product ID can be obtained from the GET /products response. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --GI-Country-Code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> record<auto_corrections: record<phrase: string>, facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, image_fingerprint: string, images: any, related_searches: table<phrase: string, url: string>, result_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset_id" $asset_id "scalar") (serialize-qp "exclude_editorial_use_only" $exclude_editorial_use_only "scalar") (serialize-qp "facet_fields" $facet_fields "csv") (serialize-qp "facet_max_count" $facet_max_count "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "image_url" $image_url "scalar") (serialize-qp "include_facets" $include_facets "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "product_types" $product_types "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/search/images/creative/by-image" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language, "GI-Country-Code": $GI_Country_Code} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for editorial images only
#
# GET /v3/search/images/editorial
export def "search-images-editorial get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-of-people: list # Filter based on the age of individuals in an image. (nullable)
  --artists: string # Search for images by specific artists (free-text, comma-separated list of artists). (nullable)
  --collection-codes: list # Filter by collections (comma-separated list of collection codes). Include or exclude based on collections_filter_type. (nullable)
  --collections-filter-type: string@collections-filter-type-completer # Use to include or exclude collections from search. The default is include
  --compositions: list # Filter based on image composition. (nullable)
  --date-from: string # Return only images that are created on or after this date. Use ISO 8601 format (e.g., 1999-12-31). (nullable, format: date-time)
  --date-to: string # Return only images that are created on or before this date. Use ISO 8601 format (e.g., 1999-12-31). (nullable, format: date-time)
  --download-product: string # Filters based on which product the asset will download against.                     Allowed values are easyaccess, editorialsubscription, imagepack, premiumaccess and royaltyfreesubscription.                     If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on.                      For example, some users may have more than one premiumaccess product, so the download_product value would be premiumaccess:1234.                      Product ID can be obtained from the GET /products response. (nullable)
  --editorial-segments: list # Return only events with a matching editorial segment. (nullable)
  --embed-content-only: oneof<nothing, bool> # Restrict search results to embeddable images. The default is false. (default: false)
  --ethnicity: list # Filter search results based on the ethnicity of individuals in an image. (nullable)
  --event-ids: list # Filter based on specific events (nullable)
  --exclude-keyword-ids: list # Return only images not tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those images matching the query phrase which also do not contain the requested keyword(s) are returned. (nullable)
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes, height, and width returned by 'download_sizes' field are estimates. (nullable)
  --file-types: list # Return only images having a specific file type. (nullable)
  --graphical-styles: list # Filter based on graphical style of the image. (nullable)
  --graphical-styles-filter-type: string@graphical-styles-filter-type-completer # Provides searching based on specified graphical style(s). The default is include.
  --include-related-searches: oneof<nothing, bool> # Specifies whether or not to include related searches in the response. The default is false. (default: false)
  --keyword-ids: list # Return only images tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those images matching the query phrase which also contain the requested keyword(s) are returned. (nullable)
  --minimum-size: string@minimum-size-completer # Filter based on minimum size requested. The default is x-small.
  --number-of-people: list # Filter based on the number of people in the image. (nullable)
  --orientations: list # Return only images with selected aspect ratios. (nullable)
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --page-size: int # Request number of images to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Search images using a search phrase. (nullable)
  --sort-order: string@sort-order-completer-3 # Select sort order of results.  The default is best_match
  --specific-people: list # Return only images associated with specific people (using a comma-delimited list). (nullable)
  --minimum-quality-rank: int # Filter search results based on minimum quality ranking. Possible values 1, 2, 3 with 1 being best. (nullable, format: int32)
  --facet-fields: list # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results.                    The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --GI-Country-Code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> record<images: table<allowed_use: record, alternative_ids: record, artist: string, asset_family: string, call_for_image: bool, caption: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_camera_shot: string, date_created: string, display_sizes: list, download_product: string, editorial_segments: list, editorial_source: record, event_ids: list, graphical_style: string, id: string, keywords: list, largest_downloads: list, license_model: string, max_dimensions: record, orientation: string, people: list, product_types: list, quality_rank: int, referral_destinations: list, title: string, uri_oembed: string>, related_searches: table<phrase: string, url: string>, result_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age_of_people" $age_of_people "csv") (serialize-qp "artists" $artists "scalar") (serialize-qp "collection_codes" $collection_codes "csv") (serialize-qp "collections_filter_type" $collections_filter_type "scalar") (serialize-qp "compositions" $compositions "csv") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "download_product" $download_product "scalar") (serialize-qp "editorial_segments" $editorial_segments "csv") (serialize-qp "embed_content_only" $embed_content_only "scalar") (serialize-qp "ethnicity" $ethnicity "csv") (serialize-qp "event_ids" $event_ids "csv") (serialize-qp "exclude_keyword_ids" $exclude_keyword_ids "csv") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "file_types" $file_types "csv") (serialize-qp "graphical_styles" $graphical_styles "csv") (serialize-qp "graphical_styles_filter_type" $graphical_styles_filter_type "scalar") (serialize-qp "include_related_searches" $include_related_searches "scalar") (serialize-qp "keyword_ids" $keyword_ids "csv") (serialize-qp "minimum_size" $minimum_size "scalar") (serialize-qp "number_of_people" $number_of_people "csv") (serialize-qp "orientations" $orientations "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "phrase" $phrase "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "specific_people" $specific_people "csv") (serialize-qp "minimum_quality_rank" $minimum_quality_rank "scalar") (serialize-qp "facet_fields" $facet_fields "csv") (serialize-qp "include_facets" $include_facets "scalar") (serialize-qp "facet_max_count" $facet_max_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/search/images/editorial" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language, "GI-Country-Code": $GI_Country_Code} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for creative videos
#
# GET /v3/search/videos/creative
export def "search-videos-creative get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-of-people: list # Provides filtering according to the age of individuals in a video. (nullable)
  --artists: string # Search for videos by specific artists (free-text, comma-separated list of artists). (nullable)
  --aspect-ratios: list # Search for videos by specific aspect ratios. (nullable)
  --collection-codes: list # Provides filtering by collection code. (nullable)
  --collections-filter-type: string@collections-filter-type-completer # Use to include or exclude collections from search. The default is include
  --compositions: list # Filter based on video composition. (nullable)
  --download-product: string # Filters based on which product the asset will download against.                     Allowed values are easyaccess, editorialsubscription, imagepack, premiumaccess and royaltyfreesubscription.                     If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on.                      For example, some users may have more than one premiumaccess product, so the download_product value would be premiumaccess:1234.                      Product ID can be obtained from the GET /products response. (nullable)
  --exclude-nudity: oneof<nothing, bool> # Excludes videos containing nudity. The default is false. (default: false)
  --exclude-editorial-use-only: oneof<nothing, bool> # Exclude videos that are only available for editorial (non-commercial) use. Default value is false. (nullable)
  --exclude-keyword-ids: list # Return only videos not tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those videos matching the query phrase which also do not contain the requested keyword(s) are returned. (nullable)
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --format-available: string@format-available-completer # Filters according to the digital video format available on a film asset.
  --frame-rates: list # Provides filtering by video frame rate (frames/second). (nullable)
  --image-techniques: list # Filter based on image technique. (nullable)
  --include-related-searches: oneof<nothing, bool> # Specifies whether or not to include related searches in the response. The default is false. (default: false)
  --keyword-ids: list # Return only videos tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those videos matching the query phrase which also contain the requested keyword(s) are returned. (nullable)
  --license-models: list # Specifies the video licensing model(s). (nullable)
  --orientations: list # Return only videos with selected orientations. (nullable)
  --min-clip-length: int # Provides filtering by minimum length of video clip, in seconds (format: int32, default: 0)
  --max-clip-length: int # Provides filtering by maximum length of video, in seconds (format: int32, default: 0)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Free-text search query. (nullable, default: )
  --safe-search: oneof<nothing, bool> # Setting safe_search to "true" excludes images containing nudity, death, profanity, drugs and alcohol, suggestive content, and graphic content from the result set. The default is false. Because this is a keyword-based filter, it's possible that a small number of unsafe images may not be caught by the filter. Please direct feedback to your Getty Images Account or API support representative. (default: false)
  --sort-order: string@sort-order-completer-2 # Select sort order of results.  The default is best_match
  --release-status: string@release-status-completer # Allows filtering by type of model release.
  --facet-fields: list # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results.                    The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --viewpoints: list # Filter based on viewpoint. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --GI-Country-Code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> record<auto_corrections: record<phrase: string>, facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, related_searches: table<phrase: string, url: string>, result_count: int, videos: table<allowed_use: record, artist: string, asset_family: string, caption: string, clip_length: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_created: string, display_sizes: list, download_product: string, era: string, event_ids: list, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, mastered_to: string, originally_shot_on: string, product_types: list, referral_destinations: list, shot_speed: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age_of_people" $age_of_people "csv") (serialize-qp "artists" $artists "scalar") (serialize-qp "aspect_ratios" $aspect_ratios "csv") (serialize-qp "collection_codes" $collection_codes "csv") (serialize-qp "collections_filter_type" $collections_filter_type "scalar") (serialize-qp "compositions" $compositions "csv") (serialize-qp "download_product" $download_product "scalar") (serialize-qp "exclude_nudity" $exclude_nudity "scalar") (serialize-qp "exclude_editorial_use_only" $exclude_editorial_use_only "scalar") (serialize-qp "exclude_keyword_ids" $exclude_keyword_ids "csv") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "format_available" $format_available "scalar") (serialize-qp "frame_rates" $frame_rates "csv") (serialize-qp "image_techniques" $image_techniques "csv") (serialize-qp "include_related_searches" $include_related_searches "scalar") (serialize-qp "keyword_ids" $keyword_ids "csv") (serialize-qp "license_models" $license_models "csv") (serialize-qp "orientations" $orientations "csv") (serialize-qp "min_clip_length" $min_clip_length "scalar") (serialize-qp "max_clip_length" $max_clip_length "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "phrase" $phrase "scalar") (serialize-qp "safe_search" $safe_search "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "release_status" $release_status "scalar") (serialize-qp "facet_fields" $facet_fields "csv") (serialize-qp "facet_max_count" $facet_max_count "scalar") (serialize-qp "include_facets" $include_facets "scalar") (serialize-qp "viewpoints" $viewpoints "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/search/videos/creative" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language, "GI-Country-Code": $GI_Country_Code} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for creative videos based on url
#
# GET /v3/search/videos/creative/by-image
export def "search-videos-creative-by-image get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # Specifies the Getty video id to use in the search. (nullable)
  --exclude-editorial-use-only: oneof<nothing, bool> # Exclude videos that are only available for editorial (non-commercial) use. Default value is false. (nullable)
  --facet-fields: list # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results.                     The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --image-url: string # Specifies the location of the image to use in the search. (nullable)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --page: int # Request results starting at a page number (default is 1). (format: int32, default: 1)
  --page-size: int # Request number of images to return in each page. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --product-types: list # Filter images to those from one of your product types.                      Allowed values are easyaccess, imagepack, premiumaccess and royaltyfreesubscription.                      If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on.                      For example, some users may have more than one premiumaccess product, so the product_types value would be premiumaccess:1234.                      Product ID can be obtained from the GET /products response. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --GI-Country-Code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> record<auto_corrections: record<phrase: string>, facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, related_searches: table<phrase: string, url: string>, result_count: int, videos: table<allowed_use: record, artist: string, asset_family: string, caption: string, clip_length: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_created: string, display_sizes: list, download_product: string, era: string, event_ids: list, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, mastered_to: string, originally_shot_on: string, product_types: list, referral_destinations: list, shot_speed: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset_id" $asset_id "scalar") (serialize-qp "exclude_editorial_use_only" $exclude_editorial_use_only "scalar") (serialize-qp "facet_fields" $facet_fields "csv") (serialize-qp "facet_max_count" $facet_max_count "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "image_url" $image_url "scalar") (serialize-qp "include_facets" $include_facets "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "product_types" $product_types "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/search/videos/creative/by-image" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language, "GI-Country-Code": $GI_Country_Code} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for editorial videos
#
# GET /v3/search/videos/editorial
export def "search-videos-editorial get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-of-people: list # Provides filtering according to the age of individuals in a video. (nullable)
  --artists: string # Search for videos by specific artists (free-text, comma-separated list of artists). (nullable)
  --aspect-ratios: list # Search for videos by specific aspect ratios. (nullable)
  --collection-codes: list # Provides filtering by collection code. (nullable)
  --collections-filter-type: string@collections-filter-type-completer # Use to include or exclude collections from search. The default is include
  --compositions: list # Filter based on video composition. (nullable)
  --download-product: string # Filters based on which product the asset will download against.                     Allowed values are easyaccess, editorialsubscription, imagepack, premiumaccess and royaltyfreesubscription.                     If you have more than one instance of a product, you may also include the ID of the product instance you wish to filter on.                      For example, some users may have more than one premiumaccess product, so the download_product value would be premiumaccess:1234.                      Product ID can be obtained from the GET /products response. (nullable)
  --editorial-video-types: list # Allows filtering by types of video. (nullable)
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --format-available: string@format-available-completer # Filters according to the digital video format available on a film asset.
  --frame-rates: list # Provides filtering by video frame rate (frames/second). (nullable)
  --image-techniques: list # Filter based on image technique. (nullable)
  --include-related-searches: oneof<nothing, bool> # Specifies whether or not to include related searches in the response. The default is false. (default: false)
  --keyword-ids: list # Return only videos tagged with specific keyword(s). Specify using a comma-separated list of keyword Ids. If keyword Ids and phrase are both specified, only those videos matching the query phrase which also contain the requested keyword(s) are returned. (nullable)
  --min-clip-length: int # Provides filtering by minimum length of video clip, in seconds (format: int32, default: 0)
  --max-clip-length: int # Provides filtering by maximum length of video clip, in seconds (format: int32, default: 0)
  --orientations: list # Return only videos with selected orientations. (nullable)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --phrase: string # Free-text search query. (nullable, default: )
  --sort-order: string@sort-order-completer-3 # Select sort order of results.  The default is best_match
  --specific-people: list # Allows filtering by specific peoples' names. (nullable)
  --release-status: string@release-status-completer # Allows filtering by type of model release.
  --facet-fields: list # Specifies the facets to return in the response. Facets provide additional search parameters to refine your results.                    The include_facets parameter must be set to "true" for facets to be returned. (nullable)
  --include-facets: oneof<nothing, bool> # Specifies whether or not to include facets in the result set. Default is "false". (nullable)
  --facet-max-count: int # Specifies the maximum number of facets to return per type. Default is 300. (format: int32, default: 300)
  --viewpoints: list # Filter based on viewpoint. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
  --GI-Country-Code: string # Receive regionally relevant search results based on the value specified. Accepts only ISO Alpha-3 country codes. The Countries operation can be used to retrieve the codes.
]: nothing -> record<facets: record<artists: list<record>, entertainment: list<record>, events: list<record>, locations: list<record>, specific_people: list<record>>, related_searches: table<phrase: string, url: string>, result_count: int, videos: table<allowed_use: record, artist: string, asset_family: string, caption: string, clip_length: string, collection_code: string, collection_id: int, collection_name: string, color_type: string, copyright: string, date_created: string, display_sizes: list, download_product: string, era: string, event_ids: list, id: string, istock_licenses: list, keywords: list, largest_downloads: list, license_model: string, mastered_to: string, originally_shot_on: string, product_types: list, referral_destinations: list, shot_speed: string, source: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age_of_people" $age_of_people "csv") (serialize-qp "artists" $artists "scalar") (serialize-qp "aspect_ratios" $aspect_ratios "csv") (serialize-qp "collection_codes" $collection_codes "csv") (serialize-qp "collections_filter_type" $collections_filter_type "scalar") (serialize-qp "compositions" $compositions "csv") (serialize-qp "download_product" $download_product "scalar") (serialize-qp "editorial_video_types" $editorial_video_types "csv") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "format_available" $format_available "scalar") (serialize-qp "frame_rates" $frame_rates "csv") (serialize-qp "image_techniques" $image_techniques "csv") (serialize-qp "include_related_searches" $include_related_searches "scalar") (serialize-qp "keyword_ids" $keyword_ids "csv") (serialize-qp "min_clip_length" $min_clip_length "scalar") (serialize-qp "max_clip_length" $max_clip_length "scalar") (serialize-qp "orientations" $orientations "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "phrase" $phrase "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "specific_people" $specific_people "csv") (serialize-qp "release_status" $release_status "scalar") (serialize-qp "facet_fields" $facet_fields "csv") (serialize-qp "include_facets" $include_facets "scalar") (serialize-qp "facet_max_count" $facet_max_count "scalar") (serialize-qp "viewpoints" $viewpoints "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/search/videos/editorial" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language, "GI-Country-Code": $GI_Country_Code} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Report usage of assets via a batch format.
#
# PUT /v3/usage-batches/{id}
# --asset_usages item shape: {asset_id?: string, quantity?: int, usage_date?: string}
export def "usage-batches put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-usages: list # Identifies the list of asset id, usage count and date of usage combinations to record. (nullable) — item shape: {asset_id?: string, quantity?: int, usage_date?: string}
]: any -> record<invalid_assets: list<string>, total_asset_usages_processed: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/usage-batches/($id)")
  let body = {asset_usages: $asset_usages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get metadata for multiple videos by supplying multiple video ids
#
# GET /v3/videos
export def "videos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # Specifies one or more video ids to return. Use comma delimiter when requesting multiple ids.  Maximum of 100 ids. (nullable)
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/videos" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metadata for a single video by supplying one video id
#
# GET /v3/videos/{id}
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
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/videos/($id)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a customer's download history for a specific asset
#
# GET /v3/videos/{id}/downloadhistory
export def "videos-downloadhistory get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-downloads: oneof<nothing, bool> # If specified, returns the list of previously downloaded videos for all users in your company.             Your account must be enabled for this functionality. Contact your Getty Images account rep for more information. Default is false.
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> record<downloads: any, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_downloads" $company_downloads "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/videos/($id)/downloadhistory" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve creative videos from the same series
#
# GET /v3/videos/{id}/same-series
export def "videos-same-series get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/videos/($id)/same-series" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve similar videos
#
# GET /v3/videos/{id}/similar
export def "videos-similar get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: list # Specifies fields to return. Defaults to 'summary_set'. NOTE: Bytes returned by 'download_sizes' field is an estimate. (nullable)
  --page: int # Identifies page to return. Default is 1. (format: int32, default: 1)
  --page-size: int # Specifies page size. Default is 30, maximum page_size is 100. (format: int32, default: 30)
  --Accept-Language: string # Provide a header to specify the language of result values. Supported values: cs (iStock only), de, en-GB, en-US, es, fi (iStock only), fr, hu (iStock only), id (iStock only), it, ja, ko (creative assets only), nl, pl (creative assets only), pt-BR, pt-PT, ro (iStock only), ru (creative assets only), sv, th (iStock only), tr, uk (iStock only), vi (iStock only), zh-HK (creative assets only).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/videos/($id)/similar" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
