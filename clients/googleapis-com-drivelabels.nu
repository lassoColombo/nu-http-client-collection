# Auto-generated client for Drive Labels API vv2beta
# Source: https://api.apis.guru/v2/specs/googleapis.com/drivelabels/v2beta/openapi.json
# Auth: --token flag or $env.DRIVE_LABELS_API_TOKEN

const BASE_URL = "https://drivelabels.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DRIVE_LABELS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://drivelabels.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def minimum-role-completer [] { ["APPLIER" "EDITOR" "LABEL_ROLE_UNSPECIFIED" "ORGANIZER" "READER"] }
def view-completer [] { ["LABEL_VIEW_BASIC" "LABEL_VIEW_FULL"] }
def label-type-completer [] { ["ADMIN" "LABEL_TYPE_UNSPECIFIED" "SHARED"] }
def copy-mode-completer [] { ["ALWAYS_COPY" "COPY_APPLIABLE" "COPY_MODE_UNSPECIFIED" "DO_NOT_COPY"] }
def role-completer [] { ["APPLIER" "EDITOR" "LABEL_ROLE_UNSPECIFIED" "ORGANIZER" "READER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v2beta-labels list" } } | get name | first)
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

# List labels.
#
# GET /v2beta/labels
# operationId: drivelabels.labels.list
export def "v2beta-labels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --customer: string # The customer to scope this list request to. For example: "customers/abcd1234". If unset, will return all labels within the current customer.
  --language-code: string # The BCP-47 language code to use for evaluating localized field labels. When not specified, values in the default configured language are used.
  --minimum-role: string@minimum-role-completer # Specifies the level of access the user must have on the returned Labels. The minimum role a user must have on a label. Defaults to `READER`.
  --page-size: int # Maximum number of labels to return per page. Default: 50. Max: 200.
  --page-token: string # The token of the page to return.
  --published-only: oneof<nothing, bool> # Whether to include only published labels in the results. * When `true`, only the current published label revisions are returned. Disabled labels are included. Returned label resource names reference the published revision (`labels/{id}/{revision_id}`). * When `false`, the current label revisions are returned, which might not be published. Returned label resource names don't reference a specific revision (`labels/{id}`).
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. This will return all Labels within the customer.
  --view: string@view-completer # When specified, only certain fields belonging to the indicated view are returned.
]: nothing -> record<labels: table<appliedCapabilities: record, appliedLabelPolicy: record, createTime: string, creator: record, customer: string, disableTime: string, disabler: record, displayHints: record, fields: list, id: string, labelType: string, learnMoreUri: string, lifecycle: record, lockStatus: record, name: string, properties: record, publishTime: string, publisher: record, revisionCreateTime: string, revisionCreator: record, revisionId: string, schemaCapabilities: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "customer" $customer "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "minimumRole" $minimum_role "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "publishedOnly" $published_only "scalar") (serialize-qp "useAdminAccess" $use_admin_access "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2beta/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a new Label.
#
# POST /v2beta/labels
# operationId: drivelabels.labels.create
# --appliedCapabilities shape: {canApply?: bool, canRead?: bool, canRemove?: bool}
# --appliedLabelPolicy shape: {copyMode?: "COPY_MODE_UNSPECIFIED"|"DO_NOT_COPY"|"ALWAYS_COPY"|"COPY_APPLIABLE"}
# --creator shape: {person?: string}
# --disabler shape: {person?: string}
# --displayHints shape: {disabled?: bool, hiddenInSearch?: bool, priority?: string, shownInApply?: bool}
# --fields item shape: {appliedCapabilities?: record, creator?: record, dateOptions?: record, disabler?: record, displayHints?: record, integerOptions?: record, lifecycle?: record, lockStatus?: record, properties?: record, publisher?: record, schemaCapabilities?: record, selectionOptions?: record, textOptions?: record, updater?: record, userOptions?: record}
# --lifecycle shape: {disabledPolicy?: record}
# --properties shape: {description?: string, title?: string}
# --publisher shape: {person?: string}
# --revisionCreator shape: {person?: string}
# --schemaCapabilities shape: {canDelete?: bool, canDisable?: bool, canEnable?: bool, canUpdate?: bool}
export def "v2beta-labels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response. — item shape: {appliedCapabilities?: record, creator?: record, dateOptions?: record, disabler?: record, displayHints?: record, integerOptions?: record, lifecycle?: record, lockStatus?: record, properties?: record, publisher?: record, schemaCapabilities?: record, selectionOptions?: record, textOptions?: record, updater?: record, userOptions?: record}
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --language-code: string # The BCP-47 language code to use for evaluating localized Field labels in response. When not specified, values in the default configured language will be used.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin privileges. The server will verify the user is an admin before allowing access.
  --applied-capabilities: record # The capabilities a user has on this label's applied metadata. — shape: {canApply?: bool, canRead?: bool, canRemove?: bool}
  --applied-label-policy: record # Behavior of this label when it's applied to Drive items. — shape: {copyMode?: "COPY_MODE_UNSPECIFIED"|"DO_NOT_COPY"|"ALWAYS_COPY"|"COPY_APPLIABLE"}
  --creator: record # Information about a user. — shape: {person?: string}
  --disabler: record # Information about a user. — shape: {person?: string}
  --display-hints: record # UI display hints for rendering the label. — shape: {disabled?: bool, hiddenInSearch?: bool, priority?: string, shownInApply?: bool}
  --fields: list # List of fields in descending priority order. — item shape: {appliedCapabilities?: record, creator?: record, dateOptions?: record, disabler?: record, displayHints?: record, integerOptions?: record, lifecycle?: record, lockStatus?: record, properties?: record, publisher?: record, schemaCapabilities?: record, selectionOptions?: record, textOptions?: record, updater?: record, userOptions?: record}
  --label-type: string@label-type-completer # Required. The type of label.
  --learn-more-uri: string # Custom URL to present to users to allow them to learn more about this label and how it should be used.
  --lifecycle: record # The lifecycle state of an object, such as label, field, or choice. The lifecycle enforces the following transitions: * `UNPUBLISHED_DRAFT` (starting state) * `UNPUBLISHED_DRAFT` -> `PUBLISHED` * `UNPUBLISHED_DRAFT` -> (Deleted) * `PUBLISHED` -> `DISABLED` * `DISABLED` -> `PUBLISHED` * `DISABLED` -> (Deleted) The published and disabled states have some distinct characteristics: * Published—Some kinds of changes might be made to an object in this state, in which case `has_unpublished_changes` will be true. Also, some kinds of changes are not permitted. Generally, any change that would invalidate or cause new restrictions on existing metadata related to the label are rejected. * Disabled—When disabled, the configured `DisabledPolicy` takes effect. — shape: {disabledPolicy?: record}
  --lock-status: record # Contains information about whether a label component should be considered locked.
  --properties: record # Basic properties of the label. — shape: {description?: string, title?: string}
  --publisher: record # Information about a user. — shape: {person?: string}
  --revision-creator: record # Information about a user. — shape: {person?: string}
  --schema-capabilities: record # The capabilities related to this label when editing the label. — shape: {canDelete?: bool, canDisable?: bool, canEnable?: bool, canUpdate?: bool}
]: any -> record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "useAdminAccess" $use_admin_access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2beta/labels" $qp)
  let req_body = {"appliedCapabilities": $applied_capabilities, "appliedLabelPolicy": $applied_label_policy, "creator": $creator, "disabler": $disabler, "displayHints": $display_hints, "fields": $fields, "labelType": $label_type, "learnMoreUri": $learn_more_uri, "lifecycle": $lifecycle, "lockStatus": $lock_status, "properties": $properties, "publisher": $publisher, "revisionCreator": $revision_creator, "schemaCapabilities": $schema_capabilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get the constraints on the structure of a Label; such as, the maximum number of Fields allowed and maximum length of the label title.
#
# GET /v2beta/limits/label
# operationId: drivelabels.limits.getLabel
export def "v2beta-limits-label get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # Required. Label revision resource name Must be: "limits/label"
]: nothing -> record<fieldLimits: record<dateLimits: record<maxValue: record, minValue: record>, integerLimits: record<maxValue: string, minValue: string>, longTextLimits: record<maxLength: int, minLength: int>, maxDescriptionLength: int, maxDisplayNameLength: int, maxIdLength: int, selectionLimits: record<listLimits: record, maxChoices: int, maxDeletedChoices: int, maxDisplayNameLength: int, maxIdLength: int>, textLimits: record<maxLength: int, minLength: int>, userLimits: record<listLimits: record>>, maxDeletedFields: int, maxDescriptionLength: int, maxDraftRevisions: int, maxFields: int, maxTitleLength: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2beta/limits/label" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a Label's permission. Permissions affect the Label resource as a whole, are not revisioned, and do not require publishing.
#
# DELETE /v2beta/{name}
# operationId: drivelabels.labels.revisions.permissions.delete
export def "v2beta delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --write-control-required-revision-id: string # The revision_id of the label that the write request will be applied to. If this is not the latest revision of the label, the request will not be processed and will return a 400 Bad Request error.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "useAdminAccess" $use_admin_access "scalar") (serialize-qp "writeControl.requiredRevisionId" $write_control_required_revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2beta/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the user capabilities.
#
# GET /v2beta/{name}
# operationId: drivelabels.users.getCapabilities
export def "v2beta get-capabilities" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --customer: string # The customer to scope this request to. For example: "customers/abcd1234". If unset, will return settings within the current customer.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server verifies that the user is an admin for the label before allowing access.
  --view: string@view-completer # When specified, only certain fields belonging to the indicated view are returned.
]: nothing -> record<canAccessLabelManager: bool, canAdministrateLabels: bool, canCreateAdminLabels: bool, canCreateSharedLabels: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "customer" $customer "scalar") (serialize-qp "useAdminAccess" $use_admin_access "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2beta/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a single Label by applying a set of update requests resulting in a new draft revision. The batch update is all-or-nothing: If any of the update requests are invalid, no changes are applied. The resulting draft revision must be published before the changes may be used with Drive Items.
#
# POST /v2beta/{name}:delta
# operationId: drivelabels.labels.delta
# --requests item shape: {createField?: record, createSelectionChoice?: record, deleteField?: record, deleteSelectionChoice?: record, disableField?: record, disableSelectionChoice?: record, enableField?: record, enableSelectionChoice?: record, updateField?: record, updateFieldType?: record, updateLabel?: record, updateSelectionChoiceProperties?: record}
# --writeControl shape: {requiredRevisionId?: string}
export def "v2beta create-delta" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --language-code: string # The BCP-47 language code to use for evaluating localized Field labels when `include_label_in_response` is `true`.
  --requests: list # A list of updates to apply to the Label. Requests will be applied in the order they are specified. — item shape: {createField?: record, createSelectionChoice?: record, deleteField?: record, deleteSelectionChoice?: record, disableField?: record, disableSelectionChoice?: record, enableField?: record, enableSelectionChoice?: record, updateField?: record, updateFieldType?: record, updateLabel?: record, updateSelectionChoiceProperties?: record}
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --view: string@view-completer # When specified, only certain fields belonging to the indicated view will be returned.
  --write-control: record # Provides control over how write requests are executed. When not specified, the last write wins. — shape: {requiredRevisionId?: string}
]: any -> record<responses: table<createField: record, createSelectionChoice: record, deleteField: record, deleteSelectionChoice: record, disableField: record, disableSelectionChoice: record, enableField: record, enableSelectionChoice: record, updateField: record, updateFieldType: record, updateLabel: record, updateSelectionChoiceProperties: record>, updatedLabel: record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: list<record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2beta/{name}:delta") $qp)
  let req_body = {"languageCode": $language_code, "requests": $requests, "useAdminAccess": $use_admin_access, "view": $view, "writeControl": $write_control} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Disable a published Label. Disabling a Label will result in a new disabled published revision based on the current published revision. If there is a draft revision, a new disabled draft revision will be created based on the latest draft revision. Older draft revisions will be deleted. Once disabled, a label may be deleted with `DeleteLabel`.
#
# POST /v2beta/{name}:disable
# operationId: drivelabels.labels.disable
# --disabledPolicy shape: {hideInSearch?: bool, showInApply?: bool}
# --writeControl shape: {requiredRevisionId?: string}
export def "v2beta disable" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --disabled-policy: record # The policy that governs how to treat a disabled label, field, or selection choice in different contexts. — shape: {hideInSearch?: bool, showInApply?: bool}
  --language-code: string # The BCP-47 language code to use for evaluating localized field labels. When not specified, values in the default configured language will be used.
  --update-mask: string # The fields that should be updated. At least one field must be specified. The root `disabled_policy` is implied and should not be specified. A single `*` can be used as short-hand for updating every field. (format: google-fieldmask)
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --write-control: record # Provides control over how write requests are executed. When not specified, the last write wins. — shape: {requiredRevisionId?: string}
]: any -> record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2beta/{name}:disable") $qp)
  let req_body = {"disabledPolicy": $disabled_policy, "languageCode": $language_code, "updateMask": $update_mask, "useAdminAccess": $use_admin_access, "writeControl": $write_control} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Enable a disabled Label and restore it to its published state. This will result in a new published revision based on the current disabled published revision. If there is an existing disabled draft revision, a new revision will be created based on that draft and will be enabled.
#
# POST /v2beta/{name}:enable
# operationId: drivelabels.labels.enable
# --writeControl shape: {requiredRevisionId?: string}
export def "v2beta enable" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --language-code: string # The BCP-47 language code to use for evaluating localized field labels. When not specified, values in the default configured language will be used.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --write-control: record # Provides control over how write requests are executed. When not specified, the last write wins. — shape: {requiredRevisionId?: string}
]: any -> record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2beta/{name}:enable") $qp)
  let req_body = {"languageCode": $language_code, "useAdminAccess": $use_admin_access, "writeControl": $write_control} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Publish all draft changes to the Label. Once published, the Label may not return to its draft state. See `google.apps.drive.labels.v2.Lifecycle` for more information. Publishing a Label will result in a new published revision. All previous draft revisions will be deleted. Previous published revisions will be kept but are subject to automated deletion as needed. Once published, some changes are no longer permitted. Generally, any change that would invalidate or cause new restrictions on existing metadata related to the Label will be rejected. For example, the following changes to a Label will be rejected after the Label is published: * The label cannot be directly deleted. It must be disabled first, then deleted. * Field.FieldType cannot be changed. * Changes to Field validation options cannot reject something that was previously accepted. * Reducing the max entries.
#
# POST /v2beta/{name}:publish
# operationId: drivelabels.labels.publish
# --writeControl shape: {requiredRevisionId?: string}
export def "v2beta publish" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --language-code: string # The BCP-47 language code to use for evaluating localized field labels. When not specified, values in the default configured language will be used.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --write-control: record # Provides control over how write requests are executed. When not specified, the last write wins. — shape: {requiredRevisionId?: string}
]: any -> record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2beta/{name}:publish") $qp)
  let req_body = {"languageCode": $language_code, "useAdminAccess": $use_admin_access, "writeControl": $write_control} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates a Label's `CopyMode`. Changes to this policy are not revisioned, do not require publishing, and take effect immediately.
#
# POST /v2beta/{name}:updateLabelCopyMode
# operationId: drivelabels.labels.updateLabelCopyMode
export def "v2beta update-label-copy-mode" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --copy-mode: string@copy-mode-completer # Required. Indicates how the applied Label, and Field values should be copied when a Drive item is copied.
  --language-code: string # The BCP-47 language code to use for evaluating localized field labels. When not specified, values in the default configured language will be used.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --view: string@view-completer # When specified, only certain fields belonging to the indicated view will be returned.
]: any -> record<appliedCapabilities: record<canApply: bool, canRead: bool, canRemove: bool>, appliedLabelPolicy: record<copyMode: string>, createTime: string, creator: record<person: string>, customer: string, disableTime: string, disabler: record<person: string>, displayHints: record<disabled: bool, hiddenInSearch: bool, priority: string, shownInApply: bool>, fields: table<appliedCapabilities: record, createTime: string, creator: record, dateOptions: record, disableTime: string, disabler: record, displayHints: record, id: string, integerOptions: record, lifecycle: record, lockStatus: record, properties: record, publisher: record, queryKey: string, schemaCapabilities: record, selectionOptions: record, textOptions: record, updateTime: string, updater: record, userOptions: record>, id: string, labelType: string, learnMoreUri: string, lifecycle: record<disabledPolicy: record<hideInSearch: bool, showInApply: bool>, hasUnpublishedChanges: bool, state: string>, lockStatus: record<locked: bool>, name: string, properties: record<description: string, title: string>, publishTime: string, publisher: record<person: string>, revisionCreateTime: string, revisionCreator: record<person: string>, revisionId: string, schemaCapabilities: record<canDelete: bool, canDisable: bool, canEnable: bool, canUpdate: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2beta/{name}:updateLabelCopyMode") $qp)
  let req_body = {"copyMode": $copy_mode, "languageCode": $language_code, "useAdminAccess": $use_admin_access, "view": $view} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the LabelLocks on a Label.
#
# GET /v2beta/{parent}/locks
# operationId: drivelabels.labels.revisions.locks.list
export def "v2beta-locks list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of Locks to return per page. Default: 100. Max: 200.
  --page-token: string # The token of the page to return.
]: nothing -> record<labelLocks: table<capabilities: record, choiceId: string, createTime: string, creator: record, deleteTime: string, fieldId: string, name: string, state: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2beta/{parent}/locks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists a Label's permissions.
#
# GET /v2beta/{parent}/permissions
# operationId: drivelabels.labels.revisions.permissions.list
export def "v2beta-permissions list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of permissions to return per page. Default: 50. Max: 200.
  --page-token: string # The token of the page to return.
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
]: nothing -> record<labelPermissions: table<audience: string, email: string, group: string, name: string, person: string, role: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "useAdminAccess" $use_admin_access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2beta/{parent}/permissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a Label's permissions. If a permission for the indicated principal doesn't exist, a new Label Permission is created, otherwise the existing permission is updated. Permissions affect the Label resource as a whole, are not revisioned, and do not require publishing.
#
# PATCH /v2beta/{parent}/permissions
# operationId: drivelabels.labels.revisions.updatePermissions
export def "v2beta-permissions update" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --audience: string # Audience to grant a role to. The magic value of `audiences/default` may be used to apply the role to the default audience in the context of the organization that owns the Label.
  --email: string # Specifies the email address for a user or group pricinpal. Not populated for audience principals. User and Group permissions may only be inserted using email address. On update requests, if email address is specified, no principal should be specified.
  --group: string # Group resource name.
  --name: string # Resource name of this permission.
  --person: string # Person resource name.
  --role: string@role-completer # The role the principal should have.
]: any -> record<audience: string, email: string, group: string, name: string, person: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "useAdminAccess" $use_admin_access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2beta/{parent}/permissions") $qp)
  let req_body = {"audience": $audience, "email": $email, "group": $group, "name": $name, "person": $person, "role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates a Label's permissions. If a permission for the indicated principal doesn't exist, a new Label Permission is created, otherwise the existing permission is updated. Permissions affect the Label resource as a whole, are not revisioned, and do not require publishing.
#
# POST /v2beta/{parent}/permissions
# operationId: drivelabels.labels.revisions.permissions.create
export def "v2beta-permissions create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access.
  --audience: string # Audience to grant a role to. The magic value of `audiences/default` may be used to apply the role to the default audience in the context of the organization that owns the Label.
  --email: string # Specifies the email address for a user or group pricinpal. Not populated for audience principals. User and Group permissions may only be inserted using email address. On update requests, if email address is specified, no principal should be specified.
  --group: string # Group resource name.
  --name: string # Resource name of this permission.
  --person: string # Person resource name.
  --role: string@role-completer # The role the principal should have.
]: any -> record<audience: string, email: string, group: string, name: string, person: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "useAdminAccess" $use_admin_access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2beta/{parent}/permissions") $qp)
  let req_body = {"audience": $audience, "email": $email, "group": $group, "name": $name, "person": $person, "role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes Label permissions. Permissions affect the Label resource as a whole, are not revisioned, and do not require publishing.
#
# POST /v2beta/{parent}/permissions:batchDelete
# operationId: drivelabels.labels.revisions.permissions.batchDelete
# --requests item shape: {name?: string, useAdminAccess?: bool}
export def "v2beta-permissions-batch-delete delete" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --requests: list # Required. The request message specifying the resources to update. — item shape: {name?: string, useAdminAccess?: bool}
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access. If this is set, the use_admin_access field in the DeleteLabelPermissionRequest messages must either be empty or match this field.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2beta/{parent}/permissions:batchDelete") $qp)
  let req_body = {"requests": $requests, "useAdminAccess": $use_admin_access} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates Label permissions. If a permission for the indicated principal doesn't exist, a new Label Permission is created, otherwise the existing permission is updated. Permissions affect the Label resource as a whole, are not revisioned, and do not require publishing.
#
# POST /v2beta/{parent}/permissions:batchUpdate
# operationId: drivelabels.labels.revisions.permissions.batchUpdate
# --requests item shape: {labelPermission?: record, parent?: string, useAdminAccess?: bool}
export def "v2beta-permissions-batch-update update" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --requests: list # Required. The request message specifying the resources to update. — item shape: {labelPermission?: record, parent?: string, useAdminAccess?: bool}
  --use-admin-access: oneof<nothing, bool> # Set to `true` in order to use the user's admin credentials. The server will verify the user is an admin for the Label before allowing access. If this is set, the use_admin_access field in the UpdateLabelPermissionRequest messages must either be empty or match this field.
]: any -> record<permissions: table<audience: string, email: string, group: string, name: string, person: string, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2beta/{parent}/permissions:batchUpdate") $qp)
  let req_body = {"requests": $requests, "useAdminAccess": $use_admin_access} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
