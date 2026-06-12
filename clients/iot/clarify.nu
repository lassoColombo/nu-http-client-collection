# Auto-generated client for api.clarify.io v1.3.7
# Source: https://api.apis.guru/v2/specs/clarify.io/1.3.7/swagger.json
# Auth: --token flag or $env.API_CLARIFY_IO_TOKEN

const BASE_URL = "https://api.clarify.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_CLARIFY_IO_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.clarify.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def audio-channel-completer [] { ["left" "right"] }
def audio-language-completer [] { ["en-UK" "en-US" "es" "fr"] }
def insight-completer [] { ["captions_r9" "spoken_keywords" "spoken_topics" "spoken_words" "transcript_r9"] }
def interval-completer [] { ["day" "hour" "month" "quarter" "week" "year"] }
def language-completer [] { ["en" "en-UK" "en-US" "es" "fr"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bundles list" } } | get name | first)
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

# List bundles
#
# GET /v1/bundles
export def "bundles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit results to specified number of bundles. Default is 10. Max 100.
  --embed: string # list of link relations to embed in the result collection. Zero or more of: items, tracks, metadata, insights. List is space or comma separated single string or an array of strings
  --iterator: string # optional opaque value, automatically provided in next/prev links, or literal "first", "last"
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "iterator" $iterator "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bundles" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a bundle
#
# POST /v1/bundles
export def "bundles post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the bundle. Up to 128 characters.
  --media-url: string # URL of a media (audio or video) file for this bundle. Up to 2083 characters.
  --audio-channel: string@audio-channel-completer # The audio channel to use for the track ( "" | left | right ). Default is empty string which means all channels of audio in the media file are used for the track.
  --audio-language: string@audio-language-completer # Language of the audio in the track, specified with an RFC5646 code.
  --start-time: float # Time offset in seconds that the media starts relative to the bundle. Default is 0.
  --parts-pending: oneof<nothing, bool> # Set to true if more media parts will be added to the track. Default is false.
  --label: string # Label for the track (if media_url is specified.) Up to 128 characters.
  --metadata: string # User-defined JSON data associated with the bundle. Must be valid JSON, up to 4000 characters.
  --notify-url: string # URL for notifications on this bundle. Up to 2083 characters.
  --external-id: string # A string that can refer to an item in an external system. Up to 128 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bundles")
  let body = {name: $name, media_url: $media_url, audio_channel: $audio_channel, audio_language: $audio_language, start_time: $start_time, parts_pending: $parts_pending, label: $label, metadata: $metadata, notify_url: $notify_url, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a bundle
#
# DELETE /v1/bundles/{bundle_id}
export def "bundles delete" [
  bundle_id: string
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
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a bundle
#
# GET /v1/bundles/{bundle_id}
export def "bundles get" [
  bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of link relations to embed in the result bundle. Zero or more of: tracks, metadata, insights. List is space or comma separated single string or an array of strings
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a bundle
#
# PUT /v1/bundles/{bundle_id}
export def "bundles put" [
  bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the bundle. Up to 128 characters.
  --notify-url: string # URL for notifications on this bundle. Up to 2083 characters.
  --external-id: string # A string that can refer to an item in an external system. Up to 128 characters.
  --version: int # Object version.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)")
  let body = {name: $name, notify_url: $notify_url, external_id: $external_id, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get bundle insights
#
# GET /v1/bundles/{bundle_id}/insights
export def "bundles-insights get" [
  bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/insights")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request an insight to be run
#
# POST /v1/bundles/{bundle_id}/insights
export def "bundles-insights post" [
  bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  insight: string@insight-completer # name of the insight: transcript_r9, captions_r9, spoken_keywords, spoken_topics, spoken_words
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/insights")
  let body = {insight: $insight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get bundle insight
#
# GET /v1/bundles/{bundle_id}/insights/{insight_id}
# operationId: v1bundlesbundle_idinsightsinsight_id
export def "bundles-insights id" [
  bundle_id: string
  insight_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/insights/($insight_id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete bundle metadata
#
# DELETE /v1/bundles/{bundle_id}/metadata
export def "bundles-metadata delete" [
  bundle_id: string
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
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bundle metadata
#
# GET /v1/bundles/{bundle_id}/metadata
export def "bundles-metadata get" [
  bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/metadata")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update bundle metadata
#
# PUT /v1/bundles/{bundle_id}/metadata
export def "bundles-metadata put" [
  bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: string # User-defined JSON data associated with the bundle. Must be valid JSON, up to 4000 characters.
  --version: int # Object version.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/metadata")
  let body = {data: $data, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete bundle tracks
#
# DELETE /v1/bundles/{bundle_id}/tracks
export def "bundles-tracks delete-by-bundle_id" [
  bundle_id: string
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
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/tracks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bundle tracks
#
# GET /v1/bundles/{bundle_id}/tracks
export def "bundles-tracks list" [
  bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/tracks")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a track for a bundle
#
# POST /v1/bundles/{bundle_id}/tracks
export def "bundles-tracks post" [
  bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Label for the track. Up to 128 characters.
  media_url: string # URL of a media file for this bundle. Up to 2083 characters.
  --audio-channel: string@audio-channel-completer # The audio channel to use for the track ( "" | left | right ). Default is empty string which means all channels of audio in the media file are used for the track.
  --audio-language: string@audio-language-completer # Language of the audio in the track, specified with an RFC5646 code.
  --start-time: float # Time offset in seconds that the media starts relative to the bundle. Default is 0.
  --parts-pending: oneof<nothing, bool> # Set to true if more media parts will be added to the track. Default is false.
  --track: int # Track number specifies the index of the new track in the tracks array. An integer from 0 to 11. If not specified, the new track is appended to the array.
  --version: int # Object version.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/tracks")
  let body = {label: $label, media_url: $media_url, audio_channel: $audio_channel, audio_language: $audio_language, start_time: $start_time, parts_pending: $parts_pending, track: $track, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update a tracks for a bundle
#
# PUT /v1/bundles/{bundle_id}/tracks
export def "bundles-tracks put-by-bundle_id" [
  bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parts-complete: oneof<nothing, bool> # Set to true if media parts in all tracks are complete. Default is false.
  --version: int # Object version.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/tracks")
  let body = {parts_complete: $parts_complete, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a bundle track
#
# DELETE /v1/bundles/{bundle_id}/tracks/{track_id}
export def "bundles-tracks delete-by-bundle_id-track_id" [
  bundle_id: string
  track_id: string
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
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/tracks/($track_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bundle track
#
# GET /v1/bundles/{bundle_id}/tracks/{track_id}
export def "bundles-tracks get" [
  bundle_id: string
  track_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/tracks/($track_id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add media to a track
#
# PUT /v1/bundles/{bundle_id}/tracks/{track_id}
export def "bundles-tracks put-by-bundle_id-track_id" [
  bundle_id: string
  track_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  media_url: string # URL of a media file for this bundle. Up to 2083 characters.
  --audio-channel: string@audio-channel-completer # The audio channel to use for the track ( "" | left | right ). Default is empty string which means all channels of audio in the media file are used for the track.
  --audio-language: string@audio-language-completer # Language of the audio in the track, specified with an RFC5646 code.
  --start-time: float # Time offset in seconds that the media starts relative to the bundle. Default is 0.
  --parts-pending: oneof<nothing, bool> # Set to true if more media parts will be added to the track. Default is false.
  --version: int # Object version.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bundles/($bundle_id)/tracks/($track_id)")
  let body = {media_url: $media_url, audio_channel: $audio_channel, audio_language: $audio_language, start_time: $start_time, parts_pending: $parts_pending, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Generate Group Report <span class="label">beta</span>
#
# GET /v1/reports/scores
# operationId: v1reportsscores
export def "reports-scores v1reportsscores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval: string@interval-completer # Duration of report periods. Default is month.
  --score-field: string # A bundle/metadata field to use as a score. Ex. insights.spoken_words.listener_score.
  --group-field: string # A metadata field by which to group scores, typically a user or team id field.
  --filter: string # filter expression, typically programmatically generated based on input controls and data segregation rules etc. Up to 500 characters.
  --language: string@language-completer # Language to search in, specified with an RFC5646 code. Default is "en"
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "interval" $interval "scalar") (serialize-qp "score_field" $score_field "scalar") (serialize-qp "group_field" $group_field "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/reports/scores" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate Trends Report <span class="label">beta</span>
#
# GET /v1/reports/trends
# operationId: v1reportstrends
export def "reports-trends v1reportstrends" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval: string@interval-completer # Duration of report periods. Default is month.
  --content: string # Content reported in each period. Zero or more of tracks, spoken_words, spoken_keywords. List is space or comma separated single string or an array of strings.
  --filter: string # filter expression, typically programmatically generated based on input controls and data segregation rules etc. Up to 500 characters.
  --language: string@language-completer # Language to search in, specified with an RFC5646 code. Default is "en"
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "interval" $interval "scalar") (serialize-qp "content" $content "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/reports/trends" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search bundles
#
# GET /v1/search
# operationId: v1search
export def "search v1search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # search terms, typically as typed into a search field. Up to 120 characters.
  --query-fields: string # list of insights, metadata, and bundle fields to search with the query. Use insights.spoken_words for searching audio, metadata.* for all metadata fields, bundle.* for all bundle fields, * for audio and all fields. Default is insights.spoken_words and metadata.*. List is space or comma separated single string or an array of strings. If single string, up to 1024 characters.
  --filter: string # filter expression, typically programmatically generated based on input controls and data segregation rules etc. Up to 500 characters.
  --language: string@language-completer # Language to search in, specified with an RFC5646 code. Default is "en"
  --limit: int # limit results to specified number of bundles. Default is 10. Max 100.
  --embed: string # list of link relations to embed in the result collection. Zero or more of: items, tracks, metadata, insights. List is space or comma separated single string or an array of strings
  --iterator: string # opaque value, automatically provided in next/prev links
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "query_fields" $query_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "embed" $embed "scalar") (serialize-qp "iterator" $iterator "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/search" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
