# Auto-generated client for Drive API vv3
# Source: https://api.apis.guru/v2/specs/googleapis.com/drive/v3/openapi.yaml
# Auth: --token flag or $env.DRIVE_API_TOKEN

const BASE_URL = "https://www.googleapis.com/drive/v3"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DRIVE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.googleapis.com/drive/v3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def corpus-completer [] { ["domain" "user"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "about driveaboutget" } } | get name | first)
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

# Gets information about the user, the user's Drive, and system capabilities.
#
# GET /about
# operationId: drive.about.get
export def "about driveaboutget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<appInstalled: bool, canCreateDrives: bool, canCreateTeamDrives: bool, driveThemes: table<backgroundImageLink: string, colorRgb: string, id: string>, exportFormats: record, folderColorPalette: list<string>, importFormats: record, kind: string, maxImportSizes: record, maxUploadSize: string, storageQuota: record<limit: string, usage: string, usageInDrive: string, usageInDriveTrash: string>, teamDriveThemes: table<backgroundImageLink: string, colorRgb: string, id: string>, user: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/about" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the changes for a user or shared drive.
#
# GET /changes
# operationId: drive.changes.list
export def "changes drivechangeslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --pageToken: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response or to the response from the getStartPageToken method.
  --driveId: string # The shared drive from which changes are returned. If specified the change IDs will be reflective of the shared drive; use the combined drive ID and change ID as an identifier.
  --includeCorpusRemovals: oneof<nothing, bool> # Whether changes should include the file resource if the file is still accessible by the user at the time of the request, even when a file was removed from the list of changes and there will be no further change entries for this file.
  --includeItemsFromAllDrives: oneof<nothing, bool> # Whether both My Drive and shared drive items should be included in results.
  --includeLabels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --includePermissionsForView: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --includeRemoved: oneof<nothing, bool> # Whether to include changes indicating that items have been removed from the list of changes, for example by deletion or loss of access.
  --includeTeamDriveItems: oneof<nothing, bool> # Deprecated use includeItemsFromAllDrives instead.
  --pageSize: int # The maximum number of changes to return per page.
  --restrictToMyDrive: oneof<nothing, bool> # Whether to restrict the results to changes inside the My Drive hierarchy. This omits changes to files such as those in the Application Data folder or shared files which have not been added to My Drive.
  --spaces: string # A comma-separated list of spaces to query within the corpora. Supported values are 'drive' and 'appDataFolder'.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --teamDriveId: string # Deprecated use driveId instead.
]: nothing -> record<changes: table<changeType: string, drive: record, driveId: string, file: record, fileId: string, kind: string, removed: bool, teamDrive: record, teamDriveId: string, time: string, type: string>, kind: string, newStartPageToken: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "driveId" $driveId "scalar") (serialize-qp "includeCorpusRemovals" $includeCorpusRemovals "scalar") (serialize-qp "includeItemsFromAllDrives" $includeItemsFromAllDrives "scalar") (serialize-qp "includeLabels" $includeLabels "scalar") (serialize-qp "includePermissionsForView" $includePermissionsForView "scalar") (serialize-qp "includeRemoved" $includeRemoved "scalar") (serialize-qp "includeTeamDriveItems" $includeTeamDriveItems "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "restrictToMyDrive" $restrictToMyDrive "scalar") (serialize-qp "spaces" $spaces "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar") (serialize-qp "teamDriveId" $teamDriveId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/changes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the starting pageToken for listing future changes.
#
# GET /changes/startPageToken
# operationId: drive.changes.getStartPageToken
export def "changes-start-page-token drivechangesgetStartPageToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --driveId: string # The ID of the shared drive for which the starting pageToken for listing future changes from that shared drive is returned.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --teamDriveId: string # Deprecated use driveId instead.
]: nothing -> record<kind: string, startPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "driveId" $driveId "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar") (serialize-qp "teamDriveId" $teamDriveId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/changes/startPageToken" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribes to changes for a user. To use this method, you must include the pageToken query parameter.
#
# POST /changes/watch
# operationId: drive.changes.watch
export def "changes-watch drivechangeswatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --pageToken: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response or to the response from the getStartPageToken method.
  --driveId: string # The shared drive from which changes are returned. If specified the change IDs will be reflective of the shared drive; use the combined drive ID and change ID as an identifier.
  --includeCorpusRemovals: oneof<nothing, bool> # Whether changes should include the file resource if the file is still accessible by the user at the time of the request, even when a file was removed from the list of changes and there will be no further change entries for this file.
  --includeItemsFromAllDrives: oneof<nothing, bool> # Whether both My Drive and shared drive items should be included in results.
  --includeLabels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --includePermissionsForView: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --includeRemoved: oneof<nothing, bool> # Whether to include changes indicating that items have been removed from the list of changes, for example by deletion or loss of access.
  --includeTeamDriveItems: oneof<nothing, bool> # Deprecated use includeItemsFromAllDrives instead.
  --pageSize: int # The maximum number of changes to return per page.
  --restrictToMyDrive: oneof<nothing, bool> # Whether to restrict the results to changes inside the My Drive hierarchy. This omits changes to files such as those in the Application Data folder or shared files which have not been added to My Drive.
  --spaces: string # A comma-separated list of spaces to query within the corpora. Supported values are 'drive' and 'appDataFolder'.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --teamDriveId: string # Deprecated use driveId instead.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resourceId: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resourceUri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "driveId" $driveId "scalar") (serialize-qp "includeCorpusRemovals" $includeCorpusRemovals "scalar") (serialize-qp "includeItemsFromAllDrives" $includeItemsFromAllDrives "scalar") (serialize-qp "includeLabels" $includeLabels "scalar") (serialize-qp "includePermissionsForView" $includePermissionsForView "scalar") (serialize-qp "includeRemoved" $includeRemoved "scalar") (serialize-qp "includeTeamDriveItems" $includeTeamDriveItems "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "restrictToMyDrive" $restrictToMyDrive "scalar") (serialize-qp "spaces" $spaces "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar") (serialize-qp "teamDriveId" $teamDriveId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/changes/watch" $qp)
  let body = {address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resourceId: $resourceId, resourceUri: $resourceUri, token: $body_token, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stop watching resources through this channel
#
# POST /channels/stop
# operationId: drive.channels.stop
export def "channels-stop drivechannelsstop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resourceId: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resourceUri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels/stop" $qp)
  let body = {address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resourceId: $resourceId, resourceUri: $resourceUri, token: $body_token, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the user's shared drives.
#
# GET /drives
# operationId: drive.drives.list
export def "drives drivedriveslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --pageSize: int # Maximum number of shared drives to return per page.
  --pageToken: string # Page token for shared drives.
  --q: string # Query string for searching shared drives.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then all shared drives of the domain in which the requester is an administrator are returned.
]: nothing -> record<drives: table<backgroundImageFile: record, backgroundImageLink: string, capabilities: record, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record, themeId: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/drives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a shared drive.
#
# POST /drives
# operationId: drive.drives.create
# --backgroundImageFile shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
# --capabilities shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeDriveBackground?: bool, canChangeDriveMembersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRename?: bool, canRenameDrive?: bool, canResetDriveRestrictions?: bool, canShare?: bool, canTrashChildren?: bool}
# --restrictions shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, driveMembersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool}
export def "drives drivedrivescreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --requestId: string # An ID, such as a random UUID, which uniquely identifies this user's request for idempotent creation of a shared drive. A repeated request by the same user and with the same request ID will avoid creating duplicates by attempting to create the same shared drive. If the shared drive already exists a 409 error will be returned.
  --backgroundImageFile: record # An image file and cropping parameters from which a background image for this shared drive is set. This is a write-only field; it can only be set on drive.drives.update requests that don't set themeId. When specified, all fields of the backgroundImageFile must be set. — shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
  --backgroundImageLink: string # A short-lived link to this shared drive's background image.
  --capabilities: record # Capabilities the current user has on this shared drive. — shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeDriveBackground?: bool, canChangeDriveMembersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRename?: bool, canRenameDrive?: bool, canResetDriveRestrictions?: bool, canShare?: bool, canTrashChildren?: bool}
  --colorRgb: string # The color of this shared drive as an RGB hex string. It can only be set on drive.drives.update requests that don't set themeId.
  --createdTime: string # The time at which the shared drive was created (RFC 3339 date-time). (format: date-time)
  --hidden: oneof<nothing, bool> # Whether the shared drive is hidden from default view.
  --id: string # The ID of this shared drive which is also the ID of the top level folder of this shared drive.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#drive". (default: drive#drive)
  --name: string # The name of this shared drive.
  --orgUnitId: string # The organizational unit of this shared drive. This field is only populated on drives.list responses when the useDomainAdminAccess parameter is set to true.
  --restrictions: record # A set of restrictions that apply to this shared drive or items inside this shared drive. — shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, driveMembersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool}
  --themeId: string # The ID of the theme from which the background image and color are set. The set of possible driveThemes can be retrieved from a drive.about.get response. When not specified on a drive.drives.create request, a random theme is chosen from which the background image and color are set. This is a write-only field; it can only be set on requests that don't set colorRgb or backgroundImageFile.
]: any -> record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "requestId" $requestId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/drives" $qp)
  let body = {backgroundImageFile: $backgroundImageFile, backgroundImageLink: $backgroundImageLink, capabilities: $capabilities, colorRgb: $colorRgb, createdTime: $createdTime, hidden: $hidden, id: $id, kind: $kind, name: $name, orgUnitId: $orgUnitId, restrictions: $restrictions, themeId: $themeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Permanently deletes a shared drive for which the user is an organizer. The shared drive cannot contain any untrashed items.
#
# DELETE /drives/{driveId}
# operationId: drive.drives.delete
export def "drives drivedrivesdelete" [
  driveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --allowItemDeletion: oneof<nothing, bool> # Whether any items inside the shared drive should also be deleted. This option is only supported when useDomainAdminAccess is also set to true.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if they are an administrator of the domain to which the shared drive belongs.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "allowItemDeletion" $allowItemDeletion "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/drives/($driveId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a shared drive's metadata by ID.
#
# GET /drives/{driveId}
# operationId: drive.drives.get
export def "drives drivedrivesget" [
  driveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if they are an administrator of the domain to which the shared drive belongs.
]: nothing -> record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/drives/($driveId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the metadata for a shared drive.
#
# PATCH /drives/{driveId}
# operationId: drive.drives.update
# --backgroundImageFile shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
# --capabilities shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeDriveBackground?: bool, canChangeDriveMembersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRename?: bool, canRenameDrive?: bool, canResetDriveRestrictions?: bool, canShare?: bool, canTrashChildren?: bool}
# --restrictions shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, driveMembersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool}
export def "drives drivedrivesupdate" [
  driveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator. If set to true, then the requester is granted access if they're an administrator of the domain to which the shared drive belongs.
  --backgroundImageFile: record # An image file and cropping parameters from which a background image for this shared drive is set. This is a write-only field; it can only be set on drive.drives.update requests that don't set themeId. When specified, all fields of the backgroundImageFile must be set. — shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
  --backgroundImageLink: string # A short-lived link to this shared drive's background image.
  --capabilities: record # Capabilities the current user has on this shared drive. — shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeDriveBackground?: bool, canChangeDriveMembersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRename?: bool, canRenameDrive?: bool, canResetDriveRestrictions?: bool, canShare?: bool, canTrashChildren?: bool}
  --colorRgb: string # The color of this shared drive as an RGB hex string. It can only be set on drive.drives.update requests that don't set themeId.
  --createdTime: string # The time at which the shared drive was created (RFC 3339 date-time). (format: date-time)
  --hidden: oneof<nothing, bool> # Whether the shared drive is hidden from default view.
  --id: string # The ID of this shared drive which is also the ID of the top level folder of this shared drive.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#drive". (default: drive#drive)
  --name: string # The name of this shared drive.
  --orgUnitId: string # The organizational unit of this shared drive. This field is only populated on drives.list responses when the useDomainAdminAccess parameter is set to true.
  --restrictions: record # A set of restrictions that apply to this shared drive or items inside this shared drive. — shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, driveMembersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool}
  --themeId: string # The ID of the theme from which the background image and color are set. The set of possible driveThemes can be retrieved from a drive.about.get response. When not specified on a drive.drives.create request, a random theme is chosen from which the background image and color are set. This is a write-only field; it can only be set on requests that don't set colorRgb or backgroundImageFile.
]: any -> record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/drives/($driveId)" $qp)
  let body = {backgroundImageFile: $backgroundImageFile, backgroundImageLink: $backgroundImageLink, capabilities: $capabilities, colorRgb: $colorRgb, createdTime: $createdTime, hidden: $hidden, id: $id, kind: $kind, name: $name, orgUnitId: $orgUnitId, restrictions: $restrictions, themeId: $themeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Hides a shared drive from the default view.
#
# POST /drives/{driveId}/hide
# operationId: drive.drives.hide
export def "drives-hide drivedriveshide" [
  driveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/drives/($driveId)/hide" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restores a shared drive to the default view.
#
# POST /drives/{driveId}/unhide
# operationId: drive.drives.unhide
export def "drives-unhide drivedrivesunhide" [
  driveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/drives/($driveId)/unhide" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists or searches files.
#
# GET /files
# operationId: drive.files.list
export def "files drivefileslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --corpora: string # Groupings of files to which the query applies. Supported groupings are: 'user' (files created by, opened by, or shared directly with the user), 'drive' (files in the specified shared drive as indicated by the 'driveId'), 'domain' (files shared to the user's domain), and 'allDrives' (A combination of 'user' and 'drive' for all drives where the user is a member). When able, use 'user' or 'drive', instead of 'allDrives', for efficiency.
  --corpus: string@corpus-completer # The source of files to list. Deprecated: use 'corpora' instead.
  --driveId: string # ID of the shared drive to search.
  --includeItemsFromAllDrives: oneof<nothing, bool> # Whether both My Drive and shared drive items should be included in results.
  --includeLabels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --includePermissionsForView: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --includeTeamDriveItems: oneof<nothing, bool> # Deprecated use includeItemsFromAllDrives instead.
  --orderBy: string # A comma-separated list of sort keys. Valid keys are 'createdTime', 'folder', 'modifiedByMeTime', 'modifiedTime', 'name', 'name_natural', 'quotaBytesUsed', 'recency', 'sharedWithMeTime', 'starred', and 'viewedByMeTime'. Each key sorts ascending by default, but may be reversed with the 'desc' modifier. Example usage: ?orderBy=folder,modifiedTime desc,name. Please note that there is a current limitation for users with approximately one million files in which the requested sort order is ignored.
  --pageSize: int # The maximum number of files to return per page. Partial or empty result pages are possible even before the end of the files list has been reached.
  --pageToken: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
  --q: string # A query for filtering the file results. See the "Search for Files" guide for supported syntax.
  --spaces: string # A comma-separated list of spaces to query within the corpora. Supported values are 'drive' and 'appDataFolder'.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --teamDriveId: string # Deprecated use driveId instead.
]: nothing -> record<files: table<appProperties: record, capabilities: record, contentHints: record, contentRestrictions: list, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record, isAppAuthorized: bool, kind: string, labelInfo: record, lastModifyingUser: record, linkShareMetadata: record, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: list, parents: list, permissionIds: list, permissions: list, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record, shortcutDetails: record, size: string, spaces: list, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record, version: string, videoMediaMetadata: record, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool>, incompleteSearch: bool, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "corpora" $corpora "scalar") (serialize-qp "corpus" $corpus "scalar") (serialize-qp "driveId" $driveId "scalar") (serialize-qp "includeItemsFromAllDrives" $includeItemsFromAllDrives "scalar") (serialize-qp "includeLabels" $includeLabels "scalar") (serialize-qp "includePermissionsForView" $includePermissionsForView "scalar") (serialize-qp "includeTeamDriveItems" $includeTeamDriveItems "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "spaces" $spaces "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar") (serialize-qp "teamDriveId" $teamDriveId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a file.
#
# POST /files
# operationId: drive.files.create
export def "files drivefilescreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --enforceSingleParent: oneof<nothing, bool> # Deprecated. Creating files in multiple folders is no longer supported.
  --ignoreDefaultVisibility: oneof<nothing, bool> # Whether to ignore the domain's default visibility settings for the created file. Domain administrators can choose to make all uploaded files visible to the domain by default; this parameter bypasses that behavior for the request. Permissions are still inherited from parent folders.
  --includeLabels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --includePermissionsForView: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --keepRevisionForever: oneof<nothing, bool> # Whether to set the 'keepForever' field in the new head revision. This is only applicable to files with binary content in Google Drive. Only 200 revisions for the file can be kept forever. If the limit is reached, try deleting pinned revisions.
  --ocrLanguage: string # A language hint for OCR processing during image import (ISO 639-1 code).
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --useContentAsIndexableText: oneof<nothing, bool> # Whether to use the uploaded content as indexable text.
  --body: record
]: any -> record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "enforceSingleParent" $enforceSingleParent "scalar") (serialize-qp "ignoreDefaultVisibility" $ignoreDefaultVisibility "scalar") (serialize-qp "includeLabels" $includeLabels "scalar") (serialize-qp "includePermissionsForView" $includePermissionsForView "scalar") (serialize-qp "keepRevisionForever" $keepRevisionForever "scalar") (serialize-qp "ocrLanguage" $ocrLanguage "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar") (serialize-qp "useContentAsIndexableText" $useContentAsIndexableText "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Generates a set of file IDs which can be provided in create or copy requests.
#
# GET /files/generateIds
# operationId: drive.files.generateIds
export def "files-generate-ids drivefilesgenerateIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --count: int # The number of IDs to return.
  --space: string # The space in which the IDs can be used to create new files. Supported values are 'drive' and 'appDataFolder'. (Default: 'drive')
  --type: string # The type of items which the IDs can be used for. Supported values are 'files' and 'shortcuts'. Note that 'shortcuts' are only supported in the drive 'space'. (Default: 'files')
]: nothing -> record<ids: list<string>, kind: string, space: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "space" $space "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files/generateIds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Permanently deletes all of the user's trashed files.
#
# DELETE /files/trash
# operationId: drive.files.emptyTrash
export def "files-trash drivefilesemptyTrash" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --driveId: string # If set, empties the trash of the provided shared drive.
  --enforceSingleParent: oneof<nothing, bool> # Deprecated. If an item is not in a shared drive and its last parent is deleted but the item itself is not, the item will be placed under its owner's root.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "driveId" $driveId "scalar") (serialize-qp "enforceSingleParent" $enforceSingleParent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files/trash" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Permanently deletes a file owned by the user without moving it to the trash. If the file belongs to a shared drive the user must be an organizer on the parent. If the target is a folder, all descendants owned by the user are also deleted.
#
# DELETE /files/{fileId}
# operationId: drive.files.delete
export def "files drivefilesdelete" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --enforceSingleParent: oneof<nothing, bool> # Deprecated. If an item is not in a shared drive and its last parent is deleted but the item itself is not, the item will be placed under its owner's root.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "enforceSingleParent" $enforceSingleParent "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a file's metadata or content by ID.
#
# GET /files/{fileId}
# operationId: drive.files.get
export def "files drivefilesget" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --acknowledgeAbuse: oneof<nothing, bool> # Whether the user is acknowledging the risk of downloading known malware or other abusive files. This is only applicable when alt=media.
  --includeLabels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --includePermissionsForView: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
]: nothing -> record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "acknowledgeAbuse" $acknowledgeAbuse "scalar") (serialize-qp "includeLabels" $includeLabels "scalar") (serialize-qp "includePermissionsForView" $includePermissionsForView "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a file's metadata and/or content. When calling this method, only populate fields in the request that you want to modify. When updating fields, some fields might change automatically, such as modifiedDate. This method supports patch semantics.
#
# PATCH /files/{fileId}
# operationId: drive.files.update
export def "files drivefilesupdate" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --addParents: string # A comma-separated list of parent IDs to add.
  --enforceSingleParent: oneof<nothing, bool> # Deprecated. Adding files to multiple folders is no longer supported. Use shortcuts instead.
  --includeLabels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --includePermissionsForView: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --keepRevisionForever: oneof<nothing, bool> # Whether to set the 'keepForever' field in the new head revision. This is only applicable to files with binary content in Google Drive. Only 200 revisions for the file can be kept forever. If the limit is reached, try deleting pinned revisions.
  --ocrLanguage: string # A language hint for OCR processing during image import (ISO 639-1 code).
  --removeParents: string # A comma-separated list of parent IDs to remove.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --useContentAsIndexableText: oneof<nothing, bool> # Whether to use the uploaded content as indexable text.
  --body: record
]: any -> record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "addParents" $addParents "scalar") (serialize-qp "enforceSingleParent" $enforceSingleParent "scalar") (serialize-qp "includeLabels" $includeLabels "scalar") (serialize-qp "includePermissionsForView" $includePermissionsForView "scalar") (serialize-qp "keepRevisionForever" $keepRevisionForever "scalar") (serialize-qp "ocrLanguage" $ocrLanguage "scalar") (serialize-qp "removeParents" $removeParents "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar") (serialize-qp "useContentAsIndexableText" $useContentAsIndexableText "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Lists a file's comments.
#
# GET /files/{fileId}/comments
# operationId: drive.comments.list
export def "files-comments drivecommentslist" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --includeDeleted: oneof<nothing, bool> # Whether to include deleted comments. Deleted comments will not include their original content.
  --pageSize: int # The maximum number of comments to return per page.
  --pageToken: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
  --startModifiedTime: string # The minimum value of 'modifiedTime' for the result comments (RFC 3339 date-time).
]: nothing -> record<comments: table<anchor: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record, replies: list, resolved: bool>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "startModifiedTime" $startModifiedTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a comment on a file.
#
# POST /files/{fileId}/comments
# operationId: drive.comments.create
# --author shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
# --quotedFileContent shape: {mimeType?: string, value?: string}
# --replies item shape: {action?: string, author?: record, content?: string, createdTime?: string, deleted?: bool, htmlContent?: string, id?: string, kind?: string, modifiedTime?: string}
export def "files-comments drivecommentscreate" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --anchor: string # A region of the document represented as a JSON string. For details on defining anchor properties, refer to  Add comments and replies.
  --author: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --content: string # The plain text content of the comment. This field is used for setting the content, while htmlContent should be displayed.
  --createdTime: string # The time at which the comment was created (RFC 3339 date-time). (format: date-time)
  --deleted: oneof<nothing, bool> # Whether the comment has been deleted. A deleted comment has no content.
  --htmlContent: string # The content of the comment with HTML formatting.
  --id: string # The ID of the comment.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#comment". (default: drive#comment)
  --modifiedTime: string # The last time the comment or any of its replies was modified (RFC 3339 date-time). (format: date-time)
  --quotedFileContent: record # The file content to which the comment refers, typically within the anchor region. For a text file, for example, this would be the text at the location of the comment. — shape: {mimeType?: string, value?: string}
  --replies: list # The full list of replies to the comment in chronological order. — item shape: {action?: string, author?: record, content?: string, createdTime?: string, deleted?: bool, htmlContent?: string, id?: string, kind?: string, modifiedTime?: string}
  --resolved: oneof<nothing, bool> # Whether the comment has been resolved by one of its replies.
]: any -> record<anchor: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record<mimeType: string, value: string>, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>, resolved: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/comments" $qp)
  let body = {anchor: $anchor, author: $author, content: $content, createdTime: $createdTime, deleted: $deleted, htmlContent: $htmlContent, id: $id, kind: $kind, modifiedTime: $modifiedTime, quotedFileContent: $quotedFileContent, replies: $replies, resolved: $resolved} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a comment.
#
# DELETE /files/{fileId}/comments/{commentId}
# operationId: drive.comments.delete
export def "files-comments drivecommentsdelete" [
  fileId: string
  commentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/comments/($commentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a comment by ID.
#
# GET /files/{fileId}/comments/{commentId}
# operationId: drive.comments.get
export def "files-comments drivecommentsget" [
  fileId: string
  commentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --includeDeleted: oneof<nothing, bool> # Whether to return deleted comments. Deleted comments will not include their original content.
]: nothing -> record<anchor: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record<mimeType: string, value: string>, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>, resolved: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/comments/($commentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a comment with patch semantics.
#
# PATCH /files/{fileId}/comments/{commentId}
# operationId: drive.comments.update
# --author shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
# --quotedFileContent shape: {mimeType?: string, value?: string}
# --replies item shape: {action?: string, author?: record, content?: string, createdTime?: string, deleted?: bool, htmlContent?: string, id?: string, kind?: string, modifiedTime?: string}
export def "files-comments drivecommentsupdate" [
  fileId: string
  commentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --anchor: string # A region of the document represented as a JSON string. For details on defining anchor properties, refer to  Add comments and replies.
  --author: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --content: string # The plain text content of the comment. This field is used for setting the content, while htmlContent should be displayed.
  --createdTime: string # The time at which the comment was created (RFC 3339 date-time). (format: date-time)
  --deleted: oneof<nothing, bool> # Whether the comment has been deleted. A deleted comment has no content.
  --htmlContent: string # The content of the comment with HTML formatting.
  --id: string # The ID of the comment.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#comment". (default: drive#comment)
  --modifiedTime: string # The last time the comment or any of its replies was modified (RFC 3339 date-time). (format: date-time)
  --quotedFileContent: record # The file content to which the comment refers, typically within the anchor region. For a text file, for example, this would be the text at the location of the comment. — shape: {mimeType?: string, value?: string}
  --replies: list # The full list of replies to the comment in chronological order. — item shape: {action?: string, author?: record, content?: string, createdTime?: string, deleted?: bool, htmlContent?: string, id?: string, kind?: string, modifiedTime?: string}
  --resolved: oneof<nothing, bool> # Whether the comment has been resolved by one of its replies.
]: any -> record<anchor: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record<mimeType: string, value: string>, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>, resolved: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/comments/($commentId)" $qp)
  let body = {anchor: $anchor, author: $author, content: $content, createdTime: $createdTime, deleted: $deleted, htmlContent: $htmlContent, id: $id, kind: $kind, modifiedTime: $modifiedTime, quotedFileContent: $quotedFileContent, replies: $replies, resolved: $resolved} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists a comment's replies.
#
# GET /files/{fileId}/comments/{commentId}/replies
# operationId: drive.replies.list
export def "files-comments-replies drivereplieslist" [
  fileId: string
  commentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --includeDeleted: oneof<nothing, bool> # Whether to include deleted replies. Deleted replies will not include their original content.
  --pageSize: int # The maximum number of replies to return per page.
  --pageToken: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
]: nothing -> record<kind: string, nextPageToken: string, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/comments/($commentId)/replies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a reply to a comment.
#
# POST /files/{fileId}/comments/{commentId}/replies
# operationId: drive.replies.create
# --author shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
export def "files-comments-replies driverepliescreate" [
  fileId: string
  commentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --action: string # The action the reply performed to the parent comment. Valid values are:   - resolve  - reopen
  --author: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --content: string # The plain text content of the reply. This field is used for setting the content, while htmlContent should be displayed. This is required on creates if no action is specified.
  --createdTime: string # The time at which the reply was created (RFC 3339 date-time). (format: date-time)
  --deleted: oneof<nothing, bool> # Whether the reply has been deleted. A deleted reply has no content.
  --htmlContent: string # The content of the reply with HTML formatting.
  --id: string # The ID of the reply.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#reply". (default: drive#reply)
  --modifiedTime: string # The last time the reply was modified (RFC 3339 date-time). (format: date-time)
]: any -> record<action: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/comments/($commentId)/replies" $qp)
  let body = {action: $action, author: $author, content: $content, createdTime: $createdTime, deleted: $deleted, htmlContent: $htmlContent, id: $id, kind: $kind, modifiedTime: $modifiedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a reply.
#
# DELETE /files/{fileId}/comments/{commentId}/replies/{replyId}
# operationId: drive.replies.delete
export def "files-comments-replies driverepliesdelete" [
  fileId: string
  commentId: string
  replyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/comments/($commentId)/replies/($replyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a reply by ID.
#
# GET /files/{fileId}/comments/{commentId}/replies/{replyId}
# operationId: drive.replies.get
export def "files-comments-replies driverepliesget" [
  fileId: string
  commentId: string
  replyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --includeDeleted: oneof<nothing, bool> # Whether to return deleted replies. Deleted replies will not include their original content.
]: nothing -> record<action: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/comments/($commentId)/replies/($replyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a reply with patch semantics.
#
# PATCH /files/{fileId}/comments/{commentId}/replies/{replyId}
# operationId: drive.replies.update
# --author shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
export def "files-comments-replies driverepliesupdate" [
  fileId: string
  commentId: string
  replyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --action: string # The action the reply performed to the parent comment. Valid values are:   - resolve  - reopen
  --author: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --content: string # The plain text content of the reply. This field is used for setting the content, while htmlContent should be displayed. This is required on creates if no action is specified.
  --createdTime: string # The time at which the reply was created (RFC 3339 date-time). (format: date-time)
  --deleted: oneof<nothing, bool> # Whether the reply has been deleted. A deleted reply has no content.
  --htmlContent: string # The content of the reply with HTML formatting.
  --id: string # The ID of the reply.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#reply". (default: drive#reply)
  --modifiedTime: string # The last time the reply was modified (RFC 3339 date-time). (format: date-time)
]: any -> record<action: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/comments/($commentId)/replies/($replyId)" $qp)
  let body = {action: $action, author: $author, content: $content, createdTime: $createdTime, deleted: $deleted, htmlContent: $htmlContent, id: $id, kind: $kind, modifiedTime: $modifiedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a copy of a file and applies any requested updates with patch semantics. Folders cannot be copied.
#
# POST /files/{fileId}/copy
# operationId: drive.files.copy
# --capabilities shape: {canAcceptOwnership?: bool, canAddChildren?: bool, canAddFolderFromAnotherDrive?: bool, canAddMyDriveParent?: bool, canChangeCopyRequiresWriterPermission?: bool, canChangeSecurityUpdateEnabled?: bool, canChangeViewersCanCopyContent?: bool, canComment?: bool, canCopy?: bool, canDelete?: bool, canDeleteChildren?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canModifyContent?: bool, canModifyContentRestriction?: bool, canModifyLabels?: bool, canMoveChildrenOutOfDrive?: bool, canMoveChildrenOutOfTeamDrive?: bool, canMoveChildrenWithinDrive?: bool, canMoveChildrenWithinTeamDrive?: bool, canMoveItemIntoTeamDrive?: bool, canMoveItemOutOfDrive?: bool, canMoveItemOutOfTeamDrive?: bool, canMoveItemWithinDrive?: bool, canMoveItemWithinTeamDrive?: bool, canMoveTeamDriveItem?: bool, canReadDrive?: bool, canReadLabels?: bool, canReadRevisions?: bool, canReadTeamDrive?: bool, canRemoveChildren?: bool, canRemoveMyDriveParent?: bool, canRename?: bool, canShare?: bool, canTrash?: bool, canTrashChildren?: bool, canUntrash?: bool}
# --contentHints shape: {indexableText?: string, thumbnail?: record}
# --contentRestrictions item shape: {readOnly?: bool, reason?: string, restrictingUser?: record, restrictionTime?: string, type?: string}
# --imageMediaMetadata shape: {aperture?: float, cameraMake?: string, cameraModel?: string, colorSpace?: string, exposureBias?: float, exposureMode?: string, exposureTime?: float, flashUsed?: bool, focalLength?: float, height?: int, isoSpeed?: int, lens?: string, location?: record, maxApertureValue?: float, meteringMode?: string, rotation?: int, sensor?: string, subjectDistance?: int, time?: string, whiteBalance?: string, width?: int}
# --labelInfo shape: {labels?: list}
# --lastModifyingUser shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
# --linkShareMetadata shape: {securityUpdateEligible?: bool, securityUpdateEnabled?: bool}
# --owners item shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
# --permissions item shape: {allowFileDiscovery?: bool, deleted?: bool, displayName?: string, domain?: string, emailAddress?: string, expirationTime?: string, id?: string, kind?: string, pendingOwner?: bool, photoLink?: string, role?: string, type?: string, view?: string}
# --sharingUser shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
# --shortcutDetails shape: {targetId?: string, targetMimeType?: string, targetResourceKey?: string}
# --trashingUser shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
# --videoMediaMetadata shape: {durationMillis?: string, height?: int, width?: int}
export def "files-copy drivefilescopy" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --enforceSingleParent: oneof<nothing, bool> # Deprecated. Copying files into multiple folders is no longer supported. Use shortcuts instead.
  --ignoreDefaultVisibility: oneof<nothing, bool> # Whether to ignore the domain's default visibility settings for the created file. Domain administrators can choose to make all uploaded files visible to the domain by default; this parameter bypasses that behavior for the request. Permissions are still inherited from parent folders.
  --includeLabels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --includePermissionsForView: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --keepRevisionForever: oneof<nothing, bool> # Whether to set the 'keepForever' field in the new head revision. This is only applicable to files with binary content in Google Drive. Only 200 revisions for the file can be kept forever. If the limit is reached, try deleting pinned revisions.
  --ocrLanguage: string # A language hint for OCR processing during image import (ISO 639-1 code).
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --appProperties: record # A collection of arbitrary key-value pairs that are private to the requesting app. Entries with null values are cleared in update and copy requests. These properties can only be retrieved using an authenticated request. An authenticated request uses an access token obtained with an OAuth 2 client ID. You cannot use an API key to retrieve private properties.
  --capabilities: record # Capabilities the current user has on this file. Each capability corresponds to a fine-grained action that a user can take. — shape: {canAcceptOwnership?: bool, canAddChildren?: bool, canAddFolderFromAnotherDrive?: bool, canAddMyDriveParent?: bool, canChangeCopyRequiresWriterPermission?: bool, canChangeSecurityUpdateEnabled?: bool, canChangeViewersCanCopyContent?: bool, canComment?: bool, canCopy?: bool, canDelete?: bool, canDeleteChildren?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canModifyContent?: bool, canModifyContentRestriction?: bool, canModifyLabels?: bool, canMoveChildrenOutOfDrive?: bool, canMoveChildrenOutOfTeamDrive?: bool, canMoveChildrenWithinDrive?: bool, canMoveChildrenWithinTeamDrive?: bool, canMoveItemIntoTeamDrive?: bool, canMoveItemOutOfDrive?: bool, canMoveItemOutOfTeamDrive?: bool, canMoveItemWithinDrive?: bool, canMoveItemWithinTeamDrive?: bool, canMoveTeamDriveItem?: bool, canReadDrive?: bool, canReadLabels?: bool, canReadRevisions?: bool, canReadTeamDrive?: bool, canRemoveChildren?: bool, canRemoveMyDriveParent?: bool, canRename?: bool, canShare?: bool, canTrash?: bool, canTrashChildren?: bool, canUntrash?: bool}
  --contentHints: record # Additional information about the content of the file. These fields are never populated in responses. — shape: {indexableText?: string, thumbnail?: record}
  --contentRestrictions: list # Restrictions for accessing the content of the file. Only populated if such a restriction exists. — item shape: {readOnly?: bool, reason?: string, restrictingUser?: record, restrictionTime?: string, type?: string}
  --copyRequiresWriterPermission: oneof<nothing, bool> # Whether the options to copy, print, or download this file, should be disabled for readers and commenters.
  --createdTime: string # The time at which the file was created (RFC 3339 date-time). (format: date-time)
  --description: string # A short description of the file.
  --driveId: string # ID of the shared drive the file resides in. Only populated for items in shared drives.
  --explicitlyTrashed: oneof<nothing, bool> # Whether the file has been explicitly trashed, as opposed to recursively trashed from a parent folder.
  --fileExtension: string # The final component of fullFileExtension. This is only available for files with binary content in Google Drive.
  --folderColorRgb: string # The color for a folder or shortcut to a folder as an RGB hex string. The supported colors are published in the folderColorPalette field of the About resource. If an unsupported color is specified, the closest color in the palette will be used instead.
  --fullFileExtension: string # The full file extension extracted from the name field. Can contain multiple concatenated extensions, such as "tar.gz". This is only available for files with binary content in Google Drive. This is automatically updated when the name field changes, however it's not cleared if the new name does not contain a valid extension.
  --hasAugmentedPermissions: oneof<nothing, bool> # Whether there are permissions directly on this file. This field is only populated for items in shared drives.
  --hasThumbnail: oneof<nothing, bool> # Whether this file has a thumbnail. This does not indicate whether the requesting app has access to the thumbnail. To check access, look for the presence of the thumbnailLink field.
  --headRevisionId: string # The ID of the file's head revision. This is only available for files with binary content in Google Drive.
  --iconLink: string # A static, unauthenticated link to the file's icon.
  --id: string # The ID of the file.
  --imageMediaMetadata: record # Additional metadata about image media, if available. — shape: {aperture?: float, cameraMake?: string, cameraModel?: string, colorSpace?: string, exposureBias?: float, exposureMode?: string, exposureTime?: float, flashUsed?: bool, focalLength?: float, height?: int, isoSpeed?: int, lens?: string, location?: record, maxApertureValue?: float, meteringMode?: string, rotation?: int, sensor?: string, subjectDistance?: int, time?: string, whiteBalance?: string, width?: int}
  --isAppAuthorized: oneof<nothing, bool> # Whether the requesting app created or opened the file.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#file". (default: drive#file)
  --labelInfo: record # An overview of the labels on the file. — shape: {labels?: list}
  --lastModifyingUser: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --linkShareMetadata: record # Contains details about the link URLs that clients are using to refer to this item. — shape: {securityUpdateEligible?: bool, securityUpdateEnabled?: bool}
  --md5Checksum: string # The MD5 checksum for the content of the file. This is only applicable to files with binary content in Google Drive.
  --mimeType: string # The MIME type of the file. Google Drive will attempt to automatically detect an appropriate value from uploaded content if no value is provided. The value cannot be changed unless a new revision is uploaded. If a file is created with a Google Doc MIME type, the uploaded content will be imported if possible. The supported import formats are published in the About resource.
  --modifiedByMe: oneof<nothing, bool> # Whether this user has modified the file.
  --modifiedByMeTime: string # The last time the user modified the file (RFC 3339 date-time). (format: date-time)
  --modifiedTime: string # The last time anyone modified the file (RFC 3339 date-time). Note that setting modifiedTime will also update modifiedByMeTime for the user. (format: date-time)
  --name: string # The name of the file. This isn't necessarily unique within a folder. Note that for immutable items such as the top-level folders of shared drives, My Drive root folder, and Application Data folder the name is constant.
  --originalFilename: string # The original filename of the uploaded content if available, or else the original value of the name field. This is only available for files with binary content in Google Drive.
  --ownedByMe: oneof<nothing, bool> # Whether the user owns the file. Not populated for items in shared drives.
  --owners: list # The owner of this file. Only certain legacy files might have more than one owner. This field isn't populated for items in shared drives. — item shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --parents: list # The IDs of the parent folders that contain the file. If not specified as part of a create request, the file will be placed directly in the user's My Drive folder. If not specified as part of a copy request, the file will inherit any discoverable parents of the source file. Update requests must use the addParents and removeParents parameters to modify the parents list.
  --permissionIds: list # List of permission IDs for users with access to this file.
  --permissions: list # The full list of permissions for the file. This is only available if the requesting user can share the file. Not populated for items in shared drives. — item shape: {allowFileDiscovery?: bool, deleted?: bool, displayName?: string, domain?: string, emailAddress?: string, expirationTime?: string, id?: string, kind?: string, pendingOwner?: bool, photoLink?: string, role?: string, type?: string, view?: string}
  --properties: record # A collection of arbitrary key-value pairs that are visible to all apps. Entries with null values are cleared in update and copy requests.
  --quotaBytesUsed: string # The number of storage quota bytes used by the file. This includes the head revision as well as previous revisions with keepForever enabled. (format: int64)
  --resourceKey: string # A key needed to access the item via a shared link.
  --sha1Checksum: string # The SHA1 checksum associated with this file, if available. This field is only populated for files with content stored in Google Drive; it's not populated for Docs Editors or shortcut files.
  --sha256Checksum: string # The SHA256 checksum associated with this file, if available. This field is only populated for files with content stored in Google Drive; it's not populated for Docs Editors or shortcut files.
  --shared: oneof<nothing, bool> # Whether the file has been shared. Not populated for items in shared drives.
  --sharedWithMeTime: string # The time at which the file was shared with the user, if applicable (RFC 3339 date-time). (format: date-time)
  --sharingUser: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --shortcutDetails: record # Shortcut file details. Only populated for shortcut files, which have the mimeType field set to application/vnd.google-apps.shortcut. — shape: {targetId?: string, targetMimeType?: string, targetResourceKey?: string}
  --size: string # The size of the file's content in bytes. This field is populated for files with binary content stored in Google Drive and for Docs Editors files; it's not populated for shortcuts or folders. (format: int64)
  --spaces: list # The list of spaces that contain the file. The currently supported values are 'drive', 'appDataFolder' and 'photos'.
  --starred: oneof<nothing, bool> # Whether the user has starred the file.
  --teamDriveId: string # Deprecated - use driveId instead.
  --thumbnailLink: string # A short-lived link to the file's thumbnail, if available. Typically lasts on the order of hours. Only populated when the requesting app can access the file's content. If the file isn't shared publicly, the URL returned in Files.thumbnailLink must be fetched using a credentialed request.
  --thumbnailVersion: string # The thumbnail version for use in thumbnail cache invalidation. (format: int64)
  --trashed: oneof<nothing, bool> # Whether the file has been trashed, either explicitly or from a trashed parent folder. Only the owner can trash a file. The trashed item is excluded from all files.list responses returned for any user who does not own the file. However, all users with access to the file can see the trashed item metadata in an API response. All users with access can copy, download, export, and share the file.
  --trashedTime: string # The time that the item was trashed (RFC 3339 date-time). Only populated for items in shared drives. (format: date-time)
  --trashingUser: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --version: string # A monotonically increasing version number for the file. This reflects every change made to the file on the server, even those not visible to the user. (format: int64)
  --videoMediaMetadata: record # Additional metadata about video media. This might not be available immediately upon upload. — shape: {durationMillis?: string, height?: int, width?: int}
  --viewedByMe: oneof<nothing, bool> # Whether this user has viewed the file.
  --viewedByMeTime: string # The last time the user viewed the file (RFC 3339 date-time). (format: date-time)
  --viewersCanCopyContent: oneof<nothing, bool> # Deprecated - use copyRequiresWriterPermission instead.
  --webContentLink: string # A link for downloading the content of the file in a browser. This is only available for files with binary content in Google Drive.
  --webViewLink: string # A link for opening the file in a relevant Google editor or viewer in a browser.
  --writersCanShare: oneof<nothing, bool> # Whether users with only writer permission can modify the file's permissions. Not populated for items in shared drives.
]: any -> record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "enforceSingleParent" $enforceSingleParent "scalar") (serialize-qp "ignoreDefaultVisibility" $ignoreDefaultVisibility "scalar") (serialize-qp "includeLabels" $includeLabels "scalar") (serialize-qp "includePermissionsForView" $includePermissionsForView "scalar") (serialize-qp "keepRevisionForever" $keepRevisionForever "scalar") (serialize-qp "ocrLanguage" $ocrLanguage "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/copy" $qp)
  let body = {appProperties: $appProperties, capabilities: $capabilities, contentHints: $contentHints, contentRestrictions: $contentRestrictions, copyRequiresWriterPermission: $copyRequiresWriterPermission, createdTime: $createdTime, description: $description, driveId: $driveId, explicitlyTrashed: $explicitlyTrashed, fileExtension: $fileExtension, folderColorRgb: $folderColorRgb, fullFileExtension: $fullFileExtension, hasAugmentedPermissions: $hasAugmentedPermissions, hasThumbnail: $hasThumbnail, headRevisionId: $headRevisionId, iconLink: $iconLink, id: $id, imageMediaMetadata: $imageMediaMetadata, isAppAuthorized: $isAppAuthorized, kind: $kind, labelInfo: $labelInfo, lastModifyingUser: $lastModifyingUser, linkShareMetadata: $linkShareMetadata, md5Checksum: $md5Checksum, mimeType: $mimeType, modifiedByMe: $modifiedByMe, modifiedByMeTime: $modifiedByMeTime, modifiedTime: $modifiedTime, name: $name, originalFilename: $originalFilename, ownedByMe: $ownedByMe, owners: $owners, parents: $parents, permissionIds: $permissionIds, permissions: $permissions, properties: $properties, quotaBytesUsed: $quotaBytesUsed, resourceKey: $resourceKey, sha1Checksum: $sha1Checksum, sha256Checksum: $sha256Checksum, shared: $shared, sharedWithMeTime: $sharedWithMeTime, sharingUser: $sharingUser, shortcutDetails: $shortcutDetails, size: $size, spaces: $spaces, starred: $starred, teamDriveId: $teamDriveId, thumbnailLink: $thumbnailLink, thumbnailVersion: $thumbnailVersion, trashed: $trashed, trashedTime: $trashedTime, trashingUser: $trashingUser, version: $version, videoMediaMetadata: $videoMediaMetadata, viewedByMe: $viewedByMe, viewedByMeTime: $viewedByMeTime, viewersCanCopyContent: $viewersCanCopyContent, webContentLink: $webContentLink, webViewLink: $webViewLink, writersCanShare: $writersCanShare} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Exports a Google Workspace document to the requested MIME type and returns exported byte content. Note that the exported content is limited to 10MB.
#
# GET /files/{fileId}/export
# operationId: drive.files.export
export def "files-export drivefilesexport" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --mimeType: string # The MIME type of the format requested for this export.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "mimeType" $mimeType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the labels on a file.
#
# GET /files/{fileId}/listLabels
# operationId: drive.files.listLabels
export def "files-list-labels drivefileslistLabels" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --maxResults: int # The maximum number of labels to return per page. When not set, this defaults to 100.
  --pageToken: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
]: nothing -> record<kind: string, labels: table<fields: record, id: string, kind: string, revisionId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/listLabels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modifies the set of labels on a file.
#
# POST /files/{fileId}/modifyLabels
# operationId: drive.files.modifyLabels
# --labelModifications item shape: {fieldModifications?: list, kind?: string, labelId?: string, removeLabel?: bool}
export def "files-modify-labels drivefilesmodifyLabels" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --kind: string # This is always drive#modifyLabelsRequest (default: drive#modifyLabelsRequest)
  --labelModifications: list # The list of modifications to apply to the labels on the file. — item shape: {fieldModifications?: list, kind?: string, labelId?: string, removeLabel?: bool}
]: any -> record<kind: string, modifiedLabels: table<fields: record, id: string, kind: string, revisionId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/modifyLabels" $qp)
  let body = {kind: $kind, labelModifications: $labelModifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists a file's or shared drive's permissions.
#
# GET /files/{fileId}/permissions
# operationId: drive.permissions.list
export def "files-permissions drivepermissionslist" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --includePermissionsForView: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --pageSize: int # The maximum number of permissions to return per page. When not set for files in a shared drive, at most 100 results will be returned. When not set for files that are not in a shared drive, the entire list will be returned.
  --pageToken: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if the file ID parameter refers to a shared drive and the requester is an administrator of the domain to which the shared drive belongs.
]: nothing -> record<kind: string, nextPageToken: string, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "includePermissionsForView" $includePermissionsForView "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a permission for a file or shared drive. For more information on creating permissions, see Share files, folders & drives.
#
# POST /files/{fileId}/permissions
# operationId: drive.permissions.create
# --permissionDetails item shape: {inherited?: bool, inheritedFrom?: string, permissionType?: string, role?: string}
# --teamDrivePermissionDetails item shape: {inherited?: bool, inheritedFrom?: string, role?: string, teamDrivePermissionType?: string}
export def "files-permissions drivepermissionscreate" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --emailMessage: string # A plain text custom message to include in the notification email.
  --enforceSingleParent: oneof<nothing, bool> # Deprecated. See moveToNewOwnersRoot for details.
  --moveToNewOwnersRoot: oneof<nothing, bool> # This parameter will only take effect if the item is not in a shared drive and the request is attempting to transfer the ownership of the item. If set to true, the item will be moved to the new owner's My Drive root folder and all prior parents removed. If set to false, parents are not changed.
  --sendNotificationEmail: oneof<nothing, bool> # Whether to send a notification email when sharing to users or groups. This defaults to true for users and groups, and is not allowed for other requests. It must not be disabled for ownership transfers.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --transferOwnership: oneof<nothing, bool> # Whether to transfer ownership to the specified user and downgrade the current owner to a writer. This parameter is required as an acknowledgement of the side effect. File owners can only transfer ownership of files existing on My Drive. Files existing in a shared drive are owned by the organization that owns that shared drive. Ownership transfers are not supported for files and folders in shared drives. Organizers of a shared drive can move items from that shared drive into their My Drive which transfers the ownership to them.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if the file ID parameter refers to a shared drive and the requester is an administrator of the domain to which the shared drive belongs.
  --allowFileDiscovery: oneof<nothing, bool> # Whether the permission allows the file to be discovered through search. This is only applicable for permissions of type domain or anyone.
  --deleted: oneof<nothing, bool> # Whether the account associated with this permission has been deleted. This field only pertains to user and group permissions.
  --displayName: string # The "pretty" name of the value of the permission. The following is a list of examples for each type of permission:   - user - User's full name, as defined for their Google Account, such as "Joe Smith."  - group - Name of the Google Group, such as "The Company Administrators."  - domain - String domain name, such as "your-company.com."  - anyone - No displayName is present.
  --domain: string # The domain to which this permission refers. The following options are currently allowed:   - The entire domain, such as "your-company.com."  - A target audience, such as "ID.audience.googledomains.com."
  --emailAddress: string # The email address of the user or group to which this permission refers.
  --expirationTime: string # The time at which this permission will expire (RFC 3339 date-time). Expiration times have the following restrictions:   - They cannot be set on shared drive items.  - They can only be set on user and group permissions.  - The time must be in the future.  - The time cannot be more than one year in the future. (format: date-time)
  --id: string # The ID of this permission. This is a unique identifier for the grantee, and is published in User resources as permissionId. IDs should be treated as opaque values.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#permission". (default: drive#permission)
  --pendingOwner: oneof<nothing, bool> # Whether the account associated with this permission is a pending owner. Only populated for user type permissions for files that aren't in a shared drive.
  --photoLink: string # A link to the user's profile photo, if available.
  --role: string # The role granted by this permission. While new values may be supported in the future, the following are currently allowed:   - owner  - organizer  - fileOrganizer  - writer  - commenter  - reader
  --type: string # The type of the grantee. Valid values are:   - user  - group  - domain  - anyone  When creating a permission, if type is user or group, you must provide an emailAddress for the user or group. When type is domain, you must provide a domain. There isn't extra information required for the anyone type.
  --view: string # Indicates the view for this permission. Only populated for permissions that belong to a view. published is the only supported value.
]: any -> record<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: table<inherited: bool, inheritedFrom: string, permissionType: string, role: string>, photoLink: string, role: string, teamDrivePermissionDetails: table<inherited: bool, inheritedFrom: string, role: string, teamDrivePermissionType: string>, type: string, view: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "emailMessage" $emailMessage "scalar") (serialize-qp "enforceSingleParent" $enforceSingleParent "scalar") (serialize-qp "moveToNewOwnersRoot" $moveToNewOwnersRoot "scalar") (serialize-qp "sendNotificationEmail" $sendNotificationEmail "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar") (serialize-qp "transferOwnership" $transferOwnership "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/permissions" $qp)
  let body = {allowFileDiscovery: $allowFileDiscovery, deleted: $deleted, displayName: $displayName, domain: $domain, emailAddress: $emailAddress, expirationTime: $expirationTime, id: $id, kind: $kind, pendingOwner: $pendingOwner, photoLink: $photoLink, role: $role, type: $type, view: $view} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a permission.
#
# DELETE /files/{fileId}/permissions/{permissionId}
# operationId: drive.permissions.delete
export def "files-permissions drivepermissionsdelete" [
  fileId: string
  permissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if the file ID parameter refers to a shared drive and the requester is an administrator of the domain to which the shared drive belongs.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/permissions/($permissionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a permission by ID.
#
# GET /files/{fileId}/permissions/{permissionId}
# operationId: drive.permissions.get
export def "files-permissions drivepermissionsget" [
  fileId: string
  permissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if the file ID parameter refers to a shared drive and the requester is an administrator of the domain to which the shared drive belongs.
]: nothing -> record<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: table<inherited: bool, inheritedFrom: string, permissionType: string, role: string>, photoLink: string, role: string, teamDrivePermissionDetails: table<inherited: bool, inheritedFrom: string, role: string, teamDrivePermissionType: string>, type: string, view: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/permissions/($permissionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a permission with patch semantics.
#
# PATCH /files/{fileId}/permissions/{permissionId}
# operationId: drive.permissions.update
# --permissionDetails item shape: {inherited?: bool, inheritedFrom?: string, permissionType?: string, role?: string}
# --teamDrivePermissionDetails item shape: {inherited?: bool, inheritedFrom?: string, role?: string, teamDrivePermissionType?: string}
export def "files-permissions drivepermissionsupdate" [
  fileId: string
  permissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --removeExpiration: oneof<nothing, bool> # Whether to remove the expiration date.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --transferOwnership: oneof<nothing, bool> # Whether to transfer ownership to the specified user and downgrade the current owner to a writer. This parameter is required as an acknowledgement of the side effect. File owners can only transfer ownership of files existing on My Drive. Files existing in a shared drive are owned by the organization that owns that shared drive. Ownership transfers are not supported for files and folders in shared drives. Organizers of a shared drive can move items from that shared drive into their My Drive which transfers the ownership to them.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if the file ID parameter refers to a shared drive and the requester is an administrator of the domain to which the shared drive belongs.
  --allowFileDiscovery: oneof<nothing, bool> # Whether the permission allows the file to be discovered through search. This is only applicable for permissions of type domain or anyone.
  --deleted: oneof<nothing, bool> # Whether the account associated with this permission has been deleted. This field only pertains to user and group permissions.
  --displayName: string # The "pretty" name of the value of the permission. The following is a list of examples for each type of permission:   - user - User's full name, as defined for their Google Account, such as "Joe Smith."  - group - Name of the Google Group, such as "The Company Administrators."  - domain - String domain name, such as "your-company.com."  - anyone - No displayName is present.
  --domain: string # The domain to which this permission refers. The following options are currently allowed:   - The entire domain, such as "your-company.com."  - A target audience, such as "ID.audience.googledomains.com."
  --emailAddress: string # The email address of the user or group to which this permission refers.
  --expirationTime: string # The time at which this permission will expire (RFC 3339 date-time). Expiration times have the following restrictions:   - They cannot be set on shared drive items.  - They can only be set on user and group permissions.  - The time must be in the future.  - The time cannot be more than one year in the future. (format: date-time)
  --id: string # The ID of this permission. This is a unique identifier for the grantee, and is published in User resources as permissionId. IDs should be treated as opaque values.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#permission". (default: drive#permission)
  --pendingOwner: oneof<nothing, bool> # Whether the account associated with this permission is a pending owner. Only populated for user type permissions for files that aren't in a shared drive.
  --photoLink: string # A link to the user's profile photo, if available.
  --role: string # The role granted by this permission. While new values may be supported in the future, the following are currently allowed:   - owner  - organizer  - fileOrganizer  - writer  - commenter  - reader
  --type: string # The type of the grantee. Valid values are:   - user  - group  - domain  - anyone  When creating a permission, if type is user or group, you must provide an emailAddress for the user or group. When type is domain, you must provide a domain. There isn't extra information required for the anyone type.
  --view: string # Indicates the view for this permission. Only populated for permissions that belong to a view. published is the only supported value.
]: any -> record<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: table<inherited: bool, inheritedFrom: string, permissionType: string, role: string>, photoLink: string, role: string, teamDrivePermissionDetails: table<inherited: bool, inheritedFrom: string, role: string, teamDrivePermissionType: string>, type: string, view: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "removeExpiration" $removeExpiration "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar") (serialize-qp "transferOwnership" $transferOwnership "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/permissions/($permissionId)" $qp)
  let body = {allowFileDiscovery: $allowFileDiscovery, deleted: $deleted, displayName: $displayName, domain: $domain, emailAddress: $emailAddress, expirationTime: $expirationTime, id: $id, kind: $kind, pendingOwner: $pendingOwner, photoLink: $photoLink, role: $role, type: $type, view: $view} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists a file's revisions.
#
# GET /files/{fileId}/revisions
# operationId: drive.revisions.list
export def "files-revisions driverevisionslist" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --pageSize: int # The maximum number of revisions to return per page.
  --pageToken: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
]: nothing -> record<kind: string, nextPageToken: string, revisions: table<exportLinks: record, id: string, keepForever: bool, kind: string, lastModifyingUser: record, md5Checksum: string, mimeType: string, modifiedTime: string, originalFilename: string, publishAuto: bool, published: bool, publishedLink: string, publishedOutsideDomain: bool, size: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/revisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Permanently deletes a file version. You can only delete revisions for files with binary content in Google Drive, like images or videos. Revisions for other files, like Google Docs or Sheets, and the last remaining file version can't be deleted.
#
# DELETE /files/{fileId}/revisions/{revisionId}
# operationId: drive.revisions.delete
export def "files-revisions driverevisionsdelete" [
  fileId: string
  revisionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/revisions/($revisionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a revision's metadata or content by ID.
#
# GET /files/{fileId}/revisions/{revisionId}
# operationId: drive.revisions.get
export def "files-revisions driverevisionsget" [
  fileId: string
  revisionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --acknowledgeAbuse: oneof<nothing, bool> # Whether the user is acknowledging the risk of downloading known malware or other abusive files. This is only applicable when alt=media.
]: nothing -> record<exportLinks: record, id: string, keepForever: bool, kind: string, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, md5Checksum: string, mimeType: string, modifiedTime: string, originalFilename: string, publishAuto: bool, published: bool, publishedLink: string, publishedOutsideDomain: bool, size: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "acknowledgeAbuse" $acknowledgeAbuse "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/revisions/($revisionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a revision with patch semantics.
#
# PATCH /files/{fileId}/revisions/{revisionId}
# operationId: drive.revisions.update
# --lastModifyingUser shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
export def "files-revisions driverevisionsupdate" [
  fileId: string
  revisionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --exportLinks: record # Links for exporting Docs Editors files to specific formats.
  --id: string # The ID of the revision.
  --keepForever: oneof<nothing, bool> # Whether to keep this revision forever, even if it is no longer the head revision. If not set, the revision will be automatically purged 30 days after newer content is uploaded. This can be set on a maximum of 200 revisions for a file. This field is only applicable to files with binary content in Drive.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#revision". (default: drive#revision)
  --lastModifyingUser: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --md5Checksum: string # The MD5 checksum of the revision's content. This is only applicable to files with binary content in Drive.
  --mimeType: string # The MIME type of the revision.
  --modifiedTime: string # The last time the revision was modified (RFC 3339 date-time). (format: date-time)
  --originalFilename: string # The original filename used to create this revision. This is only applicable to files with binary content in Drive.
  --publishAuto: oneof<nothing, bool> # Whether subsequent revisions will be automatically republished. This is only applicable to Docs Editors files.
  --published: oneof<nothing, bool> # Whether this revision is published. This is only applicable to Docs Editors files.
  --publishedLink: string # A link to the published revision. This is only populated for Google Sites files.
  --publishedOutsideDomain: oneof<nothing, bool> # Whether this revision is published outside the domain. This is only applicable to Docs Editors files.
  --size: string # The size of the revision's content in bytes. This is only applicable to files with binary content in Drive. (format: int64)
]: any -> record<exportLinks: record, id: string, keepForever: bool, kind: string, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, md5Checksum: string, mimeType: string, modifiedTime: string, originalFilename: string, publishAuto: bool, published: bool, publishedLink: string, publishedOutsideDomain: bool, size: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/revisions/($revisionId)" $qp)
  let body = {exportLinks: $exportLinks, id: $id, keepForever: $keepForever, kind: $kind, lastModifyingUser: $lastModifyingUser, md5Checksum: $md5Checksum, mimeType: $mimeType, modifiedTime: $modifiedTime, originalFilename: $originalFilename, publishAuto: $publishAuto, published: $published, publishedLink: $publishedLink, publishedOutsideDomain: $publishedOutsideDomain, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscribes to changes to a file.
#
# POST /files/{fileId}/watch
# operationId: drive.files.watch
export def "files-watch drivefileswatch" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --acknowledgeAbuse: oneof<nothing, bool> # Whether the user is acknowledging the risk of downloading known malware or other abusive files. This is only applicable when alt=media.
  --includeLabels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --includePermissionsForView: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --supportsAllDrives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supportsTeamDrives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resourceId: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resourceUri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "acknowledgeAbuse" $acknowledgeAbuse "scalar") (serialize-qp "includeLabels" $includeLabels "scalar") (serialize-qp "includePermissionsForView" $includePermissionsForView "scalar") (serialize-qp "supportsAllDrives" $supportsAllDrives "scalar") (serialize-qp "supportsTeamDrives" $supportsTeamDrives "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($fileId)/watch" $qp)
  let body = {address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resourceId: $resourceId, resourceUri: $resourceUri, token: $body_token, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deprecated use drives.list instead.
#
# GET /teamdrives
# operationId: drive.teamdrives.list
export def "teamdrives driveteamdriveslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --pageSize: int # Maximum number of Team Drives to return.
  --pageToken: string # Page token for Team Drives.
  --q: string # Query string for searching Team Drives.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then all Team Drives of the domain in which the requester is an administrator are returned.
]: nothing -> record<kind: string, nextPageToken: string, teamDrives: table<backgroundImageFile: record, backgroundImageLink: string, capabilities: record, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record, themeId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdrives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deprecated use drives.create instead.
#
# POST /teamdrives
# operationId: drive.teamdrives.create
# --backgroundImageFile shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
# --capabilities shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canChangeTeamDriveBackground?: bool, canChangeTeamMembersOnlyRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteTeamDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRemoveChildren?: bool, canRename?: bool, canRenameTeamDrive?: bool, canResetTeamDriveRestrictions?: bool, canShare?: bool, canTrashChildren?: bool}
# --restrictions shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool, teamMembersOnly?: bool}
export def "teamdrives driveteamdrivescreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --requestId: string # An ID, such as a random UUID, which uniquely identifies this user's request for idempotent creation of a Team Drive. A repeated request by the same user and with the same request ID will avoid creating duplicates by attempting to create the same Team Drive. If the Team Drive already exists a 409 error will be returned.
  --backgroundImageFile: record # An image file and cropping parameters from which a background image for this Team Drive is set. This is a write only field; it can only be set on drive.teamdrives.update requests that don't set themeId. When specified, all fields of the backgroundImageFile must be set. — shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
  --backgroundImageLink: string # A short-lived link to this Team Drive's background image.
  --capabilities: record # Capabilities the current user has on this Team Drive. — shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canChangeTeamDriveBackground?: bool, canChangeTeamMembersOnlyRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteTeamDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRemoveChildren?: bool, canRename?: bool, canRenameTeamDrive?: bool, canResetTeamDriveRestrictions?: bool, canShare?: bool, canTrashChildren?: bool}
  --colorRgb: string # The color of this Team Drive as an RGB hex string. It can only be set on a drive.teamdrives.update request that does not set themeId.
  --createdTime: string # The time at which the Team Drive was created (RFC 3339 date-time). (format: date-time)
  --id: string # The ID of this Team Drive which is also the ID of the top level folder of this Team Drive.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#teamDrive". (default: drive#teamDrive)
  --name: string # The name of this Team Drive.
  --orgUnitId: string # The organizational unit of this shared drive. This field is only populated on drives.list responses when the useDomainAdminAccess parameter is set to true.
  --restrictions: record # A set of restrictions that apply to this Team Drive or items inside this Team Drive. — shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool, teamMembersOnly?: bool}
  --themeId: string # The ID of the theme from which the background image and color will be set. The set of possible teamDriveThemes can be retrieved from a drive.about.get response. When not specified on a drive.teamdrives.create request, a random theme is chosen from which the background image and color are set. This is a write-only field; it can only be set on requests that don't set colorRgb or backgroundImageFile.
]: any -> record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canChangeTeamDriveBackground: bool, canChangeTeamMembersOnlyRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteTeamDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRemoveChildren: bool, canRename: bool, canRenameTeamDrive: bool, canResetTeamDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool, teamMembersOnly: bool>, themeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "requestId" $requestId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdrives" $qp)
  let body = {backgroundImageFile: $backgroundImageFile, backgroundImageLink: $backgroundImageLink, capabilities: $capabilities, colorRgb: $colorRgb, createdTime: $createdTime, id: $id, kind: $kind, name: $name, orgUnitId: $orgUnitId, restrictions: $restrictions, themeId: $themeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deprecated use drives.delete instead.
#
# DELETE /teamdrives/{teamDriveId}
# operationId: drive.teamdrives.delete
export def "teamdrives driveteamdrivesdelete" [
  teamDriveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teamdrives/($teamDriveId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deprecated use drives.get instead.
#
# GET /teamdrives/{teamDriveId}
# operationId: drive.teamdrives.get
export def "teamdrives driveteamdrivesget" [
  teamDriveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if they are an administrator of the domain to which the Team Drive belongs.
]: nothing -> record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canChangeTeamDriveBackground: bool, canChangeTeamMembersOnlyRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteTeamDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRemoveChildren: bool, canRename: bool, canRenameTeamDrive: bool, canResetTeamDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool, teamMembersOnly: bool>, themeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teamdrives/($teamDriveId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deprecated use drives.update instead
#
# PATCH /teamdrives/{teamDriveId}
# operationId: drive.teamdrives.update
# --backgroundImageFile shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
# --capabilities shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canChangeTeamDriveBackground?: bool, canChangeTeamMembersOnlyRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteTeamDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRemoveChildren?: bool, canRename?: bool, canRenameTeamDrive?: bool, canResetTeamDriveRestrictions?: bool, canShare?: bool, canTrashChildren?: bool}
# --restrictions shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool, teamMembersOnly?: bool}
export def "teamdrives driveteamdrivesupdate" [
  teamDriveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --useDomainAdminAccess: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if they are an administrator of the domain to which the Team Drive belongs.
  --backgroundImageFile: record # An image file and cropping parameters from which a background image for this Team Drive is set. This is a write only field; it can only be set on drive.teamdrives.update requests that don't set themeId. When specified, all fields of the backgroundImageFile must be set. — shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
  --backgroundImageLink: string # A short-lived link to this Team Drive's background image.
  --capabilities: record # Capabilities the current user has on this Team Drive. — shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canChangeTeamDriveBackground?: bool, canChangeTeamMembersOnlyRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteTeamDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRemoveChildren?: bool, canRename?: bool, canRenameTeamDrive?: bool, canResetTeamDriveRestrictions?: bool, canShare?: bool, canTrashChildren?: bool}
  --colorRgb: string # The color of this Team Drive as an RGB hex string. It can only be set on a drive.teamdrives.update request that does not set themeId.
  --createdTime: string # The time at which the Team Drive was created (RFC 3339 date-time). (format: date-time)
  --id: string # The ID of this Team Drive which is also the ID of the top level folder of this Team Drive.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#teamDrive". (default: drive#teamDrive)
  --name: string # The name of this Team Drive.
  --orgUnitId: string # The organizational unit of this shared drive. This field is only populated on drives.list responses when the useDomainAdminAccess parameter is set to true.
  --restrictions: record # A set of restrictions that apply to this Team Drive or items inside this Team Drive. — shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool, teamMembersOnly?: bool}
  --themeId: string # The ID of the theme from which the background image and color will be set. The set of possible teamDriveThemes can be retrieved from a drive.about.get response. When not specified on a drive.teamdrives.create request, a random theme is chosen from which the background image and color are set. This is a write-only field; it can only be set on requests that don't set colorRgb or backgroundImageFile.
]: any -> record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canChangeTeamDriveBackground: bool, canChangeTeamMembersOnlyRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteTeamDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRemoveChildren: bool, canRename: bool, canRenameTeamDrive: bool, canResetTeamDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool, teamMembersOnly: bool>, themeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "useDomainAdminAccess" $useDomainAdminAccess "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teamdrives/($teamDriveId)" $qp)
  let body = {backgroundImageFile: $backgroundImageFile, backgroundImageLink: $backgroundImageLink, capabilities: $capabilities, colorRgb: $colorRgb, createdTime: $createdTime, id: $id, kind: $kind, name: $name, orgUnitId: $orgUnitId, restrictions: $restrictions, themeId: $themeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
