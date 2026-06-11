# Auto-generated client for AWS Elemental MediaPackage v2017-10-12
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mediapackage/2017-10-12/openapi.json
# Auth: --token flag or $env.AWS_ELEMENTAL_MEDIAPACKAGE_TOKEN

const BASE_URL = "http://mediapackage.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_ELEMENTAL_MEDIAPACKAGE_TOKEN | default "" }
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
def base-url-completer [] { ["http://mediapackage.us-east-1.amazonaws.com" "http://mediapackage.us-east-2.amazonaws.com" "http://mediapackage.us-west-1.amazonaws.com" "http://mediapackage.us-west-2.amazonaws.com" "http://mediapackage.us-gov-west-1.amazonaws.com" "http://mediapackage.us-gov-east-1.amazonaws.com" "http://mediapackage.ca-central-1.amazonaws.com" "http://mediapackage.eu-north-1.amazonaws.com" "http://mediapackage.eu-west-1.amazonaws.com" "http://mediapackage.eu-west-2.amazonaws.com" "http://mediapackage.eu-west-3.amazonaws.com" "http://mediapackage.eu-central-1.amazonaws.com" "http://mediapackage.eu-south-1.amazonaws.com" "http://mediapackage.af-south-1.amazonaws.com" "http://mediapackage.ap-northeast-1.amazonaws.com" "http://mediapackage.ap-northeast-2.amazonaws.com" "http://mediapackage.ap-northeast-3.amazonaws.com" "http://mediapackage.ap-southeast-1.amazonaws.com" "http://mediapackage.ap-southeast-2.amazonaws.com" "http://mediapackage.ap-east-1.amazonaws.com" "http://mediapackage.ap-south-1.amazonaws.com" "http://mediapackage.sa-east-1.amazonaws.com" "http://mediapackage.me-south-1.amazonaws.com" "https://mediapackage.us-east-1.amazonaws.com" "https://mediapackage.us-east-2.amazonaws.com" "https://mediapackage.us-west-1.amazonaws.com" "https://mediapackage.us-west-2.amazonaws.com" "https://mediapackage.us-gov-west-1.amazonaws.com" "https://mediapackage.us-gov-east-1.amazonaws.com" "https://mediapackage.ca-central-1.amazonaws.com" "https://mediapackage.eu-north-1.amazonaws.com" "https://mediapackage.eu-west-1.amazonaws.com" "https://mediapackage.eu-west-2.amazonaws.com" "https://mediapackage.eu-west-3.amazonaws.com" "https://mediapackage.eu-central-1.amazonaws.com" "https://mediapackage.eu-south-1.amazonaws.com" "https://mediapackage.af-south-1.amazonaws.com" "https://mediapackage.ap-northeast-1.amazonaws.com" "https://mediapackage.ap-northeast-2.amazonaws.com" "https://mediapackage.ap-northeast-3.amazonaws.com" "https://mediapackage.ap-southeast-1.amazonaws.com" "https://mediapackage.ap-southeast-2.amazonaws.com" "https://mediapackage.ap-east-1.amazonaws.com" "https://mediapackage.ap-south-1.amazonaws.com" "https://mediapackage.sa-east-1.amazonaws.com" "https://mediapackage.me-south-1.amazonaws.com" "http://mediapackage.cn-north-1.amazonaws.com.cn" "http://mediapackage.cn-northwest-1.amazonaws.com.cn" "https://mediapackage.cn-north-1.amazonaws.com.cn" "https://mediapackage.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def origination-completer [] { ["ALLOW" "DENY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "channels-configure-logs ConfigureLogs" } } | get name | first)
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

# Changes the Channel's properities to configure log subscription
#
# PUT /channels/{id}/configure_logs
# operationId: ConfigureLogs
# --egressAccessLogs shape: {LogGroupName?: any}
# --ingressAccessLogs shape: {LogGroupName?: any}
export def "channels-configure-logs ConfigureLogs" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --egressAccessLogs: record # Configure egress access logging. — shape: {LogGroupName?: any}
  --ingressAccessLogs: record # Configure ingress access logging. — shape: {LogGroupName?: any}
]: any -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($id)/configure_logs")
  let body = {egressAccessLogs: $egressAccessLogs, ingressAccessLogs: $ingressAccessLogs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new Channel.
#
# POST /channels
# operationId: CreateChannel
export def "channels CreateChannel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --description: string # A short text description of the Channel.
  id: string # The ID of the Channel. The ID must be unique within the region and it cannot be changed after a Channel is created.
  --tags: record # A collection of tags associated with a resource
]: any -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels")
  let body = {description: $description, id: $id, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a collection of Channels.
#
# GET /channels
# operationId: ListChannels
export def "channels ListChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int # Upper bound on number of records to return.
  --nextToken: string # A token used to resume pagination from the end of a previous request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Channels: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new HarvestJob record.
#
# POST /harvest_jobs
# operationId: CreateHarvestJob
# --s3Destination shape: {BucketName?: any, ManifestKey?: any, RoleArn?: any}
export def "harvest-jobs CreateHarvestJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  endTime: string # The end of the time-window which will be harvested
  id: string # The ID of the HarvestJob. The ID must be unique within the region and it cannot be changed after the HarvestJob is submitted
  originEndpointId: string # The ID of the OriginEndpoint that the HarvestJob will harvest from. This cannot be changed after the HarvestJob is submitted.
  s3Destination: record # Configuration parameters for where in an S3 bucket to place the harvested content — shape: {BucketName?: any, ManifestKey?: any, RoleArn?: any}
  startTime: string # The start of the time-window which will be harvested
]: any -> record<Arn: record, ChannelId: record, CreatedAt: record, EndTime: record, Id: record, OriginEndpointId: record, S3Destination: record<BucketName: record, ManifestKey: record, RoleArn: record>, StartTime: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/harvest_jobs")
  let body = {endTime: $endTime, id: $id, originEndpointId: $originEndpointId, s3Destination: $s3Destination, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a collection of HarvestJob records.
#
# GET /harvest_jobs
# operationId: ListHarvestJobs
export def "harvest-jobs ListHarvestJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeChannelId: string # When specified, the request will return only HarvestJobs associated with the given Channel ID.
  --includeStatus: string # When specified, the request will return only HarvestJobs in the given status.
  --maxResults: int # The upper bound on the number of records to return.
  --nextToken: string # A token used to resume pagination from the end of a previous request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<HarvestJobs: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeChannelId" $includeChannelId "scalar") (serialize-qp "includeStatus" $includeStatus "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/harvest_jobs" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new OriginEndpoint record.
#
# POST /origin_endpoints
# operationId: CreateOriginEndpoint
# --authorization shape: {CdnIdentifierSecret?: any, SecretsRoleArn?: any}
# --cmafPackage shape: {Encryption?: any, HlsManifests?: any, SegmentDurationSeconds?: any, SegmentPrefix?: any, StreamSelection?: any}
# --dashPackage shape: {AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeIframeOnlyStream?: any, ManifestLayout?: any, ManifestWindowSeconds?: any, MinBufferTimeSeconds?: any, MinUpdatePeriodSeconds?: any, PeriodTriggers?: any, Profile?: any, SegmentDurationSeconds?: any, SegmentTemplateFormat?: any, StreamSelection?: any, SuggestedPresentationDelaySeconds?: any, UtcTiming?: any, UtcTimingUri?: any}
# --hlsPackage shape: {AdMarkers?: any, AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeDvbSubtitles?: any, IncludeIframeOnlyStream?: any, PlaylistType?: any, PlaylistWindowSeconds?: any, ProgramDateTimeIntervalSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any, UseAudioRenditionGroup?: any}
# --mssPackage shape: {Encryption?: any, ManifestWindowSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any}
export def "origin-endpoints CreateOriginEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --authorization: record # CDN Authorization credentials — shape: {CdnIdentifierSecret?: any, SecretsRoleArn?: any}
  channelId: string # The ID of the Channel that the OriginEndpoint will be associated with. This cannot be changed after the OriginEndpoint is created.
  --cmafPackage: record # A Common Media Application Format (CMAF) packaging configuration. — shape: {Encryption?: any, HlsManifests?: any, SegmentDurationSeconds?: any, SegmentPrefix?: any, StreamSelection?: any}
  --dashPackage: record # A Dynamic Adaptive Streaming over HTTP (DASH) packaging configuration. — shape: {AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeIframeOnlyStream?: any, ManifestLayout?: any, ManifestWindowSeconds?: any, MinBufferTimeSeconds?: any, MinUpdatePeriodSeconds?: any, PeriodTriggers?: any, Profile?: any, SegmentDurationSeconds?: any, SegmentTemplateFormat?: any, StreamSelection?: any, SuggestedPresentationDelaySeconds?: any, UtcTiming?: any, UtcTimingUri?: any}
  --description: string # A short text description of the OriginEndpoint.
  --hlsPackage: record # An HTTP Live Streaming (HLS) packaging configuration. — shape: {AdMarkers?: any, AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeDvbSubtitles?: any, IncludeIframeOnlyStream?: any, PlaylistType?: any, PlaylistWindowSeconds?: any, ProgramDateTimeIntervalSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any, UseAudioRenditionGroup?: any}
  id: string # The ID of the OriginEndpoint.  The ID must be unique within the region and it cannot be changed after the OriginEndpoint is created.
  --manifestName: string # A short string that will be used as the filename of the OriginEndpoint URL (defaults to "index").
  --mssPackage: record # A Microsoft Smooth Streaming (MSS) packaging configuration. — shape: {Encryption?: any, ManifestWindowSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any}
  --origination: string@origination-completer # Control whether origination of video is allowed for this OriginEndpoint. If set to ALLOW, the OriginEndpoint may by requested, pursuant to any other form of access control. If set to DENY, the OriginEndpoint may not be requested. This can be helpful for Live to VOD harvesting, or for temporarily disabling origination
  --startoverWindowSeconds: int # Maximum duration (seconds) of content to retain for startover playback. If not specified, startover playback will be disabled for the OriginEndpoint.
  --tags: record # A collection of tags associated with a resource
  --timeDelaySeconds: int # Amount of delay (seconds) to enforce on the playback of live content. If not specified, there will be no time delay in effect for the OriginEndpoint.
  --whitelist: list # A list of source IP CIDR blocks that will be allowed to access the OriginEndpoint.
]: any -> record<Arn: record, Authorization: record<CdnIdentifierSecret: record, SecretsRoleArn: record>, ChannelId: record, CmafPackage: record<Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, HlsManifests: record, SegmentDurationSeconds: record, SegmentPrefix: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, CreatedAt: record, DashPackage: record<AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, IncludeIframeOnlyStream: record, ManifestLayout: record, ManifestWindowSeconds: record, MinBufferTimeSeconds: record, MinUpdatePeriodSeconds: record, PeriodTriggers: record, Profile: record, SegmentDurationSeconds: record, SegmentTemplateFormat: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, SuggestedPresentationDelaySeconds: record, UtcTiming: record, UtcTimingUri: record>, Description: record, HlsPackage: record<AdMarkers: record, AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, RepeatExtXKey: record, SpekeKeyProvider: record>, IncludeDvbSubtitles: record, IncludeIframeOnlyStream: record, PlaylistType: record, PlaylistWindowSeconds: record, ProgramDateTimeIntervalSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, UseAudioRenditionGroup: record>, Id: record, ManifestName: record, MssPackage: record<Encryption: record<SpekeKeyProvider: record>, ManifestWindowSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, Origination: record, StartoverWindowSeconds: record, Tags: record, TimeDelaySeconds: record, Url: record, Whitelist: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/origin_endpoints")
  let body = {authorization: $authorization, channelId: $channelId, cmafPackage: $cmafPackage, dashPackage: $dashPackage, description: $description, hlsPackage: $hlsPackage, id: $id, manifestName: $manifestName, mssPackage: $mssPackage, origination: $origination, startoverWindowSeconds: $startoverWindowSeconds, tags: $tags, timeDelaySeconds: $timeDelaySeconds, whitelist: $whitelist} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a collection of OriginEndpoint records.
#
# GET /origin_endpoints
# operationId: ListOriginEndpoints
export def "origin-endpoints ListOriginEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channelId: string # When specified, the request will return only OriginEndpoints associated with the given Channel ID.
  --maxResults: int # The upper bound on the number of records to return.
  --nextToken: string # A token used to resume pagination from the end of a previous request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, OriginEndpoints: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channelId" $channelId "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/origin_endpoints" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an existing Channel.
#
# DELETE /channels/{id}
# operationId: DeleteChannel
export def "channels DeleteChannel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets details about a Channel.
#
# GET /channels/{id}
# operationId: DescribeChannel
export def "channels DescribeChannel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing Channel.
#
# PUT /channels/{id}
# operationId: UpdateChannel
export def "channels UpdateChannel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --description: string # A short text description of the Channel.
]: any -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($id)")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes an existing OriginEndpoint.
#
# DELETE /origin_endpoints/{id}
# operationId: DeleteOriginEndpoint
export def "origin-endpoints DeleteOriginEndpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/origin_endpoints/($id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets details about an existing OriginEndpoint.
#
# GET /origin_endpoints/{id}
# operationId: DescribeOriginEndpoint
export def "origin-endpoints DescribeOriginEndpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, Authorization: record<CdnIdentifierSecret: record, SecretsRoleArn: record>, ChannelId: record, CmafPackage: record<Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, HlsManifests: record, SegmentDurationSeconds: record, SegmentPrefix: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, CreatedAt: record, DashPackage: record<AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, IncludeIframeOnlyStream: record, ManifestLayout: record, ManifestWindowSeconds: record, MinBufferTimeSeconds: record, MinUpdatePeriodSeconds: record, PeriodTriggers: record, Profile: record, SegmentDurationSeconds: record, SegmentTemplateFormat: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, SuggestedPresentationDelaySeconds: record, UtcTiming: record, UtcTimingUri: record>, Description: record, HlsPackage: record<AdMarkers: record, AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, RepeatExtXKey: record, SpekeKeyProvider: record>, IncludeDvbSubtitles: record, IncludeIframeOnlyStream: record, PlaylistType: record, PlaylistWindowSeconds: record, ProgramDateTimeIntervalSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, UseAudioRenditionGroup: record>, Id: record, ManifestName: record, MssPackage: record<Encryption: record<SpekeKeyProvider: record>, ManifestWindowSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, Origination: record, StartoverWindowSeconds: record, Tags: record, TimeDelaySeconds: record, Url: record, Whitelist: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/origin_endpoints/($id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing OriginEndpoint.
#
# PUT /origin_endpoints/{id}
# operationId: UpdateOriginEndpoint
# --authorization shape: {CdnIdentifierSecret?: any, SecretsRoleArn?: any}
# --cmafPackage shape: {Encryption?: any, HlsManifests?: any, SegmentDurationSeconds?: any, SegmentPrefix?: any, StreamSelection?: any}
# --dashPackage shape: {AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeIframeOnlyStream?: any, ManifestLayout?: any, ManifestWindowSeconds?: any, MinBufferTimeSeconds?: any, MinUpdatePeriodSeconds?: any, PeriodTriggers?: any, Profile?: any, SegmentDurationSeconds?: any, SegmentTemplateFormat?: any, StreamSelection?: any, SuggestedPresentationDelaySeconds?: any, UtcTiming?: any, UtcTimingUri?: any}
# --hlsPackage shape: {AdMarkers?: any, AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeDvbSubtitles?: any, IncludeIframeOnlyStream?: any, PlaylistType?: any, PlaylistWindowSeconds?: any, ProgramDateTimeIntervalSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any, UseAudioRenditionGroup?: any}
# --mssPackage shape: {Encryption?: any, ManifestWindowSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any}
export def "origin-endpoints UpdateOriginEndpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --authorization: record # CDN Authorization credentials — shape: {CdnIdentifierSecret?: any, SecretsRoleArn?: any}
  --cmafPackage: record # A Common Media Application Format (CMAF) packaging configuration. — shape: {Encryption?: any, HlsManifests?: any, SegmentDurationSeconds?: any, SegmentPrefix?: any, StreamSelection?: any}
  --dashPackage: record # A Dynamic Adaptive Streaming over HTTP (DASH) packaging configuration. — shape: {AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeIframeOnlyStream?: any, ManifestLayout?: any, ManifestWindowSeconds?: any, MinBufferTimeSeconds?: any, MinUpdatePeriodSeconds?: any, PeriodTriggers?: any, Profile?: any, SegmentDurationSeconds?: any, SegmentTemplateFormat?: any, StreamSelection?: any, SuggestedPresentationDelaySeconds?: any, UtcTiming?: any, UtcTimingUri?: any}
  --description: string # A short text description of the OriginEndpoint.
  --hlsPackage: record # An HTTP Live Streaming (HLS) packaging configuration. — shape: {AdMarkers?: any, AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeDvbSubtitles?: any, IncludeIframeOnlyStream?: any, PlaylistType?: any, PlaylistWindowSeconds?: any, ProgramDateTimeIntervalSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any, UseAudioRenditionGroup?: any}
  --manifestName: string # A short string that will be appended to the end of the Endpoint URL.
  --mssPackage: record # A Microsoft Smooth Streaming (MSS) packaging configuration. — shape: {Encryption?: any, ManifestWindowSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any}
  --origination: string@origination-completer # Control whether origination of video is allowed for this OriginEndpoint. If set to ALLOW, the OriginEndpoint may by requested, pursuant to any other form of access control. If set to DENY, the OriginEndpoint may not be requested. This can be helpful for Live to VOD harvesting, or for temporarily disabling origination
  --startoverWindowSeconds: int # Maximum duration (in seconds) of content to retain for startover playback. If not specified, startover playback will be disabled for the OriginEndpoint.
  --timeDelaySeconds: int # Amount of delay (in seconds) to enforce on the playback of live content. If not specified, there will be no time delay in effect for the OriginEndpoint.
  --whitelist: list # A list of source IP CIDR blocks that will be allowed to access the OriginEndpoint.
]: any -> record<Arn: record, Authorization: record<CdnIdentifierSecret: record, SecretsRoleArn: record>, ChannelId: record, CmafPackage: record<Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, HlsManifests: record, SegmentDurationSeconds: record, SegmentPrefix: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, CreatedAt: record, DashPackage: record<AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, IncludeIframeOnlyStream: record, ManifestLayout: record, ManifestWindowSeconds: record, MinBufferTimeSeconds: record, MinUpdatePeriodSeconds: record, PeriodTriggers: record, Profile: record, SegmentDurationSeconds: record, SegmentTemplateFormat: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, SuggestedPresentationDelaySeconds: record, UtcTiming: record, UtcTimingUri: record>, Description: record, HlsPackage: record<AdMarkers: record, AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, RepeatExtXKey: record, SpekeKeyProvider: record>, IncludeDvbSubtitles: record, IncludeIframeOnlyStream: record, PlaylistType: record, PlaylistWindowSeconds: record, ProgramDateTimeIntervalSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, UseAudioRenditionGroup: record>, Id: record, ManifestName: record, MssPackage: record<Encryption: record<SpekeKeyProvider: record>, ManifestWindowSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, Origination: record, StartoverWindowSeconds: record, Tags: record, TimeDelaySeconds: record, Url: record, Whitelist: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/origin_endpoints/($id)")
  let body = {authorization: $authorization, cmafPackage: $cmafPackage, dashPackage: $dashPackage, description: $description, hlsPackage: $hlsPackage, manifestName: $manifestName, mssPackage: $mssPackage, origination: $origination, startoverWindowSeconds: $startoverWindowSeconds, timeDelaySeconds: $timeDelaySeconds, whitelist: $whitelist} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets details about an existing HarvestJob.
#
# GET /harvest_jobs/{id}
# operationId: DescribeHarvestJob
export def "harvest-jobs DescribeHarvestJob" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, ChannelId: record, CreatedAt: record, EndTime: record, Id: record, OriginEndpointId: record, S3Destination: record<BucketName: record, ManifestKey: record, RoleArn: record>, StartTime: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/harvest_jobs/($id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /tags/{resource-arn}
#
# operationId: ListTagsForResource
export def "tags ListTagsForResource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($resource_arn)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /tags/{resource-arn}
#
# operationId: TagResource
export def "tags TagResource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  tags: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($resource_arn)")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
#
# PUT /channels/{id}/credentials
# DEPRECATED
# operationId: RotateChannelCredentials
@deprecated
export def "channels-credentials RotateChannelCredentials" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($id)/credentials")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
#
# PUT /channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials
# operationId: RotateIngestEndpointCredentials
export def "channels-ingest-endpoints-credentials RotateIngestEndpointCredentials" [
  id: string
  ingest_endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($id)/ingest_endpoints/($ingest_endpoint_id)/credentials")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /tags/{resource-arn}#tagKeys
#
# operationId: UntagResource
export def "tags UntagResource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tagKeys: list # The key(s) of tag to be deleted
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagKeys" $tagKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($resource_arn)#tagKeys" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
