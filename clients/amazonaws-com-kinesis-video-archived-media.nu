# Auto-generated client for Amazon Kinesis Video Streams Archived Media v2017-09-30
# Source: https://api.apis.guru/v2/specs/amazonaws.com/kinesis-video-archived-media/2017-09-30/openapi.json
# Auth: --token flag or $env.AMAZON_KINESIS_VIDEO_STREAMS_ARCHIVED_MEDIA_TOKEN

const BASE_URL = "http://kinesisvideo.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_KINESIS_VIDEO_STREAMS_ARCHIVED_MEDIA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://kinesisvideo.us-east-1.amazonaws.com" "http://kinesisvideo.us-east-2.amazonaws.com" "http://kinesisvideo.us-west-1.amazonaws.com" "http://kinesisvideo.us-west-2.amazonaws.com" "http://kinesisvideo.us-gov-west-1.amazonaws.com" "http://kinesisvideo.us-gov-east-1.amazonaws.com" "http://kinesisvideo.ca-central-1.amazonaws.com" "http://kinesisvideo.eu-north-1.amazonaws.com" "http://kinesisvideo.eu-west-1.amazonaws.com" "http://kinesisvideo.eu-west-2.amazonaws.com" "http://kinesisvideo.eu-west-3.amazonaws.com" "http://kinesisvideo.eu-central-1.amazonaws.com" "http://kinesisvideo.eu-south-1.amazonaws.com" "http://kinesisvideo.af-south-1.amazonaws.com" "http://kinesisvideo.ap-northeast-1.amazonaws.com" "http://kinesisvideo.ap-northeast-2.amazonaws.com" "http://kinesisvideo.ap-northeast-3.amazonaws.com" "http://kinesisvideo.ap-southeast-1.amazonaws.com" "http://kinesisvideo.ap-southeast-2.amazonaws.com" "http://kinesisvideo.ap-east-1.amazonaws.com" "http://kinesisvideo.ap-south-1.amazonaws.com" "http://kinesisvideo.sa-east-1.amazonaws.com" "http://kinesisvideo.me-south-1.amazonaws.com" "https://kinesisvideo.us-east-1.amazonaws.com" "https://kinesisvideo.us-east-2.amazonaws.com" "https://kinesisvideo.us-west-1.amazonaws.com" "https://kinesisvideo.us-west-2.amazonaws.com" "https://kinesisvideo.us-gov-west-1.amazonaws.com" "https://kinesisvideo.us-gov-east-1.amazonaws.com" "https://kinesisvideo.ca-central-1.amazonaws.com" "https://kinesisvideo.eu-north-1.amazonaws.com" "https://kinesisvideo.eu-west-1.amazonaws.com" "https://kinesisvideo.eu-west-2.amazonaws.com" "https://kinesisvideo.eu-west-3.amazonaws.com" "https://kinesisvideo.eu-central-1.amazonaws.com" "https://kinesisvideo.eu-south-1.amazonaws.com" "https://kinesisvideo.af-south-1.amazonaws.com" "https://kinesisvideo.ap-northeast-1.amazonaws.com" "https://kinesisvideo.ap-northeast-2.amazonaws.com" "https://kinesisvideo.ap-northeast-3.amazonaws.com" "https://kinesisvideo.ap-southeast-1.amazonaws.com" "https://kinesisvideo.ap-southeast-2.amazonaws.com" "https://kinesisvideo.ap-east-1.amazonaws.com" "https://kinesisvideo.ap-south-1.amazonaws.com" "https://kinesisvideo.sa-east-1.amazonaws.com" "https://kinesisvideo.me-south-1.amazonaws.com" "http://kinesisvideo.cn-north-1.amazonaws.com.cn" "http://kinesisvideo.cn-northwest-1.amazonaws.com.cn" "https://kinesisvideo.cn-north-1.amazonaws.com.cn" "https://kinesisvideo.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def playback-mode-completer [] { ["LIVE" "LIVE_REPLAY" "ON_DEMAND"] }
def display-fragment-timestamp-completer [] { ["ALWAYS" "NEVER"] }
def display-fragment-number-completer [] { ["ALWAYS" "NEVER"] }
def container-format-completer [] { ["FRAGMENTED_MP4" "MPEG_TS"] }
def discontinuity-mode-completer [] { ["ALWAYS" "NEVER" "ON_DISCONTINUITY"] }
def image-selector-type-completer [] { ["PRODUCER_TIMESTAMP" "SERVER_TIMESTAMP"] }
def format-completer [] { ["JPEG" "PNG"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "get-clip get" } } | get name | first)
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

# Downloads an MP4 file (clip) containing the archived, on-demand media from the specified video stream over the specified time range. Both the StreamName and the StreamARN parameters are optional, but you must specify either the StreamName or the StreamARN when invoking this API operation. As a prerequisite to using GetCLip API, you must obtain an endpoint using GetDataEndpoint, specifying GET_CLIP for the APIName parameter. An Amazon Kinesis video stream has the following requirements for providing data through MP4: The media must contain h.264 or h.265 encoded video and, optionally, AAC or G.711 encoded audio. Specifically, the codec ID of track 1 should be V_MPEG/ISO/AVC (for h.264) or V_MPEGH/ISO/HEVC (for H.265). Optionally, the codec ID of track 2 should be A_AAC (for AAC) or A_MS/ACM (for G.711). Data retention must be greater than 0. The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format and HEVC for H.265 format. For more information, see MPEG-4 specification ISO/IEC 14496-15 (https://www.iso.org/standard/55980.html). For information about adapting stream data to a given format, see NAL Adaptation Flags (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html). The audio track (if present) of each fragment must contain codec private data in the AAC format (AAC specification ISO/IEC 13818-7 (https://www.iso.org/standard/43345.html)) or the MS Wave format (http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html). You can monitor the amount of outgoing data by monitoring the GetClip.OutgoingBytes Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see Monitoring Kinesis Video Streams (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html). For pricing information, see Amazon Kinesis Video Streams Pricing (https://aws.amazon.com/kinesis/video-streams/pricing/) and AWS Pricing (https://aws.amazon.com/pricing/). Charges for outgoing AWS data apply.
#
# POST /getClip
# operationId: GetClip
# --ClipFragmentSelector shape: {FragmentSelectorType?: any, TimestampRange?: any}
export def "get-clip get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --stream-name: string # The name of the stream for which to retrieve the media clip. You must specify either the StreamName or the StreamARN.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream for which to retrieve the media clip. You must specify either the StreamName or the StreamARN.
  clip_fragment_selector: record # Describes the timestamp range and timestamp origin of a range of fragments. Fragments that have duplicate producer timestamps are deduplicated. This means that if producers are producing a stream of fragments with producer timestamps that are approximately equal to the true clock time, the clip will contain all of the fragments within the requested timestamp range. If some fragments are ingested within the same time range and very different points in time, only the oldest ingested collection of fragments are returned. — shape: {FragmentSelectorType?: any, TimestampRange?: any}
]: any -> record<Payload: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getClip" $auth.query)
  let req_body = {"StreamName": $stream_name, "StreamARN": $stream_arn, "ClipFragmentSelector": $clip_fragment_selector} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves an MPEG Dynamic Adaptive Streaming over HTTP (DASH) URL for the stream. You can then open the URL in a media player to view the stream contents. Both the StreamName and the StreamARN parameters are optional, but you must specify either the StreamName or the StreamARN when invoking this API operation. An Amazon Kinesis video stream has the following requirements for providing data through MPEG-DASH: The media must contain h.264 or h.265 encoded video and, optionally, AAC or G.711 encoded audio. Specifically, the codec ID of track 1 should be V_MPEG/ISO/AVC (for h.264) or V_MPEGH/ISO/HEVC (for H.265). Optionally, the codec ID of track 2 should be A_AAC (for AAC) or A_MS/ACM (for G.711). Data retention must be greater than 0. The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format and HEVC for H.265 format. For more information, see MPEG-4 specification ISO/IEC 14496-15 (https://www.iso.org/standard/55980.html). For information about adapting stream data to a given format, see NAL Adaptation Flags (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html). The audio track (if present) of each fragment must contain codec private data in the AAC format (AAC specification ISO/IEC 13818-7 (https://www.iso.org/standard/43345.html)) or the MS Wave format (http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html). The following procedure shows how to use MPEG-DASH with Kinesis Video Streams: Get an endpoint using GetDataEndpoint (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_GetDataEndpoint.html), specifying GET_DASH_STREAMING_SESSION_URL for the APIName parameter. Retrieve the MPEG-DASH URL using GetDASHStreamingSessionURL. Kinesis Video Streams creates an MPEG-DASH streaming session to be used for accessing content in a stream using the MPEG-DASH protocol. GetDASHStreamingSessionURL returns an authenticated URL (that includes an encrypted session token) for the session's MPEG-DASH manifest (the root resource needed for streaming with MPEG-DASH). Don't share or store this token where an unauthorized entity can access it. The token provides access to the content of the stream. Safeguard the token with the same measures that you use with your AWS credentials. The media that is made available through the manifest consists only of the requested stream, time range, and format. No other media data (such as frames outside the requested window or alternate bitrates) is made available. Provide the URL (containing the encrypted session token) for the MPEG-DASH manifest to a media player that supports the MPEG-DASH protocol. Kinesis Video Streams makes the initialization fragment and media fragments available through the manifest URL. The initialization fragment contains the codec private data for the stream, and other data needed to set up the video or audio decoder and renderer. The media fragments contain encoded video frames or encoded audio samples. The media player receives the authenticated URL and requests stream metadata and media data normally. When the media player requests data, it calls the following actions: GetDASHManifest: Retrieves an MPEG DASH manifest, which contains the metadata for the media that you want to playback. GetMP4InitFragment: Retrieves the MP4 initialization fragment. The media player typically loads the initialization fragment before loading any media fragments. This fragment contains the "fytp" and "moov" MP4 atoms, and the child atoms that are needed to initialize the media player decoder. The initialization fragment does not correspond to a fragment in a Kinesis video stream. It contains only the codec private data for the stream and respective track, which the media player needs to decode the media frames. GetMP4MediaFragment: Retrieves MP4 media fragments. These fragments contain the "moof" and "mdat" MP4 atoms and their child atoms, containing the encoded fragment's media frames and their timestamps. After the first media fragment is made available in a streaming session, any fragments that don't contain the same codec private data cause an error to be returned when those different media fragments are loaded. Therefore, the codec private data should not change between fragments in a session. This also means that the session fails if the fragments in a stream change from having only video to having both audio and video. Data retrieved with this action is billable. See Pricing (https://aws.amazon.com/kinesis/video-streams/pricing/) for details. For restrictions that apply to MPEG-DASH sessions, see Kinesis Video Streams Limits (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html). You can monitor the amount of data that the media player consumes by monitoring the GetMP4MediaFragment.OutgoingBytes Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see Monitoring Kinesis Video Streams (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html). For pricing information, see Amazon Kinesis Video Streams Pricing (https://aws.amazon.com/kinesis/video-streams/pricing/) and AWS Pricing (https://aws.amazon.com/pricing/). Charges for both HLS sessions and outgoing AWS data apply. For more information about HLS, see HTTP Live Streaming (https://developer.apple.com/streaming/) on the Apple Developer site (https://developer.apple.com). If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: x-amz-ErrorType HTTP header – contains a more specific error type in addition to what the HTTP status code provides. x-amz-RequestId HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id. Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again. For more information, see the Errors section at the bottom of this topic, as well as Common Errors (https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html).
#
# POST /getDASHStreamingSessionURL
# operationId: GetDASHStreamingSessionURL
# --DASHFragmentSelector shape: {FragmentSelectorType?: any, TimestampRange?: any}
export def "get-dash-streaming-session-url get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --stream-name: string # The name of the stream for which to retrieve the MPEG-DASH manifest URL. You must specify either the StreamName or the StreamARN.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream for which to retrieve the MPEG-DASH manifest URL. You must specify either the StreamName or the StreamARN.
  --playback-mode: string@playback-mode-completer # Whether to retrieve live, live replay, or archived, on-demand data. Features of the three types of sessions include the following: LIVE : For sessions of this type, the MPEG-DASH manifest is continually updated with the latest fragments as they become available. We recommend that the media player retrieve a new manifest on a one-second interval. When this type of session is played in a media player, the user interface typically displays a "live" notification, with no scrubber control for choosing the position in the playback window to display. In LIVE mode, the newest available fragments are included in an MPEG-DASH manifest, even if there is a gap between fragments (that is, if a fragment is missing). A gap like this might cause a media player to halt or cause a jump in playback. In this mode, fragments are not added to the MPEG-DASH manifest if they are older than the newest fragment in the playlist. If the missing fragment becomes available after a subsequent fragment is added to the manifest, the older fragment is not added, and the gap is not filled. LIVE_REPLAY : For sessions of this type, the MPEG-DASH manifest is updated similarly to how it is updated for LIVE mode except that it starts by including fragments from a given start time. Instead of fragments being added as they are ingested, fragments are added as the duration of the next fragment elapses. For example, if the fragments in the session are two seconds long, then a new fragment is added to the manifest every two seconds. This mode is useful to be able to start playback from when an event is detected and continue live streaming media that has not yet been ingested as of the time of the session creation. This mode is also useful to stream previously archived media without being limited by the 1,000 fragment limit in the ON_DEMAND mode. ON_DEMAND : For sessions of this type, the MPEG-DASH manifest contains all the fragments for the session, up to the number that is specified in MaxManifestFragmentResults. The manifest must be retrieved only once for each session. When this type of session is played in a media player, the user interface typically displays a scrubber control for choosing the position in the playback window to display. In all playback modes, if FragmentSelectorType is PRODUCER_TIMESTAMP, and if there are multiple fragments with the same start timestamp, the fragment that has the larger fragment number (that is, the newer fragment) is included in the MPEG-DASH manifest. The other fragments are not included. Fragments that have different timestamps but have overlapping durations are still included in the MPEG-DASH manifest. This can lead to unexpected behavior in the media player. The default is LIVE.
  --display-fragment-timestamp: string@display-fragment-timestamp-completer # Per the MPEG-DASH specification, the wall-clock time of fragments in the manifest file can be derived using attributes in the manifest itself. However, typically, MPEG-DASH compatible media players do not properly handle gaps in the media timeline. Kinesis Video Streams adjusts the media timeline in the manifest file to enable playback of media with discontinuities. Therefore, the wall-clock time derived from the manifest file may be inaccurate. If DisplayFragmentTimestamp is set to ALWAYS, the accurate fragment timestamp is added to each S element in the manifest file with the attribute name “kvs:ts”. A custom MPEG-DASH media player is necessary to leverage this custom attribute. The default value is NEVER. When DASHFragmentSelector is SERVER_TIMESTAMP, the timestamps will be the server start timestamps. Similarly, when DASHFragmentSelector is PRODUCER_TIMESTAMP, the timestamps will be the producer start timestamps.
  --display-fragment-number: string@display-fragment-number-completer # Fragments are identified in the manifest file based on their sequence number in the session. If DisplayFragmentNumber is set to ALWAYS, the Kinesis Video Streams fragment number is added to each S element in the manifest file with the attribute name “kvs:fn”. These fragment numbers can be used for logging or for use with other APIs (e.g. GetMedia and GetMediaForFragmentList). A custom MPEG-DASH media player is necessary to leverage these this custom attribute. The default value is NEVER.
  --dash-fragment-selector: record # Contains the range of timestamps for the requested media, and the source of the timestamps. — shape: {FragmentSelectorType?: any, TimestampRange?: any}
  --expires: int # The time in seconds until the requested session expires. This value can be between 300 (5 minutes) and 43200 (12 hours). When a session expires, no new calls to GetDashManifest, GetMP4InitFragment, or GetMP4MediaFragment can be made for that session. The default is 300 (5 minutes).
  --max-manifest-fragment-results: int # The maximum number of fragments that are returned in the MPEG-DASH manifest. When the PlaybackMode is LIVE, the most recent fragments are returned up to this value. When the PlaybackMode is ON_DEMAND, the oldest fragments are returned, up to this maximum number. When there are a higher number of fragments available in a live MPEG-DASH manifest, video players often buffer content before starting playback. Increasing the buffer size increases the playback latency, but it decreases the likelihood that rebuffering will occur during playback. We recommend that a live MPEG-DASH manifest have a minimum of 3 fragments and a maximum of 10 fragments. The default is 5 fragments if PlaybackMode is LIVE or LIVE_REPLAY, and 1,000 if PlaybackMode is ON_DEMAND. The maximum value of 1,000 fragments corresponds to more than 16 minutes of video on streams with 1-second fragments, and more than 2 1/2 hours of video on streams with 10-second fragments.
]: any -> record<DASHStreamingSessionURL: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getDASHStreamingSessionURL" $auth.query)
  let req_body = {"StreamName": $stream_name, "StreamARN": $stream_arn, "PlaybackMode": $playback_mode, "DisplayFragmentTimestamp": $display_fragment_timestamp, "DisplayFragmentNumber": $display_fragment_number, "DASHFragmentSelector": $dash_fragment_selector, "Expires": $expires, "MaxManifestFragmentResults": $max_manifest_fragment_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves an HTTP Live Streaming (HLS) URL for the stream. You can then open the URL in a browser or media player to view the stream contents. Both the StreamName and the StreamARN parameters are optional, but you must specify either the StreamName or the StreamARN when invoking this API operation. An Amazon Kinesis video stream has the following requirements for providing data through HLS: The media must contain h.264 or h.265 encoded video and, optionally, AAC encoded audio. Specifically, the codec ID of track 1 should be V_MPEG/ISO/AVC (for h.264) or V_MPEG/ISO/HEVC (for h.265). Optionally, the codec ID of track 2 should be A_AAC. Data retention must be greater than 0. The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format or HEVC for H.265 format (MPEG-4 specification ISO/IEC 14496-15 (https://www.iso.org/standard/55980.html)). For information about adapting stream data to a given format, see NAL Adaptation Flags (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html). The audio track (if present) of each fragment must contain codec private data in the AAC format (AAC specification ISO/IEC 13818-7 (https://www.iso.org/standard/43345.html)). Kinesis Video Streams HLS sessions contain fragments in the fragmented MPEG-4 form (also called fMP4 or CMAF) or the MPEG-2 form (also called TS chunks, which the HLS specification also supports). For more information about HLS fragment types, see the HLS specification (https://tools.ietf.org/html/draft-pantos-http-live-streaming-23). The following procedure shows how to use HLS with Kinesis Video Streams: Get an endpoint using GetDataEndpoint (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_GetDataEndpoint.html), specifying GET_HLS_STREAMING_SESSION_URL for the APIName parameter. Retrieve the HLS URL using GetHLSStreamingSessionURL. Kinesis Video Streams creates an HLS streaming session to be used for accessing content in a stream using the HLS protocol. GetHLSStreamingSessionURL returns an authenticated URL (that includes an encrypted session token) for the session's HLS master playlist (the root resource needed for streaming with HLS). Don't share or store this token where an unauthorized entity could access it. The token provides access to the content of the stream. Safeguard the token with the same measures that you would use with your AWS credentials. The media that is made available through the playlist consists only of the requested stream, time range, and format. No other media data (such as frames outside the requested window or alternate bitrates) is made available. Provide the URL (containing the encrypted session token) for the HLS master playlist to a media player that supports the HLS protocol. Kinesis Video Streams makes the HLS media playlist, initialization fragment, and media fragments available through the master playlist URL. The initialization fragment contains the codec private data for the stream, and other data needed to set up the video or audio decoder and renderer. The media fragments contain H.264-encoded video frames or AAC-encoded audio samples. The media player receives the authenticated URL and requests stream metadata and media data normally. When the media player requests data, it calls the following actions: GetHLSMasterPlaylist: Retrieves an HLS master playlist, which contains a URL for the GetHLSMediaPlaylist action for each track, and additional metadata for the media player, including estimated bitrate and resolution. GetHLSMediaPlaylist: Retrieves an HLS media playlist, which contains a URL to access the MP4 initialization fragment with the GetMP4InitFragment action, and URLs to access the MP4 media fragments with the GetMP4MediaFragment actions. The HLS media playlist also contains metadata about the stream that the player needs to play it, such as whether the PlaybackMode is LIVE or ON_DEMAND. The HLS media playlist is typically static for sessions with a PlaybackType of ON_DEMAND. The HLS media playlist is continually updated with new fragments for sessions with a PlaybackType of LIVE. There is a distinct HLS media playlist for the video track and the audio track (if applicable) that contains MP4 media URLs for the specific track. GetMP4InitFragment: Retrieves the MP4 initialization fragment. The media player typically loads the initialization fragment before loading any media fragments. This fragment contains the "fytp" and "moov" MP4 atoms, and the child atoms that are needed to initialize the media player decoder. The initialization fragment does not correspond to a fragment in a Kinesis video stream. It contains only the codec private data for the stream and respective track, which the media player needs to decode the media frames. GetMP4MediaFragment: Retrieves MP4 media fragments. These fragments contain the "moof" and "mdat" MP4 atoms and their child atoms, containing the encoded fragment's media frames and their timestamps. After the first media fragment is made available in a streaming session, any fragments that don't contain the same codec private data cause an error to be returned when those different media fragments are loaded. Therefore, the codec private data should not change between fragments in a session. This also means that the session fails if the fragments in a stream change from having only video to having both audio and video. Data retrieved with this action is billable. See Pricing (https://aws.amazon.com/kinesis/video-streams/pricing/) for details. GetTSFragment: Retrieves MPEG TS fragments containing both initialization and media data for all tracks in the stream. If the ContainerFormat is MPEG_TS, this API is used instead of GetMP4InitFragment and GetMP4MediaFragment to retrieve stream media. Data retrieved with this action is billable. For more information, see Kinesis Video Streams pricing (https://aws.amazon.com/kinesis/video-streams/pricing/). A streaming session URL must not be shared between players. The service might throttle a session if multiple media players are sharing it. For connection limits, see Kinesis Video Streams Limits (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html). You can monitor the amount of data that the media player consumes by monitoring the GetMP4MediaFragment.OutgoingBytes Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see Monitoring Kinesis Video Streams (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html). For pricing information, see Amazon Kinesis Video Streams Pricing (https://aws.amazon.com/kinesis/video-streams/pricing/) and AWS Pricing (https://aws.amazon.com/pricing/). Charges for both HLS sessions and outgoing AWS data apply. For more information about HLS, see HTTP Live Streaming (https://developer.apple.com/streaming/) on the Apple Developer site (https://developer.apple.com). If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: x-amz-ErrorType HTTP header – contains a more specific error type in addition to what the HTTP status code provides. x-amz-RequestId HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id. Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again. For more information, see the Errors section at the bottom of this topic, as well as Common Errors (https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html).
#
# POST /getHLSStreamingSessionURL
# operationId: GetHLSStreamingSessionURL
# --HLSFragmentSelector shape: {FragmentSelectorType?: any, TimestampRange?: any}
export def "get-hls-streaming-session-url get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --stream-name: string # The name of the stream for which to retrieve the HLS master playlist URL. You must specify either the StreamName or the StreamARN.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream for which to retrieve the HLS master playlist URL. You must specify either the StreamName or the StreamARN.
  --playback-mode: string@playback-mode-completer # Whether to retrieve live, live replay, or archived, on-demand data. Features of the three types of sessions include the following: LIVE : For sessions of this type, the HLS media playlist is continually updated with the latest fragments as they become available. We recommend that the media player retrieve a new playlist on a one-second interval. When this type of session is played in a media player, the user interface typically displays a "live" notification, with no scrubber control for choosing the position in the playback window to display. In LIVE mode, the newest available fragments are included in an HLS media playlist, even if there is a gap between fragments (that is, if a fragment is missing). A gap like this might cause a media player to halt or cause a jump in playback. In this mode, fragments are not added to the HLS media playlist if they are older than the newest fragment in the playlist. If the missing fragment becomes available after a subsequent fragment is added to the playlist, the older fragment is not added, and the gap is not filled. LIVE_REPLAY : For sessions of this type, the HLS media playlist is updated similarly to how it is updated for LIVE mode except that it starts by including fragments from a given start time. Instead of fragments being added as they are ingested, fragments are added as the duration of the next fragment elapses. For example, if the fragments in the session are two seconds long, then a new fragment is added to the media playlist every two seconds. This mode is useful to be able to start playback from when an event is detected and continue live streaming media that has not yet been ingested as of the time of the session creation. This mode is also useful to stream previously archived media without being limited by the 1,000 fragment limit in the ON_DEMAND mode. ON_DEMAND : For sessions of this type, the HLS media playlist contains all the fragments for the session, up to the number that is specified in MaxMediaPlaylistFragmentResults. The playlist must be retrieved only once for each session. When this type of session is played in a media player, the user interface typically displays a scrubber control for choosing the position in the playback window to display. In all playback modes, if FragmentSelectorType is PRODUCER_TIMESTAMP, and if there are multiple fragments with the same start timestamp, the fragment that has the largest fragment number (that is, the newest fragment) is included in the HLS media playlist. The other fragments are not included. Fragments that have different timestamps but have overlapping durations are still included in the HLS media playlist. This can lead to unexpected behavior in the media player. The default is LIVE.
  --hls-fragment-selector: record # Contains the range of timestamps for the requested media, and the source of the timestamps. — shape: {FragmentSelectorType?: any, TimestampRange?: any}
  --container-format: string@container-format-completer # Specifies which format should be used for packaging the media. Specifying the FRAGMENTED_MP4 container format packages the media into MP4 fragments (fMP4 or CMAF). This is the recommended packaging because there is minimal packaging overhead. The other container format option is MPEG_TS. HLS has supported MPEG TS chunks since it was released and is sometimes the only supported packaging on older HLS players. MPEG TS typically has a 5-25 percent packaging overhead. This means MPEG TS typically requires 5-25 percent more bandwidth and cost than fMP4. The default is FRAGMENTED_MP4.
  --discontinuity-mode: string@discontinuity-mode-completer # Specifies when flags marking discontinuities between fragments are added to the media playlists. Media players typically build a timeline of media content to play, based on the timestamps of each fragment. This means that if there is any overlap or gap between fragments (as is typical if HLSFragmentSelector is set to SERVER_TIMESTAMP), the media player timeline will also have small gaps between fragments in some places, and will overwrite frames in other places. Gaps in the media player timeline can cause playback to stall and overlaps can cause playback to be jittery. When there are discontinuity flags between fragments, the media player is expected to reset the timeline, resulting in the next fragment being played immediately after the previous fragment. The following modes are supported: ALWAYS: a discontinuity marker is placed between every fragment in the HLS media playlist. It is recommended to use a value of ALWAYS if the fragment timestamps are not accurate. NEVER: no discontinuity markers are placed anywhere. It is recommended to use a value of NEVER to ensure the media player timeline most accurately maps to the producer timestamps. ON_DISCONTINUITY: a discontinuity marker is placed between fragments that have a gap or overlap of more than 50 milliseconds. For most playback scenarios, it is recommended to use a value of ON_DISCONTINUITY so that the media player timeline is only reset when there is a significant issue with the media timeline (e.g. a missing fragment). The default is ALWAYS when HLSFragmentSelector is set to SERVER_TIMESTAMP, and NEVER when it is set to PRODUCER_TIMESTAMP.
  --display-fragment-timestamp: string@display-fragment-timestamp-completer # Specifies when the fragment start timestamps should be included in the HLS media playlist. Typically, media players report the playhead position as a time relative to the start of the first fragment in the playback session. However, when the start timestamps are included in the HLS media playlist, some media players might report the current playhead as an absolute time based on the fragment timestamps. This can be useful for creating a playback experience that shows viewers the wall-clock time of the media. The default is NEVER. When HLSFragmentSelector is SERVER_TIMESTAMP, the timestamps will be the server start timestamps. Similarly, when HLSFragmentSelector is PRODUCER_TIMESTAMP, the timestamps will be the producer start timestamps.
  --expires: int # The time in seconds until the requested session expires. This value can be between 300 (5 minutes) and 43200 (12 hours). When a session expires, no new calls to GetHLSMasterPlaylist, GetHLSMediaPlaylist, GetMP4InitFragment, GetMP4MediaFragment, or GetTSFragment can be made for that session. The default is 300 (5 minutes).
  --max-media-playlist-fragment-results: int # The maximum number of fragments that are returned in the HLS media playlists. When the PlaybackMode is LIVE, the most recent fragments are returned up to this value. When the PlaybackMode is ON_DEMAND, the oldest fragments are returned, up to this maximum number. When there are a higher number of fragments available in a live HLS media playlist, video players often buffer content before starting playback. Increasing the buffer size increases the playback latency, but it decreases the likelihood that rebuffering will occur during playback. We recommend that a live HLS media playlist have a minimum of 3 fragments and a maximum of 10 fragments. The default is 5 fragments if PlaybackMode is LIVE or LIVE_REPLAY, and 1,000 if PlaybackMode is ON_DEMAND. The maximum value of 5,000 fragments corresponds to more than 80 minutes of video on streams with 1-second fragments, and more than 13 hours of video on streams with 10-second fragments.
]: any -> record<HLSStreamingSessionURL: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getHLSStreamingSessionURL" $auth.query)
  let req_body = {"StreamName": $stream_name, "StreamARN": $stream_arn, "PlaybackMode": $playback_mode, "HLSFragmentSelector": $hls_fragment_selector, "ContainerFormat": $container_format, "DiscontinuityMode": $discontinuity_mode, "DisplayFragmentTimestamp": $display_fragment_timestamp, "Expires": $expires, "MaxMediaPlaylistFragmentResults": $max_media_playlist_fragment_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a list of Images corresponding to each timestamp for a given time range, sampling interval, and image format configuration.
#
# POST /getImages
# operationId: GetImages
export def "get-images get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --stream-name: string # The name of the stream from which to retrieve the images. You must specify either the StreamName or the StreamARN.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream from which to retrieve the images. You must specify either the StreamName or the StreamARN.
  image_selector_type: string@image-selector-type-completer # The origin of the Server or Producer timestamps to use to generate the images.
  start_timestamp: string # The starting point from which the images should be generated. This StartTimestamp must be within an inclusive range of timestamps for an image to be returned. (format: date-time)
  end_timestamp: string # The end timestamp for the range of images to be generated. (format: date-time)
  sampling_interval: int # The time interval in milliseconds (ms) at which the images need to be generated from the stream. The minimum value that can be provided is 3000 ms. If the timestamp range is less than the sampling interval, the Image from the startTimestamp will be returned if available. The minimum value of 3000 ms is a soft limit. If needed, a lower sampling frequency can be requested.
  format: string@format-completer # The format that will be used to encode the image.
  --format-config: record # The list of a key-value pair structure that contains extra parameters that can be applied when the image is generated. The FormatConfig key is the JPEGQuality, which indicates the JPEG quality key to be used to generate the image. The FormatConfig value accepts ints from 1 to 100. If the value is 1, the image will be generated with less quality and the best compression. If the value is 100, the image will be generated with the best quality and less compression. If no value is provided, the default value of the JPEGQuality key will be set to 80.
  --width-pixels: int # The width of the output image that is used in conjunction with the HeightPixels parameter. When both WidthPixels and HeightPixels parameters are provided, the image will be stretched to fit the specified aspect ratio. If only the WidthPixels parameter is provided or if only the HeightPixels is provided, a ValidationException will be thrown. If neither parameter is provided, the original image size from the stream will be returned.
  --height-pixels: int # The height of the output image that is used in conjunction with the WidthPixels parameter. When both HeightPixels and WidthPixels parameters are provided, the image will be stretched to fit the specified aspect ratio. If only the HeightPixels parameter is provided, its original aspect ratio will be used to calculate the WidthPixels ratio. If neither parameter is provided, the original image size will be returned.
  --max-results-body: int # The maximum number of images to be returned by the API. The default limit is 100 images per API response. The additional results will be paginated. (body field)
  --next-token-body: string # A token that specifies where to start paginating the next set of Images. This is the GetImages:NextToken from a previously truncated response. (body field)
]: any -> record<Images: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getImages" $qp $auth.query)
  let req_body = {"StreamName": $stream_name, "StreamARN": $stream_arn, "ImageSelectorType": $image_selector_type, "StartTimestamp": $start_timestamp, "EndTimestamp": $end_timestamp, "SamplingInterval": $sampling_interval, "Format": $format, "FormatConfig": $format_config, "WidthPixels": $width_pixels, "HeightPixels": $height_pixels, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets media for a list of fragments (specified by fragment number) from the archived data in an Amazon Kinesis video stream. You must first call the GetDataEndpoint API to get an endpoint. Then send the GetMediaForFragmentList requests to this endpoint using the --endpoint-url parameter (https://docs.aws.amazon.com/cli/latest/reference/). For limits, see Kinesis Video Streams Limits (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html). If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: x-amz-ErrorType HTTP header – contains a more specific error type in addition to what the HTTP status code provides. x-amz-RequestId HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id. Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again. For more information, see the Errors section at the bottom of this topic, as well as Common Errors (https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html).
#
# POST /getMediaForFragmentList
# operationId: GetMediaForFragmentList
export def "get-media-for-fragment-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --stream-name: string # The name of the stream from which to retrieve fragment media. Specify either this parameter or the StreamARN parameter.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream from which to retrieve fragment media. Specify either this parameter or the StreamName parameter.
  fragments: list<string> # A list of the numbers of fragments for which to retrieve media. You retrieve these values with ListFragments.
]: any -> record<Payload: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getMediaForFragmentList" $auth.query)
  let req_body = {"StreamName": $stream_name, "StreamARN": $stream_arn, "Fragments": $fragments} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of Fragment objects from the specified stream and timestamp range within the archived data. Listing fragments is eventually consistent. This means that even if the producer receives an acknowledgment that a fragment is persisted, the result might not be returned immediately from a request to ListFragments. However, results are typically available in less than one second. You must first call the GetDataEndpoint API to get an endpoint. Then send the ListFragments requests to this endpoint using the --endpoint-url parameter (https://docs.aws.amazon.com/cli/latest/reference/). If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: x-amz-ErrorType HTTP header – contains a more specific error type in addition to what the HTTP status code provides. x-amz-RequestId HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id. Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again. For more information, see the Errors section at the bottom of this topic, as well as Common Errors (https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html).
#
# POST /listFragments
# operationId: ListFragments
# --FragmentSelector shape: {FragmentSelectorType?: any, TimestampRange?: any}
export def "list-fragments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --stream-name: string # The name of the stream from which to retrieve a fragment list. Specify either this parameter or the StreamARN parameter.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream from which to retrieve a fragment list. Specify either this parameter or the StreamName parameter.
  --max-results-body: int # The total number of fragments to return. If the total number of fragments available is more than the value specified in max-results, then a ListFragmentsOutput$NextToken is provided in the output that you can use to resume pagination. (body field)
  --next-token-body: string # A token to specify where to start paginating. This is the ListFragmentsOutput$NextToken from a previously truncated response. (body field)
  --fragment-selector: record # Describes the timestamp range and timestamp origin of a range of fragments. Only fragments with a start timestamp greater than or equal to the given start time and less than or equal to the end time are returned. For example, if a stream contains fragments with the following start timestamps: 00:00:00 00:00:02 00:00:04 00:00:06 A fragment selector range with a start time of 00:00:01 and end time of 00:00:04 would return the fragments with start times of 00:00:02 and 00:00:04. — shape: {FragmentSelectorType?: any, TimestampRange?: any}
]: any -> record<Fragments: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listFragments" $qp $auth.query)
  let req_body = {"StreamName": $stream_name, "StreamARN": $stream_arn, "MaxResults": $max_results_body, "NextToken": $next_token_body, "FragmentSelector": $fragment_selector} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
