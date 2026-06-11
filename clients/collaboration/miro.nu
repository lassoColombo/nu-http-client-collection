# Auto-generated client for Miro Developer Platform vv2.0
# Source: https://raw.githubusercontent.com/miroapp/api-clients/main/packages/generator/spec.json
# Auth: --token flag or $env.MIRO_DEVELOPER_PLATFORM_TOKEN

const BASE_URL = "https://api.miro.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MIRO_DEVELOPER_PLATFORM_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.miro.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sorting-completer [] { ["asc" "desc"] }
def sorting-completer-1 [] { ["ASC" "DESC"] }
def textContentType-completer [] { ["html" "markdown"] }
def boardFormat-completer [] { ["HTML" "PDF" "SVG"] }
def status-completer [] { ["CANCELLED"] }
def sortOrder-completer [] { ["ascending" "descending"] }
def accept-completer [] { ["application/json" "application/scim+json"] }
def schemas-completer [] { ["urn:ietf:params:scim:api:messages:2.0:PatchOp"] }
def role-completer [] { ["organization_external_user" "organization_internal_admin" "organization_internal_user" "organization_team_guest_user" "unknown"] }
def license-completer [] { ["advanced" "basic" "free" "free_restricted" "full" "full_trial" "occasional" "standard" "unknown"] }
def sort-completer [] { ["alphabetically" "default" "last_created" "last_modified" "last_opened"] }
def shape-completer [] { ["curved" "elbowed" "straight"] }
def type-completer [] { ["app_card" "card" "data_table_format" "doc_format" "document" "embed" "frame" "image" "preview" "shape" "sticky_note" "text"] }
def role-completer-1 [] { ["commenter" "coowner" "editor" "owner" "viewer"] }
def period-completer [] { ["DAY" "MONTH" "WEEK"] }
def type-completer-1 [] { ["shape"] }
def fillColor-completer [] { ["black" "blue" "cyan" "dark_blue" "dark_green" "gray" "green" "light_green" "magenta" "red" "violet" "yellow"] }
def role-completer-2 [] { ["commentator" "coowner" "editor" "owner" "viewer"] }
def role-completer-3 [] { ["admin" "member"] }
def role-completer-4 [] { ["member"] }
def role-completer-5 [] { ["COMMENTER" "EDITOR" "VIEWER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "oauth-revoke revoke-token" } } | get name | first)
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

# Revoke token (v1)
#
# POST /v1/oauth/revoke
# DEPRECATED
# operationId: revoke-token
@deprecated
export def "oauth-revoke revoke-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-token: string # Access token that you want to revoke
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/oauth/revoke" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get access token information
#
# GET /v1/oauth-token
# operationId: token-info
export def "oauth-token token-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, organization: record<type: string, name: string, id: string>, team: record<type: string, name: string, id: string>, createdBy: record<type: string, name: string, id: string>, user: record<type: string, name: string, id: string>, scopes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get AI interaction logs (Beta)
#
# GET /v2/orgs/{org_id}/ai-interaction-logs
# operationId: enterprise-get-ai-interaction-logs
export def "orgs-ai-interaction-logs enterprise-get-ai-interaction-logs" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --object-ids: list # List of object IDs used to retrieve AI interaction logs.  Currently, supported object types include board IDs and organization IDs.  You can obtain object IDs from the response of this endpoint (the <code>object.id</code> field),  from other Platform API endpoints (for example, [Get boards API](https://developers.miro.com/reference/get-boards)),  or from Miro UI URLs (board ID and organization ID from the URLs).  (e.g. [3458764549483493025, u8J_kllZmDk=])
  --emails: list # Filters AI interaction logs using a list of user emails. Only AI interactions associated with the provided emails will be included in the response. (e.g. [someone@domain.com, someoneelse@domain.com])
  --qp-from: string # Start date and time of the time range used to filter AI interaction logs. Only interactions that were stored within the specified <code>from</code> - <code>to</code> time range are returned. Format: UTC, adheres to [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601), includes a [trailing Z offset](https://en.wikipedia.org/wiki/ISO_8601#Coordinated_Universal_Time_(UTC)).  (format: date-time, e.g. 2026-01-30T17:26:50Z)
  --qp-to: string # End date and time of the time range used to filter AI interaction logs. Only interactions that were stored within the specified <code>from</code> - <code>to</code> time range are returned. Format: UTC, adheres to [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601), includes a [trailing Z offset](https://en.wikipedia.org/wiki/ISO_8601#Coordinated_Universal_Time_(UTC)).  (format: date-time, e.g. 2036-03-30T17:26:50Z)
  --cursor: string # A cursor-paginated method returns a portion of the total set of results based on the limit specified and a cursor that points to the next portion of the results. To retrieve the next portion of the collection, set the cursor parameter equal to the cursor value you received in the response of the previous request.  (e.g. MTY2OTg4NTIwMDAwMHwxMjM=)
  --limit: int # The maximum number of results to return per call. If the number of logs in the response is greater than the limit specified, the response returns the cursor parameter with a value.  (format: int32, default: 100, e.g. 100)
  --sorting: string@sorting-completer # Sort order in which you want to view the result set based on the interaction date. To sort by an ascending date, specify `asc`. To sort by a descending date, specify `desc`.  (default: asc, e.g. asc)
]: nothing -> record<limit: int, size: int, data: table<id: string, createdAt: string, storedAt: string, sessionId: string, messageId: string, object: record, aiFeatureName: string, actor: record, logType: string, details: record>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "object_ids" $object_ids "multi") (serialize-qp "emails" $emails "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sorting" $sorting "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/ai-interaction-logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get audit logs
#
# GET /v2/audit/logs
# operationId: enterprise-get-audit-logs
export def "audit-logs enterprise-get-audit-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdAfter: string # Retrieve audit logs created after the date and time provided. This is the start date of the duration for which you want to retrieve audit logs. For example, if you want to retrieve audit logs between `2023-03-30T17:26:50.000Z` and `2023-04-30T17:26:50.000Z`, provide `2023-03-30T17:26:50.000Z` as the value for the `createdAfter` parameter.<br>Format: UTC, adheres to [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601), including milliseconds and a [trailing Z offset](https://en.wikipedia.org/wiki/ISO_8601#Coordinated_Universal_Time_(UTC))."  (e.g. 2023-03-30T17:26:50.000Z)
  --createdBefore: string # Retrieve audit logs created before the date and time provided. This is the end date of the duration for which you want to retrieve audit logs. For example, if you want to retrieve audit logs between `2023-03-30T17:26:50.000Z` and `2023-04-30T17:26:50.000Z`, provide `2023-04-30T17:26:50.000Z` as the value for the `createdBefore` parameter.<br>Format: UTC, adheres to [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601), including milliseconds and a [trailing Z offset](https://en.wikipedia.org/wiki/ISO_8601#Coordinated_Universal_Time_(UTC)).  (e.g. 2023-04-30T17:26:50.000Z)
  --cursor: string # A cursor-paginated method returns a portion of the total set of results based on the `limit` specified and a `cursor` that points to the next portion of the results. To retrieve the next set of results of the collection, set the `cursor` parameter in your next request to the appropriate cursor value returned in the response.
  --limit: int # Maximum number of results returned based on the `limit` specified in the request. For example, if there are `30` results, the request has no `cursor` value, and the `limit` is set to `20`,the `size` of the results will be `20`. The rest of the results will not be returned. To retrieve the rest of the results, you must make another request and set the appropriate value for the `cursor` parameter value that  you obtained from the response.<br>Default: `100`  (e.g. 100)
  --sorting: string@sorting-completer-1 # Sort order in which you want to view the result set. Based on the value you provide, the results are sorted in an ascending or descending order of the audit log creation date (audit log `createdAt` parameter).<br>Default: `ASC`  (e.g. ASC)
]: nothing -> record<type: string, limit: int, size: int, cursor: string, data: table<id: string, context: record, object: record, createdAt: string, details: record, createdBy: record, event: string, category: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sorting" $sorting "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/audit/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization settings
#
# GET /v2/orgs/{org_id}/data-classification-settings
# operationId: enterprise-dataclassification-organization-settings-get
export def "orgs-data-classification-settings enterprise-dataclassification-organization-settings-get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, labels: table<id: string, color: string, default: bool, description: string, name: string, orderNumber: int, sharingRecommendation: string, guidelineUrl: string, type: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/data-classification-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk update boards classification
#
# PATCH /v2/orgs/{org_id}/teams/{team_id}/data-classification
# operationId: enterprise-dataclassification-team-boards-bulk
export def "orgs-teams-data-classification enterprise-dataclassification-team-boards-bulk" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labelId: int # Data classification label id for team (format: int64, e.g. 3000457366756291000)
  --notClassifiedOnly: string@bool-completer # Assign data classification label to not-classified only or to all boards of team (e.g. true)
]: any -> record<numberUpdatedBoards: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/data-classification")
  let body = {labelId: $labelId, notClassifiedOnly: $notClassifiedOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get team settings
#
# GET /v2/orgs/{org_id}/teams/{team_id}/data-classification-settings
# operationId: enterprise-dataclassification-team-settings-get
export def "orgs-teams-data-classification-settings enterprise-dataclassification-team-settings-get" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<defaultLabelId: string, enabled: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/data-classification-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update team settings
#
# PATCH /v2/orgs/{org_id}/teams/{team_id}/data-classification-settings
# operationId: enterprise-dataclassification-team-settings-set
export def "orgs-teams-data-classification-settings enterprise-dataclassification-team-settings-set" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --defaultLabelId: int # Data classification default label id (format: int64, e.g. 3000457366756291000)
  --enabled: string@bool-completer # Data classification enabled for team (e.g. true)
]: any -> record<defaultLabelId: string, enabled: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/data-classification-settings")
  let body = {defaultLabelId: $defaultLabelId, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get board classification
#
# GET /v2/orgs/{org_id}/teams/{team_id}/boards/{board_id}/data-classification
# operationId: enterprise-dataclassification-board-get
export def "orgs-teams-boards-data-classification enterprise-dataclassification-board-get" [
  org_id: string
  team_id: string
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<color: string, description: string, id: string, name: string, sharingRecommendation: string, guidelineUrl: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/boards/($board_id)/data-classification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update board classification
#
# POST /v2/orgs/{org_id}/teams/{team_id}/boards/{board_id}/data-classification
# operationId: enterprise-dataclassification-board-set
export def "orgs-teams-boards-data-classification enterprise-dataclassification-board-set" [
  org_id: string
  team_id: string
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labelId: string # Data classification label id (e.g. 3000457366756290996)
]: any -> record<color: string, description: string, id: string, name: string, sharingRecommendation: string, guidelineUrl: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/boards/($board_id)/data-classification")
  let body = {labelId: $labelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create doc format item
#
# POST /v2/boards/{board_id}/docs
# operationId: create-doc-format-item
# --data shape: {contentType: "markdown", content: string, contentVersion?: float}
# --position shape: {x?: float, y?: float}
# --parent shape: {id?: string}
export def "boards-docs create-doc-format-item" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {contentType: "markdown", content: string, contentVersion?: float}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record, position: record<origin: string, relativeTo: string, x: float, y: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/docs")
  let body = {data: $data, position: $position, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get doc format item
#
# GET /v2/boards/{board_id}/docs/{item_id}
# operationId: get-doc-format-item
export def "boards-docs get-doc-format-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --textContentType: string@textContentType-completer # Controls the contentType of the returned doc's content.
]: nothing -> record<id: string, data: record, position: record<origin: string, relativeTo: string, x: float, y: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "textContentType" $textContentType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id)/docs/($item_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete doc format item
#
# DELETE /v2/boards/{board_id}/docs/{item_id}
# operationId: delete-doc-format-item
export def "boards-docs delete-doc-format-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/docs/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all cases
#
# GET /v2/orgs/{org_id}/cases
# operationId: get-all-cases
export def "orgs-cases get-all-cases" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of items in the result list. (format: int32, default: 100, e.g. 10)
  --cursor: string # An indicator of the position of a page in the full set of results. To obtain the first page leave it empty. To obtain subsequent pages set it to the value returned in the cursor field of the previous request.  (e.g. MTY2OTg4NTIwMDAwMHwxMjM=)
]: nothing -> record<size: int, total: int, cursor: string, limit: int, type: string, data: table<id: string, organizationId: string, name: string, description: string, createdBy: record, lastModifiedBy: record, createdAt: string, lastModifiedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create case
#
# POST /v2/orgs/{org_id}/cases
# operationId: create-case
export def "orgs-cases create-case" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the case. (e.g. My Case)
  --description: string # The description of the case. (e.g. Info about my case)
]: any -> record<id: string, organizationId: string, name: string, description: string, createdBy: record<id: string, email: string, firstName: string, lastName: string>, lastModifiedBy: record<id: string, email: string, firstName: string, lastName: string>, createdAt: string, lastModifiedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Close case
#
# DELETE /v2/orgs/{org_id}/cases/{case_id}
# operationId: delete-case
export def "orgs-cases delete-case" [
  org_id: string
  case_id: string
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
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases/($case_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get case
#
# GET /v2/orgs/{org_id}/cases/{case_id}
# operationId: get-case
export def "orgs-cases get-case" [
  org_id: string
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, organizationId: string, name: string, description: string, createdBy: record<id: string, email: string, firstName: string, lastName: string>, lastModifiedBy: record<id: string, email: string, firstName: string, lastName: string>, createdAt: string, lastModifiedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases/($case_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit case
#
# PUT /v2/orgs/{org_id}/cases/{case_id}
# operationId: edit-case
export def "orgs-cases edit-case" [
  org_id: string
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the case. (e.g. My Case)
  --description: string # The description of the case. (e.g. Info about my case)
]: any -> record<id: string, organizationId: string, name: string, description: string, createdBy: record<id: string, email: string, firstName: string, lastName: string>, lastModifiedBy: record<id: string, email: string, firstName: string, lastName: string>, createdAt: string, lastModifiedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases/($case_id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all legal holds within a case
#
# GET /v2/orgs/{org_id}/cases/{case_id}/legal-holds
# operationId: get-all-legal-holds
export def "orgs-cases-legal-holds get-all-legal-holds" [
  org_id: string
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of items in the result list. (format: int32, default: 100, e.g. 10)
  --cursor: string # An indicator of the position of a page in the full set of results. To obtain the first page leave it empty. To obtain subsequent pages set it to the value returned in the cursor field of the previous request.  (e.g. MTY2OTg4NTIwMDAwMHwxMjM=)
]: nothing -> record<size: int, total: int, cursor: string, limit: int, type: string, data: table<id: string, organizationId: string, caseId: string, name: string, description: string, state: string, scope: any, createdBy: record, lastModifiedBy: record, createdAt: string, lastModifiedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases/($case_id)/legal-holds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create legal hold
#
# POST /v2/orgs/{org_id}/cases/{case_id}/legal-holds
# operationId: create-legal-hold
export def "orgs-cases-legal-holds create-legal-hold" [
  org_id: string
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the legal hold. (e.g. My legal hold)
  --description: string # The description of the legal hold. (e.g. Info about my legal hold)
  scope: any # The legal hold scope determines the criteria used to put content items under hold. The variants of this field might get extended in the future, although the most common use case is to put users under hold. Currently only the `users` scope is supported. However, the parsing of this field must ignore unexpected variants. The request must always include a list of all users to be placed under hold, whether it's for a new legal hold or an update to an existing one. You can have up to 200 users per legal hold, including users added in legal hold updates.
]: any -> record<id: string, organizationId: string, caseId: string, name: string, description: string, state: string, scope: any, createdBy: record<id: string, email: string, firstName: string, lastName: string>, lastModifiedBy: record<id: string, email: string, firstName: string, lastName: string>, createdAt: string, lastModifiedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases/($case_id)/legal-holds")
  let body = {name: $name, description: $description, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get board export jobs of a case
#
# GET /v2/orgs/{org_id}/cases/{case_id}/export-jobs
# operationId: get-legal-hold-export-jobs
export def "orgs-cases-export-jobs get-legal-hold-export-jobs" [
  org_id: string
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of items in the result list. (format: int32, default: 100, e.g. 10)
  --cursor: string # An indicator of the position of a page in the full set of results. To obtain the first page leave it empty. To obtain subsequent pages set it to the value returned in the cursor field of the previous request.  (e.g. MTY2OTg4NTIwMDAwMHwxMjM=)
]: nothing -> record<size: int, cursor: string, limit: int, type: string, data: table<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases/($case_id)/export-jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close legal hold
#
# DELETE /v2/orgs/{org_id}/cases/{case_id}/legal-holds/{legal_hold_id}
# operationId: delete-legal-hold
export def "orgs-cases-legal-holds delete-legal-hold" [
  org_id: string
  case_id: string
  legal_hold_id: string
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
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases/($case_id)/legal-holds/($legal_hold_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get legal hold information
#
# GET /v2/orgs/{org_id}/cases/{case_id}/legal-holds/{legal_hold_id}
# operationId: get-legal-hold
export def "orgs-cases-legal-holds get-legal-hold" [
  org_id: string
  case_id: string
  legal_hold_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, organizationId: string, caseId: string, name: string, description: string, state: string, scope: any, createdBy: record<id: string, email: string, firstName: string, lastName: string>, lastModifiedBy: record<id: string, email: string, firstName: string, lastName: string>, createdAt: string, lastModifiedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases/($case_id)/legal-holds/($legal_hold_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit legal hold
#
# PUT /v2/orgs/{org_id}/cases/{case_id}/legal-holds/{legal_hold_id}
# operationId: edit-legal-hold
export def "orgs-cases-legal-holds edit-legal-hold" [
  org_id: string
  case_id: string
  legal_hold_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the legal hold. (e.g. My legal hold)
  --description: string # The description of the legal hold. (e.g. Info about my legal hold)
  scope: any # The legal hold scope determines the criteria used to put content items under hold. The variants of this field might get extended in the future, although the most common use case is to put users under hold. Currently only the `users` scope is supported. However, the parsing of this field must ignore unexpected variants. The request must always include a list of all users to be placed under hold, whether it's for a new legal hold or an update to an existing one. You can have up to 200 users per legal hold, including users added in legal hold updates.
]: any -> record<id: string, organizationId: string, caseId: string, name: string, description: string, state: string, scope: any, createdBy: record<id: string, email: string, firstName: string, lastName: string>, lastModifiedBy: record<id: string, email: string, firstName: string, lastName: string>, createdAt: string, lastModifiedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases/($case_id)/legal-holds/($legal_hold_id)")
  let body = {name: $name, description: $description, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get content items under legal hold
#
# GET /v2/orgs/{org_id}/cases/{case_id}/legal-holds/{legal_hold_id}/content-items
# operationId: get-legal-hold-content-items
export def "orgs-cases-legal-holds-content-items get-legal-hold-content-items" [
  org_id: string
  case_id: string
  legal_hold_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of items in the result list. (format: int32, default: 100, e.g. 10)
  --cursor: string # An indicator of the position of a page in the full set of results. To obtain the first page leave it empty. To obtain subsequent pages set it to the value returned in the cursor field of the previous request.  (e.g. MTY2OTg4NTIwMDAwMHwxMjM=)
]: nothing -> record<size: int, total: int, cursor: string, limit: int, type: string, data: table<contentId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/cases/($case_id)/legal-holds/($legal_hold_id)/content-items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create board export job
#
# POST /v2/orgs/{org_id}/boards/export/jobs
# operationId: enterprise-create-board-export
export def "orgs-boards-export-jobs enterprise-create-board-export" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request-id: string # Unique identifier of the board export job. (format: uuid, e.g. 92343229-c532-446d-b8cb-2f155bedb807)
  --boardIds: list # List of board IDs to be exported. Each export job can contain up to 1,000 boards. (e.g. o9J_kzlUDmo=)
  --boardFormat: string@boardFormat-completer # Specifies the format of the file to which the board will be exported. Supported formats include SVG (default), HTML, and PDF. (default: SVG, e.g. SVG)
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request_id" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/boards/export/jobs" $qp)
  let body = {boardIds: $boardIds, boardFormat: $boardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get board export jobs list
#
# GET /v2/orgs/{org_id}/boards/export/jobs
# operationId: enterprise-board-export-jobs
export def "orgs-boards-export-jobs enterprise-board-export-jobs" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: list # Status of the board export jobs that you want to retrieve, such as JOB_STATUS_CREATED, JOB_STATUS_IN_PROGRESS, JOB_STATUS_CANCELLED or JOB_STATUS_FINISHED.
  --creatorId: list # Unique identifier of the board export job creator. (e.g. [1234567890, 9876543210])
  --cursor: string # A cursor-paginated method returns a portion of the total set of results based on the limit specified and a cursor that points to the next portion of the results. To retrieve the next portion of the collection, set the cursor parameter equal to the cursor value you received in the response of the previous request.  (format: uuid, e.g. 87a1a375-cee6-43f2-8049-5c9b5b6b9069)
  --limit: int # The maximum number of results to return per call. If the number of jobs in the response is greater than the limit specified, the response returns the cursor parameter with a value.  (format: int32, default: 50, e.g. 10)
]: nothing -> record<total: int, cursor: string, data: table<id: string, name: string, boardFormat: string, status: string, createdAt: string, modifiedAt: string, tasksCount: record, creator: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "multi") (serialize-qp "creatorId" $creatorId "multi") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/boards/export/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get board export job status
#
# GET /v2/orgs/{org_id}/boards/export/jobs/{job_id}
# operationId: enterprise-board-export-job-status
export def "orgs-boards-export-jobs enterprise-board-export-job-status" [
  org_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<jobStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/boards/export/jobs/($job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get results for board export job
#
# GET /v2/orgs/{org_id}/boards/export/jobs/{job_id}/results
# operationId: enterprise-board-export-job-results
export def "orgs-boards-export-jobs-results enterprise-board-export-job-results" [
  org_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<jobId: string, results: table<boardId: string, errorMessage: string, exportLink: string, status: string, errorType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/boards/export/jobs/($job_id)/results")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update board export job status
#
# PUT /v2/orgs/{org_id}/boards/export/jobs/{job_id}/status
# operationId: enterprise-update-board-export-job
export def "orgs-boards-export-jobs-status enterprise-update-board-export-job" [
  org_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer # Only the `CANCELLED` status is currently supported.
]: any -> record<status: record<jobStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/boards/export/jobs/($job_id)/status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get board export job tasks list
#
# GET /v2/orgs/{org_id}/boards/export/jobs/{job_id}/tasks
# operationId: enterprise-board-export-job-tasks
export def "orgs-boards-export-jobs-tasks enterprise-board-export-job-tasks" [
  org_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: list # Filters the list of board export tasks by their status. Accepts an array of statuses such as TASK_STATUS_CREATED, TASK_STATUS_CANCELLED, TASK_STATUS_SCHEDULED, TASK_STATUS_SUCCESS or TASK_STATUS_ERROR. (e.g. TASK_STATUS_CREATED)
  --cursor: string # A cursor-paginated method returns a portion of the total set of results based on the limit specified and a cursor that points to the next portion of the results. To retrieve the next portion of the collection, set the cursor parameter equal to the cursor value you received in the response of the previous request.  (format: uuid, e.g. 87a1a375-cee6-43f2-8049-5c9b5b6b9069)
  --limit: int # The maximum number of results to return per call. If the number of tasks in the response is greater than the limit specified, the response returns the cursor parameter with a value.  (format: int32, default: 50, e.g. 50)
]: nothing -> record<total: int, cursor: string, data: table<id: string, status: string, artifactExpiredAt: string, sizeInBytes: int, errorMessage: string, errorType: string, board: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "multi") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/boards/export/jobs/($job_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create task export link
#
# POST /v2/orgs/{org_id}/boards/export/jobs/{job_id}/tasks/{task_id}/export-link
# operationId: enterprise-create-board-export-task-export-link
export def "orgs-boards-export-jobs-tasks-export-link enterprise-create-board-export-task-export-link" [
  org_id: string
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, exportLink: string, artifactExpiredAt: string, linkExpiredAt: string, errorMessage: string, errorType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/boards/export/jobs/($job_id)/tasks/($task_id)/export-link")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve content change logs of board items
#
# GET /v2/orgs/{org_id}/content-logs/items
# operationId: enterprise-board-content-item-logs-fetch
export def "orgs-content-logs-items enterprise-board-content-item-logs-fetch" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --board-ids: list # List of board IDs for which you want to retrieve the content logs. (e.g. [o9J_kzlUDmo=, u8J_kllZmDk=])
  --emails: list # Filter content logs based on the list of emails of users who created, modified, or deleted the board item. (e.g. [someone@domain.com, someoneelse@domain.com])
  --qp-from: string # Filter content logs based on the date and time when the board item was last modified. This is the start date and time for the modified date duration. Format: UTC, adheres to [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601), includes a [trailing Z offset](https://en.wikipedia.org/wiki/ISO_8601#Coordinated_Universal_Time_(UTC)).  (format: date-time, e.g. 2022-03-30T17:26:50Z)
  --qp-to: string # Filter content logs based on the date and time when the board item was last modified. This is the end date and time for the modified date duration. Format: UTC, adheres to [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601), includes a [trailing Z offset](https://en.wikipedia.org/wiki/ISO_8601#Coordinated_Universal_Time_(UTC)).  (format: date-time, e.g. 2023-03-30T17:26:50Z)
  --cursor: string # A cursor-paginated method returns a portion of the total set of results based on the limit specified and a cursor that points to the next portion of the results. To retrieve the next portion of the collection, set the cursor parameter equal to the cursor value you received in the response of the previous request.  (e.g. MTY2OTg4NTIwMDAwMHwxMjM=)
  --limit: int # The maximum number of results to return per call. If the number of logs in the response is greater than the limit specified, the response returns the cursor parameter with a value.  (format: int32, default: 1000, e.g. 1000)
  --sorting: string@sorting-completer # Sort order in which you want to view the result set based on the modified date. To sort by an ascending modified date, specify `asc`. To sort by a descending modified date, specify `desc`.  (default: asc, e.g. asc)
]: nothing -> record<limit: int, size: int, data: table<id: string, contentId: string, actionType: string, actionTime: string, actor: record, itemType: string, itemId: string, state: record, relationships: list>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "board_ids" $board_ids "multi") (serialize-qp "emails" $emails "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sorting" $sorting "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/content-logs/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset all sessions of a user
#
# POST /v2/sessions/reset_all
# operationId: enterprise-post-user-sessions-reset
export def "sessions-reset-all enterprise-post-user-sessions-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Email ID of the user whose sessions you want to reset. Note that this user will be signed out from all devices. (e.g. john.smith@example.com)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sessions/reset_all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users
#
# GET /Users
# operationId: listUsers
export def "users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --attributes: string # A comma-separated list of attribute names to return in the response. <br><br> Example attributes: id, userName, displayName, name, userType, active, emails, photos, groups, roles. You can also retrieve attributes within complex attributes, for Example: emails.value. The API also supports sorting and the filter parameter.
  --filter: string # You can request a subset of resources by specifying the filter query parameter containing a filter expression. Attribute names and attribute operators used in filters are not case sensitive. The filter parameter must contain at least one valid expression. Each expression must contain an attribute name followed by an attribute operator and an optional value. <br>eq = equal<br> ne = not equal<br> co = contains<br> sw = starts with<br> ew = ends with<br> pr = preset (has value)<br> gt = greater than<br> ge = greater than or equal to<br> lt = less than<br> le = less than or equal to<br> and = Logical "and"<br> or = Logical "or"<br> not = "Not" function<br> () = Precedence grouping <br>The value must be passed within parenthesis. <br><br> <u>Example filters</u>:<br><br> For fetching  users with user name as user@miro.com: userName eq "user@miro.com" <br><br> For fetching all active users in the organization: active eq true <br><br> For fetching users with "user" in their displayName: displayName co "user" <br><br> For fetching users that are member of a specific group (team): groups.value eq "3458764577585056871" <br><br> For fetching users that are not of userType Full: userType ne "Full"
  --startIndex: int # Use startIndex in combination with count query parameters to receive paginated results. <br><br> start index is 1-based. <br><br> Example: startIndex=1
  --count: int # Specifies the maximum number of query results per page. <br><br> Use count in combination with startIndex query parameters to receive paginated results. <br><br> The count query parameter is set to 100 by default and the maximum value allowed for this parameter is 1000. <br><br> Example: count=12
  --sortBy: string # Specifies the attribute whose value will be used to order the response. <br><br> Example: sortBy=userName, sortBy=emails.value
  --sortOrder: string@sortOrder-completer # Defines the order in which the sortBy parameter is applied. <br><br> Example: sortOrder=ascending
]: nothing -> record<schemas: list<string>, totalResults: float, startIndex: float, itemsPerPage: float, Resources: table<schemas: list, id: string, meta: record, userName: string, name: record, displayName: string, userType: string, active: bool, emails: list, photos: list, groups: list, roles: list, preferredLanguage: string, urn_ietf_params_scim_schemas_extension_enterprise_2_0_User: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Users" $qp)
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create user
#
# POST /Users
# operationId: createUser
# --name shape: {formatted?: string, familyName: string, givenName: string}
# --photos item shape: {type?: string, value?: string}
# --roles item shape: {type?: string, value?: string, display?: string, primary?: bool}
# --urn:ietf:params:scim:schemas:extension:enterprise:2.0:User shape: {employeeNumber?: string, costCenter?: string, organization?: string, division?: string, department?: string, manager?: record}
export def "users createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --schemas: list # Identifies which schema(s) this resource uses. In this case it is the SCIM core User schema.
  userName: string # The unique username/login identifier. An email address in this case. <br><br> Note: Payload must include the userName attribute populated with an email address<br><br> User is created with this email address in the organization. This attribute will be used as full name of the created user if the displayName or name attribute is not provided. (e.g. user@miro.com)
  --name: record # Structured object for the person’s name. This includes the family name (last name), and given name (first name). — shape: {formatted?: string, familyName: string, givenName: string}
  --displayName: string # A human-readable name for the user, typically the full name. This attribute is used if the value is not empty. <br><br> Maximum length: 60 characters (e.g. John Doe)
  --userType: string # Free-form string to indicate the user license type in the organization. <br><br> Only supported values for license types are allowed. Supported license types can vary per organization. An organization can have one or more of the following license type values: Full, Free, Free Restricted, Full (Trial), Basic, Standard, Advanced. <br><br> Note: When `userType` is specified, the `userType` license is set per the value provided. When `userType` is not specified, the user license is set according to internal Miro logic, which depends on the organization plan. (e.g. Full)
  --active: string@bool-completer # Indicates whether the user is active or deactivated in the organization.
  --photos: list # An array of display picture for the user in the organization. Contains photo value and type. <br><br> Notes: Must be a text URL to the image. Supported file types: jpg, jpeg, bmp, png, gif. <br><br> To define file type, you should have defined file extension in url (e.g. https://host.com/avatar_user1.jpg) or request to url should return together with a file content a header Content-Type (e.g. Content-Type = image/jpeg) <br><br> Maximum file size to download is: 31457280 bytes. <br><br> Example (Okta): photos.^[type==photo].value <br> Example (Azure): photos[type eq "photo"].value — item shape: {type?: string, value?: string}
  --roles: list # An array of roles assigned to the user in the organization. Contains role value, display, type, and primary flag. <br><br> organization_user_role supported values include: ORGANIZATION_INTERNAL_ADMIN and ORGANIZATION_INTERNAL_USER. organization_admin_role supported values include: Content Admin, User Admin, Security Admin, or names of custom admin roles. <br><br> Example (Okta) for organization_user_role: roles.^[primary==true].value <br> Example (Azure) for organization_user_role: roles[primary eq "True"].value <br> Example (Okta) for organization_admin_role: roles.^[primary==false].value <br> Example (Azure) for organization_admin_role: roles[primary eq "False"].value <br> — item shape: {type?: string, value?: string, display?: string, primary?: bool}
  --preferredLanguage: string # Specifies the user's preferred language. <br><br> Example: en_US for English. (e.g. en_US)
  --urn:ietf:params:scim:schemas:extension:enterprise:20:User: record # Enterprise User extension schema. — shape: {employeeNumber?: string, costCenter?: string, organization?: string, division?: string, department?: string, manager?: record}
]: any -> record<schemas: list<string>, id: string, meta: record<resourceType: string, location: string>, userName: string, name: record<formatted: string, familyName: string, givenName: string>, displayName: string, userType: string, active: bool, emails: table<value: string, type: string, primary: bool>, photos: table<type: string, value: string>, groups: table<value: string, display: string>, roles: table<type: string, value: string, display: string, primary: bool>, preferredLanguage: string, urn_ietf_params_scim_schemas_extension_enterprise_2_0_User: record<employeeNumber: string, costCenter: string, organization: string, division: string, department: string, manager: record<displayName: string, value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Users")
  let body = {schemas: $schemas, userName: $userName, name: $name, displayName: $displayName, userType: $userType, active: $active, photos: $photos, roles: $roles, preferredLanguage: $preferredLanguage, urn:ietf:params:scim:schemas:extension:enterprise:2.0:User: $urn:ietf:params:scim:schemas:extension:enterprise:20:User} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user
#
# GET /Users/{id}
# operationId: getUser
export def "users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --attributes: string # A comma-separated list of attribute names to return in the response. <br><br> <br>Example attributes</b> - id, userName, displayName, name, userType, active, emails, photos, groups, roles. <br><br> <br>Note</b>: It is also possible to fetch attributes within complex attributes, for Example: emails.value
]: nothing -> record<schemas: list<string>, id: string, meta: record<resourceType: string, location: string>, userName: string, name: record<formatted: string, familyName: string, givenName: string>, displayName: string, userType: string, active: bool, emails: table<value: string, type: string, primary: bool>, photos: table<type: string, value: string>, groups: table<value: string, display: string>, roles: table<type: string, value: string, display: string, primary: bool>, preferredLanguage: string, urn_ietf_params_scim_schemas_extension_enterprise_2_0_User: record<employeeNumber: string, costCenter: string, organization: string, division: string, department: string, manager: record<displayName: string, value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Users/($id)" $qp)
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace user
#
# PUT /Users/{id}
# operationId: replaceUser
# --meta shape: {resourceType?: string, location?: string}
# --name shape: {formatted?: string, familyName?: string, givenName?: string}
# --emails item shape: {value?: string, type?: string, primary?: bool}
# --photos item shape: {type?: string, value?: string}
# --groups item shape: {value?: string, display?: string}
# --roles item shape: {type?: string, value?: string, display?: string, primary?: bool}
# --urn:ietf:params:scim:schemas:extension:enterprise:2.0:User shape: {employeeNumber?: string, costCenter?: string, organization?: string, division?: string, department?: string, manager?: record}
export def "users replaceUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --schemas: list # Identifies which schema(s) this resource uses. In this case it is the SCIM core User schema.
  --body-id: string # A server-assigned, unique identifier for this user. (e.g. 3074457365265951581)
  --meta: record # Metadata about the resource. — shape: {resourceType?: string, location?: string}
  --userName: string # The unique username/login identifier. An email address in this case. (e.g. user@miro.com)
  --name: record # Structured object for the person’s name. This includes the family name (last name), and given name (first name). — shape: {formatted?: string, familyName?: string, givenName?: string}
  --displayName: string # A human-readable name for the user, typically the full name. (e.g. John Doe)
  --userType: string # Free-form string to indicate the user license type in the organization. (e.g. Full)
  --active: string@bool-completer # Indicates whether the user is active or deactivated in the organization.
  --emails: list # An array of email addresses, each an object with a value, display and primary flag. — item shape: {value?: string, type?: string, primary?: bool}
  --photos: list # An array for profile pictures, contains type. — item shape: {type?: string, value?: string}
  --groups: list # An array of groups (teams) the user belongs to in the organization. Contains id and display name of the team. — item shape: {value?: string, display?: string}
  --roles: list # An array of roles assigned to the user in the organization. Contains role type, value, display and primary flag. — item shape: {type?: string, value?: string, display?: string, primary?: bool}
  --preferredLanguage: string # Specifies the users preferred language. <br><br> Example: en_US for English. (e.g. en_US)
  --urn:ietf:params:scim:schemas:extension:enterprise:20:User: record # Enterprise User extension schema. — shape: {employeeNumber?: string, costCenter?: string, organization?: string, division?: string, department?: string, manager?: record}
]: any -> record<schemas: list<string>, id: string, meta: record<resourceType: string, location: string>, userName: string, name: record<formatted: string, familyName: string, givenName: string>, displayName: string, userType: string, active: bool, emails: table<value: string, type: string, primary: bool>, photos: table<type: string, value: string>, groups: table<value: string, display: string>, roles: table<type: string, value: string, display: string, primary: bool>, preferredLanguage: string, urn_ietf_params_scim_schemas_extension_enterprise_2_0_User: record<employeeNumber: string, costCenter: string, organization: string, division: string, department: string, manager: record<displayName: string, value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Users/($id)")
  let body = {schemas: $schemas, id: $body_id, meta: $meta, userName: $userName, name: $name, displayName: $displayName, userType: $userType, active: $active, emails: $emails, photos: $photos, groups: $groups, roles: $roles, preferredLanguage: $preferredLanguage, urn:ietf:params:scim:schemas:extension:enterprise:2.0:User: $urn:ietf:params:scim:schemas:extension:enterprise:20:User} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch user
#
# PATCH /Users/{id}
# operationId: patchUser
# --Operations item shape: {op: "Add"|"Remove"|"Replace", path: string, value: string}
export def "users patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  schemas: list # Identifies which schema(s) this resource used. In this case, identifies the request as a SCIM PatchOp.
  Operations: list # A list of patch operations. <br><br> Updating the user to deactivated/reactivated, <br> { "op": "Replace", "path": "active", "value": "true/false" } must be provided in the Operations array.<br><br> Renaming the user, <br> { "op": "Replace", "path": "displayName", "value": "New displayName" } must be provided in the Operations array.<br><br> Upgrading userType (license) to Full, <br> { "op": "Replace", "path": "userType", "value": "Full" } must be provided in the Operations array. Note that userType (license) cannot be downgraded using this operation.<br><br> Updating userName of the user, <br> { "op": "Replace", "path": "userName", "value": "oleg@test.com" } must be provided in the Operations array. <br><br> Updating userRole of the user, { "op": "Replace", <br> "path": "roles[primary eq true].value", "value": "ORGANIZATION_INTERNAL_ADMIN" must be provided in the Operations array. Note that ORGANIZATION_INTERNAL_ADMIN and ORGANIZATION_INTERNAL_USER are the only supported primary user roles and guest roles are not supported. <br><br> Adding an admin role, <br> { "op": "Add", "path": "roles", "value": [{"value": "Content Admin", "type": "organization_admin_role", "primary": false}]} must be provided in the Operations array. <br><br> Removing an admin role, <br> { "op": "Remove", "path":"roles[value eq \"Content Admin\"]" } must be provided in the Operations array. <br><br> Updating department of the user, <br> { "op": "Replace", "path": "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:department", "value": "IT" } must be provided in the Operations array. Similarly, attributes such as employeeNumber, costCentre, organization, division, manager (displayName and value) can also be updated.  — item shape: {op: "Add"|"Remove"|"Replace", path: string, value: string}
]: any -> record<schemas: list<string>, id: string, meta: record<resourceType: string, location: string>, userName: string, name: record<formatted: string, familyName: string, givenName: string>, displayName: string, userType: string, active: bool, emails: table<value: string, type: string, primary: bool>, photos: table<type: string, value: string>, groups: table<value: string, display: string>, roles: table<type: string, value: string, display: string, primary: bool>, preferredLanguage: string, urn_ietf_params_scim_schemas_extension_enterprise_2_0_User: record<employeeNumber: string, costCenter: string, organization: string, division: string, department: string, manager: record<displayName: string, value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Users/($id)")
  let body = {schemas: $schemas, Operations: $Operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete user
#
# DELETE /Users/{id}
# operationId: deleteUser
export def "users delete" [
  id: string
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
  let full_url = (build-url $base $"/Users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List groups
#
# GET /Groups
# operationId: listGroups
export def "groups listGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --attributes: string # A comma-separated list of attribute names to return in the response. <br><br> Example attributes: id,displayName <br> Note</b>: It is also possible to fetch attributes within complex attributes, for Example: members.display.
  --filter: string # You can request a subset of resources by specifying the filter query parameter containing a filter expression. Attribute names and attribute operators used in filters are not case sensitive. The filter parameter must contain at least one valid expression. Each expression must contain an attribute name followed by an attribute operator and an optional value. <br>eq = equal<br> ne = not equal<br> co = contains<br> sw = starts with<br> ew = ends with<br> pr = preset (has value)<br> gt = greater than<br> ge = greater than or equal to<br> lt = less than<br> le = less than or equal to<br> and = Logical "and"<br> or = Logical "or"<br> not = "Not" function<br> () = Precedence grouping <br>The value must be passed within parenthesis. <br><br>For Example: displayName eq "Product Team" will fetch information related to team matching the display name "Product Team". <br>Note</b>: Filtering on complex attributes is not supported
  --startIndex: int # Use startIndex in combination with count query parameters to receive paginated results. <br><br> start index is 1-based. <br><br> Example: startIndex=1
  --count: int # Specifies the maximum number of query results per page. <br><br> Use count in combination with startIndex query parameters to receive paginated results. <br><br> The count query parameter is set to 100 by default and the maximum value allowed for this parameter is 1000. <br><br> Example: count=12
  --sortBy: string # Specifies the attribute whose value will be used to order the response. Example sortBy=displayName
  --sortOrder: string@sortOrder-completer # Defines the order in which the 'sortBy' parameter is applied. Example: sortOrder=ascending
]: nothing -> record<schemas: list<string>, totalResults: float, startIndex: float, itemsPerPage: float, Resources: table<schemas: list, id: string, displayName: string, members: list, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Groups" $qp)
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get group
#
# GET /Groups/{id}
# operationId: getGroup
export def "groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --attributes: string # A comma-separated list of attribute names to return in the response. <br><br> Example attributes: id,displayName <br> Note</b>: It is also possible to retrieve attributes within complex attributes. For example: members.display
]: nothing -> record<schemas: list<string>, id: string, meta: record<resourceType: string, location: string>, displayName: string, members: table<value: string, type: string, display: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Groups/($id)" $qp)
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch group
#
# PATCH /Groups/{id}
# operationId: patchGroup
# --Operations item shape: {op: "Add"|"Remove"|"Replace", path?: "members"|"displayName", value?: any}
export def "groups patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --attributes: string # A comma-separated list of attribute names to return in the response. <br><br> Example attributes: id,displayName <br> It is also possible to fetch attributes within complex attributes, for Example: members.display
  schemas: list@schemas-completer # Identifies which schema(s) this resource uses. In this case it is the PatchOp schema.
  Operations: list # A list of patch operations. <br><br> Multiple users can be added or removed from the group (team) in one request. use the array to add or remove multiple users.<br><br> For updating security group name: <br> "op"="replace", "value"={"id":"13266533725732", "displayName":"New group name"} must be provided in the Operations array. — item shape: {op: "Add"|"Remove"|"Replace", path?: "members"|"displayName", value?: any}
]: any -> record<schemas: list<string>, id: string, meta: record<resourceType: string, location: string>, displayName: string, members: table<value: string, type: string, display: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Groups/($id)" $qp)
  let body = {schemas: $schemas, Operations: $Operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Service Provider Config
#
# GET /ServiceProviderConfig
# operationId: listServiceProviderConfigs
export def "service-provider-config listServiceProviderConfigs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<schemas: list<string>, documentationUri: string, patch: record<supported: bool>, bulk: record<supported: bool, maxOperations: float, maxPayloadSize: float>, filter: record<supported: bool, maxResults: float>, changePassword: record<supported: bool>, sort: record<supported: bool>, etag: record<supported: bool>, authenticationSchemes: table<name: string, description: string, specUri: string, type: string, primary: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ServiceProviderConfig")
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List resource types
#
# GET /ResourceTypes
# operationId: listResourceTypes
export def "resource-types listResourceTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<schemas: list<string>, totalResults: float, Resources: table<schemas: list, id: string, name: string, description: string, endpoint: string, schema: string, schemaExtensions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ResourceTypes")
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get resource type
#
# GET /ResourceTypes/{resource}
# operationId: getResourceType
export def "resource-types get" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<schemas: list<string>, id: string, name: string, description: string, endpoint: string, schema: string, schemaExtensions: table<schema: string, required: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ResourceTypes/($resource)")
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List schemas
#
# GET /Schemas
# operationId: listSchemas
export def "schemas listSchemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<schemas: list<string>, totalResults: float, Resources: table<schemas: list, id: string, name: string, description: string, attributes: list, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Schemas")
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get schema
#
# GET /Schemas/{uri}
# operationId: getSchema
export def "schemas get" [
  uri: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, name: string, description: string, attributes: table<schemas: list, name: string, type: string, multiValued: bool, description: string, required: bool, subAttributes: list, caseExact: bool, mutability: string, returned: string, uniqueness: string>, meta: record<resourceType: string, location: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Schemas/($uri)")
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization info
#
# GET /v2/orgs/{org_id}
# operationId: enterprise-get-organization
export def "orgs enterprise-get-organization" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, fullLicensesPurchased: int, name: string, plan: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization members
#
# GET /v2/orgs/{org_id}/members
# operationId: enterprise-get-organization-members
export def "orgs-members enterprise-get-organization-members" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --emails: string # e.g. someEmail1@miro.com
  --role: string@role-completer
  --license: string@license-completer
  --active: string@bool-completer
  --cursor: string # e.g. 3055557345821141000
  --limit: int # format: int32, default: 100, e.g. 100
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "emails" $emails "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "license" $license "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization member
#
# GET /v2/orgs/{org_id}/members/{member_id}
# operationId: enterprise-get-organization-member
export def "orgs-members enterprise-get-organization-member" [
  org_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, active: bool, email: string, lastActivityAt: string, license: string, licenseAssignedAt: string, role: string, type: string, adminRoles: table<type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create board
#
# POST /v2/boards
# operationId: create-board
# --policy shape: {permissionsPolicy?: record, sharingPolicy?: record}
export def "boards create-board" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the board.
  --name: string # Name for the board. (default: Untitled)
  --policy: record # Defines the permissions policies and sharing policies for the board. — shape: {permissionsPolicy?: record, sharingPolicy?: record}
  --teamId: string # Unique identifier (ID) of the team where the board must be placed.  **Note**: On Enterprise plan, boards can be moved via API by Board Owners, Co-Owners, and Content Admins. This behavior differs from the Miro UI, where only Board Owners can move boards. This difference is **intentional** and works as designed. On non-Enterprise plans, only Board Owners can move boards between teams—both via the API and the Miro UI.
  --projectId: string # Unique identifier (ID) of the project to which the board must be added.  **Note**: Projects have been renamed to Spaces. Use this parameter to update the space. For Starter and Edu plans, Team Admins looking to move boards between Spaces/Projects of the same team would need to be direct Board Editors on the boards to move.
]: any -> record<id: string, name: string, description: string, team: record<id: string, name: string, picture: record<id: float, imageURL: string, originalUrl: string, type: string>, type: string>, project: record<id: string>, picture: record<id: float, imageURL: string, originalUrl: string, type: string>, policy: record<permissionsPolicy: record<collaborationToolsStartAccess: string, copyAccess: string, sharingAccess: string>, sharingPolicy: record<access: string, accessPasswordRequired: bool, inviteToAccountAndBoardLinkAccess: string, organizationAccess: string, teamAccess: string>>, viewLink: string, owner: record<id: string, name: string, type: string>, currentUserMembership: record<id: string, name: string, role: string, type: string>, createdAt: string, createdBy: record<id: string, name: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, name: string, type: string>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/boards")
  let body = {description: $description, name: $name, policy: $policy, teamId: $teamId, projectId: $projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get boards
#
# GET /v2/boards
# operationId: get-boards
export def "boards get-boards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: string
  --project-id: string
  --qp-query: string
  --owner: string
  --limit: string
  --offset: string
  --qp-sort: string@sort-completer # default: default
]: nothing -> record<data: table<createdAt: string, createdBy: record, currentUserMembership: record, description: string, id: string, lastOpenedAt: string, lastOpenedBy: record, modifiedAt: string, modifiedBy: record, name: string, owner: record, picture: record, policy: record, team: record, project: record, type: string, viewLink: string>, total: int, size: int, offset: int, limit: int, links: record<first: string, last: string, next: string, prev: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/boards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy board
#
# PUT /v2/boards
# operationId: copy-board
# --policy shape: {permissionsPolicy?: record, sharingPolicy?: record}
export def "boards copy-board" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --copy-from: string # Unique identifier (ID) of the board that you want to copy.
  --description: string # Description of the board.
  --name: string # Name for the board. (default: Untitled)
  --policy: record # Defines the permissions policies and sharing policies for the board. — shape: {permissionsPolicy?: record, sharingPolicy?: record}
  --teamId: string # Unique identifier (ID) of the team where the board must be placed.
]: any -> record<id: string, name: string, description: string, team: record<id: string, name: string, picture: record<id: float, imageURL: string, originalUrl: string, type: string>, type: string>, picture: record<id: float, imageURL: string, originalUrl: string, type: string>, policy: record<permissionsPolicy: record<collaborationToolsStartAccess: string, copyAccess: string, sharingAccess: string>, sharingPolicy: record<access: string, accessPasswordRequired: bool, inviteToAccountAndBoardLinkAccess: string, organizationAccess: string, teamAccess: string>>, viewLink: string, owner: record<id: string, name: string, type: string>, currentUserMembership: record<id: string, name: string, role: string, type: string>, createdAt: string, createdBy: record<id: string, name: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, name: string, type: string>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "copy_from" $copy_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/boards" $qp)
  let body = {description: $description, name: $name, policy: $policy, teamId: $teamId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get specific board
#
# GET /v2/boards/{board_id}
# operationId: get-specific-board
export def "boards get-specific-board" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, team: record<id: string, name: string, picture: record<id: float, imageURL: string, originalUrl: string, type: string>, type: string>, project: record<id: string>, picture: record<id: float, imageURL: string, originalUrl: string, type: string>, policy: record<permissionsPolicy: record<collaborationToolsStartAccess: string, copyAccess: string, sharingAccess: string>, sharingPolicy: record<access: string, accessPasswordRequired: bool, inviteToAccountAndBoardLinkAccess: string, organizationAccess: string, teamAccess: string>>, viewLink: string, owner: record<id: string, name: string, type: string>, currentUserMembership: record<id: string, name: string, role: string, type: string>, createdAt: string, createdBy: record<id: string, name: string, type: string>, lastOpenedAt: string, lastOpenedBy: record<id: string, name: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, name: string, type: string>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update board
#
# PATCH /v2/boards/{board_id}
# operationId: update-board
# --policy shape: {permissionsPolicy?: record, sharingPolicy?: record}
export def "boards update-board" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the board.
  --name: string # Name for the board. (default: Untitled)
  --policy: record # Defines the permissions policies and sharing policies for the board. — shape: {permissionsPolicy?: record, sharingPolicy?: record}
  --teamId: string # Unique identifier (ID) of the team where the board must be placed.  **Note**: On Enterprise plan, boards can be moved via API by Board Owners, Co-Owners, and Content Admins. This behavior differs from the Miro UI, where only Board Owners can move boards. This difference is **intentional** and works as designed. On non-Enterprise plans, only Board Owners can move boards between teams—both via the API and the Miro UI.
  --projectId: string # Unique identifier (ID) of the project to which the board must be added.  **Note**: Projects have been renamed to Spaces. Use this parameter to update the space. For Starter and Edu plans, Team Admins looking to move boards between Spaces/Projects of the same team would need to be direct Board Editors on the boards to move.
]: any -> record<id: string, name: string, description: string, team: record<id: string, name: string, picture: record<id: float, imageURL: string, originalUrl: string, type: string>, type: string>, project: record<id: string>, picture: record<id: float, imageURL: string, originalUrl: string, type: string>, policy: record<permissionsPolicy: record<collaborationToolsStartAccess: string, copyAccess: string, sharingAccess: string>, sharingPolicy: record<access: string, accessPasswordRequired: bool, inviteToAccountAndBoardLinkAccess: string, organizationAccess: string, teamAccess: string>>, viewLink: string, owner: record<id: string, name: string, type: string>, currentUserMembership: record<id: string, name: string, role: string, type: string>, createdAt: string, createdBy: record<id: string, name: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, name: string, type: string>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)")
  let body = {description: $description, name: $name, policy: $policy, teamId: $teamId, projectId: $projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete board
#
# DELETE /v2/boards/{board_id}
# operationId: delete-board
export def "boards delete-board" [
  board_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create app card item
#
# POST /v2/boards/{board_id}/app_cards
# operationId: create-app-card-item
# --data shape: {description?: string, fields?: list, status?: "disconnected"|"connected"|"disabled", title?: string}
# --style shape: {fillColor?: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-app-cards create-app-card-item" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains app card item data, such as the title, description, or fields. — shape: {description?: string, fields?: list, status?: "disconnected"|"connected"|"disabled", title?: string}
  --style: record # Contains information about the style of an app card item, such as the fill color. — shape: {fillColor?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<description: string, fields: list<record>, owned: bool, status: string, title: string>, style: record<fillColor: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/app_cards")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get app card item
#
# GET /v2/boards/{board_id}/app_cards/{item_id}
# operationId: get-app-card-item
export def "boards-app-cards get-app-card-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<description: string, fields: list<record>, owned: bool, status: string, title: string>, style: record<fillColor: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/app_cards/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update app card item
#
# PATCH /v2/boards/{board_id}/app_cards/{item_id}
# operationId: update-app-card-item
# --data shape: {description?: string, fields?: list, status?: "disconnected"|"connected"|"disabled", title?: string}
# --style shape: {fillColor?: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-app-cards update-app-card-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains app card item data, such as the title, description, or fields. — shape: {description?: string, fields?: list, status?: "disconnected"|"connected"|"disabled", title?: string}
  --style: record # Contains information about the style of an app card item, such as the fill color. — shape: {fillColor?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<description: string, fields: list<record>, owned: bool, status: string, title: string>, style: record<fillColor: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/app_cards/($item_id)")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete app card item
#
# DELETE /v2/boards/{board_id}/app_cards/{item_id}
# operationId: delete-app-card-item
export def "boards-app-cards delete-app-card-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/app_cards/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create card item
#
# POST /v2/boards/{board_id}/cards
# operationId: create-card-item
# --data shape: {assigneeId?: string, description?: string, dueDate?: string, title?: string}
# --style shape: {cardTheme?: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-cards create-card-item" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains card item data, such as the title, description, due date, or assignee ID. — shape: {assigneeId?: string, description?: string, dueDate?: string, title?: string}
  --style: record # Contains information about the style of a card item, such as the card theme. — shape: {cardTheme?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<assigneeId: string, description: string, dueDate: string, title: string>, style: record<cardTheme: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/cards")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get card item
#
# GET /v2/boards/{board_id}/cards/{item_id}
# operationId: get-card-item
export def "boards-cards get-card-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<assigneeId: string, description: string, dueDate: string, title: string>, style: record<cardTheme: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/cards/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update card item
#
# PATCH /v2/boards/{board_id}/cards/{item_id}
# operationId: update-card-item
# --data shape: {assigneeId?: string, description?: string, dueDate?: string, title?: string}
# --style shape: {cardTheme?: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-cards update-card-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains card item data, such as the title, description, due date, or assignee ID. — shape: {assigneeId?: string, description?: string, dueDate?: string, title?: string}
  --style: record # Contains information about the style of a card item, such as the card theme. — shape: {cardTheme?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<assigneeId: string, description: string, dueDate: string, title: string>, style: record<cardTheme: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/cards/($item_id)")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete card item
#
# DELETE /v2/boards/{board_id}/cards/{item_id}
# operationId: delete-card-item
export def "boards-cards delete-card-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/cards/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create connector
#
# POST /v2/boards/{board_id}/connectors
# operationId: create-connector
# --startItem shape: {id?: string, position?: record, snapTo?: "auto"|"top"|"right"|"bottom"|"left"}
# --endItem shape: {id?: string, position?: record, snapTo?: "auto"|"top"|"right"|"bottom"|"left"}
# --captions item shape: {content: string, position?: string, textAlignVertical?: "top"|"middle"|"bottom"}
# --style shape: {color?: string, endStrokeCap?: "none"|"stealth"|"rounded_stealth"|"diamond"|"filled_diamond"|"oval"|"filled_oval"|"arrow"|"triangle"|"filled_triangle"|"erd_one"|"erd_many"|"erd_only_one"|"erd_zero_or_one"|"erd_one_or_many"|"erd_zero_or_many"|"unknown", fontSize?: string, startStrokeCap?: "none"|"stealth"|"rounded_stealth"|"diamond"|"filled_diamond"|"oval"|"filled_oval"|"arrow"|"triangle"|"filled_triangle"|"erd_one"|"erd_many"|"erd_only_one"|"erd_zero_or_one"|"erd_one_or_many"|"erd_zero_or_many"|"unknown", strokeColor?: string, strokeStyle?: "normal"|"dotted"|"dashed", strokeWidth?: string, textOrientation?: "horizontal"|"aligned"}
export def "boards-connectors create-connector" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  startItem: record # The end point of the connector. endItem.id must be different from startItem.id — shape: {id?: string, position?: record, snapTo?: "auto"|"top"|"right"|"bottom"|"left"}
  endItem: record # The end point of the connector. endItem.id must be different from startItem.id — shape: {id?: string, position?: record, snapTo?: "auto"|"top"|"right"|"bottom"|"left"}
  --shape: string@shape-completer # The path type of the connector line, defines curvature. Default: curved.
  --captions: list # Blocks of text you want to display on the connector. — item shape: {content: string, position?: string, textAlignVertical?: "top"|"middle"|"bottom"}
  --style: record # Contains information about the style of a connector, such as the color or caption font size — shape: {color?: string, endStrokeCap?: "none"|"stealth"|"rounded_stealth"|"diamond"|"filled_diamond"|"oval"|"filled_oval"|"arrow"|"triangle"|"filled_triangle"|"erd_one"|"erd_many"|"erd_only_one"|"erd_zero_or_one"|"erd_one_or_many"|"erd_zero_or_many"|"unknown", fontSize?: string, startStrokeCap?: "none"|"stealth"|"rounded_stealth"|"diamond"|"filled_diamond"|"oval"|"filled_oval"|"arrow"|"triangle"|"filled_triangle"|"erd_one"|"erd_many"|"erd_only_one"|"erd_zero_or_one"|"erd_one_or_many"|"erd_zero_or_many"|"unknown", strokeColor?: string, strokeStyle?: "normal"|"dotted"|"dashed", strokeWidth?: string, textOrientation?: "horizontal"|"aligned"}
]: any -> record<captions: table<content: string, position: string, textAlignVertical: string>, createdAt: string, createdBy: record<id: string, type: string>, endItem: record<id: string, links: record<self: string>, position: record<x: string, y: string>>, id: string, isSupported: bool, links: record<self: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, shape: string, startItem: record<id: string, links: record<self: string>, position: record<x: string, y: string>>, style: record<color: string, endStrokeCap: string, fontSize: string, startStrokeCap: string, strokeColor: string, strokeStyle: string, strokeWidth: string, textOrientation: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/connectors")
  let body = {startItem: $startItem, endItem: $endItem, shape: $shape, captions: $captions, style: $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get connectors
#
# GET /v2/boards/{board_id}/connectors
# operationId: get-connectors
export def "boards-connectors get-connectors" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # default: 10
  --cursor: string
]: nothing -> record<cursor: string, data: table<captions: list, createdAt: string, createdBy: record, endItem: record, id: string, isSupported: bool, links: record, modifiedAt: string, modifiedBy: record, shape: string, startItem: record, style: record, type: string>, limit: int, links: record<first: string, last: string, next: string, prev: string, self: string>, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id)/connectors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specific connector
#
# GET /v2/boards/{board_id}/connectors/{connector_id}
# operationId: get-connector
export def "boards-connectors get-connector" [
  board_id: string
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<captions: table<content: string, position: string, textAlignVertical: string>, createdAt: string, createdBy: record<id: string, type: string>, endItem: record<id: string, links: record<self: string>, position: record<x: string, y: string>>, id: string, isSupported: bool, links: record<self: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, shape: string, startItem: record<id: string, links: record<self: string>, position: record<x: string, y: string>>, style: record<color: string, endStrokeCap: string, fontSize: string, startStrokeCap: string, strokeColor: string, strokeStyle: string, strokeWidth: string, textOrientation: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/connectors/($connector_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update connector
#
# PATCH /v2/boards/{board_id}/connectors/{connector_id}
# operationId: update-connector
# --startItem shape: {id?: string, position?: record, snapTo?: "auto"|"top"|"right"|"bottom"|"left"}
# --endItem shape: {id?: string, position?: record, snapTo?: "auto"|"top"|"right"|"bottom"|"left"}
# --captions item shape: {content: string, position?: string, textAlignVertical?: "top"|"middle"|"bottom"}
# --style shape: {color?: string, endStrokeCap?: "none"|"stealth"|"rounded_stealth"|"diamond"|"filled_diamond"|"oval"|"filled_oval"|"arrow"|"triangle"|"filled_triangle"|"erd_one"|"erd_many"|"erd_only_one"|"erd_zero_or_one"|"erd_one_or_many"|"erd_zero_or_many"|"unknown", fontSize?: string, startStrokeCap?: "none"|"stealth"|"rounded_stealth"|"diamond"|"filled_diamond"|"oval"|"filled_oval"|"arrow"|"triangle"|"filled_triangle"|"erd_one"|"erd_many"|"erd_only_one"|"erd_zero_or_one"|"erd_one_or_many"|"erd_zero_or_many"|"unknown", strokeColor?: string, strokeStyle?: "normal"|"dotted"|"dashed", strokeWidth?: string, textOrientation?: "horizontal"|"aligned"}
export def "boards-connectors update-connector" [
  board_id: string
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startItem: record # The ending point of the connector. If startItem is also provided, endItem.id must be different from startItem.id — shape: {id?: string, position?: record, snapTo?: "auto"|"top"|"right"|"bottom"|"left"}
  --endItem: record # The ending point of the connector. If startItem is also provided, endItem.id must be different from startItem.id — shape: {id?: string, position?: record, snapTo?: "auto"|"top"|"right"|"bottom"|"left"}
  --shape: string@shape-completer # The path type of the connector line, defines curvature. Default: curved.
  --captions: list # Blocks of text you want to display on the connector. — item shape: {content: string, position?: string, textAlignVertical?: "top"|"middle"|"bottom"}
  --style: record # Contains information about the style of a connector, such as the color or caption font size — shape: {color?: string, endStrokeCap?: "none"|"stealth"|"rounded_stealth"|"diamond"|"filled_diamond"|"oval"|"filled_oval"|"arrow"|"triangle"|"filled_triangle"|"erd_one"|"erd_many"|"erd_only_one"|"erd_zero_or_one"|"erd_one_or_many"|"erd_zero_or_many"|"unknown", fontSize?: string, startStrokeCap?: "none"|"stealth"|"rounded_stealth"|"diamond"|"filled_diamond"|"oval"|"filled_oval"|"arrow"|"triangle"|"filled_triangle"|"erd_one"|"erd_many"|"erd_only_one"|"erd_zero_or_one"|"erd_one_or_many"|"erd_zero_or_many"|"unknown", strokeColor?: string, strokeStyle?: "normal"|"dotted"|"dashed", strokeWidth?: string, textOrientation?: "horizontal"|"aligned"}
]: any -> record<captions: table<content: string, position: string, textAlignVertical: string>, createdAt: string, createdBy: record<id: string, type: string>, endItem: record<id: string, links: record<self: string>, position: record<x: string, y: string>>, id: string, isSupported: bool, links: record<self: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, shape: string, startItem: record<id: string, links: record<self: string>, position: record<x: string, y: string>>, style: record<color: string, endStrokeCap: string, fontSize: string, startStrokeCap: string, strokeColor: string, strokeStyle: string, strokeWidth: string, textOrientation: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/connectors/($connector_id)")
  let body = {startItem: $startItem, endItem: $endItem, shape: $shape, captions: $captions, style: $style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete connector
#
# DELETE /v2/boards/{board_id}/connectors/{connector_id}
# operationId: delete-connector
export def "boards-connectors delete-connector" [
  board_id: string
  connector_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/connectors/($connector_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create document item using URL
#
# POST /v2/boards/{board_id}/documents
# operationId: create-document-item-using-url
# --data shape: {title?: string, url: string}
# --position shape: {x?: float, y?: float}
# --parent shape: {id?: string}
export def "boards-documents create-document-item-using-url" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # Contains information about the document URL. — shape: {title?: string, url: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<documentUrl: string, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/documents")
  let body = {data: $data, position: $position, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get document item
#
# GET /v2/boards/{board_id}/documents/{item_id}
# operationId: get-document-item
export def "boards-documents get-document-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<documentUrl: string, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/documents/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update document item using URL
#
# PATCH /v2/boards/{board_id}/documents/{item_id}
# operationId: update-document-item-using-url
# --data shape: {title?: string, url?: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, width?: float, rotation?: float}
# --parent shape: {id?: string}
export def "boards-documents update-document-item-using-url" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains information about the document URL. — shape: {title?: string, url?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or rotation. You can set either the width or height, you cannot set both the width and height at the same time. — shape: {height?: float, width?: float, rotation?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<documentUrl: string, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/documents/($item_id)")
  let body = {data: $data, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete document item
#
# DELETE /v2/boards/{board_id}/documents/{item_id}
# operationId: delete-document-item
export def "boards-documents delete-document-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/documents/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create embed item
#
# POST /v2/boards/{board_id}/embeds
# operationId: create-embed-item
# --data shape: {mode?: "inline"|"modal", previewUrl?: string, url: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-embeds create-embed-item" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # Contains information about the embed URL. — shape: {mode?: "inline"|"modal", previewUrl?: string, url: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item. You can set either the width or height. You cannot set both the width and height at the same time. — shape: {height?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<contentType: string, description: string, html: string, mode: string, previewUrl: string, providerName: string, providerUrl: string, title: string, url: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/embeds")
  let body = {data: $data, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get embed item
#
# GET /v2/boards/{board_id}/embeds/{item_id}
# operationId: get-embed-item
export def "boards-embeds get-embed-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<contentType: string, description: string, html: string, mode: string, previewUrl: string, providerName: string, providerUrl: string, title: string, url: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/embeds/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update embed item
#
# PATCH /v2/boards/{board_id}/embeds/{item_id}
# operationId: update-embed-item
# --data shape: {mode?: "inline"|"modal", previewUrl?: string, url?: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-embeds update-embed-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains information about the embed URL. — shape: {mode?: "inline"|"modal", previewUrl?: string, url?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item. You can set either the width or height. You cannot set both the width and height at the same time. — shape: {height?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<contentType: string, description: string, html: string, mode: string, previewUrl: string, providerName: string, providerUrl: string, title: string, url: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/embeds/($item_id)")
  let body = {data: $data, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete embed item
#
# DELETE /v2/boards/{board_id}/embeds/{item_id}
# operationId: delete-embed-item
export def "boards-embeds delete-embed-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/embeds/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create image item using URL
#
# POST /v2/boards/{board_id}/images
# operationId: create-image-item-using-url
# --data shape: {title?: string, url: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, width?: float, rotation?: float}
# --parent shape: {id?: string}
export def "boards-images create-image-item-using-url" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # Contains information about the image URL. — shape: {title?: string, url: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or rotation. You can set either the width or height, you cannot set both the width and height at the same time. — shape: {height?: float, width?: float, rotation?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<imageUrl: string, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/images")
  let body = {data: $data, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get image item
#
# GET /v2/boards/{board_id}/images/{item_id}
# operationId: get-image-item
export def "boards-images get-image-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<imageUrl: string, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/images/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update image item using URL
#
# PATCH /v2/boards/{board_id}/images/{item_id}
# operationId: update-image-item-using-url
# --data shape: {title?: string, url?: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, width?: float, rotation?: float}
# --parent shape: {id?: string}
export def "boards-images update-image-item-using-url" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains information about the image URL. — shape: {title?: string, url?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or rotation. You can set either the width or height, you cannot set both the width and height at the same time. — shape: {height?: float, width?: float, rotation?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<imageUrl: string, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/images/($item_id)")
  let body = {data: $data, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete image item
#
# DELETE /v2/boards/{board_id}/images/{item_id}
# operationId: delete-image-item
export def "boards-images delete-image-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/images/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get items on board
#
# GET /v2/boards/{board_id}/items
# operationId: get-items
export def "boards-items get-items" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # default: 10
  --type: string@type-completer
  --cursor: string
]: nothing -> record<data: table<createdAt: string, createdBy: record, data: record, geometry: record, id: string, modifiedAt: string, modifiedBy: record, parent: record, position: record, type: string>, total: int, size: int, cursor: string, limit: int, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specific item on board
#
# GET /v2/boards/{board_id}/items/{item_id}
# operationId: get-specific-item
export def "boards-items get-specific-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, createdBy: record<id: string, type: string>, data: record, geometry: record<height: float, rotation: float, width: float>, id: string, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/items/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update item position or parent
#
# PATCH /v2/boards/{board_id}/items/{item_id}
# operationId: update-item-position-or-parent
# --parent shape: {id?: string}
# --position shape: {x?: float, y?: float}
export def "boards-items update-item-position-or-parent" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
]: any -> record<createdAt: string, createdBy: record<id: string, type: string>, data: record, geometry: record<height: float, rotation: float, width: float>, id: string, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/items/($item_id)")
  let body = {parent: $parent, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete item
#
# DELETE /v2/boards/{board_id}/items/{item_id}
# operationId: delete-item
export def "boards-items delete-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/items/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Share board
#
# POST /v2/boards/{board_id}/members
# operationId: share-board
export def "boards-members share-board" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  emails: list # Email IDs of the users you want to invite to the board. You can invite up to 20 members per call.
  --role: string@role-completer-1 # Role of the board member. Inviting users with the role `owner` has the same effect as the role `coowner`. (default: commenter)
  --message: string # The message that will be sent in the invitation email. (e.g. Hey there! Join my board and let's collaborate on this project!)
]: any -> record<failed: table<email: string, reason: string>, successful: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/members")
  let body = {emails: $emails, role: $role, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all board members
#
# GET /v2/boards/{board_id}/members
# operationId: get-board-members
export def "boards-members get-board-members" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string
  --offset: string
]: nothing -> record<data: table<id: string, name: string, role: string, type: string>, total: int, size: int, offset: int, limit: int, links: record<first: string, last: string, next: string, prev: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specific board member
#
# GET /v2/boards/{board_id}/members/{board_member_id}
# operationId: get-specific-board-member
export def "boards-members get-specific-board-member" [
  board_id: string
  board_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, role: string, links: record<self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/members/($board_member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update board member
#
# PATCH /v2/boards/{board_id}/members/{board_member_id}
# operationId: update-board-member
export def "boards-members update-board-member" [
  board_id: string
  board_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer-1 # Role of the board member. (default: commenter)
]: any -> record<id: string, name: string, role: string, links: record<self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/members/($board_member_id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove board member
#
# DELETE /v2/boards/{board_id}/members/{board_member_id}
# operationId: remove-board-member
export def "boards-members remove-board-member" [
  board_id: string
  board_member_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/members/($board_member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create shape item
#
# POST /v2/boards/{board_id}/shapes
# operationId: create-shape-item
# --data shape: {content?: string, shape?: string}
# --style shape: {borderColor?: string, borderOpacity?: string, borderStyle?: "normal"|"dotted"|"dashed", borderWidth?: string, color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center"|"unknown", textAlignVertical?: "top"|"middle"|"bottom"|"unknown"}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-shapes create-shape-item" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains shape item data, such as the content or the type of the shape. — shape: {content?: string, shape?: string}
  --style: record # Contains information about the shape style, such as the border color or opacity. <br> All properties in style object are supported for shape types aren't listed below. <br> <table>   <tr>     <th align="left">Shape type</th>     <th align="left">Unsupported properties</th>   </tr>   <tr>     <td>flow_chart_or</td>     <td>fontSize, fontFamily, color, textAlign, textAlignVertical</td>   </tr>   <tr>     <td>flow_chart_summing_junction</td>     <td>fontSize, fontFamily, color, textAlign, textAlignVertical</td>   </tr>   <tr>     <td>flow_chart_note_curly_left</td>     <td>fillColor, fillOpacity</td>   </tr>   <tr>     <td>flow_chart_note_curly_right</td>     <td>fillColor, fillOpacity</td>   </tr>   <tr>     <td>flow_chart_note_square</td>     <td>fillColor, fillOpacity</td>   </tr> </table> — shape: {borderColor?: string, borderOpacity?: string, borderStyle?: "normal"|"dotted"|"dashed", borderWidth?: string, color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center"|"unknown", textAlignVertical?: "top"|"middle"|"bottom"|"unknown"}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<content: string, shape: string>, style: record<borderColor: string, borderOpacity: string, borderStyle: string, borderWidth: string, color: string, fillColor: string, fillOpacity: string, fontFamily: string, fontSize: string, textAlign: string, textAlignVertical: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/shapes")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get shape item
#
# GET /v2/boards/{board_id}/shapes/{item_id}
# operationId: get-shape-item
export def "boards-shapes get-shape-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<content: string, shape: string>, style: record<borderColor: string, borderOpacity: string, borderStyle: string, borderWidth: string, color: string, fillColor: string, fillOpacity: string, fontFamily: string, fontSize: string, textAlign: string, textAlignVertical: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/shapes/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update shape item
#
# PATCH /v2/boards/{board_id}/shapes/{item_id}
# operationId: update-shape-item
# --data shape: {content?: string, shape?: string}
# --style shape: {borderColor?: string, borderOpacity?: string, borderStyle?: "normal"|"dotted"|"dashed", borderWidth?: string, color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center", textAlignVertical?: "top"|"middle"|"bottom"}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-shapes update-shape-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains shape item data, such as the content or the type of the shape. — shape: {content?: string, shape?: string}
  --style: record # Contains information about the shape style, such as the border color or opacity. <br> All properties in style object are supported for shape types aren't listed below. <br> <table>   <tr>     <th align="left">Shape type</th>     <th align="left">Unsupported properties</th>   </tr>   <tr>     <td>flow_chart_or</td>     <td>fontSize, fontFamily, color, textAlign, textAlignVertical</td>   </tr>   <tr>     <td>flow_chart_summing_junction</td>     <td>fontSize, fontFamily, color, textAlign, textAlignVertical</td>   </tr>   <tr>     <td>flow_chart_note_curly_left</td>     <td>fillColor, fillOpacity</td>   </tr>   <tr>     <td>flow_chart_note_curly_right</td>     <td>fillColor, fillOpacity</td>   </tr>   <tr>     <td>flow_chart_note_square</td>     <td>fillColor, fillOpacity</td>   </tr> </table> — shape: {borderColor?: string, borderOpacity?: string, borderStyle?: "normal"|"dotted"|"dashed", borderWidth?: string, color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center", textAlignVertical?: "top"|"middle"|"bottom"}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<content: string, shape: string>, style: record<borderColor: string, borderOpacity: string, borderStyle: string, borderWidth: string, color: string, fillColor: string, fillOpacity: string, fontFamily: string, fontSize: string, textAlign: string, textAlignVertical: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/shapes/($item_id)")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete shape item
#
# DELETE /v2/boards/{board_id}/shapes/{item_id}
# operationId: delete-shape-item
export def "boards-shapes delete-shape-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/shapes/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create sticky note item
#
# POST /v2/boards/{board_id}/sticky_notes
# operationId: create-sticky-note-item
# --data shape: {content?: string, shape?: "square"|"rectangle"}
# --style shape: {fillColor?: "gray"|"light_yellow"|"yellow"|"orange"|"light_green"|"green"|"dark_green"|"cyan"|"light_pink"|"pink"|"violet"|"red"|"light_blue"|"blue"|"dark_blue"|"black", textAlign?: "left"|"right"|"center", textAlignVertical?: "top"|"middle"|"bottom"}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-sticky-notes create-sticky-note-item" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains sticky note item data, such as the content or shape of the sticky note. — shape: {content?: string, shape?: "square"|"rectangle"}
  --style: record # Contains information about the style of a sticky note item, such as the fill color or text alignment. — shape: {fillColor?: "gray"|"light_yellow"|"yellow"|"orange"|"light_green"|"green"|"dark_green"|"cyan"|"light_pink"|"pink"|"violet"|"red"|"light_blue"|"blue"|"dark_blue"|"black", textAlign?: "left"|"right"|"center", textAlignVertical?: "top"|"middle"|"bottom"}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item. You can set either the width or height. You cannot set both the width and height at the same time. — shape: {height?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<content: string, shape: string>, style: record<fillColor: string, textAlign: string, textAlignVertical: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/sticky_notes")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get sticky note item
#
# GET /v2/boards/{board_id}/sticky_notes/{item_id}
# operationId: get-sticky-note-item
export def "boards-sticky-notes get-sticky-note-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<content: string, shape: string>, style: record<fillColor: string, textAlign: string, textAlignVertical: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/sticky_notes/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update sticky note item
#
# PATCH /v2/boards/{board_id}/sticky_notes/{item_id}
# operationId: update-sticky-note-item
# --data shape: {content?: string, shape?: "square"|"rectangle"}
# --style shape: {fillColor?: "gray"|"light_yellow"|"yellow"|"orange"|"light_green"|"green"|"dark_green"|"cyan"|"light_pink"|"pink"|"violet"|"red"|"light_blue"|"blue"|"dark_blue"|"black", textAlign?: "left"|"right"|"center", textAlignVertical?: "top"|"middle"|"bottom"}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-sticky-notes update-sticky-note-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains sticky note item data, such as the content or shape of the sticky note. — shape: {content?: string, shape?: "square"|"rectangle"}
  --style: record # Contains information about the style of a sticky note item, such as the fill color or text alignment. — shape: {fillColor?: "gray"|"light_yellow"|"yellow"|"orange"|"light_green"|"green"|"dark_green"|"cyan"|"light_pink"|"pink"|"violet"|"red"|"light_blue"|"blue"|"dark_blue"|"black", textAlign?: "left"|"right"|"center", textAlignVertical?: "top"|"middle"|"bottom"}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item. You can set either the width or height. You cannot set both the width and height at the same time. — shape: {height?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<content: string, shape: string>, style: record<fillColor: string, textAlign: string, textAlignVertical: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/sticky_notes/($item_id)")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete sticky note item
#
# DELETE /v2/boards/{board_id}/sticky_notes/{item_id}
# operationId: delete-sticky-note-item
export def "boards-sticky-notes delete-sticky-note-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/sticky_notes/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create text item
#
# POST /v2/boards/{board_id}/texts
# operationId: create-text-item
# --data shape: {content: string}
# --style shape: {color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center"}
# --position shape: {x?: float, y?: float}
# --geometry shape: {rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-texts create-text-item" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # Contains text item data, such as the title, content, or description. For more information on the JSON properties, see [Data](https://developers.miro.com/reference/data). — shape: {content: string}
  --style: record # Contains information about the style of a text item, such as the fill color or font family. — shape: {color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center"}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or rotation. You can only specify the width of the text item as the height is dynamically updated based on the content. — shape: {rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<content: string>, style: record<color: string, fillColor: string, fillOpacity: string, fontFamily: string, fontSize: string, textAlign: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/texts")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get text item
#
# GET /v2/boards/{board_id}/texts/{item_id}
# operationId: get-text-item
export def "boards-texts get-text-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<content: string>, style: record<color: string, fillColor: string, fillOpacity: string, fontFamily: string, fontSize: string, textAlign: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/texts/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update text item
#
# PATCH /v2/boards/{board_id}/texts/{item_id}
# operationId: update-text-item
# --data shape: {content: string}
# --style shape: {color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center"}
# --position shape: {x?: float, y?: float}
# --geometry shape: {rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "boards-texts update-text-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains text item data, such as the title, content, or description. For more information on the JSON properties, see [Data](https://developers.miro.com/reference/data). — shape: {content: string}
  --style: record # Contains information about the style of a text item, such as the fill color or font family. — shape: {color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center"}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or rotation. You can only specify the width of the text item as the height is dynamically updated based on the content. — shape: {rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<content: string>, style: record<color: string, fillColor: string, fillOpacity: string, fontFamily: string, fontSize: string, textAlign: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/texts/($item_id)")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete text item
#
# DELETE /v2/boards/{board_id}/texts/{item_id}
# operationId: delete-text-item
export def "boards-texts delete-text-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/texts/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create items in bulk
#
# POST /v2/boards/{board_id}/items/bulk
# operationId: create-items
export def "boards-items-bulk create-items" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<data: table<id: string, type: string, data: record, position: record, geometry: record, parent: record, createdBy: record, createdAt: string, modifiedBy: record, modifiedAt: string, links: record>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/items/bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create frame
#
# POST /v2/boards/{board_id}/frames
# operationId: create-frame-item
# --data shape: {format?: "custom", title?: string, type?: "freeform", showContent?: bool}
# --style shape: {fillColor?: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, width?: float}
export def "boards-frames create-frame-item" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # Contains frame item data, such as the title, frame type, or frame format. — shape: {format?: "custom", title?: string, type?: "freeform", showContent?: bool}
  --style: record # Contains information about the style of a frame item, such as the fill color. — shape: {fillColor?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, width?: float}
]: any -> record<id: string, data: record<format: string, title: string, type: string>, style: record<fillColor: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/frames")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get frame
#
# GET /v2/boards/{board_id}/frames/{item_id}
# operationId: get-frame-item
export def "boards-frames get-frame-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<format: string, title: string, type: string>, style: record<fillColor: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/frames/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update frame
#
# PATCH /v2/boards/{board_id}/frames/{item_id}
# operationId: update-frame-item
# --data shape: {format?: "custom", title?: string, type?: "freeform", showContent?: bool}
# --style shape: {fillColor?: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, width?: float}
export def "boards-frames update-frame-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains frame item data, such as the title, frame type, or frame format. — shape: {format?: "custom", title?: string, type?: "freeform", showContent?: bool}
  --style: record # Contains information about the style of a frame item, such as the fill color. — shape: {fillColor?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, width?: float}
]: any -> record<id: string, data: record<format: string, title: string, type: string>, style: record<fillColor: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/frames/($item_id)")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete frame
#
# DELETE /v2/boards/{board_id}/frames/{item_id}
# operationId: delete-frame-item
export def "boards-frames delete-frame-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/frames/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get items within frame
#
# GET /v2/boards/{board_id_PlatformContainers}/items
# operationId: get-items-within-frame
export def "boards-items get-items-within-frame" [
  board_id_PlatformContainers: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent-item-id: string # ID of the frame for which you want to retrieve the list of available items.
  --limit: string # default: 10
  --type: string
  --cursor: string
]: nothing -> record<data: table<createdAt: string, createdBy: record, data: record, geometry: record, id: string, modifiedAt: string, modifiedBy: record, parent: record, position: record, type: string>, total: int, size: int, cursor: string, limit: int, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_item_id" $parent_item_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id_PlatformContainers)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create items in bulk using file from device
#
# POST /v2/boards/{board_id_Platformcreateitemsinbulkusingfilefromdevice}/items/bulk
# operationId: create-items-in-bulk-using-file-from-device
export def "boards-items-bulk create-items-in-bulk-using-file-from-device" [
  board_id: string
  board_id_Platformcreateitemsinbulkusingfilefromdevice: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: string # JSON file containing bulk data, where each object represents an item to be created. For details, see [JSON file example](https://developers.miro.com/reference/json-data-example). (format: binary)
  resources: list # Array of items to create (PDFs, images, etc.). Maximum of 20 items.
]: any -> record<data: table<id: string, type: string, data: record, position: record, geometry: record, parent: record, createdBy: record, createdAt: string, modifiedBy: record, modifiedAt: string, links: record>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id_Platformcreateitemsinbulkusingfilefromdevice)/items/bulk")
  let body = {data: $data, resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get app metrics
#
# GET /v2-experimental/apps/{app_id}/metrics
# operationId: get-metrics
export def "v2-experimental-apps-metrics get-metrics" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # Start date of the period in UTC format. For example, 2024-12-31. (format: date)
  --endDate: string # End date of the period in UTC format. For example, 2024-12-31. (format: date)
  --period: string@period-completer # Group data by this time period. (default: WEEK)
]: nothing -> table<periodStart: string, uniqueUsers: int, uniqueRecurringUsers: int, uniqueOrganizations: int, installations: int, uninstallations: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2-experimental/apps/($app_id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get total app metrics
#
# GET /v2-experimental/apps/{app_id}/metrics-total
# operationId: get-metrics-total
export def "v2-experimental-apps-metrics-total get-metrics-total" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uniqueUsers: int, uniqueRecurringUsers: int, uniqueOrganizations: int, installations: int, uninstallations: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2-experimental/apps/($app_id)/metrics-total")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specific mind map node
#
# GET /v2-experimental/boards/{board_id}/mindmap_nodes/{item_id}
# operationId: get-mindmap-node-experimental
export def "v2-experimental-boards-mindmap-nodes get-mindmap-node-experimental" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<nodeView: record<type: string, data: any, style: record>, isRoot: bool, direction: string>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string, style: record<nodeColor: string, shape: string, fontSize: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/mindmap_nodes/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete mind map node
#
# DELETE /v2-experimental/boards/{board_id}/mindmap_nodes/{item_id}
# operationId: delete-mindmap-node-experimental
export def "v2-experimental-boards-mindmap-nodes delete-mindmap-node-experimental" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/mindmap_nodes/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get mind map nodes
#
# GET /v2-experimental/boards/{board_id}/mindmap_nodes
# operationId: get-mindmap-nodes-experimental
export def "v2-experimental-boards-mindmap-nodes get-mindmap-nodes-experimental" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # Maximum number of results returned
  --cursor: string # Points to the next portion of the results set
]: nothing -> record<data: table<id: string, data: record, createdAt: string, createdBy: record, modifiedAt: string, modifiedBy: record, parent: record, links: record, type: string, style: record>, total: int, size: int, cursor: string, limit: int, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/mindmap_nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create mind map node
#
# POST /v2-experimental/boards/{board_id}/mindmap_nodes
# operationId: create-mindmap-nodes-experimental
# --data shape: {nodeView: record}
# --position shape: {x?: float, y?: float}
# --geometry shape: {width?: float}
# --parent shape: {id?: string}
export def "v2-experimental-boards-mindmap-nodes create-mindmap-nodes-experimental" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # Contains mind map node data, such as the title, content, or description. — shape: {nodeView: record}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains width of the item. — shape: {width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<nodeView: record<type: string, data: any, style: record>, isRoot: bool, direction: string>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string, style: record<nodeColor: string, shape: string, fontSize: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/mindmap_nodes")
  let body = {data: $data, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get items on board
#
# GET /v2-experimental/boards/{board_id}/items
# operationId: get-items-experimental
export def "v2-experimental-boards-items get-items-experimental" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # default: 10
  --type: string@type-completer-1
  --cursor: string
]: nothing -> record<data: table<createdAt: string, createdBy: record, data: record, geometry: record, id: string, modifiedAt: string, modifiedBy: record, parent: record, position: record, type: string>, total: int, size: int, cursor: string, limit: int, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specific item on board
#
# GET /v2-experimental/boards/{board_id}/items/{item_id}
# operationId: get-specific-item-experimental
export def "v2-experimental-boards-items get-specific-item-experimental" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, createdBy: record<id: string, type: string>, data: record, geometry: record<height: float, rotation: float, width: float>, id: string, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/items/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete item
#
# DELETE /v2-experimental/boards/{board_id}/items/{item_id}
# operationId: delete-item-experimental
export def "v2-experimental-boards-items delete-item-experimental" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/items/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create shape item
#
# POST /v2-experimental/boards/{board_id}/shapes
# operationId: create-shape-item-flowchart
# --data shape: {content?: string, shape?: string}
# --style shape: {borderColor?: string, borderOpacity?: string, borderStyle?: "normal"|"dotted"|"dashed", borderWidth?: string, color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center"|"unknown", textAlignVertical?: "top"|"middle"|"bottom"|"unknown"}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "v2-experimental-boards-shapes create-shape-item-flowchart" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains shape item data, such as the content or the type of the shape. — shape: {content?: string, shape?: string}
  --style: record # Contains information about the shape style, such as the border color or opacity. <br> All properties in style object are supported for shape types aren't listed below. <br> <table>   <tr>     <th align="left">Shape type</th>     <th align="left">Unsupported properties</th>   </tr>   <tr>     <td>flow_chart_or</td>     <td>fontSize, fontFamily, color, textAlign, textAlignVertical</td>   </tr>   <tr>     <td>flow_chart_summing_junction</td>     <td>fontSize, fontFamily, color, textAlign, textAlignVertical</td>   </tr>   <tr>     <td>flow_chart_note_curly_left</td>     <td>fillColor, fillOpacity</td>   </tr>   <tr>     <td>flow_chart_note_curly_right</td>     <td>fillColor, fillOpacity</td>   </tr>   <tr>     <td>flow_chart_note_square</td>     <td>fillColor, fillOpacity</td>   </tr> </table> — shape: {borderColor?: string, borderOpacity?: string, borderStyle?: "normal"|"dotted"|"dashed", borderWidth?: string, color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center"|"unknown", textAlignVertical?: "top"|"middle"|"bottom"|"unknown"}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<content: string, shape: string>, style: record<borderColor: string, borderOpacity: string, borderStyle: string, borderWidth: string, color: string, fillColor: string, fillOpacity: string, fontFamily: string, fontSize: string, textAlign: string, textAlignVertical: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/shapes")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get shape item
#
# GET /v2-experimental/boards/{board_id}/shapes/{item_id}
# operationId: get-shape-item-flowchart
export def "v2-experimental-boards-shapes get-shape-item-flowchart" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<content: string, shape: string>, style: record<borderColor: string, borderOpacity: string, borderStyle: string, borderWidth: string, color: string, fillColor: string, fillOpacity: string, fontFamily: string, fontSize: string, textAlign: string, textAlignVertical: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/shapes/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update shape item
#
# PATCH /v2-experimental/boards/{board_id}/shapes/{item_id}
# operationId: update-shape-item-flowchart
# --data shape: {content?: string, shape?: string}
# --style shape: {borderColor?: string, borderOpacity?: string, borderStyle?: "normal"|"dotted"|"dashed", borderWidth?: string, color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center", textAlignVertical?: "top"|"middle"|"bottom"}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "v2-experimental-boards-shapes update-shape-item-flowchart" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains shape item data, such as the content or the type of the shape. — shape: {content?: string, shape?: string}
  --style: record # Contains information about the shape style, such as the border color or opacity. <br> All properties in style object are supported for shape types aren't listed below. <br> <table>   <tr>     <th align="left">Shape type</th>     <th align="left">Unsupported properties</th>   </tr>   <tr>     <td>flow_chart_or</td>     <td>fontSize, fontFamily, color, textAlign, textAlignVertical</td>   </tr>   <tr>     <td>flow_chart_summing_junction</td>     <td>fontSize, fontFamily, color, textAlign, textAlignVertical</td>   </tr>   <tr>     <td>flow_chart_note_curly_left</td>     <td>fillColor, fillOpacity</td>   </tr>   <tr>     <td>flow_chart_note_curly_right</td>     <td>fillColor, fillOpacity</td>   </tr>   <tr>     <td>flow_chart_note_square</td>     <td>fillColor, fillOpacity</td>   </tr> </table> — shape: {borderColor?: string, borderOpacity?: string, borderStyle?: "normal"|"dotted"|"dashed", borderWidth?: string, color?: string, fillColor?: string, fillOpacity?: string, fontFamily?: "arial"|"abril_fatface"|"bangers"|"eb_garamond"|"georgia"|"graduate"|"gravitas_one"|"fredoka_one"|"nixie_one"|"open_sans"|"permanent_marker"|"pt_sans"|"pt_sans_narrow"|"pt_serif"|"rammetto_one"|"roboto"|"roboto_condensed"|"roboto_slab"|"caveat"|"times_new_roman"|"titan_one"|"lemon_tuesday"|"roboto_mono"|"noto_sans"|"plex_sans"|"plex_serif"|"plex_mono"|"spoof"|"tiempos_text"|"formular", fontSize?: string, textAlign?: "left"|"right"|"center", textAlignVertical?: "top"|"middle"|"bottom"}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<content: string, shape: string>, style: record<borderColor: string, borderOpacity: string, borderStyle: string, borderWidth: string, color: string, fillColor: string, fillOpacity: string, fontFamily: string, fontSize: string, textAlign: string, textAlignVertical: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/shapes/($item_id)")
  let body = {data: $data, style: $style, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete shape item
#
# DELETE /v2-experimental/boards/{board_id}/shapes/{item_id}
# operationId: delete-shape-item-flowchart
export def "v2-experimental-boards-shapes delete-shape-item-flowchart" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/shapes/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get code widget items
#
# GET /v2-experimental/boards/{board_id}/code_widgets
# operationId: get-code-widget-items
export def "v2-experimental-boards-code-widgets get-code-widget-items" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # default: 10
  --cursor: string
]: nothing -> record<data: table<id: string, data: record, position: record, geometry: record, createdAt: string, createdBy: record, modifiedAt: string, modifiedBy: record, links: record, type: string>, total: int, size: int, cursor: string, limit: int, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/code_widgets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create code widget item
#
# POST /v2-experimental/boards/{board_id}/code_widgets
# operationId: create-code-widget-item
# --data shape: {code?: string, language?: string, lineNumbersVisible?: bool, title?: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "v2-experimental-boards-code-widgets create-code-widget-item" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains the data properties of a code widget item, such as the code content, programming language, and display settings. — shape: {code?: string, language?: string, lineNumbersVisible?: bool, title?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<code: string, language: string, lineNumbersVisible: bool, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/code_widgets")
  let body = {data: $data, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get code widget item
#
# GET /v2-experimental/boards/{board_id}/code_widgets/{item_id}
# operationId: get-code-widget-item
export def "v2-experimental-boards-code-widgets get-code-widget-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, data: record<code: string, language: string, lineNumbersVisible: bool, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, links: record<related: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/code_widgets/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update code widget item
#
# PATCH /v2-experimental/boards/{board_id}/code_widgets/{item_id}
# operationId: update-code-widget-item
# --data shape: {code?: string, language?: string, lineNumbersVisible?: bool, title?: string}
# --position shape: {x?: float, y?: float}
# --geometry shape: {height?: float, rotation?: float, width?: float}
# --parent shape: {id?: string}
export def "v2-experimental-boards-code-widgets update-code-widget-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Contains the data properties of a code widget item, such as the code content, programming language, and display settings. — shape: {code?: string, language?: string, lineNumbersVisible?: bool, title?: string}
  --position: record # Contains information about the item's position on the board, such as its `x` coordinate, `y` coordinate, and the origin of the `x` and `y` coordinates. — shape: {x?: float, y?: float}
  --geometry: record # Contains geometrical information about the item, such as its width or height. — shape: {height?: float, rotation?: float, width?: float}
  --parent: record # Contains information about the parent frame for the item. — shape: {id?: string}
]: any -> record<id: string, data: record<code: string, language: string, lineNumbersVisible: bool, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/code_widgets/($item_id)")
  let body = {data: $data, position: $position, geometry: $geometry, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete code widget item
#
# DELETE /v2-experimental/boards/{board_id}/code_widgets/{item_id}
# operationId: delete-code-widget-item
export def "v2-experimental-boards-code-widgets delete-code-widget-item" [
  board_id: string
  item_id: string
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
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/code_widgets/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move code widget item
#
# PATCH /v2-experimental/boards/{board_id}/code_widgets/{item_id}/position
# operationId: move-code-widget-item
export def "v2-experimental-boards-code-widgets-position move-code-widget-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x: float # X-axis coordinate of the location of the item on the board. By default, all items have absolute positioning to the board, not the current viewport. Default: `0`. The center point of the board has `x: 0` and `y: 0` coordinates. (format: double, default: 0, e.g. 100)
  --y: float # Y-axis coordinate of the location of the item on the board. By default, all items have absolute positioning to the board, not the current viewport. Default: `0`. The center point of the board has `x: 0` and `y: 0` coordinates. (format: double, default: 0, e.g. 100)
]: any -> record<id: string, data: record<code: string, language: string, lineNumbersVisible: bool, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2-experimental/boards/($board_id)/code_widgets/($item_id)/position")
  let body = {x: $x, y: $y} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create document item using file from device
#
# POST /v2/boards/{board_id_PlatformFileUpload}/documents
# operationId: create-document-item-using-file-from-device
# --data shape: {title?: string, position?: record, geometry?: record, parent?: record}
export def "boards-documents create-document-item-using-file-from-device" [
  board_id_PlatformFileUpload: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # shape: {title?: string, position?: record, geometry?: record, parent?: record}
  resource: string # Select a file to upload. Maximum file size is 6 MB. (format: binary)
]: any -> record<id: string, data: record<documentUrl: string, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id_PlatformFileUpload)/documents")
  let body = {data: $data, resource: $resource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update document item using file from device
#
# PATCH /v2/boards/{board_id_PlatformFileUpload}/documents/{item_id}
# operationId: update-document-item-using-file-from-device
# --data shape: {title?: string, altText?: string, position?: record, geometry?: record, parent?: record}
export def "boards-documents update-document-item-using-file-from-device" [
  board_id_PlatformFileUpload: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # shape: {title?: string, altText?: string, position?: record, geometry?: record, parent?: record}
  resource: string # Select a file to upload. Maximum file size is 6 MB. (format: binary)
]: any -> record<id: string, data: record<documentUrl: string, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id_PlatformFileUpload)/documents/($item_id)")
  let body = {data: $data, resource: $resource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create image item using file from device
#
# POST /v2/boards/{board_id_PlatformFileUpload}/images
# operationId: create-image-item-using-local-file
# --data shape: {title?: string, altText?: string, position?: record, geometry?: record, parent?: record}
export def "boards-images create-image-item-using-local-file" [
  board_id_PlatformFileUpload: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # shape: {title?: string, altText?: string, position?: record, geometry?: record, parent?: record}
  resource: string # Select a file to upload. Maximum file size is 6 MB. (format: binary)
]: any -> record<id: string, data: record<imageUrl: string, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id_PlatformFileUpload)/images")
  let body = {data: $data, resource: $resource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update image item using file from device
#
# PATCH /v2/boards/{board_id_PlatformFileUpload}/images/{item_id}
# operationId: update-image-item-using-file-from-device
# --data shape: {title?: string, altText?: string, position?: record, geometry?: record, parent?: record}
export def "boards-images update-image-item-using-file-from-device" [
  board_id_PlatformFileUpload: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # shape: {title?: string, altText?: string, position?: record, geometry?: record, parent?: record}
  resource: string # Select a file to upload. Maximum file size is 6 MB. (format: binary)
]: any -> record<id: string, data: record<imageUrl: string, title: string>, position: record<origin: string, relativeTo: string, x: float, y: float>, geometry: record<height: float, rotation: float, width: float>, createdAt: string, createdBy: record<id: string, type: string>, modifiedAt: string, modifiedBy: record<id: string, type: string>, parent: record<id: string, links: record<self: string>>, links: record<related: string, self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id_PlatformFileUpload)/images/($item_id)")
  let body = {data: $data, resource: $resource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create group
#
# POST /v2/boards/{board_id}/groups
# operationId: createGroup
export def "boards-groups createGroup" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # User group ID (e.g. 3074457345618265000)
  name: string # User group name (e.g. My group)
  --description: string # User group description (e.g. Info about group)
  type: string # Object type (default: user-group)
]: any -> record<id: string, type: string, data: record<id: string, name: string, description: string, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/groups")
  let body = {id: $id, name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all groups on a board
#
# GET /v2/boards/{board_id}/groups
# operationId: get-all-groups
export def "boards-groups get-all-groups" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of items to return at one time, default is 10, maximum is 50. (format: int32, default: 10)
  --cursor: string
]: nothing -> record<limit: int, size: int, data: table<id: string, type: string, data: record, links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get items of a group by ID
#
# GET /v2/boards/{board_id}/groups/items
# operationId: getItemsByGroupId
export def "boards-groups-items get" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of items to return at one time, default is 10, maximum is 50. (format: int32, default: 10)
  --cursor: string
  --group-item-id: string # The ID of the group item to retrieve.
]: nothing -> record<limit: int, size: int, total: int, data: record<id: string, type: string, data: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "group_item_id" $group_item_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id)/groups/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a group by its ID
#
# GET /v2/boards/{board_id}/groups/{group_id}
# operationId: getGroupById
export def "boards-groups get" [
  board_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, data: record<id: string, name: string, description: string, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ungroup items
#
# DELETE /v2/boards/{board_id}/groups/{group_id}
# operationId: unGroup
export def "boards-groups unGroup" [
  board_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-items: string@bool-completer # Indicates whether the items should be removed. By default, false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_items" $delete_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id)/groups/($group_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a group with new items
#
# PUT /v2/boards/{board_id}/groups/{group_id}
# operationId: updateGroup
export def "boards-groups updateGroup" [
  board_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # User group ID (e.g. 3074457345618265000)
  name: string # User group name (e.g. My group)
  --description: string # User group description (e.g. Info about group)
  type: string # Object type (default: user-group)
]: any -> record<id: string, type: string, data: record<id: string, name: string, description: string, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/groups/($group_id)")
  let body = {id: $id, name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the group
#
# DELETE /v2/boards/{board_id}/groups/{group_id}?
# operationId: deleteGroup
export def "boards-groups delete" [
  board_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-items: string@bool-completer # Indicates whether the items should be removed. Set to `true` to delete items in the group.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_items" $delete_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id)/groups/($group_id)?" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke token (v2)
#
# POST /v2/oauth/revoke
# operationId: revoke-token-v2
export def "oauth-revoke revoke-token-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  accessToken: string # The access token to be revoked.
  clientId: string # The client ID associated with the access token.
  clientSecret: string # The client secret associated with the access token.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/oauth/revoke")
  let body = {accessToken: $accessToken, clientId: $clientId, clientSecret: $clientSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get tags from item
#
# GET /v2/boards/{board_id}/items/{item_id}/tags
# operationId: get-tags-from-item
export def "boards-items-tags get-tags-from-item" [
  board_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: table<fillColor: string, id: string, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/items/($item_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create tag
#
# POST /v2/boards/{board_id}/tags
# operationId: create-tag
export def "boards-tags create-tag" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fillColor: string@fillColor-completer # Fill color for the tag. (default: red)
  title: string # Text of the tag. Case-sensitive. Must be unique. (e.g. to do)
]: any -> record<id: string, title: string, fillColor: string, links: record<self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/tags")
  let body = {fillColor: $fillColor, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get tags from board
#
# GET /v2/boards/{board_id}/tags
# operationId: get-tags-from-board
export def "boards-tags get-tags-from-board" [
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string
  --offset: string
]: nothing -> record<data: table<fillColor: string, id: string, title: string, type: string>, total: int, size: int, offset: int, limit: int, links: record<first: string, last: string, next: string, prev: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tag
#
# GET /v2/boards/{board_id}/tags/{tag_id}
# operationId: get-tag
export def "boards-tags get-tag" [
  board_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, title: string, fillColor: string, links: record<self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/tags/($tag_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tag
#
# PATCH /v2/boards/{board_id}/tags/{tag_id}
# operationId: update-tag
export def "boards-tags update-tag" [
  board_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fillColor: string@fillColor-completer # Fill color for the tag.
  --title: string # Text of the tag. Case-sensitive. Must be unique. (e.g. done)
]: any -> record<id: string, title: string, fillColor: string, links: record<self: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/boards/($board_id)/tags/($tag_id)")
  let body = {fillColor: $fillColor, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete tag
#
# DELETE /v2/boards/{board_id}/tags/{tag_id}
# operationId: delete-tag
export def "boards-tags delete-tag" [
  board_id: string
  tag_id: string
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
  let full_url = (build-url $base $"/v2/boards/($board_id)/tags/($tag_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get items by tag
#
# GET /v2/boards/{board_id_PlatformTags}/items
# operationId: get-items-by-tag
export def "boards-items get-items-by-tag" [
  board_id_PlatformTags: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string
  --offset: string
  --tag-id: string # Unique identifier (ID) of the tag that you want to retrieve.
]: nothing -> record<data: table<createdAt: string, createdBy: record, data: record, geometry: record, id: string, modifiedAt: string, modifiedBy: record, parent: record, position: record, type: string>, limit: int, links: record<first: string, last: string, next: string, prev: string, self: string>, offset: int, size: int, total: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "tag_id" $tag_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id_PlatformTags)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach tag to item
#
# POST /v2/boards/{board_id_PlatformTags}/items/{item_id}
# operationId: attach-tag-to-item
export def "boards-items attach-tag-to-item" [
  board_id_PlatformTags: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag-id: string # Unique identifier (ID) of the tag you want to add to the item.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag_id" $tag_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id_PlatformTags)/items/($item_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove tag from item
#
# DELETE /v2/boards/{board_id_PlatformTags}/items/{item_id}
# operationId: remove-tag-from-item
export def "boards-items remove-tag-from-item" [
  board_id_PlatformTags: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag-id: string # Unique identifier (ID) of the tag that you want to remove from the item.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag_id" $tag_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/boards/($board_id_PlatformTags)/items/($item_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create project
#
# POST /v2/orgs/{org_id}/teams/{team_id}/projects
# operationId: enterprise-create-project
export def "orgs-teams-projects enterprise-create-project" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Project name. (e.g. My project)
]: any -> record<id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List of projects
#
# GET /v2/orgs/{org_id}/teams/{team_id}/projects
# operationId: enterprise-get-projects
export def "orgs-teams-projects enterprise-get-projects" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to return per call. If the number of projects in the response is greater than the limit specified, the response returns the cursor parameter with a value. (format: int32, default: 100, e.g. 100)
  --cursor: string # An indicator of the position of a page in the full set of results. To obtain the first page leave it empty. To obtain subsequent pages set it to the value returned in the cursor field of the previous request. (e.g. 3074457345618265000)
]: nothing -> record<limit: int, size: int, data: table<id: string, name: string, type: string>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project
#
# GET /v2/orgs/{org_id}/teams/{team_id}/projects/{project_id}
# operationId: enterprise-get-project
export def "orgs-teams-projects enterprise-get-project" [
  org_id: string
  team_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project
#
# PATCH /v2/orgs/{org_id}/teams/{team_id}/projects/{project_id}
# operationId: enterprise-update-project
export def "orgs-teams-projects enterprise-update-project" [
  org_id: string
  team_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # New name of the project. (e.g. My project)
]: any -> record<id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects/($project_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete project
#
# DELETE /v2/orgs/{org_id}/teams/{team_id}/projects/{project_id}
# operationId: enterprise-delete-project
export def "orgs-teams-projects enterprise-delete-project" [
  org_id: string
  team_id: string
  project_id: string
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
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project settings
#
# GET /v2/orgs/{org_id}/teams/{team_id}/projects/{project_id}/settings
# operationId: enterprise-get-project-settings
export def "orgs-teams-projects-settings enterprise-get-project-settings" [
  org_id: string
  team_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sharingPolicySettings: record<teamAccess: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects/($project_id)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project settings
#
# PATCH /v2/orgs/{org_id}/teams/{team_id}/projects/{project_id}/settings
# operationId: enterprise-update-project-settings
# --sharingPolicySettings shape: {teamAccess?: "private"|"view"}
export def "orgs-teams-projects-settings enterprise-update-project-settings" [
  org_id: string
  team_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sharingPolicySettings: record # shape: {teamAccess?: "private"|"view"}
]: any -> record<sharingPolicySettings: record<teamAccess: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects/($project_id)/settings")
  let body = {sharingPolicySettings: $sharingPolicySettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add member in a project
#
# POST /v2/orgs/{org_id}/teams/{team_id}/projects/{project_id}/members
# operationId: enterprise-add-project-member
export def "orgs-teams-projects-members enterprise-add-project-member" [
  org_id: string
  team_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Email ID of the user. (e.g. someone@domain.com)
  role: string@role-completer-2 # Role of the project member. (e.g. viewer)
]: any -> record<id: string, email: string, role: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects/($project_id)/members")
  let body = {email: $email, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List of project members
#
# GET /v2/orgs/{org_id}/teams/{team_id}/projects/{project_id}/members
# operationId: enterprise-get-project-members
export def "orgs-teams-projects-members enterprise-get-project-members" [
  org_id: string
  team_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to return per call. If the number of project members in the response is greater than the limit specified, the response returns the cursor parameter with a value. (format: int32, default: 100, e.g. 100)
  --cursor: string # An indicator of the position of a page in the full set of results. To obtain the first page leave it empty. To obtain subsequent pages set it to the value returned in the cursor field of the previous request. (e.g. 3074457345618265000)
]: nothing -> record<limit: int, size: int, data: table<id: string, email: string, role: string, type: string>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects/($project_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project member
#
# GET /v2/orgs/{org_id}/teams/{team_id}/projects/{project_id}/members/{member_id}
# operationId: enterprise-get-project-member
export def "orgs-teams-projects-members enterprise-get-project-member" [
  org_id: string
  team_id: string
  project_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, email: string, role: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects/($project_id)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project member
#
# PATCH /v2/orgs/{org_id}/teams/{team_id}/projects/{project_id}/members/{member_id}
# operationId: enterprise-update-project-member
export def "orgs-teams-projects-members enterprise-update-project-member" [
  org_id: string
  team_id: string
  project_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer-2 # Role of the project member. (e.g. viewer)
]: any -> record<id: string, email: string, role: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects/($project_id)/members/($member_id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove project member
#
# DELETE /v2/orgs/{org_id}/teams/{team_id}/projects/{project_id}/members/{member_id}
# operationId: enterprise-delete-project-member
export def "orgs-teams-projects-members enterprise-delete-project-member" [
  org_id: string
  team_id: string
  project_id: string
  member_id: string
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
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/projects/($project_id)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create team
#
# POST /v2/orgs/{org_id}/teams
# operationId: enterprise-create-team
export def "orgs-teams enterprise-create-team" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Team name. (e.g. My Team)
]: any -> record<id: string, name: string, picture: record<id: float, imageURL: string, originalUrl: string, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List teams
#
# GET /v2/orgs/{org_id}/teams
# operationId: enterprise-get-teams
export def "orgs-teams enterprise-get-teams" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # format: int32, default: 100, e.g. 100
  --cursor: string # An indicator of the position of a page in the full set of results. To obtain the first page leave it empty. To obtain subsequent pages set it to the value returned in the cursor field of the previous request. (e.g. 3055557345821140500)
  --name: string # Name query. Filters teams by name using case insensitive partial match. A value "dev" will return both "Developer's team" and "Team for developers". (e.g. My team)
]: nothing -> record<limit: int, size: int, data: table<id: string, name: string, picture: record, type: string>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get team
#
# GET /v2/orgs/{org_id}/teams/{team_id}
# operationId: enterprise-get-team
export def "orgs-teams enterprise-get-team" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, picture: record<id: float, imageURL: string, originalUrl: string, type: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update team
#
# PATCH /v2/orgs/{org_id}/teams/{team_id}
# operationId: enterprise-update-team
export def "orgs-teams enterprise-update-team" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # New name for the team. (e.g. My Team)
]: any -> record<id: string, name: string, picture: record<id: float, imageURL: string, originalUrl: string, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete team
#
# DELETE /v2/orgs/{org_id}/teams/{team_id}
# operationId: enterprise-delete-team
export def "orgs-teams enterprise-delete-team" [
  org_id: string
  team_id: string
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
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite team members
#
# POST /v2/orgs/{org_id}/teams/{team_id}/members
# operationId: enterprise-invite-team-member
export def "orgs-teams-members enterprise-invite-team-member" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # User email to add to a team (e.g. user@miro.com)
  --role: string@role-completer-3 #  Role of the team member. * "member":     Team member with full member permissions. * "admin":      Admin of a team. Team member with permission to manage team.  (e.g. member)
]: any -> record<id: string, role: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, teamId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/members")
  let body = {email: $email, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List team members
#
# GET /v2/orgs/{org_id}/teams/{team_id}/members
# operationId: enterprise-get-team-members
export def "orgs-teams-members enterprise-get-team-members" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # format: int32, default: 100, e.g. 100
  --cursor: string # An indicator of the position of a page in the full set of results. To obtain the first page leave it empty. To obtain subsequent pages set it to the value returned in the cursor field of the previous request. (e.g. 3055557345821140500)
  --role: string #  Role query. Filters members by role using full word match. Accepted values are: * "member":     Team member with full member permissions. * "admin":      Admin of a team. Team member with permission to manage team. * "non_team":   External user, non-team user. * "team_guest": (Deprecated) Team-guest user, user with access only to a team without access to organization.
]: nothing -> record<limit: int, size: int, data: table<id: string, role: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, teamId: string, type: string>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get team member
#
# GET /v2/orgs/{org_id}/teams/{team_id}/members/{member_id}
# operationId: enterprise-get-team-member
export def "orgs-teams-members enterprise-get-team-member" [
  org_id: string
  team_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, role: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, teamId: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update team member
#
# PATCH /v2/orgs/{org_id}/teams/{team_id}/members/{member_id}
# operationId: enterprise-update-team-member
export def "orgs-teams-members enterprise-update-team-member" [
  org_id: string
  team_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer-3 #  Role of the team member. * "member":     Team member with full member permissions. * "admin":      Admin of a team. Team member with permission to manage team.  (e.g. member)
]: any -> record<id: string, role: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, teamId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/members/($member_id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete team member from team
#
# DELETE /v2/orgs/{org_id}/teams/{team_id}/members/{member_id}
# operationId: enterprise-delete-team-member
export def "orgs-teams-members enterprise-delete-team-member" [
  org_id: string
  team_id: string
  member_id: string
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
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get default team settings
#
# GET /v2/orgs/{org_id}/default_teams_settings
# operationId: enterprise-get-default-team-settings
export def "orgs-default-teams-settings enterprise-get-default-team-settings" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organizationId: string, teamAccountDiscoverySettings: record<accountDiscovery: string>, teamCollaborationSettings: record<coOwnerRole: string>, teamCopyAccessLevelSettings: record<copyAccessLevel: string, copyAccessLevelLimitation: string>, teamId: string, teamInvitationSettings: record<inviteExternalUsers: string, whoCanInvite: string>, teamSharingPolicySettings: record<allowListedDomains: list<string>, createAssetAccessLevel: string, defaultBoardAccess: string, defaultBoardSharingAccess: string, defaultOrganizationAccess: string, defaultProjectAccess: string, moveBoardToAccount: string, restrictAllowedDomains: string, sharingOnAccount: string, sharingOnOrganization: string, sharingViaPublicLink: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/default_teams_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get team settings
#
# GET /v2/orgs/{org_id}/teams/{team_id}/settings
# operationId: enterprise-get-team-settings
export def "orgs-teams-settings enterprise-get-team-settings" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organizationId: string, teamAccountDiscoverySettings: record<accountDiscovery: string>, teamCollaborationSettings: record<coOwnerRole: string>, teamCopyAccessLevelSettings: record<copyAccessLevel: string, copyAccessLevelLimitation: string>, teamId: string, teamInvitationSettings: record<inviteExternalUsers: string, whoCanInvite: string>, teamSharingPolicySettings: record<allowListedDomains: list<string>, createAssetAccessLevel: string, defaultBoardAccess: string, defaultBoardSharingAccess: string, defaultOrganizationAccess: string, defaultProjectAccess: string, moveBoardToAccount: string, restrictAllowedDomains: string, sharingOnAccount: string, sharingOnOrganization: string, sharingViaPublicLink: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update team settings
#
# PATCH /v2/orgs/{org_id}/teams/{team_id}/settings
# operationId: enterprise-update-team-settings
# --teamAccountDiscoverySettings shape: {accountDiscovery?: "hidden"|"request"|"join"}
# --teamCollaborationSettings shape: {coOwnerRole?: "enabled"|"disabled"}
# --teamCopyAccessLevelSettings shape: {copyAccessLevel?: "anyone"|"team_members"|"team_editors"|"board_owner", copyAccessLevelLimitation?: "anyone"|"team_members"}
# --teamInvitationSettings shape: {inviteExternalUsers?: "allowed"|"not_allowed", whoCanInvite?: "only_org_admins"|"admins"|"all_members"}
# --teamSharingPolicySettings shape: {allowListedDomains?: list, createAssetAccessLevel?: "company_admins"|"admins"|"all_members", defaultBoardAccess?: "private"|"view"|"comment"|"edit", defaultBoardSharingAccess?: "team_members_with_editing_rights"|"owner_and_coowners", defaultOrganizationAccess?: "private"|"view"|"comment"|"edit", defaultProjectAccess?: "private"|"view", moveBoardToAccount?: "allowed"|"not_allowed", restrictAllowedDomains?: "enabled"|"enabled_with_external_user_access"|"disabled", sharingOnAccount?: "allowed"|"not_allowed", sharingOnOrganization?: "allowed"|"allowed_with_editing"|"not_allowed", sharingViaPublicLink?: "allowed"|"allowed_with_editing"|"not_allowed"}
export def "orgs-teams-settings enterprise-update-team-settings" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamAccountDiscoverySettings: record # Team account discovery settings — shape: {accountDiscovery?: "hidden"|"request"|"join"}
  --teamCollaborationSettings: record # Team collaboration settings — shape: {coOwnerRole?: "enabled"|"disabled"}
  --teamCopyAccessLevelSettings: record # Team copy access settings — shape: {copyAccessLevel?: "anyone"|"team_members"|"team_editors"|"board_owner", copyAccessLevelLimitation?: "anyone"|"team_members"}
  --teamInvitationSettings: record # Team invitation settings — shape: {inviteExternalUsers?: "allowed"|"not_allowed", whoCanInvite?: "only_org_admins"|"admins"|"all_members"}
  --teamSharingPolicySettings: record # Team sharing policy settings — shape: {allowListedDomains?: list, createAssetAccessLevel?: "company_admins"|"admins"|"all_members", defaultBoardAccess?: "private"|"view"|"comment"|"edit", defaultBoardSharingAccess?: "team_members_with_editing_rights"|"owner_and_coowners", defaultOrganizationAccess?: "private"|"view"|"comment"|"edit", defaultProjectAccess?: "private"|"view", moveBoardToAccount?: "allowed"|"not_allowed", restrictAllowedDomains?: "enabled"|"enabled_with_external_user_access"|"disabled", sharingOnAccount?: "allowed"|"not_allowed", sharingOnOrganization?: "allowed"|"allowed_with_editing"|"not_allowed", sharingViaPublicLink?: "allowed"|"allowed_with_editing"|"not_allowed"}
]: any -> record<organizationId: string, teamAccountDiscoverySettings: record<accountDiscovery: string>, teamCollaborationSettings: record<coOwnerRole: string>, teamCopyAccessLevelSettings: record<copyAccessLevel: string, copyAccessLevelLimitation: string>, teamId: string, teamInvitationSettings: record<inviteExternalUsers: string, whoCanInvite: string>, teamSharingPolicySettings: record<allowListedDomains: list<string>, createAssetAccessLevel: string, defaultBoardAccess: string, defaultBoardSharingAccess: string, defaultOrganizationAccess: string, defaultProjectAccess: string, moveBoardToAccount: string, restrictAllowedDomains: string, sharingOnAccount: string, sharingOnOrganization: string, sharingViaPublicLink: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/settings")
  let body = {teamAccountDiscoverySettings: $teamAccountDiscoverySettings, teamCollaborationSettings: $teamCollaborationSettings, teamCopyAccessLevelSettings: $teamCopyAccessLevelSettings, teamInvitationSettings: $teamInvitationSettings, teamSharingPolicySettings: $teamSharingPolicySettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List of user groups
#
# GET /v2/orgs/{org_id}/groups
# operationId: enterprise-get-groups
export def "orgs-groups enterprise-get-groups" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of user groups in the result list. (format: int32, default: 100, e.g. 100)
  --cursor: string # A representation of the position of a user group in the full set of results. It is used to determine the first item of the resulting set. Leave empty to retrieve items from the beginning. (e.g. 3055557345821140500)
]: nothing -> record<limit: int, size: int, data: table<id: string, name: string, description: string, type: string>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create user group
#
# POST /v2/orgs/{org_id}/groups
# operationId: enterprise-create-group
export def "orgs-groups enterprise-create-group" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # User group name. (e.g. My user group)
  --description: string # Description of the user group being created. (e.g. This user group consists of users from the product team.)
]: any -> record<id: string, name: string, description: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user group
#
# GET /v2/orgs/{org_id}/groups/{group_id}
# operationId: enterprise-get-group
export def "orgs-groups enterprise-get-group" [
  org_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user group
#
# PATCH /v2/orgs/{org_id}/groups/{group_id}
# operationId: enterprise-update-group
export def "orgs-groups enterprise-update-group" [
  org_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # New name for the user group being updated. (e.g. Product user group)
  --description: string # New description of the user group. (e.g. This group contains users that belong to the product team.)
]: any -> record<id: string, name: string, description: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups/($group_id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete user group
#
# DELETE /v2/orgs/{org_id}/groups/{group_id}
# operationId: enterprise-delete-group
export def "orgs-groups enterprise-delete-group" [
  org_id: string
  group_id: string
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
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of user group members
#
# GET /v2/orgs/{org_id}/groups/{group_id}/members
# operationId: enterprise-get-group-members
export def "orgs-groups-members enterprise-get-group-members" [
  org_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of members in the result list. (format: int32, default: 100, e.g. 100)
  --cursor: string # A representation of the position of a member in the full set of results. It is used to determine the first item of the resulting set. Leave empty to retrieve items from the beginning. (e.g. 3055557345821140500)
]: nothing -> record<limit: int, size: int, data: table<id: string, email: string, type: string>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups/($group_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create user group member
#
# POST /v2/orgs/{org_id}/groups/{group_id}/members
# operationId: enterprise-create-group-member
export def "orgs-groups-members enterprise-create-group-member" [
  org_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # User email (e.g. user@mail.com)
]: any -> record<id: string, email: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups/($group_id)/members")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk edit of membership in user group
#
# PATCH /v2/orgs/{org_id}/groups/{group_id}/members
# operationId: enterprise-update-group-members
export def "orgs-groups-members enterprise-update-group-members" [
  org_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --membersToAdd: list # List of user identifiers (can be email or ID) to add to the user group. (e.g. [3074457345618265000, user0@example.com])
  --membersToRemove: list # List of user identifiers (can be email or ID) to remove from the user group. (e.g. [3074457345618265001, user1@example.com])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups/($group_id)/members")
  let body = {membersToAdd: $membersToAdd, membersToRemove: $membersToRemove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user group member
#
# GET /v2/orgs/{org_id}/groups/{group_id}/members/{member_id}
# operationId: enterprise-get-group-member
export def "orgs-groups-members enterprise-get-group-member" [
  org_id: string
  group_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, email: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups/($group_id)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user group member
#
# DELETE /v2/orgs/{org_id}/groups/{group_id}/members/{member_id}
# operationId: enterprise-delete-group-member
export def "orgs-groups-members enterprise-delete-group-member" [
  org_id: string
  group_id: string
  member_id: string
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
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups/($group_id)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get teams of a user group
#
# GET /v2/orgs/{org_id}/groups/{group_id}/teams
# operationId: enterprise-groups-get-teams
export def "orgs-groups-teams enterprise-groups-get-teams" [
  org_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of teams in the result list. (format: int32, default: 100, e.g. 100)
  --cursor: string # A representation of the position of a team in the full set of results. It is used to determine the first item of the resulting set. Leave empty to retrieve items from the beginning. (e.g. 3055557345821140500)
]: nothing -> record<limit: int, size: int, data: table<id: string, role: string, type: string>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups/($group_id)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user group team
#
# GET /v2/orgs/{org_id}/groups/{group_id}/teams/{team_id}
# operationId: enterprise-groups-get-team
export def "orgs-groups-teams enterprise-groups-get-team" [
  org_id: string
  group_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, role: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/groups/($group_id)/teams/($team_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of user group to team connections
#
# GET /v2/orgs/{org_id}/teams/{team_id}/groups
# operationId: enterprise-teams-get-groups
export def "orgs-teams-groups enterprise-teams-get-groups" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of user groups in the result list. (format: int32, default: 100, e.g. 100)
  --cursor: string # A representation of the position of a user group in the full set of results. It is used to determine the first item of the resulting set. Leave empty to retrieve items from the beginning. (e.g. 3055557345821140500)
]: nothing -> record<limit: int, size: int, data: table<id: string, role: string, type: string>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create user group to team connection
#
# POST /v2/orgs/{org_id}/teams/{team_id}/groups
# operationId: enterprise-teams-create-group
export def "orgs-teams-groups enterprise-teams-create-group" [
  org_id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userGroupId: string # User group ID. (e.g. 3074457345618265000)
  role: string@role-completer-4 # Role of user group in the team. (e.g. member)
]: any -> record<id: string, role: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/groups")
  let body = {userGroupId: $userGroupId, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user group of a team
#
# GET /v2/orgs/{org_id}/teams/{team_id}/groups/{group_id}
# operationId: enterprise-teams-get-group
export def "orgs-teams-groups enterprise-teams-get-group" [
  org_id: string
  team_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, role: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user group to team connection
#
# DELETE /v2/orgs/{org_id}/teams/{team_id}/groups/{group_id}
# operationId: enterprise-teams-delete-group
export def "orgs-teams-groups enterprise-teams-delete-group" [
  org_id: string
  team_id: string
  group_id: string
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
  let full_url = (build-url $base $"/v2/orgs/($org_id)/teams/($team_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get board user group assignments
#
# GET /v2/orgs/{org_id}/boards/{board_id}/groups
# operationId: enterprise-boards-get-groups
export def "orgs-boards-groups enterprise-boards-get-groups" [
  org_id: string
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of user groups in the result list. (format: int32, default: 100, e.g. 100)
  --cursor: string # A representation of the position of a user group in the full set of results. It is used to determine the first item of the resulting set. Leave empty to retrieve items from the beginning. (e.g. MlR5YnRrRUJBV0N2OUxnbWxTNnJ5THwzNDU4NzY0NjEzMTE0Nzk4ODA1fEdST1VQ)
]: nothing -> record<limit: int, size: int, data: table<id: string, role: any, type: any>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/boards/($board_id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create board user group assignments
#
# POST /v2/orgs/{org_id}/boards/{board_id}/groups
# operationId: enterprise-boards-create-group
export def "orgs-boards-groups enterprise-boards-create-group" [
  org_id: string
  board_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userGroupIds: list # List of user group ids.
  role: string@role-completer-5 # Role of the user group on the board. (default: VIEWER, e.g. VIEWER)
]: any -> record<id: string, role: any, type: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/boards/($board_id)/groups")
  let body = {userGroupIds: $userGroupIds, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete board user group assignment
#
# DELETE /v2/orgs/{org_id}/boards/{board_id}/groups/{group_id}
# operationId: enterprise-boards-delete-groups
export def "orgs-boards-groups enterprise-boards-delete-groups" [
  org_id: string
  board_id: string
  group_id: string
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
  let full_url = (build-url $base $"/v2/orgs/($org_id)/boards/($board_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project user group assignments
#
# GET /v2/orgs/{org_id}/projects/{project_id}/groups
# operationId: enterprise-projects-get-groups
export def "orgs-projects-groups enterprise-projects-get-groups" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of user groups in the result list. (format: int32, default: 100, e.g. 100)
  --cursor: string # A representation of the position of a user group in the full set of results. It is used to determine the first item of the resulting set. Leave empty to retrieve items from the beginning. (e.g. MlR5YnRrRUJBV0N2OUxnbWxTNnJ5THwzNDU4NzY0NjEzMTE0Nzk4ODA1fEdST1VQ)
]: nothing -> record<limit: int, size: int, data: table<id: string, role: any, type: any>, cursor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orgs/($org_id)/projects/($project_id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create project user group assignments
#
# POST /v2/orgs/{org_id}/projects/{project_id}/groups
# operationId: enterprise-project-create-group
export def "orgs-projects-groups enterprise-project-create-group" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userGroupIds: list # List of user group ids.
  role: string@role-completer-5 # Role of the user group on the project. (default: VIEWER, e.g. VIEWER)
]: any -> record<id: string, role: any, type: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orgs/($org_id)/projects/($project_id)/groups")
  let body = {userGroupIds: $userGroupIds, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete project user group assignment
#
# DELETE /v2/orgs/{org_id}/projects/{project_id}/groups/{group_id}
# operationId: enterprise-project-delete-groups
export def "orgs-projects-groups enterprise-project-delete-groups" [
  org_id: string
  project_id: string
  group_id: string
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
  let full_url = (build-url $base $"/v2/orgs/($org_id)/projects/($project_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
