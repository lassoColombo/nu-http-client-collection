# Auto-generated client for Jira Software Cloud API v1001.0.0
# Source: https://developer.atlassian.com/cloud/jira/software/swagger.v3.json
# Auth: --token flag or $env.JIRA_SOFTWARE_CLOUD_API_TOKEN

const BASE_URL = "https://your-domain.atlassian.net"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o JIRA_SOFTWARE_CLOUD_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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
def base-url-completer [] { ["https://your-domain.atlassian.net"] }
def auth-scheme-completer [] { ["bearer" "basic"] }

# Completers for enum parameters
def orderBy-completer [] { ["+name" "-name" "name"] }
def type-completer [] { ["agility" "kanban" "scrum"] }
def operationType-completer [] { ["BACKFILL" "NORMAL"] }
def operationType-completer-1 [] { ["BACKFILL" "NORMAL" "SCAN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rest-agile-10-backlog-issue moveIssuesToBacklog" } } | get name | first)
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

# Move issues to backlog
#
# POST /rest/agile/1.0/backlog/issue
# operationId: moveIssuesToBacklog
export def "rest-agile-10-backlog-issue moveIssuesToBacklog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --issues: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/agile/1.0/backlog/issue")
  let body = {issues: $issues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move issues to backlog for board
#
# POST /rest/agile/1.0/backlog/{boardId}/issue
# operationId: moveIssuesToBacklogForBoard
export def "rest-agile-10-backlog-issue moveIssuesToBacklogForBoard" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --issues: list
  --rankAfterIssue: string
  --rankBeforeIssue: string
  --rankCustomFieldId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/backlog/($boardId)/issue")
  let body = {issues: $issues, rankAfterIssue: $rankAfterIssue, rankBeforeIssue: $rankBeforeIssue, rankCustomFieldId: $rankCustomFieldId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all boards
#
# GET /rest/agile/1.0/board
# operationId: getAllBoards
export def "rest-agile-10-board list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned boards. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64, default: 0)
  --maxResults: int # The maximum number of boards to return per page. See the 'Pagination' section at the top of this page for more details. (format: int32, default: 50)
  --type: record # Filters results to boards of the specified types. Valid values: scrum, kanban, simple.
  --name: string # Filters results to boards that match or partially match the specified name.
  --projectKeyOrId: string # Filters results to boards that are relevant to a project. Relevance means that the jql filter defined in board contains a reference to a project.
  --accountIdLocation: string
  --projectLocation: string
  --includePrivate: string@bool-completer # Appends private boards to the end of the list. The name and type fields are excluded for security reasons.
  --negateLocationFiltering: string@bool-completer # If set to true, negate filters used for querying by location. By default false.
  --orderBy: string@orderBy-completer # Ordering of the results by a given field. If not provided, values will not be sorted. Valid values: name.
  --expand: string # List of fields to expand for each board. Valid values: admins, permissions.
  --projectTypeLocation: list # Filters results to boards that are relevant to a project types. Support Jira Software, Jira Service Management. Valid values: software, service\_desk. By default software.
  --filterId: int # Filters results to boards that are relevant to a filter. Not supported for next-gen boards. (format: int64)
]: nothing -> record<isLast: bool, maxResults: int, startAt: int, total: int, values: table<admins: record, canEdit: bool, favourite: bool, id: int, isPrivate: bool, location: record, name: string, self: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "type" $type "multi") (serialize-qp "name" $name "scalar") (serialize-qp "projectKeyOrId" $projectKeyOrId "scalar") (serialize-qp "accountIdLocation" $accountIdLocation "scalar") (serialize-qp "projectLocation" $projectLocation "scalar") (serialize-qp "includePrivate" $includePrivate "scalar") (serialize-qp "negateLocationFiltering" $negateLocationFiltering "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "projectTypeLocation" $projectTypeLocation "multi") (serialize-qp "filterId" $filterId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/agile/1.0/board" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create board
#
# POST /rest/agile/1.0/board
# operationId: createBoard
# --location shape: {projectKeyOrId?: string, type?: "project"|"user"}
export def "rest-agile-10-board createBoard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterId: int # format: int64
  --location: record # shape: {projectKeyOrId?: string, type?: "project"|"user"}
  --name: string
  --type: string@type-completer
]: any -> record<admins: record<groups: list<record>, users: list<record>>, canEdit: bool, favourite: bool, id: int, isPrivate: bool, location: record<avatarURI: string, displayName: string, name: string, projectId: int, projectKey: string, projectName: string, projectTypeKey: string, userAccountId: string, userId: int>, name: string, self: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/agile/1.0/board")
  let body = {filterId: $filterId, location: $location, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get board by filter id
#
# GET /rest/agile/1.0/board/filter/{filterId}
# operationId: getBoardByFilterId
export def "rest-agile-10-board-filter get" [
  filterId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned boards. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of boards to return per page. Default: 50. See the 'Pagination' section at the top of this page for more details. (format: int32)
]: nothing -> record<isLast: bool, maxResults: int, startAt: int, total: int, values: table<id: int, name: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/board/filter/($filterId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete board
#
# DELETE /rest/agile/1.0/board/{boardId}
# operationId: deleteBoard
export def "rest-agile-10-board delete" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get board
#
# GET /rest/agile/1.0/board/{boardId}
# operationId: getBoard
export def "rest-agile-10-board get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<admins: record<groups: list<record>, users: list<record>>, canEdit: bool, favourite: bool, id: int, isPrivate: bool, location: record<avatarURI: string, displayName: string, name: string, projectId: int, projectKey: string, projectName: string, projectTypeKey: string, userAccountId: string, userId: int>, name: string, self: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get issues for backlog
#
# GET /rest/agile/1.0/board/{boardId}/backlog
# DEPRECATED
# operationId: getIssuesForBacklog
@deprecated
export def "rest-agile-10-board-backlog get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned issues. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of issues to return per page. Default: 50. See the 'Pagination' section at the top of this page for more details. Note, the total number of issues returned is limited by the property 'jira.search.views.default.max' in your Jira instance. If you exceed this limit, your results will be truncated. (format: int32)
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Agile fields are returned.
  --expand: string # This parameter is currently not used.
]: nothing -> record<expand: string, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, maxResults: int, names: record, schema: record, startAt: int, total: int, warningMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/backlog" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get issues for backlog (enhanced)
#
# GET /rest/software/1.0/board/{boardId}/backlog
# operationId: getIssuesForBacklogJSIS
export def "rest-software-10-board-backlog get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextPageToken: string # The token for a page to fetch that is not the first page. The first page has a `nextPageToken` of `null`. Use the `nextPageToken` to fetch the next page of issues.  Note: The `nextPageToken` field is **not included** in the response for the last page, indicating there is no next page.
  --maxResults: int # The maximum number of items to return per page. To manage page size, the API may return fewer items per page where there is a large number of fields or properties returned. It returns max 5000 issues. (format: int32)
  --reconcileIssues: list # Strong consistency issue IDs to be reconciled with search results. Accepts max 50 IDs. This list of IDs should be consistent with each paginated request across different pages.
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Software project fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> record<expand: string, isLast: bool, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, names: record, nextPageToken: string, schema: record, warningMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "reconcileIssues" $reconcileIssues "multi") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/software/1.0/board/($boardId)/backlog" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get approximate issue count for backlog
#
# GET /rest/software/1.0/board/{boardId}/backlog/approximate-count
# operationId: getApproximateIssueCountForBacklog
export def "rest-software-10-board-backlog-approximate-count get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --jql: string # Filters results using a JQL query. Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jql" $jql "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/software/1.0/board/($boardId)/backlog/approximate-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get configuration
#
# GET /rest/agile/1.0/board/{boardId}/configuration
# operationId: getConfiguration
export def "rest-agile-10-board-configuration get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<columnConfig: record<columns: list<record>, constraintType: string>, estimation: record<field: record<displayName: string, fieldId: string>, type: string>, filter: record<id: string, self: string>, id: int, location: record<projectKeyOrId: string, type: string>, name: string, ranking: record<rankCustomFieldId: int>, self: string, subQuery: record<query: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get epics
#
# GET /rest/agile/1.0/board/{boardId}/epic
# operationId: getEpics
export def "rest-agile-10-board-epic get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned epics. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of epics to return per page. See the 'Pagination' section at the top of this page for more details. (format: int32)
  --done: string # Filters results to epics that are either done or not done. Valid values: true, false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "done" $done "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/epic" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get issues without epic for board
#
# GET /rest/agile/1.0/board/{boardId}/epic/none/issue
# DEPRECATED
# operationId: getIssuesWithoutEpicForBoard
@deprecated
export def "rest-agile-10-board-epic-none-issue get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned issues. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of issues to return per page. See the 'Pagination' section at the top of this page for more details. Note, the total number of issues returned is limited by the property 'jira.search.views.default.max' in your Jira instance. If you exceed this limit, your results will be truncated. (format: int32)
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Agile fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/epic/none/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get issues without epic for board (enhanced)
#
# GET /rest/software/1.0/board/{boardId}/epic/none/issue
# operationId: getIssuesWithoutEpicForBoardJSIS
export def "rest-software-10-board-epic-none-issue get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextPageToken: string # The token for a page to fetch that is not the first page. The first page has a `nextPageToken` of `null`. Use the `nextPageToken` to fetch the next page of issues.  Note: The `nextPageToken` field is **not included** in the response for the last page, indicating there is no next page.
  --maxResults: int # The maximum number of items to return per page. To manage page size, the API may return fewer items per page where there is a large number of fields or properties returned. It returns max 5000 issues. (format: int32)
  --reconcileIssues: list # Strong consistency issue IDs to be reconciled with search results. Accepts max 50 IDs. This list of IDs should be consistent with each paginated request across different pages.
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Software project fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> record<expand: string, isLast: bool, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, names: record, nextPageToken: string, schema: record, warningMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "reconcileIssues" $reconcileIssues "multi") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/software/1.0/board/($boardId)/epic/none/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get board issues for epic
#
# GET /rest/agile/1.0/board/{boardId}/epic/{epicId}/issue
# DEPRECATED
# operationId: getBoardIssuesForEpic
@deprecated
export def "rest-agile-10-board-epic-issue get" [
  boardId: int
  epicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned issues. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of issues to return per page. Default: 50. See the 'Pagination' section at the top of this page for more details. Note, the total number of issues returned is limited by the property 'jira.search.views.default.max' in your Jira instance. If you exceed this limit, your results will be truncated. (format: int32)
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Agile fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/epic/($epicId)/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get board issues for epic (enhanced)
#
# GET /rest/software/1.0/board/{boardId}/epic/{epicId}/issue
# operationId: getBoardIssuesForEpicJSIS
export def "rest-software-10-board-epic-issue get" [
  boardId: int
  epicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextPageToken: string # The token for a page to fetch that is not the first page. The first page has a `nextPageToken` of `null`. Use the `nextPageToken` to fetch the next page of issues.  Note: The `nextPageToken` field is **not included** in the response for the last page, indicating there is no next page.
  --maxResults: int # The maximum number of items to return per page. To manage page size, the API may return fewer items per page where there is a large number of fields or properties returned. It returns max 5000 issues. (format: int32)
  --reconcileIssues: list # Strong consistency issue IDs to be reconciled with search results. Accepts max 50 IDs. This list of IDs should be consistent with each paginated request across different pages.
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Software project fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> record<expand: string, isLast: bool, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, names: record, nextPageToken: string, schema: record, warningMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "reconcileIssues" $reconcileIssues "multi") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/software/1.0/board/($boardId)/epic/($epicId)/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get features for board
#
# GET /rest/agile/1.0/board/{boardId}/features
# operationId: getFeaturesForBoard
export def "rest-agile-10-board-features get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<features: table<boardFeature: string, boardId: int, featureId: string, featureType: string, imageUri: string, learnMoreArticleId: string, learnMoreLink: string, localisedDescription: string, localisedGroup: string, localisedName: string, permissibleEstimationTypes: list, state: string, toggleLocked: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/features")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Toggle features
#
# PUT /rest/agile/1.0/board/{boardId}/features
# operationId: toggleFeatures
export def "rest-agile-10-board-features toggleFeatures" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-boardId: int # format: int64
  --enabling: string@bool-completer
  --feature: string
]: any -> record<features: table<boardFeature: string, boardId: int, featureId: string, featureType: string, imageUri: string, learnMoreArticleId: string, learnMoreLink: string, localisedDescription: string, localisedGroup: string, localisedName: string, permissibleEstimationTypes: list, state: string, toggleLocked: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/features")
  let body = {boardId: $body_boardId, enabling: $enabling, feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get issues for board
#
# GET /rest/agile/1.0/board/{boardId}/issue
# DEPRECATED
# operationId: getIssuesForBoard
@deprecated
export def "rest-agile-10-board-issue get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned issues. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of issues to return per page. See the 'Pagination' section at the top of this page for more details. Note, the total number of issues returned is limited by the property 'jira.search.views.default.max' in your Jira instance. If you exceed this limit, your results will be truncated. (format: int32)
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Agile fields are returned.
  --expand: string # This parameter is currently not used.
]: nothing -> record<expand: string, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, maxResults: int, names: record, schema: record, startAt: int, total: int, warningMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move issues to board
#
# POST /rest/agile/1.0/board/{boardId}/issue
# operationId: moveIssuesToBoard
export def "rest-agile-10-board-issue moveIssuesToBoard" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --issues: list
  --rankAfterIssue: string
  --rankBeforeIssue: string
  --rankCustomFieldId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/issue")
  let body = {issues: $issues, rankAfterIssue: $rankAfterIssue, rankBeforeIssue: $rankBeforeIssue, rankCustomFieldId: $rankCustomFieldId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get issues for board (enhanced)
#
# GET /rest/software/1.0/board/{boardId}/issue
# operationId: getIssuesForBoardJSIS
export def "rest-software-10-board-issue get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextPageToken: string # The token for a page to fetch that is not the first page. The first page has a `nextPageToken` of `null`. Use the `nextPageToken` to fetch the next page of issues.  Note: The `nextPageToken` field is **not included** in the response for the last page, indicating there is no next page.
  --maxResults: int # The maximum number of items to return per page. To manage page size, the API may return fewer items per page where there is a large number of fields or properties returned. It returns max 5000 issues. (format: int32)
  --reconcileIssues: list # Strong consistency issue IDs to be reconciled with search results. Accepts max 50 IDs. This list of IDs should be consistent with each paginated request across different pages.
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Software project fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> record<expand: string, isLast: bool, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, names: record, nextPageToken: string, schema: record, warningMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "reconcileIssues" $reconcileIssues "multi") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/software/1.0/board/($boardId)/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get approximate issue count for board
#
# GET /rest/software/1.0/board/{boardId}/issue/approximate-count
# operationId: getApproximateIssueCountForBoard
export def "rest-software-10-board-issue-approximate-count get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --jql: string # Filters results using a JQL query. Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jql" $jql "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/software/1.0/board/($boardId)/issue/approximate-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get projects
#
# GET /rest/agile/1.0/board/{boardId}/project
# operationId: getProjects
export def "rest-agile-10-board-project get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned projects. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of projects to return per page. See the 'Pagination' section at the top of this page for more details. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/project" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get projects full
#
# GET /rest/agile/1.0/board/{boardId}/project/full
# operationId: getProjectsFull
export def "rest-agile-10-board-project-full get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/project/full")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get board property keys
#
# GET /rest/agile/1.0/board/{boardId}/properties
# operationId: getBoardPropertyKeys
export def "rest-agile-10-board-properties list" [
  boardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/properties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete board property
#
# DELETE /rest/agile/1.0/board/{boardId}/properties/{propertyKey}
# operationId: deleteBoardProperty
export def "rest-agile-10-board-properties delete" [
  boardId: string
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/properties/($propertyKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get board property
#
# GET /rest/agile/1.0/board/{boardId}/properties/{propertyKey}
# operationId: getBoardProperty
export def "rest-agile-10-board-properties get" [
  boardId: string
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/properties/($propertyKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set board property
#
# PUT /rest/agile/1.0/board/{boardId}/properties/{propertyKey}
# operationId: setBoardProperty
export def "rest-agile-10-board-properties setBoardProperty" [
  boardId: string
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/properties/($propertyKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all quick filters
#
# GET /rest/agile/1.0/board/{boardId}/quickfilter
# operationId: getAllQuickFilters
export def "rest-agile-10-board-quickfilter list" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned quick filters. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of sprints to return per page. See the 'Pagination' section at the top of this page for more details. (format: int32)
]: nothing -> record<isLast: bool, maxResults: int, startAt: int, total: int, values: table<boardId: int, description: string, id: int, jql: string, name: string, position: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/quickfilter" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get quick filter
#
# GET /rest/agile/1.0/board/{boardId}/quickfilter/{quickFilterId}
# operationId: getQuickFilter
export def "rest-agile-10-board-quickfilter get" [
  boardId: int
  quickFilterId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<boardId: int, description: string, id: int, jql: string, name: string, position: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/quickfilter/($quickFilterId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get reports for board
#
# GET /rest/agile/1.0/board/{boardId}/reports
# operationId: getReportsForBoard
export def "rest-agile-10-board-reports get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<reports: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/reports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all sprints
#
# GET /rest/agile/1.0/board/{boardId}/sprint
# operationId: getAllSprints
export def "rest-agile-10-board-sprint get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned sprints. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of sprints to return per page. See the 'Pagination' section at the top of this page for more details. (format: int32)
  --state: record # Filters results to sprints in specified states. Valid values: future, active, closed. You can define multiple states separated by commas, e.g. state=active,closed
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "state" $state "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/sprint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get board issues for sprint
#
# GET /rest/agile/1.0/board/{boardId}/sprint/{sprintId}/issue
# DEPRECATED
# operationId: getBoardIssuesForSprint
@deprecated
export def "rest-agile-10-board-sprint-issue get" [
  boardId: int
  sprintId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned issues. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of issues to return per page. See the 'Pagination' section at the top of this page for more details. Note, the total number of issues returned is limited by the property 'jira.search.views.default.max' in your Jira instance. If you exceed this limit, your results will be truncated. (format: int32)
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Agile fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/sprint/($sprintId)/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get board issues for sprint (enhanced)
#
# GET /rest/software/1.0/board/{boardId}/sprint/{sprintId}/issue
# operationId: getBoardIssuesForSprintJSIS
export def "rest-software-10-board-sprint-issue get" [
  boardId: int
  sprintId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextPageToken: string # The token for a page to fetch that is not the first page. The first page has a `nextPageToken` of `null`. Use the `nextPageToken` to fetch the next page of issues.  Note: The `nextPageToken` field is **not included** in the response for the last page, indicating there is no next page.
  --maxResults: int # The maximum number of items to return per page. To manage page size, the API may return fewer items per page where there is a large number of fields or properties returned. It returns max 5000 issues. (format: int32)
  --reconcileIssues: list # Strong consistency issue IDs to be reconciled with search results. Accepts max 50 IDs. This list of IDs should be consistent with each paginated request across different pages.
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Software project fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> record<expand: string, isLast: bool, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, names: record, nextPageToken: string, schema: record, warningMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "reconcileIssues" $reconcileIssues "multi") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/software/1.0/board/($boardId)/sprint/($sprintId)/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all versions
#
# GET /rest/agile/1.0/board/{boardId}/version
# operationId: getAllVersions
export def "rest-agile-10-board-version get" [
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned versions. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of versions to return per page. See the 'Pagination' section at the top of this page for more details. (format: int32)
  --released: string # Filters results to versions that are either released or unreleased. Valid values: true, false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "released" $released "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/board/($boardId)/version" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get issues without epic
#
# GET /rest/agile/1.0/epic/none/issue
# DEPRECATED
# operationId: getIssuesWithoutEpic
@deprecated
export def "rest-agile-10-epic-none-issue get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned issues. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of issues to return per page. See the 'Pagination' section at the top of this page for more details. Note, the total number of issues returned is limited by the property 'jira.search.views.default.max' in your Jira instance. If you exceed this limit, your results will be truncated. (format: int32)
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Agile fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/agile/1.0/epic/none/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove issues from epic
#
# POST /rest/agile/1.0/epic/none/issue
# operationId: removeIssuesFromEpic
export def "rest-agile-10-epic-none-issue removeIssuesFromEpic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --issues: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/agile/1.0/epic/none/issue")
  let body = {issues: $issues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get issues without epic (enhanced)
#
# GET /rest/software/1.0/epic/none/issue
# operationId: getIssuesWithoutEpicJSIS
export def "rest-software-10-epic-none-issue get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextPageToken: string # The token for a page to fetch that is not the first page. The first page has a `nextPageToken` of `null`. Use the `nextPageToken` to fetch the next page of issues.  Note: The `nextPageToken` field is **not included** in the response for the last page, indicating there is no next page.
  --maxResults: int # The maximum number of items to return per page. To manage page size, the API may return fewer items per page where there is a large number of fields or properties returned. It returns max 5000 issues. (format: int32)
  --reconcileIssues: list # Strong consistency issue IDs to be reconciled with search results. Accepts max 50 IDs. This list of IDs should be consistent with each paginated request across different pages.
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Software project fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> record<expand: string, isLast: bool, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, names: record, nextPageToken: string, schema: record, warningMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "reconcileIssues" $reconcileIssues "multi") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/software/1.0/epic/none/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get epic
#
# GET /rest/agile/1.0/epic/{epicIdOrKey}
# operationId: getEpic
export def "rest-agile-10-epic get" [
  epicIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/epic/($epicIdOrKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partially update epic
#
# POST /rest/agile/1.0/epic/{epicIdOrKey}
# operationId: partiallyUpdateEpic
# --color shape: {key?: "color_1"|"color_2"|"color_3"|"color_4"|"color_5"|"color_6"|"color_7"|"color_8"|"color_9"|"color_10"|"color_11"|"color_12"|"color_13"|"color_14"}
export def "rest-agile-10-epic partiallyUpdateEpic" [
  epicIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: record # shape: {key?: "color_1"|"color_2"|"color_3"|"color_4"|"color_5"|"color_6"|"color_7"|"color_8"|"color_9"|"color_10"|"color_11"|"color_12"|"color_13"|"color_14"}
  --done: string@bool-completer
  --name: string
  --summary: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/epic/($epicIdOrKey)")
  let body = {color: $color, done: $done, name: $name, summary: $summary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get issues for epic
#
# GET /rest/agile/1.0/epic/{epicIdOrKey}/issue
# DEPRECATED
# operationId: getIssuesForEpic
@deprecated
export def "rest-agile-10-epic-issue get" [
  epicIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned issues. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of issues to return per page. Default: 50. See the 'Pagination' section at the top of this page for more details. Note, the total number of issues returned is limited by the property 'jira.search.views.default.max' in your Jira instance. If you exceed this limit, your results will be truncated. (format: int32)
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Agile fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/epic/($epicIdOrKey)/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move issues to epic
#
# POST /rest/agile/1.0/epic/{epicIdOrKey}/issue
# operationId: moveIssuesToEpic
export def "rest-agile-10-epic-issue moveIssuesToEpic" [
  epicIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --issues: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/epic/($epicIdOrKey)/issue")
  let body = {issues: $issues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get issues for epic (enhanced)
#
# GET /rest/software/1.0/epic/{epicIdOrKey}/issue
# operationId: getIssuesForEpicJSIS
export def "rest-software-10-epic-issue get" [
  epicIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextPageToken: string # The token for a page to fetch that is not the first page. The first page has a `nextPageToken` of `null`. Use the `nextPageToken` to fetch the next page of issues.  Note: The `nextPageToken` field is **not included** in the response for the last page, indicating there is no next page.
  --maxResults: int # The maximum number of items to return per page. To manage page size, the API may return fewer items per page where there is a large number of fields or properties returned. It returns max 5000 issues. (format: int32)
  --reconcileIssues: list # Strong consistency issue IDs to be reconciled with search results. Accepts max 50 IDs. This list of IDs should be consistent with each paginated request across different pages.
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Software project fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> record<expand: string, isLast: bool, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, names: record, nextPageToken: string, schema: record, warningMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "reconcileIssues" $reconcileIssues "multi") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/software/1.0/epic/($epicIdOrKey)/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rank epics
#
# PUT /rest/agile/1.0/epic/{epicIdOrKey}/rank
# operationId: rankEpics
export def "rest-agile-10-epic-rank rankEpics" [
  epicIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rankAfterEpic: string
  --rankBeforeEpic: string
  --rankCustomFieldId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/epic/($epicIdOrKey)/rank")
  let body = {rankAfterEpic: $rankAfterEpic, rankBeforeEpic: $rankBeforeEpic, rankCustomFieldId: $rankCustomFieldId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rank issues
#
# PUT /rest/agile/1.0/issue/rank
# operationId: rankIssues
export def "rest-agile-10-issue-rank rankIssues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --issues: list
  --rankAfterIssue: string
  --rankBeforeIssue: string
  --rankCustomFieldId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/agile/1.0/issue/rank")
  let body = {issues: $issues, rankAfterIssue: $rankAfterIssue, rankBeforeIssue: $rankBeforeIssue, rankCustomFieldId: $rankCustomFieldId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get issue
#
# GET /rest/agile/1.0/issue/{issueIdOrKey}
# operationId: getIssue
export def "rest-agile-10-issue get" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Agile fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
  --updateHistory: string@bool-completer # A boolean indicating whether the issue retrieved by this method should be added to the current user's issue history
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar") (serialize-qp "updateHistory" $updateHistory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/issue/($issueIdOrKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get issue estimation for board
#
# GET /rest/agile/1.0/issue/{issueIdOrKey}/estimation
# operationId: getIssueEstimationForBoard
export def "rest-agile-10-issue-estimation get" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --boardId: int # The ID of the board required to determine which field is used for estimation. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "boardId" $boardId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/issue/($issueIdOrKey)/estimation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Estimate issue for board
#
# PUT /rest/agile/1.0/issue/{issueIdOrKey}/estimation
# operationId: estimateIssueForBoard
export def "rest-agile-10-issue-estimation estimateIssueForBoard" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --boardId: int # The ID of the board required to determine which field is used for estimation. (format: int64)
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "boardId" $boardId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/issue/($issueIdOrKey)/estimation" $qp)
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create sprint
#
# POST /rest/agile/1.0/sprint
# operationId: createSprint
export def "rest-agile-10-sprint createSprint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDate: string
  --goal: string
  --name: string
  --originBoardId: int # format: int64
  --startDate: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/agile/1.0/sprint")
  let body = {endDate: $endDate, goal: $goal, name: $name, originBoardId: $originBoardId, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete sprint
#
# DELETE /rest/agile/1.0/sprint/{sprintId}
# operationId: deleteSprint
export def "rest-agile-10-sprint delete" [
  sprintId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/sprint/($sprintId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sprint
#
# GET /rest/agile/1.0/sprint/{sprintId}
# operationId: getSprint
export def "rest-agile-10-sprint get" [
  sprintId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/sprint/($sprintId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partially update sprint
#
# POST /rest/agile/1.0/sprint/{sprintId}
# operationId: partiallyUpdateSprint
export def "rest-agile-10-sprint partiallyUpdateSprint" [
  sprintId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --completeDate: string
  --createdDate: string
  --endDate: string
  --goal: string
  --id: int # format: int64
  --name: string
  --originBoardId: int # format: int64
  --self: string # format: uri
  --startDate: string
  --state: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/sprint/($sprintId)")
  let body = {completeDate: $completeDate, createdDate: $createdDate, endDate: $endDate, goal: $goal, id: $id, name: $name, originBoardId: $originBoardId, self: $self, startDate: $startDate, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update sprint
#
# PUT /rest/agile/1.0/sprint/{sprintId}
# operationId: updateSprint
export def "rest-agile-10-sprint updateSprint" [
  sprintId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --completeDate: string
  --createdDate: string
  --endDate: string
  --goal: string
  --id: int # format: int64
  --name: string
  --originBoardId: int # format: int64
  --self: string # format: uri
  --startDate: string
  --state: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/sprint/($sprintId)")
  let body = {completeDate: $completeDate, createdDate: $createdDate, endDate: $endDate, goal: $goal, id: $id, name: $name, originBoardId: $originBoardId, self: $self, startDate: $startDate, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get issues for sprint
#
# GET /rest/agile/1.0/sprint/{sprintId}/issue
# DEPRECATED
# operationId: getIssuesForSprint
@deprecated
export def "rest-agile-10-sprint-issue get" [
  sprintId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAt: int # The starting index of the returned issues. Base index: 0. See the 'Pagination' section at the top of this page for more details. (format: int64)
  --maxResults: int # The maximum number of issues to return per page. See the 'Pagination' section at the top of this page for more details. Note, the total number of issues returned is limited by the property 'jira.search.views.default.max' in your Jira instance. If you exceed this limit, your results will be truncated. (format: int32)
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Agile fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $startAt "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/agile/1.0/sprint/($sprintId)/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move issues to sprint and rank
#
# POST /rest/agile/1.0/sprint/{sprintId}/issue
# operationId: moveIssuesToSprintAndRank
export def "rest-agile-10-sprint-issue moveIssuesToSprintAndRank" [
  sprintId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --issues: list
  --rankAfterIssue: string
  --rankBeforeIssue: string
  --rankCustomFieldId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/sprint/($sprintId)/issue")
  let body = {issues: $issues, rankAfterIssue: $rankAfterIssue, rankBeforeIssue: $rankBeforeIssue, rankCustomFieldId: $rankCustomFieldId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get issues for sprint (enhanced)
#
# GET /rest/software/1.0/sprint/{sprintId}/issue
# operationId: getIssuesForSprintJSIS
export def "rest-software-10-sprint-issue get" [
  sprintId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextPageToken: string # The token for a page to fetch that is not the first page. The first page has a `nextPageToken` of `null`. Use the `nextPageToken` to fetch the next page of issues.  Note: The `nextPageToken` field is **not included** in the response for the last page, indicating there is no next page.
  --maxResults: int # The maximum number of items to return per page. To manage page size, the API may return fewer items per page where there is a large number of fields or properties returned. It returns max 5000 issues. (format: int32)
  --reconcileIssues: list # Strong consistency issue IDs to be reconciled with search results. Accepts max 50 IDs. This list of IDs should be consistent with each paginated request across different pages.
  --jql: string # Filters results using a JQL query. If you define an order in your JQL query, it will override the default order of the returned issues.   Note that `username` and `userkey` can't be used as search terms for this parameter due to privacy reasons. Use `accountId` instead.
  --validateQuery: string@bool-completer # Specifies whether to validate the JQL query or not. Default: true.
  --qp-fields: list # The list of fields to return for each issue. By default, all navigable and Software project fields are returned.
  --expand: string # A comma-separated list of the parameters to expand.
]: nothing -> record<expand: string, isLast: bool, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, names: record, nextPageToken: string, schema: record, warningMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "reconcileIssues" $reconcileIssues "multi") (serialize-qp "jql" $jql "scalar") (serialize-qp "validateQuery" $validateQuery "scalar") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/software/1.0/sprint/($sprintId)/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get properties keys
#
# GET /rest/agile/1.0/sprint/{sprintId}/properties
# operationId: getPropertiesKeys
export def "rest-agile-10-sprint-properties list" [
  sprintId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/sprint/($sprintId)/properties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete property
#
# DELETE /rest/agile/1.0/sprint/{sprintId}/properties/{propertyKey}
# operationId: deleteProperty
export def "rest-agile-10-sprint-properties delete" [
  sprintId: string
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/sprint/($sprintId)/properties/($propertyKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get property
#
# GET /rest/agile/1.0/sprint/{sprintId}/properties/{propertyKey}
# operationId: getProperty
export def "rest-agile-10-sprint-properties get" [
  sprintId: string
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/sprint/($sprintId)/properties/($propertyKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set property
#
# PUT /rest/agile/1.0/sprint/{sprintId}/properties/{propertyKey}
# operationId: setProperty
export def "rest-agile-10-sprint-properties setProperty" [
  sprintId: string
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/sprint/($sprintId)/properties/($propertyKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Swap sprint
#
# POST /rest/agile/1.0/sprint/{sprintId}/swap
# operationId: swapSprint
export def "rest-agile-10-sprint-swap swapSprint" [
  sprintId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sprintToSwapWith: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/agile/1.0/sprint/($sprintId)/swap")
  let body = {sprintToSwapWith: $sprintToSwapWith} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Store development information
#
# POST /rest/devinfo/0.10/bulk
# operationId: storeDevelopmentInformation
# --repositories item shape: {name: string, description?: string, forkOf?: string, url: string, commits?: list, branches?: list, pullRequests?: list, avatar?: string, avatarDescription?: string, id: string, updateSequenceId: int}
# --providerMetadata shape: {product?: string}
export def "rest-devinfo-010-bulk storeDevelopmentInformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira. If the JWT token corresponds to a Connect app that does not define the jiraDevelopmentTool module it will be rejected with a 403. See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
  repositories: list # List of repositories containing development information. Must not contain duplicates. Maximum number of entities across all repositories is 1000. — item shape: {name: string, description?: string, forkOf?: string, url: string, commits?: list, branches?: list, pullRequests?: list, avatar?: string, avatarDescription?: string, id: string, updateSequenceId: int}
  --preventTransitions: string@bool-completer # Flag to prevent automatic issue transitions and smart commits being fired, default is false.
  --operationType: string@operationType-completer # Indicates the operation being performed by the provider system when sending this data. "NORMAL" - Data received during normal operation (e.g. a user pushing a branch). "BACKFILL" - Data received while backfilling existing data (e.g. indexing a newly connected account). Default is "NORMAL". Please note that "BACKFILL" operations have a much higher rate-limiting threshold but are also processed slower in comparison to "NORMAL" operations. (e.g. NORMAL)
  --properties: record # Arbitrary properties to tag the submitted repositories with. These properties can be used for delete operations to e.g. clean up all development information associated with an account in the event that the account is removed from the provider system. Note that these properties will never be returned with repository or entity data. They are not intended for use as metadata to associate with a repository. Maximum length of each key or value is 255 characters. Maximum allowed number of properties key/value pairs is 5. Properties keys cannot start with '_' character. Properties keys cannot contain ':' character. 
  --providerMetadata: record # Information about the provider. This is useful for auditing, logging, debugging, and other internal uses. It is not considered private information. Hence, it may not contain personally identifiable information. — shape: {product?: string}
]: any -> record<acceptedDevinfoEntities: record, failedDevinfoEntities: record, unknownIssueKeys: list<string>, unknownAssociations: table<associationType: string, values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/devinfo/0.10/bulk")
  let body = {repositories: $repositories, preventTransitions: $preventTransitions, operationType: $operationType, properties: $properties, providerMetadata: $providerMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get repository
#
# GET /rest/devinfo/0.10/repository/{repositoryId}
# operationId: getRepository
export def "rest-devinfo-010-repository get" [
  repositoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira. If the JWT token corresponds to a Connect app that does not define the jiraDevelopmentTool module it will be rejected with a 403. See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> record<name: string, description: string, forkOf: string, url: string, commits: table<id: string, issueKeys: list, associations: list, updateSequenceId: int, hash: string, flags: list, message: string, author: record, fileCount: int, url: string, files: list, authorTimestamp: string, displayId: string>, branches: table<id: string, issueKeys: list, associations: list, updateSequenceId: int, name: string, lastCommit: record, createPullRequestUrl: string, url: string>, pullRequests: table<id: string, issueKeys: list, associations: list, updateSequenceId: int, status: string, title: string, author: record, commentCount: int, sourceBranch: string, sourceBranchUrl: string, lastUpdate: string, destinationBranch: string, destinationBranchUrl: string, reviewers: list, url: string, displayId: string>, avatar: string, avatarDescription: string, id: string, updateSequenceId: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/devinfo/0.10/repository/($repositoryId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete repository
#
# DELETE /rest/devinfo/0.10/repository/{repositoryId}
# operationId: deleteRepository
export def "rest-devinfo-010-repository delete-by-repositoryId" [
  repositoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceId: int # An optional property to use to control deletion. Only stored data with an updateSequenceId less than or equal to that provided will be deleted. This can be used to help ensure submit/delete requests are applied correctly if they are issued close together.  (format: int64)
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira. If the JWT token corresponds to a Connect app that does not define the jiraDevelopmentTool module it will be rejected with a 403. See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceId" $updateSequenceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/devinfo/0.10/repository/($repositoryId)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete development information by properties
#
# DELETE /rest/devinfo/0.10/bulkByProperties
# operationId: deleteByProperties
export def "rest-devinfo-010-bulk-by-properties delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceId: int # An optional property to use to control deletion. Only stored data with an updateSequenceId less than or equal to that provided will be deleted. This can be used to help ensure submit/delete requests are applied correctly if they are issued close together.  (format: int64)
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira. If the JWT token corresponds to a Connect app that does not define the jiraDevelopmentTool module it will be rejected with a 403. See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceId" $updateSequenceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/devinfo/0.10/bulkByProperties" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if data exists for the supplied properties
#
# GET /rest/devinfo/0.10/existsByProperties
# operationId: existsByProperties
export def "rest-devinfo-010-exists-by-properties existsByProperties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceId: int # An optional property. Filters out entities and repositories which have updateSequenceId greater than specified.  (format: int64)
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira. If the JWT token corresponds to a Connect app that does not define the jiraDevelopmentTool module it will be rejected with a 403. See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> record<hasDataMatchingProperties: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceId" $updateSequenceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/devinfo/0.10/existsByProperties" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete development information entity
#
# DELETE /rest/devinfo/0.10/repository/{repositoryId}/{entityType}/{entityId}
# operationId: deleteEntity
export def "rest-devinfo-010-repository delete-by-repositoryId-entityType-entityId" [
  repositoryId: string
  entityType: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceId: int # An optional property to use to control deletion. Only stored data with an updateSequenceId less than or equal to that provided will be deleted. This can be used to help ensure submit/delete requests are applied correctly if they are issued close together.  (format: int64)
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira. If the JWT token corresponds to a Connect app that does not define the jiraDevelopmentTool module it will be rejected with a 403. See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceId" $updateSequenceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/devinfo/0.10/repository/($repositoryId)/($entityType)/($entityId)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Feature Flag data
#
# POST /rest/featureflags/0.1/bulk
# operationId: submitFeatureFlags
# --flags item shape: {schemaVersion?: "1.0", id: string, key: string, updateSequenceId: int, displayName?: string, issueKeys?: list, associations?: list, summary: any, details: list}
# --providerMetadata shape: {product?: string}
export def "rest-featureflags-01-bulk submitFeatureFlags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Feature Flags module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
  --properties: record # Properties assigned to Feature Flag data that can then be used for delete / query operations.  Examples might be an account or user ID that can then be used to clean up data if an account is removed from the Provider system.  Note that these properties will never be returned with Feature Flag data. They are not intended for use as metadata to associate with a Feature Flag. Internally they are stored as a hash so that personal information etc. is never stored within Jira.  Properties are supplied as key/value pairs, a maximum of 5 properties can be supplied, and keys must not contain ':' or start with '_'.  (e.g. {accountId: account-234, projectId: project-123})
  flags: list # A list of Feature Flags to submit to Jira.  Each Feature Flag may be associated with 1 or more Jira issue keys, and will be associated with any properties included in this request. — item shape: {schemaVersion?: "1.0", id: string, key: string, updateSequenceId: int, displayName?: string, issueKeys?: list, associations?: list, summary: any, details: list}
  --providerMetadata: record # Information about the provider. This is useful for auditing, logging, debugging, and other internal uses. It is not considered private information. Hence, it may not contain personally identifiable information. — shape: {product?: string}
]: any -> record<acceptedFeatureFlags: list<string>, failedFeatureFlags: record, unknownIssueKeys: list<string>, unknownAssociations: table<associationType: string, values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/featureflags/0.1/bulk")
  let body = {properties: $properties, flags: $flags, providerMetadata: $providerMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Feature Flags by Property
#
# DELETE /rest/featureflags/0.1/bulkByProperties
# operationId: deleteFeatureFlagsByProperty
@deprecated --flag updateSequenceId
export def "rest-featureflags-01-bulk-by-properties delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceId: int # This parameter usage is no longer supported.  An optional `_updateSequenceId` to use to control deletion.  Only stored data with an `updateSequenceId` less than or equal to that provided will be deleted. This can be used help ensure submit/delete requests are applied correctly if issued close together.  If not provided, all stored data that matches the request will be deleted.  (DEPRECATED, format: int64)
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Feature Flags module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceId" $updateSequenceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/featureflags/0.1/bulkByProperties" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Feature Flag by ID
#
# GET /rest/featureflags/0.1/flag/{featureFlagId}
# operationId: getFeatureFlagById
export def "rest-featureflags-01-flag get" [
  featureFlagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Feature Flags module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> record<schemaVersion: string, id: string, key: string, updateSequenceId: int, displayName: string, issueKeys: list<string>, associations: table<associationType: string, values: list>, summary: record<url: string, status: record<enabled: bool, defaultValue: string, rollout: record>, lastUpdated: string>, details: table<url: string, lastUpdated: string, environment: record, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/featureflags/0.1/flag/($featureFlagId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Feature Flag by ID
#
# DELETE /rest/featureflags/0.1/flag/{featureFlagId}
# operationId: deleteFeatureFlagById
@deprecated --flag updateSequenceId
export def "rest-featureflags-01-flag delete" [
  featureFlagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceId: int # This parameter usage is no longer supported.  An optional `_updateSequenceId` to use to control deletion.  Only stored data with an `updateSequenceId` less than or equal to that provided will be deleted. This can be used help ensure submit/delete requests are applied correctly if issued close together.  (DEPRECATED, format: int64)
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Feature Flags module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceId" $updateSequenceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/featureflags/0.1/flag/($featureFlagId)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit deployment data
#
# POST /rest/deployments/0.1/bulk
# operationId: submitDeployments
# --deployments item shape: {deploymentSequenceNumber: int, updateSequenceNumber: int, issueKeys?: list, associations?: list, displayName: string, url: string, description: string, lastUpdated: string, label?: string, duration?: int, state: "unknown"|"pending"|"in_progress"|"cancelled"|"failed"|"rolled_back"|"successful", pipeline: any, environment: any, commands?: list, schemaVersion?: "1.0"}
# --providerMetadata shape: {product?: string}
export def "rest-deployments-01-bulk submitDeployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraDeploymentInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
  --properties: record # Properties assigned to deployment data that can then be used for delete / query operations.  Examples might be an account or user ID that can then be used to clean up data if an account is removed from the Provider system.  Properties are supplied as key/value pairs, and a maximum of 5 properties can be supplied, keys cannot contain ':' or start with '_'.  (e.g. {accountId: account-234, projectId: project-123})
  deployments: list # A list of deployments to submit to Jira.  Each deployment may be associated with one or more Jira issue keys, and will be associated with any properties included in this request. — item shape: {deploymentSequenceNumber: int, updateSequenceNumber: int, issueKeys?: list, associations?: list, displayName: string, url: string, description: string, lastUpdated: string, label?: string, duration?: int, state: "unknown"|"pending"|"in_progress"|"cancelled"|"failed"|"rolled_back"|"successful", pipeline: any, environment: any, commands?: list, schemaVersion?: "1.0"}
  --providerMetadata: record # Information about the provider. This is useful for auditing, logging, debugging, and other internal uses. It is not considered private information. Hence, it may not contain personally identifiable information. — shape: {product?: string}
]: any -> record<acceptedDeployments: table<pipelineId: string, environmentId: string, deploymentSequenceNumber: int>, rejectedDeployments: table<key: record, errors: list>, unknownIssueKeys: list<string>, unknownAssociations: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/deployments/0.1/bulk")
  let body = {properties: $properties, deployments: $deployments, providerMetadata: $providerMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete deployments by Property
#
# DELETE /rest/deployments/0.1/bulkByProperties
# operationId: deleteDeploymentsByProperty
@deprecated --flag updateSequenceNumber
export def "rest-deployments-01-bulk-by-properties delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceNumber: int # This parameter usage is no longer supported.  An optional `updateSequenceNumber` to use to control deletion.  Only stored data with an `updateSequenceNumber` less than or equal to that provided will be deleted. This can be used help ensure submit/delete requests are applied correctly if issued close together.  If not provided, all stored data that matches the request will be deleted.  (DEPRECATED, format: int64)
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraDeploymentInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceNumber" $updateSequenceNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/deployments/0.1/bulkByProperties" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a deployment by key
#
# GET /rest/deployments/0.1/pipelines/{pipelineId}/environments/{environmentId}/deployments/{deploymentSequenceNumber}
# operationId: getDeploymentByKey
export def "rest-deployments-01-pipelines-environments-deployments get" [
  pipelineId: string
  environmentId: string
  deploymentSequenceNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraDeploymentInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> record<deploymentSequenceNumber: int, updateSequenceNumber: int, issueKeys: list<string>, associations: list<any>, displayName: string, url: string, description: string, lastUpdated: string, label: string, duration: int, state: string, pipeline: record<id: string, displayName: string, url: string>, environment: record<id: string, displayName: string, type: string>, commands: table<command: string>, schemaVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/deployments/0.1/pipelines/($pipelineId)/environments/($environmentId)/deployments/($deploymentSequenceNumber)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a deployment by key
#
# DELETE /rest/deployments/0.1/pipelines/{pipelineId}/environments/{environmentId}/deployments/{deploymentSequenceNumber}
# operationId: deleteDeploymentByKey
@deprecated --flag updateSequenceNumber
export def "rest-deployments-01-pipelines-environments-deployments delete" [
  pipelineId: string
  environmentId: string
  deploymentSequenceNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceNumber: int # This parameter usage is no longer supported.  An optional `_updateSequenceNumber` to use to control deletion.  Only stored data with an `updateSequenceNumber` less than or equal to that provided will be deleted. This can be used help ensure submit/delete requests are applied correctly if issued close together.  (DEPRECATED, format: int64)
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraDeploymentInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceNumber" $updateSequenceNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/deployments/0.1/pipelines/($pipelineId)/environments/($environmentId)/deployments/($deploymentSequenceNumber)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get deployment gating status by key
#
# GET /rest/deployments/0.1/pipelines/{pipelineId}/environments/{environmentId}/deployments/{deploymentSequenceNumber}/gating-status
# operationId: getDeploymentGatingStatusByKey
export def "rest-deployments-01-pipelines-environments-deployments-gating-status get" [
  pipelineId: string
  environmentId: string
  deploymentSequenceNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deploymentSequenceNumber: int, pipelineId: string, environmentId: string, updatedTimestamp: string, gatingStatus: string, details: table<type: string, issueKey: string, issueLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/deployments/0.1/pipelines/($pipelineId)/environments/($environmentId)/deployments/($deploymentSequenceNumber)/gating-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit build data
#
# POST /rest/builds/0.1/bulk
# operationId: submitBuilds
# --builds item shape: {schemaVersion?: "1.0", pipelineId: string, buildNumber: int, updateSequenceNumber: int, displayName: string, description?: string, label?: string, url: string, state: "pending"|"in_progress"|"successful"|"failed"|"cancelled"|"unknown", lastUpdated: string, issueKeys?: list, associations?: list, testInfo?: record, references?: list}
# --providerMetadata shape: {product?: string}
export def "rest-builds-01-bulk submitBuilds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraBuildInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
  --properties: record # Properties assigned to build data that can then be used for delete / query operations.  Examples might be an account or user ID that can then be used to clean up data if an account is removed from the Provider system.  Note that these properties will never be returned with build data. They are not intended for use as metadata to associate with a build. Internally they are stored as a hash so that personal information etc. is never stored within Jira.  Properties are supplied as key/value pairs, a maximum of 5 properties can be supplied, and keys must not contain ':' or start with '_'.  (e.g. {accountId: account-234, projectId: project-123})
  builds: list # A list of builds to submit to Jira.  Each build may be associated with one or more Jira issue keys, and will be associated with any properties included in this request. — item shape: {schemaVersion?: "1.0", pipelineId: string, buildNumber: int, updateSequenceNumber: int, displayName: string, description?: string, label?: string, url: string, state: "pending"|"in_progress"|"successful"|"failed"|"cancelled"|"unknown", lastUpdated: string, issueKeys?: list, associations?: list, testInfo?: record, references?: list}
  --providerMetadata: record # Information about the provider. This is useful for auditing, logging, debugging, and other internal uses. It is not considered private information. Hence, it may not contain personally identifiable information. — shape: {product?: string}
]: any -> record<acceptedBuilds: table<pipelineId: string, buildNumber: int>, rejectedBuilds: table<key: record, errors: list>, unknownIssueKeys: list<string>, unknownAssociations: table<associationType: string, values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/builds/0.1/bulk")
  let body = {properties: $properties, builds: $builds, providerMetadata: $providerMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete builds by Property
#
# DELETE /rest/builds/0.1/bulkByProperties
# operationId: deleteBuildsByProperty
@deprecated --flag updateSequenceNumber
export def "rest-builds-01-bulk-by-properties delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceNumber: int # This parameter usage is no longer supported.  An optional `_updateSequenceNumber` to use to control deletion.  Only stored data with an `updateSequenceNumber` less than or equal to that provided will be deleted. This can be used help ensure submit/delete requests are applied correctly if issued close together.  If not provided, all stored data that matches the request will be deleted.  (DEPRECATED, format: int64)
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraBuildInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceNumber" $updateSequenceNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/builds/0.1/bulkByProperties" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a build by key
#
# GET /rest/builds/0.1/pipelines/{pipelineId}/builds/{buildNumber}
# operationId: getBuildByKey
export def "rest-builds-01-pipelines-builds get" [
  pipelineId: string
  buildNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraBuildInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> record<schemaVersion: string, pipelineId: string, buildNumber: int, updateSequenceNumber: int, displayName: string, description: string, label: string, url: string, state: string, lastUpdated: string, issueKeys: list<string>, associations: table<associationType: string, values: list>, testInfo: record<totalNumber: int, numberPassed: int, numberFailed: int, numberSkipped: int>, references: table<commit: record, ref: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/builds/0.1/pipelines/($pipelineId)/builds/($buildNumber)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a build by key
#
# DELETE /rest/builds/0.1/pipelines/{pipelineId}/builds/{buildNumber}
# operationId: deleteBuildByKey
@deprecated --flag updateSequenceNumber
export def "rest-builds-01-pipelines-builds delete" [
  pipelineId: string
  buildNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceNumber: int # This parameter usage is no longer supported.  An optional `_updateSequenceNumber` to use to control deletion.  Only stored data with an `updateSequenceNumber` less than or equal to that provided will be deleted. This can be used help ensure submit/delete requests are applied correctly if issued close together.  (DEPRECATED, format: int64)
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraBuildInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceNumber" $updateSequenceNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/builds/0.1/pipelines/($pipelineId)/builds/($buildNumber)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Remote Link data
#
# POST /rest/remotelinks/1.0/bulk
# operationId: submitRemoteLinks
# --remoteLinks item shape: {schemaVersion?: "1.0", id: string, updateSequenceNumber: int, displayName: string, url: string, type: "document"|"alert"|"test"|"security"|"logFile"|"prototype"|"coverage"|"bugReport"|"other", description?: string, lastUpdated: string, associations?: list, status?: record, actionIds?: list, attributeMap?: record}
# --providerMetadata shape: {product?: string}
export def "rest-remotelinks-10-bulk submitRemoteLinks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraRemoteLinkInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
  --properties: record # Properties assigned to Remote Link data that can then be used for delete / query operations.  Examples might be an account or user ID that can then be used to clean up data if an account is removed from the Provider system.  Properties are supplied as key/value pairs, a maximum of 5 properties can be supplied, and keys must not contain ':' or start with '_'.  (e.g. {accountId: account-234, projectId: project-123})
  remoteLinks: list # A list of Remote Links to submit to Jira.  Each Remote Link may be associated with one or more Jira issue keys, and will be associated with any properties included in this request. — item shape: {schemaVersion?: "1.0", id: string, updateSequenceNumber: int, displayName: string, url: string, type: "document"|"alert"|"test"|"security"|"logFile"|"prototype"|"coverage"|"bugReport"|"other", description?: string, lastUpdated: string, associations?: list, status?: record, actionIds?: list, attributeMap?: record}
  --providerMetadata: record # Information about the provider. This is useful for auditing, logging, debugging, and other internal uses. It is not considered private information. Hence, it may not contain personally identifiable information. — shape: {product?: string}
]: any -> record<acceptedRemoteLinks: list<string>, rejectedRemoteLinks: record, unknownAssociations: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/remotelinks/1.0/bulk")
  let body = {properties: $properties, remoteLinks: $remoteLinks, providerMetadata: $providerMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Remote Links by Property
#
# DELETE /rest/remotelinks/1.0/bulkByProperties
# operationId: deleteRemoteLinksByProperty
@deprecated --flag updateSequenceNumber
export def "rest-remotelinks-10-bulk-by-properties delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceNumber: int # This parameter usage is no longer supported.  An optional `_updateSequenceNumber` to use to control deletion.  Only stored data with an `updateSequenceNumber` less than or equal to that provided will be deleted. This can be used help ensure submit/delete requests are applied correctly if issued close together.  If not provided, all stored data that matches the request will be deleted.  (DEPRECATED, format: int64)
  --params: record # Free-form query parameters to specify which properties to delete by. Properties refer to the arbitrary information the provider tagged Remote Links with previously.  For example, if the provider previously tagged a remote link with accountId:   "properties": {     "accountId": "account-123"   }  And now they want to delete Remote Links in bulk by that specific accountId as follows: e.g. DELETE /bulkByProperties?accountId=account-123
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraRemoteLinkInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceNumber" $updateSequenceNumber "scalar") (serialize-qp "params" $params "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/remotelinks/1.0/bulkByProperties" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Remote Link by ID
#
# GET /rest/remotelinks/1.0/remotelink/{remoteLinkId}
# operationId: getRemoteLinkById
export def "rest-remotelinks-10-remotelink get" [
  remoteLinkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraRemoteLinkInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> record<schemaVersion: string, id: string, updateSequenceNumber: int, displayName: string, url: string, type: string, description: string, lastUpdated: string, associations: list<any>, status: record<appearance: string, label: string>, actionIds: list<string>, attributeMap: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/remotelinks/1.0/remotelink/($remoteLinkId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Remote Link by ID
#
# DELETE /rest/remotelinks/1.0/remotelink/{remoteLinkId}
# operationId: deleteRemoteLinkById
@deprecated --flag updateSequenceNumber
export def "rest-remotelinks-10-remotelink delete" [
  remoteLinkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateSequenceNumber: int # This parameter usage is no longer supported.  An optional `_updateSequenceNumber` to use to control deletion.  Only stored data with an `updateSequenceNumber` less than or equal to that provided will be deleted. This can be used help ensure submit/delete requests are applied correctly if issued close together.  (DEPRECATED, format: int64)
  --Authorization: string # All requests must be signed with either a Connect JWT token or OAuth token for an on-premise integration that corresponds to an app installed in Jira.  If the Connect JWT token corresponds to an app that does not define `jiraRemoteLinkInfoProvider` module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details about Connect JWT tokens. See https://developer.atlassian.com/cloud/jira/software/integrate-jsw-cloud-with-onpremises-tools/ for details about on-premise integrations.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_updateSequenceNumber" $updateSequenceNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/remotelinks/1.0/remotelink/($remoteLinkId)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Security Workspaces to link
#
# POST /rest/security/1.0/linkedWorkspaces/bulk
# operationId: submitWorkspaces
export def "rest-security-10-linked-workspaces-bulk submitWorkspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define the Security Information module it will be rejected with a 403.  Read [understanding jwt](https://developer.atlassian.com/blog/2015/01/understanding-jwt/) for more details.
  workspaceIds: list # The IDs of Security Workspaces to link to this Jira site. These must follow this regex pattern: `[a-zA-Z0-9\\-_.~@:{}=]+(\/[a-zA-Z0-9\\-_.~@:{}=]+)*`  (e.g. [111-222-333, 444-555-666])
]: any -> table<message: string, errorTraceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/security/1.0/linkedWorkspaces/bulk")
  let body = {workspaceIds: $workspaceIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete linked Security Workspaces
#
# DELETE /rest/security/1.0/linkedWorkspaces/bulk
# operationId: deleteLinkedWorkspaces
export def "rest-security-10-linked-workspaces-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define the Security Information module it will be rejected with a 403.  Read [understanding jwt](https://developer.atlassian.com/blog/2015/01/understanding-jwt/) for more details.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/security/1.0/linkedWorkspaces/bulk")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get linked Security Workspaces
#
# GET /rest/security/1.0/linkedWorkspaces
# operationId: getLinkedWorkspaces
export def "rest-security-10-linked-workspaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define the Security Information module it will be rejected with a 403.  Read more about JWT [here](https://developer.atlassian.com/blog/2015/01/understanding-jwt/).
]: nothing -> record<workspaceIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/security/1.0/linkedWorkspaces")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a linked Security Workspace by ID
#
# GET /rest/security/1.0/linkedWorkspaces/{workspaceId}
# operationId: getLinkedWorkspaceById
export def "rest-security-10-linked-workspaces get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define the Security Information module it will be rejected with a 403.  Read more about JWT [here](https://developer.atlassian.com/blog/2015/01/understanding-jwt/).
]: nothing -> record<workspaceId: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/security/1.0/linkedWorkspaces/($workspaceId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Vulnerability data
#
# POST /rest/security/1.0/bulk
# operationId: submitVulnerabilities
# --vulnerabilities item shape: {schemaVersion: "1.0", id: string, updateSequenceNumber: int, containerId: string, displayName: string, description: string, url: string, type: "sca"|"sast"|"dast"|"unknown", introducedDate: string, lastUpdated: string, severity: any, identifiers?: list, status: "open"|"closed"|"ignored"|"unknown", additionalInfo?: record, addAssociations?: list, removeAssociations?: list, associationsLastUpdated?: string, associationsUpdateSequenceNumber?: int}
# --providerMetadata shape: {product?: string}
export def "rest-security-10-bulk submitVulnerabilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define the Security Information module it will be rejected with a 403.  Read more about JWT [here](https://developer.atlassian.com/blog/2015/01/understanding-jwt/).
  --operationType: string@operationType-completer-1 # Indicates the operation being performed by the provider system when sending this data. "NORMAL" - Data received during real-time, user-triggered actions (e.g. user closed or updated a vulnerability). "SCAN" - Data sent through some automated process (e.g. some periodically scheduled repository scan). "BACKFILL" - Data received while backfilling existing data (e.g. pushing historical vulnerabilities when re-connect a workspace). Default is "NORMAL". "NORMAL" traffic has higher priority but tighter rate limits, "SCAN" traffic has medium priority and looser limits, "BACKFILL" has lower priority and much looser limits  (e.g. SCAN)
  --properties: record # Properties assigned to vulnerability data that can then be used for delete / query operations.  Examples might be an account or user ID that can then be used to clean up data if an account is removed from the Provider system.  Properties are supplied as key/value pairs, and a maximum of 5 properties can be supplied, keys cannot contain ':' or start with '_'.  (e.g. {accountId: account-234, projectId: project-123})
  vulnerabilities: list # item shape: {schemaVersion: "1.0", id: string, updateSequenceNumber: int, containerId: string, displayName: string, description: string, url: string, type: "sca"|"sast"|"dast"|"unknown", introducedDate: string, lastUpdated: string, severity: any, identifiers?: list, status: "open"|"closed"|"ignored"|"unknown", additionalInfo?: record, addAssociations?: list, removeAssociations?: list, associationsLastUpdated?: string, associationsUpdateSequenceNumber?: int}
  --providerMetadata: record # Information about the provider. This is useful for auditing, logging, debugging, and other internal uses. Information in this property is not considered private, so it should not contain personally identifiable information — shape: {product?: string}
]: any -> record<acceptedVulnerabilities: list<string>, failedVulnerabilities: record, unknownAssociations: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/security/1.0/bulk")
  let body = {operationType: $operationType, properties: $properties, vulnerabilities: $vulnerabilities, providerMetadata: $providerMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Vulnerabilities by Property
#
# DELETE /rest/security/1.0/bulkByProperties
# operationId: deleteVulnerabilitiesByProperty
export def "rest-security-10-bulk-by-properties delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Security Information module it will be rejected with a 403.  Read more about JWT [here](https://developer.atlassian.com/blog/2015/01/understanding-jwt/).
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/security/1.0/bulkByProperties")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Vulnerability by ID
#
# GET /rest/security/1.0/vulnerability/{vulnerabilityId}
# operationId: getVulnerabilityById
export def "rest-security-10-vulnerability get" [
  vulnerabilityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Security Information module it will be rejected with a 403.  Read more about JWT [here](https://developer.atlassian.com/blog/2015/01/understanding-jwt/).
]: nothing -> record<schemaVersion: string, id: string, updateSequenceNumber: int, containerId: string, displayName: string, description: string, url: string, type: string, introducedDate: string, lastUpdated: string, severity: record<level: string>, identifiers: table<displayName: string, url: string>, status: string, additionalInfo: record<content: string, url: string>, addAssociations: list<any>, removeAssociations: list<any>, associationsLastUpdated: string, associationsUpdateSequenceNumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/security/1.0/vulnerability/($vulnerabilityId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Vulnerability by ID
#
# DELETE /rest/security/1.0/vulnerability/{vulnerabilityId}
# operationId: deleteVulnerabilityById
export def "rest-security-10-vulnerability delete" [
  vulnerabilityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Security Information module it will be rejected with a 403.  Read more about JWT [here](https://developer.atlassian.com/blog/2015/01/understanding-jwt/).
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/security/1.0/vulnerability/($vulnerabilityId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Operations Workspace Ids
#
# POST /rest/operations/1.0/linkedWorkspaces/bulk
# operationId: submitOperationsWorkspaces
export def "rest-operations-10-linked-workspaces-bulk submitOperationsWorkspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define the Operations module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
  workspaceIds: list # The IDs of Operations Workspaces that are available to this Jira site.  (e.g. [111-222-333, 444-555-666])
]: any -> record<acceptedWorkspaceIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/operations/1.0/linkedWorkspaces/bulk")
  let body = {workspaceIds: $workspaceIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Operations Workpaces by Id
#
# DELETE /rest/operations/1.0/linkedWorkspaces/bulk
# operationId: deleteWorkspaces
export def "rest-operations-10-linked-workspaces-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define the Operations module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/operations/1.0/linkedWorkspaces/bulk")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Operations Workspace IDs or a specific Operations Workspace by ID
#
# GET /rest/operations/1.0/linkedWorkspaces
# operationId: getWorkspaces
export def "rest-operations-10-linked-workspaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define the Operations Information module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> record<workspaceIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/operations/1.0/linkedWorkspaces")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Incident or Review data
#
# POST /rest/operations/1.0/bulk
# operationId: submitEntity
# --providerMetadata shape: {product?: string}
# --incidents item shape: {schemaVersion: "1.0", id: string, updateSequenceNumber: int, affectedComponents: list, summary: string, description: string, url: string, createdDate: string, lastUpdated: string, severity?: any, status: "open"|"resolved"|"unknown", associations?: list}
# --reviews item shape: {schemaVersion: "1.0", id: string, updateSequenceNumber: int, reviews: list, summary: string, description: string, url: string, createdDate: string, lastUpdated: string, status: "in progress"|"outstanding actions"|"completed"|"unknown", associations?: list}
export def "rest-operations-10-bulk submitEntity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define the Operations Information module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
  --properties: record # Properties assigned to incidents/components/review data that can then be used for delete / query operations.  Examples might be an account or user ID that can then be used to clean up data if an account is removed from the Provider system.  Properties are supplied as key/value pairs, and a maximum of 5 properties can be supplied, keys cannot contain ':' or start with '_'.  (e.g. {accountId: account-234, projectId: project-123})
  --providerMetadata: record # Information about the provider. This is useful for auditing, logging, debugging, and other internal uses. It is not considered private information. Hence, it may not contain personally identifiable information. — shape: {product?: string}
  --incidents: list # item shape: {schemaVersion: "1.0", id: string, updateSequenceNumber: int, affectedComponents: list, summary: string, description: string, url: string, createdDate: string, lastUpdated: string, severity?: any, status: "open"|"resolved"|"unknown", associations?: list}
  --reviews: list # item shape: {schemaVersion: "1.0", id: string, updateSequenceNumber: int, reviews: list, summary: string, description: string, url: string, createdDate: string, lastUpdated: string, status: "in progress"|"outstanding actions"|"completed"|"unknown", associations?: list}
]: any -> record<acceptedIncidents: list<string>, failedIncidents: record, unknownProjectKeys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/operations/1.0/bulk")
  let body = {properties: $properties, providerMetadata: $providerMetadata, incidents: $incidents, reviews: $reviews} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Incidents or Review by Property
#
# DELETE /rest/operations/1.0/bulkByProperties
# operationId: deleteEntityByProperty
export def "rest-operations-10-bulk-by-properties delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Operations Information module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/operations/1.0/bulkByProperties")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Incident by ID
#
# GET /rest/operations/1.0/incidents/{incidentId}
# operationId: getIncidentById
export def "rest-operations-10-incidents get" [
  incidentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Operations Information module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> record<schemaVersion: string, id: string, updateSequenceNumber: int, affectedComponents: list<string>, summary: string, description: string, url: string, createdDate: string, lastUpdated: string, severity: record<level: string>, status: string, associations: table<associationType: string, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/operations/1.0/incidents/($incidentId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Incident by ID
#
# DELETE /rest/operations/1.0/incidents/{incidentId}
# operationId: deleteIncidentById
export def "rest-operations-10-incidents delete" [
  incidentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Operations Information module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/operations/1.0/incidents/($incidentId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Review by ID
#
# GET /rest/operations/1.0/post-incident-reviews/{reviewId}
# operationId: getReviewById
export def "rest-operations-10-post-incident-reviews get" [
  reviewId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Operations Information module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> record<schemaVersion: string, id: string, updateSequenceNumber: int, reviews: list<string>, summary: string, description: string, url: string, createdDate: string, lastUpdated: string, status: string, associations: table<associationType: string, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/operations/1.0/post-incident-reviews/($reviewId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Review by ID
#
# DELETE /rest/operations/1.0/post-incident-reviews/{reviewId}
# operationId: deleteReviewById
export def "rest-operations-10-post-incident-reviews delete" [
  reviewId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Operations Information module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/operations/1.0/post-incident-reviews/($reviewId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit DevOps Components
#
# POST /rest/devopscomponents/1.0/bulk
# operationId: submitComponents
# --devopsComponents item shape: {schemaVersion: "1.0", id: string, updateSequenceNumber: int, name: string, providerName?: string, description: string, url: string, avatarUrl: string, tier: "Tier 1"|"Tier 2"|"Tier 3"|"Tier 4", componentType: "Service"|"Application"|"Library"|"Capability"|"Cloud resource"|"Data pipeline"|"Machine learning model"|"UI element"|"Website"|"Other", lastUpdated: string}
# --providerMetadata shape: {product?: string}
export def "rest-devopscomponents-10-bulk submitComponents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define the DevOps Information module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
  --properties: record # Properties assigned to incidents/components/review data that can then be used for delete / query operations.  Examples might be an account or user ID that can then be used to clean up data if an account is removed from the Provider system.  Properties are supplied as key/value pairs, and a maximum of 5 properties can be supplied, keys cannot contain ':' or start with '_'.  (e.g. {accountId: account-234, projectId: project-123})
  devopsComponents: list # item shape: {schemaVersion: "1.0", id: string, updateSequenceNumber: int, name: string, providerName?: string, description: string, url: string, avatarUrl: string, tier: "Tier 1"|"Tier 2"|"Tier 3"|"Tier 4", componentType: "Service"|"Application"|"Library"|"Capability"|"Cloud resource"|"Data pipeline"|"Machine learning model"|"UI element"|"Website"|"Other", lastUpdated: string}
  --providerMetadata: record # Information about the provider. This is useful for auditing, logging, debugging, and other internal uses. It is not considered private information. Hence, it may not contain personally identifiable information. — shape: {product?: string}
]: any -> record<acceptedComponents: list<string>, failedComponents: record, unknownProjectKeys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/devopscomponents/1.0/bulk")
  let body = {properties: $properties, devopsComponents: $devopsComponents, providerMetadata: $providerMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete DevOps Components by Property
#
# DELETE /rest/devopscomponents/1.0/bulkByProperties
# operationId: deleteComponentsByProperty
export def "rest-devopscomponents-10-bulk-by-properties delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define the Operations Information module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/devopscomponents/1.0/bulkByProperties")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Component by ID
#
# GET /rest/devopscomponents/1.0/devopscomponents/{componentId}
# operationId: getComponentById
export def "rest-devopscomponents-10-devopscomponents get" [
  componentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Operations Information module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> record<schemaVersion: string, id: string, updateSequenceNumber: int, name: string, providerName: string, description: string, url: string, avatarUrl: string, tier: string, componentType: string, lastUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/devopscomponents/1.0/devopscomponents/($componentId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Component by ID
#
# DELETE /rest/devopscomponents/1.0/devopscomponents/{componentId}
# operationId: deleteComponentById
export def "rest-devopscomponents-10-devopscomponents delete" [
  componentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # All requests must be signed with a Connect JWT token that corresponds to the Provider app installed in Jira.  If the JWT token corresponds to an app that does not define Operations Information module it will be rejected with a 403.  See https://developer.atlassian.com/blog/2015/01/understanding-jwt/ for more details.
]: nothing -> table<message: string, errorTraceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/devopscomponents/1.0/devopscomponents/($componentId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
