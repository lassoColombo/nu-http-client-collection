# Auto-generated client for Stream API v1.5.0
# Source: https://video.bunnycdn.com/openapi/bunnynet-video-api.public.json
# Auth: --token flag or $env.STREAM_API_TOKEN

const BASE_URL = "https://video.bunnycdn.com"
const DEFAULT_AUTH = "accesskey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STREAM_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "accesskey" => { {headers: {AccessKey: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://video.bunnycdn.com"] }
def auth-scheme-completer [] { ["accesskey"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "library-collections GetCollection" } } | get name | first)
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

# Get Collection
#
# GET /library/{libraryId}/collections/{collectionId}
# operationId: Collection_GetCollection
export def "library-collections GetCollection" [
  libraryId: int
  collectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeThumbnails: oneof<nothing, bool> # default: false
]: nothing -> record<videoLibraryId: int, guid: string, name: string, videoCount: int, totalSize: int, previewVideoIds: string, previewImageUrls: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeThumbnails" $includeThumbnails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/collections/($collectionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Collection
#
# POST /library/{libraryId}/collections/{collectionId}
# operationId: Collection_UpdateCollection
export def "library-collections UpdateCollection" [
  libraryId: int
  collectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the collection (nullable)
]: any -> record<success: bool, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/collections/($collectionId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Collection
#
# DELETE /library/{libraryId}/collections/{collectionId}
# operationId: Collection_DeleteCollection
export def "library-collections DeleteCollection" [
  libraryId: int
  collectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, message: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/collections/($collectionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Collection List
#
# GET /library/{libraryId}/collections
# operationId: Collection_List
export def "library-collections List" [
  libraryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --itemsPerPage: int # format: int32, default: 100
  --search: string # nullable, default: 
  --orderBy: string # nullable, default: date
  --includeThumbnails: oneof<nothing, bool> # default: false
]: nothing -> record<totalItems: int, currentPage: int, itemsPerPage: int, items: table<videoLibraryId: int, guid: string, name: string, videoCount: int, totalSize: int, previewVideoIds: string, previewImageUrls: list>> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "includeThumbnails" $includeThumbnails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/collections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Collection
#
# POST /library/{libraryId}/collections
# operationId: Collection_CreateCollection
export def "library-collections CreateCollection" [
  libraryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the collection (nullable)
]: any -> record<videoLibraryId: int, guid: string, name: string, videoCount: int, totalSize: int, previewVideoIds: string, previewImageUrls: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/collections")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Video
#
# GET /library/{libraryId}/videos/{videoId}
# operationId: Video_GetVideo
export def "library-videos GetVideo" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<videoLibraryId: int, guid: string, title: string, description: string, dateUploaded: string, views: int, isPublic: bool, length: int, status: any, framerate: float, rotation: int, width: int, height: int, availableResolutions: string, outputCodecs: string, thumbnailCount: int, encodeProgress: int, storageSize: int, captions: table<srclang: string, label: string, version: int>, hasMP4Fallback: bool, collectionId: string, thumbnailFileName: string, thumbnailBlurhash: string, averageWatchTime: int, totalWatchTime: int, category: string, chapters: table<title: string, start: int, end: int>, moments: table<label: string, timestamp: int>, metaTags: table<property: string, value: string>, transcodingMessages: table<timeStamp: string, level: int, issueCode: int, message: string, value: string>, jitEncodingEnabled: bool, smartGenerateStatus: any, smartGenerateFeaturesStatus: any, hasOriginal: bool, originalHash: string, hasHighQualityPreview: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Video
#
# POST /library/{libraryId}/videos/{videoId}
# operationId: Video_UpdateVideo
# --chapters item shape: {title: string, start?: int, end?: int}
# --moments item shape: {label: string, timestamp?: int}
# --metaTags item shape: {property?: string, value?: string}
export def "library-videos UpdateVideo" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # The title of the video (nullable)
  --collectionId: string # The ID of the collection where the video belongs (nullable)
  --chapters: list # The list of chapters available for the video (nullable) — item shape: {title: string, start?: int, end?: int}
  --moments: list # The list of moments available for the video (nullable) — item shape: {label: string, timestamp?: int}
  --metaTags: list # The meta tags added to the video (nullable) — item shape: {property?: string, value?: string}
]: any -> record<success: bool, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)")
  let body = {title: $title, collectionId: $collectionId, chapters: $chapters, moments: $moments, metaTags: $metaTags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Video
#
# DELETE /library/{libraryId}/videos/{videoId}
# operationId: Video_DeleteVideo
export def "library-videos DeleteVideo" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, message: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload Video
#
# PUT /library/{libraryId}/videos/{videoId}
# operationId: Video_UploadVideo
export def "library-videos UploadVideo" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --jitEnabled: oneof<nothing, bool> # Marks whether JIT encoding should be enabled for this video (works only when Premium Encoding is enabled), overrides library settings
  --enabledResolutions: string # Comma separated list of resolutions enabled for encoding, available options: 240p, 360p, 480p, 720p, 1080p, 1440p, 2160p (nullable, default: )
  --enabledOutputCodecs: string # List of codecs that will be used to encode the file (overrides library settings). Available values: x264, vp9 (nullable, default: )
  --transcribeEnabled: oneof<nothing, bool> # Setting this to true will enable transcription on this video. Enabling this will incur transcription charges (nullable)
  --transcribeLanguages: string # Comma separated list of languages that will be used as target languages, use ISO 639-1 language codes. (nullable)
  --sourceLanguage: string # Language spoken in the video, use ISO 639-1 language codes. (nullable)
  --generateTitle: oneof<nothing, bool> # Whether video title should be generated from transcription. (nullable)
  --generateDescription: oneof<nothing, bool> # Whether video description should be generated from transcription. (nullable)
  --generateChapters: oneof<nothing, bool> # Whether video chapters should be generated from transcription. (nullable)
  --generateMoments: oneof<nothing, bool> # Whether video moments should be generated from transcription. (nullable)
  --body: record
]: any -> record<success: bool, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jitEnabled" $jitEnabled "scalar") (serialize-qp "enabledResolutions" $enabledResolutions "scalar") (serialize-qp "enabledOutputCodecs" $enabledOutputCodecs "scalar") (serialize-qp "transcribeEnabled" $transcribeEnabled "scalar") (serialize-qp "transcribeLanguages" $transcribeLanguages "scalar") (serialize-qp "sourceLanguage" $sourceLanguage "scalar") (serialize-qp "generateTitle" $generateTitle "scalar") (serialize-qp "generateDescription" $generateDescription "scalar") (serialize-qp "generateChapters" $generateChapters "scalar") (serialize-qp "generateMoments" $generateMoments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Get Video Heatmap
#
# GET /library/{libraryId}/videos/{videoId}/heatmap
# operationId: Video_GetVideoHeatmap
export def "library-videos-heatmap GetVideoHeatmap" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<heatmap: record> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/heatmap")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Video play data
#
# GET /library/{libraryId}/videos/{videoId}/play
# operationId: Video_GetVideoPlayData
export def "library-videos-play GetVideoPlayData" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # nullable, default: 
  --expires: int # format: int64, default: 0
]: nothing -> record<video: any, libraryName: string, captionsPath: string, seekPath: string, thumbnailUrl: string, fallbackUrl: string, videoPlaylistUrl: string, originalUrl: string, previewUrl: string, controls: string, enableDRM: bool, drmVersion: int, playerKeyColor: string, vastTagUrl: string, viAiPublisherId: string, captionsFontSize: int, captionsFontColor: string, captionsBackground: string, uiLanguage: string, allowEarlyPlay: bool, tokenAuthEnabled: bool, enableMP4Fallback: bool, showHeatmap: bool, fontFamily: string, playbackSpeeds: string, widevineMinClientSecurityLevel: int, zoneTier: int, isPlayable: bool, isPlaylistPlayable: bool, preferredPlaybackSource: any, rememberPlayerPosition: bool, customCss: string, exposeVideoMetadata: bool, enableCompactControls: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "expires" $expires "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/play" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Video heatmap data
#
# GET /library/{libraryId}/videos/{videoId}/play/heatmap
# operationId: Video_GetVideoHeatmapData
export def "library-videos-play-heatmap GetVideoHeatmapData" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # nullable, default: 
  --expires: int # format: int64, default: 0
]: nothing -> record<video: any, libraryName: string, captionsPath: string, seekPath: string, thumbnailUrl: string, fallbackUrl: string, videoPlaylistUrl: string, originalUrl: string, previewUrl: string, controls: string, enableDRM: bool, drmVersion: int, playerKeyColor: string, vastTagUrl: string, viAiPublisherId: string, captionsFontSize: int, captionsFontColor: string, captionsBackground: string, uiLanguage: string, allowEarlyPlay: bool, tokenAuthEnabled: bool, enableMP4Fallback: bool, showHeatmap: bool, fontFamily: string, playbackSpeeds: string, widevineMinClientSecurityLevel: int, zoneTier: int, isPlayable: bool, isPlaylistPlayable: bool, preferredPlaybackSource: any, rememberPlayerPosition: bool, customCss: string, exposeVideoMetadata: bool, enableCompactControls: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "expires" $expires "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/play/heatmap" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Video Statistics
#
# GET /library/{libraryId}/statistics
# operationId: Video_GetVideoStatistics
export def "library-statistics GetVideoStatistics" [
  libraryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # Optional start of the time range (UTC). If omitted or invalid, the last 30 days are returned. (nullable, format: date-time)
  --dateTo: string # Optional end of the time range (UTC). If omitted with a valid start, defaults to now; otherwise the last 30 days are returned. (nullable, format: date-time)
  --hourly: oneof<nothing, bool> # Optional. If true, returns hourly data; otherwise daily (UTC). Default is daily. (default: false)
  --videoGuid: string # Optional video GUID to filter results. When omitted, returns library-level aggregates. (nullable)
]: nothing -> record<viewsChart: record, watchTimeChart: record, countryViewCounts: record, countryWatchTime: record, engagementScore: int> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "hourly" $hourly "scalar") (serialize-qp "videoGuid" $videoGuid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reencode Video
#
# POST /library/{libraryId}/videos/{videoId}/reencode
# operationId: Video_ReencodeVideo
export def "library-videos-reencode ReencodeVideo" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<videoLibraryId: int, guid: string, title: string, description: string, dateUploaded: string, views: int, isPublic: bool, length: int, status: any, framerate: float, rotation: int, width: int, height: int, availableResolutions: string, outputCodecs: string, thumbnailCount: int, encodeProgress: int, storageSize: int, captions: table<srclang: string, label: string, version: int>, hasMP4Fallback: bool, collectionId: string, thumbnailFileName: string, thumbnailBlurhash: string, averageWatchTime: int, totalWatchTime: int, category: string, chapters: table<title: string, start: int, end: int>, moments: table<label: string, timestamp: int>, metaTags: table<property: string, value: string>, transcodingMessages: table<timeStamp: string, level: int, issueCode: int, message: string, value: string>, jitEncodingEnabled: bool, smartGenerateStatus: any, smartGenerateFeaturesStatus: any, hasOriginal: bool, originalHash: string, hasHighQualityPreview: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/reencode")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add output codec to video
#
# PUT /library/{libraryId}/videos/{videoId}/outputs/{outputCodecId}
# operationId: Video_ReencodeUsingCodec
export def "library-videos-outputs ReencodeUsingCodec" [
  libraryId: int
  videoId: string
  outputCodecId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<videoLibraryId: int, guid: string, title: string, description: string, dateUploaded: string, views: int, isPublic: bool, length: int, status: any, framerate: float, rotation: int, width: int, height: int, availableResolutions: string, outputCodecs: string, thumbnailCount: int, encodeProgress: int, storageSize: int, captions: table<srclang: string, label: string, version: int>, hasMP4Fallback: bool, collectionId: string, thumbnailFileName: string, thumbnailBlurhash: string, averageWatchTime: int, totalWatchTime: int, category: string, chapters: table<title: string, start: int, end: int>, moments: table<label: string, timestamp: int>, metaTags: table<property: string, value: string>, transcodingMessages: table<timeStamp: string, level: int, issueCode: int, message: string, value: string>, jitEncodingEnabled: bool, smartGenerateStatus: any, smartGenerateFeaturesStatus: any, hasOriginal: bool, originalHash: string, hasHighQualityPreview: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/outputs/($outputCodecId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Repackage Video
#
# POST /library/{libraryId}/videos/{videoId}/repackage
# operationId: Video_Repackage
export def "library-videos-repackage Repackage" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keepOriginalFiles: oneof<nothing, bool> # Marks whether previous file versions should be kept in storage, allows for faster repackage later on. Default is true. (default: true)
]: nothing -> record<videoLibraryId: int, guid: string, title: string, description: string, dateUploaded: string, views: int, isPublic: bool, length: int, status: any, framerate: float, rotation: int, width: int, height: int, availableResolutions: string, outputCodecs: string, thumbnailCount: int, encodeProgress: int, storageSize: int, captions: table<srclang: string, label: string, version: int>, hasMP4Fallback: bool, collectionId: string, thumbnailFileName: string, thumbnailBlurhash: string, averageWatchTime: int, totalWatchTime: int, category: string, chapters: table<title: string, start: int, end: int>, moments: table<label: string, timestamp: int>, metaTags: table<property: string, value: string>, transcodingMessages: table<timeStamp: string, level: int, issueCode: int, message: string, value: string>, jitEncodingEnabled: bool, smartGenerateStatus: any, smartGenerateFeaturesStatus: any, hasOriginal: bool, originalHash: string, hasHighQualityPreview: bool> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keepOriginalFiles" $keepOriginalFiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/repackage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Videos
#
# GET /library/{libraryId}/videos
# operationId: Video_List
export def "library-videos List" [
  libraryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --itemsPerPage: int # format: int32, default: 100
  --search: string # nullable, default: 
  --collection: string # nullable, default: 
  --orderBy: string # nullable, default: date
]: nothing -> record<totalItems: int, currentPage: int, itemsPerPage: int, items: table<videoLibraryId: int, guid: string, title: string, description: string, dateUploaded: string, views: int, isPublic: bool, length: int, status: any, framerate: float, rotation: int, width: int, height: int, availableResolutions: string, outputCodecs: string, thumbnailCount: int, encodeProgress: int, storageSize: int, captions: list, hasMP4Fallback: bool, collectionId: string, thumbnailFileName: string, thumbnailBlurhash: string, averageWatchTime: int, totalWatchTime: int, category: string, chapters: list, moments: list, metaTags: list, transcodingMessages: list, jitEncodingEnabled: bool, smartGenerateStatus: any, smartGenerateFeaturesStatus: any, hasOriginal: bool, originalHash: string, hasHighQualityPreview: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "collection" $collection "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Video
#
# POST /library/{libraryId}/videos
# operationId: Video_CreateVideo
export def "library-videos CreateVideo" [
  libraryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # The title of the video
  --collectionId: string # The ID of the collection where the video will be put (nullable)
  --thumbnailTime: int # Video time in ms to extract the main video thumbnail. (nullable, format: int32)
]: any -> record<videoLibraryId: int, guid: string, title: string, description: string, dateUploaded: string, views: int, isPublic: bool, length: int, status: any, framerate: float, rotation: int, width: int, height: int, availableResolutions: string, outputCodecs: string, thumbnailCount: int, encodeProgress: int, storageSize: int, captions: table<srclang: string, label: string, version: int>, hasMP4Fallback: bool, collectionId: string, thumbnailFileName: string, thumbnailBlurhash: string, averageWatchTime: int, totalWatchTime: int, category: string, chapters: table<title: string, start: int, end: int>, moments: table<label: string, timestamp: int>, metaTags: table<property: string, value: string>, transcodingMessages: table<timeStamp: string, level: int, issueCode: int, message: string, value: string>, jitEncodingEnabled: bool, smartGenerateStatus: any, smartGenerateFeaturesStatus: any, hasOriginal: bool, originalHash: string, hasHighQualityPreview: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos")
  let body = {title: $title, collectionId: $collectionId, thumbnailTime: $thumbnailTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Thumbnail
#
# POST /library/{libraryId}/videos/{videoId}/thumbnail
# operationId: Video_SetThumbnail
export def "library-videos-thumbnail SetThumbnail" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --thumbnailUrl: string # nullable
  --body: record
]: any -> record<success: bool, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thumbnailUrl" $thumbnailUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/thumbnail" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Fetch Video
#
# POST /library/{libraryId}/videos/fetch
# operationId: Video_FetchNewVideo
export def "library-videos-fetch FetchNewVideo" [
  libraryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --collectionId: string # nullable
  --thumbnailTime: int # (Optional) Video time in ms to extract the main video thumbnail. (nullable, format: int32)
  --body-url: string # The URL from which the video will be fetched from.
  --headers: record # The headers that will be sent along with the fetch request. (nullable)
  --title: string # The title that will be set to video. (nullable)
]: any -> record<success: bool, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collectionId" $collectionId "scalar") (serialize-qp "thumbnailTime" $thumbnailTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/videos/fetch" $qp)
  let body = {url: $body_url, headers: $headers, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Caption
#
# POST /library/{libraryId}/videos/{videoId}/captions/{srclang}
# operationId: Video_AddCaption
export def "library-videos-captions AddCaption" [
  libraryId: int
  videoId: string
  srclang: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-srclang: string # The unique srclang shortcode for the caption (nullable)
  --label: string # The text description label for the caption (nullable)
  --captionsFile: string # Base64 encoded captions file (nullable)
]: any -> record<success: bool, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/captions/($srclang)")
  let body = {srclang: $body_srclang, label: $label, captionsFile: $captionsFile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Caption
#
# DELETE /library/{libraryId}/videos/{videoId}/captions/{srclang}
# operationId: Video_DeleteCaption
export def "library-videos-captions DeleteCaption" [
  libraryId: int
  videoId: string
  srclang: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, message: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/captions/($srclang)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transcribe video
#
# POST /library/{libraryId}/videos/{videoId}/transcribe
# operationId: Video_TranscribeVideo
export def "library-videos-transcribe TranscribeVideo" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # default: false
  --targetLanguages: list # List of languages that will be used as target languages, use ISO 639-1 language codes. (nullable)
  --generateTitle: oneof<nothing, bool> # Whether video title should be automatically generated. (nullable)
  --generateDescription: oneof<nothing, bool> # Whether video description should be automatically generated. (nullable)
  --generateChapters: oneof<nothing, bool> # Whether video chapters should be automatically generated. (nullable)
  --generateMoments: oneof<nothing, bool> # Whether video moments should be automatically generated. (nullable)
  --sourceLanguage: string # Video source language, use ISO 639-1 language code. (nullable)
]: any -> record<success: bool, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/transcribe" $qp)
  let body = {targetLanguages: $targetLanguages, generateTitle: $generateTitle, generateDescription: $generateDescription, generateChapters: $generateChapters, generateMoments: $generateMoments, sourceLanguage: $sourceLanguage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Trigger Smart actions
#
# POST /library/{libraryId}/videos/{videoId}/smart
# operationId: Video_SmartGenerate
export def "library-videos-smart SmartGenerate" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --generateTitle: oneof<nothing, bool> # Whether video title should be generated. (nullable)
  --generateDescription: oneof<nothing, bool> # Whether video description should be generated. (nullable)
  --generateChapters: oneof<nothing, bool> # Whether video chapters should be generated. (nullable)
  --generateMoments: oneof<nothing, bool> # Whether video moments should be generated. (nullable)
  --sourceLanguage: string # (Optional) Video source language, use ISO 639-1 language code. (nullable)
]: any -> record<success: bool, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/smart")
  let body = {generateTitle: $generateTitle, generateDescription: $generateDescription, generateChapters: $generateChapters, generateMoments: $generateMoments, sourceLanguage: $sourceLanguage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Video resolutions info
#
# GET /library/{libraryId}/videos/{videoId}/resolutions
# operationId: Video_GetVideoResolutions
export def "library-videos-resolutions GetVideoResolutions" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, message: string, statusCode: int, data: any> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/resolutions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get video storage size info
#
# GET /library/{libraryId}/videos/{videoId}/storage
# operationId: Video_GetVideoStorageSize
export def "library-videos-storage GetVideoStorageSize" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, message: string, statusCode: int, data: any> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/storage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cleanup unconfigured resolutions
#
# POST /library/{libraryId}/videos/{videoId}/resolutions/cleanup
# operationId: Video_DeleteResolutions
export def "library-videos-resolutions-cleanup DeleteResolutions" [
  libraryId: int
  videoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resolutionsToDelete: string # nullable
  --deleteNonConfiguredResolutions: oneof<nothing, bool> # default: false
  --allResolutions: oneof<nothing, bool> # default: false
  --deleteOriginal: oneof<nothing, bool> # default: false
  --outputs: string # Outputs to clean. Supported values: hls, mp4, all (nullable)
  --deleteMp4Files: oneof<nothing, bool> # default: false
  --dryRun: oneof<nothing, bool> # If set to true, no actual file manipulation will happen, only informational data will be returned (default: false)
]: nothing -> record<success: bool, message: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resolutionsToDelete" $resolutionsToDelete "scalar") (serialize-qp "deleteNonConfiguredResolutions" $deleteNonConfiguredResolutions "scalar") (serialize-qp "allResolutions" $allResolutions "scalar") (serialize-qp "deleteOriginal" $deleteOriginal "scalar") (serialize-qp "outputs" $outputs "scalar") (serialize-qp "deleteMp4Files" $deleteMp4Files "scalar") (serialize-qp "dryRun" $dryRun "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/library/($libraryId)/videos/($videoId)/resolutions/cleanup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /OEmbed
#
# operationId: OEmbed_GetOEmbed
export def "o-embed GetOEmbed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-url: string # nullable
  --maxWidth: int # nullable, format: int32
  --maxHeight: int # nullable, format: int32
  --qp-token: string # nullable, default: 
  --expires: int # format: int64, default: 0
]: nothing -> record<version: string, title: string, type: string, thumbnail_url: string, width: int, height: int, html: string, provider_name: string, provider_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "maxWidth" $maxWidth "scalar") (serialize-qp "maxHeight" $maxHeight "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "expires" $expires "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/OEmbed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
