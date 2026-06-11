# Auto-generated client for SONOS SWAGGER API v0.9
# Source: https://raw.githubusercontent.com/antxxxx/sonos-swagger-api/master/api/swagger/swagger.yaml
# Auth: --token flag or $env.SONOS_SWAGGER_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SONOS_SWAGGER_API_TOKEN | default "" }
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
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def mute-completer [] { ["mute off" "mute on"] }
def playbackState-completer [] { ["pause" "play" "toggle"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "players list" } } | get name | first)
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

# get all players
#
# GET /players
# operationId: getPlayers
export def "players list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<coordinator: record<uuid: string, zoneName: string>, groupState: record<volume: int, mute: string, : string>, playerName: string, state: record<currentTrack: record, nextTrack: record, volume: int, mute: string, trackNo: int, elapsedTime: int, elapsedTimeFormatted: string, playbackState: string, playMode: record>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/players")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get individual player
#
# GET /players/{playerName}
# operationId: getPlayer
export def "players get" [
  playerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<coordinator: record<uuid: string, zoneName: string>, groupState: record<volume: int, mute: string, : string>, playerName: string, state: record<currentTrack: record<artist: string, title: string, album: string, duration: int, uri: string, type: string, stationName: string>, nextTrack: record<artist: string, title: string, album: string, duration: int, uri: string>, volume: int, mute: string, trackNo: int, elapsedTime: int, elapsedTimeFormatted: string, playbackState: string, playMode: record<repeat: string, shuffle: string, crossfade: string>>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/players/($playerName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get player state
#
# GET /players/{playerName}/state
# operationId: getPlayerState
export def "players-state get" [
  playerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<currentTrack: record<artist: string, title: string, album: string, duration: int, uri: string, type: string, stationName: string>, nextTrack: record<artist: string, title: string, album: string, duration: int, uri: string>, volume: int, mute: string, trackNo: int, elapsedTime: int, elapsedTimeFormatted: string, playbackState: string, playMode: record<repeat: string, shuffle: string, crossfade: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/players/($playerName)/state")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# set player state
#
# PUT /players/{playerName}/state
# operationId: setPlayerState
# --currentTrack shape: {favourite?: string, playlist?: string, clip?: string, text?: string, skip?: string, source?: string, lineinSource?: string, artistTopTracks?: string, artistRadio?: string, song?: string, ?: string}
# --playMode shape: {repeat?: "all"|"one"|"none", shuffle?: "shuffle on"|"shuffle off", crossfade?: "crossfade on"|"crossfade off", ?: string}
export def "players-state setPlayerState" [
  playerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
  --currentTrack: record # shape: {favourite?: string, playlist?: string, clip?: string, text?: string, skip?: string, source?: string, lineinSource?: string, artistTopTracks?: string, artistRadio?: string, song?: string, ?: string}
  --volume: int
  --mute: string@mute-completer
  --trackNo: int
  --elapsedTime: int
  --playbackState: string@playbackState-completer
  --playMode: record # shape: {repeat?: "all"|"one"|"none", shuffle?: "shuffle on"|"shuffle off", crossfade?: "crossfade on"|"crossfade off", ?: string}
]: any -> record<currentTrack: record<artist: string, title: string, album: string, duration: int, uri: string, type: string, stationName: string>, nextTrack: record<artist: string, title: string, album: string, duration: int, uri: string>, volume: int, mute: string, trackNo: int, elapsedTime: int, elapsedTimeFormatted: string, playbackState: string, playMode: record<repeat: string, shuffle: string, crossfade: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($playerName)/state" $qp)
  let body = {currentTrack: $currentTrack, volume: $volume, mute: $mute, trackNo: $trackNo, elapsedTime: $elapsedTime, playbackState: $playbackState, playMode: $playMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get player now playing
#
# GET /players/{playerName}/nowplaying
# operationId: getPlayerNowPlaying
export def "players-nowplaying get" [
  playerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<artist: string, title: string, album: string, albumArtUri: string, duration: int, uri: string, type: string, stationName: string, absoluteAlbumArtUri: string, uriMetadata: string, avTransportUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/players/($playerName)/nowplaying")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# set player now playing
#
# POST /players/{playerName}/nowplaying
# operationId: setPlayerNowPlaying
export def "players-nowplaying setPlayerNowPlaying" [
  playerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
  --uri: string
  --metadata: string
]: any -> record<artist: string, title: string, album: string, albumArtUri: string, duration: int, uri: string, type: string, stationName: string, absoluteAlbumArtUri: string, uriMetadata: string, avTransportUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($playerName)/nowplaying" $qp)
  let body = {uri: $uri, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get player queue
#
# GET /players/{playerName}/queue
# operationId: getPlayerQueue
export def "players-queue get" [
  playerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detailed: string@bool-completer # Flag to indicate if detailed information should be returned. Default is false
]: nothing -> table<uri: string, albumArtURI: string, title: string, artist: string, album: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($playerName)/queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# add to player queue
#
# PATCH /players/{playerName}/queue
# operationId: addToPlayerQueue
export def "players-queue addToPlayerQueue" [
  playerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
  --uri: string
  --metadata: string
  --enqueAsNext: string@bool-completer
  --desiredFirstTrackNumberEnqueued: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($playerName)/queue" $qp)
  let body = {uri: $uri, metadata: $metadata, enqueAsNext: $enqueAsNext, desiredFirstTrackNumberEnqueued: $desiredFirstTrackNumberEnqueued} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# clear player queue
#
# DELETE /players/{playerName}/queue
# operationId: clearPlayerQueue
export def "players-queue clearPlayerQueue" [
  playerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($playerName)/queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# replace playerqueue
#
# POST /players/{playerName}/queue
# operationId: replacePlayerQueue
export def "players-queue replacePlayerQueue" [
  playerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
  --uri: string
  --metadata: string
  --enqueAsNext: string@bool-completer
  --desiredFirstTrackNumberEnqueued: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($playerName)/queue" $qp)
  let body = {uri: $uri, metadata: $metadata, enqueAsNext: $enqueAsNext, desiredFirstTrackNumberEnqueued: $desiredFirstTrackNumberEnqueued} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get all zones
#
# GET /zones
# operationId: getZones
export def "zones list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<zoneName: string, state: record<currentTrack: record, nextTrack: record, volume: int, mute: string, trackNo: int, elapsedTime: int, elapsedTimeFormatted: string, playbackState: string, playMode: record>, members: list<record>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/zones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get individual zone
#
# GET /zones/{zoneName}
# operationId: getZone
export def "zones get" [
  zoneName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<zoneName: string, state: record<currentTrack: record<artist: string, title: string, album: string, duration: int, uri: string, type: string, stationName: string>, nextTrack: record<artist: string, title: string, album: string, duration: int, uri: string>, volume: int, mute: string, trackNo: int, elapsedTime: int, elapsedTimeFormatted: string, playbackState: string, playMode: record<repeat: string, shuffle: string, crossfade: string>>, members: table<playerName: string, state: record, uuid: string>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/zones/($zoneName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get zone state
#
# GET /zones/{zoneName}/state
# operationId: getZoneState
export def "zones-state get" [
  zoneName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<currentTrack: record<artist: string, title: string, album: string, duration: int, uri: string, type: string, stationName: string>, nextTrack: record<artist: string, title: string, album: string, duration: int, uri: string>, volume: int, mute: string, trackNo: int, elapsedTime: int, elapsedTimeFormatted: string, playbackState: string, playMode: record<repeat: string, shuffle: string, crossfade: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/zones/($zoneName)/state")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# set zone state
#
# PUT /zones/{zoneName}/state
# operationId: setZoneState
# --currentTrack shape: {favourite?: string, playlist?: string, clip?: string, text?: string, skip?: string, source?: string, lineinSource?: string, artistTopTracks?: string, artistRadio?: string, song?: string, ?: string}
# --playMode shape: {repeat?: "all"|"one"|"none", shuffle?: "shuffle on"|"shuffle off", crossfade?: "crossfade on"|"crossfade off", ?: string}
export def "zones-state setZoneState" [
  zoneName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
  --currentTrack: record # shape: {favourite?: string, playlist?: string, clip?: string, text?: string, skip?: string, source?: string, lineinSource?: string, artistTopTracks?: string, artistRadio?: string, song?: string, ?: string}
  --volume: int
  --mute: string@mute-completer
  --trackNo: int
  --elapsedTime: int
  --playbackState: string@playbackState-completer
  --playMode: record # shape: {repeat?: "all"|"one"|"none", shuffle?: "shuffle on"|"shuffle off", crossfade?: "crossfade on"|"crossfade off", ?: string}
]: any -> record<currentTrack: record<artist: string, title: string, album: string, duration: int, uri: string, type: string, stationName: string>, nextTrack: record<artist: string, title: string, album: string, duration: int, uri: string>, volume: int, mute: string, trackNo: int, elapsedTime: int, elapsedTimeFormatted: string, playbackState: string, playMode: record<repeat: string, shuffle: string, crossfade: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/($zoneName)/state" $qp)
  let body = {currentTrack: $currentTrack, volume: $volume, mute: $mute, trackNo: $trackNo, elapsedTime: $elapsedTime, playbackState: $playbackState, playMode: $playMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get zone now playing
#
# GET /zones/{zoneName}/nowplaying
# operationId: getZoneNowPlaying
export def "zones-nowplaying get" [
  zoneName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<artist: string, title: string, album: string, albumArtUri: string, duration: int, uri: string, type: string, stationName: string, absoluteAlbumArtUri: string, uriMetadata: string, avTransportUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/zones/($zoneName)/nowplaying")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# set zone now playing
#
# POST /zones/{zoneName}/nowplaying
# operationId: setZoneNowPlaying
export def "zones-nowplaying setZoneNowPlaying" [
  zoneName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
  --uri: string
  --metadata: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/($zoneName)/nowplaying" $qp)
  let body = {uri: $uri, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get zone queue
#
# GET /zones/{zoneName}/queue
# operationId: getZoneQueue
export def "zones-queue get" [
  zoneName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detailed: string@bool-completer # Flag to indicate if detailed information should be returned. Default is false
]: nothing -> table<uri: string, albumArtURI: string, title: string, artist: string, album: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/($zoneName)/queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# add to zone queue
#
# PATCH /zones/{zoneName}/queue
# operationId: addToZoneQueue
export def "zones-queue addToZoneQueue" [
  zoneName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
  --uri: string
  --metadata: string
  --enqueAsNext: string@bool-completer
  --desiredFirstTrackNumberEnqueued: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/($zoneName)/queue" $qp)
  let body = {uri: $uri, metadata: $metadata, enqueAsNext: $enqueAsNext, desiredFirstTrackNumberEnqueued: $desiredFirstTrackNumberEnqueued} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# clear zone queue
#
# DELETE /zones/{zoneName}/queue
# operationId: clearZoneQueue
export def "zones-queue clearZoneQueue" [
  zoneName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/($zoneName)/queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# replace zone queue
#
# POST /zones/{zoneName}/queue
# operationId: replaceZoneQueue
export def "zones-queue replaceZoneQueue" [
  zoneName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
  --uri: string
  --metadata: string
  --enqueAsNext: string@bool-completer
  --desiredFirstTrackNumberEnqueued: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/($zoneName)/queue" $qp)
  let body = {uri: $uri, metadata: $metadata, enqueAsNext: $enqueAsNext, desiredFirstTrackNumberEnqueued: $desiredFirstTrackNumberEnqueued} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get zone members
#
# GET /zones/{zoneName}/members
# operationId: getZoneMembers
export def "zones-members get" [
  zoneName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<playerName: string, state: record<currentTrack: record, nextTrack: record, volume: int, mute: string, trackNo: int, elapsedTime: int, elapsedTimeFormatted: string, playbackState: string, playMode: record>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/zones/($zoneName)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# add zone member
#
# POST /zones/{zoneName}/members
# operationId: addZoneMember
export def "zones-members addZoneMember" [
  zoneName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
  player: string
]: any -> table<playerName: string, state: record<currentTrack: record, nextTrack: record, volume: int, mute: string, trackNo: int, elapsedTime: int, elapsedTimeFormatted: string, playbackState: string, playMode: record>, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/($zoneName)/members" $qp)
  let body = {player: $player} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# remove zone member
#
# DELETE /zones/{zoneName}/members/{roomName}
# operationId: removeZoneMember
export def "zones-members removeZoneMember" [
  zoneName: string
  roomName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string@bool-completer
]: nothing -> table<playerName: string, state: record<currentTrack: record, nextTrack: record, volume: int, mute: string, trackNo: int, elapsedTime: int, elapsedTimeFormatted: string, playbackState: string, playMode: record>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/($zoneName)/members/($roomName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get search results from a music service
#
# GET /search
# operationId: search
export def "search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --service: string # The service to search
  --type: string # The type of search to perform - can be song, album, artist
  --q: string # The term to search for
  --offset: int # Used when multiple pages of results are returned to show results starting at offset
  --limit: int # How many search items to return
]: nothing -> record<returned: int, start: int, total: int, items: table<uri: string, title: string, artist: string, album: string, albumTrackNumber: int, imageUrl: string, type: string, metadata: string, synopsis: string, station: string, broadcast: string, duration: int>, previous: string, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "service" $service "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get favourites from sonos
#
# GET /favourites
# operationId: getFavourites
export def "favourites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detailed: string@bool-completer # Used to specify if return just the names of the favourites or full details. Defaults to false
]: nothing -> table<uri: string, title: string, metadata: string, albumArtUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/favourites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get individual favourite
#
# GET /favourites/{favourite}
# operationId: getFavourite
export def "favourites get" [
  favourite: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, title: string, albumArtUri: string, metadata: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/favourites/($favourite)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the swagger definiton
#
# GET /swagger
# operationId: GET_swagger
export def "swagger swagger" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/swagger")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
