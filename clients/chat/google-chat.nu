# Auto-generated client for Google Chat API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/chat/v1/openapi.json
# Auth: --token flag or $env.GOOGLE_CHAT_API_TOKEN

const BASE_URL = "https://chat.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOOGLE_CHAT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://chat.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def messageReplyOption-completer [] { ["MESSAGE_REPLY_OPTION_UNSPECIFIED" "REPLY_MESSAGE_FALLBACK_TO_NEW_THREAD" "REPLY_MESSAGE_OR_FAIL"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "media chatmediadownload" } } | get name | first)
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

# Downloads media. Download is supported on the URI `/v1/media/{+name}?alt=media`.
#
# GET /v1/media/{resourceName}
# operationId: chat.media.download
export def "media chatmediadownload" [
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<resourceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/media/($resourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists spaces the caller is a member of. Requires [authentication](https://developers.google.com/chat/api/guides/auth). Fully supports [service account authentication](https://developers.google.com/chat/api/guides/auth/service-accounts). Supports [user authentication](https://developers.google.com/chat/api/guides/auth/users) as part of the [Google Workspace Developer Preview Program](https://developers.google.com/workspace/preview), which grants early access to certain features. [User authentication](https://developers.google.com/chat/api/guides/auth/users) requires the `chat.spaces` or `chat.spaces.readonly` authorization scope. Lists spaces visible to the caller or authenticated user. Group chats and DMs aren't listed until the first message is sent.
#
# GET /v1/spaces
# operationId: chat.spaces.list
export def "spaces chatspaceslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Optional. The maximum number of spaces to return. The service may return fewer than this value. If unspecified, at most 100 spaces are returned. The maximum value is 1000; values above 1000 are coerced to 1000. Negative values return an `INVALID_ARGUMENT` error.
  --pageToken: string # Optional. A page token, received from a previous list spaces call. Provide this to retrieve the subsequent page. When paginating, the filter value should match the call that provided the page token. Passing a different value may lead to unexpected results.
]: nothing -> record<nextPageToken: string, spaces: table<adminInstalled: bool, displayName: string, name: string, singleUserBotDm: bool, spaceDetails: record, spaceThreadingState: string, threaded: bool, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/spaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a message. For example usage, see [Delete a message](https://developers.google.com/chat/api/guides/crudl/messages#delete_a_message). Requires [authentication](https://developers.google.com/chat/api/guides/auth). Fully supports [service account authentication](https://developers.google.com/chat/api/guides/auth/service-accounts). Supports [user authentication](https://developers.google.com/chat/api/guides/auth/users) as part of the [Google Workspace Developer Preview Program](https://developers.google.com/workspace/preview), which grants early access to certain features. [User authentication](https://developers.google.com/chat/api/guides/auth/users) requires the `chat.messages` authorization scope.
#
# DELETE /v1/{name}
# operationId: chat.spaces.messages.delete
export def "spaces chatspacesmessagesdelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the metadata of a message attachment. The attachment data is fetched using the [media API](https://developers.google.com/chat/api/reference/rest/v1/media/download). Requires [service account authentication](https://developers.google.com/chat/api/guides/auth/service-accounts).
#
# GET /v1/{name}
# operationId: chat.spaces.messages.attachments.get
export def "spaces chatspacesmessagesattachmentsget" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<attachmentDataRef: record<resourceName: string>, contentName: string, contentType: string, downloadUri: string, driveDataRef: record<driveFileId: string>, name: string, source: string, thumbnailUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a message. There's a difference between `patch` and `update` methods. The `patch` method uses a `patch` request while the `update` method uses a `put` request. We recommend using the `patch` method. For example usage, see [Update a message](https://developers.google.com/chat/api/guides/crudl/messages#update_a_message). Requires [authentication](https://developers.google.com/chat/api/guides/auth/). Fully supports [service account authentication](https://developers.google.com/chat/api/guides/auth/service-accounts). Supports [user authentication](https://developers.google.com/chat/api/guides/auth/users) as part of the [Google Workspace Developer Preview Program](https://developers.google.com/workspace/preview), which grants early access to certain features. [User authentication](https://developers.google.com/chat/api/guides/auth/users) requires the `chat.messages` authorization scope.
#
# PATCH /v1/{name}
# operationId: chat.spaces.messages.patch
# --actionResponse shape: {dialogAction?: record, type?: "TYPE_UNSPECIFIED"|"NEW_MESSAGE"|"UPDATE_MESSAGE"|"UPDATE_USER_MESSAGE_CARDS"|"REQUEST_CONFIG"|"DIALOG", url?: string}
# --annotations item shape: {length?: int, slashCommand?: record, startIndex?: int, type?: "ANNOTATION_TYPE_UNSPECIFIED"|"USER_MENTION"|"SLASH_COMMAND", userMention?: record}
# --attachment item shape: {attachmentDataRef?: record, contentName?: string, contentType?: string, driveDataRef?: record, name?: string, source?: "SOURCE_UNSPECIFIED"|"DRIVE_FILE"|"UPLOADED_CONTENT"}
# --cards item shape: {cardActions?: list, header?: record, name?: string, sections?: list}
# --cardsV2 item shape: {card?: record, cardId?: string}
# --sender shape: {domainId?: string, name?: string, type?: "TYPE_UNSPECIFIED"|"HUMAN"|"BOT"}
# --slashCommand shape: {commandId?: string}
# --space shape: {displayName?: string, name?: string, singleUserBotDm?: bool, spaceDetails?: record}
# --thread shape: {name?: string, threadKey?: string}
export def "spaces chatspacesmessagespatch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allowMissing: oneof<nothing, bool> # Optional. If `true` and the message is not found, a new message is created and `updateMask` is ignored. The specified message ID must be [client-assigned](https://developers.google.com/chat/api/guides/crudl/messages#name_a_created_message) or the request fails.
  --updateMask: string # Required. The field paths to update. Separate multiple values with commas. Currently supported field paths: - text - cards (Requires [service account authentication](/chat/api/guides/auth/service-accounts).) - cards_v2 
  --actionResponse: record # Parameters that a Chat app can use to configure how its response is posted. — shape: {dialogAction?: record, type?: "TYPE_UNSPECIFIED"|"NEW_MESSAGE"|"UPDATE_MESSAGE"|"UPDATE_USER_MESSAGE_CARDS"|"REQUEST_CONFIG"|"DIALOG", url?: string}
  --attachment: list # User-uploaded attachment. — item shape: {attachmentDataRef?: record, contentName?: string, contentType?: string, driveDataRef?: record, name?: string, source?: "SOURCE_UNSPECIFIED"|"DRIVE_FILE"|"UPLOADED_CONTENT"}
  --cards: list # Deprecated: Use `cards_v2` instead. Rich, formatted and interactive cards that can be used to display UI elements such as: formatted texts, buttons, clickable images. Cards are normally displayed below the plain-text body of the message. `cards` and `cards_v2` can have a maximum size of 32 KB. — item shape: {cardActions?: list, header?: record, name?: string, sections?: list}
  --cardsV2: list # Richly formatted and interactive cards that display UI elements and editable widgets, such as: - Formatted text - Buttons - Clickable images - Checkboxes - Radio buttons - Input widgets. Cards are usually displayed below the text body of a Chat message, but can situationally appear other places, such as [dialogs](https://developers.google.com/chat/how-tos/dialogs). Each card can have a maximum size of 32 KB. The `cardId` is a unique identifier among cards in the same message and for identifying user input values. Currently supported widgets include: - `TextParagraph` - `DecoratedText` - `Image` - `ButtonList` - `Divider` - `TextInput` - `SelectionInput` - `Grid` — item shape: {card?: record, cardId?: string}
  --clientAssignedMessageId: string # A custom name for a Chat message assigned at creation. Must start with `client-` and contain only lowercase letters, numbers, and hyphens up to 63 characters in length. Specify this field to get, update, or delete the message with the specified value. For example usage, see [Name a created message](https://developers.google.com/chat/api/guides/crudl/messages#name_a_created_message).
  --fallbackText: string # A plain-text description of the message's cards, used when the actual cards cannot be displayed (e.g. mobile notifications).
  --matchedUrl: record # A matched url in a Chat message. Chat apps can preview matched URLs. For more information, refer to [Preview links](https://developers.google.com/chat/how-tos/preview-links).
  --body-name: string # Resource name in the form `spaces/*/messages/*`. Example: `spaces/AAAAAAAAAAA/messages/BBBBBBBBBBB.BBBBBBBBBBB`
  --sender: record # A user in Google Chat. — shape: {domainId?: string, name?: string, type?: "TYPE_UNSPECIFIED"|"HUMAN"|"BOT"}
  --slashCommand: record # A [slash command](https://developers.google.com/chat/how-tos/slash-commands) in Google Chat. — shape: {commandId?: string}
  --space: record # A space in Google Chat. Spaces are conversations between two or more users or 1:1 messages between a user and a Chat app. — shape: {displayName?: string, name?: string, singleUserBotDm?: bool, spaceDetails?: record}
  --text: string # Plain-text body of the message. The first link to an image, video, web page, or other preview-able item generates a preview chip.
  --thread: record # A thread in Google Chat. — shape: {name?: string, threadKey?: string}
]: any -> record<actionResponse: record<dialogAction: record<actionStatus: record, dialog: record>, type: string, url: string>, annotations: table<length: int, slashCommand: record, startIndex: int, type: string, userMention: record>, argumentText: string, attachment: table<attachmentDataRef: record, contentName: string, contentType: string, downloadUri: string, driveDataRef: record, name: string, source: string, thumbnailUri: string>, cards: table<cardActions: list, header: record, name: string, sections: list>, cardsV2: table<card: record, cardId: string>, clientAssignedMessageId: string, createTime: string, fallbackText: string, lastUpdateTime: string, matchedUrl: record<url: string>, name: string, sender: record<displayName: string, domainId: string, isAnonymous: bool, name: string, type: string>, slashCommand: record<commandId: string>, space: record<adminInstalled: bool, displayName: string, name: string, singleUserBotDm: bool, spaceDetails: record<description: string, guidelines: string>, spaceThreadingState: string, threaded: bool, type: string>, text: string, thread: record<name: string, threadKey: string>, threadReply: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "allowMissing" $allowMissing "scalar") (serialize-qp "updateMask" $updateMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let body = {actionResponse: $actionResponse, attachment: $attachment, cards: $cards, cardsV2: $cardsV2, clientAssignedMessageId: $clientAssignedMessageId, fallbackText: $fallbackText, matchedUrl: $matchedUrl, name: $body_name, sender: $sender, slashCommand: $slashCommand, space: $space, text: $text, thread: $thread} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a message. There's a difference between `patch` and `update` methods. The `patch` method uses a `patch` request while the `update` method uses a `put` request. We recommend using the `patch` method. For example usage, see [Update a message](https://developers.google.com/chat/api/guides/crudl/messages#update_a_message). Requires [authentication](https://developers.google.com/chat/api/guides/auth/). Fully supports [service account authentication](https://developers.google.com/chat/api/guides/auth/service-accounts). Supports [user authentication](https://developers.google.com/chat/api/guides/auth/users) as part of the [Google Workspace Developer Preview Program](https://developers.google.com/workspace/preview), which grants early access to certain features. [User authentication](https://developers.google.com/chat/api/guides/auth/users) requires the `chat.messages` authorization scope.
#
# PUT /v1/{name}
# operationId: chat.spaces.messages.update
# --actionResponse shape: {dialogAction?: record, type?: "TYPE_UNSPECIFIED"|"NEW_MESSAGE"|"UPDATE_MESSAGE"|"UPDATE_USER_MESSAGE_CARDS"|"REQUEST_CONFIG"|"DIALOG", url?: string}
# --annotations item shape: {length?: int, slashCommand?: record, startIndex?: int, type?: "ANNOTATION_TYPE_UNSPECIFIED"|"USER_MENTION"|"SLASH_COMMAND", userMention?: record}
# --attachment item shape: {attachmentDataRef?: record, contentName?: string, contentType?: string, driveDataRef?: record, name?: string, source?: "SOURCE_UNSPECIFIED"|"DRIVE_FILE"|"UPLOADED_CONTENT"}
# --cards item shape: {cardActions?: list, header?: record, name?: string, sections?: list}
# --cardsV2 item shape: {card?: record, cardId?: string}
# --sender shape: {domainId?: string, name?: string, type?: "TYPE_UNSPECIFIED"|"HUMAN"|"BOT"}
# --slashCommand shape: {commandId?: string}
# --space shape: {displayName?: string, name?: string, singleUserBotDm?: bool, spaceDetails?: record}
# --thread shape: {name?: string, threadKey?: string}
export def "spaces chatspacesmessagesupdate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allowMissing: oneof<nothing, bool> # Optional. If `true` and the message is not found, a new message is created and `updateMask` is ignored. The specified message ID must be [client-assigned](https://developers.google.com/chat/api/guides/crudl/messages#name_a_created_message) or the request fails.
  --updateMask: string # Required. The field paths to update. Separate multiple values with commas. Currently supported field paths: - text - cards (Requires [service account authentication](/chat/api/guides/auth/service-accounts).) - cards_v2 
  --actionResponse: record # Parameters that a Chat app can use to configure how its response is posted. — shape: {dialogAction?: record, type?: "TYPE_UNSPECIFIED"|"NEW_MESSAGE"|"UPDATE_MESSAGE"|"UPDATE_USER_MESSAGE_CARDS"|"REQUEST_CONFIG"|"DIALOG", url?: string}
  --attachment: list # User-uploaded attachment. — item shape: {attachmentDataRef?: record, contentName?: string, contentType?: string, driveDataRef?: record, name?: string, source?: "SOURCE_UNSPECIFIED"|"DRIVE_FILE"|"UPLOADED_CONTENT"}
  --cards: list # Deprecated: Use `cards_v2` instead. Rich, formatted and interactive cards that can be used to display UI elements such as: formatted texts, buttons, clickable images. Cards are normally displayed below the plain-text body of the message. `cards` and `cards_v2` can have a maximum size of 32 KB. — item shape: {cardActions?: list, header?: record, name?: string, sections?: list}
  --cardsV2: list # Richly formatted and interactive cards that display UI elements and editable widgets, such as: - Formatted text - Buttons - Clickable images - Checkboxes - Radio buttons - Input widgets. Cards are usually displayed below the text body of a Chat message, but can situationally appear other places, such as [dialogs](https://developers.google.com/chat/how-tos/dialogs). Each card can have a maximum size of 32 KB. The `cardId` is a unique identifier among cards in the same message and for identifying user input values. Currently supported widgets include: - `TextParagraph` - `DecoratedText` - `Image` - `ButtonList` - `Divider` - `TextInput` - `SelectionInput` - `Grid` — item shape: {card?: record, cardId?: string}
  --clientAssignedMessageId: string # A custom name for a Chat message assigned at creation. Must start with `client-` and contain only lowercase letters, numbers, and hyphens up to 63 characters in length. Specify this field to get, update, or delete the message with the specified value. For example usage, see [Name a created message](https://developers.google.com/chat/api/guides/crudl/messages#name_a_created_message).
  --fallbackText: string # A plain-text description of the message's cards, used when the actual cards cannot be displayed (e.g. mobile notifications).
  --matchedUrl: record # A matched url in a Chat message. Chat apps can preview matched URLs. For more information, refer to [Preview links](https://developers.google.com/chat/how-tos/preview-links).
  --body-name: string # Resource name in the form `spaces/*/messages/*`. Example: `spaces/AAAAAAAAAAA/messages/BBBBBBBBBBB.BBBBBBBBBBB`
  --sender: record # A user in Google Chat. — shape: {domainId?: string, name?: string, type?: "TYPE_UNSPECIFIED"|"HUMAN"|"BOT"}
  --slashCommand: record # A [slash command](https://developers.google.com/chat/how-tos/slash-commands) in Google Chat. — shape: {commandId?: string}
  --space: record # A space in Google Chat. Spaces are conversations between two or more users or 1:1 messages between a user and a Chat app. — shape: {displayName?: string, name?: string, singleUserBotDm?: bool, spaceDetails?: record}
  --text: string # Plain-text body of the message. The first link to an image, video, web page, or other preview-able item generates a preview chip.
  --thread: record # A thread in Google Chat. — shape: {name?: string, threadKey?: string}
]: any -> record<actionResponse: record<dialogAction: record<actionStatus: record, dialog: record>, type: string, url: string>, annotations: table<length: int, slashCommand: record, startIndex: int, type: string, userMention: record>, argumentText: string, attachment: table<attachmentDataRef: record, contentName: string, contentType: string, downloadUri: string, driveDataRef: record, name: string, source: string, thumbnailUri: string>, cards: table<cardActions: list, header: record, name: string, sections: list>, cardsV2: table<card: record, cardId: string>, clientAssignedMessageId: string, createTime: string, fallbackText: string, lastUpdateTime: string, matchedUrl: record<url: string>, name: string, sender: record<displayName: string, domainId: string, isAnonymous: bool, name: string, type: string>, slashCommand: record<commandId: string>, space: record<adminInstalled: bool, displayName: string, name: string, singleUserBotDm: bool, spaceDetails: record<description: string, guidelines: string>, spaceThreadingState: string, threaded: bool, type: string>, text: string, thread: record<name: string, threadKey: string>, threadReply: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "allowMissing" $allowMissing "scalar") (serialize-qp "updateMask" $updateMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let body = {actionResponse: $actionResponse, attachment: $attachment, cards: $cards, cardsV2: $cardsV2, clientAssignedMessageId: $clientAssignedMessageId, fallbackText: $fallbackText, matchedUrl: $matchedUrl, name: $body_name, sender: $sender, slashCommand: $slashCommand, space: $space, text: $text, thread: $thread} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists memberships in a space. Requires [authentication](https://developers.google.com/chat/api/guides/auth/). Fully supports [service account authentication](https://developers.google.com/chat/api/guides/auth/service-accounts). Supports [user authentication](https://developers.google.com/chat/api/guides/auth/users) as part of the [Google Workspace Developer Preview Program](https://developers.google.com/workspace/preview), which grants early access to certain features. [User authentication](https://developers.google.com/chat/api/guides/auth/users) requires the `chat.memberships` or `chat.memberships.readonly` authorization scope.
#
# GET /v1/{parent}/members
# operationId: chat.spaces.members.list
export def "members chatspacesmemberslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # The maximum number of memberships to return. The service may return fewer than this value. If unspecified, at most 100 memberships are returned. The maximum value is 1000; values above 1000 are coerced to 1000. Negative values return an INVALID_ARGUMENT error.
  --pageToken: string # A page token, received from a previous call to list memberships. Provide this to retrieve the subsequent page. When paginating, all other parameters provided should match the call that provided the page token. Passing different values to the other parameters may lead to unexpected results.
]: nothing -> record<memberships: table<createTime: string, member: record, name: string, role: string, state: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a message. For example usage, see [Create a message](https://developers.google.com/chat/api/guides/crudl/messages#create_a_message). Requires [authentication](https://developers.google.com/chat/api/guides/auth). Fully supports [service account authentication](https://developers.google.com/chat/api/guides/auth/service-accounts). Supports [user authentication](https://developers.google.com/chat/api/guides/auth/users) as part of the [Google Workspace Developer Preview Program](https://developers.google.com/workspace/preview), which grants early access to certain features. [User authentication](https://developers.google.com/chat/api/guides/auth/users) requires the `chat.messages` or `chat.messages.create` authorization scope. Because Chat provides authentication for [webhooks](https://developers.google.com/chat/how-tos/webhooks) as part of the URL that's generated when a webhook is registered, webhooks can create messages without a service account or user authentication.
#
# POST /v1/{parent}/messages
# operationId: chat.spaces.messages.create
# --actionResponse shape: {dialogAction?: record, type?: "TYPE_UNSPECIFIED"|"NEW_MESSAGE"|"UPDATE_MESSAGE"|"UPDATE_USER_MESSAGE_CARDS"|"REQUEST_CONFIG"|"DIALOG", url?: string}
# --annotations item shape: {length?: int, slashCommand?: record, startIndex?: int, type?: "ANNOTATION_TYPE_UNSPECIFIED"|"USER_MENTION"|"SLASH_COMMAND", userMention?: record}
# --attachment item shape: {attachmentDataRef?: record, contentName?: string, contentType?: string, driveDataRef?: record, name?: string, source?: "SOURCE_UNSPECIFIED"|"DRIVE_FILE"|"UPLOADED_CONTENT"}
# --cards item shape: {cardActions?: list, header?: record, name?: string, sections?: list}
# --cardsV2 item shape: {card?: record, cardId?: string}
# --sender shape: {domainId?: string, name?: string, type?: "TYPE_UNSPECIFIED"|"HUMAN"|"BOT"}
# --slashCommand shape: {commandId?: string}
# --space shape: {displayName?: string, name?: string, singleUserBotDm?: bool, spaceDetails?: record}
# --thread shape: {name?: string, threadKey?: string}
export def "messages chatspacesmessagescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --messageId: string # Optional. A custom name for a Chat message assigned at creation. Must start with `client-` and contain only lowercase letters, numbers, and hyphens up to 63 characters in length. Specify this field to get, update, or delete the message with the specified value. For example usage, see [Name a created message](https://developers.google.com/chat/api/guides/crudl/messages#name_a_created_message).
  --messageReplyOption: string@messageReplyOption-completer # Optional. Specifies whether a message starts a thread or replies to one. Only supported in named spaces.
  --requestId: string # Optional. A unique request ID for this message. Specifying an existing request ID returns the message created with that ID instead of creating a new message.
  --threadKey: string # Optional. Deprecated: Use thread.thread_key instead. Opaque thread identifier. To start or add to a thread, create a message and specify a `threadKey` or the thread.name. For example usage, see [Start or reply to a message thread](https://developers.google.com/chat/api/guides/crudl/messages#start_or_reply_to_a_message_thread).
  --actionResponse: record # Parameters that a Chat app can use to configure how its response is posted. — shape: {dialogAction?: record, type?: "TYPE_UNSPECIFIED"|"NEW_MESSAGE"|"UPDATE_MESSAGE"|"UPDATE_USER_MESSAGE_CARDS"|"REQUEST_CONFIG"|"DIALOG", url?: string}
  --attachment: list # User-uploaded attachment. — item shape: {attachmentDataRef?: record, contentName?: string, contentType?: string, driveDataRef?: record, name?: string, source?: "SOURCE_UNSPECIFIED"|"DRIVE_FILE"|"UPLOADED_CONTENT"}
  --cards: list # Deprecated: Use `cards_v2` instead. Rich, formatted and interactive cards that can be used to display UI elements such as: formatted texts, buttons, clickable images. Cards are normally displayed below the plain-text body of the message. `cards` and `cards_v2` can have a maximum size of 32 KB. — item shape: {cardActions?: list, header?: record, name?: string, sections?: list}
  --cardsV2: list # Richly formatted and interactive cards that display UI elements and editable widgets, such as: - Formatted text - Buttons - Clickable images - Checkboxes - Radio buttons - Input widgets. Cards are usually displayed below the text body of a Chat message, but can situationally appear other places, such as [dialogs](https://developers.google.com/chat/how-tos/dialogs). Each card can have a maximum size of 32 KB. The `cardId` is a unique identifier among cards in the same message and for identifying user input values. Currently supported widgets include: - `TextParagraph` - `DecoratedText` - `Image` - `ButtonList` - `Divider` - `TextInput` - `SelectionInput` - `Grid` — item shape: {card?: record, cardId?: string}
  --clientAssignedMessageId: string # A custom name for a Chat message assigned at creation. Must start with `client-` and contain only lowercase letters, numbers, and hyphens up to 63 characters in length. Specify this field to get, update, or delete the message with the specified value. For example usage, see [Name a created message](https://developers.google.com/chat/api/guides/crudl/messages#name_a_created_message).
  --fallbackText: string # A plain-text description of the message's cards, used when the actual cards cannot be displayed (e.g. mobile notifications).
  --matchedUrl: record # A matched url in a Chat message. Chat apps can preview matched URLs. For more information, refer to [Preview links](https://developers.google.com/chat/how-tos/preview-links).
  --name: string # Resource name in the form `spaces/*/messages/*`. Example: `spaces/AAAAAAAAAAA/messages/BBBBBBBBBBB.BBBBBBBBBBB`
  --sender: record # A user in Google Chat. — shape: {domainId?: string, name?: string, type?: "TYPE_UNSPECIFIED"|"HUMAN"|"BOT"}
  --slashCommand: record # A [slash command](https://developers.google.com/chat/how-tos/slash-commands) in Google Chat. — shape: {commandId?: string}
  --space: record # A space in Google Chat. Spaces are conversations between two or more users or 1:1 messages between a user and a Chat app. — shape: {displayName?: string, name?: string, singleUserBotDm?: bool, spaceDetails?: record}
  --text: string # Plain-text body of the message. The first link to an image, video, web page, or other preview-able item generates a preview chip.
  --thread: record # A thread in Google Chat. — shape: {name?: string, threadKey?: string}
]: any -> record<actionResponse: record<dialogAction: record<actionStatus: record, dialog: record>, type: string, url: string>, annotations: table<length: int, slashCommand: record, startIndex: int, type: string, userMention: record>, argumentText: string, attachment: table<attachmentDataRef: record, contentName: string, contentType: string, downloadUri: string, driveDataRef: record, name: string, source: string, thumbnailUri: string>, cards: table<cardActions: list, header: record, name: string, sections: list>, cardsV2: table<card: record, cardId: string>, clientAssignedMessageId: string, createTime: string, fallbackText: string, lastUpdateTime: string, matchedUrl: record<url: string>, name: string, sender: record<displayName: string, domainId: string, isAnonymous: bool, name: string, type: string>, slashCommand: record<commandId: string>, space: record<adminInstalled: bool, displayName: string, name: string, singleUserBotDm: bool, spaceDetails: record<description: string, guidelines: string>, spaceThreadingState: string, threaded: bool, type: string>, text: string, thread: record<name: string, threadKey: string>, threadReply: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "messageId" $messageId "scalar") (serialize-qp "messageReplyOption" $messageReplyOption "scalar") (serialize-qp "requestId" $requestId "scalar") (serialize-qp "threadKey" $threadKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/messages" $qp)
  let body = {actionResponse: $actionResponse, attachment: $attachment, cards: $cards, cardsV2: $cardsV2, clientAssignedMessageId: $clientAssignedMessageId, fallbackText: $fallbackText, matchedUrl: $matchedUrl, name: $name, sender: $sender, slashCommand: $slashCommand, space: $space, text: $text, thread: $thread} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
