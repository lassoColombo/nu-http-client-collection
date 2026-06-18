# Auto-generated client for Wowza Streaming Cloud REST API Reference Documentation v1
# Source: https://api.apis.guru/v2/specs/wowza.com/1/swagger.json
# Auth: --token flag or $env.WOWZA_STREAMING_CLOUD_REST_API_REFERENCE_DOCUMENTATION_TOKEN

const BASE_URL = "https://api-sandbox.cloud.wowza.com/api/v1"
const DEFAULT_AUTH = "wsc-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WOWZA_STREAMING_CLOUD_REST_API_REFERENCE_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "wsc-access-key" => { {headers: {wsc-access-key: $token_val}, query: ""} }
    "wsc-api-key" => { {headers: {wsc-api-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api-sandbox.cloud.wowza.com/api/v1"] }
def auth-scheme-completer [] { ["wsc-access-key" "wsc-api-key"] }

# Completers for enum parameters
def interval-completer [] { ["#d" "#h" "#m" "#s" "day" "hour" "minute" "month" "second"] }
def transcoder-type-completer [] { ["passthrough" "transcoded"] }
def billing-mode-completer [] { ["pay_as_you_go" "twentyfour_seven"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "specs get" } } | get name | first)
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

# Fetch Swagger information
#
# GET /api/v1/specs
# operationId: specs
export def "specs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<basePath: string, consumes: list<string>, definitions: record, externalDocs: record, host: string, info: record, paths: record, produces: list<string>, schemes: list<string>, security: list<record>, securityDefinitions: record, swagger: string, tags: list<record>, x_tagGroups: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/specs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch all live streams
#
# GET /live_streams
# operationId: listLiveStreams
export def "live-streams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> record<live_streams: table<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list, delivery_type: string, direct_playback_urls: list, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/live_streams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a live stream
#
# POST /live_streams
# operationId: createLiveStream
# --live_stream shape: {aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: "pay_as_you_go"|"twentyfour_seven", broadcast_location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method?: "pull"|"cdn"|"push", delivery_protocols?: list<string>, ... (29 more fields)}
export def "live-streams create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  live_stream: record # shape: {aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: "pay_as_you_go"|"twentyfour_seven", broadcast_location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method?: "pull"|"cdn"|"push", delivery_protocols?: list<string>, ... (29 more fields)}
]: any -> record<live_stream: record<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list<string>, delivery_type: string, direct_playback_urls: list<record>, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list<record>, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/live_streams")
  let req_body = {"live_stream": $live_stream} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a live stream
#
# DELETE /live_streams/{id}
# operationId: deleteLiveStream
export def "live-streams delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/live_streams/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a live stream
#
# GET /live_streams/{id}
# operationId: showLiveStream
export def "live-streams get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<live_stream: record<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list<string>, delivery_type: string, direct_playback_urls: list<record>, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list<record>, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/live_streams/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a live stream
#
# PATCH /live_streams/{id}
# operationId: updateLiveStream
# --live_stream shape: {aspect_ratio_height: int, aspect_ratio_width: int, closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method?: "pull"|"cdn"|"push", delivery_protocols?: list<string>, disable_authentication?: bool, encoder: "wowza_streaming_engine"|"wowza_gocoder"|"media_ds"|"axis"|"epiphan"|"hauppauge"|"jvc"|"live_u"|"matrox"|"newtek_tricaster"|"osprey"|"sony"|"telestream_wirecast"|"teradek_cube"|"vmix"|"x_split"|"ipcamera"|"other_rtmp"|"other_rtsp", hosted_page_description?: string, ... (22 more fields)}
export def "live-streams update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  live_stream: record # shape: {aspect_ratio_height: int, aspect_ratio_width: int, closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method?: "pull"|"cdn"|"push", delivery_protocols?: list<string>, disable_authentication?: bool, encoder: "wowza_streaming_engine"|"wowza_gocoder"|"media_ds"|"axis"|"epiphan"|"hauppauge"|"jvc"|"live_u"|"matrox"|"newtek_tricaster"|"osprey"|"sony"|"telestream_wirecast"|"teradek_cube"|"vmix"|"x_split"|"ipcamera"|"other_rtmp"|"other_rtsp", hosted_page_description?: string, ... (22 more fields)}
]: any -> record<live_stream: record<aspect_ratio_height: int, aspect_ratio_width: int, billing_mode: string, broadcast_location: string, closed_caption_type: string, connection_code: string, connection_code_expires_at: string, created_at: string, delivery_method: string, delivery_protocol: string, delivery_protocols: list<string>, delivery_type: string, direct_playback_urls: list<record>, encoder: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: bool, hosted_page_title: string, hosted_page_url: string, id: string, low_latency: bool, name: string, player_countdown: bool, player_countdown_at: string, player_embed_code: string, player_hds_playback_url: string, player_hls_playback_url: string, player_id: string, player_logo_image_url: string, player_logo_position: string, player_responsive: bool, player_type: string, player_video_poster_image_url: string, player_width: int, recording: bool, source_connection_information: record, stream_source_id: string, stream_targets: list<record>, target_delivery_protocol: string, transcoder_type: string, updated_at: string, use_stream_source: bool, video_fallback: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/live_streams/{id}"))
  let req_body = {"live_stream": $live_stream} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Regenerate the connection code for a live stream
#
# PUT /live_streams/{id}/regenerate_connection_code
# operationId: regenerateConnectionCodeLiveStream
export def "live-streams-regenerate-connection-code update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<live_stream: record<connection_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/live_streams/{id}/regenerate_connection_code"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset a live stream
#
# PUT /live_streams/{id}/reset
# operationId: resetLiveStream
export def "live-streams-reset reset" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<live_stream: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/live_streams/{id}/reset"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start a live stream
#
# PUT /live_streams/{id}/start
# operationId: startLiveStream
export def "live-streams-start start" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<live_stream: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/live_streams/{id}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the state of a live stream
#
# GET /live_streams/{id}/state
# operationId: showLiveStreamState
export def "live-streams-state get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<live_stream: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/live_streams/{id}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch metrics for an active live stream
#
# GET /live_streams/{id}/stats
# operationId: showLiveStreamStats
export def "live-streams-stats stats-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<live_stream: record<audio_codec: record<status: string, text: string, units: string, value: string>, bits_in_rate: record<status: string, text: string, units: string, value: float>, bits_out_rate: record<status: string, text: string, units: string, value: float>, bytes_in_rate: record<status: string, text: string, units: string, value: float>, bytes_out_rate: record<status: string, text: string, units: string, value: float>, configured_bytes_out_rate: record<status: string, text: string, units: string, value: int>, connected: record<status: string, text: string, units: string, value: string>, cpu: record<status: string, text: string, units: string, value: int>, frame_rate: record<status: string, text: string, units: string, value: int>, frame_size: record<status: string, text: string, units: string, value: string>, gpu_decoder_usage: record<status: string, text: string, units: string, value: int>, gpu_driver_version: record<status: string, text: string, units: string, value: string>, gpu_encoder_usage: record<status: string, text: string, units: string, value: int>, gpu_memory_usage: record<status: string, text: string, units: string, value: int>, gpu_usage: record<status: string, text: string, units: string, value: int>, height: record<status: string, text: string, units: string, value: int>, keyframe_interval: record<status: string, text: string, units: string, value: int>, stream_target_status_OUTPUTIDX_STREAMTARGETIDX: record<status: string, text: string, units: string, value: string>, unique_views: record<status: string, text: string, units: string, value: int>, video_codec: record<status: string, text: string, units: string, value: string>, width: record<status: string, text: string, units: string, value: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/live_streams/{id}/stats"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop a live stream
#
# PUT /live_streams/{id}/stop
# operationId: stopLiveStream
export def "live-streams-stop stop" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<live_stream: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/live_streams/{id}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the thumbnail URL of a live stream
#
# GET /live_streams/{id}/thumbnail_url
# operationId: showLiveStreamThumbnailUrl
export def "live-streams-thumbnail-url get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<live_stream: record<thumbnail_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/live_streams/{id}/thumbnail_url"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch all players
#
# GET /players
# operationId: listPlayers
export def "players list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> record<players: table<countdown: bool, countdown_at: string, created_at: string, embed_code: string, hds_playback_url: string, hls_playback_url: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: string, hosted_page_title: string, hosted_page_url: string, id: string, logo_image_url: string, logo_position: string, responsive: bool, transcoder_id: string, type: string, updated_at: string, video_poster_image_url: string, width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/players" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a player
#
# GET /players/{id}
# operationId: showPlayer
export def "players get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<player: record<countdown: bool, countdown_at: string, created_at: string, embed_code: string, hds_playback_url: string, hls_playback_url: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: string, hosted_page_title: string, hosted_page_url: string, id: string, logo_image_url: string, logo_position: string, responsive: bool, transcoder_id: string, type: string, updated_at: string, video_poster_image_url: string, width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/players/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a player
#
# PATCH /players/{id}
# operationId: updatePlayer
# --player shape: {countdown?: bool, countdown_at?: string, hosted_page?: bool, hosted_page_description?: string, hosted_page_logo_image?: string, hosted_page_sharing_icons?: bool, hosted_page_title?: string, logo_image?: string, logo_position?: string, remove_hosted_page_logo_image?: bool, remove_logo_image?: bool, remove_video_poster_image?: bool, responsive?: bool, type?: string, video_poster_image?: string, width?: int}
export def "players update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  player: record # shape: {countdown?: bool, countdown_at?: string, hosted_page?: bool, hosted_page_description?: string, hosted_page_logo_image?: string, hosted_page_sharing_icons?: bool, hosted_page_title?: string, logo_image?: string, logo_position?: string, remove_hosted_page_logo_image?: bool, remove_logo_image?: bool, remove_video_poster_image?: bool, responsive?: bool, type?: string, video_poster_image?: string, width?: int}
]: any -> record<player: record<countdown: bool, countdown_at: string, created_at: string, embed_code: string, hds_playback_url: string, hls_playback_url: string, hosted_page: bool, hosted_page_description: string, hosted_page_logo_image_url: string, hosted_page_sharing_icons: string, hosted_page_title: string, hosted_page_url: string, id: string, logo_image_url: string, logo_position: string, responsive: bool, transcoder_id: string, type: string, updated_at: string, video_poster_image_url: string, width: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/players/{id}"))
  let req_body = {"player": $player} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Rebuild player code
#
# POST /players/{id}/rebuild
# operationId: requestPlayerRebuild
export def "players-rebuild request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<player: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/players/{id}/rebuild"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the state of a player
#
# GET /players/{id}/state
# operationId: showPlayerState
export def "players-state get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<player: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/players/{id}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch all player URLs
#
# GET /players/{player_id}/urls
# operationId: listPlayerUrls
export def "players-urls list" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<urls: table<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player_id: (encode-path-segment $player_id)} | format pattern "/players/{player_id}/urls"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a player URL
#
# POST /players/{player_id}/urls
# operationId: createPlayerUrl
# --url shape: {bitrate?: int, height?: int, label?: string, url?: string, width?: int}
export def "players-urls create" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  url: record # shape: {bitrate?: int, height?: int, label?: string, url?: string, width?: int}
]: any -> record<url: record<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player_id: (encode-path-segment $player_id)} | format pattern "/players/{player_id}/urls"))
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a player URL
#
# DELETE /players/{player_id}/urls/{id}
# operationId: deletePlayerUrl
export def "players-urls delete" [
  player_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player_id: (encode-path-segment $player_id), id: (encode-path-segment $id)} | format pattern "/players/{player_id}/urls/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a player URL
#
# GET /players/{player_id}/urls/{id}
# operationId: showPlayerUrl
export def "players-urls get-show" [
  player_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: record<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player_id: (encode-path-segment $player_id), id: (encode-path-segment $id)} | format pattern "/players/{player_id}/urls/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a player URL
#
# PATCH /players/{player_id}/urls/{id}
# operationId: updatePlayerUrl
# --url shape: {bitrate?: int, height?: int, label?: string, url?: string, width?: int}
export def "players-urls update" [
  player_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  url: record # shape: {bitrate?: int, height?: int, label?: string, url?: string, width?: int}
]: any -> record<url: record<bitrate: int, created_at: string, height: int, id: string, label: string, player_id: string, updated_at: string, url: string, width: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player_id: (encode-path-segment $player_id), id: (encode-path-segment $id)} | format pattern "/players/{player_id}/urls/{id}"))
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Fetch all recordings
#
# GET /recordings
# operationId: listRecordings
export def "recordings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> record<recordings: table<created_at: string, download_url: string, duration: int, file_name: string, file_size: int, id: string, reason: string, starts_at: string, state: string, transcoder_id: string, transcoder_name: string, transcoding_uptime_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recordings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a recording
#
# DELETE /recordings/{id}
# operationId: deleteRecording
export def "recordings delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/recordings/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a recording
#
# GET /recordings/{id}
# operationId: showRecording
export def "recordings get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<recording: record<created_at: string, download_url: string, duration: int, file_name: string, file_size: int, id: string, reason: string, starts_at: string, state: string, transcoder_id: string, transcoder_name: string, transcoding_uptime_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/recordings/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the state of a recording
#
# GET /recordings/{id}/state
# operationId: showRecordingState
export def "recordings-state get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<recording: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/recordings/{id}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch all schedules
#
# GET /schedules
# operationId: listSchedules
export def "schedules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> record<schedules: table<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a schedule
#
# POST /schedules
# operationId: createSchedule
# --schedule shape: {action_type: "start"|"stop"|"start_stop", end_repeat?: string, name: string, recurrence_data?: "sunday"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday", recurrence_type: "once"|"recur", start_repeat?: string, start_transcoder?: string, stop_transcoder?: string, transcoder_id: string}
export def "schedules create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule: record # shape: {action_type: "start"|"stop"|"start_stop", end_repeat?: string, name: string, recurrence_data?: "sunday"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday", recurrence_type: "once"|"recur", start_repeat?: string, start_transcoder?: string, stop_transcoder?: string, transcoder_id: string}
]: any -> record<schedule: record<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/schedules")
  let req_body = {"schedule": $schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a schedule
#
# DELETE /schedules/{id}
# operationId: deleteSchedule
export def "schedules delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/schedules/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a schedule
#
# GET /schedules/{id}
# operationId: showSchedule
export def "schedules get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule: record<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/schedules/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a schedule
#
# PATCH /schedules/{id}
# operationId: updateSchedule
# --schedule shape: {action_type: "start"|"stop"|"start_stop", end_repeat?: string, name: string, recurrence_data?: "sunday"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday", start_repeat?: string, start_transcoder?: string, stop_transcoder?: string}
export def "schedules update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule: record # shape: {action_type: "start"|"stop"|"start_stop", end_repeat?: string, name: string, recurrence_data?: "sunday"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday", start_repeat?: string, start_transcoder?: string, stop_transcoder?: string}
]: any -> record<schedule: record<action_type: string, created_at: string, end_repeat: string, id: string, name: string, recurrence_data: string, recurrence_type: string, start_repeat: string, start_transcoder: string, state: string, stop_transcoder: string, transcoder_id: string, transcoder_name: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/schedules/{id}"))
  let req_body = {"schedule": $schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disable a schedule
#
# PUT /schedules/{id}/disable
# operationId: disableSchedule
export def "schedules-disable disable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/schedules/{id}/disable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a schedule
#
# PUT /schedules/{id}/enable
# operationId: enableSchedule
export def "schedules-enable enable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/schedules/{id}/enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the state of a schedule
#
# GET /schedules/{id}/state
# operationId: showScheduleState
export def "schedules-state get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/schedules/{id}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch all stream sources
#
# GET /stream_sources
# operationId: listStreamSources
export def "stream-sources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> record<stream_sources: table<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stream_sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a stream source
#
# POST /stream_sources
# operationId: createStreamSource
# --stream_source shape: {backup_ip_address?: string, ip_address?: string, location?: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", location_method: "region"|"ip_address", name: string}
export def "stream-sources create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_source: record # shape: {backup_ip_address?: string, ip_address?: string, location?: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", location_method: "region"|"ip_address", name: string}
]: any -> record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stream_sources")
  let req_body = {"stream_source": $stream_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deprecated operation
#
# POST /stream_sources/add
# DEPRECATED
# operationId: addStreamSource
# --stream_source shape: {backup_ip_address?: string, ip_address?: string, location?: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", location_method: "region"|"ip_address", name: string}
@deprecated
export def "stream-sources-add create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_source: record # shape: {backup_ip_address?: string, ip_address?: string, location?: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", location_method: "region"|"ip_address", name: string}
]: any -> record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stream_sources/add")
  let req_body = {"stream_source": $stream_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a stream source
#
# DELETE /stream_sources/{id}
# operationId: deleteStreamSource
export def "stream-sources delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/stream_sources/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a stream source
#
# GET /stream_sources/{id}
# operationId: showStreamSource
export def "stream-sources get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/stream_sources/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a stream source
#
# PATCH /stream_sources/{id}
# operationId: updateStreamSource
# --stream_source shape: {name: string}
export def "stream-sources update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_source: record # shape: {name: string}
]: any -> record<stream_source: record<backup_ip_address: string, backup_url: string, created_at: string, id: string, ip_address: string, location: string, location_method: string, name: string, password: string, playback_url: string, primary_url: string, provider: string, stream_name: string, updated_at: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/stream_sources/{id}"))
  let req_body = {"stream_source": $stream_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Fetch all stream targets
#
# GET /stream_targets
# operationId: listStreamTargets
export def "stream-targets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> record<stream_targets: table<chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, hds_playback_url: string, hls_playback_url: string, id: string, location: string, name: string, primary_url: string, provider: string, rtmp_playback_url: string, stream_name: string, type: string, updated_at: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stream_targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a stream target
#
# POST /stream_targets
# operationId: createStreamTarget
# --stream_target shape: {backup_url?: string, chunk_size?: "2"|"4"|"6"|"8"|"10", enable_hls?: bool, enabled?: bool, hds_playback_url?: string, hls_playback_url?: string, ingest_ip_whitelist?: list<string>, location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", name: string, password?: string, primary_url: string, ... (11 more fields)}
export def "stream-targets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_target: record # shape: {backup_url?: string, chunk_size?: "2"|"4"|"6"|"8"|"10", enable_hls?: bool, enabled?: bool, hds_playback_url?: string, hls_playback_url?: string, ingest_ip_whitelist?: list<string>, location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", name: string, password?: string, primary_url: string, ... (11 more fields)}
]: any -> record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stream_targets")
  let req_body = {"stream_target": $stream_target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deprecated operation
#
# POST /stream_targets/add
# DEPRECATED
# operationId: addStreamTarget
# --stream_target shape: {chunk_size?: "2"|"4"|"6"|"8"|"10", location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", name: string, provider?: string, type?: string, use_cors?: bool, use_https?: bool, use_secure_ingest?: bool}
@deprecated
export def "stream-targets-add create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_target: record # shape: {chunk_size?: "2"|"4"|"6"|"8"|"10", location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", name: string, provider?: string, type?: string, use_cors?: bool, use_https?: bool, use_secure_ingest?: bool}
]: any -> record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stream_targets/add")
  let req_body = {"stream_target": $stream_target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a stream target
#
# DELETE /stream_targets/{id}
# operationId: deleteStreamTarget
export def "stream-targets delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/stream_targets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a stream target
#
# GET /stream_targets/{id}
# operationId: showStreamTarget
export def "stream-targets get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/stream_targets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a stream target
#
# PATCH /stream_targets/{id}
# operationId: updateStreamTarget
# --stream_target shape: {backup_url?: string, chunk_size?: "2"|"4"|"6"|"8"|"10", enabled?: bool, hds_playback_url?: string, hls_playback_url?: string, ingest_ip_whitelist?: list<string>, name?: string, password?: string, primary_url?: string, provider?: string, rtmp_playback_url?: string, source_url?: string, stream_name?: string, username?: string}
export def "stream-targets update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  stream_target: record # shape: {backup_url?: string, chunk_size?: "2"|"4"|"6"|"8"|"10", enabled?: bool, hds_playback_url?: string, hls_playback_url?: string, ingest_ip_whitelist?: list<string>, name?: string, password?: string, primary_url?: string, provider?: string, rtmp_playback_url?: string, source_url?: string, stream_name?: string, username?: string}
]: any -> record<stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/stream_targets/{id}"))
  let req_body = {"stream_target": $stream_target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Fetch current health metrics for an active Wowza ultra low latency stream target
#
# GET /stream_targets/{id}/metrics/current
# operationId: showStreamTargetMetricsCurrent
export def "stream-targets-metrics-current get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, metrics: record<average_bytes_in: float, average_total_connections: float, created_at: string, dropped_connections: int, maximum_total_connections: int, minimum_total_connections: int, new_connections: int>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/stream_targets/{id}/metrics/current"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch historic health metrics for a Wowza ultra low latency stream target
#
# GET /stream_targets/{id}/metrics/historic
# operationId: showStreamTargetMetricsHistoric
export def "stream-targets-metrics-historic get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The start of the range of time used to aggregate the metrics. Express the value by using the ISO 8601 standard of YYYY-MM-DDTHH:MM:SSZ where HH is a 24-hour clock in UTC.
  --qp-to: string # The end of the range of time used to aggregate the metrics. Express the value by using the ISO 8601 standard of YYYY-MM-DDTHH:MM:SSZ where HH is a 24-hour clock in UTC.
  --interval: string@interval-completer # The length of time for a block of metrics. The default is **10m** (10 minutes).
]: nothing -> record<id: string, interval: string, metrics: table<average_bytes_in: float, average_total_connections: float, created_at: string, dropped_connections: int, maximum_total_connections: int, minimum_total_connections: int, new_connections: int>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/stream_targets/{id}/metrics/historic") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerate the connection code for a stream target
#
# PUT /stream_targets/{id}/regenerate_connection_code
# operationId: regenerateConnectionCodeStreamTarget
export def "stream-targets-regenerate-connection-code update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stream_target: record<connection_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/stream_targets/{id}/regenerate_connection_code"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch geo-blocking for a stream target
#
# GET /stream_targets/{stream_target_id}/geoblock
# operationId: showStreamTargetGeoblock
export def "stream-targets-geoblock get-show" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<geoblock: record<countries: list<string>, created_at: string, state: string, stream_target_id: string, type: string, updated_at: string, whitelist: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/stream_targets/{stream_target_id}/geoblock"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update geo-blocking for a stream target
#
# PATCH /stream_targets/{stream_target_id}/geoblock
# operationId: updateStreamTargetGeoblock
# --geoblock shape: {countries?: list<string>, type: "disabled"|"allow"|"deny", whitelist?: list<string>}
export def "stream-targets-geoblock update" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  geoblock: record # shape: {countries?: list<string>, type: "disabled"|"allow"|"deny", whitelist?: list<string>}
]: any -> record<geoblock: record<countries: list<string>, created_at: string, state: string, stream_target_id: string, type: string, updated_at: string, whitelist: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/stream_targets/{stream_target_id}/geoblock"))
  let req_body = {"geoblock": $geoblock} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create geo-blocking for a stream target
#
# POST /stream_targets/{stream_target_id}/geoblock
# operationId: createStreamTargetGeoblock
# --geoblock shape: {countries?: list<string>, type: "disabled"|"allow"|"deny", whitelist?: list<string>}
export def "stream-targets-geoblock create" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  geoblock: record # shape: {countries?: list<string>, type: "disabled"|"allow"|"deny", whitelist?: list<string>}
]: any -> record<geoblock: record<countries: list<string>, created_at: string, state: string, stream_target_id: string, type: string, updated_at: string, whitelist: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/stream_targets/{stream_target_id}/geoblock"))
  let req_body = {"geoblock": $geoblock} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Fetch all properties of a stream target
#
# GET /stream_targets/{stream_target_id}/properties
# operationId: listStreamTargetProperties
export def "stream-targets-properties list" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<properties: table<key: string, section: string, stream_target_id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/stream_targets/{stream_target_id}/properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a property for a stream target
#
# POST /stream_targets/{stream_target_id}/properties
# operationId: createStreamTargetProperty
# --property shape: {key: "chunkSize"|"playSSL"|"relativePlaylists"|"sendSSL", section: "hls"|"playlist", value: "2"|"4"|"6"|"8"|"10"|"true"|"false"}
export def "stream-targets-properties create-property" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  property: record # shape: {key: "chunkSize"|"playSSL"|"relativePlaylists"|"sendSSL", section: "hls"|"playlist", value: "2"|"4"|"6"|"8"|"10"|"true"|"false"}
]: any -> record<property: record<key: string, section: string, stream_target_id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/stream_targets/{stream_target_id}/properties"))
  let req_body = {"property": $property} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a stream target property
#
# DELETE /stream_targets/{stream_target_id}/properties/{id}
# operationId: deleteStreamTargetProperty
export def "stream-targets-properties delete-property" [
  stream_target_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stream_target_id: (encode-path-segment $stream_target_id), id: (encode-path-segment $id)} | format pattern "/stream_targets/{stream_target_id}/properties/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a property of a stream target
#
# GET /stream_targets/{stream_target_id}/properties/{id}
# operationId: showStreamTargetProperty
export def "stream-targets-properties get-show-property" [
  stream_target_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<property: record<key: string, section: string, stream_target_id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stream_target_id: (encode-path-segment $stream_target_id), id: (encode-path-segment $id)} | format pattern "/stream_targets/{stream_target_id}/properties/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch token authorization for a stream target
#
# GET /stream_targets/{stream_target_id}/token_auth
# operationId: showStreamTargetTokenAuth
export def "stream-targets-token-auth get-show" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token_auth: record<created_at: string, enabled: bool, stream_target_id: string, trusted_shared_secret: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/stream_targets/{stream_target_id}/token_auth"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update token authorization for a stream target
#
# PATCH /stream_targets/{stream_target_id}/token_auth
# operationId: updateStreamTargetTokenAuth
# --token_auth shape: {enabled?: bool, trusted_shared_secret?: string}
export def "stream-targets-token-auth update" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  token_auth: record # shape: {enabled?: bool, trusted_shared_secret?: string}
]: any -> record<token_auth: record<created_at: string, enabled: bool, stream_target_id: string, trusted_shared_secret: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/stream_targets/{stream_target_id}/token_auth"))
  let req_body = {"token_auth": $token_auth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create token authorization for a stream target
#
# POST /stream_targets/{stream_target_id}/token_auth
# operationId: createStreamTargetTokenAuth
# --token_auth shape: {enabled: bool, trusted_shared_secret: string}
export def "stream-targets-token-auth create" [
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  token_auth: record # shape: {enabled: bool, trusted_shared_secret: string}
]: any -> record<token_auth: record<created_at: string, enabled: bool, stream_target_id: string, trusted_shared_secret: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/stream_targets/{stream_target_id}/token_auth"))
  let req_body = {"token_auth": $token_auth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Fetch all transcoders
#
# GET /transcoders
# operationId: listTranscoders
export def "transcoders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> record<transcoders: table<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list, description: string, direct_playback_urls: list, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transcoders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a transcoder
#
# POST /transcoders
# operationId: createTranscoder
# --transcoder shape: {billing_mode: "pay_as_you_go"|"twentyfour_seven", broadcast_location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", buffer_size?: "0"|"1000"|"2000"|"3000"|"4000"|"5000"|"6000"|"7000"|"8000", closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method: "pull"|"cdn"|"push", ... (24 more fields)}
export def "transcoders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  transcoder: record # shape: {billing_mode: "pay_as_you_go"|"twentyfour_seven", broadcast_location: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", buffer_size?: "0"|"1000"|"2000"|"3000"|"4000"|"5000"|"6000"|"7000"|"8000", closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method: "pull"|"cdn"|"push", ... (24 more fields)}
]: any -> record<transcoder: record<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list<string>, description: string, direct_playback_urls: list<record>, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list<record>, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transcoders")
  let req_body = {"transcoder": $transcoder} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a transcoder
#
# DELETE /transcoders/{id}
# operationId: deleteTranscoder
export def "transcoders delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a transcoder
#
# GET /transcoders/{id}
# operationId: showTranscoder
export def "transcoders get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcoder: record<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list<string>, description: string, direct_playback_urls: list<record>, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list<record>, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a transcoder
#
# PATCH /transcoders/{id}
# operationId: updateTranscoder
# --transcoder shape: {broadcast_location?: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", buffer_size?: "0"|"1000"|"2000"|"3000"|"4000"|"5000"|"6000"|"7000"|"8000", closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method: "pull"|"cdn"|"push", delivery_protocols?: list<string>, description?: string, ... (22 more fields)}
export def "transcoders update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  transcoder: record # shape: {broadcast_location?: "asia_pacific_australia"|"asia_pacific_japan"|"asia_pacific_singapore"|"asia_pacific_taiwan"|"eu_belgium"|"eu_germany"|"eu_ireland"|"south_america_brazil"|"us_central_iowa"|"us_east_s_carolina"|"us_east_virginia"|"us_west_california"|"us_west_oregon", buffer_size?: "0"|"1000"|"2000"|"3000"|"4000"|"5000"|"6000"|"7000"|"8000", closed_caption_type?: "none"|"cea"|"on_text"|"both", delivery_method: "pull"|"cdn"|"push", delivery_protocols?: list<string>, description?: string, ... (22 more fields)}
]: any -> record<transcoder: record<application_name: string, billing_mode: string, broadcast_location: string, buffer_size: int, closed_caption_type: string, created_at: string, delivery_method: string, delivery_protocols: list<string>, description: string, direct_playback_urls: list<record>, disable_authentication: bool, domain_name: string, id: string, idle_timeout: int, low_latency: bool, name: string, outputs: list<record>, password: string, play_maximum_connections: int, protocol: string, recording: bool, source_port: int, source_url: string, stream_extension: string, stream_name: string, stream_smoother: bool, stream_source_id: string, suppress_stream_target_start: bool, transcoder_type: string, updated_at: string, username: string, video_fallback: bool, watermark: bool, watermark_height: int, watermark_image_url: string, watermark_opacity: int, watermark_position: string, watermark_width: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}"))
  let req_body = {"transcoder": $transcoder} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disable a transcoder's stream targets
#
# PUT /transcoders/{id}/disable_all_stream_targets
# operationId: disableAllStreamTargetsTranscoder
export def "transcoders-disable-all-stream-targets disable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcoder: record<stream_targets: record<state: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}/disable_all_stream_targets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a transcoder's stream targets
#
# PUT /transcoders/{id}/enable_all_stream_targets
# operationId: enableAllStreamTargetsTranscoder
export def "transcoders-enable-all-stream-targets enable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcoder: record<stream_targets: record<state: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}/enable_all_stream_targets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a transcoder's recordings
#
# GET /transcoders/{id}/recordings
# operationId: listTranscoderRecordings
export def "transcoders-recordings list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcoder: record<recordings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}/recordings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset a transcoder
#
# PUT /transcoders/{id}/reset
# operationId: resetTranscoder
export def "transcoders-reset reset" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcoder: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}/reset"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch transcoder's schedules
#
# GET /transcoders/{id}/schedules
# operationId: listTranscoderSchedules
export def "transcoders-schedules list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcoder: record<schedules: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}/schedules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start a transcoder
#
# PUT /transcoders/{id}/start
# operationId: startTranscoder
export def "transcoders-start start" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcoder: record<state: string, transcoding_uptime_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the state and uptime ID of a transcoder
#
# GET /transcoders/{id}/state
# operationId: showTranscoderState
export def "transcoders-state get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcoder: record<state: string, transcoding_uptime_id: string, uptime_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch statistics for a current transcoder
#
# GET /transcoders/{id}/stats
# operationId: showTranscoderStats
export def "transcoders-stats stats-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcoder: record<audio_codec: record<status: string, text: string, units: string, value: string>, bits_in_rate: record<status: string, text: string, units: string, value: float>, bits_out_rate: record<status: string, text: string, units: string, value: float>, bytes_in_rate: record<status: string, text: string, units: string, value: float>, bytes_out_rate: record<status: string, text: string, units: string, value: float>, configured_bytes_out_rate: record<status: string, text: string, units: string, value: int>, connected: record<status: string, text: string, units: string, value: string>, cpu: record<status: string, text: string, units: string, value: int>, frame_rate: record<status: string, text: string, units: string, value: int>, frame_size: record<status: string, text: string, units: string, value: string>, gpu_decoder_usage: record<status: string, text: string, units: string, value: int>, gpu_driver_version: record<status: string, text: string, units: string, value: string>, gpu_encoder_usage: record<status: string, text: string, units: string, value: int>, gpu_memory_usage: record<status: string, text: string, units: string, value: int>, gpu_usage: record<status: string, text: string, units: string, value: int>, height: record<status: string, text: string, units: string, value: int>, keyframe_interval: record<status: string, text: string, units: string, value: int>, stream_target_status_OUTPUTIDX_STREAMTARGETIDX: record<status: string, text: string, units: string, value: string>, unique_views: record<status: string, text: string, units: string, value: int>, video_codec: record<status: string, text: string, units: string, value: string>, width: record<status: string, text: string, units: string, value: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}/stats"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop a transcoder
#
# PUT /transcoders/{id}/stop
# operationId: stopTranscoder
export def "transcoders-stop stop" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcoder: record<state: string, transcoding_uptime_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the thumbnail URL of a transcoder
#
# GET /transcoders/{id}/thumbnail_url
# operationId: showTranscoderThumbnailUrl
export def "transcoders-thumbnail-url get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcoder: record<thumbnail_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transcoders/{id}/thumbnail_url"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch all outputs of a transcoder
#
# GET /transcoders/{transcoder_id}/outputs
# operationId: listTranscoderOutputs
export def "transcoders-outputs list" [
  transcoder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<outputs: table<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id)} | format pattern "/transcoders/{transcoder_id}/outputs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an output
#
# POST /transcoders/{transcoder_id}/outputs
# operationId: createTranscoderOutput
# --output shape: {aspect_ratio_height?: int, aspect_ratio_width?: int, bitrate_audio?: int, bitrate_video?: int, framerate_reduction?: "0"|"1/2"|"1/4"|"1/25"|"1/30"|"1/50"|"1/60", h264_profile?: "main"|"baseline"|"high", keyframes?: "follow_source"|"25"|"30"|"50"|"60"|"100"|"120", passthrough_audio?: bool, passthrough_video?: bool, stream_format: "audiovideo"|"videoonly"|"audioonly"}
export def "transcoders-outputs create" [
  transcoder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  output: record # shape: {aspect_ratio_height?: int, aspect_ratio_width?: int, bitrate_audio?: int, bitrate_video?: int, framerate_reduction?: "0"|"1/2"|"1/4"|"1/25"|"1/30"|"1/50"|"1/60", h264_profile?: "main"|"baseline"|"high", keyframes?: "follow_source"|"25"|"30"|"50"|"60"|"100"|"120", passthrough_audio?: bool, passthrough_video?: bool, stream_format: "audiovideo"|"videoonly"|"audioonly"}
]: any -> record<output: record<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list<record>, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id)} | format pattern "/transcoders/{transcoder_id}/outputs"))
  let req_body = {"output": $output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an output
#
# DELETE /transcoders/{transcoder_id}/outputs/{id}
# operationId: deleteTranscoderOutput
export def "transcoders-outputs delete" [
  transcoder_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), id: (encode-path-segment $id)} | format pattern "/transcoders/{transcoder_id}/outputs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an output
#
# GET /transcoders/{transcoder_id}/outputs/{id}
# operationId: showTranscoderOutput
export def "transcoders-outputs get-show" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<output: record<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list<record>, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), id: (encode-path-segment $id)} | format pattern "/transcoders/{transcoder_id}/outputs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an output
#
# PATCH /transcoders/{transcoder_id}/outputs/{id}
# operationId: updateTranscoderOutput
# --output shape: {aspect_ratio_height?: int, aspect_ratio_width?: int, bitrate_audio?: int, bitrate_video?: int, framerate_reduction?: "0"|"1/2"|"1/4"|"1/25"|"1/30"|"1/50"|"1/60", h264_profile?: "main"|"baseline"|"high", keyframes?: "follow_source"|"25"|"30"|"50"|"60"|"100"|"120", passthrough_audio?: bool, passthrough_video?: bool, stream_format: "audiovideo"|"videoonly"|"audioonly"}
export def "transcoders-outputs update" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  output: record # shape: {aspect_ratio_height?: int, aspect_ratio_width?: int, bitrate_audio?: int, bitrate_video?: int, framerate_reduction?: "0"|"1/2"|"1/4"|"1/25"|"1/30"|"1/50"|"1/60", h264_profile?: "main"|"baseline"|"high", keyframes?: "follow_source"|"25"|"30"|"50"|"60"|"100"|"120", passthrough_audio?: bool, passthrough_video?: bool, stream_format: "audiovideo"|"videoonly"|"audioonly"}
]: any -> record<output: record<aspect_ratio_height: int, aspect_ratio_width: int, bitrate_audio: int, bitrate_video: int, created_at: string, framerate_reduction: string, h264_profile: string, id: string, keyframes: string, name: string, output_stream_targets: list<record>, passthrough_audio: bool, passthrough_video: bool, stream_format: string, transcoder_id: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), id: (encode-path-segment $id)} | format pattern "/transcoders/{transcoder_id}/outputs/{id}"))
  let req_body = {"output": $output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deprecated operation
#
# POST /transcoders/{transcoder_id}/outputs/{id}/add_stream_target
# DEPRECATED
# operationId: addStreamTargetToTranscoderOutput
# --output_stream_target shape: {stream_target_id: string, use_stream_target_backup_url?: bool}
@deprecated
export def "transcoders-outputs-add-stream-target create" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  output_stream_target: record # shape: {stream_target_id: string, use_stream_target_backup_url?: bool}
]: any -> record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), id: (encode-path-segment $id)} | format pattern "/transcoders/{transcoder_id}/outputs/{id}/add_stream_target"))
  let req_body = {"output_stream_target": $output_stream_target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deprecated operation
#
# DELETE /transcoders/{transcoder_id}/outputs/{id}/remove_stream_target
# DEPRECATED
# operationId: removeStreamTargetToTranscoderOutput
# --output_stream_target shape: {stream_target_id: string}
@deprecated
export def "transcoders-outputs-remove-stream-target delete" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  output_stream_target: record # shape: {stream_target_id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), id: (encode-path-segment $id)} | format pattern "/transcoders/{transcoder_id}/outputs/{id}/remove_stream_target"))
  let req_body = {"output_stream_target": $output_stream_target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Fetch all output stream targets of an output of a transcoder
#
# GET /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets
# operationId: listTranscoderOutputOutputStreamTargets
export def "transcoders-outputs-output-stream-targets list" [
  transcoder_id: string
  output_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list<string>, location: string, name: string, password: string, playback_urls: record<hls: string, wowz: string, ws: string>, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), output_id: (encode-path-segment $output_id)} | format pattern "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an output stream target
#
# POST /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets
# operationId: createTranscoderOutputOutputStreamTarget
# --output_stream_target shape: {stream_target_id: string, use_stream_target_backup_url?: bool}
export def "transcoders-outputs-output-stream-targets create" [
  transcoder_id: string
  output_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  output_stream_target: record # shape: {stream_target_id: string, use_stream_target_backup_url?: bool}
]: any -> record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), output_id: (encode-path-segment $output_id)} | format pattern "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets"))
  let req_body = {"output_stream_target": $output_stream_target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an output stream target
#
# DELETE /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}
# operationId: deleteTranscoderOutputOutputStreamTarget
export def "transcoders-outputs-output-stream-targets delete" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), output_id: (encode-path-segment $output_id), stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an output stream target
#
# GET /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}
# operationId: showTranscoderOutputOutputStreamTarget
export def "transcoders-outputs-output-stream-targets get-show" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), output_id: (encode-path-segment $output_id), stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an output stream target
#
# PATCH /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}
# operationId: updateTranscoderOutputOutputStreamTarget
# --output_stream_target shape: {stream_target_id: string, use_stream_target_backup_url?: bool}
export def "transcoders-outputs-output-stream-targets update" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  output_stream_target: record # shape: {stream_target_id: string, use_stream_target_backup_url?: bool}
]: any -> record<output_stream_target: record<created_at: string, id: string, output_id: string, stream_target: record<backup_url: string, chunk_size: string, connection_code: string, connection_code_expires_at: string, created_at: string, enable_hls: bool, enabled: bool, hds_playback_url: string, hls_playback_url: string, id: string, ingest_ip_whitelist: list, location: string, name: string, password: string, playback_urls: record, primary_url: string, provider: string, region_override: string, rtmp_playback_url: string, secure_ingest_query_param: string, source_delivery_method: string, source_url: string, stream_name: string, type: string, updated_at: string, use_cors: bool, use_https: bool, use_secure_ingest: bool, username: string>, stream_target_id: string, updated_at: string, use_stream_target_backup_url: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), output_id: (encode-path-segment $output_id), stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}"))
  let req_body = {"output_stream_target": $output_stream_target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disable an output stream target
#
# PUT /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/disable
# operationId: disableTranscoderOutputOutputStreamTarget
export def "transcoders-outputs-output-stream-targets-disable disable" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stream_target: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), output_id: (encode-path-segment $output_id), stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/disable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable an output stream target
#
# PUT /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/enable
# operationId: enableTranscoderOutputOutputStreamTarget
export def "transcoders-outputs-output-stream-targets-enable enable" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stream_target: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), output_id: (encode-path-segment $output_id), stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restart an output stream target
#
# PUT /transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/restart
# operationId: restartTranscoderOutputOutputStreamTarget
export def "transcoders-outputs-output-stream-targets-restart restart" [
  transcoder_id: string
  output_id: string
  stream_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stream_target: record<state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), output_id: (encode-path-segment $output_id), stream_target_id: (encode-path-segment $stream_target_id)} | format pattern "/transcoders/{transcoder_id}/outputs/{output_id}/output_stream_targets/{stream_target_id}/restart"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a transcoder's properties
#
# GET /transcoders/{transcoder_id}/properties
# operationId: listTranscoderProperties
export def "transcoders-properties list" [
  transcoder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<properties: table<key: string, section: string, transcoder_id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id)} | format pattern "/transcoders/{transcoder_id}/properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a property for a transcoder
#
# POST /transcoders/{transcoder_id}/properties
# operationId: createTranscoderProperty
# --property shape: {key: string, section: string, value: string}
export def "transcoders-properties create-property" [
  transcoder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  property: record # shape: {key: string, section: string, value: string}
]: any -> record<property: record<key: string, section: string, transcoder_id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id)} | format pattern "/transcoders/{transcoder_id}/properties"))
  let req_body = {"property": $property} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a transcoder's property
#
# DELETE /transcoders/{transcoder_id}/properties/{id}
# operationId: deleteTranscoderProperty
export def "transcoders-properties delete-property" [
  transcoder_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), id: (encode-path-segment $id)} | format pattern "/transcoders/{transcoder_id}/properties/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a property for a transcoder
#
# GET /transcoders/{transcoder_id}/properties/{id}
# operationId: showTranscoderProperty
export def "transcoders-properties get-show-property" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<property: record<key: string, section: string, transcoder_id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), id: (encode-path-segment $id)} | format pattern "/transcoders/{transcoder_id}/properties/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch all uptime records for a transcoder
#
# GET /transcoders/{transcoder_id}/uptimes
# operationId: indexUptimes
export def "transcoders-uptimes get-index" [
  transcoder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Returns a paginated view of results from the HTTP request. Specify a positive integer to indicate which page of the results should be displayed first. Next and Previous links allow you to navigate multiple pages of results. Omit the page parameter or specify an integer that's less than or equal to 0 to view all (unpaginated) results.
  --per-page: int # For use with the page parameter. Indicates how many records should be included on each page of results. A valid value is any positive integer. The default is 10.
]: nothing -> record<uptimes: table<billed: bool, created_at: string, ended_at: string, id: string, running: bool, started_at: string, transcoder_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id)} | format pattern "/transcoders/{transcoder_id}/uptimes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an uptime record
#
# GET /transcoders/{transcoder_id}/uptimes/{id}
# operationId: showUptime
export def "transcoders-uptimes get-show" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billed: bool, created_at: string, ended_at: string, id: string, running: bool, started_at: string, transcoder_id: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), id: (encode-path-segment $id)} | format pattern "/transcoders/{transcoder_id}/uptimes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch current stream health metrics for an active transcoder
#
# GET /transcoders/{transcoder_id}/uptimes/{id}/metrics/current
# operationId: showUptimeMetricsCurrent
export def "transcoders-uptimes-metrics-current get-show" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # A comma-separated list of fields to return.
]: nothing -> record<current: record<audio_codec: record<status: string, text: string, units: string, value: string>, bits_in_rate: record<status: string, text: string, units: string, value: float>, bits_out_rate: record<status: string, text: string, units: string, value: float>, bytes_in_rate: record<status: string, text: string, units: string, value: float>, bytes_out_rate: record<status: string, text: string, units: string, value: float>, configured_bytes_out_rate: record<status: string, text: string, units: string, value: int>, connected: record<status: string, text: string, units: string, value: string>, cpu: record<status: string, text: string, units: string, value: int>, frame_rate: record<status: string, text: string, units: string, value: int>, frame_size: record<status: string, text: string, units: string, value: string>, gpu_decoder_usage: record<status: string, text: string, units: string, value: int>, gpu_driver_version: record<status: string, text: string, units: string, value: string>, gpu_encoder_usage: record<status: string, text: string, units: string, value: int>, gpu_memory_usage: record<status: string, text: string, units: string, value: int>, gpu_usage: record<status: string, text: string, units: string, value: int>, height: record<status: string, text: string, units: string, value: int>, keyframe_interval: record<status: string, text: string, units: string, value: int>, stream_target_status_OUTPUTIDX_STREAMTARGETIDX: record<status: string, text: string, units: string, value: string>, unique_views: record<status: string, text: string, units: string, value: int>, video_codec: record<status: string, text: string, units: string, value: string>, width: record<status: string, text: string, units: string, value: int>>, limits: record<fields: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), id: (encode-path-segment $id)} | format pattern "/transcoders/{transcoder_id}/uptimes/{id}/metrics/current") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch historic stream health metrics for a transcoder
#
# GET /transcoders/{transcoder_id}/uptimes/{id}/metrics/historic
# operationId: showUptimeMetricsHistoric
export def "transcoders-uptimes-metrics-historic get-show" [
  transcoder_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # A comma-separated list of fields to return.
  --qp-from: string # The start of the range of time used to aggregate the metrics. Express the value by using the ISO 8601 standard of YYYY-MM-DDTHH:MM:SSZ where HH is a 24-hour clock in UTC.
  --qp-to: string # The end of the range of time used to aggregate the metrics. Express the value by using the ISO 8601 standard of YYYY-MM-DDTHH:MM:SSZ where HH is a 24-hour clock in UTC.
]: nothing -> record<historic: table<audio_codec: record, bits_in_rate: record, bits_out_rate: record, cpu_idle: record, created_at: string, frame_rate: record, height: record, keyframe_interval: record, video_codec: record, width: record>, limits: record<fields: string, from: string, to: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transcoder_id: (encode-path-segment $transcoder_id), id: (encode-path-segment $id)} | format pattern "/transcoders/{transcoder_id}/uptimes/{id}/metrics/historic") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch network usage for all stream sources
#
# GET /usage/network/stream_sources
# operationId: usageNetworkStreamSourcesIndex
export def "usage-network-stream-sources get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --qp-to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
]: nothing -> record<stream_sources: table<bytes_billed: int, bytes_used: int, deleted: bool, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usage/network/stream_sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch network usage for all stream targets
#
# GET /usage/network/stream_targets
# operationId: usageNetworkStreamTargetsIndex
export def "usage-network-stream-targets get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --qp-to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
]: nothing -> record<stream_targets: record<bytes_billed: int, bytes_used: int, deleted: bool, id: string, name: string, protocols: record<zones: record>>, total: record<bytes_billed: int, bytes_used: int, protocols: record<zones: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usage/network/stream_targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch network usage for all transcoders
#
# GET /usage/network/transcoders
# operationId: usageNetworkTranscodersIndex
export def "usage-network-transcoders get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --qp-to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
  --transcoder-type: string@transcoder-type-completer # The type of transcoder. The default is transcoded.
  --billing-mode: string@billing-mode-completer # The billing mode for the transcoder. The default is pay_as_you_go.
]: nothing -> record<transcoders: table<bytes_billed: int, bytes_used: int, deleted: bool, id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "transcoder_type" $transcoder_type "scalar") (serialize-qp "billing_mode" $billing_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usage/network/transcoders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch peak recording storage
#
# GET /usage/storage/peak_recording
# operationId: usageStoragePeakRecordingIndex
export def "usage-storage-peak-recording get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --qp-to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
]: nothing -> record<peak_recording: record<bytes_total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usage/storage/peak_recording" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch stream processing time
#
# GET /usage/time/transcoders
# operationId: usageTimeTranscodersIndex
export def "usage-time-transcoders get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --qp-to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
  --transcoder-type: string@transcoder-type-completer # The type of transcoder. The default is transcoded.
  --billing-mode: string@billing-mode-completer # The billing mode for the transcoder. The default is pay_as_you_go.
]: nothing -> record<transcoders: table<deleted: bool, id: int, name: string, seconds_billed: int, seconds_used: int>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "transcoder_type" $transcoder_type "scalar") (serialize-qp "billing_mode" $billing_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usage/time/transcoders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch viewer data for a stream target
#
# GET /usage/viewer_data/stream_targets/{id}
# operationId: showViewerDataStreamTarget
export def "usage-viewer-data-stream-targets get-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The start of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The from default is the last billing date. (format: date-time)
  --qp-to: string # The end of the range of time you want to view. Specify YYYY-MM-DD HH:MM:SS where HH is a 24-hour clock in UTC. The to default is the end of the current day. (format: date-time)
]: nothing -> record<stream_target: record<countries: list<record>, country_list: list<string>, percentage_viewers: int, percentage_viewing_time: int, protocols: list<record>, rendition_list: list<string>, renditions: list<record>, seconds_avg_viewing_time: int, seconds_total_viewing_time: int, total_unique_viewers: int>> {
  let auth = (build-auth $token ($auth_scheme | default "wsc-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/usage/viewer_data/stream_targets/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
