# Auto-generated client for The Jira Cloud platform REST API v1001.0.0-SNAPSHOT
# Source: https://api.apis.guru/v2/specs/atlassian.com/jira/1001.0.0-SNAPSHOT/openapi.json
# Auth: --token flag or $env.THE_JIRA_CLOUD_PLATFORM_REST_API_TOKEN

const BASE_URL = "https://your-domain.atlassian.net"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o THE_JIRA_CLOUD_PLATFORM_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
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

def base-url-completer [] { ["https://your-domain.atlassian.net"] }
def auth-scheme-completer [] { ["bearer" "basic" "basic-credentials"] }

# Completers for enum parameters
def assignee-type-completer [] { ["COMPONENT_LEAD" "PROJECT_DEFAULT" "PROJECT_LEAD" "UNASSIGNED"] }
def default-unit-completer [] { ["day" "hour" "minute" "week"] }
def time-format-completer [] { ["days" "hours" "pretty"] }
def filter-completer [] { ["favourite" "my"] }
def order-by-completer [] { ["+description" "+favorite_count" "+id" "+is_favorite" "+name" "+owner" "-description" "-favorite_count" "-id" "-is_favorite" "-name" "-owner" "description" "favorite_count" "id" "is_favorite" "name" "owner"] }
def status-completer [] { ["active" "archived" "deleted"] }
def check-completer [] { ["complexity" "syntax" "type"] }
def searcher-key-completer [] { ["com.atlassian.jira.plugin.system.customfieldtypes:cascadingselectsearcher" "com.atlassian.jira.plugin.system.customfieldtypes:daterange" "com.atlassian.jira.plugin.system.customfieldtypes:datetimerange" "com.atlassian.jira.plugin.system.customfieldtypes:exactnumber" "com.atlassian.jira.plugin.system.customfieldtypes:exacttextsearcher" "com.atlassian.jira.plugin.system.customfieldtypes:grouppickersearcher" "com.atlassian.jira.plugin.system.customfieldtypes:labelsearcher" "com.atlassian.jira.plugin.system.customfieldtypes:multiselectsearcher" "com.atlassian.jira.plugin.system.customfieldtypes:numberrange" "com.atlassian.jira.plugin.system.customfieldtypes:projectsearcher" "com.atlassian.jira.plugin.system.customfieldtypes:textsearcher" "com.atlassian.jira.plugin.system.customfieldtypes:userpickergroupsearcher" "com.atlassian.jira.plugin.system.customfieldtypes:versionsearcher"] }
def order-by-completer-1 [] { ["+contextsCount" "+lastUsed" "+name" "+projectsCount" "+screensCount" "-contextsCount" "-lastUsed" "-name" "-projectsCount" "-screensCount" "contextsCount" "lastUsed" "name" "projectsCount" "screensCount"] }
def expand-completer [] { ["+name" "+plannedDeletionDate" "+projectsCount" "+trashDate" "-name" "-plannedDeletionDate" "-projectsCount" "-trashDate" "name" "plannedDeletionDate" "projectsCount" "trashDate"] }
def position-completer [] { ["First" "Last"] }
def scope-completer [] { ["AUTHENTICATED" "GLOBAL" "PRIVATE"] }
def order-by-completer-2 [] { ["+description" "+favourite_count" "+id" "+is_favourite" "+is_shared" "+name" "+owner" "-description" "-favourite_count" "-id" "-is_favourite" "-is_shared" "-name" "-owner" "description" "favourite_count" "id" "is_favourite" "is_shared" "name" "owner"] }
def type-completer [] { ["authenticated" "global" "group" "project" "projectRole" "user"] }
def avatar-size-completer [] { ["large" "large@2x" "large@3x" "medium" "medium@2x" "medium@3x" "small" "small@2x" "small@3x" "xlarge" "xlarge@2x" "xlarge@3x" "xsmall" "xsmall@2x" "xsmall@3x" "xxlarge" "xxlarge@2x" "xxlarge@3x" "xxxlarge" "xxxlarge@2x" "xxxlarge@3x"] }
def delete-subtasks-completer [] { ["false" "true"] }
def order-by-completer-3 [] { ["+created" "-created" "created"] }
def adjust-estimate-completer [] { ["auto" "leave" "manual" "new"] }
def type-completer-1 [] { ["standard" "subtask"] }
def order-by-completer-4 [] { ["+id" "+name" "-id" "-name" "id" "name"] }
def validation-completer [] { ["none" "strict" "warn"] }
def icon-url-completer [] { ["/images/icons/priorities/blocker.png" "/images/icons/priorities/critical.png" "/images/icons/priorities/high.png" "/images/icons/priorities/highest.png" "/images/icons/priorities/low.png" "/images/icons/priorities/lowest.png" "/images/icons/priorities/major.png" "/images/icons/priorities/medium.png" "/images/icons/priorities/minor.png" "/images/icons/priorities/trivial.png"] }
def assignee-type-completer-1 [] { ["PROJECT_LEAD" "UNASSIGNED"] }
def project-template-key-completer [] { ["com.atlassian.jira-core-project-templates:jira-core-simplified-content-management" "com.atlassian.jira-core-project-templates:jira-core-simplified-document-approval" "com.atlassian.jira-core-project-templates:jira-core-simplified-lead-tracking" "com.atlassian.jira-core-project-templates:jira-core-simplified-process-control" "com.atlassian.jira-core-project-templates:jira-core-simplified-procurement" "com.atlassian.jira-core-project-templates:jira-core-simplified-project-management" "com.atlassian.jira-core-project-templates:jira-core-simplified-recruitment" "com.atlassian.jira-core-project-templates:jira-core-simplified-task-" "com.atlassian.servicedesk:simplified-analytics-service-desk" "com.atlassian.servicedesk:simplified-custom-project-service-desk" "com.atlassian.servicedesk:simplified-external-service-desk" "com.atlassian.servicedesk:simplified-facilities-service-desk" "com.atlassian.servicedesk:simplified-finance-service-desk" "com.atlassian.servicedesk:simplified-general-service-desk" "com.atlassian.servicedesk:simplified-general-service-desk-business" "com.atlassian.servicedesk:simplified-general-service-desk-it" "com.atlassian.servicedesk:simplified-halp-service-desk" "com.atlassian.servicedesk:simplified-hr-service-desk" "com.atlassian.servicedesk:simplified-internal-service-desk" "com.atlassian.servicedesk:simplified-it-service-management" "com.atlassian.servicedesk:simplified-legal-service-desk" "com.atlassian.servicedesk:simplified-marketing-service-desk" "com.pyxis.greenhopper.jira:gh-simplified-agility-kanban" "com.pyxis.greenhopper.jira:gh-simplified-agility-scrum" "com.pyxis.greenhopper.jira:gh-simplified-basic" "com.pyxis.greenhopper.jira:gh-simplified-kanban-classic" "com.pyxis.greenhopper.jira:gh-simplified-scrum-classic"] }
def project-type-key-completer [] { ["business" "service_desk" "software"] }
def order-by-completer-5 [] { ["+archivedDate" "+category" "+deletedDate" "+issueCount" "+key" "+lastIssueUpdatedDate" "+name" "+owner" "-archivedDate" "-category" "-deletedDate" "-issueCount" "-key" "-lastIssueUpdatedDate" "-name" "-owner" "archivedDate" "category" "deletedDate" "issueCount" "key" "lastIssueUpdatedDate" "name" "owner"] }
def action-completer [] { ["browse" "edit" "view"] }
def order-by-completer-6 [] { ["+description" "+issueCount" "+lead" "+name" "-description" "-issueCount" "-lead" "-name" "description" "issueCount" "lead" "name"] }
def state-completer [] { ["COMING_SOON" "DISABLED" "ENABLED"] }
def order-by-completer-7 [] { ["+description" "+name" "+releaseDate" "+sequence" "+startDate" "-description" "-name" "-releaseDate" "-sequence" "-startDate" "description" "name" "releaseDate" "sequence" "startDate"] }
def position-completer-1 [] { ["Earlier" "First" "Last" "Later"] }
def validate-query-completer [] { ["false" "none" "strict" "true" "warn"] }
def size-completer [] { ["large" "medium" "small" "xlarge" "xsmall"] }
def format-completer [] { ["png" "svg"] }
def accept-completer [] { ["*/*" "application/json" "image/png" "image/svg+xml"] }
def order-by-completer-8 [] { ["+created" "+name" "+updated" "-created" "-name" "-updated" "created" "name" "updated"] }
def workflow-mode-completer [] { ["draft" "live"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rest-3-announcement-banner get" } } | get name | first)
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

# Get announcement banner configuration
#
# GET /rest/api/3/announcementBanner
# operationId: getBanner
export def "rest-3-announcement-banner get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<hashId: string, isDismissible: bool, isEnabled: bool, message: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/announcementBanner")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update announcement banner configuration
#
# PUT /rest/api/3/announcementBanner
# operationId: setBanner
export def "rest-3-announcement-banner update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-dismissible: oneof<nothing, bool> # Flag indicating if the announcement banner can be dismissed by the user.
  --is-enabled: oneof<nothing, bool> # Flag indicating if the announcement banner is enabled or not.
  --message: string # The text on the announcement banner.
  --visibility: string # Visibility of the announcement banner. Can be public or private.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/announcementBanner")
  let req_body = {"isDismissible": $is_dismissible, "isEnabled": $is_enabled, "message": $message, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update custom fields
#
# POST /rest/api/3/app/field/value
# operationId: updateMultipleCustomFieldValues
# --updates item shape: {customField: string, issueIds: list<int>, value: any}
export def "rest-3-app-field-value update-multiple-custom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --generate-changelog: oneof<nothing, bool> # Whether to generate a changelog for this update. (default: true)
  --updates: list # item shape: {customField: string, issueIds: list<int>, value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "generateChangelog" $generate_changelog "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/app/field/value" $qp)
  let req_body = {"updates": $updates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get custom field configurations
#
# GET /rest/api/3/app/field/{fieldIdOrKey}/context/configuration
# operationId: getCustomFieldConfiguration
export def "rest-3-app-field-context-configuration get-custom" [
  field_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<int> # The list of configuration IDs. To include multiple configurations, separate IDs with an ampersand: `id=10000&id=10001`. Can't be provided with `fieldContextId`, `issueId`, `projectKeyOrId`, or `issueTypeId`.
  --field-context-id: list<int> # The list of field context IDs. To include multiple field contexts, separate IDs with an ampersand: `fieldContextId=10000&fieldContextId=10001`. Can't be provided with `id`, `issueId`, `projectKeyOrId`, or `issueTypeId`.
  --issue-id: int # The ID of the issue to filter results by. If the issue doesn't exist, an empty list is returned. Can't be provided with `projectKeyOrId`, or `issueTypeId`. (format: int64)
  --project-key-or-id: string # The ID or key of the project to filter results by. Must be provided with `issueTypeId`. Can't be provided with `issueId`.
  --issue-type-id: string # The ID of the issue type to filter results by. Must be provided with `projectKeyOrId`. Can't be provided with `issueId`.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 100)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<configuration: any, fieldContextId: string, id: string, schema: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "fieldContextId" $field_context_id "multi") (serialize-qp "issueId" $issue_id "scalar") (serialize-qp "projectKeyOrId" $project_key_or_id "scalar") (serialize-qp "issueTypeId" $issue_type_id "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id_or_key: (encode-path-segment $field_id_or_key)} | format pattern "/rest/api/3/app/field/{field_id_or_key}/context/configuration") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update custom field configurations
#
# PUT /rest/api/3/app/field/{fieldIdOrKey}/context/configuration
# operationId: updateCustomFieldConfiguration
# --configurations item shape: {configuration?: any, id: string, schema?: any}
export def "rest-3-app-field-context-configuration update-custom" [
  field_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  configurations: list # The list of custom field configuration details. — item shape: {configuration?: any, id: string, schema?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id_or_key: (encode-path-segment $field_id_or_key)} | format pattern "/rest/api/3/app/field/{field_id_or_key}/context/configuration"))
  let req_body = {"configurations": $configurations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update custom field value
#
# PUT /rest/api/3/app/field/{fieldIdOrKey}/value
# operationId: updateCustomFieldValue
# --updates item shape: {issueIds: list<int>, value: any}
export def "rest-3-app-field-value update-custom" [
  field_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --generate-changelog: oneof<nothing, bool> # Whether to generate a changelog for this update. (default: true)
  --updates: list # The list of custom field update details. — item shape: {issueIds: list<int>, value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "generateChangelog" $generate_changelog "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id_or_key: (encode-path-segment $field_id_or_key)} | format pattern "/rest/api/3/app/field/{field_id_or_key}/value") $qp)
  let req_body = {"updates": $updates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get application property
#
# GET /rest/api/3/application-properties
# operationId: getApplicationProperty
export def "rest-3-application-properties get-property" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The key of the application property.
  --permission-level: string # The permission level of all items being returned in the list.
  --key-filter: string # When a `key` isn't provided, this filters the list of results by the application property `key` using a regular expression. For example, using `jira.lf.*` will return all application properties with keys that start with *jira.lf.*.
]: nothing -> table<allowedValues: list<string>, defaultValue: string, desc: string, example: string, id: string, key: string, name: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "permissionLevel" $permission_level "scalar") (serialize-qp "keyFilter" $key_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/application-properties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get advanced settings
#
# GET /rest/api/3/application-properties/advanced-settings
# operationId: getAdvancedSettings
export def "rest-3-application-properties-advanced-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<allowedValues: list<string>, defaultValue: string, desc: string, example: string, id: string, key: string, name: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/application-properties/advanced-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set application property
#
# PUT /rest/api/3/application-properties/{id}
# operationId: setApplicationProperty
export def "rest-3-application-properties update-property" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # The ID of the application property.
  --value: string # The new value.
]: any -> record<allowedValues: list<string>, defaultValue: string, desc: string, example: string, id: string, key: string, name: string, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/application-properties/{id}"))
  let req_body = {"id": $body_id, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all application roles
#
# GET /rest/api/3/applicationrole
# operationId: getAllApplicationRoles
export def "rest-3-applicationrole get-list-application-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<defaultGroups: list<string>, defaultGroupsDetails: list<record>, defined: bool, groupDetails: list<record>, groups: list<string>, hasUnlimitedSeats: bool, key: string, name: string, numberOfSeats: int, platform: bool, remainingSeats: int, selectedByDefault: bool, userCount: int, userCountDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/applicationrole")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get application role
#
# GET /rest/api/3/applicationrole/{key}
# operationId: getApplicationRole
export def "rest-3-applicationrole get-application-role" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultGroups: list<string>, defaultGroupsDetails: table<groupId: string, name: string, self: string>, defined: bool, groupDetails: table<groupId: string, name: string, self: string>, groups: list<string>, hasUnlimitedSeats: bool, key: string, name: string, numberOfSeats: int, platform: bool, remainingSeats: int, selectedByDefault: bool, userCount: int, userCountDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/rest/api/3/applicationrole/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachment content
#
# GET /rest/api/3/attachment/content/{id}
# operationId: getAttachmentContent
export def "rest-3-attachment-content get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirect: oneof<nothing, bool> # Whether a redirect is provided for the attachment download. Clients that do not automatically follow redirects can set this to `false` to avoid making multiple requests to download the attachment. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirect" $redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/attachment/content/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Jira attachment settings
#
# GET /rest/api/3/attachment/meta
# operationId: getAttachmentMeta
export def "rest-3-attachment-meta get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, uploadLimit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/attachment/meta")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachment thumbnail
#
# GET /rest/api/3/attachment/thumbnail/{id}
# operationId: getAttachmentThumbnail
export def "rest-3-attachment-thumbnail get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirect: oneof<nothing, bool> # Whether a redirect is provided for the attachment download. Clients that do not automatically follow redirects can set this to `false` to avoid making multiple requests to download the attachment. (default: true)
  --fallback-to-default: oneof<nothing, bool> # Whether a default thumbnail is returned when the requested thumbnail is not found. (default: true)
  --width: int # The maximum width to scale the thumbnail to. (format: int32)
  --height: int # The maximum height to scale the thumbnail to. (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirect" $redirect "scalar") (serialize-qp "fallbackToDefault" $fallback_to_default "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/attachment/thumbnail/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete attachment
#
# DELETE /rest/api/3/attachment/{id}
# operationId: removeAttachment
export def "rest-3-attachment delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/attachment/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachment metadata
#
# GET /rest/api/3/attachment/{id}
# operationId: getAttachment
export def "rest-3-attachment get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<author: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, content: string, created: string, filename: string, id: int, mimeType: string, properties: record, self: string, size: int, thumbnail: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/attachment/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all metadata for an expanded attachment
#
# GET /rest/api/3/attachment/{id}/expand/human
# operationId: expandAttachmentForHumans
export def "rest-3-attachment-expand-human get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<entries: table<index: int, label: string, mediaType: string, path: string, size: string>, id: int, mediaType: string, name: string, totalEntryCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/attachment/{id}/expand/human"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contents metadata for an expanded attachment
#
# GET /rest/api/3/attachment/{id}/expand/raw
# operationId: expandAttachmentForMachines
export def "rest-3-attachment-expand-raw get-for-machines" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<entries: table<abbreviatedName: string, entryIndex: int, mediaType: string, name: string, size: int>, totalEntryCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/attachment/{id}/expand/raw"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get audit records
#
# GET /rest/api/3/auditing/record
# operationId: getAuditRecords
export def "rest-3-auditing-record get-audit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of records to skip before returning the first result. (format: int32, default: 0)
  --limit: int # The maximum number of results to return. (format: int32, default: 1000)
  --filter: string # The strings to match with audit field content, space separated.
  --qp-from: string # The date and time on or after which returned audit records must have been created. If `to` is provided `from` must be before `to` or no audit records are returned. (format: date-time)
  --qp-to: string # The date and time on or before which returned audit results must have been created. If `from` is provided `to` must be after `from` or no audit records are returned. (format: date-time)
]: nothing -> record<limit: int, offset: int, records: table<associatedItems: list, authorKey: string, category: string, changedValues: list, created: string, description: string, eventSource: string, id: int, objectItem: record, remoteAddress: string, summary: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/auditing/record" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get system avatars by type
#
# GET /rest/api/3/avatar/{type}/system
# operationId: getAllSystemAvatars
export def "rest-3-avatar-system get-list" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<system: table<fileName: string, id: string, isDeletable: bool, isSelected: bool, isSystemAvatar: bool, owner: string, urls: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/rest/api/3/avatar/{type}/system"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get comments by IDs
#
# POST /rest/api/3/comment/list
# operationId: getCommentsByIds
export def "rest-3-comment-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about comments in the response. This parameter accepts a comma-separated list. Expand options include: * `renderedBody` Returns the comment body rendered in HTML. * `properties` Returns the comment's properties.
  ids: list<int> # The list of comment IDs. A maximum of 1000 IDs can be specified.
]: any -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<author: record, body: any, created: string, id: string, jsdAuthorCanSeeRequest: bool, jsdPublic: bool, properties: list, renderedBody: string, self: string, updateAuthor: record, updated: string, visibility: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/comment/list" $qp)
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get comment property keys
#
# GET /rest/api/3/comment/{commentId}/properties
# operationId: getCommentPropertyKeys
export def "rest-3-comment-properties get-property-keys" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keys: table<key: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/rest/api/3/comment/{comment_id}/properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete comment property
#
# DELETE /rest/api/3/comment/{commentId}/properties/{propertyKey}
# operationId: deleteCommentProperty
export def "rest-3-comment-properties delete-property" [
  comment_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/comment/{comment_id}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get comment property
#
# GET /rest/api/3/comment/{commentId}/properties/{propertyKey}
# operationId: getCommentProperty
export def "rest-3-comment-properties get-property" [
  comment_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/comment/{comment_id}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set comment property
#
# PUT /rest/api/3/comment/{commentId}/properties/{propertyKey}
# operationId: setCommentProperty
export def "rest-3-comment-properties update-property" [
  comment_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/comment/{comment_id}/properties/{property_key}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create component
#
# POST /rest/api/3/component
# operationId: createComponent
export def "rest-3-component create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee-type: string@assignee-type-completer # The nominal user type used to determine the assignee for issues created with this component. See `realAssigneeType` for details on how the type of the user, and hence the user, assigned to issues is determined. Can take the following values: * `PROJECT_LEAD` the assignee to any issues created with this component is nominally the lead for the project the component is in. * `COMPONENT_LEAD` the assignee to any issues created with this component is nominally the lead for the component. * `UNASSIGNED` an assignee is not set for issues created with this component. * `PROJECT_DEFAULT` the assignee to any issues created with this component is nominally the default assignee for the project that the component is in. Default value: `PROJECT_DEFAULT`. Optional when creating or updating a component.
  --description: string # The description for the component. Optional when creating or updating a component.
  --lead-account-id: string # The accountId of the component's lead user. The accountId uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*.
  --lead-user-name: string # This property is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --name: string # The unique name for the component in the project. Required when creating a component. Optional when updating a component. The maximum length is 255 characters.
  --project: string # The key of the project the component is assigned to. Required when creating a component. Can't be updated.
]: any -> record<assignee: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, assigneeType: string, description: string, id: string, isAssigneeTypeValid: bool, lead: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, leadAccountId: string, leadUserName: string, name: string, project: string, projectId: int, realAssignee: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, realAssigneeType: string, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/component")
  let req_body = {"assigneeType": $assignee_type, "description": $description, "leadAccountId": $lead_account_id, "leadUserName": $lead_user_name, "name": $name, "project": $project} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete component
#
# DELETE /rest/api/3/component/{id}
# operationId: deleteComponent
export def "rest-3-component delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --move-issues-to: string # The ID of the component to replace the deleted component. If this value is null no replacement is made.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "moveIssuesTo" $move_issues_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/component/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get component
#
# GET /rest/api/3/component/{id}
# operationId: getComponent
export def "rest-3-component get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, assigneeType: string, description: string, id: string, isAssigneeTypeValid: bool, lead: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, leadAccountId: string, leadUserName: string, name: string, project: string, projectId: int, realAssignee: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, realAssigneeType: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/component/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update component
#
# PUT /rest/api/3/component/{id}
# operationId: updateComponent
export def "rest-3-component update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee-type: string@assignee-type-completer # The nominal user type used to determine the assignee for issues created with this component. See `realAssigneeType` for details on how the type of the user, and hence the user, assigned to issues is determined. Can take the following values: * `PROJECT_LEAD` the assignee to any issues created with this component is nominally the lead for the project the component is in. * `COMPONENT_LEAD` the assignee to any issues created with this component is nominally the lead for the component. * `UNASSIGNED` an assignee is not set for issues created with this component. * `PROJECT_DEFAULT` the assignee to any issues created with this component is nominally the default assignee for the project that the component is in. Default value: `PROJECT_DEFAULT`. Optional when creating or updating a component.
  --description: string # The description for the component. Optional when creating or updating a component.
  --lead-account-id: string # The accountId of the component's lead user. The accountId uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*.
  --lead-user-name: string # This property is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --name: string # The unique name for the component in the project. Required when creating a component. Optional when updating a component. The maximum length is 255 characters.
  --project: string # The key of the project the component is assigned to. Required when creating a component. Can't be updated.
]: any -> record<assignee: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, assigneeType: string, description: string, id: string, isAssigneeTypeValid: bool, lead: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, leadAccountId: string, leadUserName: string, name: string, project: string, projectId: int, realAssignee: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, realAssigneeType: string, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/component/{id}"))
  let req_body = {"assigneeType": $assignee_type, "description": $description, "leadAccountId": $lead_account_id, "leadUserName": $lead_user_name, "name": $name, "project": $project} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get component issues count
#
# GET /rest/api/3/component/{id}/relatedIssueCounts
# operationId: getComponentRelatedIssues
export def "rest-3-component-related-issue-counts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<issueCount: int, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/component/{id}/relatedIssueCounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get global settings
#
# GET /rest/api/3/configuration
# operationId: getConfiguration
export def "rest-3-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachmentsEnabled: bool, issueLinkingEnabled: bool, subTasksEnabled: bool, timeTrackingConfiguration: record<defaultUnit: string, timeFormat: string, workingDaysPerWeek: float, workingHoursPerDay: float>, timeTrackingEnabled: bool, unassignedIssuesAllowed: bool, votingEnabled: bool, watchingEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get selected time tracking provider
#
# GET /rest/api/3/configuration/timetracking
# operationId: getSelectedTimeTrackingImplementation
export def "rest-3-configuration-timetracking get-selected-time-tracking-implementation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/configuration/timetracking")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Select time tracking provider
#
# PUT /rest/api/3/configuration/timetracking
# operationId: selectTimeTrackingImplementation
export def "rest-3-configuration-timetracking update-select-time-tracking-implementation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string # The key for the time tracking provider. For example, *JIRA*.
  --name: string # The name of the time tracking provider. For example, *JIRA provided time tracking*.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/configuration/timetracking")
  let req_body = {"key": $key, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all time tracking providers
#
# GET /rest/api/3/configuration/timetracking/list
# operationId: getAvailableTimeTrackingImplementations
export def "rest-3-configuration-timetracking-list get-available-time-tracking-implementations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/configuration/timetracking/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get time tracking settings
#
# GET /rest/api/3/configuration/timetracking/options
# operationId: getSharedTimeTrackingConfiguration
export def "rest-3-configuration-timetracking-options get-shared-time-tracking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultUnit: string, timeFormat: string, workingDaysPerWeek: float, workingHoursPerDay: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/configuration/timetracking/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set time tracking settings
#
# PUT /rest/api/3/configuration/timetracking/options
# operationId: setSharedTimeTrackingConfiguration
export def "rest-3-configuration-timetracking-options update-shared-time-tracking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  default_unit: string@default-unit-completer # The default unit of time applied to logged time.
  time_format: string@time-format-completer # The format that will appear on an issue's *Time Spent* field.
  working_days_per_week: float # The number of days in a working week. (format: double)
  working_hours_per_day: float # The number of hours in a working day. (format: double)
]: any -> record<defaultUnit: string, timeFormat: string, workingDaysPerWeek: float, workingHoursPerDay: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/configuration/timetracking/options")
  let req_body = {"defaultUnit": $default_unit, "timeFormat": $time_format, "workingDaysPerWeek": $working_days_per_week, "workingHoursPerDay": $working_hours_per_day} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get custom field option
#
# GET /rest/api/3/customFieldOption/{id}
# operationId: getCustomFieldOption
export def "rest-3-custom-field-option get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<self: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/customFieldOption/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all dashboards
#
# GET /rest/api/3/dashboard
# operationId: getAllDashboards
export def "rest-3-dashboard get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer # The filter applied to the list of dashboards. Valid values are: * `favourite` Returns dashboards the user has marked as favorite. * `my` Returns dashboards owned by the user.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int32, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 20)
]: nothing -> record<dashboards: table<automaticRefreshMs: int, description: string, editPermissions: list, id: string, isFavourite: bool, isWritable: bool, name: string, owner: record, popularity: int, rank: int, self: string, sharePermissions: list, systemDashboard: bool, view: string>, maxResults: int, next: string, prev: string, startAt: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/dashboard" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create dashboard
#
# POST /rest/api/3/dashboard
# operationId: createDashboard
# --editPermissions item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
# --sharePermissions item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
export def "rest-3-dashboard create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the dashboard.
  edit_permissions: list # The edit permissions for the dashboard. — item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
  name: string # The name of the dashboard.
  share_permissions: list # The share permissions for the dashboard. — item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
]: any -> record<automaticRefreshMs: int, description: string, editPermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, id: string, isFavourite: bool, isWritable: bool, name: string, owner: record<accountId: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, key: string, name: string, self: string>, popularity: int, rank: int, self: string, sharePermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, systemDashboard: bool, view: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/dashboard")
  let req_body = {"description": $description, "editPermissions": $edit_permissions, "name": $name, "sharePermissions": $share_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get available gadgets
#
# GET /rest/api/3/dashboard/gadgets
# operationId: getAllAvailableDashboardGadgets
export def "rest-3-dashboard-gadgets get-list-available" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<gadgets: table<moduleKey: string, title: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/dashboard/gadgets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for dashboards
#
# GET /rest/api/3/dashboard/search
# operationId: getDashboardsPaginated
export def "rest-3-dashboard-search get-paginated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dashboard-name: string # String used to perform a case-insensitive partial match with `name`.
  --account-id: string # User account ID used to return dashboards with the matching `owner.accountId`. This parameter cannot be used with the `owner` parameter.
  --owner: string # This parameter is deprecated because of privacy changes. Use `accountId` instead. See the [migration guide](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details. User name used to return dashboards with the matching `owner.name`. This parameter cannot be used with the `accountId` parameter.
  --groupname: string # As a group's name can change, use of `groupId` is recommended. Group name used to return dashboards that are shared with a group that matches `sharePermissions.group.name`. This parameter cannot be used with the `groupId` parameter.
  --group-id: string # Group ID used to return dashboards that are shared with a group that matches `sharePermissions.group.groupId`. This parameter cannot be used with the `groupname` parameter.
  --project-id: int # Project ID used to returns dashboards that are shared with a project that matches `sharePermissions.project.id`. (format: int64)
  --order-by: string@order-by-completer # [Order](#ordering) the results by a field: * `description` Sorts by dashboard description. Note that this sort works independently of whether the expand to display the description field is in use. * `favourite_count` Sorts by dashboard popularity. * `id` Sorts by dashboard ID. * `is_favourite` Sorts by whether the dashboard is marked as a favorite. * `name` Sorts by dashboard name. * `owner` Sorts by dashboard owner name. (default: name)
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --status: string@status-completer # The status to filter by. It may be active, archived or deleted. (default: active)
  --expand: string # Use [expand](#expansion) to include additional information about dashboard in the response. This parameter accepts a comma-separated list. Expand options include: * `description` Returns the description of the dashboard. * `owner` Returns the owner of the dashboard. * `viewUrl` Returns the URL that is used to view the dashboard. * `favourite` Returns `isFavourite`, an indicator of whether the user has set the dashboard as a favorite. * `favouritedCount` Returns `popularity`, a count of how many users have set this dashboard as a favorite. * `sharePermissions` Returns details of the share permissions defined for the dashboard. * `editPermissions` Returns details of the edit permissions defined for the dashboard. * `isWritable` Returns whether the current user has permission to edit the dashboard.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<automaticRefreshMs: int, description: string, editPermissions: list, id: string, isFavourite: bool, isWritable: bool, name: string, owner: record, popularity: int, rank: int, self: string, sharePermissions: list, systemDashboard: bool, view: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dashboardName" $dashboard_name "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "groupname" $groupname "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/dashboard/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get gadgets
#
# GET /rest/api/3/dashboard/{dashboardId}/gadget
# operationId: getAllGadgets
export def "rest-3-dashboard-gadget get-list" [
  dashboard_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --module-key: list<string> # The list of gadgets module keys. To include multiple module keys, separate module keys with ampersand: `moduleKey=key:one&moduleKey=key:two`.
  --uri: list<string> # The list of gadgets URIs. To include multiple URIs, separate URIs with ampersand: `uri=/rest/example/uri/1&uri=/rest/example/uri/2`.
  --gadget-id: list<int> # The list of gadgets IDs. To include multiple IDs, separate IDs with ampersand: `gadgetId=10000&gadgetId=10001`.
]: nothing -> record<gadgets: table<color: string, id: int, moduleKey: string, position: record, title: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "moduleKey" $module_key "multi") (serialize-qp "uri" $uri "multi") (serialize-qp "gadgetId" $gadget_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/rest/api/3/dashboard/{dashboard_id}/gadget") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add gadget to dashboard
#
# POST /rest/api/3/dashboard/{dashboardId}/gadget
# operationId: addGadget
export def "rest-3-dashboard-gadget create" [
  dashboard_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string # The color of the gadget. Should be one of `blue`, `red`, `yellow`, `green`, `cyan`, `purple`, `gray`, or `white`.
  --ignore-uri-and-module-key-validation: oneof<nothing, bool> # Whether to ignore the validation of module key and URI. For example, when a gadget is created that is a part of an application that isn't installed.
  --module-key: string # The module key of the gadget type. Can't be provided with `uri`.
  --position: any # The position of the gadget. When the gadget is placed into the position, other gadgets in the same column are moved down to accommodate it.
  --title: string # The title of the gadget.
  --uri: string # The URI of the gadget type. Can't be provided with `moduleKey`.
]: any -> record<color: string, id: int, moduleKey: string, position: record<The_column_position_of_the_gadget_: int, The_row_position_of_the_gadget_: int>, title: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/rest/api/3/dashboard/{dashboard_id}/gadget"))
  let req_body = {"color": $color, "ignoreUriAndModuleKeyValidation": $ignore_uri_and_module_key_validation, "moduleKey": $module_key, "position": $position, "title": $title, "uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove gadget from dashboard
#
# DELETE /rest/api/3/dashboard/{dashboardId}/gadget/{gadgetId}
# operationId: removeGadget
export def "rest-3-dashboard-gadget delete" [
  dashboard_id: int
  gadget_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: (encode-path-segment $dashboard_id), gadget_id: (encode-path-segment $gadget_id)} | format pattern "/rest/api/3/dashboard/{dashboard_id}/gadget/{gadget_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update gadget on dashboard
#
# PUT /rest/api/3/dashboard/{dashboardId}/gadget/{gadgetId}
# operationId: updateGadget
export def "rest-3-dashboard-gadget update" [
  dashboard_id: int
  gadget_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string # The color of the gadget. Should be one of `blue`, `red`, `yellow`, `green`, `cyan`, `purple`, `gray`, or `white`.
  --position: any # The position of the gadget.
  --title: string # The title of the gadget.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: (encode-path-segment $dashboard_id), gadget_id: (encode-path-segment $gadget_id)} | format pattern "/rest/api/3/dashboard/{dashboard_id}/gadget/{gadget_id}"))
  let req_body = {"color": $color, "position": $position, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get dashboard item property keys
#
# GET /rest/api/3/dashboard/{dashboardId}/items/{itemId}/properties
# operationId: getDashboardItemPropertyKeys
export def "rest-3-dashboard-items-properties get-property-keys" [
  dashboard_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keys: table<key: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: (encode-path-segment $dashboard_id), item_id: (encode-path-segment $item_id)} | format pattern "/rest/api/3/dashboard/{dashboard_id}/items/{item_id}/properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete dashboard item property
#
# DELETE /rest/api/3/dashboard/{dashboardId}/items/{itemId}/properties/{propertyKey}
# operationId: deleteDashboardItemProperty
export def "rest-3-dashboard-items-properties delete-property" [
  dashboard_id: string
  item_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: (encode-path-segment $dashboard_id), item_id: (encode-path-segment $item_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/dashboard/{dashboard_id}/items/{item_id}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get dashboard item property
#
# GET /rest/api/3/dashboard/{dashboardId}/items/{itemId}/properties/{propertyKey}
# operationId: getDashboardItemProperty
export def "rest-3-dashboard-items-properties get-property" [
  dashboard_id: string
  item_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: (encode-path-segment $dashboard_id), item_id: (encode-path-segment $item_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/dashboard/{dashboard_id}/items/{item_id}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set dashboard item property
#
# PUT /rest/api/3/dashboard/{dashboardId}/items/{itemId}/properties/{propertyKey}
# operationId: setDashboardItemProperty
export def "rest-3-dashboard-items-properties update-property" [
  dashboard_id: string
  item_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: (encode-path-segment $dashboard_id), item_id: (encode-path-segment $item_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/dashboard/{dashboard_id}/items/{item_id}/properties/{property_key}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete dashboard
#
# DELETE /rest/api/3/dashboard/{id}
# operationId: deleteDashboard
export def "rest-3-dashboard delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/dashboard/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get dashboard
#
# GET /rest/api/3/dashboard/{id}
# operationId: getDashboard
export def "rest-3-dashboard get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<automaticRefreshMs: int, description: string, editPermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, id: string, isFavourite: bool, isWritable: bool, name: string, owner: record<accountId: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, key: string, name: string, self: string>, popularity: int, rank: int, self: string, sharePermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, systemDashboard: bool, view: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/dashboard/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update dashboard
#
# PUT /rest/api/3/dashboard/{id}
# operationId: updateDashboard
# --editPermissions item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
# --sharePermissions item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
export def "rest-3-dashboard update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the dashboard.
  edit_permissions: list # The edit permissions for the dashboard. — item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
  name: string # The name of the dashboard.
  share_permissions: list # The share permissions for the dashboard. — item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
]: any -> record<automaticRefreshMs: int, description: string, editPermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, id: string, isFavourite: bool, isWritable: bool, name: string, owner: record<accountId: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, key: string, name: string, self: string>, popularity: int, rank: int, self: string, sharePermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, systemDashboard: bool, view: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/dashboard/{id}"))
  let req_body = {"description": $description, "editPermissions": $edit_permissions, "name": $name, "sharePermissions": $share_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Copy dashboard
#
# POST /rest/api/3/dashboard/{id}/copy
# operationId: copyDashboard
# --editPermissions item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
# --sharePermissions item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
export def "rest-3-dashboard-copy copy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the dashboard.
  edit_permissions: list # The edit permissions for the dashboard. — item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
  name: string # The name of the dashboard.
  share_permissions: list # The share permissions for the dashboard. — item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
]: any -> record<automaticRefreshMs: int, description: string, editPermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, id: string, isFavourite: bool, isWritable: bool, name: string, owner: record<accountId: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, key: string, name: string, self: string>, popularity: int, rank: int, self: string, sharePermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, systemDashboard: bool, view: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/dashboard/{id}/copy"))
  let req_body = {"description": $description, "editPermissions": $edit_permissions, "name": $name, "sharePermissions": $share_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get events
#
# GET /rest/api/3/events
# operationId: getEvents
export def "rest-3-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Analyse Jira expression
#
# POST /rest/api/3/expression/analyse
# operationId: analyseExpression
export def "rest-3-expression-analyse create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --check: string@check-completer # The check to perform: * `syntax` Each expression's syntax is checked to ensure the expression can be parsed. Also, syntactic limits are validated. For example, the expression's length. * `type` EXPERIMENTAL. Each expression is type checked and the final type of the expression inferred. Any type errors that would result in the expression failure at runtime are reported. For example, accessing properties that don't exist or passing the wrong number of arguments to functions. Also performs the syntax check. * `complexity` EXPERIMENTAL. Determines the formulae for how many [expensive operations](https://developer.atlassian.com/cloud/jira/platform/jira-expressions/#expensive-operations) each expression may execute. (default: syntax)
  --context-variables: record # Context variables and their types. The type checker assumes that [common context variables](https://developer.atlassian.com/cloud/jira/platform/jira-expressions/#context-variables), such as `issue` or `project`, are available in context and sets their type. Use this property to override the default types or provide details of new variables.
  expressions: list<string> # The list of Jira expressions to analyse. (e.g. issues.map(issue => issue.properties['property_key']))
]: any -> record<results: table<complexity: record, errors: list, expression: string, type: string, valid: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "check" $check "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/expression/analyse" $qp)
  let req_body = {"contextVariables": $context_variables, "expressions": $expressions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Evaluate Jira expression
#
# POST /rest/api/3/expression/eval
# operationId: evaluateJiraExpression
export def "rest-3-expression-eval create-evaluate-jira" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts `meta.complexity` that returns information about the expression complexity. For example, the number of expensive operations used by the expression and how close the expression is to reaching the [complexity limit](https://developer.atlassian.com/cloud/jira/platform/jira-expressions/#restrictions). Useful when designing and debugging your expressions.
  --context: any # The context in which the Jira expression is evaluated.
  expression: string # The Jira expression to evaluate. (e.g. { key: issue.key, type: issue.issueType.name, links: issue.links.map(link => link.linkedIssue.id) })
]: any -> record<meta: record<complexity: record<beans: record, expensiveOperations: record, primitiveValues: record, steps: record>, issues: record<jql: record>>, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/expression/eval" $qp)
  let req_body = {"context": $context, "expression": $expression} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get fields
#
# GET /rest/api/3/field
# operationId: getFields
export def "rest-3-field get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<clauseNames: list<string>, custom: bool, id: string, key: string, name: string, navigable: bool, orderable: bool, schema: record<configuration: record, custom: string, customId: int, items: string, system: string, type: string>, scope: record<project: record, type: string>, searchable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/field")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create custom field
#
# POST /rest/api/3/field
# operationId: createCustomField
export def "rest-3-field create-custom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the custom field, which is displayed in Jira.
  name: string # The name of the custom field, which is displayed in Jira. This is not the unique identifier.
  --searcher-key: string@searcher-key-completer # The searcher defines the way the field is searched in Jira. For example, *com.atlassian.jira.plugin.system.customfieldtypes:grouppickersearcher*. The search UI (basic search and JQL search) will display different operations and values for the field, based on the field searcher. You must specify a searcher that is valid for the field type, as listed below (abbreviated values shown): * `cascadingselect`: `cascadingselectsearcher` * `datepicker`: `daterange` * `datetime`: `datetimerange` * `float`: `exactnumber` or `numberrange` * `grouppicker`: `grouppickersearcher` * `importid`: `exactnumber` or `numberrange` * `labels`: `labelsearcher` * `multicheckboxes`: `multiselectsearcher` * `multigrouppicker`: `multiselectsearcher` * `multiselect`: `multiselectsearcher` * `multiuserpicker`: `userpickergroupsearcher` * `multiversion`: `versionsearcher` * `project`: `projectsearcher` * `radiobuttons`: `multiselectsearcher` * `readonlyfield`: `textsearcher` * `select`: `multiselectsearcher` * `textarea`: `textsearcher` * `textfield`: `textsearcher` * `url`: `exacttextsearcher` * `userpicker`: `userpickergroupsearcher` * `version`: `versionsearcher` If no searcher is provided, the field isn't searchable. However, [Forge custom fields](https://developer.atlassian.com/platform/forge/manifest-reference/modules/#jira-custom-field-type--beta-) have a searcher set automatically, so are always searchable.
  type: string # The type of the custom field. These built-in custom field types are available: * `cascadingselect`: Enables values to be selected from two levels of select lists (value: `com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect`) * `datepicker`: Stores a date using a picker control (value: `com.atlassian.jira.plugin.system.customfieldtypes:datepicker`) * `datetime`: Stores a date with a time component (value: `com.atlassian.jira.plugin.system.customfieldtypes:datetime`) * `float`: Stores and validates a numeric (floating point) input (value: `com.atlassian.jira.plugin.system.customfieldtypes:float`) * `grouppicker`: Stores a user group using a picker control (value: `com.atlassian.jira.plugin.system.customfieldtypes:grouppicker`) * `importid`: A read-only field that stores the ID the issue had in the system it was imported from (value: `com.atlassian.jira.plugin.system.customfieldtypes:importid`) * `labels`: Stores labels (value: `com.atlassian.jira.plugin.system.customfieldtypes:labels`) * `multicheckboxes`: Stores multiple values using checkboxes (value: ``) * `multigrouppicker`: Stores multiple user groups using a picker control (value: ``) * `multiselect`: Stores multiple values using a select list (value: `com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes`) * `multiuserpicker`: Stores multiple users using a picker control (value: `com.atlassian.jira.plugin.system.customfieldtypes:multigrouppicker`) * `multiversion`: Stores multiple versions from the versions available in a project using a picker control (value: `com.atlassian.jira.plugin.system.customfieldtypes:multiversion`) * `project`: Stores a project from a list of projects that the user is permitted to view (value: `com.atlassian.jira.plugin.system.customfieldtypes:project`) * `radiobuttons`: Stores a value using radio buttons (value: `com.atlassian.jira.plugin.system.customfieldtypes:radiobuttons`) * `readonlyfield`: Stores a read-only text value, which can only be populated via the API (value: `com.atlassian.jira.plugin.system.customfieldtypes:readonlyfield`) * `select`: Stores a value from a configurable list of options (value: `com.atlassian.jira.plugin.system.customfieldtypes:select`) * `textarea`: Stores a long text string using a multiline text area (value: `com.atlassian.jira.plugin.system.customfieldtypes:textarea`) * `textfield`: Stores a text string using a single-line text box (value: `com.atlassian.jira.plugin.system.customfieldtypes:textfield`) * `url`: Stores a URL (value: `com.atlassian.jira.plugin.system.customfieldtypes:url`) * `userpicker`: Stores a user using a picker control (value: `com.atlassian.jira.plugin.system.customfieldtypes:userpicker`) * `version`: Stores a version using a picker control (value: `com.atlassian.jira.plugin.system.customfieldtypes:version`) To create a field based on a [Forge custom field type](https://developer.atlassian.com/platform/forge/manifest-reference/modules/#jira-custom-field-type--beta-), use the ID of the Forge custom field type as the value. For example, `ari:cloud:ecosystem::extension/e62f20a2-4b61-4dbe-bfb9-9a88b5e3ac84/548c5df1-24aa-4f7c-bbbb-3038d947cb05/static/my-cf-type-key`.
]: any -> record<clauseNames: list<string>, custom: bool, id: string, key: string, name: string, navigable: bool, orderable: bool, schema: record<configuration: record, custom: string, customId: int, items: string, system: string, type: string>, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, searchable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/field")
  let req_body = {"description": $description, "name": $name, "searcherKey": $searcher_key, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get fields paginated
#
# GET /rest/api/3/field/search
# operationId: getFieldsPaginated
export def "rest-3-field-search get-paginated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --type: list<string> # The type of fields to search.
  --id: list<string> # The IDs of the custom fields to return or, where `query` is specified, filter.
  --query: string # String used to perform a case-insensitive partial match with field names or descriptions.
  --order-by: string@order-by-completer-1 # [Order](#ordering) the results by a field: * `contextsCount` sorts by the number of contexts related to a field * `lastUsed` sorts by the date when the value of the field last changed * `name` sorts by the field name * `screensCount` sorts by the number of screens related to a field
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expand options include: * `key` returns the key for each field * `lastUsed` returns the date when the value of the field last changed * `screensCount` returns the number of screens related to a field * `contextsCount` returns the number of contexts related to a field * `isLocked` returns information about whether the field is [locked](https://confluence.atlassian.com/x/ZSN7Og) * `searcherKey` returns the searcher key for each custom field
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<contextsCount: int, description: string, id: string, isLocked: bool, isUnscreenable: bool, key: string, lastUsed: record, name: string, projectsCount: int, schema: record, screensCount: int, searcherKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "type" $type "multi") (serialize-qp "id" $id "multi") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/field/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get fields in trash paginated
#
# GET /rest/api/3/field/search/trashed
# operationId: getTrashedFieldsPaginated
export def "rest-3-field-search-trashed get-paginated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --id: list<string>
  --query: string # String used to perform a case-insensitive partial match with field names or descriptions.
  --expand: string@expand-completer
  --order-by: string # [Order](#ordering) the results by a field: * `name` sorts by the field name * `trashDate` sorts by the date the field was moved to the trash * `plannedDeletionDate` sorts by the planned deletion date
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<contextsCount: int, description: string, id: string, isLocked: bool, isUnscreenable: bool, key: string, lastUsed: record, name: string, projectsCount: int, schema: record, screensCount: int, searcherKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "id" $id "multi") (serialize-qp "query" $query "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/field/search/trashed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update custom field
#
# PUT /rest/api/3/field/{fieldId}
# operationId: updateCustomField
export def "rest-3-field update-custom" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the custom field. The maximum length is 40000 characters.
  --name: string # The name of the custom field. It doesn't have to be unique. The maximum length is 255 characters.
  --searcher-key: string@searcher-key-completer # The searcher that defines the way the field is searched in Jira. It can be set to `null`, otherwise you must specify the valid searcher for the field type, as listed below (abbreviated values shown): * `cascadingselect`: `cascadingselectsearcher` * `datepicker`: `daterange` * `datetime`: `datetimerange` * `float`: `exactnumber` or `numberrange` * `grouppicker`: `grouppickersearcher` * `importid`: `exactnumber` or `numberrange` * `labels`: `labelsearcher` * `multicheckboxes`: `multiselectsearcher` * `multigrouppicker`: `multiselectsearcher` * `multiselect`: `multiselectsearcher` * `multiuserpicker`: `userpickergroupsearcher` * `multiversion`: `versionsearcher` * `project`: `projectsearcher` * `radiobuttons`: `multiselectsearcher` * `readonlyfield`: `textsearcher` * `select`: `multiselectsearcher` * `textarea`: `textsearcher` * `textfield`: `textsearcher` * `url`: `exacttextsearcher` * `userpicker`: `userpickergroupsearcher` * `version`: `versionsearcher`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/rest/api/3/field/{field_id}"))
  let req_body = {"description": $description, "name": $name, "searcherKey": $searcher_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get custom field contexts
#
# GET /rest/api/3/field/{fieldId}/context
# operationId: getContextsForField
export def "rest-3-field-context get" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-any-issue-type: oneof<nothing, bool> # Whether to return contexts that apply to all issue types.
  --is-global-context: oneof<nothing, bool> # Whether to return contexts that apply to all projects.
  --context-id: list<int> # The list of context IDs. To include multiple contexts, separate IDs with ampersand: `contextId=10000&contextId=10001`.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, id: string, isAnyIssueType: bool, isGlobalContext: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isAnyIssueType" $is_any_issue_type "scalar") (serialize-qp "isGlobalContext" $is_global_context "scalar") (serialize-qp "contextId" $context_id "multi") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/rest/api/3/field/{field_id}/context") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create custom field context
#
# POST /rest/api/3/field/{fieldId}/context
# operationId: createCustomFieldContext
export def "rest-3-field-context create-custom" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the context.
  --issue-type-ids: list<string> # The list of issue types IDs for the context. If the list is empty, the context refers to all issue types.
  name: string # The name of the context.
  --project-ids: list<string> # The list of project IDs associated with the context. If the list is empty, the context is global.
]: any -> record<description: string, id: string, issueTypeIds: list<string>, name: string, projectIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/rest/api/3/field/{field_id}/context"))
  let req_body = {"description": $description, "issueTypeIds": $issue_type_ids, "name": $name, "projectIds": $project_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get custom field contexts default values
#
# GET /rest/api/3/field/{fieldId}/context/defaultValue
# operationId: getDefaultValues
export def "rest-3-field-context-default-value get" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context-id: list<int> # The IDs of the contexts.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextId" $context_id "multi") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/rest/api/3/field/{field_id}/context/defaultValue") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set custom field contexts default values
#
# PUT /rest/api/3/field/{fieldId}/context/defaultValue
# operationId: setDefaultValues
export def "rest-3-field-context-default-value update" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-values: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/rest/api/3/field/{field_id}/context/defaultValue"))
  let req_body = {"defaultValues": $default_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get issue types for custom field context
#
# GET /rest/api/3/field/{fieldId}/context/issuetypemapping
# operationId: getIssueTypeMappingsForContexts
export def "rest-3-field-context-issuetypemapping get-issue-type-mappings" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context-id: list<int> # The ID of the context. To include multiple contexts, provide an ampersand-separated list. For example, `contextId=10001&contextId=10002`.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<contextId: string, isAnyIssueType: bool, issueTypeId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextId" $context_id "multi") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/rest/api/3/field/{field_id}/context/issuetypemapping") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom field contexts for projects and issue types
#
# POST /rest/api/3/field/{fieldId}/context/mapping
# operationId: getCustomFieldContextsForProjectsAndIssueTypes
# --mappings item shape: {issueTypeId: string, projectId: string}
export def "rest-3-field-context-mapping get-custom-for-projects-and-issue-types" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  mappings: list # The project and issue type mappings. — item shape: {issueTypeId: string, projectId: string}
]: any -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<contextId: string, issueTypeId: string, projectId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/rest/api/3/field/{field_id}/context/mapping") $qp)
  let req_body = {"mappings": $mappings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get project mappings for custom field context
#
# GET /rest/api/3/field/{fieldId}/context/projectmapping
# operationId: getProjectContextMapping
export def "rest-3-field-context-projectmapping get-project-mapping" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context-id: list<int> # The list of context IDs. To include multiple context, separate IDs with ampersand: `contextId=10000&contextId=10001`.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<contextId: string, isGlobalContext: bool, projectId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextId" $context_id "multi") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/rest/api/3/field/{field_id}/context/projectmapping") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete custom field context
#
# DELETE /rest/api/3/field/{fieldId}/context/{contextId}
# operationId: deleteCustomFieldContext
export def "rest-3-field-context delete-custom" [
  field_id: string
  context_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), context_id: (encode-path-segment $context_id)} | format pattern "/rest/api/3/field/{field_id}/context/{context_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update custom field context
#
# PUT /rest/api/3/field/{fieldId}/context/{contextId}
# operationId: updateCustomFieldContext
export def "rest-3-field-context update-custom" [
  field_id: string
  context_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the custom field context. The maximum length is 255 characters.
  --name: string # The name of the custom field context. The name must be unique. The maximum length is 255 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), context_id: (encode-path-segment $context_id)} | format pattern "/rest/api/3/field/{field_id}/context/{context_id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add issue types to context
#
# PUT /rest/api/3/field/{fieldId}/context/{contextId}/issuetype
# operationId: addIssueTypesToContext
export def "rest-3-field-context-issuetype create-issue-types" [
  field_id: string
  context_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  issue_type_ids: list<string> # The list of issue type IDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), context_id: (encode-path-segment $context_id)} | format pattern "/rest/api/3/field/{field_id}/context/{context_id}/issuetype"))
  let req_body = {"issueTypeIds": $issue_type_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove issue types from context
#
# POST /rest/api/3/field/{fieldId}/context/{contextId}/issuetype/remove
# operationId: removeIssueTypesFromContext
export def "rest-3-field-context-issuetype-remove delete-issue-types" [
  field_id: string
  context_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  issue_type_ids: list<string> # The list of issue type IDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), context_id: (encode-path-segment $context_id)} | format pattern "/rest/api/3/field/{field_id}/context/{context_id}/issuetype/remove"))
  let req_body = {"issueTypeIds": $issue_type_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get custom field options (context)
#
# GET /rest/api/3/field/{fieldId}/context/{contextId}/option
# operationId: getOptionsForContext
export def "rest-3-field-context-option get" [
  field_id: string
  context_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --option-id: int # The ID of the option. (format: int64)
  --only-options: oneof<nothing, bool> # Whether only options are returned. (default: false)
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 100)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<disabled: bool, id: string, optionId: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "optionId" $option_id "scalar") (serialize-qp "onlyOptions" $only_options "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), context_id: (encode-path-segment $context_id)} | format pattern "/rest/api/3/field/{field_id}/context/{context_id}/option") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create custom field options (context)
#
# POST /rest/api/3/field/{fieldId}/context/{contextId}/option
# operationId: createCustomFieldOption
# --options item shape: {disabled?: bool, optionId?: string, value: string}
export def "rest-3-field-context-option create-custom" [
  field_id: string
  context_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --options: list # Details of options to create. — item shape: {disabled?: bool, optionId?: string, value: string}
]: any -> record<options: table<disabled: bool, id: string, optionId: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), context_id: (encode-path-segment $context_id)} | format pattern "/rest/api/3/field/{field_id}/context/{context_id}/option"))
  let req_body = {"options": $options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update custom field options (context)
#
# PUT /rest/api/3/field/{fieldId}/context/{contextId}/option
# operationId: updateCustomFieldOption
# --options item shape: {disabled?: bool, id: string, value?: string}
export def "rest-3-field-context-option update-custom" [
  field_id: string
  context_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --options: list # Details of the options to update. — item shape: {disabled?: bool, id: string, value?: string}
]: any -> record<options: table<disabled: bool, id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), context_id: (encode-path-segment $context_id)} | format pattern "/rest/api/3/field/{field_id}/context/{context_id}/option"))
  let req_body = {"options": $options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Reorder custom field options (context)
#
# PUT /rest/api/3/field/{fieldId}/context/{contextId}/option/move
# operationId: reorderCustomFieldOptions
export def "rest-3-field-context-option-move update-reorder-custom" [
  field_id: string
  context_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # The ID of the custom field option or cascading option to place the moved options after. Required if `position` isn't provided.
  custom_field_option_ids: list<string> # A list of IDs of custom field options to move. The order of the custom field option IDs in the list is the order they are given after the move. The list must contain custom field options or cascading options, but not both.
  --position: string@position-completer # The position the custom field options should be moved to. Required if `after` isn't provided.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), context_id: (encode-path-segment $context_id)} | format pattern "/rest/api/3/field/{field_id}/context/{context_id}/option/move"))
  let req_body = {"after": $after, "customFieldOptionIds": $custom_field_option_ids, "position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete custom field options (context)
#
# DELETE /rest/api/3/field/{fieldId}/context/{contextId}/option/{optionId}
# operationId: deleteCustomFieldOption
export def "rest-3-field-context-option delete-custom" [
  field_id: string
  context_id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), context_id: (encode-path-segment $context_id), option_id: (encode-path-segment $option_id)} | format pattern "/rest/api/3/field/{field_id}/context/{context_id}/option/{option_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign custom field context to projects
#
# PUT /rest/api/3/field/{fieldId}/context/{contextId}/project
# operationId: assignProjectsToCustomFieldContext
export def "rest-3-field-context-project assign-to-custom" [
  field_id: string
  context_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project_ids: list<string> # The IDs of projects.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), context_id: (encode-path-segment $context_id)} | format pattern "/rest/api/3/field/{field_id}/context/{context_id}/project"))
  let req_body = {"projectIds": $project_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove custom field context from projects
#
# POST /rest/api/3/field/{fieldId}/context/{contextId}/project/remove
# operationId: removeCustomFieldContextFromProjects
export def "rest-3-field-context-project-remove delete-custom" [
  field_id: string
  context_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project_ids: list<string> # The IDs of projects.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), context_id: (encode-path-segment $context_id)} | format pattern "/rest/api/3/field/{field_id}/context/{context_id}/project/remove"))
  let req_body = {"projectIds": $project_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get contexts for a field
#
# GET /rest/api/3/field/{fieldId}/contexts
# DEPRECATED
# operationId: getContextsForFieldDeprecated
@deprecated
export def "rest-3-field-contexts get-for-deprecated" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 20)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<id: int, name: string, scope: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/rest/api/3/field/{field_id}/contexts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get screens for a field
#
# GET /rest/api/3/field/{fieldId}/screens
# operationId: getScreensForField
export def "rest-3-field-screens get" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 100)
  --expand: string # Use [expand](#expansion) to include additional information about screens in the response. This parameter accepts `tab` which returns details about the screen tabs the field is used in.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, id: int, name: string, scope: record, tab: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/rest/api/3/field/{field_id}/screens") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all issue field options
#
# GET /rest/api/3/field/{fieldKey}/option
# operationId: getAllIssueFieldOptions
export def "rest-3-field-option get-list-issue" [
  field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<config: record, id: int, properties: record, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_key: (encode-path-segment $field_key)} | format pattern "/rest/api/3/field/{field_key}/option") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create issue field option
#
# POST /rest/api/3/field/{fieldKey}/option
# operationId: createIssueFieldOption
# --config shape: {attributes?: list<string>, scope?: any}
export def "rest-3-field-option create-issue" [
  field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record # Details of the projects the option is available in. — shape: {attributes?: list<string>, scope?: any}
  --properties: record # The properties of the option as arbitrary key-value pairs. These properties can be searched using JQL, if the extractions (see https://developer.atlassian.com/cloud/jira/platform/modules/issue-field-option-property-index/) are defined in the descriptor for the issue field module.
  value: string # The option's name, which is displayed in Jira.
]: any -> record<config: record<attributes: list<string>, scope: record<global: record, projects: list, projects2: list>>, id: int, properties: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_key: (encode-path-segment $field_key)} | format pattern "/rest/api/3/field/{field_key}/option"))
  let req_body = {"config": $config, "properties": $properties, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get selectable issue field options
#
# GET /rest/api/3/field/{fieldKey}/option/suggestions/edit
# operationId: getSelectableIssueFieldOptions
export def "rest-3-field-option-suggestions-edit get-selectable-issue" [
  field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --project-id: int # Filters the results to options that are only available in the specified project. (format: int64)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<config: record, id: int, properties: record, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_key: (encode-path-segment $field_key)} | format pattern "/rest/api/3/field/{field_key}/option/suggestions/edit") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get visible issue field options
#
# GET /rest/api/3/field/{fieldKey}/option/suggestions/search
# operationId: getVisibleIssueFieldOptions
export def "rest-3-field-option-suggestions-search get-visible-issue" [
  field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32)
  --project-id: int # Filters the results to options that are only available in the specified project. (format: int64)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<config: record, id: int, properties: record, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_key: (encode-path-segment $field_key)} | format pattern "/rest/api/3/field/{field_key}/option/suggestions/search") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete issue field option
#
# DELETE /rest/api/3/field/{fieldKey}/option/{optionId}
# operationId: deleteIssueFieldOption
export def "rest-3-field-option delete-issue" [
  field_key: string
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_key: (encode-path-segment $field_key), option_id: (encode-path-segment $option_id)} | format pattern "/rest/api/3/field/{field_key}/option/{option_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue field option
#
# GET /rest/api/3/field/{fieldKey}/option/{optionId}
# operationId: getIssueFieldOption
export def "rest-3-field-option get-issue" [
  field_key: string
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config: record<attributes: list<string>, scope: record<global: record, projects: list, projects2: list>>, id: int, properties: record, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_key: (encode-path-segment $field_key), option_id: (encode-path-segment $option_id)} | format pattern "/rest/api/3/field/{field_key}/option/{option_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update issue field option
#
# PUT /rest/api/3/field/{fieldKey}/option/{optionId}
# operationId: updateIssueFieldOption
# --config shape: {attributes?: list<string>, scope?: any}
export def "rest-3-field-option update-issue" [
  field_key: string
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record # Details of the projects the option is available in. — shape: {attributes?: list<string>, scope?: any}
  id: int # The unique identifier for the option. This is only unique within the select field's set of options. (format: int64)
  --properties: record # The properties of the object, as arbitrary key-value pairs. These properties can be searched using JQL, if the extractions (see [Issue Field Option Property Index](https://developer.atlassian.com/cloud/jira/platform/modules/issue-field-option-property-index/)) are defined in the descriptor for the issue field module.
  value: string # The option's name, which is displayed in Jira.
]: any -> record<config: record<attributes: list<string>, scope: record<global: record, projects: list, projects2: list>>, id: int, properties: record, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_key: (encode-path-segment $field_key), option_id: (encode-path-segment $option_id)} | format pattern "/rest/api/3/field/{field_key}/option/{option_id}"))
  let req_body = {"config": $config, "id": $id, "properties": $properties, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Replace issue field option
#
# DELETE /rest/api/3/field/{fieldKey}/option/{optionId}/issue
# operationId: replaceIssueFieldOption
export def "rest-3-field-option-issue update" [
  field_key: string
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --replace-with: int # The ID of the option that will replace the currently selected option. (format: int64)
  --jql: string # A JQL query that specifies the issues to be updated. For example, *project=10000*.
  --override-screen-security: oneof<nothing, bool> # Whether screen security is overridden to enable hidden fields to be edited. Available to Connect and Forge app users with admin permission. (default: false)
  --override-editable-flag: oneof<nothing, bool> # Whether screen security is overridden to enable uneditable fields to be edited. Available to Connect and Forge app users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replaceWith" $replace_with "scalar") (serialize-qp "jql" $jql "scalar") (serialize-qp "overrideScreenSecurity" $override_screen_security "scalar") (serialize-qp "overrideEditableFlag" $override_editable_flag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_key: (encode-path-segment $field_key), option_id: (encode-path-segment $option_id)} | format pattern "/rest/api/3/field/{field_key}/option/{option_id}/issue") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete custom field
#
# DELETE /rest/api/3/field/{id}
# operationId: deleteCustomField
export def "rest-3-field delete-custom" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/field/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restore custom field from trash
#
# POST /rest/api/3/field/{id}/restore
# operationId: restoreCustomField
export def "rest-3-field-restore create-custom" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/field/{id}/restore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move custom field to trash
#
# POST /rest/api/3/field/{id}/trash
# operationId: trashCustomField
export def "rest-3-field-trash create-custom" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/field/{id}/trash"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all field configurations
#
# GET /rest/api/3/fieldconfiguration
# operationId: getAllFieldConfigurations
export def "rest-3-fieldconfiguration get-list-field-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --id: list<int> # The list of field configuration IDs. To include multiple IDs, provide an ampersand-separated list. For example, `id=10000&id=10001`.
  --is-default: oneof<nothing, bool> # If *true* returns default field configurations only. (default: false)
  --query: string # The query string used to match against field configuration names and descriptions. (default: )
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "id" $id "multi") (serialize-qp "isDefault" $is_default "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/fieldconfiguration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create field configuration
#
# POST /rest/api/3/fieldconfiguration
# operationId: createFieldConfiguration
export def "rest-3-fieldconfiguration create-field-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the field configuration.
  name: string # The name of the field configuration. Must be unique.
]: any -> record<description: string, id: int, isDefault: bool, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/fieldconfiguration")
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete field configuration
#
# DELETE /rest/api/3/fieldconfiguration/{id}
# operationId: deleteFieldConfiguration
export def "rest-3-fieldconfiguration delete-field-configuration" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/fieldconfiguration/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update field configuration
#
# PUT /rest/api/3/fieldconfiguration/{id}
# operationId: updateFieldConfiguration
export def "rest-3-fieldconfiguration update-field-configuration" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the field configuration.
  name: string # The name of the field configuration. Must be unique.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/fieldconfiguration/{id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get field configuration items
#
# GET /rest/api/3/fieldconfiguration/{id}/fields
# operationId: getFieldConfigurationItems
export def "rest-3-fieldconfiguration-fields get-configuration-items" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, id: string, isHidden: bool, isRequired: bool, renderer: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/fieldconfiguration/{id}/fields") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update field configuration items
#
# PUT /rest/api/3/fieldconfiguration/{id}/fields
# operationId: updateFieldConfigurationItems
# --fieldConfigurationItems item shape: {description?: string, id: string, isHidden?: bool, isRequired?: bool, renderer?: string}
export def "rest-3-fieldconfiguration-fields update-configuration-items" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  field_configuration_items: list # Details of fields in a field configuration. — item shape: {description?: string, id: string, isHidden?: bool, isRequired?: bool, renderer?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/fieldconfiguration/{id}/fields"))
  let req_body = {"fieldConfigurationItems": $field_configuration_items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all field configuration schemes
#
# GET /rest/api/3/fieldconfigurationscheme
# operationId: getAllFieldConfigurationSchemes
export def "rest-3-fieldconfigurationscheme get-list-field-configuration-schemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --id: list<int> # The list of field configuration scheme IDs. To include multiple IDs, provide an ampersand-separated list. For example, `id=10000&id=10001`.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/fieldconfigurationscheme" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create field configuration scheme
#
# POST /rest/api/3/fieldconfigurationscheme
# operationId: createFieldConfigurationScheme
export def "rest-3-fieldconfigurationscheme create-field-configuration-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the field configuration scheme.
  name: string # The name of the field configuration scheme. The name must be unique.
]: any -> record<description: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/fieldconfigurationscheme")
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get field configuration issue type items
#
# GET /rest/api/3/fieldconfigurationscheme/mapping
# operationId: getFieldConfigurationSchemeMappings
export def "rest-3-fieldconfigurationscheme-mapping get-field-configuration-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --field-configuration-scheme-id: list<int> # The list of field configuration scheme IDs. To include multiple field configuration schemes separate IDs with ampersand: `fieldConfigurationSchemeId=10000&fieldConfigurationSchemeId=10001`.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<fieldConfigurationId: string, fieldConfigurationSchemeId: string, issueTypeId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "fieldConfigurationSchemeId" $field_configuration_scheme_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/fieldconfigurationscheme/mapping" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get field configuration schemes for projects
#
# GET /rest/api/3/fieldconfigurationscheme/project
# operationId: getFieldConfigurationSchemeProjectMapping
export def "rest-3-fieldconfigurationscheme-project get-field-configuration-scheme-mapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --project-id: list<int> # The list of project IDs. To include multiple projects, separate IDs with ampersand: `projectId=10000&projectId=10001`.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<fieldConfigurationScheme: record, projectIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "projectId" $project_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/fieldconfigurationscheme/project" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign field configuration scheme to project
#
# PUT /rest/api/3/fieldconfigurationscheme/project
# operationId: assignFieldConfigurationSchemeToProject
export def "rest-3-fieldconfigurationscheme-project assign-field-configuration-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-configuration-scheme-id: string # The ID of the field configuration scheme. If the field configuration scheme ID is `null`, the operation assigns the default field configuration scheme.
  project_id: string # The ID of the project.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/fieldconfigurationscheme/project")
  let req_body = {"fieldConfigurationSchemeId": $field_configuration_scheme_id, "projectId": $project_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete field configuration scheme
#
# DELETE /rest/api/3/fieldconfigurationscheme/{id}
# operationId: deleteFieldConfigurationScheme
export def "rest-3-fieldconfigurationscheme delete-field-configuration-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/fieldconfigurationscheme/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update field configuration scheme
#
# PUT /rest/api/3/fieldconfigurationscheme/{id}
# operationId: updateFieldConfigurationScheme
export def "rest-3-fieldconfigurationscheme update-field-configuration-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the field configuration scheme.
  name: string # The name of the field configuration scheme. The name must be unique.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/fieldconfigurationscheme/{id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Assign issue types to field configurations
#
# PUT /rest/api/3/fieldconfigurationscheme/{id}/mapping
# operationId: setFieldConfigurationSchemeMapping
# --mappings item shape: {fieldConfigurationId: string, issueTypeId: string}
export def "rest-3-fieldconfigurationscheme-mapping update-field-configuration-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  mappings: list # Field configuration to issue type mappings. — item shape: {fieldConfigurationId: string, issueTypeId: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/fieldconfigurationscheme/{id}/mapping"))
  let req_body = {"mappings": $mappings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove issue types from field configuration scheme
#
# POST /rest/api/3/fieldconfigurationscheme/{id}/mapping/delete
# operationId: removeIssueTypesFromGlobalFieldConfigurationScheme
export def "rest-3-fieldconfigurationscheme-mapping-delete delete-issue-types-from-global-field-configuration-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  issue_type_ids: list<string> # The list of issue type IDs. Must contain unique values not longer than 255 characters and not be empty. Maximum of 100 IDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/fieldconfigurationscheme/{id}/mapping/delete"))
  let req_body = {"issueTypeIds": $issue_type_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get filters
#
# GET /rest/api/3/filter
# DEPRECATED
# operationId: getFilters
@deprecated
export def "rest-3-filter list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about filter in the response. This parameter accepts a comma-separated list. Expand options include: * `sharedUsers` Returns the users that the filter is shared with. This includes users that can browse projects that the filter is shared with. If you don't specify `sharedUsers`, then the `sharedUsers` object is returned but it doesn't list any users. The list of users returned is limited to 1000, to access additional users append `[start-index:end-index]` to the expand request. For example, to access the next 1000 users, use `?expand=sharedUsers[1001:2000]`. * `subscriptions` Returns the users that are subscribed to the filter. If you don't specify `subscriptions`, the `subscriptions` object is returned but it doesn't list any subscriptions. The list of subscriptions returned is limited to 1000, to access additional subscriptions append `[start-index:end-index]` to the expand request. For example, to access the next 1000 subscriptions, use `?expand=subscriptions[1001:2000]`.
]: nothing -> table<description: string, editPermissions: list<record>, favourite: bool, favouritedCount: int, id: string, jql: string, name: string, owner: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, searchUrl: string, self: string, sharePermissions: list<record>, sharedUsers: record<end_index: int, items: list, max_results: int, size: int, start_index: int>, subscriptions: record<end_index: int, items: list, max_results: int, size: int, start_index: int>, viewUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/filter" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create filter
#
# POST /rest/api/3/filter
# operationId: createFilter
# --editPermissions item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
# --sharePermissions item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
export def "rest-3-filter create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about filter in the response. This parameter accepts a comma-separated list. Expand options include: * `sharedUsers` Returns the users that the filter is shared with. This includes users that can browse projects that the filter is shared with. If you don't specify `sharedUsers`, then the `sharedUsers` object is returned but it doesn't list any users. The list of users returned is limited to 1000, to access additional users append `[start-index:end-index]` to the expand request. For example, to access the next 1000 users, use `?expand=sharedUsers[1001:2000]`. * `subscriptions` Returns the users that are subscribed to the filter. If you don't specify `subscriptions`, the `subscriptions` object is returned but it doesn't list any subscriptions. The list of subscriptions returned is limited to 1000, to access additional subscriptions append `[start-index:end-index]` to the expand request. For example, to access the next 1000 subscriptions, use `?expand=subscriptions[1001:2000]`.
  --override-share-permissions: oneof<nothing, bool> # EXPERIMENTAL: Whether share permissions are overridden to enable filters with any share permissions to be created. Available to users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). (default: false)
  --description: string # A description of the filter.
  --edit-permissions: list # The groups and projects that can edit the filter. — item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
  --favourite: oneof<nothing, bool> # Whether the filter is selected as a favorite.
  --jql: string # The JQL query for the filter. For example, *project = SSP AND issuetype = Bug*.
  name: string # The name of the filter. Must be unique.
  --share-permissions: list # The groups and projects that the filter is shared with. — item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
]: any -> record<description: string, editPermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, favourite: bool, favouritedCount: int, id: string, jql: string, name: string, owner: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, searchUrl: string, self: string, sharePermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, sharedUsers: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>, subscriptions: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>, viewUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "overrideSharePermissions" $override_share_permissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/filter" $qp)
  let req_body = {"description": $description, "editPermissions": $edit_permissions, "favourite": $favourite, "jql": $jql, "name": $name, "sharePermissions": $share_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get default share scope
#
# GET /rest/api/3/filter/defaultShareScope
# operationId: getDefaultShareScope
export def "rest-3-filter-default-share-scope get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/filter/defaultShareScope")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set default share scope
#
# PUT /rest/api/3/filter/defaultShareScope
# operationId: setDefaultShareScope
export def "rest-3-filter-default-share-scope update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  scope: string@scope-completer # The scope of the default sharing for new filters and dashboards: * `AUTHENTICATED` Shared with all logged-in users. * `GLOBAL` Shared with all logged-in users. This shows as `AUTHENTICATED` in the response. * `PRIVATE` Not shared with any users.
]: any -> record<scope: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/filter/defaultShareScope")
  let req_body = {"scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get favorite filters
#
# GET /rest/api/3/filter/favourite
# operationId: getFavouriteFilters
export def "rest-3-filter-favourite get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about filter in the response. This parameter accepts a comma-separated list. Expand options include: * `sharedUsers` Returns the users that the filter is shared with. This includes users that can browse projects that the filter is shared with. If you don't specify `sharedUsers`, then the `sharedUsers` object is returned but it doesn't list any users. The list of users returned is limited to 1000, to access additional users append `[start-index:end-index]` to the expand request. For example, to access the next 1000 users, use `?expand=sharedUsers[1001:2000]`. * `subscriptions` Returns the users that are subscribed to the filter. If you don't specify `subscriptions`, the `subscriptions` object is returned but it doesn't list any subscriptions. The list of subscriptions returned is limited to 1000, to access additional subscriptions append `[start-index:end-index]` to the expand request. For example, to access the next 1000 subscriptions, use `?expand=subscriptions[1001:2000]`.
]: nothing -> table<description: string, editPermissions: list<record>, favourite: bool, favouritedCount: int, id: string, jql: string, name: string, owner: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, searchUrl: string, self: string, sharePermissions: list<record>, sharedUsers: record<end_index: int, items: list, max_results: int, size: int, start_index: int>, subscriptions: record<end_index: int, items: list, max_results: int, size: int, start_index: int>, viewUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/filter/favourite" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get my filters
#
# GET /rest/api/3/filter/my
# operationId: getMyFilters
export def "rest-3-filter-my get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about filter in the response. This parameter accepts a comma-separated list. Expand options include: * `sharedUsers` Returns the users that the filter is shared with. This includes users that can browse projects that the filter is shared with. If you don't specify `sharedUsers`, then the `sharedUsers` object is returned but it doesn't list any users. The list of users returned is limited to 1000, to access additional users append `[start-index:end-index]` to the expand request. For example, to access the next 1000 users, use `?expand=sharedUsers[1001:2000]`. * `subscriptions` Returns the users that are subscribed to the filter. If you don't specify `subscriptions`, the `subscriptions` object is returned but it doesn't list any subscriptions. The list of subscriptions returned is limited to 1000, to access additional subscriptions append `[start-index:end-index]` to the expand request. For example, to access the next 1000 subscriptions, use `?expand=subscriptions[1001:2000]`.
  --include-favourites: oneof<nothing, bool> # Include the user's favorite filters in the response. (default: false)
]: nothing -> table<description: string, editPermissions: list<record>, favourite: bool, favouritedCount: int, id: string, jql: string, name: string, owner: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, searchUrl: string, self: string, sharePermissions: list<record>, sharedUsers: record<end_index: int, items: list, max_results: int, size: int, start_index: int>, subscriptions: record<end_index: int, items: list, max_results: int, size: int, start_index: int>, viewUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "includeFavourites" $include_favourites "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/filter/my" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for filters
#
# GET /rest/api/3/filter/search
# operationId: getFiltersPaginated
export def "rest-3-filter-search get-paginated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-name: string # String used to perform a case-insensitive partial match with `name`.
  --account-id: string # User account ID used to return filters with the matching `owner.accountId`. This parameter cannot be used with `owner`.
  --owner: string # This parameter is deprecated because of privacy changes. Use `accountId` instead. See the [migration guide](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details. User name used to return filters with the matching `owner.name`. This parameter cannot be used with `accountId`.
  --groupname: string # As a group's name can change, use of `groupId` is recommended to identify a group. Group name used to returns filters that are shared with a group that matches `sharePermissions.group.groupname`. This parameter cannot be used with the `groupId` parameter.
  --group-id: string # Group ID used to returns filters that are shared with a group that matches `sharePermissions.group.groupId`. This parameter cannot be used with the `groupname` parameter.
  --project-id: int # Project ID used to returns filters that are shared with a project that matches `sharePermissions.project.id`. (format: int64)
  --id: list<int> # The list of filter IDs. To include multiple IDs, provide an ampersand-separated list. For example, `id=10000&id=10001`. Do not exceed 200 filter IDs.
  --order-by: string@order-by-completer-2 # [Order](#ordering) the results by a field: * `description` Sorts by filter description. Note that this sorting works independently of whether the expand to display the description field is in use. * `favourite_count` Sorts by the count of how many users have this filter as a favorite. * `is_favourite` Sorts by whether the filter is marked as a favorite. * `id` Sorts by filter ID. * `name` Sorts by filter name. * `owner` Sorts by the ID of the filter owner. * `is_shared` Sorts by whether the filter is shared. (default: name)
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --expand: string # Use [expand](#expansion) to include additional information about filter in the response. This parameter accepts a comma-separated list. Expand options include: * `description` Returns the description of the filter. * `favourite` Returns an indicator of whether the user has set the filter as a favorite. * `favouritedCount` Returns a count of how many users have set this filter as a favorite. * `jql` Returns the JQL query that the filter uses. * `owner` Returns the owner of the filter. * `searchUrl` Returns a URL to perform the filter's JQL query. * `sharePermissions` Returns the share permissions defined for the filter. * `editPermissions` Returns the edit permissions defined for the filter. * `isWritable` Returns whether the current user has permission to edit the filter. * `subscriptions` Returns the users that are subscribed to the filter. * `viewUrl` Returns a URL to view the filter.
  --override-share-permissions: oneof<nothing, bool> # EXPERIMENTAL: Whether share permissions are overridden to enable filters with any share permissions to be returned. Available to users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). (default: false)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, editPermissions: list, expand: string, favourite: bool, favouritedCount: int, id: string, jql: string, name: string, owner: record, searchUrl: string, self: string, sharePermissions: list, subscriptions: list, viewUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterName" $filter_name "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "groupname" $groupname "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "id" $id "multi") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "overrideSharePermissions" $override_share_permissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/filter/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete filter
#
# DELETE /rest/api/3/filter/{id}
# operationId: deleteFilter
export def "rest-3-filter delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/filter/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get filter
#
# GET /rest/api/3/filter/{id}
# operationId: getFilter
export def "rest-3-filter get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about filter in the response. This parameter accepts a comma-separated list. Expand options include: * `sharedUsers` Returns the users that the filter is shared with. This includes users that can browse projects that the filter is shared with. If you don't specify `sharedUsers`, then the `sharedUsers` object is returned but it doesn't list any users. The list of users returned is limited to 1000, to access additional users append `[start-index:end-index]` to the expand request. For example, to access the next 1000 users, use `?expand=sharedUsers[1001:2000]`. * `subscriptions` Returns the users that are subscribed to the filter. If you don't specify `subscriptions`, the `subscriptions` object is returned but it doesn't list any subscriptions. The list of subscriptions returned is limited to 1000, to access additional subscriptions append `[start-index:end-index]` to the expand request. For example, to access the next 1000 subscriptions, use `?expand=subscriptions[1001:2000]`.
  --override-share-permissions: oneof<nothing, bool> # EXPERIMENTAL: Whether share permissions are overridden to enable filters with any share permissions to be returned. Available to users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). (default: false)
]: nothing -> record<description: string, editPermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, favourite: bool, favouritedCount: int, id: string, jql: string, name: string, owner: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, searchUrl: string, self: string, sharePermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, sharedUsers: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>, subscriptions: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>, viewUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "overrideSharePermissions" $override_share_permissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/filter/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update filter
#
# PUT /rest/api/3/filter/{id}
# operationId: updateFilter
# --editPermissions item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
# --sharePermissions item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
export def "rest-3-filter update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about filter in the response. This parameter accepts a comma-separated list. Expand options include: * `sharedUsers` Returns the users that the filter is shared with. This includes users that can browse projects that the filter is shared with. If you don't specify `sharedUsers`, then the `sharedUsers` object is returned but it doesn't list any users. The list of users returned is limited to 1000, to access additional users append `[start-index:end-index]` to the expand request. For example, to access the next 1000 users, use `?expand=sharedUsers[1001:2000]`. * `subscriptions` Returns the users that are subscribed to the filter. If you don't specify `subscriptions`, the `subscriptions` object is returned but it doesn't list any subscriptions. The list of subscriptions returned is limited to 1000, to access additional subscriptions append `[start-index:end-index]` to the expand request. For example, to access the next 1000 subscriptions, use `?expand=subscriptions[1001:2000]`.
  --override-share-permissions: oneof<nothing, bool> # EXPERIMENTAL: Whether share permissions are overridden to enable the addition of any share permissions to filters. Available to users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). (default: false)
  --description: string # A description of the filter.
  --edit-permissions: list # The groups and projects that can edit the filter. — item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
  --favourite: oneof<nothing, bool> # Whether the filter is selected as a favorite.
  --jql: string # The JQL query for the filter. For example, *project = SSP AND issuetype = Bug*.
  name: string # The name of the filter. Must be unique.
  --share-permissions: list # The groups and projects that the filter is shared with. — item shape: {group?: any, project?: any, role?: any, type: "user"|"group"|"project"|"projectRole"|"global"|"loggedin"|"authenticated"|"project-unknown", user?: any}
]: any -> record<description: string, editPermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, favourite: bool, favouritedCount: int, id: string, jql: string, name: string, owner: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, searchUrl: string, self: string, sharePermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, sharedUsers: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>, subscriptions: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>, viewUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "overrideSharePermissions" $override_share_permissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/filter/{id}") $qp)
  let req_body = {"description": $description, "editPermissions": $edit_permissions, "favourite": $favourite, "jql": $jql, "name": $name, "sharePermissions": $share_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Reset columns
#
# DELETE /rest/api/3/filter/{id}/columns
# operationId: resetColumns
export def "rest-3-filter-columns reset" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/filter/{id}/columns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get columns
#
# GET /rest/api/3/filter/{id}/columns
# operationId: getColumns
export def "rest-3-filter-columns get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<label: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/filter/{id}/columns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set columns
#
# PUT /rest/api/3/filter/{id}/columns
# operationId: setColumns
export def "rest-3-filter-columns update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/filter/{id}/columns"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $req_body
}

# Remove filter as favorite
#
# DELETE /rest/api/3/filter/{id}/favourite
# operationId: deleteFavouriteForFilter
export def "rest-3-filter-favourite delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about filter in the response. This parameter accepts a comma-separated list. Expand options include: * `sharedUsers` Returns the users that the filter is shared with. This includes users that can browse projects that the filter is shared with. If you don't specify `sharedUsers`, then the `sharedUsers` object is returned but it doesn't list any users. The list of users returned is limited to 1000, to access additional users append `[start-index:end-index]` to the expand request. For example, to access the next 1000 users, use `?expand=sharedUsers[1001:2000]`. * `subscriptions` Returns the users that are subscribed to the filter. If you don't specify `subscriptions`, the `subscriptions` object is returned but it doesn't list any subscriptions. The list of subscriptions returned is limited to 1000, to access additional subscriptions append `[start-index:end-index]` to the expand request. For example, to access the next 1000 subscriptions, use `?expand=subscriptions[1001:2000]`.
]: nothing -> record<description: string, editPermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, favourite: bool, favouritedCount: int, id: string, jql: string, name: string, owner: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, searchUrl: string, self: string, sharePermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, sharedUsers: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>, subscriptions: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>, viewUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/filter/{id}/favourite") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add filter as favorite
#
# PUT /rest/api/3/filter/{id}/favourite
# operationId: setFavouriteForFilter
export def "rest-3-filter-favourite update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about filter in the response. This parameter accepts a comma-separated list. Expand options include: * `sharedUsers` Returns the users that the filter is shared with. This includes users that can browse projects that the filter is shared with. If you don't specify `sharedUsers`, then the `sharedUsers` object is returned but it doesn't list any users. The list of users returned is limited to 1000, to access additional users append `[start-index:end-index]` to the expand request. For example, to access the next 1000 users, use `?expand=sharedUsers[1001:2000]`. * `subscriptions` Returns the users that are subscribed to the filter. If you don't specify `subscriptions`, the `subscriptions` object is returned but it doesn't list any subscriptions. The list of subscriptions returned is limited to 1000, to access additional subscriptions append `[start-index:end-index]` to the expand request. For example, to access the next 1000 subscriptions, use `?expand=subscriptions[1001:2000]`.
]: nothing -> record<description: string, editPermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, favourite: bool, favouritedCount: int, id: string, jql: string, name: string, owner: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, searchUrl: string, self: string, sharePermissions: table<group: record, id: int, project: record, role: record, type: string, user: record>, sharedUsers: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>, subscriptions: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>, viewUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/filter/{id}/favourite") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change filter owner
#
# PUT /rest/api/3/filter/{id}/owner
# operationId: changeFilterOwner
export def "rest-3-filter-owner update-change" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The account ID of the new owner.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/filter/{id}/owner"))
  let req_body = {"accountId": $account_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get share permissions
#
# GET /rest/api/3/filter/{id}/permission
# operationId: getSharePermissions
export def "rest-3-filter-permission list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<group: record<groupId: string, name: string, self: string>, id: int, project: record<archived: bool, archivedBy: record, archivedDate: string, assigneeType: string, avatarUrls: record, components: list, deleted: bool, deletedBy: record, deletedDate: string, description: string, email: string, expand: string, favourite: bool, id: string, insight: record, isPrivate: bool, issueTypeHierarchy: record, issueTypes: list, key: string, landingPageInfo: record, lead: record, name: string, permissions: record, projectCategory: record, projectTypeKey: string, properties: record, retentionTillDate: string, roles: record, self: string, simplified: bool, style: string, url: string, uuid: string, versions: list>, role: record<actors: list, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record, self: string, translatedName: string>, type: string, user: record<accountId: string, active: bool, avatarUrls: record, displayName: string, key: string, name: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/filter/{id}/permission"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add share permission
#
# POST /rest/api/3/filter/{id}/permission
# operationId: addSharePermission
export def "rest-3-filter-permission create-share" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The user account ID that the filter is shared with. For a request, specify the `accountId` property for the user.
  --group-id: string # The ID of the group, which uniquely identifies the group across all Atlassian products.For example, *952d12c3-5b5b-4d04-bb32-44d383afc4b2*. Cannot be provided with `groupname`.
  --groupname: string # The name of the group to share the filter with. Set `type` to `group`. Please note that the name of a group is mutable, to reliably identify a group use `groupId`.
  --project-id: string # The ID of the project to share the filter with. Set `type` to `project`.
  --project-role-id: string # The ID of the project role to share the filter with. Set `type` to `projectRole` and the `projectId` for the project that the role is in.
  --rights: int # The rights for the share permission. (format: int32)
  type: string@type-completer # The type of the share permission.Specify the type as follows: * `user` Share with a user. * `group` Share with a group. Specify `groupname` as well. * `project` Share with a project. Specify `projectId` as well. * `projectRole` Share with a project role in a project. Specify `projectId` and `projectRoleId` as well. * `global` Share globally, including anonymous users. If set, this type overrides all existing share permissions and must be deleted before any non-global share permissions is set. * `authenticated` Share with all logged-in users. This shows as `loggedin` in the response. If set, this type overrides all existing share permissions and must be deleted before any non-global share permissions is set.
]: any -> table<group: record<groupId: string, name: string, self: string>, id: int, project: record<archived: bool, archivedBy: record, archivedDate: string, assigneeType: string, avatarUrls: record, components: list, deleted: bool, deletedBy: record, deletedDate: string, description: string, email: string, expand: string, favourite: bool, id: string, insight: record, isPrivate: bool, issueTypeHierarchy: record, issueTypes: list, key: string, landingPageInfo: record, lead: record, name: string, permissions: record, projectCategory: record, projectTypeKey: string, properties: record, retentionTillDate: string, roles: record, self: string, simplified: bool, style: string, url: string, uuid: string, versions: list>, role: record<actors: list, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record, self: string, translatedName: string>, type: string, user: record<accountId: string, active: bool, avatarUrls: record, displayName: string, key: string, name: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/filter/{id}/permission"))
  let req_body = {"accountId": $account_id, "groupId": $group_id, "groupname": $groupname, "projectId": $project_id, "projectRoleId": $project_role_id, "rights": $rights, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete share permission
#
# DELETE /rest/api/3/filter/{id}/permission/{permissionId}
# operationId: deleteSharePermission
export def "rest-3-filter-permission delete-share" [
  id: int
  permission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), permission_id: (encode-path-segment $permission_id)} | format pattern "/rest/api/3/filter/{id}/permission/{permission_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get share permission
#
# GET /rest/api/3/filter/{id}/permission/{permissionId}
# operationId: getSharePermission
export def "rest-3-filter-permission get-share" [
  id: int
  permission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<group: record<groupId: string, name: string, self: string>, id: int, project: record<archived: bool, archivedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, archivedDate: string, assigneeType: string, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, components: list<record>, deleted: bool, deletedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, deletedDate: string, description: string, email: string, expand: string, favourite: bool, id: string, insight: record<lastIssueUpdateTime: string, totalIssueCount: int>, isPrivate: bool, issueTypeHierarchy: record<baseLevelId: int, levels: list>, issueTypes: list<record>, key: string, landingPageInfo: record<attributes: record, boardId: int, boardName: string, projectKey: string, projectType: string, queueCategory: string, queueId: int, queueName: string, simpleBoard: bool, simplified: bool, url: string>, lead: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, permissions: record<canEdit: bool>, projectCategory: record<description: string, id: string, name: string, self: string>, projectTypeKey: string, properties: record, retentionTillDate: string, roles: record, self: string, simplified: bool, style: string, url: string, uuid: string, versions: list<record>>, role: record<actors: list<record>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record, type: string>, self: string, translatedName: string>, type: string, user: record<accountId: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, key: string, name: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), permission_id: (encode-path-segment $permission_id)} | format pattern "/rest/api/3/filter/{id}/permission/{permission_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove group
#
# DELETE /rest/api/3/group
# operationId: removeGroup
export def "rest-3-group delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupname: string
  --group-id: string # The ID of the group. This parameter cannot be used with the `groupname` parameter.
  --swap-group: string # As a group's name can change, use of `swapGroupId` is recommended to identify a group. The group to transfer restrictions to. Only comments and worklogs are transferred. If restrictions are not transferred, comments and worklogs are inaccessible after the deletion. This parameter cannot be used with the `swapGroupId` parameter.
  --swap-group-id: string # The ID of the group to transfer restrictions to. Only comments and worklogs are transferred. If restrictions are not transferred, comments and worklogs are inaccessible after the deletion. This parameter cannot be used with the `swapGroup` parameter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupname" $groupname "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "swapGroup" $swap_group "scalar") (serialize-qp "swapGroupId" $swap_group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group
#
# GET /rest/api/3/group
# DEPRECATED
# operationId: getGroup
@deprecated
export def "rest-3-group get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupname: string # As a group's name can change, use of `groupId` is recommended to identify a group. The name of the group. This parameter cannot be used with the `groupId` parameter.
  --group-id: string # The ID of the group. This parameter cannot be used with the `groupName` parameter.
  --expand: string # List of fields to expand.
]: nothing -> record<expand: string, groupId: string, name: string, self: string, users: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupname" $groupname "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create group
#
# POST /rest/api/3/group
# operationId: createGroup
export def "rest-3-group create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the group.
]: any -> record<expand: string, groupId: string, name: string, self: string, users: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/group")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk get groups
#
# GET /rest/api/3/group/bulk
# operationId: bulkGetGroups
export def "rest-3-group-bulk get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --group-id: list<string> # The ID of a group. To specify multiple IDs, pass multiple `groupId` parameters. For example, `groupId=5b10a2844c20165700ede21g&groupId=5b10ac8d82e05b22cc7d4ef5`. (e.g. 3571b9a7-348f-414a-9087-8e1ea03a7df8)
  --group-name: list<string> # The name of a group. To specify multiple names, pass multiple `groupName` parameters. For example, `groupName=administrators&groupName=jira-software-users`.
  --access-type: string # The access level of a group. Valid values: 'site-admin', 'admin', 'user'.
  --application-key: string # The application key of the product user groups to search for. Valid values: 'jira-servicedesk', 'jira-software', 'jira-product-discovery', 'jira-core'.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<groupId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "groupId" $group_id "multi") (serialize-qp "groupName" $group_name "multi") (serialize-qp "accessType" $access_type "scalar") (serialize-qp "applicationKey" $application_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/group/bulk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users from group
#
# GET /rest/api/3/group/member
# operationId: getUsersFromGroup
export def "rest-3-group-member get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupname: string # As a group's name can change, use of `groupId` is recommended to identify a group. The name of the group. This parameter cannot be used with the `groupId` parameter.
  --group-id: string # The ID of the group. This parameter cannot be used with the `groupName` parameter.
  --include-inactive-users: oneof<nothing, bool> # Include inactive users. (default: false)
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<accountId: string, accountType: string, active: bool, avatarUrls: record, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupname" $groupname "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "includeInactiveUsers" $include_inactive_users "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/group/member" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove user from group
#
# DELETE /rest/api/3/group/user
# operationId: removeUserFromGroup
export def "rest-3-group-user delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupname: string # As a group's name can change, use of `groupId` is recommended to identify a group. The name of the group. This parameter cannot be used with the `groupId` parameter.
  --group-id: string # The ID of the group. This parameter cannot be used with the `groupName` parameter.
  --username: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. (e.g. 5b10ac8d82e05b22cc7d4ef5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupname" $groupname "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/group/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add user to group
#
# POST /rest/api/3/group/user
# operationId: addUserToGroup
export def "rest-3-group-user create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupname: string # As a group's name can change, use of `groupId` is recommended to identify a group. The name of the group. This parameter cannot be used with the `groupId` parameter.
  --group-id: string # The ID of the group. This parameter cannot be used with the `groupName` parameter.
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*.
  --name: string # This property is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
]: any -> record<expand: string, groupId: string, name: string, self: string, users: record<end_index: int, items: list<record>, max_results: int, size: int, start_index: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupname" $groupname "scalar") (serialize-qp "groupId" $group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/group/user" $qp)
  let req_body = {"accountId": $account_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Find groups
#
# GET /rest/api/3/groups/picker
# operationId: findGroups
export def "rest-3-groups-picker find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # This parameter is deprecated, setting it does not affect the results. To find groups containing a particular user, use [Get user groups](#api-rest-api-3-user-groups-get).
  --query: string # The string to find in group names. (e.g. query)
  --exclude: list<string> # As a group's name can change, use of `excludeGroupIds` is recommended to identify a group. A group to exclude from the result. To exclude multiple groups, provide an ampersand-separated list. For example, `exclude=group1&exclude=group2`. This parameter cannot be used with the `excludeGroupIds` parameter.
  --exclude-id: list<string> # A group ID to exclude from the result. To exclude multiple groups, provide an ampersand-separated list. For example, `excludeId=group1-id&excludeId=group2-id`. This parameter cannot be used with the `excludeGroups` parameter.
  --max-results: int # The maximum number of groups to return. The maximum number of groups that can be returned is limited by the system property `jira.ajax.autocomplete.limit`. (format: int32)
  --case-insensitive: oneof<nothing, bool> # Whether the search for groups should be case insensitive. (default: false)
  --user-name: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
]: nothing -> record<groups: table<groupId: string, html: string, labels: list, name: string>, header: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "exclude" $exclude "multi") (serialize-qp "excludeId" $exclude_id "multi") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "caseInsensitive" $case_insensitive "scalar") (serialize-qp "userName" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/groups/picker" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find users and groups
#
# GET /rest/api/3/groupuserpicker
# operationId: findUsersAndGroups
export def "rest-3-groupuserpicker find-users-and-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The search string.
  --max-results: int # The maximum number of items to return in each list. (format: int32, default: 50)
  --show-avatar: oneof<nothing, bool> # Whether the user avatar should be returned. If an invalid value is provided, the default value is used. (default: false)
  --field-id: string # The custom field ID of the field this request is for.
  --project-id: list<string> # The ID of a project that returned users and groups must have permission to view. To include multiple projects, provide an ampersand-separated list. For example, `projectId=10000&projectId=10001`. This parameter is only used when `fieldId` is present.
  --issue-type-id: list<string> # The ID of an issue type that returned users and groups must have permission to view. To include multiple issue types, provide an ampersand-separated list. For example, `issueTypeId=10000&issueTypeId=10001`. Special values, such as `-1` (all standard issue types) and `-2` (all subtask issue types), are supported. This parameter is only used when `fieldId` is present.
  --avatar-size: string@avatar-size-completer # The size of the avatar to return. If an invalid value is provided, the default value is used. (default: xsmall)
  --case-insensitive: oneof<nothing, bool> # Whether the search for groups should be case insensitive. (default: false)
  --exclude-connect-addons: oneof<nothing, bool> # Whether Connect app users and groups should be excluded from the search results. If an invalid value is provided, the default value is used. (default: false)
]: nothing -> record<groups: record<groups: list<record>, header: string, total: int>, users: record<header: string, total: int, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "showAvatar" $show_avatar "scalar") (serialize-qp "fieldId" $field_id "scalar") (serialize-qp "projectId" $project_id "multi") (serialize-qp "issueTypeId" $issue_type_id "multi") (serialize-qp "avatarSize" $avatar_size "scalar") (serialize-qp "caseInsensitive" $case_insensitive "scalar") (serialize-qp "excludeConnectAddons" $exclude_connect_addons "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/groupuserpicker" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get license
#
# GET /rest/api/3/instance/license
# operationId: getLicense
export def "rest-3-instance-license get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<applications: table<id: string, plan: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/instance/license")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create issue
#
# POST /rest/api/3/issue
# operationId: createIssue
# --properties item shape: {key?: string, value?: any}
export def "rest-3-issue create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-history: oneof<nothing, bool> # Whether the project in which the issue is created is added to the user's **Recently viewed** project list, as shown under **Projects** in Jira. When provided, the issue type and request type are added to the user's history for a project. These values are then used to provide defaults on the issue create screen. (default: false)
  --fields: record # List of issue screen fields to update, specifying the sub-field to update and its value for each field. This field provides a straightforward option when setting a sub-field. When multiple sub-fields or other operations are required, use `update`. Fields included in here cannot be included in `update`.
  --history-metadata: any # Additional issue history details.
  --properties: list # Details of issue properties to be add or update. — item shape: {key?: string, value?: any}
  --transition: any # Details of a transition. Required when performing a transition, optional when creating or editing an issue.
  --update: record # A Map containing the field field name and a list of operations to perform on the issue screen field. Note that fields included in here cannot be included in `fields`.
]: any -> record<id: string, key: string, self: string, transition: record<errorCollection: record<errorMessages: list, errors: record, status: int>, status: int, warningCollection: record<warnings: list>>, watchers: record<errorCollection: record<errorMessages: list, errors: record, status: int>, status: int, warningCollection: record<warnings: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateHistory" $update_history "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/issue" $qp)
  let req_body = {"fields": $fields, "historyMetadata": $history_metadata, "properties": $properties, "transition": $transition, "update": $update} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk create issue
#
# POST /rest/api/3/issue/bulk
# operationId: createIssues
# --issueUpdates item shape: {fields?: record, historyMetadata?: any, properties?: list, transition?: any, update?: record}
export def "rest-3-issue-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --issue-updates: list # item shape: {fields?: record, historyMetadata?: any, properties?: list, transition?: any, update?: record}
]: any -> record<errors: table<elementErrors: record, failedElementNumber: int, status: int>, issues: table<id: string, key: string, self: string, transition: record, watchers: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issue/bulk")
  let req_body = {"issueUpdates": $issue_updates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get create issue metadata
#
# GET /rest/api/3/issue/createmeta
# operationId: getCreateIssueMeta
export def "rest-3-issue-createmeta get-create-meta" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-ids: list<string> # List of project IDs. This parameter accepts a comma-separated list. Multiple project IDs can also be provided using an ampersand-separated list. For example, `projectIds=10000,10001&projectIds=10020,10021`. This parameter may be provided with `projectKeys`.
  --project-keys: list<string> # List of project keys. This parameter accepts a comma-separated list. Multiple project keys can also be provided using an ampersand-separated list. For example, `projectKeys=proj1,proj2&projectKeys=proj3`. This parameter may be provided with `projectIds`.
  --issuetype-ids: list<string> # List of issue type IDs. This parameter accepts a comma-separated list. Multiple issue type IDs can also be provided using an ampersand-separated list. For example, `issuetypeIds=10000,10001&issuetypeIds=10020,10021`. This parameter may be provided with `issuetypeNames`.
  --issuetype-names: list<string> # List of issue type names. This parameter accepts a comma-separated list. Multiple issue type names can also be provided using an ampersand-separated list. For example, `issuetypeNames=name1,name2&issuetypeNames=name3`. This parameter may be provided with `issuetypeIds`.
  --expand: string # Use [expand](#expansion) to include additional information about issue metadata in the response. This parameter accepts `projects.issuetypes.fields`, which returns information about the fields in the issue creation screen for each issue type. Fields hidden from the screen are not returned. Use the information to populate the `fields` and `update` fields in [Create issue](#api-rest-api-3-issue-post) and [Create issues](#api-rest-api-3-issue-bulk-post).
]: nothing -> record<expand: string, projects: table<avatarUrls: record, expand: string, id: string, issuetypes: list, key: string, name: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectIds" $project_ids "multi") (serialize-qp "projectKeys" $project_keys "multi") (serialize-qp "issuetypeIds" $issuetype_ids "multi") (serialize-qp "issuetypeNames" $issuetype_names "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/issue/createmeta" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue picker suggestions
#
# GET /rest/api/3/issue/picker
# operationId: getIssuePickerResource
export def "rest-3-issue-picker get-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A string to match against text fields in the issue such as title, description, or comments. (e.g. query)
  --current-jql: string # A JQL query defining a list of issues to search for the query term. Note that `username` and `userkey` cannot be used as search terms for this parameter, due to privacy reasons. Use `accountId` instead.
  --current-issue-key: string # The key of an issue to exclude from search results. For example, the issue the user is viewing when they perform this query.
  --current-project-id: string # The ID of a project that suggested issues must belong to.
  --show-sub-tasks: oneof<nothing, bool> # Indicate whether to include subtasks in the suggestions list.
  --show-sub-task-parent: oneof<nothing, bool> # When `currentIssueKey` is a subtask, whether to include the parent issue in the suggestions if it matches the query.
]: nothing -> record<sections: table<id: string, issues: list, label: string, msg: string, sub: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "currentJQL" $current_jql "scalar") (serialize-qp "currentIssueKey" $current_issue_key "scalar") (serialize-qp "currentProjectId" $current_project_id "scalar") (serialize-qp "showSubTasks" $show_sub_tasks "scalar") (serialize-qp "showSubTaskParent" $show_sub_task_parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/issue/picker" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk set issues properties by list
#
# POST /rest/api/3/issue/properties
# operationId: bulkSetIssuesPropertiesList
export def "rest-3-issue-properties update-bulk-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities-ids: list<int> # A list of entity property IDs.
  --properties: record # A list of entity property keys and values.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issue/properties")
  let req_body = {"entitiesIds": $entities_ids, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk set issue properties by issue
#
# POST /rest/api/3/issue/properties/multi
# operationId: bulkSetIssuePropertiesByIssue
# --issues item shape: {issueID?: int, properties?: record}
export def "rest-3-issue-properties-multi update-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --issues: list # A list of issue IDs and their respective properties. — item shape: {issueID?: int, properties?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issue/properties/multi")
  let req_body = {"issues": $issues} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk delete issue property
#
# DELETE /rest/api/3/issue/properties/{propertyKey}
# operationId: bulkDeleteIssueProperty
export def "rest-3-issue-properties delete-bulk-property" [
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-value: any # The value of properties to perform the bulk operation on.
  --entity-ids: list<int> # List of issues to perform the bulk delete operation on.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/issue/properties/{property_key}"))
  let req_body = {"currentValue": $current_value, "entityIds": $entity_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk set issue property
#
# PUT /rest/api/3/issue/properties/{propertyKey}
# operationId: bulkSetIssueProperty
export def "rest-3-issue-properties update-bulk-property" [
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expression: string # EXPERIMENTAL. The Jira expression to calculate the value of the property. The value of the expression must be an object that can be converted to JSON, such as a number, boolean, string, list, or map. The context variables available to the expression are `issue` and `user`. Issues for which the expression returns a value whose JSON representation is longer than 32768 characters are ignored.
  --filter: any # The bulk operation filter.
  --value: any # The value of the property. The value must be a [valid](https://tools.ietf.org/html/rfc4627), non-empty JSON blob. The maximum length is 32768 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/issue/properties/{property_key}"))
  let req_body = {"expression": $expression, "filter": $filter, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get is watching issue bulk
#
# POST /rest/api/3/issue/watching
# operationId: getIsWatchingIssueBulk
export def "rest-3-issue-watching get-is-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  issue_ids: list<string> # The list of issue IDs.
]: any -> record<issuesIsWatching: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issue/watching")
  let req_body = {"issueIds": $issue_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete issue
#
# DELETE /rest/api/3/issue/{issueIdOrKey}
# operationId: deleteIssue
export def "rest-3-issue delete" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-subtasks: string@delete-subtasks-completer # Whether the issue's subtasks are deleted when the issue is deleted. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteSubtasks" $delete_subtasks "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue
#
# GET /rest/api/3/issue/{issueIdOrKey}
# operationId: getIssue
export def "rest-3-issue get" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A list of fields to return for the issue. This parameter accepts a comma-separated list. Use it to retrieve a subset of fields. Allowed values: * `*all` Returns all fields. * `*navigable` Returns navigable fields. * Any issue field, prefixed with a minus to exclude. Examples: * `summary,comment` Returns only the summary and comments fields. * `-description` Returns all (default) fields except description. * `*navigable,-comment` Returns all navigable fields except comment. This parameter may be specified multiple times. For example, `fields=field1,field2& fields=field3`. Note: All fields are returned by default. This differs from [Search for issues using JQL (GET)](#api-rest-api-3-search-get) and [Search for issues using JQL (POST)](#api-rest-api-3-search-post) where the default is all navigable fields.
  --fields-by-keys: oneof<nothing, bool> # Whether fields in `fields` are referenced by keys rather than IDs. This parameter is useful where fields have been added by a connect app and a field's key may differ from its ID. (default: false)
  --expand: string # Use [expand](#expansion) to include additional information about the issues in the response. This parameter accepts a comma-separated list. Expand options include: * `renderedFields` Returns field values rendered in HTML format. * `names` Returns the display name of each field. * `schema` Returns the schema describing a field type. * `transitions` Returns all possible transitions for the issue. * `editmeta` Returns information about how each field can be edited. * `changelog` Returns a list of recent updates to an issue, sorted by date, starting from the most recent. * `versionedRepresentations` Returns a JSON array for each version of a field's value, with the highest number representing the most recent version. Note: When included in the request, the `fields` parameter is ignored.
  --properties: list<string> # A list of issue properties to return for the issue. This parameter accepts a comma-separated list. Allowed values: * `*all` Returns all issue properties. * Any issue property key, prefixed with a minus to exclude. Examples: * `*all` Returns all properties. * `*all,-prop1` Returns all properties except `prop1`. * `prop1,prop2` Returns `prop1` and `prop2` properties. This parameter may be specified multiple times. For example, `properties=prop1,prop2& properties=prop3`.
  --update-history: oneof<nothing, bool> # Whether the project in which the issue is created is added to the user's **Recently viewed** project list, as shown under **Projects** in Jira. This also populates the [JQL issues search](#api-rest-api-3-search-get) `lastViewed` field. (default: false)
]: nothing -> record<changelog: record<histories: list<record>, maxResults: int, startAt: int, total: int>, editmeta: record<fields: record>, expand: string, fields: record, fieldsToInclude: record<actuallyIncluded: list<string>, excluded: list<string>, included: list<string>>, id: string, key: string, names: record, operations: record<linkGroups: list<record>>, properties: record, renderedFields: record, schema: record, self: string, transitions: table<expand: string, fields: record, hasScreen: bool, id: string, isAvailable: bool, isConditional: bool, isGlobal: bool, isInitial: bool, looped: bool, name: string, to: record>, versionedRepresentations: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "multi") (serialize-qp "fieldsByKeys" $fields_by_keys "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "properties" $properties "multi") (serialize-qp "updateHistory" $update_history "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit issue
#
# PUT /rest/api/3/issue/{issueIdOrKey}
# operationId: editIssue
# --properties item shape: {key?: string, value?: any}
export def "rest-3-issue update-edit" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-users: oneof<nothing, bool> # Whether a notification email about the issue update is sent to all watchers. To disable the notification, administer Jira or administer project permissions are required. If the user doesn't have the necessary permission the request is ignored. (default: true)
  --override-screen-security: oneof<nothing, bool> # Whether screen security is overridden to enable hidden fields to be edited. Available to Connect app users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg) and Forge apps acting on behalf of users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). (default: false)
  --override-editable-flag: oneof<nothing, bool> # Whether screen security is overridden to enable uneditable fields to be edited. Available to Connect app users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg) and Forge apps acting on behalf of users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). (default: false)
  --fields: record # List of issue screen fields to update, specifying the sub-field to update and its value for each field. This field provides a straightforward option when setting a sub-field. When multiple sub-fields or other operations are required, use `update`. Fields included in here cannot be included in `update`.
  --history-metadata: any # Additional issue history details.
  --properties: list # Details of issue properties to be add or update. — item shape: {key?: string, value?: any}
  --transition: any # Details of a transition. Required when performing a transition, optional when creating or editing an issue.
  --update: record # A Map containing the field field name and a list of operations to perform on the issue screen field. Note that fields included in here cannot be included in `fields`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notifyUsers" $notify_users "scalar") (serialize-qp "overrideScreenSecurity" $override_screen_security "scalar") (serialize-qp "overrideEditableFlag" $override_editable_flag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}") $qp)
  let req_body = {"fields": $fields, "historyMetadata": $history_metadata, "properties": $properties, "transition": $transition, "update": $update} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Assign issue
#
# PUT /rest/api/3/issue/{issueIdOrKey}/assignee
# operationId: assignIssue
export def "rest-3-issue-assignee assign" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. Required in requests.
  --key: string # This property is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --name: string # This property is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/assignee"))
  let req_body = {"accountId": $account_id, "key": $key, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add attachment
#
# POST /rest/api/3/issue/{issueIdOrKey}/attachments
# operationId: addAttachment
export def "rest-3-issue-attachments create" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<author: record<accountId: string, accountType: string, active: bool, avatarUrls: record, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, content: string, created: string, filename: string, id: string, mimeType: string, self: string, size: int, thumbnail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/attachments"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $req_body
}

# Get changelogs
#
# GET /rest/api/3/issue/{issueIdOrKey}/changelog
# operationId: getChangeLogs
export def "rest-3-issue-changelog get-change-logs" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int32, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 100)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<author: record, created: string, historyMetadata: record, id: string, items: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/changelog") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get changelogs by IDs
#
# POST /rest/api/3/issue/{issueIdOrKey}/changelog/list
# operationId: getChangeLogsByIds
export def "rest-3-issue-changelog-list get-change-logs" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  changelog_ids: list<int> # The list of changelog IDs.
]: any -> record<histories: table<author: record, created: string, historyMetadata: record, id: string, items: list>, maxResults: int, startAt: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/changelog/list"))
  let req_body = {"changelogIds": $changelog_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get comments
#
# GET /rest/api/3/issue/{issueIdOrKey}/comment
# operationId: getComments
export def "rest-3-issue-comment list" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 5000)
  --order-by: string@order-by-completer-3 # [Order](#ordering) the results by a field. Accepts *created* to sort comments by their created date.
  --expand: string # Use [expand](#expansion) to include additional information about comments in the response. This parameter accepts `renderedBody`, which returns the comment body rendered in HTML.
]: nothing -> record<comments: table<author: record, body: any, created: string, id: string, jsdAuthorCanSeeRequest: bool, jsdPublic: bool, properties: list, renderedBody: string, self: string, updateAuthor: record, updated: string, visibility: record>, maxResults: int, startAt: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/comment") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add comment
#
# POST /rest/api/3/issue/{issueIdOrKey}/comment
# operationId: addComment
# --properties item shape: {key?: string, value?: any}
export def "rest-3-issue-comment create" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about comments in the response. This parameter accepts `renderedBody`, which returns the comment body rendered in HTML.
  --body: any # The comment text in [Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/).
  --properties: list # A list of comment properties. Optional on create and update. — item shape: {key?: string, value?: any}
  --visibility: any # The group or role to which this comment is visible. Optional on create and update.
]: any -> record<author: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, body: any, created: string, id: string, jsdAuthorCanSeeRequest: bool, jsdPublic: bool, properties: table<key: string, value: any>, renderedBody: string, self: string, updateAuthor: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, updated: string, visibility: record<identifier: string, type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/comment") $qp)
  let req_body = {"body": $body, "properties": $properties, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete comment
#
# DELETE /rest/api/3/issue/{issueIdOrKey}/comment/{id}
# operationId: deleteComment
export def "rest-3-issue-comment delete" [
  issue_id_or_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), id: (encode-path-segment $id)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/comment/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get comment
#
# GET /rest/api/3/issue/{issueIdOrKey}/comment/{id}
# operationId: getComment
export def "rest-3-issue-comment get" [
  issue_id_or_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about comments in the response. This parameter accepts `renderedBody`, which returns the comment body rendered in HTML.
]: nothing -> record<author: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, body: any, created: string, id: string, jsdAuthorCanSeeRequest: bool, jsdPublic: bool, properties: table<key: string, value: any>, renderedBody: string, self: string, updateAuthor: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, updated: string, visibility: record<identifier: string, type: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), id: (encode-path-segment $id)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/comment/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update comment
#
# PUT /rest/api/3/issue/{issueIdOrKey}/comment/{id}
# operationId: updateComment
# --properties item shape: {key?: string, value?: any}
export def "rest-3-issue-comment update" [
  issue_id_or_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-users: oneof<nothing, bool> # Whether users are notified when a comment is updated. (default: true)
  --override-editable-flag: oneof<nothing, bool> # Whether screen security is overridden to enable uneditable fields to be edited. Available to Connect app users with the *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg) and Forge apps acting on behalf of users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). (default: false)
  --expand: string # Use [expand](#expansion) to include additional information about comments in the response. This parameter accepts `renderedBody`, which returns the comment body rendered in HTML.
  --body: any # The comment text in [Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/).
  --properties: list # A list of comment properties. Optional on create and update. — item shape: {key?: string, value?: any}
  --visibility: any # The group or role to which this comment is visible. Optional on create and update.
]: any -> record<author: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, body: any, created: string, id: string, jsdAuthorCanSeeRequest: bool, jsdPublic: bool, properties: table<key: string, value: any>, renderedBody: string, self: string, updateAuthor: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, updated: string, visibility: record<identifier: string, type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notifyUsers" $notify_users "scalar") (serialize-qp "overrideEditableFlag" $override_editable_flag "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), id: (encode-path-segment $id)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/comment/{id}") $qp)
  let req_body = {"body": $body, "properties": $properties, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get edit issue metadata
#
# GET /rest/api/3/issue/{issueIdOrKey}/editmeta
# operationId: getEditIssueMeta
export def "rest-3-issue-editmeta get-edit-meta" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --override-screen-security: oneof<nothing, bool> # Whether hidden fields are returned. Available to Connect app users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg) and Forge apps acting on behalf of users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). (default: false)
  --override-editable-flag: oneof<nothing, bool> # Whether non-editable fields are returned. Available to Connect app users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg) and Forge apps acting on behalf of users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). (default: false)
]: nothing -> record<fields: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overrideScreenSecurity" $override_screen_security "scalar") (serialize-qp "overrideEditableFlag" $override_editable_flag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/editmeta") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send notification for issue
#
# POST /rest/api/3/issue/{issueIdOrKey}/notify
# operationId: notify
export def "rest-3-issue-notify notify" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --html-body: string # The HTML body of the email notification for the issue.
  --restrict: any # Restricts the notifications to users with the specified permissions.
  --subject: string # The subject of the email notification for the issue. If this is not specified, then the subject is set to the issue key and summary.
  --text-body: string # The plain text body of the email notification for the issue.
  --body-to: any # The recipients of the email notification for the issue.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/notify"))
  let req_body = {"htmlBody": $html_body, "restrict": $restrict, "subject": $subject, "textBody": $text_body, "to": $body_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get issue property keys
#
# GET /rest/api/3/issue/{issueIdOrKey}/properties
# operationId: getIssuePropertyKeys
export def "rest-3-issue-properties get-property-keys" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keys: table<key: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete issue property
#
# DELETE /rest/api/3/issue/{issueIdOrKey}/properties/{propertyKey}
# operationId: deleteIssueProperty
export def "rest-3-issue-properties delete-property" [
  issue_id_or_key: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue property
#
# GET /rest/api/3/issue/{issueIdOrKey}/properties/{propertyKey}
# operationId: getIssueProperty
export def "rest-3-issue-properties get-property" [
  issue_id_or_key: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set issue property
#
# PUT /rest/api/3/issue/{issueIdOrKey}/properties/{propertyKey}
# operationId: setIssueProperty
export def "rest-3-issue-properties update-property" [
  issue_id_or_key: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/properties/{property_key}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete remote issue link by global ID
#
# DELETE /rest/api/3/issue/{issueIdOrKey}/remotelink
# operationId: deleteRemoteIssueLinkByGlobalId
export def "rest-3-issue-remotelink delete-remote-link-by-global" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-id: string # The global ID of a remote issue link. (e.g. system=http://www.mycompany.com/support&id=1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "globalId" $global_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/remotelink") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get remote issue links
#
# GET /rest/api/3/issue/{issueIdOrKey}/remotelink
# operationId: getRemoteIssueLinks
export def "rest-3-issue-remotelink get-remote-links" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-id: string # The global ID of the remote issue link.
]: nothing -> record<application: record<name: string, type: string>, globalId: string, id: int, object: record<icon: record<link: string, title: string, url16x16: string>, status: record<icon: record, resolved: bool>, summary: string, title: string, url: string>, relationship: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "globalId" $global_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/remotelink") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update remote issue link
#
# POST /rest/api/3/issue/{issueIdOrKey}/remotelink
# operationId: createOrUpdateRemoteIssueLink
export def "rest-3-issue-remotelink create-or-update-remote-link" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --application: any # Details of the remote application the linked item is in. For example, trello.
  --global-id: string # An identifier for the remote item in the remote system. For example, the global ID for a remote item in Confluence would consist of the app ID and page ID, like this: `appId=456&pageId=123`. Setting this field enables the remote issue link details to be updated or deleted using remote system and item details as the record identifier, rather than using the record's Jira ID. The maximum length is 255 characters.
  object: any # Details of the item linked to.
  --relationship: string # Description of the relationship between the issue and the linked item. If not set, the relationship description "links to" is used in Jira.
]: any -> record<id: int, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/remotelink"))
  let req_body = {"application": $application, "globalId": $global_id, "object": $object, "relationship": $relationship} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete remote issue link by ID
#
# DELETE /rest/api/3/issue/{issueIdOrKey}/remotelink/{linkId}
# operationId: deleteRemoteIssueLinkById
export def "rest-3-issue-remotelink delete-remote-link" [
  issue_id_or_key: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), link_id: (encode-path-segment $link_id)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/remotelink/{link_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get remote issue link by ID
#
# GET /rest/api/3/issue/{issueIdOrKey}/remotelink/{linkId}
# operationId: getRemoteIssueLinkById
export def "rest-3-issue-remotelink get-remote-link" [
  issue_id_or_key: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<application: record<name: string, type: string>, globalId: string, id: int, object: record<icon: record<link: string, title: string, url16x16: string>, status: record<icon: record, resolved: bool>, summary: string, title: string, url: string>, relationship: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), link_id: (encode-path-segment $link_id)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/remotelink/{link_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update remote issue link by ID
#
# PUT /rest/api/3/issue/{issueIdOrKey}/remotelink/{linkId}
# operationId: updateRemoteIssueLink
export def "rest-3-issue-remotelink update-remote-link" [
  issue_id_or_key: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --application: any # Details of the remote application the linked item is in. For example, trello.
  --global-id: string # An identifier for the remote item in the remote system. For example, the global ID for a remote item in Confluence would consist of the app ID and page ID, like this: `appId=456&pageId=123`. Setting this field enables the remote issue link details to be updated or deleted using remote system and item details as the record identifier, rather than using the record's Jira ID. The maximum length is 255 characters.
  object: any # Details of the item linked to.
  --relationship: string # Description of the relationship between the issue and the linked item. If not set, the relationship description "links to" is used in Jira.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), link_id: (encode-path-segment $link_id)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/remotelink/{link_id}"))
  let req_body = {"application": $application, "globalId": $global_id, "object": $object, "relationship": $relationship} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get transitions
#
# GET /rest/api/3/issue/{issueIdOrKey}/transitions
# operationId: getTransitions
export def "rest-3-issue-transitions get" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about transitions in the response. This parameter accepts `transitions.fields`, which returns information about the fields in the transition screen for each transition. Fields hidden from the screen are not returned. Use this information to populate the `fields` and `update` fields in [Transition issue](#api-rest-api-3-issue-issueIdOrKey-transitions-post).
  --transition-id: string # The ID of the transition.
  --skip-remote-only-condition: oneof<nothing, bool> # Whether transitions with the condition *Hide From User Condition* are included in the response. (default: false)
  --include-unavailable-transitions: oneof<nothing, bool> # Whether details of transitions that fail a condition are included in the response (default: false)
  --sort-by-ops-bar-and-status: oneof<nothing, bool> # Whether the transitions are sorted by ops-bar sequence value first then category order (Todo, In Progress, Done) or only by ops-bar sequence value. (default: false)
]: nothing -> record<expand: string, transitions: table<expand: string, fields: record, hasScreen: bool, id: string, isAvailable: bool, isConditional: bool, isGlobal: bool, isInitial: bool, looped: bool, name: string, to: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "transitionId" $transition_id "scalar") (serialize-qp "skipRemoteOnlyCondition" $skip_remote_only_condition "scalar") (serialize-qp "includeUnavailableTransitions" $include_unavailable_transitions "scalar") (serialize-qp "sortByOpsBarAndStatus" $sort_by_ops_bar_and_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/transitions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transition issue
#
# POST /rest/api/3/issue/{issueIdOrKey}/transitions
# operationId: doTransition
# --properties item shape: {key?: string, value?: any}
export def "rest-3-issue-transitions create-do" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: record # List of issue screen fields to update, specifying the sub-field to update and its value for each field. This field provides a straightforward option when setting a sub-field. When multiple sub-fields or other operations are required, use `update`. Fields included in here cannot be included in `update`.
  --history-metadata: any # Additional issue history details.
  --properties: list # Details of issue properties to be add or update. — item shape: {key?: string, value?: any}
  --transition: any # Details of a transition. Required when performing a transition, optional when creating or editing an issue.
  --update: record # A Map containing the field field name and a list of operations to perform on the issue screen field. Note that fields included in here cannot be included in `fields`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/transitions"))
  let req_body = {"fields": $fields, "historyMetadata": $history_metadata, "properties": $properties, "transition": $transition, "update": $update} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete vote
#
# DELETE /rest/api/3/issue/{issueIdOrKey}/votes
# operationId: removeVote
export def "rest-3-issue-votes delete" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/votes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get votes
#
# GET /rest/api/3/issue/{issueIdOrKey}/votes
# operationId: getVotes
export def "rest-3-issue-votes get" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<hasVoted: bool, self: string, voters: table<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, votes: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/votes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add vote
#
# POST /rest/api/3/issue/{issueIdOrKey}/votes
# operationId: addVote
export def "rest-3-issue-votes create" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/votes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete watcher
#
# DELETE /rest/api/3/issue/{issueIdOrKey}/watchers
# operationId: removeWatcher
export def "rest-3-issue-watchers delete" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. Required. (e.g. 5b10ac8d82e05b22cc7d4ef5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "accountId" $account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/watchers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue watchers
#
# GET /rest/api/3/issue/{issueIdOrKey}/watchers
# operationId: getIssueWatchers
export def "rest-3-issue-watchers get" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isWatching: bool, self: string, watchCount: int, watchers: table<accountId: string, accountType: string, active: bool, avatarUrls: record, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/watchers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add watcher
#
# POST /rest/api/3/issue/{issueIdOrKey}/watchers
# operationId: addWatcher
export def "rest-3-issue-watchers create" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/watchers"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get issue worklogs
#
# GET /rest/api/3/issue/{issueIdOrKey}/worklog
# operationId: getIssueWorklog
export def "rest-3-issue-worklog list" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 5000)
  --started-after: int # The worklog start date and time, as a UNIX timestamp in milliseconds, after which worklogs are returned. (format: int64)
  --started-before: int # The worklog start date and time, as a UNIX timestamp in milliseconds, before which worklogs are returned. (format: int64)
  --expand: string # Use [expand](#expansion) to include additional information about worklogs in the response. This parameter accepts`properties`, which returns worklog properties. (default: )
]: nothing -> record<maxResults: int, startAt: int, total: int, worklogs: table<author: record, comment: any, created: string, id: string, issueId: string, properties: list, self: string, started: string, timeSpent: string, timeSpentSeconds: int, updateAuthor: record, updated: string, visibility: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "startedAfter" $started_after "scalar") (serialize-qp "startedBefore" $started_before "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/worklog") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add worklog
#
# POST /rest/api/3/issue/{issueIdOrKey}/worklog
# operationId: addWorklog
# --properties item shape: {key?: string, value?: any}
export def "rest-3-issue-worklog create" [
  issue_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-users: oneof<nothing, bool> # Whether users watching the issue are notified by email. (default: true)
  --adjust-estimate: string@adjust-estimate-completer # Defines how to update the issue's time estimate, the options are: * `new` Sets the estimate to a specific value, defined in `newEstimate`. * `leave` Leaves the estimate unchanged. * `manual` Reduces the estimate by amount specified in `reduceBy`. * `auto` Reduces the estimate by the value of `timeSpent` in the worklog. (default: auto)
  --new-estimate: string # The value to set as the issue's remaining time estimate, as days (\#d), hours (\#h), or minutes (\#m or \#). For example, *2d*. Required when `adjustEstimate` is `new`.
  --reduce-by: string # The amount to reduce the issue's remaining estimate by, as days (\#d), hours (\#h), or minutes (\#m). For example, *2d*. Required when `adjustEstimate` is `manual`.
  --expand: string # Use [expand](#expansion) to include additional information about work logs in the response. This parameter accepts `properties`, which returns worklog properties. (default: )
  --override-editable-flag: oneof<nothing, bool> # Whether the worklog entry should be added to the issue even if the issue is not editable, because jira.issue.editable set to false or missing. For example, the issue is closed. Connect and Forge app users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg) can use this flag. (default: false)
  --comment: any # A comment about the worklog in [Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/). Optional when creating or updating a worklog.
  --properties: list # Details of properties for the worklog. Optional when creating or updating a worklog. — item shape: {key?: string, value?: any}
  --started: string # The datetime on which the worklog effort was started. Required when creating a worklog. Optional when updating a worklog. (format: date-time)
  --time-spent: string # The time spent working on the issue as days (\#d), hours (\#h), or minutes (\#m or \#). Required when creating a worklog if `timeSpentSeconds` isn't provided. Optional when updating a worklog. Cannot be provided if `timeSpentSecond` is provided.
  --time-spent-seconds: int # The time in seconds spent working on the issue. Required when creating a worklog if `timeSpent` isn't provided. Optional when updating a worklog. Cannot be provided if `timeSpent` is provided. (format: int64)
  --visibility: any # Details about any restrictions in the visibility of the worklog. Optional when creating or updating a worklog.
]: any -> record<author: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, comment: any, created: string, id: string, issueId: string, properties: table<key: string, value: any>, self: string, started: string, timeSpent: string, timeSpentSeconds: int, updateAuthor: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, updated: string, visibility: record<identifier: string, type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notifyUsers" $notify_users "scalar") (serialize-qp "adjustEstimate" $adjust_estimate "scalar") (serialize-qp "newEstimate" $new_estimate "scalar") (serialize-qp "reduceBy" $reduce_by "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "overrideEditableFlag" $override_editable_flag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/worklog") $qp)
  let req_body = {"comment": $comment, "properties": $properties, "started": $started, "timeSpent": $time_spent, "timeSpentSeconds": $time_spent_seconds, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete worklog
#
# DELETE /rest/api/3/issue/{issueIdOrKey}/worklog/{id}
# operationId: deleteWorklog
export def "rest-3-issue-worklog delete" [
  issue_id_or_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-users: oneof<nothing, bool> # Whether users watching the issue are notified by email. (default: true)
  --adjust-estimate: string@adjust-estimate-completer # Defines how to update the issue's time estimate, the options are: * `new` Sets the estimate to a specific value, defined in `newEstimate`. * `leave` Leaves the estimate unchanged. * `manual` Increases the estimate by amount specified in `increaseBy`. * `auto` Reduces the estimate by the value of `timeSpent` in the worklog. (default: auto)
  --new-estimate: string # The value to set as the issue's remaining time estimate, as days (\#d), hours (\#h), or minutes (\#m or \#). For example, *2d*. Required when `adjustEstimate` is `new`.
  --increase-by: string # The amount to increase the issue's remaining estimate by, as days (\#d), hours (\#h), or minutes (\#m or \#). For example, *2d*. Required when `adjustEstimate` is `manual`.
  --override-editable-flag: oneof<nothing, bool> # Whether the work log entry should be added to the issue even if the issue is not editable, because jira.issue.editable set to false or missing. For example, the issue is closed. Connect and Forge app users with admin permission can use this flag. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notifyUsers" $notify_users "scalar") (serialize-qp "adjustEstimate" $adjust_estimate "scalar") (serialize-qp "newEstimate" $new_estimate "scalar") (serialize-qp "increaseBy" $increase_by "scalar") (serialize-qp "overrideEditableFlag" $override_editable_flag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), id: (encode-path-segment $id)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/worklog/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get worklog
#
# GET /rest/api/3/issue/{issueIdOrKey}/worklog/{id}
# operationId: getWorklog
export def "rest-3-issue-worklog get" [
  issue_id_or_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about work logs in the response. This parameter accepts `properties`, which returns worklog properties. (default: )
]: nothing -> record<author: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, comment: any, created: string, id: string, issueId: string, properties: table<key: string, value: any>, self: string, started: string, timeSpent: string, timeSpentSeconds: int, updateAuthor: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, updated: string, visibility: record<identifier: string, type: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), id: (encode-path-segment $id)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/worklog/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update worklog
#
# PUT /rest/api/3/issue/{issueIdOrKey}/worklog/{id}
# operationId: updateWorklog
# --properties item shape: {key?: string, value?: any}
export def "rest-3-issue-worklog update" [
  issue_id_or_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-users: oneof<nothing, bool> # Whether users watching the issue are notified by email. (default: true)
  --adjust-estimate: string@adjust-estimate-completer # Defines how to update the issue's time estimate, the options are: * `new` Sets the estimate to a specific value, defined in `newEstimate`. * `leave` Leaves the estimate unchanged. * `auto` Updates the estimate by the difference between the original and updated value of `timeSpent` or `timeSpentSeconds`. (default: auto)
  --new-estimate: string # The value to set as the issue's remaining time estimate, as days (\#d), hours (\#h), or minutes (\#m or \#). For example, *2d*. Required when `adjustEstimate` is `new`.
  --expand: string # Use [expand](#expansion) to include additional information about worklogs in the response. This parameter accepts `properties`, which returns worklog properties. (default: )
  --override-editable-flag: oneof<nothing, bool> # Whether the worklog should be added to the issue even if the issue is not editable. For example, because the issue is closed. Connect and Forge app users with *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg) can use this flag. (default: false)
  --comment: any # A comment about the worklog in [Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/). Optional when creating or updating a worklog.
  --properties: list # Details of properties for the worklog. Optional when creating or updating a worklog. — item shape: {key?: string, value?: any}
  --started: string # The datetime on which the worklog effort was started. Required when creating a worklog. Optional when updating a worklog. (format: date-time)
  --time-spent: string # The time spent working on the issue as days (\#d), hours (\#h), or minutes (\#m or \#). Required when creating a worklog if `timeSpentSeconds` isn't provided. Optional when updating a worklog. Cannot be provided if `timeSpentSecond` is provided.
  --time-spent-seconds: int # The time in seconds spent working on the issue. Required when creating a worklog if `timeSpent` isn't provided. Optional when updating a worklog. Cannot be provided if `timeSpent` is provided. (format: int64)
  --visibility: any # Details about any restrictions in the visibility of the worklog. Optional when creating or updating a worklog.
]: any -> record<author: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, comment: any, created: string, id: string, issueId: string, properties: table<key: string, value: any>, self: string, started: string, timeSpent: string, timeSpentSeconds: int, updateAuthor: record<accountId: string, accountType: string, active: bool, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, updated: string, visibility: record<identifier: string, type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notifyUsers" $notify_users "scalar") (serialize-qp "adjustEstimate" $adjust_estimate "scalar") (serialize-qp "newEstimate" $new_estimate "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "overrideEditableFlag" $override_editable_flag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), id: (encode-path-segment $id)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/worklog/{id}") $qp)
  let req_body = {"comment": $comment, "properties": $properties, "started": $started, "timeSpent": $time_spent, "timeSpentSeconds": $time_spent_seconds, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get worklog property keys
#
# GET /rest/api/3/issue/{issueIdOrKey}/worklog/{worklogId}/properties
# operationId: getWorklogPropertyKeys
export def "rest-3-issue-worklog-properties get-property-keys" [
  issue_id_or_key: string
  worklog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keys: table<key: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), worklog_id: (encode-path-segment $worklog_id)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/worklog/{worklog_id}/properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete worklog property
#
# DELETE /rest/api/3/issue/{issueIdOrKey}/worklog/{worklogId}/properties/{propertyKey}
# operationId: deleteWorklogProperty
export def "rest-3-issue-worklog-properties delete-property" [
  issue_id_or_key: string
  worklog_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), worklog_id: (encode-path-segment $worklog_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/worklog/{worklog_id}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get worklog property
#
# GET /rest/api/3/issue/{issueIdOrKey}/worklog/{worklogId}/properties/{propertyKey}
# operationId: getWorklogProperty
export def "rest-3-issue-worklog-properties get-property" [
  issue_id_or_key: string
  worklog_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), worklog_id: (encode-path-segment $worklog_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/worklog/{worklog_id}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set worklog property
#
# PUT /rest/api/3/issue/{issueIdOrKey}/worklog/{worklogId}/properties/{propertyKey}
# operationId: setWorklogProperty
export def "rest-3-issue-worklog-properties update-property" [
  issue_id_or_key: string
  worklog_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id_or_key: (encode-path-segment $issue_id_or_key), worklog_id: (encode-path-segment $worklog_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/issue/{issue_id_or_key}/worklog/{worklog_id}/properties/{property_key}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create issue link
#
# POST /rest/api/3/issueLink
# operationId: linkIssues
# --comment shape: {body?: any, properties?: list, visibility?: any}
# --inwardIssue shape: {id?: string, key?: string}
# --outwardIssue shape: {id?: string, key?: string}
# --type shape: {id?: string, inward?: string, name?: string, outward?: string}
export def "rest-3-issue-link create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: record # A comment. — shape: {body?: any, properties?: list, visibility?: any}
  inward_issue: record # The ID or key of a linked issue. — shape: {id?: string, key?: string}
  outward_issue: record # The ID or key of a linked issue. — shape: {id?: string, key?: string}
  type: record # This object is used as follows: * In the [ issueLink](#api-rest-api-3-issueLink-post) resource it defines and reports on the type of link between the issues. Find a list of issue link types with [Get issue link types](#api-rest-api-3-issueLinkType-get). * In the [ issueLinkType](#api-rest-api-3-issueLinkType-post) resource it defines and reports on issue link types. — shape: {id?: string, inward?: string, name?: string, outward?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issueLink")
  let req_body = {"comment": $comment, "inwardIssue": $inward_issue, "outwardIssue": $outward_issue, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete issue link
#
# DELETE /rest/api/3/issueLink/{linkId}
# operationId: deleteIssueLink
export def "rest-3-issue-link delete" [
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({link_id: (encode-path-segment $link_id)} | format pattern "/rest/api/3/issueLink/{link_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue link
#
# GET /rest/api/3/issueLink/{linkId}
# operationId: getIssueLink
export def "rest-3-issue-link get" [
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, inwardIssue: record<fields: record<assignee: record, issueType: record, issuetype: record, priority: record, status: record, summary: string, timetracking: record>, id: string, key: string, self: string>, outwardIssue: record<fields: record<assignee: record, issueType: record, issuetype: record, priority: record, status: record, summary: string, timetracking: record>, id: string, key: string, self: string>, self: string, type: record<id: string, inward: string, name: string, outward: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({link_id: (encode-path-segment $link_id)} | format pattern "/rest/api/3/issueLink/{link_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue link types
#
# GET /rest/api/3/issueLinkType
# operationId: getIssueLinkTypes
export def "rest-3-issue-link-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<issueLinkTypes: table<id: string, inward: string, name: string, outward: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issueLinkType")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create issue link type
#
# POST /rest/api/3/issueLinkType
# operationId: createIssueLinkType
export def "rest-3-issue-link-type create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the issue link type and is used as follows: * In the [ issueLink](#api-rest-api-3-issueLink-post) resource it is the type of issue link. Required on create when `name` isn't provided. Otherwise, read only. * In the [ issueLinkType](#api-rest-api-3-issueLinkType-post) resource it is read only.
  --inward: string # The description of the issue link type inward link and is used as follows: * In the [ issueLink](#api-rest-api-3-issueLink-post) resource it is read only. * In the [ issueLinkType](#api-rest-api-3-issueLinkType-post) resource it is required on create and optional on update. Otherwise, read only.
  --name: string # The name of the issue link type and is used as follows: * In the [ issueLink](#api-rest-api-3-issueLink-post) resource it is the type of issue link. Required on create when `id` isn't provided. Otherwise, read only. * In the [ issueLinkType](#api-rest-api-3-issueLinkType-post) resource it is required on create and optional on update. Otherwise, read only.
  --outward: string # The description of the issue link type outward link and is used as follows: * In the [ issueLink](#api-rest-api-3-issueLink-post) resource it is read only. * In the [ issueLinkType](#api-rest-api-3-issueLinkType-post) resource it is required on create and optional on update. Otherwise, read only.
]: any -> record<id: string, inward: string, name: string, outward: string, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issueLinkType")
  let req_body = {"id": $id, "inward": $inward, "name": $name, "outward": $outward} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete issue link type
#
# DELETE /rest/api/3/issueLinkType/{issueLinkTypeId}
# operationId: deleteIssueLinkType
export def "rest-3-issue-link-type delete" [
  issue_link_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_link_type_id: (encode-path-segment $issue_link_type_id)} | format pattern "/rest/api/3/issueLinkType/{issue_link_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue link type
#
# GET /rest/api/3/issueLinkType/{issueLinkTypeId}
# operationId: getIssueLinkType
export def "rest-3-issue-link-type get" [
  issue_link_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, inward: string, name: string, outward: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_link_type_id: (encode-path-segment $issue_link_type_id)} | format pattern "/rest/api/3/issueLinkType/{issue_link_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update issue link type
#
# PUT /rest/api/3/issueLinkType/{issueLinkTypeId}
# operationId: updateIssueLinkType
export def "rest-3-issue-link-type update" [
  issue_link_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the issue link type and is used as follows: * In the [ issueLink](#api-rest-api-3-issueLink-post) resource it is the type of issue link. Required on create when `name` isn't provided. Otherwise, read only. * In the [ issueLinkType](#api-rest-api-3-issueLinkType-post) resource it is read only.
  --inward: string # The description of the issue link type inward link and is used as follows: * In the [ issueLink](#api-rest-api-3-issueLink-post) resource it is read only. * In the [ issueLinkType](#api-rest-api-3-issueLinkType-post) resource it is required on create and optional on update. Otherwise, read only.
  --name: string # The name of the issue link type and is used as follows: * In the [ issueLink](#api-rest-api-3-issueLink-post) resource it is the type of issue link. Required on create when `id` isn't provided. Otherwise, read only. * In the [ issueLinkType](#api-rest-api-3-issueLinkType-post) resource it is required on create and optional on update. Otherwise, read only.
  --outward: string # The description of the issue link type outward link and is used as follows: * In the [ issueLink](#api-rest-api-3-issueLink-post) resource it is read only. * In the [ issueLinkType](#api-rest-api-3-issueLinkType-post) resource it is required on create and optional on update. Otherwise, read only.
]: any -> record<id: string, inward: string, name: string, outward: string, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_link_type_id: (encode-path-segment $issue_link_type_id)} | format pattern "/rest/api/3/issueLinkType/{issue_link_type_id}"))
  let req_body = {"id": $id, "inward": $inward, "name": $name, "outward": $outward} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get issue security schemes
#
# GET /rest/api/3/issuesecurityschemes
# operationId: getIssueSecuritySchemes
export def "rest-3-issuesecurityschemes get-issue-security-schemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<issueSecuritySchemes: table<defaultSecurityLevelId: int, description: string, id: int, levels: list, name: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issuesecurityschemes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue security scheme
#
# GET /rest/api/3/issuesecurityschemes/{id}
# operationId: getIssueSecurityScheme
export def "rest-3-issuesecurityschemes get-issue-security-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultSecurityLevelId: int, description: string, id: int, levels: table<description: string, id: string, isDefault: bool, issueSecuritySchemeId: string, name: string, self: string>, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/issuesecurityschemes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue security level members
#
# GET /rest/api/3/issuesecurityschemes/{issueSecuritySchemeId}/members
# operationId: getIssueSecurityLevelMembers
export def "rest-3-issuesecurityschemes-members get-issue-security-level" [
  issue_security_scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --issue-security-level-id: list<int> # The list of issue security level IDs. To include multiple issue security levels separate IDs with ampersand: `issueSecurityLevelId=10000&issueSecurityLevelId=10001`.
  --expand: string # Use expand to include additional information in the response. This parameter accepts a comma-separated list. Expand options include: * `all` Returns all expandable information. * `field` Returns information about the custom field granted the permission. * `group` Returns information about the group that is granted the permission. * `projectRole` Returns information about the project role granted the permission. * `user` Returns information about the user who is granted the permission.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<holder: record, id: int, issueSecurityLevelId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "issueSecurityLevelId" $issue_security_level_id "multi") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_security_scheme_id: (encode-path-segment $issue_security_scheme_id)} | format pattern "/rest/api/3/issuesecurityschemes/{issue_security_scheme_id}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all issue types for user
#
# GET /rest/api/3/issuetype
# operationId: getIssueAllTypes
export def "rest-3-issuetype get-issue-list-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<avatarId: int, description: string, entityId: string, hierarchyLevel: int, iconUrl: string, id: string, name: string, scope: record<project: record, type: string>, self: string, subtask: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issuetype")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create issue type
#
# POST /rest/api/3/issuetype
# operationId: createIssueType
export def "rest-3-issuetype create-issue-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the issue type.
  --hierarchy-level: int # The hierarchy level of the issue type. Use: * `-1` for Subtask. * `0` for Base. Defaults to `0`. (format: int32)
  name: string # The unique name for the issue type. The maximum length is 60 characters.
  --type: string@type-completer-1 # Deprecated. Use `hierarchyLevel` instead. See the [deprecation notice](https://community.developer.atlassian.com/t/deprecation-of-the-epic-link-parent-link-and-other-related-fields-in-rest-apis-and-webhooks/54048) for details. Whether the issue type is `subtype` or `standard`. Defaults to `standard`.
]: any -> record<avatarId: int, description: string, entityId: string, hierarchyLevel: int, iconUrl: string, id: string, name: string, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, subtask: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issuetype")
  let req_body = {"description": $description, "hierarchyLevel": $hierarchy_level, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get issue types for project
#
# GET /rest/api/3/issuetype/project
# operationId: getIssueTypesForProject
export def "rest-3-issuetype-project get-issue-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: int # The ID of the project. (format: int64)
  --level: int # The level of the issue type to filter by. Use: * `-1` for Subtask. * `0` for Base. * `1` for Epic. (format: int32)
]: nothing -> table<avatarId: int, description: string, entityId: string, hierarchyLevel: int, iconUrl: string, id: string, name: string, scope: record<project: record, type: string>, self: string, subtask: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "level" $level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/issuetype/project" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete issue type
#
# DELETE /rest/api/3/issuetype/{id}
# operationId: deleteIssueType
export def "rest-3-issuetype delete-issue-type" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternative-issue-type-id: string # The ID of the replacement issue type.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alternativeIssueTypeId" $alternative_issue_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/issuetype/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue type
#
# GET /rest/api/3/issuetype/{id}
# operationId: getIssueType
export def "rest-3-issuetype get-issue-type" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatarId: int, description: string, entityId: string, hierarchyLevel: int, iconUrl: string, id: string, name: string, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, subtask: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/issuetype/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update issue type
#
# PUT /rest/api/3/issuetype/{id}
# operationId: updateIssueType
export def "rest-3-issuetype update-issue-type" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar-id: int # The ID of an issue type avatar. (format: int64)
  --description: string # The description of the issue type.
  --name: string # The unique name for the issue type. The maximum length is 60 characters.
]: any -> record<avatarId: int, description: string, entityId: string, hierarchyLevel: int, iconUrl: string, id: string, name: string, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, subtask: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/issuetype/{id}"))
  let req_body = {"avatarId": $avatar_id, "description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get alternative issue types
#
# GET /rest/api/3/issuetype/{id}/alternatives
# operationId: getAlternativeIssueTypes
export def "rest-3-issuetype-alternatives get-issue-types" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<avatarId: int, description: string, entityId: string, hierarchyLevel: int, iconUrl: string, id: string, name: string, scope: record<project: record, type: string>, self: string, subtask: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/issuetype/{id}/alternatives"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Load issue type avatar
#
# POST /rest/api/3/issuetype/{id}/avatar2
# operationId: createIssueTypeAvatar
export def "rest-3-issuetype-avatar2 create-issue-type-avatar" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x: int # The X coordinate of the top-left corner of the crop region. (format: int32, default: 0)
  --y: int # The Y coordinate of the top-left corner of the crop region. (format: int32, default: 0)
  --size: int # The length of each side of the crop region. (format: int32)
  --body: record
]: any -> record<fileName: string, id: string, isDeletable: bool, isSelected: bool, isSystemAvatar: bool, owner: string, urls: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "x" $x "scalar") (serialize-qp "y" $y "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/issuetype/{id}/avatar2") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $req_body
}

# Get issue type property keys
#
# GET /rest/api/3/issuetype/{issueTypeId}/properties
# operationId: getIssueTypePropertyKeys
export def "rest-3-issuetype-properties get-issue-type-property-keys" [
  issue_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keys: table<key: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_id: (encode-path-segment $issue_type_id)} | format pattern "/rest/api/3/issuetype/{issue_type_id}/properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete issue type property
#
# DELETE /rest/api/3/issuetype/{issueTypeId}/properties/{propertyKey}
# operationId: deleteIssueTypeProperty
export def "rest-3-issuetype-properties delete-issue-type-property" [
  issue_type_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_id: (encode-path-segment $issue_type_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/issuetype/{issue_type_id}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue type property
#
# GET /rest/api/3/issuetype/{issueTypeId}/properties/{propertyKey}
# operationId: getIssueTypeProperty
export def "rest-3-issuetype-properties get-issue-type-property" [
  issue_type_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_id: (encode-path-segment $issue_type_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/issuetype/{issue_type_id}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set issue type property
#
# PUT /rest/api/3/issuetype/{issueTypeId}/properties/{propertyKey}
# operationId: setIssueTypeProperty
export def "rest-3-issuetype-properties update-issue-type-property" [
  issue_type_id: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_id: (encode-path-segment $issue_type_id), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/issuetype/{issue_type_id}/properties/{property_key}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all issue type schemes
#
# GET /rest/api/3/issuetypescheme
# operationId: getAllIssueTypeSchemes
export def "rest-3-issuetypescheme get-list-issue-type-schemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --id: list<int> # The list of issue type schemes IDs. To include multiple IDs, provide an ampersand-separated list. For example, `id=10000&id=10001`.
  --order-by: string@order-by-completer-4 # [Order](#ordering) the results by a field: * `name` Sorts by issue type scheme name. * `id` Sorts by issue type scheme ID. (default: id)
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expand options include: * `projects` For each issue type schemes, returns information about the projects the issue type scheme is assigned to. * `issueTypes` For each issue type schemes, returns information about the issueTypes the issue type scheme have. (default: )
  --query-string: string # String used to perform a case-insensitive partial match with issue type scheme name. (default: )
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<defaultIssueTypeId: string, description: string, id: string, isDefault: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "id" $id "multi") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "queryString" $query_string "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/issuetypescheme" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create issue type scheme
#
# POST /rest/api/3/issuetypescheme
# operationId: createIssueTypeScheme
export def "rest-3-issuetypescheme create-issue-type-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-issue-type-id: string # The ID of the default issue type of the issue type scheme. This ID must be included in `issueTypeIds`.
  --description: string # The description of the issue type scheme. The maximum length is 4000 characters.
  issue_type_ids: list<string> # The list of issue types IDs of the issue type scheme. At least one standard issue type ID is required.
  name: string # The name of the issue type scheme. The name must be unique. The maximum length is 255 characters.
]: any -> record<issueTypeSchemeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issuetypescheme")
  let req_body = {"defaultIssueTypeId": $default_issue_type_id, "description": $description, "issueTypeIds": $issue_type_ids, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get issue type scheme items
#
# GET /rest/api/3/issuetypescheme/mapping
# operationId: getIssueTypeSchemesMapping
export def "rest-3-issuetypescheme-mapping get-issue-type-schemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --issue-type-scheme-id: list<int> # The list of issue type scheme IDs. To include multiple IDs, provide an ampersand-separated list. For example, `issueTypeSchemeId=10000&issueTypeSchemeId=10001`.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<issueTypeId: string, issueTypeSchemeId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "issueTypeSchemeId" $issue_type_scheme_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/issuetypescheme/mapping" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue type schemes for projects
#
# GET /rest/api/3/issuetypescheme/project
# operationId: getIssueTypeSchemeForProjects
export def "rest-3-issuetypescheme-project get-issue-type-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --project-id: list<int> # The list of project IDs. To include multiple project IDs, provide an ampersand-separated list. For example, `projectId=10000&projectId=10001`.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<issueTypeScheme: record, projectIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "projectId" $project_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/issuetypescheme/project" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign issue type scheme to project
#
# PUT /rest/api/3/issuetypescheme/project
# operationId: assignIssueTypeSchemeToProject
export def "rest-3-issuetypescheme-project assign-issue-type-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  issue_type_scheme_id: string # The ID of the issue type scheme.
  project_id: string # The ID of the project.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issuetypescheme/project")
  let req_body = {"issueTypeSchemeId": $issue_type_scheme_id, "projectId": $project_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete issue type scheme
#
# DELETE /rest/api/3/issuetypescheme/{issueTypeSchemeId}
# operationId: deleteIssueTypeScheme
export def "rest-3-issuetypescheme delete-issue-type-scheme" [
  issue_type_scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_scheme_id: (encode-path-segment $issue_type_scheme_id)} | format pattern "/rest/api/3/issuetypescheme/{issue_type_scheme_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update issue type scheme
#
# PUT /rest/api/3/issuetypescheme/{issueTypeSchemeId}
# operationId: updateIssueTypeScheme
export def "rest-3-issuetypescheme update-issue-type-scheme" [
  issue_type_scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-issue-type-id: string # The ID of the default issue type of the issue type scheme.
  --description: string # The description of the issue type scheme. The maximum length is 4000 characters.
  --name: string # The name of the issue type scheme. The name must be unique. The maximum length is 255 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_scheme_id: (encode-path-segment $issue_type_scheme_id)} | format pattern "/rest/api/3/issuetypescheme/{issue_type_scheme_id}"))
  let req_body = {"defaultIssueTypeId": $default_issue_type_id, "description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add issue types to issue type scheme
#
# PUT /rest/api/3/issuetypescheme/{issueTypeSchemeId}/issuetype
# operationId: addIssueTypesToIssueTypeScheme
export def "rest-3-issuetypescheme-issuetype create-issue-types-to-issue-type-scheme" [
  issue_type_scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  issue_type_ids: list<string> # The list of issue type IDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_scheme_id: (encode-path-segment $issue_type_scheme_id)} | format pattern "/rest/api/3/issuetypescheme/{issue_type_scheme_id}/issuetype"))
  let req_body = {"issueTypeIds": $issue_type_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Change order of issue types
#
# PUT /rest/api/3/issuetypescheme/{issueTypeSchemeId}/issuetype/move
# operationId: reorderIssueTypesInIssueTypeScheme
export def "rest-3-issuetypescheme-issuetype-move update-reorder-issue-types-in-issue-type-scheme" [
  issue_type_scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # The ID of the issue type to place the moved issue types after. Required if `position` isn't provided.
  issue_type_ids: list<string> # A list of the issue type IDs to move. The order of the issue type IDs in the list is the order they are given after the move.
  --position: string@position-completer # The position the issue types should be moved to. Required if `after` isn't provided.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_scheme_id: (encode-path-segment $issue_type_scheme_id)} | format pattern "/rest/api/3/issuetypescheme/{issue_type_scheme_id}/issuetype/move"))
  let req_body = {"after": $after, "issueTypeIds": $issue_type_ids, "position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove issue type from issue type scheme
#
# DELETE /rest/api/3/issuetypescheme/{issueTypeSchemeId}/issuetype/{issueTypeId}
# operationId: removeIssueTypeFromIssueTypeScheme
export def "rest-3-issuetypescheme-issuetype delete-issue-type-from-issue-type-scheme" [
  issue_type_scheme_id: int
  issue_type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_scheme_id: (encode-path-segment $issue_type_scheme_id), issue_type_id: (encode-path-segment $issue_type_id)} | format pattern "/rest/api/3/issuetypescheme/{issue_type_scheme_id}/issuetype/{issue_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue type screen schemes
#
# GET /rest/api/3/issuetypescreenscheme
# operationId: getIssueTypeScreenSchemes
export def "rest-3-issuetypescreenscheme get-issue-type-screen-schemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --id: list<int> # The list of issue type screen scheme IDs. To include multiple IDs, provide an ampersand-separated list. For example, `id=10000&id=10001`.
  --query-string: string # String used to perform a case-insensitive partial match with issue type screen scheme name. (default: )
  --order-by: string@order-by-completer-4 # [Order](#ordering) the results by a field: * `name` Sorts by issue type screen scheme name. * `id` Sorts by issue type screen scheme ID. (default: id)
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts `projects` that, for each issue type screen schemes, returns information about the projects the issue type screen scheme is assigned to. (default: )
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "id" $id "multi") (serialize-qp "queryString" $query_string "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/issuetypescreenscheme" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create issue type screen scheme
#
# POST /rest/api/3/issuetypescreenscheme
# operationId: createIssueTypeScreenScheme
# --issueTypeMappings item shape: {issueTypeId: string, screenSchemeId: string}
export def "rest-3-issuetypescreenscheme create-issue-type-screen-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the issue type screen scheme. The maximum length is 255 characters.
  issue_type_mappings: list # The IDs of the screen schemes for the issue type IDs and *default*. A *default* entry is required to create an issue type screen scheme, it defines the mapping for all issue types without a screen scheme. — item shape: {issueTypeId: string, screenSchemeId: string}
  name: string # The name of the issue type screen scheme. The name must be unique. The maximum length is 255 characters.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issuetypescreenscheme")
  let req_body = {"description": $description, "issueTypeMappings": $issue_type_mappings, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get issue type screen scheme items
#
# GET /rest/api/3/issuetypescreenscheme/mapping
# operationId: getIssueTypeScreenSchemeMappings
export def "rest-3-issuetypescreenscheme-mapping get-issue-type-screen-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --issue-type-screen-scheme-id: list<int> # The list of issue type screen scheme IDs. To include multiple issue type screen schemes, separate IDs with ampersand: `issueTypeScreenSchemeId=10000&issueTypeScreenSchemeId=10001`.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<issueTypeId: string, issueTypeScreenSchemeId: string, screenSchemeId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "issueTypeScreenSchemeId" $issue_type_screen_scheme_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/issuetypescreenscheme/mapping" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue type screen schemes for projects
#
# GET /rest/api/3/issuetypescreenscheme/project
# operationId: getIssueTypeScreenSchemeProjectAssociations
export def "rest-3-issuetypescreenscheme-project get-issue-type-screen-scheme-associations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --project-id: list<int> # The list of project IDs. To include multiple projects, separate IDs with ampersand: `projectId=10000&projectId=10001`.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<issueTypeScreenScheme: record, projectIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "projectId" $project_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/issuetypescreenscheme/project" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign issue type screen scheme to project
#
# PUT /rest/api/3/issuetypescreenscheme/project
# operationId: assignIssueTypeScreenSchemeToProject
export def "rest-3-issuetypescreenscheme-project assign-issue-type-screen-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --issue-type-screen-scheme-id: string # The ID of the issue type screen scheme.
  --project-id: string # The ID of the project.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/issuetypescreenscheme/project")
  let req_body = {"issueTypeScreenSchemeId": $issue_type_screen_scheme_id, "projectId": $project_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete issue type screen scheme
#
# DELETE /rest/api/3/issuetypescreenscheme/{issueTypeScreenSchemeId}
# operationId: deleteIssueTypeScreenScheme
export def "rest-3-issuetypescreenscheme delete-issue-type-screen-scheme" [
  issue_type_screen_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_screen_scheme_id: (encode-path-segment $issue_type_screen_scheme_id)} | format pattern "/rest/api/3/issuetypescreenscheme/{issue_type_screen_scheme_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update issue type screen scheme
#
# PUT /rest/api/3/issuetypescreenscheme/{issueTypeScreenSchemeId}
# operationId: updateIssueTypeScreenScheme
export def "rest-3-issuetypescreenscheme update-issue-type-screen-scheme" [
  issue_type_screen_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the issue type screen scheme. The maximum length is 255 characters.
  --name: string # The name of the issue type screen scheme. The name must be unique. The maximum length is 255 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_screen_scheme_id: (encode-path-segment $issue_type_screen_scheme_id)} | format pattern "/rest/api/3/issuetypescreenscheme/{issue_type_screen_scheme_id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Append mappings to issue type screen scheme
#
# PUT /rest/api/3/issuetypescreenscheme/{issueTypeScreenSchemeId}/mapping
# operationId: appendMappingsForIssueTypeScreenScheme
# --issueTypeMappings item shape: {issueTypeId: string, screenSchemeId: string}
export def "rest-3-issuetypescreenscheme-mapping create-for-issue-type-screen-scheme" [
  issue_type_screen_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  issue_type_mappings: list # The list of issue type to screen scheme mappings. A *default* entry cannot be specified because a default entry is added when an issue type screen scheme is created. — item shape: {issueTypeId: string, screenSchemeId: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_screen_scheme_id: (encode-path-segment $issue_type_screen_scheme_id)} | format pattern "/rest/api/3/issuetypescreenscheme/{issue_type_screen_scheme_id}/mapping"))
  let req_body = {"issueTypeMappings": $issue_type_mappings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update issue type screen scheme default screen scheme
#
# PUT /rest/api/3/issuetypescreenscheme/{issueTypeScreenSchemeId}/mapping/default
# operationId: updateDefaultScreenScheme
export def "rest-3-issuetypescreenscheme-mapping-default update-screen-scheme" [
  issue_type_screen_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  screen_scheme_id: string # The ID of the screen scheme.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_screen_scheme_id: (encode-path-segment $issue_type_screen_scheme_id)} | format pattern "/rest/api/3/issuetypescreenscheme/{issue_type_screen_scheme_id}/mapping/default"))
  let req_body = {"screenSchemeId": $screen_scheme_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove mappings from issue type screen scheme
#
# POST /rest/api/3/issuetypescreenscheme/{issueTypeScreenSchemeId}/mapping/remove
# operationId: removeMappingsFromIssueTypeScreenScheme
export def "rest-3-issuetypescreenscheme-mapping-remove delete-from-issue-type-screen-scheme" [
  issue_type_screen_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  issue_type_ids: list<string> # The list of issue type IDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_type_screen_scheme_id: (encode-path-segment $issue_type_screen_scheme_id)} | format pattern "/rest/api/3/issuetypescreenscheme/{issue_type_screen_scheme_id}/mapping/remove"))
  let req_body = {"issueTypeIds": $issue_type_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get issue type screen scheme projects
#
# GET /rest/api/3/issuetypescreenscheme/{issueTypeScreenSchemeId}/project
# operationId: getProjectsForIssueTypeScreenScheme
export def "rest-3-issuetypescreenscheme-project get-for-issue-type-screen-scheme" [
  issue_type_screen_scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --query: string # default: 
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({issue_type_screen_scheme_id: (encode-path-segment $issue_type_screen_scheme_id)} | format pattern "/rest/api/3/issuetypescreenscheme/{issue_type_screen_scheme_id}/project") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get field reference data (GET)
#
# GET /rest/api/3/jql/autocompletedata
# operationId: getAutoComplete
export def "rest-3-jql-autocompletedata get-auto-complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<jqlReservedWords: list<string>, visibleFieldNames: table<auto: string, cfid: string, deprecated: string, deprecatedSearcherKey: string, displayName: string, operators: list, orderable: string, searchable: string, types: list, value: string>, visibleFunctionNames: table<displayName: string, isList: string, types: list, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/jql/autocompletedata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get field reference data (POST)
#
# POST /rest/api/3/jql/autocompletedata
# operationId: getAutoCompletePost
export def "rest-3-jql-autocompletedata get-auto-complete-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-collapsed-fields: oneof<nothing, bool> # Include collapsed fields for fields that have non-unique names. (default: false)
  --project-ids: list<int> # List of project IDs used to filter the visible field details returned.
]: any -> record<jqlReservedWords: list<string>, visibleFieldNames: table<auto: string, cfid: string, deprecated: string, deprecatedSearcherKey: string, displayName: string, operators: list, orderable: string, searchable: string, types: list, value: string>, visibleFunctionNames: table<displayName: string, isList: string, types: list, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/jql/autocompletedata")
  let req_body = {"includeCollapsedFields": $include_collapsed_fields, "projectIds": $project_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get field auto complete suggestions
#
# GET /rest/api/3/jql/autocompletedata/suggestions
# operationId: getFieldAutoCompleteForQueryString
export def "rest-3-jql-autocompletedata-suggestions get-field-auto-complete-for-list-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-name: string # The name of the field. (e.g. reporter)
  --field-value: string # The partial field item name entered by the user.
  --predicate-name: string # The name of the [ CHANGED operator predicate](https://confluence.atlassian.com/x/hQORLQ#Advancedsearching-operatorsreference-CHANGEDCHANGED) for which the suggestions are generated. The valid predicate operators are *by*, *from*, and *to*.
  --predicate-value: string # The partial predicate item name entered by the user.
]: nothing -> record<results: table<displayName: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldName" $field_name "scalar") (serialize-qp "fieldValue" $field_value "scalar") (serialize-qp "predicateName" $predicate_name "scalar") (serialize-qp "predicateValue" $predicate_value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/jql/autocompletedata/suggestions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get precomputation
#
# GET /rest/api/3/jql/function/computation
# operationId: getPrecomputations
export def "rest-3-jql-function-computation get-precomputations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --function-key: list<string>
  --start-at: int # format: int64, default: 0
  --max-results: int # format: int32, default: 5000
  --order-by: string
  --filter: string
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<arguments: list, created: string, field: string, functionKey: string, functionName: string, id: string, operator: string, updated: string, used: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "functionKey" $function_key "multi") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/jql/function/computation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update precomputations
#
# POST /rest/api/3/jql/function/computation
# operationId: updatePrecomputations
# --values item shape: {id: int, value: string}
export def "rest-3-jql-function-computation update-precomputations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --values: list # item shape: {id: int, value: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/jql/function/computation")
  let req_body = {"values": $values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Check issues against JQL
#
# POST /rest/api/3/jql/match
# operationId: matchIssues
export def "rest-3-jql-match create-issues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  issue_ids: list<int> # A list of issue IDs.
  jqls: list<string> # A list of JQL queries.
]: any -> record<matches: table<errors: list, matchedIssues: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/jql/match")
  let req_body = {"issueIds": $issue_ids, "jqls": $jqls} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Parse JQL query
#
# POST /rest/api/3/jql/parse
# operationId: parseJqlQueries
export def "rest-3-jql-parse create-queries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --validation: string@validation-completer # How to validate the JQL query and treat the validation results. Validation options include: * `strict` Returns all errors. If validation fails, the query structure is not returned. * `warn` Returns all errors. If validation fails but the JQL query is correctly formed, the query structure is returned. * `none` No validation is performed. If JQL query is correctly formed, the query structure is returned. (default: strict)
  queries: list<string> # A list of queries to parse.
]: any -> record<queries: table<errors: list, query: string, structure: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validation" $validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/jql/parse" $qp)
  let req_body = {"queries": $queries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Convert user identifiers to account IDs in JQL queries
#
# POST /rest/api/3/jql/pdcleaner
# operationId: migrateQueries
export def "rest-3-jql-pdcleaner create-migrate-queries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query-strings: list<string> # A list of queries with user identifiers. Maximum of 100 queries.
]: any -> record<queriesWithUnknownUsers: table<convertedQuery: string, originalQuery: string>, queryStrings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/jql/pdcleaner")
  let req_body = {"queryStrings": $query_strings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Sanitize JQL queries
#
# POST /rest/api/3/jql/sanitize
# operationId: sanitiseJqlQueries
# --queries item shape: {accountId?: string, query: string}
export def "rest-3-jql-sanitize create-sanitise-queries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  queries: list # The list of JQL queries to sanitize. Must contain unique values. Maximum of 20 queries. — item shape: {accountId?: string, query: string}
]: any -> record<queries: table<accountId: string, errors: record, initialQuery: string, sanitizedQuery: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/jql/sanitize")
  let req_body = {"queries": $queries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all labels
#
# GET /rest/api/3/label
# operationId: getAllLabels
export def "rest-3-label get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 1000)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/label" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get approximate license count
#
# GET /rest/api/3/license/approximateLicenseCount
# operationId: getApproximateLicenseCount
export def "rest-3-license-approximate-license-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/license/approximateLicenseCount")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get approximate application license count
#
# GET /rest/api/3/license/approximateLicenseCount/product/{applicationKey}
# operationId: getApproximateApplicationLicenseCount
export def "rest-3-license-approximate-license-count-product get-application" [
  application_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({application_key: (encode-path-segment $application_key)} | format pattern "/rest/api/3/license/approximateLicenseCount/product/{application_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get my permissions
#
# GET /rest/api/3/mypermissions
# operationId: getMyPermissions
export def "rest-3-mypermissions get-my-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-key: string # The key of project. Ignored if `projectId` is provided.
  --project-id: string # The ID of project.
  --issue-key: string # The key of the issue. Ignored if `issueId` is provided.
  --issue-id: string # The ID of the issue.
  --permissions: string # A list of permission keys. (Required) This parameter accepts a comma-separated list. To get the list of available permissions, use [Get all permissions](#api-rest-api-3-permissions-get). (e.g. BROWSE_PROJECTS,EDIT_ISSUES)
  --project-uuid: string
  --project-configuration-uuid: string
  --comment-id: string # The ID of the comment.
]: nothing -> record<permissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectKey" $project_key "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "issueKey" $issue_key "scalar") (serialize-qp "issueId" $issue_id "scalar") (serialize-qp "permissions" $permissions "scalar") (serialize-qp "projectUuid" $project_uuid "scalar") (serialize-qp "projectConfigurationUuid" $project_configuration_uuid "scalar") (serialize-qp "commentId" $comment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/mypermissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete preference
#
# DELETE /rest/api/3/mypreferences
# operationId: removePreference
export def "rest-3-mypreferences delete-preference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The key of the preference.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/mypreferences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get preference
#
# GET /rest/api/3/mypreferences
# operationId: getPreference
export def "rest-3-mypreferences get-preference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The key of the preference.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/mypreferences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set preference
#
# PUT /rest/api/3/mypreferences
# operationId: setPreference
export def "rest-3-mypreferences update-preference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The key of the preference. The maximum length is 255 characters.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/mypreferences" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete locale
#
# DELETE /rest/api/3/mypreferences/locale
# DEPRECATED
# operationId: deleteLocale
@deprecated
export def "rest-3-mypreferences-locale delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/mypreferences/locale")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get locale
#
# GET /rest/api/3/mypreferences/locale
# operationId: getLocale
export def "rest-3-mypreferences-locale get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<locale: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/mypreferences/locale")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set locale
#
# PUT /rest/api/3/mypreferences/locale
# DEPRECATED
# operationId: setLocale
@deprecated
export def "rest-3-mypreferences-locale update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale code. The Java the locale format is used: a two character language code (ISO 639), an underscore, and two letter country code (ISO 3166). For example, en\_US represents a locale of English (United States). Required on create.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/mypreferences/locale")
  let req_body = {"locale": $locale} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get current user
#
# GET /rest/api/3/myself
# operationId: getCurrentUser
export def "rest-3-myself get-get-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about user in the response. This parameter accepts a comma-separated list. Expand options include: * `groups` Returns all groups, including nested groups, the user belongs to. * `applicationRoles` Returns the application roles the user is assigned to.
]: nothing -> record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list<record>, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list<record>, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/myself" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get notification schemes paginated
#
# GET /rest/api/3/notificationscheme
# operationId: getNotificationSchemes
export def "rest-3-notificationscheme get-notification-schemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # The index of the first item to return in a page of results (page offset). (default: 0)
  --max-results: string # The maximum number of items to return per page. (default: 50)
  --id: list<string> # The list of notification schemes IDs to be filtered by
  --project-id: list<string> # The list of projects IDs to be filtered by
  --only-default: oneof<nothing, bool> # When set to true, returns only the default notification scheme. If you provide project IDs not associated with the default, returns an empty page. The default value is false. (default: false)
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expand options include: * `all` Returns all expandable information * `field` Returns information about any custom fields assigned to receive an event * `group` Returns information about any groups assigned to receive an event * `notificationSchemeEvents` Returns a list of event associations. This list is returned for all expandable information * `projectRole` Returns information about any project roles assigned to receive an event * `user` Returns information about any users assigned to receive an event
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, expand: string, id: int, name: string, notificationSchemeEvents: list, projects: list, scope: record, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "id" $id "multi") (serialize-qp "projectId" $project_id "multi") (serialize-qp "onlyDefault" $only_default "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/notificationscheme" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create notification scheme
#
# POST /rest/api/3/notificationscheme
# operationId: createNotificationScheme
# --notificationSchemeEvents item shape: {event: any, notifications: list}
export def "rest-3-notificationscheme create-notification-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the notification scheme.
  name: string # The name of the notification scheme. Must be unique (case-insensitive).
  --notification-scheme-events: list # The list of notifications which should be added to the notification scheme. — item shape: {event: any, notifications: list}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/notificationscheme")
  let req_body = {"description": $description, "name": $name, "notificationSchemeEvents": $notification_scheme_events} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get projects using notification schemes paginated
#
# GET /rest/api/3/notificationscheme/project
# operationId: getNotificationSchemeToProjectMappings
export def "rest-3-notificationscheme-project get-notification-scheme-to-mappings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # The index of the first item to return in a page of results (page offset). (default: 0)
  --max-results: string # The maximum number of items to return per page. (default: 50)
  --notification-scheme-id: list<string> # The list of notifications scheme IDs to be filtered out
  --project-id: list<string> # The list of project IDs to be filtered out
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<notificationSchemeId: string, projectId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "notificationSchemeId" $notification_scheme_id "multi") (serialize-qp "projectId" $project_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/notificationscheme/project" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get notification scheme
#
# GET /rest/api/3/notificationscheme/{id}
# operationId: getNotificationScheme
export def "rest-3-notificationscheme get-notification-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expand options include: * `all` Returns all expandable information * `field` Returns information about any custom fields assigned to receive an event * `group` Returns information about any groups assigned to receive an event * `notificationSchemeEvents` Returns a list of event associations. This list is returned for all expandable information * `projectRole` Returns information about any project roles assigned to receive an event * `user` Returns information about any users assigned to receive an event
]: nothing -> record<description: string, expand: string, id: int, name: string, notificationSchemeEvents: table<event: record, notifications: list>, projects: list<int>, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/notificationscheme/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update notification scheme
#
# PUT /rest/api/3/notificationscheme/{id}
# operationId: updateNotificationScheme
export def "rest-3-notificationscheme update-notification-scheme" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the notification scheme.
  --name: string # The name of the notification scheme. Must be unique.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/notificationscheme/{id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add notifications to notification scheme
#
# PUT /rest/api/3/notificationscheme/{id}/notification
# operationId: addNotifications
# --notificationSchemeEvents item shape: {event: any, notifications: list}
export def "rest-3-notificationscheme-notification create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  notification_scheme_events: list # The list of notifications which should be added to the notification scheme. — item shape: {event: any, notifications: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/notificationscheme/{id}/notification"))
  let req_body = {"notificationSchemeEvents": $notification_scheme_events} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete notification scheme
#
# DELETE /rest/api/3/notificationscheme/{notificationSchemeId}
# operationId: deleteNotificationScheme
export def "rest-3-notificationscheme delete-notification-scheme" [
  notification_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({notification_scheme_id: (encode-path-segment $notification_scheme_id)} | format pattern "/rest/api/3/notificationscheme/{notification_scheme_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove notification from notification scheme
#
# DELETE /rest/api/3/notificationscheme/{notificationSchemeId}/notification/{notificationId}
# operationId: removeNotificationFromNotificationScheme
export def "rest-3-notificationscheme-notification delete-from-scheme" [
  notification_scheme_id: string
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({notification_scheme_id: (encode-path-segment $notification_scheme_id), notification_id: (encode-path-segment $notification_id)} | format pattern "/rest/api/3/notificationscheme/{notification_scheme_id}/notification/{notification_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all permissions
#
# GET /rest/api/3/permissions
# operationId: getAllPermissions
export def "rest-3-permissions get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<permissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bulk permissions
#
# POST /rest/api/3/permissions/check
# operationId: getBulkPermissions
# --projectPermissions item shape: {issues?: list<int>, permissions: list<string>, projects?: list<int>}
export def "rest-3-permissions-check get-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of a user.
  --global-permissions: list<string> # Global permissions to look up.
  --project-permissions: list # Project permissions with associated projects and issues to look up. — item shape: {issues?: list<int>, permissions: list<string>, projects?: list<int>}
]: any -> record<globalPermissions: list<string>, projectPermissions: table<issues: list, permission: string, projects: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/permissions/check")
  let req_body = {"accountId": $account_id, "globalPermissions": $global_permissions, "projectPermissions": $project_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get permitted projects
#
# POST /rest/api/3/permissions/project
# operationId: getPermittedProjects
export def "rest-3-permissions-project get-permitted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  permissions: list<string> # A list of permission keys.
]: any -> record<projects: table<id: int, key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/permissions/project")
  let req_body = {"permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all permission schemes
#
# GET /rest/api/3/permissionscheme
# operationId: getAllPermissionSchemes
export def "rest-3-permissionscheme get-list-permission-schemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use expand to include additional information in the response. This parameter accepts a comma-separated list. Note that permissions are included when you specify any value. Expand options include: * `all` Returns all expandable information. * `field` Returns information about the custom field granted the permission. * `group` Returns information about the group that is granted the permission. * `permissions` Returns all permission grants for each permission scheme. * `projectRole` Returns information about the project role granted the permission. * `user` Returns information about the user who is granted the permission.
]: nothing -> record<permissionSchemes: table<description: string, expand: string, id: int, name: string, permissions: list, scope: record, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/permissionscheme" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create permission scheme
#
# POST /rest/api/3/permissionscheme
# operationId: createPermissionScheme
# --permissions item shape: {holder?: any, permission?: string}
export def "rest-3-permissionscheme create-permission-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use expand to include additional information in the response. This parameter accepts a comma-separated list. Note that permissions are always included when you specify any value. Expand options include: * `all` Returns all expandable information. * `field` Returns information about the custom field granted the permission. * `group` Returns information about the group that is granted the permission. * `permissions` Returns all permission grants for each permission scheme. * `projectRole` Returns information about the project role granted the permission. * `user` Returns information about the user who is granted the permission.
  --description: string # A description for the permission scheme.
  name: string # The name of the permission scheme. Must be unique.
  --permissions: list # The permission scheme to create or update. See [About permission schemes and grants](../api-group-permission-schemes/#about-permission-schemes-and-grants) for more information. — item shape: {holder?: any, permission?: string}
  --scope: any # The scope of the permission scheme.
]: any -> record<description: string, expand: string, id: int, name: string, permissions: table<holder: record, id: int, permission: string, self: string>, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/permissionscheme" $qp)
  let req_body = {"description": $description, "name": $name, "permissions": $permissions, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete permission scheme
#
# DELETE /rest/api/3/permissionscheme/{schemeId}
# operationId: deletePermissionScheme
export def "rest-3-permissionscheme delete-permission-scheme" [
  scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scheme_id: (encode-path-segment $scheme_id)} | format pattern "/rest/api/3/permissionscheme/{scheme_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get permission scheme
#
# GET /rest/api/3/permissionscheme/{schemeId}
# operationId: getPermissionScheme
export def "rest-3-permissionscheme get-permission-scheme" [
  scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use expand to include additional information in the response. This parameter accepts a comma-separated list. Note that permissions are included when you specify any value. Expand options include: * `all` Returns all expandable information. * `field` Returns information about the custom field granted the permission. * `group` Returns information about the group that is granted the permission. * `permissions` Returns all permission grants for each permission scheme. * `projectRole` Returns information about the project role granted the permission. * `user` Returns information about the user who is granted the permission.
]: nothing -> record<description: string, expand: string, id: int, name: string, permissions: table<holder: record, id: int, permission: string, self: string>, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scheme_id: (encode-path-segment $scheme_id)} | format pattern "/rest/api/3/permissionscheme/{scheme_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update permission scheme
#
# PUT /rest/api/3/permissionscheme/{schemeId}
# operationId: updatePermissionScheme
# --permissions item shape: {holder?: any, permission?: string}
export def "rest-3-permissionscheme update-permission-scheme" [
  scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use expand to include additional information in the response. This parameter accepts a comma-separated list. Note that permissions are always included when you specify any value. Expand options include: * `all` Returns all expandable information. * `field` Returns information about the custom field granted the permission. * `group` Returns information about the group that is granted the permission. * `permissions` Returns all permission grants for each permission scheme. * `projectRole` Returns information about the project role granted the permission. * `user` Returns information about the user who is granted the permission.
  --description: string # A description for the permission scheme.
  name: string # The name of the permission scheme. Must be unique.
  --permissions: list # The permission scheme to create or update. See [About permission schemes and grants](../api-group-permission-schemes/#about-permission-schemes-and-grants) for more information. — item shape: {holder?: any, permission?: string}
  --scope: any # The scope of the permission scheme.
]: any -> record<description: string, expand: string, id: int, name: string, permissions: table<holder: record, id: int, permission: string, self: string>, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scheme_id: (encode-path-segment $scheme_id)} | format pattern "/rest/api/3/permissionscheme/{scheme_id}") $qp)
  let req_body = {"description": $description, "name": $name, "permissions": $permissions, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get permission scheme grants
#
# GET /rest/api/3/permissionscheme/{schemeId}/permission
# operationId: getPermissionSchemeGrants
export def "rest-3-permissionscheme-permission get-scheme-grants" [
  scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use expand to include additional information in the response. This parameter accepts a comma-separated list. Note that permissions are always included when you specify any value. Expand options include: * `permissions` Returns all permission grants for each permission scheme. * `user` Returns information about the user who is granted the permission. * `group` Returns information about the group that is granted the permission. * `projectRole` Returns information about the project role granted the permission. * `field` Returns information about the custom field granted the permission. * `all` Returns all expandable information.
]: nothing -> record<expand: string, permissions: table<holder: record, id: int, permission: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scheme_id: (encode-path-segment $scheme_id)} | format pattern "/rest/api/3/permissionscheme/{scheme_id}/permission") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create permission grant
#
# POST /rest/api/3/permissionscheme/{schemeId}/permission
# operationId: createPermissionGrant
export def "rest-3-permissionscheme-permission create-grant" [
  scheme_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use expand to include additional information in the response. This parameter accepts a comma-separated list. Note that permissions are always included when you specify any value. Expand options include: * `permissions` Returns all permission grants for each permission scheme. * `user` Returns information about the user who is granted the permission. * `group` Returns information about the group that is granted the permission. * `projectRole` Returns information about the project role granted the permission. * `field` Returns information about the custom field granted the permission. * `all` Returns all expandable information.
  --holder: any # The user or group being granted the permission. It consists of a `type`, a type-dependent `parameter` and a type-dependent `value`. See [Holder object](../api-group-permission-schemes/#holder-object) in *Get all permission schemes* for more information.
  --permission: string # The permission to grant. This permission can be one of the built-in permissions or a custom permission added by an app. See [Built-in permissions](../api-group-permission-schemes/#built-in-permissions) in *Get all permission schemes* for more information about the built-in permissions. See the [project permission](https://developer.atlassian.com/cloud/jira/platform/modules/project-permission/) and [global permission](https://developer.atlassian.com/cloud/jira/platform/modules/global-permission/) module documentation for more information about custom permissions.
]: any -> record<holder: record<expand: string, parameter: string, type: string, value: string>, id: int, permission: string, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scheme_id: (encode-path-segment $scheme_id)} | format pattern "/rest/api/3/permissionscheme/{scheme_id}/permission") $qp)
  let req_body = {"holder": $holder, "permission": $permission} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete permission scheme grant
#
# DELETE /rest/api/3/permissionscheme/{schemeId}/permission/{permissionId}
# operationId: deletePermissionSchemeEntity
export def "rest-3-permissionscheme-permission delete-scheme-entity" [
  scheme_id: int
  permission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scheme_id: (encode-path-segment $scheme_id), permission_id: (encode-path-segment $permission_id)} | format pattern "/rest/api/3/permissionscheme/{scheme_id}/permission/{permission_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get permission scheme grant
#
# GET /rest/api/3/permissionscheme/{schemeId}/permission/{permissionId}
# operationId: getPermissionSchemeGrant
export def "rest-3-permissionscheme-permission get-scheme-grant" [
  scheme_id: int
  permission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use expand to include additional information in the response. This parameter accepts a comma-separated list. Note that permissions are always included when you specify any value. Expand options include: * `all` Returns all expandable information. * `field` Returns information about the custom field granted the permission. * `group` Returns information about the group that is granted the permission. * `permissions` Returns all permission grants for each permission scheme. * `projectRole` Returns information about the project role granted the permission. * `user` Returns information about the user who is granted the permission.
]: nothing -> record<holder: record<expand: string, parameter: string, type: string, value: string>, id: int, permission: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scheme_id: (encode-path-segment $scheme_id), permission_id: (encode-path-segment $permission_id)} | format pattern "/rest/api/3/permissionscheme/{scheme_id}/permission/{permission_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get priorities
#
# GET /rest/api/3/priority
# DEPRECATED
# operationId: getPriorities
@deprecated
export def "rest-3-priority get-priorities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, iconUrl: string, id: string, isDefault: bool, name: string, self: string, statusColor: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/priority")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create priority
#
# POST /rest/api/3/priority
# operationId: createPriority
export def "rest-3-priority create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the priority.
  --icon-url: string@icon-url-completer # The URL of an icon for the priority. Accepted protocols are HTTP and HTTPS. Built in icons can also be used.
  name: string # The name of the priority. Must be unique.
  status_color: string # The status color of the priority in 3-digit or 6-digit hexadecimal format.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/priority")
  let req_body = {"description": $description, "iconUrl": $icon_url, "name": $name, "statusColor": $status_color} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Set default priority
#
# PUT /rest/api/3/priority/default
# operationId: setDefaultPriority
export def "rest-3-priority-default update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The ID of the new default issue priority. Must be an existing ID or null. Setting this to null erases the default priority setting.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/priority/default")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Move priorities
#
# PUT /rest/api/3/priority/move
# operationId: movePriorities
export def "rest-3-priority-move move-priorities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # The ID of the priority. Required if `position` isn't provided.
  ids: list<string> # The list of issue IDs to be reordered. Cannot contain duplicates nor after ID.
  --position: string # The position for issue priorities to be moved to. Required if `after` isn't provided.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/priority/move")
  let req_body = {"after": $after, "ids": $ids, "position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Search priorities
#
# GET /rest/api/3/priority/search
# operationId: searchPriorities
export def "rest-3-priority-search list-priorities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # The index of the first item to return in a page of results (page offset). (default: 0)
  --max-results: string # The maximum number of items to return per page. (default: 50)
  --id: list<string> # The list of priority IDs. To include multiple IDs, provide an ampersand-separated list. For example, `id=2&id=3`.
  --only-default: oneof<nothing, bool> # Whether only the default priority is returned. (default: false)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, iconUrl: string, id: string, isDefault: bool, name: string, self: string, statusColor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "id" $id "multi") (serialize-qp "onlyDefault" $only_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/priority/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete priority
#
# DELETE /rest/api/3/priority/{id}
# operationId: deletePriority
export def "rest-3-priority delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --replace-with: string # The ID of the issue priority that will replace the currently selected resolution.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replaceWith" $replace_with "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/priority/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get priority
#
# GET /rest/api/3/priority/{id}
# operationId: getPriority
export def "rest-3-priority get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, iconUrl: string, id: string, isDefault: bool, name: string, self: string, statusColor: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/priority/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update priority
#
# PUT /rest/api/3/priority/{id}
# operationId: updatePriority
export def "rest-3-priority update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the priority.
  --icon-url: string@icon-url-completer # The URL of an icon for the priority. Accepted protocols are HTTP and HTTPS. Built in icons can also be used.
  --name: string # The name of the priority. Must be unique.
  --status-color: string # The status color of the priority in 3-digit or 6-digit hexadecimal format.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/priority/{id}"))
  let req_body = {"description": $description, "iconUrl": $icon_url, "name": $name, "statusColor": $status_color} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all projects
#
# GET /rest/api/3/project
# DEPRECATED
# operationId: getAllProjects
@deprecated
export def "rest-3-project get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expanded options include: * `description` Returns the project description. * `issueTypes` Returns all issue types associated with the project. * `lead` Returns information about the project lead. * `projectKeys` Returns all project keys associated with the project.
  --recent: int # Returns the user's most recently accessed projects. You may specify the number of results to return up to a maximum of 20. If access is anonymous, then the recently accessed projects are based on the current HTTP session. (format: int32)
  --properties: list<string> # A list of project properties to return for the project. This parameter accepts a comma-separated list.
]: nothing -> table<archived: bool, archivedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, archivedDate: string, assigneeType: string, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, components: list<record>, deleted: bool, deletedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, deletedDate: string, description: string, email: string, expand: string, favourite: bool, id: string, insight: record<lastIssueUpdateTime: string, totalIssueCount: int>, isPrivate: bool, issueTypeHierarchy: record<baseLevelId: int, levels: list>, issueTypes: list<record>, key: string, landingPageInfo: record<attributes: record, boardId: int, boardName: string, projectKey: string, projectType: string, queueCategory: string, queueId: int, queueName: string, simpleBoard: bool, simplified: bool, url: string>, lead: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, permissions: record<canEdit: bool>, projectCategory: record<description: string, id: string, name: string, self: string>, projectTypeKey: string, properties: record, retentionTillDate: string, roles: record, self: string, simplified: bool, style: string, url: string, uuid: string, versions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "recent" $recent "scalar") (serialize-qp "properties" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/project" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create project
#
# POST /rest/api/3/project
# operationId: createProject
export def "rest-3-project create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee-type: string@assignee-type-completer-1 # The default assignee when creating issues for this project.
  --avatar-id: int # An integer value for the project's avatar. (format: int64)
  --category-id: int # The ID of the project's category. A complete list of category IDs is found using the [Get all project categories](#api-rest-api-3-projectCategory-get) operation. (format: int64)
  --description: string # A brief description of the project.
  --field-configuration-scheme: int # The ID of the field configuration scheme for the project. Use the [Get all field configuration schemes](#api-rest-api-3-fieldconfigurationscheme-get) operation to get a list of field configuration scheme IDs. If you specify the field configuration scheme you cannot specify the project template key. (format: int64)
  --issue-security-scheme: int # The ID of the issue security scheme for the project, which enables you to control who can and cannot view issues. Use the [Get issue security schemes](#api-rest-api-3-issuesecurityschemes-get) resource to get all issue security scheme IDs. (format: int64)
  --issue-type-scheme: int # The ID of the issue type scheme for the project. Use the [Get all issue type schemes](#api-rest-api-3-issuetypescheme-get) operation to get a list of issue type scheme IDs. If you specify the issue type scheme you cannot specify the project template key. (format: int64)
  --issue-type-screen-scheme: int # The ID of the issue type screen scheme for the project. Use the [Get all issue type screen schemes](#api-rest-api-3-issuetypescreenscheme-get) operation to get a list of issue type screen scheme IDs. If you specify the issue type screen scheme you cannot specify the project template key. (format: int64)
  key: string # Project keys must be unique and start with an uppercase letter followed by one or more uppercase alphanumeric characters. The maximum length is 10 characters.
  --lead: string # This parameter is deprecated because of privacy changes. Use `leadAccountId` instead. See the [migration guide](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details. The user name of the project lead. Either `lead` or `leadAccountId` must be set when creating a project. Cannot be provided with `leadAccountId`.
  --lead-account-id: string # The account ID of the project lead. Either `lead` or `leadAccountId` must be set when creating a project. Cannot be provided with `lead`.
  name: string # The name of the project.
  --notification-scheme: int # The ID of the notification scheme for the project. Use the [Get notification schemes](#api-rest-api-3-notificationscheme-get) resource to get a list of notification scheme IDs. (format: int64)
  --permission-scheme: int # The ID of the permission scheme for the project. Use the [Get all permission schemes](#api-rest-api-3-permissionscheme-get) resource to see a list of all permission scheme IDs. (format: int64)
  --project-template-key: string@project-template-key-completer # A predefined configuration for a project. The type of the `projectTemplateKey` must match with the type of the `projectTypeKey`.
  --project-type-key: string@project-type-key-completer # The [project type](https://confluence.atlassian.com/x/GwiiLQ#Jiraapplicationsoverview-Productfeaturesandprojecttypes), which defines the application-specific feature set. If you don't specify the project template you have to specify the project type.
  --url: string # A link to information about this project, such as project documentation
  --workflow-scheme: int # The ID of the workflow scheme for the project. Use the [Get all workflow schemes](#api-rest-api-3-workflowscheme-get) operation to get a list of workflow scheme IDs. If you specify the workflow scheme you cannot specify the project template key. (format: int64)
]: any -> record<id: int, key: string, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/project")
  let req_body = {"assigneeType": $assignee_type, "avatarId": $avatar_id, "categoryId": $category_id, "description": $description, "fieldConfigurationScheme": $field_configuration_scheme, "issueSecurityScheme": $issue_security_scheme, "issueTypeScheme": $issue_type_scheme, "issueTypeScreenScheme": $issue_type_screen_scheme, "key": $key, "lead": $lead, "leadAccountId": $lead_account_id, "name": $name, "notificationScheme": $notification_scheme, "permissionScheme": $permission_scheme, "projectTemplateKey": $project_template_key, "projectTypeKey": $project_type_key, "url": $url, "workflowScheme": $workflow_scheme} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get recent projects
#
# GET /rest/api/3/project/recent
# operationId: getRecent
export def "rest-3-project-recent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expanded options include: * `description` Returns the project description. * `projectKeys` Returns all project keys associated with a project. * `lead` Returns information about the project lead. * `issueTypes` Returns all issue types associated with the project. * `url` Returns the URL associated with the project. * `permissions` Returns the permissions associated with the project. * `insight` EXPERIMENTAL. Returns the insight details of total issue count and last issue update time for the project. * `*` Returns the project with all available expand options.
  --properties: list # EXPERIMENTAL. A list of project properties to return for the project. This parameter accepts a comma-separated list. Invalid property names are ignored.
]: nothing -> table<archived: bool, archivedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, archivedDate: string, assigneeType: string, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, components: list<record>, deleted: bool, deletedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, deletedDate: string, description: string, email: string, expand: string, favourite: bool, id: string, insight: record<lastIssueUpdateTime: string, totalIssueCount: int>, isPrivate: bool, issueTypeHierarchy: record<baseLevelId: int, levels: list>, issueTypes: list<record>, key: string, landingPageInfo: record<attributes: record, boardId: int, boardName: string, projectKey: string, projectType: string, queueCategory: string, queueId: int, queueName: string, simpleBoard: bool, simplified: bool, url: string>, lead: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, permissions: record<canEdit: bool>, projectCategory: record<description: string, id: string, name: string, self: string>, projectTypeKey: string, properties: record, retentionTillDate: string, roles: record, self: string, simplified: bool, style: string, url: string, uuid: string, versions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "properties" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/project/recent" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get projects paginated
#
# GET /rest/api/3/project/search
# operationId: searchProjects
export def "rest-3-project-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --order-by: string@order-by-completer-5 # [Order](#ordering) the results by a field. * `category` Sorts by project category. A complete list of category IDs is found using [Get all project categories](#api-rest-api-3-projectCategory-get). * `issueCount` Sorts by the total number of issues in each project. * `key` Sorts by project key. * `lastIssueUpdatedTime` Sorts by the last issue update time. * `name` Sorts by project name. * `owner` Sorts by project lead. * `archivedDate` EXPERIMENTAL. Sorts by project archived date. * `deletedDate` EXPERIMENTAL. Sorts by project deleted date. (default: key)
  --id: list<int> # The project IDs to filter the results by. To include multiple IDs, provide an ampersand-separated list. For example, `id=10000&id=10001`. Up to 50 project IDs can be provided.
  --keys: list<string> # The project keys to filter the results by. To include multiple keys, provide an ampersand-separated list. For example, `keys=PA&keys=PB`. Up to 50 project keys can be provided.
  --query: string # Filter the results using a literal string. Projects with a matching `key` or `name` are returned (case insensitive).
  --type-key: string # Orders results by the [project type](https://confluence.atlassian.com/x/GwiiLQ#Jiraapplicationsoverview-Productfeaturesandprojecttypes). This parameter accepts a comma-separated list. Valid values are `business`, `service_desk`, and `software`.
  --category-id: int # The ID of the project's category. A complete list of category IDs is found using the [Get all project categories](#api-rest-api-3-projectCategory-get) operation. (format: int64)
  --action: string@action-completer # Filter results by projects for which the user can: * `view` the project, meaning that they have one of the following permissions: * *Browse projects* [project permission](https://confluence.atlassian.com/x/yodKLg) for the project. * *Administer projects* [project permission](https://confluence.atlassian.com/x/yodKLg) for the project. * *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). * `browse` the project, meaning that they have the *Browse projects* [project permission](https://confluence.atlassian.com/x/yodKLg) for the project. * `edit` the project, meaning that they have one of the following permissions: * *Administer projects* [project permission](https://confluence.atlassian.com/x/yodKLg) for the project. * *Administer Jira* [global permission](https://confluence.atlassian.com/x/x4dKLg). (default: view)
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expanded options include: * `description` Returns the project description. * `projectKeys` Returns all project keys associated with a project. * `lead` Returns information about the project lead. * `issueTypes` Returns all issue types associated with the project. * `url` Returns the URL associated with the project. * `insight` EXPERIMENTAL. Returns the insight details of total issue count and last issue update time for the project.
  --status: list<string> # EXPERIMENTAL. Filter results by project status: * `live` Search live projects. * `archived` Search archived projects. * `deleted` Search deleted projects, those in the recycle bin.
  --properties: list # EXPERIMENTAL. A list of project properties to return for the project. This parameter accepts a comma-separated list.
  --property-query: string # EXPERIMENTAL. A query string used to search properties. The query string cannot be specified using a JSON object. For example, to search for the value of `nested` from `{"something":{"nested":1,"other":2}}` use `[thepropertykey].something.nested=1`. Note that the propertyQuery key is enclosed in square brackets to enable searching where the propertyQuery key includes dot (.) or equals (=) characters. Note that `thepropertykey` is only returned when included in `properties`.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<archived: bool, archivedBy: record, archivedDate: string, assigneeType: string, avatarUrls: record, components: list, deleted: bool, deletedBy: record, deletedDate: string, description: string, email: string, expand: string, favourite: bool, id: string, insight: record, isPrivate: bool, issueTypeHierarchy: record, issueTypes: list, key: string, landingPageInfo: record, lead: record, name: string, permissions: record, projectCategory: record, projectTypeKey: string, properties: record, retentionTillDate: string, roles: record, self: string, simplified: bool, style: string, url: string, uuid: string, versions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "id" $id "multi") (serialize-qp "keys" $keys "multi") (serialize-qp "query" $query "scalar") (serialize-qp "typeKey" $type_key "scalar") (serialize-qp "categoryId" $category_id "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "status" $status "multi") (serialize-qp "properties" $properties "multi") (serialize-qp "propertyQuery" $property_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/project/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all project types
#
# GET /rest/api/3/project/type
# operationId: getAllProjectTypes
export def "rest-3-project-type get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<color: string, descriptionI18nKey: string, formattedKey: string, icon: string, key: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/project/type")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get licensed project types
#
# GET /rest/api/3/project/type/accessible
# operationId: getAllAccessibleProjectTypes
export def "rest-3-project-type-accessible get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<color: string, descriptionI18nKey: string, formattedKey: string, icon: string, key: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/project/type/accessible")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project type by key
#
# GET /rest/api/3/project/type/{projectTypeKey}
# operationId: getProjectTypeByKey
export def "rest-3-project-type get-by-key" [
  project_type_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<color: string, descriptionI18nKey: string, formattedKey: string, icon: string, key: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_type_key: (encode-path-segment $project_type_key)} | format pattern "/rest/api/3/project/type/{project_type_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get accessible project type by key
#
# GET /rest/api/3/project/type/{projectTypeKey}/accessible
# operationId: getAccessibleProjectTypeByKey
export def "rest-3-project-type-accessible get-by-key" [
  project_type_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<color: string, descriptionI18nKey: string, formattedKey: string, icon: string, key: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_type_key: (encode-path-segment $project_type_key)} | format pattern "/rest/api/3/project/type/{project_type_key}/accessible"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete project
#
# DELETE /rest/api/3/project/{projectIdOrKey}
# operationId: deleteProject
export def "rest-3-project delete" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enable-undo: oneof<nothing, bool> # Whether this project is placed in the Jira recycle bin where it will be available for restoration. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enableUndo" $enable_undo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project
#
# GET /rest/api/3/project/{projectIdOrKey}
# operationId: getProject
export def "rest-3-project get" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Note that the project description, issue types, and project lead are included in all responses by default. Expand options include: * `description` The project description. * `issueTypes` The issue types associated with the project. * `lead` The project lead. * `projectKeys` All project keys associated with the project. * `issueTypeHierarchy` The project issue type hierarchy.
  --properties: list<string> # A list of project properties to return for the project. This parameter accepts a comma-separated list.
]: nothing -> record<archived: bool, archivedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, archivedDate: string, assigneeType: string, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, components: table<assignee: record, assigneeType: string, description: string, id: string, isAssigneeTypeValid: bool, lead: record, leadAccountId: string, leadUserName: string, name: string, project: string, projectId: int, realAssignee: record, realAssigneeType: string, self: string>, deleted: bool, deletedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, deletedDate: string, description: string, email: string, expand: string, favourite: bool, id: string, insight: record<lastIssueUpdateTime: string, totalIssueCount: int>, isPrivate: bool, issueTypeHierarchy: record<baseLevelId: int, levels: list<record>>, issueTypes: table<avatarId: int, description: string, entityId: string, hierarchyLevel: int, iconUrl: string, id: string, name: string, scope: record, self: string, subtask: bool>, key: string, landingPageInfo: record<attributes: record, boardId: int, boardName: string, projectKey: string, projectType: string, queueCategory: string, queueId: int, queueName: string, simpleBoard: bool, simplified: bool, url: string>, lead: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, permissions: record<canEdit: bool>, projectCategory: record<description: string, id: string, name: string, self: string>, projectTypeKey: string, properties: record, retentionTillDate: string, roles: record, self: string, simplified: bool, style: string, url: string, uuid: string, versions: table<archived: bool, description: string, expand: string, id: string, issuesStatusForFixVersion: record, moveUnfixedIssuesTo: string, name: string, operations: list, overdue: bool, project: string, projectId: int, releaseDate: string, released: bool, self: string, startDate: string, userReleaseDate: string, userStartDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "properties" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project
#
# PUT /rest/api/3/project/{projectIdOrKey}
# operationId: updateProject
export def "rest-3-project update" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Note that the project description, issue types, and project lead are included in all responses by default. Expand options include: * `description` The project description. * `issueTypes` The issue types associated with the project. * `lead` The project lead. * `projectKeys` All project keys associated with the project.
  --assignee-type: string@assignee-type-completer-1 # The default assignee when creating issues for this project.
  --avatar-id: int # An integer value for the project's avatar. (format: int64)
  --category-id: int # The ID of the project's category. A complete list of category IDs is found using the [Get all project categories](#api-rest-api-3-projectCategory-get) operation. To remove the project category from the project, set the value to `-1.` (format: int64)
  --description: string # A brief description of the project.
  --issue-security-scheme: int # The ID of the issue security scheme for the project, which enables you to control who can and cannot view issues. Use the [Get issue security schemes](#api-rest-api-3-issuesecurityschemes-get) resource to get all issue security scheme IDs. (format: int64)
  --key: string # Project keys must be unique and start with an uppercase letter followed by one or more uppercase alphanumeric characters. The maximum length is 10 characters.
  --lead: string # This parameter is deprecated because of privacy changes. Use `leadAccountId` instead. See the [migration guide](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details. The user name of the project lead. Cannot be provided with `leadAccountId`.
  --lead-account-id: string # The account ID of the project lead. Cannot be provided with `lead`.
  --name: string # The name of the project.
  --notification-scheme: int # The ID of the notification scheme for the project. Use the [Get notification schemes](#api-rest-api-3-notificationscheme-get) resource to get a list of notification scheme IDs. (format: int64)
  --permission-scheme: int # The ID of the permission scheme for the project. Use the [Get all permission schemes](#api-rest-api-3-permissionscheme-get) resource to see a list of all permission scheme IDs. (format: int64)
  --url: string # A link to information about this project, such as project documentation
]: any -> record<archived: bool, archivedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, archivedDate: string, assigneeType: string, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, components: table<assignee: record, assigneeType: string, description: string, id: string, isAssigneeTypeValid: bool, lead: record, leadAccountId: string, leadUserName: string, name: string, project: string, projectId: int, realAssignee: record, realAssigneeType: string, self: string>, deleted: bool, deletedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, deletedDate: string, description: string, email: string, expand: string, favourite: bool, id: string, insight: record<lastIssueUpdateTime: string, totalIssueCount: int>, isPrivate: bool, issueTypeHierarchy: record<baseLevelId: int, levels: list<record>>, issueTypes: table<avatarId: int, description: string, entityId: string, hierarchyLevel: int, iconUrl: string, id: string, name: string, scope: record, self: string, subtask: bool>, key: string, landingPageInfo: record<attributes: record, boardId: int, boardName: string, projectKey: string, projectType: string, queueCategory: string, queueId: int, queueName: string, simpleBoard: bool, simplified: bool, url: string>, lead: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, permissions: record<canEdit: bool>, projectCategory: record<description: string, id: string, name: string, self: string>, projectTypeKey: string, properties: record, retentionTillDate: string, roles: record, self: string, simplified: bool, style: string, url: string, uuid: string, versions: table<archived: bool, description: string, expand: string, id: string, issuesStatusForFixVersion: record, moveUnfixedIssuesTo: string, name: string, operations: list, overdue: bool, project: string, projectId: int, releaseDate: string, released: bool, self: string, startDate: string, userReleaseDate: string, userStartDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}") $qp)
  let req_body = {"assigneeType": $assignee_type, "avatarId": $avatar_id, "categoryId": $category_id, "description": $description, "issueSecurityScheme": $issue_security_scheme, "key": $key, "lead": $lead, "leadAccountId": $lead_account_id, "name": $name, "notificationScheme": $notification_scheme, "permissionScheme": $permission_scheme, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Archive project
#
# POST /rest/api/3/project/{projectIdOrKey}/archive
# operationId: archiveProject
export def "rest-3-project-archive archive" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/archive"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set project avatar
#
# PUT /rest/api/3/project/{projectIdOrKey}/avatar
# operationId: updateProjectAvatar
export def "rest-3-project-avatar update" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The ID of the avatar.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/avatar"))
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete project avatar
#
# DELETE /rest/api/3/project/{projectIdOrKey}/avatar/{id}
# operationId: deleteProjectAvatar
export def "rest-3-project-avatar delete" [
  project_id_or_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key), id: (encode-path-segment $id)} | format pattern "/rest/api/3/project/{project_id_or_key}/avatar/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Load project avatar
#
# POST /rest/api/3/project/{projectIdOrKey}/avatar2
# operationId: createProjectAvatar
export def "rest-3-project-avatar2 create-avatar" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x: int # The X coordinate of the top-left corner of the crop region. (format: int32, default: 0)
  --y: int # The Y coordinate of the top-left corner of the crop region. (format: int32, default: 0)
  --size: int # The length of each side of the crop region. (format: int32)
  --body: record
]: any -> record<fileName: string, id: string, isDeletable: bool, isSelected: bool, isSystemAvatar: bool, owner: string, urls: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "x" $x "scalar") (serialize-qp "y" $y "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/avatar2") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $req_body
}

# Get all project avatars
#
# GET /rest/api/3/project/{projectIdOrKey}/avatars
# operationId: getAllProjectAvatars
export def "rest-3-project-avatars get-list" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<custom: table<fileName: string, id: string, isDeletable: bool, isSelected: bool, isSystemAvatar: bool, owner: string, urls: record>, system: table<fileName: string, id: string, isDeletable: bool, isSelected: bool, isSystemAvatar: bool, owner: string, urls: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/avatars"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project components paginated
#
# GET /rest/api/3/project/{projectIdOrKey}/component
# operationId: getProjectComponentsPaginated
export def "rest-3-project-component get-paginated" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --order-by: string@order-by-completer-6 # [Order](#ordering) the results by a field: * `description` Sorts by the component description. * `issueCount` Sorts by the count of issues associated with the component. * `lead` Sorts by the user key of the component's project lead. * `name` Sorts by component name.
  --query: string # Filter the results using a literal string. Components with a matching `name` or `description` are returned (case insensitive).
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<assignee: record, assigneeType: string, description: string, id: string, isAssigneeTypeValid: bool, issueCount: int, lead: record, name: string, project: string, projectId: int, realAssignee: record, realAssigneeType: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/component") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project components
#
# GET /rest/api/3/project/{projectIdOrKey}/components
# operationId: getProjectComponents
export def "rest-3-project-components get" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<assignee: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, assigneeType: string, description: string, id: string, isAssigneeTypeValid: bool, lead: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, leadAccountId: string, leadUserName: string, name: string, project: string, projectId: int, realAssignee: record<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>, realAssigneeType: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/components"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete project asynchronously
#
# POST /rest/api/3/project/{projectIdOrKey}/delete
# operationId: deleteProjectAsynchronously
export def "rest-3-project-delete delete-asynchronously" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/delete"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project features
#
# GET /rest/api/3/project/{projectIdOrKey}/features
# operationId: getFeaturesForProject
export def "rest-3-project-features get" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<features: table<feature: string, imageUri: string, localisedDescription: string, localisedName: string, prerequisites: list, projectId: int, state: string, toggleLocked: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/features"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set project feature state
#
# PUT /rest/api/3/project/{projectIdOrKey}/features/{featureKey}
# operationId: toggleFeatureForProject
export def "rest-3-project-features update-toggle" [
  project_id_or_key: string
  feature_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # The feature state.
]: any -> record<features: table<feature: string, imageUri: string, localisedDescription: string, localisedName: string, prerequisites: list, projectId: int, state: string, toggleLocked: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key), feature_key: (encode-path-segment $feature_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/features/{feature_key}"))
  let req_body = {"state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get project property keys
#
# GET /rest/api/3/project/{projectIdOrKey}/properties
# operationId: getProjectPropertyKeys
export def "rest-3-project-properties get-property-keys" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keys: table<key: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete project property
#
# DELETE /rest/api/3/project/{projectIdOrKey}/properties/{propertyKey}
# operationId: deleteProjectProperty
export def "rest-3-project-properties delete-property" [
  project_id_or_key: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project property
#
# GET /rest/api/3/project/{projectIdOrKey}/properties/{propertyKey}
# operationId: getProjectProperty
export def "rest-3-project-properties get-property" [
  project_id_or_key: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set project property
#
# PUT /rest/api/3/project/{projectIdOrKey}/properties/{propertyKey}
# operationId: setProjectProperty
export def "rest-3-project-properties update-property" [
  project_id_or_key: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key), property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/properties/{property_key}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Restore deleted or archived project
#
# POST /rest/api/3/project/{projectIdOrKey}/restore
# operationId: restore
export def "rest-3-project-restore create" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived: bool, archivedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, archivedDate: string, assigneeType: string, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, components: table<assignee: record, assigneeType: string, description: string, id: string, isAssigneeTypeValid: bool, lead: record, leadAccountId: string, leadUserName: string, name: string, project: string, projectId: int, realAssignee: record, realAssigneeType: string, self: string>, deleted: bool, deletedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, deletedDate: string, description: string, email: string, expand: string, favourite: bool, id: string, insight: record<lastIssueUpdateTime: string, totalIssueCount: int>, isPrivate: bool, issueTypeHierarchy: record<baseLevelId: int, levels: list<record>>, issueTypes: table<avatarId: int, description: string, entityId: string, hierarchyLevel: int, iconUrl: string, id: string, name: string, scope: record, self: string, subtask: bool>, key: string, landingPageInfo: record<attributes: record, boardId: int, boardName: string, projectKey: string, projectType: string, queueCategory: string, queueId: int, queueName: string, simpleBoard: bool, simplified: bool, url: string>, lead: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, permissions: record<canEdit: bool>, projectCategory: record<description: string, id: string, name: string, self: string>, projectTypeKey: string, properties: record, retentionTillDate: string, roles: record, self: string, simplified: bool, style: string, url: string, uuid: string, versions: table<archived: bool, description: string, expand: string, id: string, issuesStatusForFixVersion: record, moveUnfixedIssuesTo: string, name: string, operations: list, overdue: bool, project: string, projectId: int, releaseDate: string, released: bool, self: string, startDate: string, userReleaseDate: string, userStartDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/restore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project roles for project
#
# GET /rest/api/3/project/{projectIdOrKey}/role
# operationId: getProjectRoles
export def "rest-3-project-role list" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/role"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete actors from project role
#
# DELETE /rest/api/3/project/{projectIdOrKey}/role/{id}
# operationId: deleteActor
export def "rest-3-project-role delete-actor" [
  project_id_or_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # The user account ID of the user to remove from the project role. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --group: string # The name of the group to remove from the project role. This parameter cannot be used with the `groupId` parameter. As a group's name can change, use of `groupId` is recommended.
  --group-id: string # The ID of the group to remove from the project role. This parameter cannot be used with the `group` parameter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "groupId" $group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key), id: (encode-path-segment $id)} | format pattern "/rest/api/3/project/{project_id_or_key}/role/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project role for project
#
# GET /rest/api/3/project/{projectIdOrKey}/role/{id}
# operationId: getProjectRole
export def "rest-3-project-role get" [
  project_id_or_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-inactive-users: oneof<nothing, bool> # Exclude inactive users. (default: false)
]: nothing -> record<actors: table<actorGroup: record, actorUser: record, avatarUrl: string, displayName: string, id: int, name: string, type: string>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, translatedName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludeInactiveUsers" $exclude_inactive_users "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key), id: (encode-path-segment $id)} | format pattern "/rest/api/3/project/{project_id_or_key}/role/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add actors to project role
#
# POST /rest/api/3/project/{projectIdOrKey}/role/{id}
# operationId: addActorUsers
export def "rest-3-project-role create-actor-users" [
  project_id_or_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group: list<string> # The name of the group to add. This parameter cannot be used with the `groupId` parameter. As a group's name can change, use of `groupId` is recommended.
  --group-id: list<string> # The ID of the group to add. This parameter cannot be used with the `group` parameter.
  --user: list<string> # The user account ID of the user to add.
]: any -> record<actors: table<actorGroup: record, actorUser: record, avatarUrl: string, displayName: string, id: int, name: string, type: string>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, translatedName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key), id: (encode-path-segment $id)} | format pattern "/rest/api/3/project/{project_id_or_key}/role/{id}"))
  let req_body = {"group": $group, "groupId": $group_id, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Set actors for project role
#
# PUT /rest/api/3/project/{projectIdOrKey}/role/{id}
# operationId: setActors
export def "rest-3-project-role update-actors" [
  project_id_or_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categorised-actors: record # The actors to add to the project role. Add groups using: * `atlassian-group-role-actor` and a list of group names. * `atlassian-group-role-actor-id` and a list of group IDs. As a group's name can change, use of `atlassian-group-role-actor-id` is recommended. For example, `"atlassian-group-role-actor-id":["eef79f81-0b89-4fca-a736-4be531a10869","77f6ab39-e755-4570-a6ae-2d7a8df0bcb8"]`. Add users using `atlassian-user-role-actor` and a list of account IDs. For example, `"atlassian-user-role-actor":["12345678-9abc-def1-2345-6789abcdef12", "abcdef12-3456-789a-bcde-f123456789ab"]`.
]: any -> record<actors: table<actorGroup: record, actorUser: record, avatarUrl: string, displayName: string, id: int, name: string, type: string>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, translatedName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key), id: (encode-path-segment $id)} | format pattern "/rest/api/3/project/{project_id_or_key}/role/{id}"))
  let req_body = {"categorisedActors": $categorised_actors} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get project role details
#
# GET /rest/api/3/project/{projectIdOrKey}/roledetails
# operationId: getProjectRoleDetails
export def "rest-3-project-roledetails get-role-details" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-member: oneof<nothing, bool> # Whether the roles should be filtered to include only those the user is assigned to. (default: false)
  --exclude-connect-addons: oneof<nothing, bool> # default: false
]: nothing -> table<admin: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record, type: string>, self: string, translatedName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currentMember" $current_member "scalar") (serialize-qp "excludeConnectAddons" $exclude_connect_addons "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/roledetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all statuses for project
#
# GET /rest/api/3/project/{projectIdOrKey}/statuses
# operationId: getAllStatuses
export def "rest-3-project-statuses get-list" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, self: string, statuses: list<record>, subtask: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/statuses"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project type
#
# PUT /rest/api/3/project/{projectIdOrKey}/type/{newProjectTypeKey}
# DEPRECATED
# operationId: updateProjectType
@deprecated
export def "rest-3-project-type update" [
  project_id_or_key: string
  new_project_type_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived: bool, archivedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, archivedDate: string, assigneeType: string, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, components: table<assignee: record, assigneeType: string, description: string, id: string, isAssigneeTypeValid: bool, lead: record, leadAccountId: string, leadUserName: string, name: string, project: string, projectId: int, realAssignee: record, realAssigneeType: string, self: string>, deleted: bool, deletedBy: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, deletedDate: string, description: string, email: string, expand: string, favourite: bool, id: string, insight: record<lastIssueUpdateTime: string, totalIssueCount: int>, isPrivate: bool, issueTypeHierarchy: record<baseLevelId: int, levels: list<record>>, issueTypes: table<avatarId: int, description: string, entityId: string, hierarchyLevel: int, iconUrl: string, id: string, name: string, scope: record, self: string, subtask: bool>, key: string, landingPageInfo: record<attributes: record, boardId: int, boardName: string, projectKey: string, projectType: string, queueCategory: string, queueId: int, queueName: string, simpleBoard: bool, simplified: bool, url: string>, lead: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, permissions: record<canEdit: bool>, projectCategory: record<description: string, id: string, name: string, self: string>, projectTypeKey: string, properties: record, retentionTillDate: string, roles: record, self: string, simplified: bool, style: string, url: string, uuid: string, versions: table<archived: bool, description: string, expand: string, id: string, issuesStatusForFixVersion: record, moveUnfixedIssuesTo: string, name: string, operations: list, overdue: bool, project: string, projectId: int, releaseDate: string, released: bool, self: string, startDate: string, userReleaseDate: string, userStartDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key), new_project_type_key: (encode-path-segment $new_project_type_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/type/{new_project_type_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project versions paginated
#
# GET /rest/api/3/project/{projectIdOrKey}/version
# operationId: getProjectVersionsPaginated
export def "rest-3-project-version get-paginated" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --order-by: string@order-by-completer-7 # [Order](#ordering) the results by a field: * `description` Sorts by version description. * `name` Sorts by version name. * `releaseDate` Sorts by release date, starting with the oldest date. Versions with no release date are listed last. * `sequence` Sorts by the order of appearance in the user interface. * `startDate` Sorts by start date, starting with the oldest date. Versions with no start date are listed last.
  --query: string # Filter the results using a literal string. Versions with matching `name` or `description` are returned (case insensitive).
  --status: string # A list of status values used to filter the results by version status. This parameter accepts a comma-separated list. The status values are `released`, `unreleased`, and `archived`.
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expand options include: * `issuesstatus` Returns the number of issues in each status category for each version. * `operations` Returns actions that can be performed on the specified version.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<archived: bool, description: string, expand: string, id: string, issuesStatusForFixVersion: record, moveUnfixedIssuesTo: string, name: string, operations: list, overdue: bool, project: string, projectId: int, releaseDate: string, released: bool, self: string, startDate: string, userReleaseDate: string, userStartDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/version") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project versions
#
# GET /rest/api/3/project/{projectIdOrKey}/versions
# operationId: getProjectVersions
export def "rest-3-project-versions get" [
  project_id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts `operations`, which returns actions that can be performed on the version.
]: nothing -> table<archived: bool, description: string, expand: string, id: string, issuesStatusForFixVersion: record<done: int, inProgress: int, toDo: int, unmapped: int>, moveUnfixedIssuesTo: string, name: string, operations: list<record>, overdue: bool, project: string, projectId: int, releaseDate: string, released: bool, self: string, startDate: string, userReleaseDate: string, userStartDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id_or_key: (encode-path-segment $project_id_or_key)} | format pattern "/rest/api/3/project/{project_id_or_key}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project's sender email
#
# GET /rest/api/3/project/{projectId}/email
# operationId: getProjectEmail
export def "rest-3-project-email get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emailAddress: string, emailAddressStatus: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/rest/api/3/project/{project_id}/email"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set project's sender email
#
# PUT /rest/api/3/project/{projectId}/email
# operationId: updateProjectEmail
export def "rest-3-project-email update" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-address: string # The email address.
  --email-address-status: list<string> # When using a custom domain, the status of the email address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/rest/api/3/project/{project_id}/email"))
  let req_body = {"emailAddress": $email_address, "emailAddressStatus": $email_address_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get project issue type hierarchy
#
# GET /rest/api/3/project/{projectId}/hierarchy
# DEPRECATED
# operationId: getHierarchy
@deprecated
export def "rest-3-project-hierarchy get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<hierarchy: table<entityId: string, issueTypes: list, level: int, name: string>, projectId: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/rest/api/3/project/{project_id}/hierarchy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project issue security scheme
#
# GET /rest/api/3/project/{projectKeyOrId}/issuesecuritylevelscheme
# operationId: getProjectIssueSecurityScheme
export def "rest-3-project-issuesecuritylevelscheme get-issue-security-scheme" [
  project_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultSecurityLevelId: int, description: string, id: int, levels: table<description: string, id: string, isDefault: bool, issueSecuritySchemeId: string, name: string, self: string>, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_key_or_id: (encode-path-segment $project_key_or_id)} | format pattern "/rest/api/3/project/{project_key_or_id}/issuesecuritylevelscheme"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project notification scheme
#
# GET /rest/api/3/project/{projectKeyOrId}/notificationscheme
# DEPRECATED
# operationId: getNotificationSchemeForProject
@deprecated
export def "rest-3-project-notificationscheme get-notification-scheme" [
  project_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expand options include: * `all` Returns all expandable information * `field` Returns information about any custom fields assigned to receive an event * `group` Returns information about any groups assigned to receive an event * `notificationSchemeEvents` Returns a list of event associations. This list is returned for all expandable information * `projectRole` Returns information about any project roles assigned to receive an event * `user` Returns information about any users assigned to receive an event
]: nothing -> record<description: string, expand: string, id: int, name: string, notificationSchemeEvents: table<event: record, notifications: list>, projects: list<int>, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_key_or_id: (encode-path-segment $project_key_or_id)} | format pattern "/rest/api/3/project/{project_key_or_id}/notificationscheme") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get assigned permission scheme
#
# GET /rest/api/3/project/{projectKeyOrId}/permissionscheme
# operationId: getAssignedPermissionScheme
export def "rest-3-project-permissionscheme get-assigned-permission-scheme" [
  project_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Note that permissions are included when you specify any value. Expand options include: * `all` Returns all expandable information. * `field` Returns information about the custom field granted the permission. * `group` Returns information about the group that is granted the permission. * `permissions` Returns all permission grants for each permission scheme. * `projectRole` Returns information about the project role granted the permission. * `user` Returns information about the user who is granted the permission.
]: nothing -> record<description: string, expand: string, id: int, name: string, permissions: table<holder: record, id: int, permission: string, self: string>, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_key_or_id: (encode-path-segment $project_key_or_id)} | format pattern "/rest/api/3/project/{project_key_or_id}/permissionscheme") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign permission scheme
#
# PUT /rest/api/3/project/{projectKeyOrId}/permissionscheme
# operationId: assignPermissionScheme
export def "rest-3-project-permissionscheme assign-permission-scheme" [
  project_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Note that permissions are included when you specify any value. Expand options include: * `all` Returns all expandable information. * `field` Returns information about the custom field granted the permission. * `group` Returns information about the group that is granted the permission. * `permissions` Returns all permission grants for each permission scheme. * `projectRole` Returns information about the project role granted the permission. * `user` Returns information about the user who is granted the permission.
  id: int # The ID of the permission scheme to associate with the project. Use the [Get all permission schemes](#api-rest-api-3-permissionscheme-get) resource to get a list of permission scheme IDs. (format: int64)
]: any -> record<description: string, expand: string, id: int, name: string, permissions: table<holder: record, id: int, permission: string, self: string>, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_key_or_id: (encode-path-segment $project_key_or_id)} | format pattern "/rest/api/3/project/{project_key_or_id}/permissionscheme") $qp)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get project issue security levels
#
# GET /rest/api/3/project/{projectKeyOrId}/securitylevel
# operationId: getSecurityLevelsForProject
export def "rest-3-project-securitylevel get-security-levels" [
  project_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<levels: table<description: string, id: string, isDefault: bool, issueSecuritySchemeId: string, name: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_key_or_id: (encode-path-segment $project_key_or_id)} | format pattern "/rest/api/3/project/{project_key_or_id}/securitylevel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all project categories
#
# GET /rest/api/3/projectCategory
# operationId: getAllProjectCategories
export def "rest-3-project-category get-list-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/projectCategory")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create project category
#
# POST /rest/api/3/projectCategory
# operationId: createProjectCategory
export def "rest-3-project-category create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the project category.
  --name: string # The name of the project category. Required on create, optional on update.
]: any -> record<description: string, id: string, name: string, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/projectCategory")
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete project category
#
# DELETE /rest/api/3/projectCategory/{id}
# operationId: removeProjectCategory
export def "rest-3-project-category delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/projectCategory/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project category by ID
#
# GET /rest/api/3/projectCategory/{id}
# operationId: getProjectCategoryById
export def "rest-3-project-category get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/projectCategory/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project category
#
# PUT /rest/api/3/projectCategory/{id}
# operationId: updateProjectCategory
export def "rest-3-project-category update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the project category.
  --name: string # The name of the project category. Required on create, optional on update.
]: any -> record<description: string, id: string, name: string, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/projectCategory/{id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Validate project key
#
# GET /rest/api/3/projectvalidate/key
# operationId: validateProjectKey
export def "rest-3-projectvalidate-key validate-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The project key. (e.g. HSP)
]: nothing -> record<errorMessages: list<string>, errors: record, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/projectvalidate/key" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get valid project key
#
# GET /rest/api/3/projectvalidate/validProjectKey
# operationId: getValidProjectKey
export def "rest-3-projectvalidate-valid-project-key get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The project key. (e.g. HSP)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/projectvalidate/validProjectKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get valid project name
#
# GET /rest/api/3/projectvalidate/validProjectName
# operationId: getValidProjectName
export def "rest-3-projectvalidate-valid-project-name get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The project name.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/projectvalidate/validProjectName" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get resolutions
#
# GET /rest/api/3/resolution
# DEPRECATED
# operationId: getResolutions
@deprecated
export def "rest-3-resolution list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, id: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/resolution")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create resolution
#
# POST /rest/api/3/resolution
# operationId: createResolution
export def "rest-3-resolution create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the resolution.
  name: string # The name of the resolution. Must be unique (case-insensitive).
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/resolution")
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Set default resolution
#
# PUT /rest/api/3/resolution/default
# operationId: setDefaultResolution
export def "rest-3-resolution-default update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The ID of the new default issue resolution. Must be an existing ID or null. Setting this to null erases the default resolution setting.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/resolution/default")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Move resolutions
#
# PUT /rest/api/3/resolution/move
# operationId: moveResolutions
export def "rest-3-resolution-move move" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # The ID of the resolution. Required if `position` isn't provided.
  ids: list<string> # The list of resolution IDs to be reordered. Cannot contain duplicates nor after ID.
  --position: string # The position for issue resolutions to be moved to. Required if `after` isn't provided.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/resolution/move")
  let req_body = {"after": $after, "ids": $ids, "position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Search resolutions
#
# GET /rest/api/3/resolution/search
# operationId: searchResolutions
export def "rest-3-resolution-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # The index of the first item to return in a page of results (page offset). (default: 0)
  --max-results: string # The maximum number of items to return per page. (default: 50)
  --id: list<string> # The list of resolutions IDs to be filtered out
  --only-default: oneof<nothing, bool> # When set to true, return default only, when IDs provided, if none of them is default, return empty page. Default value is false (default: false)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<default: bool, description: string, iconUrl: string, id: string, name: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "id" $id "multi") (serialize-qp "onlyDefault" $only_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/resolution/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete resolution
#
# DELETE /rest/api/3/resolution/{id}
# operationId: deleteResolution
export def "rest-3-resolution delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --replace-with: string # The ID of the issue resolution that will replace the currently selected resolution.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replaceWith" $replace_with "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/resolution/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get resolution
#
# GET /rest/api/3/resolution/{id}
# operationId: getResolution
export def "rest-3-resolution get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/resolution/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update resolution
#
# PUT /rest/api/3/resolution/{id}
# operationId: updateResolution
export def "rest-3-resolution update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the resolution.
  name: string # The name of the resolution. Must be unique.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/resolution/{id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all project roles
#
# GET /rest/api/3/role
# operationId: getAllProjectRoles
export def "rest-3-role get-list-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<actors: list<record>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record, type: string>, self: string, translatedName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/role")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create project role
#
# POST /rest/api/3/role
# operationId: createProjectRole
export def "rest-3-role create-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description of the project role. Required when fully updating a project role. Optional when creating or partially updating a project role.
  --name: string # The name of the project role. Must be unique. Cannot begin or end with whitespace. The maximum length is 255 characters. Required when creating a project role. Optional when partially updating a project role.
]: any -> record<actors: table<actorGroup: record, actorUser: record, avatarUrl: string, displayName: string, id: int, name: string, type: string>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, translatedName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/role")
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete project role
#
# DELETE /rest/api/3/role/{id}
# operationId: deleteProjectRole
export def "rest-3-role delete-project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --swap: int # The ID of the project role that will replace the one being deleted. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "swap" $swap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/role/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project role by ID
#
# GET /rest/api/3/role/{id}
# operationId: getProjectRoleById
export def "rest-3-role get-project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actors: table<actorGroup: record, actorUser: record, avatarUrl: string, displayName: string, id: int, name: string, type: string>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, translatedName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/role/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partial update project role
#
# POST /rest/api/3/role/{id}
# operationId: partialUpdateProjectRole
export def "rest-3-role update-project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description of the project role. Required when fully updating a project role. Optional when creating or partially updating a project role.
  --name: string # The name of the project role. Must be unique. Cannot begin or end with whitespace. The maximum length is 255 characters. Required when creating a project role. Optional when partially updating a project role.
]: any -> record<actors: table<actorGroup: record, actorUser: record, avatarUrl: string, displayName: string, id: int, name: string, type: string>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, translatedName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/role/{id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Fully update project role
#
# PUT /rest/api/3/role/{id}
# operationId: fullyUpdateProjectRole
export def "rest-3-role update-fully-project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description of the project role. Required when fully updating a project role. Optional when creating or partially updating a project role.
  --name: string # The name of the project role. Must be unique. Cannot begin or end with whitespace. The maximum length is 255 characters. Required when creating a project role. Optional when partially updating a project role.
]: any -> record<actors: table<actorGroup: record, actorUser: record, avatarUrl: string, displayName: string, id: int, name: string, type: string>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, translatedName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/role/{id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete default actors from project role
#
# DELETE /rest/api/3/role/{id}/actors
# operationId: deleteProjectRoleActorsFromRole
export def "rest-3-role-actors delete-project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # The user account ID of the user to remove as a default actor. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --group-id: string # The group ID of the group to be removed as a default actor. This parameter cannot be used with the `group` parameter.
  --group: string # The group name of the group to be removed as a default actor.This parameter cannot be used with the `groupId` parameter. As a group's name can change, use of `groupId` is recommended.
]: nothing -> record<actors: table<actorGroup: record, actorUser: record, avatarUrl: string, displayName: string, id: int, name: string, type: string>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, translatedName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "group" $group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/role/{id}/actors") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default actors for project role
#
# GET /rest/api/3/role/{id}/actors
# operationId: getProjectRoleActorsForRole
export def "rest-3-role-actors get-project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actors: table<actorGroup: record, actorUser: record, avatarUrl: string, displayName: string, id: int, name: string, type: string>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, translatedName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/role/{id}/actors"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add default actors to project role
#
# POST /rest/api/3/role/{id}/actors
# operationId: addProjectRoleActorsToRole
export def "rest-3-role-actors create-project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group: list<string> # The name of the group to add as a default actor. This parameter cannot be used with the `groupId` parameter. As a group's name can change,use of `groupId` is recommended. This parameter accepts a comma-separated list. For example, `"group":["project-admin", "jira-developers"]`.
  --group-id: list<string> # The ID of the group to add as a default actor. This parameter cannot be used with the `group` parameter This parameter accepts a comma-separated list. For example, `"groupId":["77f6ab39-e755-4570-a6ae-2d7a8df0bcb8", "0c011f85-69ed-49c4-a801-3b18d0f771bc"]`.
  --user: list<string> # The account IDs of the users to add as default actors. This parameter accepts a comma-separated list. For example, `"user":["5b10a2844c20165700ede21g", "5b109f2e9729b51b54dc274d"]`.
]: any -> record<actors: table<actorGroup: record, actorUser: record, avatarUrl: string, displayName: string, id: int, name: string, type: string>, admin: bool, currentUserRole: bool, default: bool, description: string, id: int, name: string, roleConfigurable: bool, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>, self: string, translatedName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/role/{id}/actors"))
  let req_body = {"group": $group, "groupId": $group_id, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get screens
#
# GET /rest/api/3/screens
# operationId: getScreens
export def "rest-3-screens get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 100)
  --id: list<int> # The list of screen IDs. To include multiple IDs, provide an ampersand-separated list. For example, `id=10000&id=10001`.
  --query-string: string # String used to perform a case-insensitive partial match with screen name. (default: )
  --scope: list<string> # The scope filter string. To filter by multiple scope, provide an ampersand-separated list. For example, `scope=GLOBAL&scope=PROJECT`.
  --order-by: string@order-by-completer-4 # [Order](#ordering) the results by a field: * `id` Sorts by screen ID. * `name` Sorts by screen name.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, id: int, name: string, scope: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "id" $id "multi") (serialize-qp "queryString" $query_string "scalar") (serialize-qp "scope" $scope "multi") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/screens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create screen
#
# POST /rest/api/3/screens
# operationId: createScreen
export def "rest-3-screens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the screen. The maximum length is 255 characters.
  name: string # The name of the screen. The name must be unique. The maximum length is 255 characters.
]: any -> record<description: string, id: int, name: string, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/screens")
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add field to default screen
#
# POST /rest/api/3/screens/addToDefault/{fieldId}
# operationId: addFieldToDefaultScreen
export def "rest-3-screens-add-to-default create-field" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/rest/api/3/screens/addToDefault/{field_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete screen
#
# DELETE /rest/api/3/screens/{screenId}
# operationId: deleteScreen
export def "rest-3-screens delete" [
  screen_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id)} | format pattern "/rest/api/3/screens/{screen_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update screen
#
# PUT /rest/api/3/screens/{screenId}
# operationId: updateScreen
export def "rest-3-screens update" [
  screen_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the screen. The maximum length is 255 characters.
  --name: string # The name of the screen. The name must be unique. The maximum length is 255 characters.
]: any -> record<description: string, id: int, name: string, scope: record<project: record<avatarUrls: record, id: string, key: string, name: string, projectCategory: record, projectTypeKey: string, self: string, simplified: bool>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id)} | format pattern "/rest/api/3/screens/{screen_id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get available screen fields
#
# GET /rest/api/3/screens/{screenId}/availableFields
# operationId: getAvailableScreenFields
export def "rest-3-screens-available-fields get" [
  screen_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id)} | format pattern "/rest/api/3/screens/{screen_id}/availableFields"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all screen tabs
#
# GET /rest/api/3/screens/{screenId}/tabs
# operationId: getAllScreenTabs
export def "rest-3-screens-tabs get-list" [
  screen_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-key: string # The key of the project.
]: nothing -> table<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectKey" $project_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id)} | format pattern "/rest/api/3/screens/{screen_id}/tabs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create screen tab
#
# POST /rest/api/3/screens/{screenId}/tabs
# operationId: addScreenTab
export def "rest-3-screens-tabs create" [
  screen_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the screen tab. The maximum length is 255 characters.
]: any -> record<id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id)} | format pattern "/rest/api/3/screens/{screen_id}/tabs"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete screen tab
#
# DELETE /rest/api/3/screens/{screenId}/tabs/{tabId}
# operationId: deleteScreenTab
export def "rest-3-screens-tabs delete" [
  screen_id: int
  tab_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id), tab_id: (encode-path-segment $tab_id)} | format pattern "/rest/api/3/screens/{screen_id}/tabs/{tab_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update screen tab
#
# PUT /rest/api/3/screens/{screenId}/tabs/{tabId}
# operationId: renameScreenTab
export def "rest-3-screens-tabs rename" [
  screen_id: int
  tab_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the screen tab. The maximum length is 255 characters.
]: any -> record<id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id), tab_id: (encode-path-segment $tab_id)} | format pattern "/rest/api/3/screens/{screen_id}/tabs/{tab_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all screen tab fields
#
# GET /rest/api/3/screens/{screenId}/tabs/{tabId}/fields
# operationId: getAllScreenTabFields
export def "rest-3-screens-tabs-fields get-list" [
  screen_id: int
  tab_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-key: string # The key of the project.
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectKey" $project_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id), tab_id: (encode-path-segment $tab_id)} | format pattern "/rest/api/3/screens/{screen_id}/tabs/{tab_id}/fields") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add screen tab field
#
# POST /rest/api/3/screens/{screenId}/tabs/{tabId}/fields
# operationId: addScreenTabField
export def "rest-3-screens-tabs-fields create" [
  screen_id: int
  tab_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  field_id: string # The ID of the field to add.
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id), tab_id: (encode-path-segment $tab_id)} | format pattern "/rest/api/3/screens/{screen_id}/tabs/{tab_id}/fields"))
  let req_body = {"fieldId": $field_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove screen tab field
#
# DELETE /rest/api/3/screens/{screenId}/tabs/{tabId}/fields/{id}
# operationId: removeScreenTabField
export def "rest-3-screens-tabs-fields delete" [
  screen_id: int
  tab_id: int
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id), tab_id: (encode-path-segment $tab_id), id: (encode-path-segment $id)} | format pattern "/rest/api/3/screens/{screen_id}/tabs/{tab_id}/fields/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move screen tab field
#
# POST /rest/api/3/screens/{screenId}/tabs/{tabId}/fields/{id}/move
# operationId: moveScreenTabField
export def "rest-3-screens-tabs-fields-move move" [
  screen_id: int
  tab_id: int
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # The ID of the screen tab field after which to place the moved screen tab field. Required if `position` isn't provided. (format: uri)
  --position: string@position-completer-1 # The named position to which the screen tab field should be moved. Required if `after` isn't provided.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id), tab_id: (encode-path-segment $tab_id), id: (encode-path-segment $id)} | format pattern "/rest/api/3/screens/{screen_id}/tabs/{tab_id}/fields/{id}/move"))
  let req_body = {"after": $after, "position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Move screen tab
#
# POST /rest/api/3/screens/{screenId}/tabs/{tabId}/move/{pos}
# operationId: moveScreenTab
export def "rest-3-screens-tabs-move move" [
  screen_id: int
  tab_id: int
  pos: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_id: (encode-path-segment $screen_id), tab_id: (encode-path-segment $tab_id), pos: (encode-path-segment $pos)} | format pattern "/rest/api/3/screens/{screen_id}/tabs/{tab_id}/move/{pos}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get screen schemes
#
# GET /rest/api/3/screenscheme
# operationId: getScreenSchemes
export def "rest-3-screenscheme get-screen-schemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 25)
  --id: list<int> # The list of screen scheme IDs. To include multiple IDs, provide an ampersand-separated list. For example, `id=10000&id=10001`.
  --expand: string # Use [expand](#expansion) include additional information in the response. This parameter accepts `issueTypeScreenSchemes` that, for each screen schemes, returns information about the issue type screen scheme the screen scheme is assigned to. (default: )
  --query-string: string # String used to perform a case-insensitive partial match with screen scheme name. (default: )
  --order-by: string@order-by-completer-4 # [Order](#ordering) the results by a field: * `id` Sorts by screen scheme ID. * `name` Sorts by screen scheme name.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, id: int, issueTypeScreenSchemes: record, name: string, screens: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "id" $id "multi") (serialize-qp "expand" $expand "scalar") (serialize-qp "queryString" $query_string "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/screenscheme" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create screen scheme
#
# POST /rest/api/3/screenscheme
# operationId: createScreenScheme
export def "rest-3-screenscheme create-screen-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the screen scheme. The maximum length is 255 characters.
  name: string # The name of the screen scheme. The name must be unique. The maximum length is 255 characters.
  screens: any # The IDs of the screens for the screen types of the screen scheme. Only screens used in classic projects are accepted.
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/screenscheme")
  let req_body = {"description": $description, "name": $name, "screens": $screens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete screen scheme
#
# DELETE /rest/api/3/screenscheme/{screenSchemeId}
# operationId: deleteScreenScheme
export def "rest-3-screenscheme delete-screen-scheme" [
  screen_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_scheme_id: (encode-path-segment $screen_scheme_id)} | format pattern "/rest/api/3/screenscheme/{screen_scheme_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update screen scheme
#
# PUT /rest/api/3/screenscheme/{screenSchemeId}
# operationId: updateScreenScheme
export def "rest-3-screenscheme update-screen-scheme" [
  screen_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the screen scheme. The maximum length is 255 characters.
  --name: string # The name of the screen scheme. The name must be unique. The maximum length is 255 characters.
  --screens: any # The IDs of the screens for the screen types of the screen scheme. Only screens used in classic projects are accepted.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({screen_scheme_id: (encode-path-segment $screen_scheme_id)} | format pattern "/rest/api/3/screenscheme/{screen_scheme_id}"))
  let req_body = {"description": $description, "name": $name, "screens": $screens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Search for issues using JQL (GET)
#
# GET /rest/api/3/search
# operationId: searchForIssuesUsingJql
export def "rest-3-search list-for-issues-using-jql" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --jql: string # The [JQL](https://confluence.atlassian.com/x/egORLQ) that defines the search. Note: * If no JQL expression is provided, all issues are returned. * `username` and `userkey` cannot be used as search terms due to privacy reasons. Use `accountId` instead. * If a user has hidden their email address in their user profile, partial matches of the email address will not find the user. An exact match is required. (e.g. project = HSP)
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int32, default: 0)
  --max-results: int # The maximum number of items to return per page. To manage page size, Jira may return fewer items per page where a large number of fields are requested. The greatest number of items returned per page is achieved when requesting `id` or `key` only. (format: int32, default: 50)
  --validate-query: string@validate-query-completer # Determines how to validate the JQL query and treat the validation results. Supported values are: * `strict` Returns a 400 response code if any errors are found, along with a list of all errors (and warnings). * `warn` Returns all errors as warnings. * `none` No validation is performed. * `true` *Deprecated* A legacy synonym for `strict`. * `false` *Deprecated* A legacy synonym for `warn`. Note: If the JQL is not correctly formed a 400 response code is returned, regardless of the `validateQuery` value. (default: strict)
  --fields: list<string> # A list of fields to return for each issue, use it to retrieve a subset of fields. This parameter accepts a comma-separated list. Expand options include: * `*all` Returns all fields. * `*navigable` Returns navigable fields. * Any issue field, prefixed with a minus to exclude. Examples: * `summary,comment` Returns only the summary and comments fields. * `-description` Returns all navigable (default) fields except description. * `*all,-comment` Returns all fields except comments. This parameter may be specified multiple times. For example, `fields=field1,field2&fields=field3`. Note: All navigable fields are returned by default. This differs from [GET issue](#api-rest-api-3-issue-issueIdOrKey-get) where the default is all fields.
  --expand: string # Use [expand](#expansion) to include additional information about issues in the response. This parameter accepts a comma-separated list. Expand options include: * `renderedFields` Returns field values rendered in HTML format. * `names` Returns the display name of each field. * `schema` Returns the schema describing a field type. * `transitions` Returns all possible transitions for the issue. * `operations` Returns all possible operations for the issue. * `editmeta` Returns information about how each field can be edited. * `changelog` Returns a list of recent updates to an issue, sorted by date, starting from the most recent. * `versionedRepresentations` Instead of `fields`, returns `versionedRepresentations` a JSON array containing each version of a field's value, with the highest numbered item representing the most recent version.
  --properties: list<string> # A list of issue property keys for issue properties to include in the results. This parameter accepts a comma-separated list. Multiple properties can also be provided using an ampersand separated list. For example, `properties=prop1,prop2&properties=prop3`. A maximum of 5 issue property keys can be specified.
  --fields-by-keys: oneof<nothing, bool> # Reference fields by their key (rather than ID). (default: false)
]: nothing -> record<expand: string, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, maxResults: int, names: record, schema: record, startAt: int, total: int, warningMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jql" $jql "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "validateQuery" $validate_query "scalar") (serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "scalar") (serialize-qp "properties" $properties "multi") (serialize-qp "fieldsByKeys" $fields_by_keys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for issues using JQL (POST)
#
# POST /rest/api/3/search
# operationId: searchForIssuesUsingJqlPost
export def "rest-3-search create-for-issues-using-jql" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list<string> # Use [expand](em>#expansion) to include additional information about issues in the response. Note that, unlike the majority of instances where `expand` is specified, `expand` is defined as a list of values. The expand options are: * `renderedFields` Returns field values rendered in HTML format. * `names` Returns the display name of each field. * `schema` Returns the schema describing a field type. * `transitions` Returns all possible transitions for the issue. * `operations` Returns all possible operations for the issue. * `editmeta` Returns information about how each field can be edited. * `changelog` Returns a list of recent updates to an issue, sorted by date, starting from the most recent. * `versionedRepresentations` Instead of `fields`, returns `versionedRepresentations` a JSON array containing each version of a field's value, with the highest numbered item representing the most recent version.
  --fields: list<string> # A list of fields to return for each issue, use it to retrieve a subset of fields. This parameter accepts a comma-separated list. Expand options include: * `*all` Returns all fields. * `*navigable` Returns navigable fields. * Any issue field, prefixed with a minus to exclude. The default is `*navigable`. Examples: * `summary,comment` Returns the summary and comments fields only. * `-description` Returns all navigable (default) fields except description. * `*all,-comment` Returns all fields except comments. Multiple `fields` parameters can be included in a request. Note: All navigable fields are returned by default. This differs from [GET issue](#api-rest-api-3-issue-issueIdOrKey-get) where the default is all fields.
  --fields-by-keys: oneof<nothing, bool> # Reference fields by their key (rather than ID). The default is `false`.
  --jql: string # A [JQL](https://confluence.atlassian.com/x/egORLQ) expression.
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --properties: list<string> # A list of up to 5 issue properties to include in the results. This parameter accepts a comma-separated list.
  --start-at: int # The index of the first item to return in the page of results (page offset). The base index is `0`. (format: int32)
  --validate-query: string@validate-query-completer # Determines how to validate the JQL query and treat the validation results. Supported values: * `strict` Returns a 400 response code if any errors are found, along with a list of all errors (and warnings). * `warn` Returns all errors as warnings. * `none` No validation is performed. * `true` *Deprecated* A legacy synonym for `strict`. * `false` *Deprecated* A legacy synonym for `warn`. The default is `strict`. Note: If the JQL is not correctly formed a 400 response code is returned, regardless of the `validateQuery` value.
]: any -> record<expand: string, issues: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>, maxResults: int, names: record, schema: record, startAt: int, total: int, warningMessages: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/search")
  let req_body = {"expand": $expand, "fields": $fields, "fieldsByKeys": $fields_by_keys, "jql": $jql, "maxResults": $max_results, "properties": $properties, "startAt": $start_at, "validateQuery": $validate_query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get issue security level
#
# GET /rest/api/3/securitylevel/{id}
# operationId: getIssueSecurityLevel
export def "rest-3-securitylevel get-issue-security-level" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, isDefault: bool, issueSecuritySchemeId: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/securitylevel/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Jira instance info
#
# GET /rest/api/3/serverInfo
# operationId: getServerInfo
export def "rest-3-server-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseUrl: string, buildDate: string, buildNumber: int, deploymentType: string, healthChecks: table<description: string, name: string, passed: bool>, scmInfo: string, serverTime: string, serverTitle: string, version: string, versionNumbers: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/serverInfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue navigator default columns
#
# GET /rest/api/3/settings/columns
# operationId: getIssueNavigatorDefaultColumns
export def "rest-3-settings-columns get-issue-navigator-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<label: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/settings/columns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set issue navigator default columns
#
# PUT /rest/api/3/settings/columns
# operationId: setIssueNavigatorDefaultColumns
export def "rest-3-settings-columns update-issue-navigator-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/settings/columns")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $req_body
}

# Get all statuses
#
# GET /rest/api/3/status
# operationId: getStatuses
export def "rest-3-status get-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, iconUrl: string, id: string, name: string, self: string, statusCategory: record<colorName: string, id: int, key: string, name: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get status
#
# GET /rest/api/3/status/{idOrName}
# operationId: getStatus
export def "rest-3-status get" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, iconUrl: string, id: string, name: string, self: string, statusCategory: record<colorName: string, id: int, key: string, name: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name)} | format pattern "/rest/api/3/status/{id_or_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all status categories
#
# GET /rest/api/3/statuscategory
# operationId: getStatusCategories
export def "rest-3-statuscategory get-status-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<colorName: string, id: int, key: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/statuscategory")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get status category
#
# GET /rest/api/3/statuscategory/{idOrKey}
# operationId: getStatusCategory
export def "rest-3-statuscategory get-status-category" [
  id_or_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<colorName: string, id: int, key: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_or_key: (encode-path-segment $id_or_key)} | format pattern "/rest/api/3/statuscategory/{id_or_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk delete Statuses
#
# DELETE /rest/api/3/statuses
# operationId: deleteStatusesById
export def "rest-3-statuses delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # The list of status IDs. To include multiple IDs, provide an ampersand-separated list. For example, id=10000&id=10001. Min items `1`, Max items `50`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk get statuses
#
# GET /rest/api/3/statuses
# operationId: getStatusesById
export def "rest-3-statuses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expand options include: * `usages` Returns the project and issue types that use the status in their workflow.
  --id: list<string> # The list of status IDs. To include multiple IDs, provide an ampersand-separated list. For example, id=10000&id=10001. Min items `1`, Max items `50`
]: nothing -> table<description: string, id: string, name: string, scope: record<project: record, type: string>, statusCategory: string, usages: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk create statuses
#
# POST /rest/api/3/statuses
# operationId: createStatuses
# --scope shape: {project?: record, type: "PROJECT"|"GLOBAL"}
# --statuses item shape: {description?: string, name: string, statusCategory: "TODO"|"IN_PROGRESS"|"DONE"}
export def "rest-3-statuses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  scope: record # The scope of the status. — shape: {project?: record, type: "PROJECT"|"GLOBAL"}
  statuses: list # Details of the statuses being created. — item shape: {description?: string, name: string, statusCategory: "TODO"|"IN_PROGRESS"|"DONE"}
]: any -> table<description: string, id: string, name: string, scope: record<project: record, type: string>, statusCategory: string, usages: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/statuses")
  let req_body = {"scope": $scope, "statuses": $statuses} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk update statuses
#
# PUT /rest/api/3/statuses
# operationId: updateStatuses
# --statuses item shape: {description?: string, id: string, name: string, statusCategory: "TODO"|"IN_PROGRESS"|"DONE"}
export def "rest-3-statuses update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --statuses: list # The list of statuses that will be updated. — item shape: {description?: string, id: string, name: string, statusCategory: "TODO"|"IN_PROGRESS"|"DONE"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/statuses")
  let req_body = {"statuses": $statuses} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Search statuses paginated
#
# GET /rest/api/3/statuses/search
# operationId: search
export def "rest-3-statuses-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expand options include: * `usages` Returns the project and issue types that use the status in their workflow.
  --project-id: string # The project the status is part of or null for global statuses.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 200)
  --search-string: string # Term to match status names against or null to search for all statuses in the search scope.
  --status-category: string # Category of the status to filter by. The supported values are: `TODO`, `IN_PROGRESS`, and `DONE`.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<description: string, id: string, name: string, scope: record, statusCategory: string, usages: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "searchString" $search_string "scalar") (serialize-qp "statusCategory" $status_category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/statuses/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get task
#
# GET /rest/api/3/task/{taskId}
# operationId: getTask
export def "rest-3-task get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, elapsedRuntime: int, finished: int, id: string, lastUpdate: int, message: string, progress: int, result: any, self: string, started: int, status: string, submitted: int, submittedBy: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/rest/api/3/task/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel task
#
# POST /rest/api/3/task/{taskId}/cancel
# operationId: cancelTask
export def "rest-3-task-cancel cancel" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/rest/api/3/task/{task_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get UI modifications
#
# GET /rest/api/3/uiModifications
# operationId: getUiModifications
export def "rest-3-ui-modifications get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --expand: string # Use expand to include additional information in the response. This parameter accepts a comma-separated list. Expand options include: * `data` Returns UI modification data. * `contexts` Returns UI modification contexts.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<contexts: list, data: string, description: string, id: string, name: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/uiModifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create UI modification
#
# POST /rest/api/3/uiModifications
# operationId: createUiModification
# --contexts item shape: {issueTypeId: string, projectId: string, viewType: string}
export def "rest-3-ui-modifications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contexts: list # List of contexts of the UI modification. The maximum number of contexts is 1000. — item shape: {issueTypeId: string, projectId: string, viewType: string}
  --data: string # The data of the UI modification. The maximum size of the data is 50000 characters.
  --description: string # The description of the UI modification. The maximum length is 255 characters.
  name: string # The name of the UI modification. The maximum length is 255 characters.
]: any -> record<id: string, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/uiModifications")
  let req_body = {"contexts": $contexts, "data": $data, "description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete UI modification
#
# DELETE /rest/api/3/uiModifications/{uiModificationId}
# operationId: deleteUiModification
export def "rest-3-ui-modifications delete" [
  ui_modification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ui_modification_id: (encode-path-segment $ui_modification_id)} | format pattern "/rest/api/3/uiModifications/{ui_modification_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update UI modification
#
# PUT /rest/api/3/uiModifications/{uiModificationId}
# operationId: updateUiModification
# --contexts item shape: {issueTypeId: string, projectId: string, viewType: string}
export def "rest-3-ui-modifications update" [
  ui_modification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contexts: list # List of contexts of the UI modification. The maximum number of contexts is 1000. If provided, replaces all existing contexts. — item shape: {issueTypeId: string, projectId: string, viewType: string}
  --data: string # The data of the UI modification. The maximum size of the data is 50000 characters.
  --description: string # The description of the UI modification. The maximum length is 255 characters.
  --name: string # The name of the UI modification. The maximum length is 255 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ui_modification_id: (encode-path-segment $ui_modification_id)} | format pattern "/rest/api/3/uiModifications/{ui_modification_id}"))
  let req_body = {"contexts": $contexts, "data": $data, "description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get avatars
#
# GET /rest/api/3/universal_avatar/type/{type}/owner/{entityId}
# operationId: getAvatars
export def "rest-3-universal-avatar-type-owner get" [
  type: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<custom: table<fileName: string, id: string, isDeletable: bool, isSelected: bool, isSystemAvatar: bool, owner: string, urls: record>, system: table<fileName: string, id: string, isDeletable: bool, isSelected: bool, isSystemAvatar: bool, owner: string, urls: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), entity_id: (encode-path-segment $entity_id)} | format pattern "/rest/api/3/universal_avatar/type/{type}/owner/{entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Load avatar
#
# POST /rest/api/3/universal_avatar/type/{type}/owner/{entityId}
# operationId: storeAvatar
export def "rest-3-universal-avatar-type-owner create-store" [
  type: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x: int # The X coordinate of the top-left corner of the crop region. (format: int32, default: 0)
  --y: int # The Y coordinate of the top-left corner of the crop region. (format: int32, default: 0)
  --size: int # The length of each side of the crop region. (format: int32)
  --body: record
]: any -> record<fileName: string, id: string, isDeletable: bool, isSelected: bool, isSystemAvatar: bool, owner: string, urls: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "x" $x "scalar") (serialize-qp "y" $y "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), entity_id: (encode-path-segment $entity_id)} | format pattern "/rest/api/3/universal_avatar/type/{type}/owner/{entity_id}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $req_body
}

# Delete avatar
#
# DELETE /rest/api/3/universal_avatar/type/{type}/owner/{owningObjectId}/avatar/{id}
# operationId: deleteAvatar
export def "rest-3-universal-avatar-type-owner-avatar delete" [
  type: string
  owning_object_id: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), owning_object_id: (encode-path-segment $owning_object_id), id: (encode-path-segment $id)} | format pattern "/rest/api/3/universal_avatar/type/{type}/owner/{owning_object_id}/avatar/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get avatar image by type
#
# GET /rest/api/3/universal_avatar/view/type/{type}
# operationId: getAvatarImageByType
export def "rest-3-universal-avatar-view-type get-image" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --size: string@size-completer # The size of the avatar image. If not provided the default size is returned.
  --format: string@format-completer # The format to return the avatar image in. If not provided the original content format is returned.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/rest/api/3/universal_avatar/view/type/{type}") $qp)
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get avatar image by ID
#
# GET /rest/api/3/universal_avatar/view/type/{type}/avatar/{id}
# operationId: getAvatarImageByID
export def "rest-3-universal-avatar-view-type-avatar get-image" [
  type: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --size: string@size-completer # The size of the avatar image. If not provided the default size is returned.
  --format: string@format-completer # The format to return the avatar image in. If not provided the original content format is returned.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/rest/api/3/universal_avatar/view/type/{type}/avatar/{id}") $qp)
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get avatar image by owner
#
# GET /rest/api/3/universal_avatar/view/type/{type}/owner/{entityId}
# operationId: getAvatarImageByOwner
export def "rest-3-universal-avatar-view-type-owner get-image" [
  type: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --size: string@size-completer # The size of the avatar image. If not provided the default size is returned.
  --format: string@format-completer # The format to return the avatar image in. If not provided the original content format is returned.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), entity_id: (encode-path-segment $entity_id)} | format pattern "/rest/api/3/universal_avatar/view/type/{type}/owner/{entity_id}") $qp)
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user
#
# DELETE /rest/api/3/user
# operationId: removeUser
export def "rest-3-user delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --username: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --key: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user
#
# GET /rest/api/3/user
# operationId: getUser
export def "rest-3-user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. Required. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --username: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide) for details.
  --key: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide) for details.
  --expand: string # Use [expand](#expansion) to include additional information about users in the response. This parameter accepts a comma-separated list. Expand options include: * `groups` includes all groups and nested groups to which the user belongs. * `applicationRoles` includes details of all the applications to which the user has access.
]: nothing -> record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list<record>, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list<record>, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create user
#
# POST /rest/api/3/user
# operationId: createUser
export def "rest-3-user create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --application-keys: list<string> # Deprecated, do not use.
  --display-name: string # This property is no longer available. If the user has an Atlassian account, their display name is not changed. If the user does not have an Atlassian account, they are sent an email asking them set up an account.
  email_address: string # The email address for the user.
  --key: string # This property is no longer available. See the [migration guide](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --name: string # This property is no longer available. See the [migration guide](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --password: string # This property is no longer available. If the user has an Atlassian account, their password is not changed. If the user does not have an Atlassian account, they are sent an email asking them set up an account.
]: any -> record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list<record>, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list<record>, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/user")
  let req_body = {"applicationKeys": $application_keys, "displayName": $display_name, "emailAddress": $email_address, "key": $key, "name": $name, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Find users assignable to projects
#
# GET /rest/api/3/user/assignable/multiProjectSearch
# operationId: findBulkAssignableUsers
export def "rest-3-user-assignable-multi-project-search find-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query string that is matched against user attributes, such as `displayName` and `emailAddress`, to find relevant users. The string can match the prefix of the attribute's value. For example, *query=john* matches a user with a `displayName` of *John Smith* and a user with an `emailAddress` of *johnson@example.com*. Required, unless `accountId` is specified. (e.g. query)
  --username: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --account-id: string # A query string that is matched exactly against user `accountId`. Required, unless `query` is specified.
  --project-keys: string # A list of project keys (case sensitive). This parameter accepts a comma-separated list.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int32, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
]: nothing -> table<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "projectKeys" $project_keys "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/assignable/multiProjectSearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find users assignable to issues
#
# GET /rest/api/3/user/assignable/search
# operationId: findAssignableUsers
export def "rest-3-user-assignable-search find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query string that is matched against user attributes, such as `displayName`, and `emailAddress`, to find relevant users. The string can match the prefix of the attribute's value. For example, *query=john* matches a user with a `displayName` of *John Smith* and a user with an `emailAddress` of *johnson@example.com*. Required, unless `username` or `accountId` is specified. (e.g. query)
  --session-id: string # The sessionId of this request. SessionId is the same until the assignee is set.
  --username: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --account-id: string # A query string that is matched exactly against user `accountId`. Required, unless `query` is specified.
  --project: string # The project ID or project key (case sensitive). Required, unless `issueKey` is specified.
  --issue-key: string # The key of the issue. Required, unless `project` is specified.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int32, default: 0)
  --max-results: int # The maximum number of items to return. This operation may return less than the maximum number of items even if more are available. The operation fetches users up to the maximum and then, from the fetched users, returns only the users that can be assigned to the issue. (format: int32, default: 50)
  --action-descriptor-id: int # The ID of the transition. (format: int32)
  --recommend: oneof<nothing, bool> # default: false
]: nothing -> table<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sessionId" $session_id "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "issueKey" $issue_key "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "actionDescriptorId" $action_descriptor_id "scalar") (serialize-qp "recommend" $recommend "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/assignable/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk get users
#
# GET /rest/api/3/user/bulk
# operationId: bulkGetUsers
export def "rest-3-user-bulk get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 10)
  --username: list<string> # This parameter is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --key: list<string> # This parameter is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --account-id: list<string> # The account ID of a user. To specify multiple users, pass multiple `accountId` parameters. For example, `accountId=5b10a2844c20165700ede21g&accountId=5b10ac8d82e05b22cc7d4ef5`. (e.g. 5b10ac8d82e05b22cc7d4ef5)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "username" $username "multi") (serialize-qp "key" $key "multi") (serialize-qp "accountId" $account_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/bulk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account IDs for users
#
# GET /rest/api/3/user/bulk/migration
# operationId: bulkGetUsersMigration
export def "rest-3-user-bulk-migration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 10)
  --username: list<string> # Username of a user. To specify multiple users, pass multiple copies of this parameter. For example, `username=fred&username=barney`. Required if `key` isn't provided. Cannot be provided if `key` is present.
  --key: list<string> # Key of a user. To specify multiple users, pass multiple copies of this parameter. For example, `key=fred&key=barney`. Required if `username` isn't provided. Cannot be provided if `username` is present.
]: nothing -> table<accountId: string, key: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "username" $username "multi") (serialize-qp "key" $key "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/bulk/migration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset user default columns
#
# DELETE /rest/api/3/user/columns
# operationId: resetUserColumns
export def "rest-3-user-columns reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --username: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/columns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user default columns
#
# GET /rest/api/3/user/columns
# operationId: getUserDefaultColumns
export def "rest-3-user-columns get-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --username: string # This parameter is no longer available See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
]: nothing -> table<label: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/columns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set user default columns
#
# PUT /rest/api/3/user/columns
# operationId: setUserColumns
export def "rest-3-user-columns update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/columns" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $req_body
}

# Get user email
#
# GET /rest/api/3/user/email
# operationId: getUserEmail
export def "rest-3-user-email get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, `5b10ac8d82e05b22cc7d4ef5`.
]: nothing -> record<accountId: string, email: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/email" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user email bulk
#
# GET /rest/api/3/user/email/bulk
# operationId: getUserEmailBulk
export def "rest-3-user-email-bulk get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: list<string> # The account IDs of the users for which emails are required. An `accountId` is an identifier that uniquely identifies the user across all Atlassian products. For example, `5b10ac8d82e05b22cc7d4ef5`. Note, this should be treated as an opaque identifier (that is, do not assume any structure in the value).
]: nothing -> record<accountId: string, email: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/email/bulk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user groups
#
# GET /rest/api/3/user/groups
# operationId: getUserGroups
export def "rest-3-user-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --username: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --key: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
]: nothing -> table<groupId: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find users with permissions
#
# GET /rest/api/3/user/permission/search
# operationId: findUsersWithAllPermissions
export def "rest-3-user-permission-search find-with-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query string that is matched against user attributes, such as `displayName` and `emailAddress`, to find relevant users. The string can match the prefix of the attribute's value. For example, *query=john* matches a user with a `displayName` of *John Smith* and a user with an `emailAddress` of *johnson@example.com*. Required, unless `accountId` is specified. (e.g. query)
  --username: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --account-id: string # A query string that is matched exactly against user `accountId`. Required, unless `query` is specified.
  --permissions: string # A comma separated list of permissions. Permissions can be specified as any: * permission returned by [Get all permissions](#api-rest-api-3-permissions-get). * custom project permission added by Connect apps. * (deprecated) one of the following: * ASSIGNABLE\_USER * ASSIGN\_ISSUE * ATTACHMENT\_DELETE\_ALL * ATTACHMENT\_DELETE\_OWN * BROWSE * CLOSE\_ISSUE * COMMENT\_DELETE\_ALL * COMMENT\_DELETE\_OWN * COMMENT\_EDIT\_ALL * COMMENT\_EDIT\_OWN * COMMENT\_ISSUE * CREATE\_ATTACHMENT * CREATE\_ISSUE * DELETE\_ISSUE * EDIT\_ISSUE * LINK\_ISSUE * MANAGE\_WATCHER\_LIST * MODIFY\_REPORTER * MOVE\_ISSUE * PROJECT\_ADMIN * RESOLVE\_ISSUE * SCHEDULE\_ISSUE * SET\_ISSUE\_SECURITY * TRANSITION\_ISSUE * VIEW\_VERSION\_CONTROL * VIEW\_VOTERS\_AND\_WATCHERS * VIEW\_WORKFLOW\_READONLY * WORKLOG\_DELETE\_ALL * WORKLOG\_DELETE\_OWN * WORKLOG\_EDIT\_ALL * WORKLOG\_EDIT\_OWN * WORK\_ISSUE
  --issue-key: string # The issue key for the issue.
  --project-key: string # The project key for the project (case sensitive).
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int32, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
]: nothing -> table<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "permissions" $permissions "scalar") (serialize-qp "issueKey" $issue_key "scalar") (serialize-qp "projectKey" $project_key "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/permission/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find users for picker
#
# GET /rest/api/3/user/picker
# operationId: findUsersForPicker
export def "rest-3-user-picker find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query string that is matched against user attributes, such as `displayName`, and `emailAddress`, to find relevant users. The string can match the prefix of the attribute's value. For example, *query=john* matches a user with a `displayName` of *John Smith* and a user with an `emailAddress` of *johnson@example.com*.
  --max-results: int # The maximum number of items to return. The total number of matched users is returned in `total`. (format: int32, default: 50)
  --show-avatar: oneof<nothing, bool> # Include the URI to the user's avatar. (default: false)
  --exclude: list<string> # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --exclude-account-ids: list<string> # A list of account IDs to exclude from the search results. This parameter accepts a comma-separated list. Multiple account IDs can also be provided using an ampersand-separated list. For example, `excludeAccountIds=5b10a2844c20165700ede21g,5b10a0effa615349cb016cd8&excludeAccountIds=5b10ac8d82e05b22cc7d4ef5`. Cannot be provided with `exclude`.
  --avatar-size: string
  --exclude-connect-users: oneof<nothing, bool> # default: false
]: nothing -> record<header: string, total: int, users: table<accountId: string, avatarUrl: string, displayName: string, html: string, key: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "showAvatar" $show_avatar "scalar") (serialize-qp "exclude" $exclude "multi") (serialize-qp "excludeAccountIds" $exclude_account_ids "multi") (serialize-qp "avatarSize" $avatar_size "scalar") (serialize-qp "excludeConnectUsers" $exclude_connect_users "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/picker" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user property keys
#
# GET /rest/api/3/user/properties
# operationId: getUserPropertyKeys
export def "rest-3-user-properties get-property-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --user-key: string # This parameter is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --username: string # This parameter is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
]: nothing -> record<keys: table<key: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "userKey" $user_key "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/properties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user property
#
# DELETE /rest/api/3/user/properties/{propertyKey}
# operationId: deleteUserProperty
export def "rest-3-user-properties delete-property" [
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --user-key: string # This parameter is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --username: string # This parameter is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "userKey" $user_key "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/user/properties/{property_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user property
#
# GET /rest/api/3/user/properties/{propertyKey}
# operationId: getUserProperty
export def "rest-3-user-properties get-property" [
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --user-key: string # This parameter is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --username: string # This parameter is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
]: nothing -> record<key: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "userKey" $user_key "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/user/properties/{property_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set user property
#
# PUT /rest/api/3/user/properties/{propertyKey}
# operationId: setUserProperty
export def "rest-3-user-properties update-property" [
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*. (e.g. 5b10ac8d82e05b22cc7d4ef5)
  --user-key: string # This parameter is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --username: string # This parameter is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "userKey" $user_key "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({property_key: (encode-path-segment $property_key)} | format pattern "/rest/api/3/user/properties/{property_key}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Find users
#
# GET /rest/api/3/user/search
# operationId: findUsers
export def "rest-3-user-search find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query string that is matched against user attributes ( `displayName`, and `emailAddress`) to find relevant users. The string can match the prefix of the attribute's value. For example, *query=john* matches a user with a `displayName` of *John Smith* and a user with an `emailAddress` of *johnson@example.com*. Required, unless `accountId` or `property` is specified. (e.g. query)
  --username: string
  --account-id: string # A query string that is matched exactly against a user `accountId`. Required, unless `query` or `property` is specified.
  --start-at: int # The index of the first item to return in a page of filtered results (page offset). (format: int32, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --property: string # A query string used to search properties. Property keys are specified by path, so property keys containing dot (.) or equals (=) characters cannot be used. The query string cannot be specified using a JSON object. Example: To search for the value of `nested` from `{"something":{"nested":1,"other":2}}` use `thepropertykey.something.nested=1`. Required, unless `accountId` or `query` is specified.
]: nothing -> table<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "property" $property "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find users by query
#
# GET /rest/api/3/user/search/query
# operationId: findUsersByQuery
export def "rest-3-user-search-query find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The search query.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 100)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<accountId: string, accountType: string, active: bool, applicationRoles: record, avatarUrls: record, displayName: string, emailAddress: string, expand: string, groups: record, key: string, locale: string, name: string, self: string, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/search/query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find user keys by query
#
# GET /rest/api/3/user/search/query/key
# operationId: findUserKeysByQuery
export def "rest-3-user-search-query-key find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The search query.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 100)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<accountId: string, key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/search/query/key" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find users with browse permission
#
# GET /rest/api/3/user/viewissue/search
# operationId: findUsersWithBrowsePermission
export def "rest-3-user-viewissue-search find-with-browse-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query string that is matched against user attributes, such as `displayName` and `emailAddress`, to find relevant users. The string can match the prefix of the attribute's value. For example, *query=john* matches a user with a `displayName` of *John Smith* and a user with an `emailAddress` of *johnson@example.com*. Required, unless `accountId` is specified. (e.g. query)
  --username: string # This parameter is no longer available. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.
  --account-id: string # A query string that is matched exactly against user `accountId`. Required, unless `query` is specified.
  --issue-key: string # The issue key for the issue. Required, unless `projectKey` is specified.
  --project-key: string # The project key for the project (case sensitive). Required, unless `issueKey` is specified.
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int32, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
]: nothing -> table<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "issueKey" $issue_key "scalar") (serialize-qp "projectKey" $project_key "scalar") (serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/user/viewissue/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all users default
#
# GET /rest/api/3/users
# operationId: getAllUsersDefault
export def "rest-3-users get-list-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return. (format: int32, default: 0)
  --max-results: int # The maximum number of items to return. (format: int32, default: 50)
]: nothing -> table<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all users
#
# GET /rest/api/3/users/search
# operationId: getAllUsers
export def "rest-3-users-search get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return. (format: int32, default: 0)
  --max-results: int # The maximum number of items to return. (format: int32, default: 50)
]: nothing -> table<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/users/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create version
#
# POST /rest/api/3/version
# operationId: createVersion
# --operations item shape: {href?: string, iconClass?: string, id?: string, label?: string, styleClass?: string, title?: string, weight?: int}
export def "rest-3-version create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool> # Indicates that the version is archived. Optional when creating or updating a version.
  --description: string # The description of the version. Optional when creating or updating a version.
  --expand: string # Use [expand](em>#expansion) to include additional information about version in the response. This parameter accepts a comma-separated list. Expand options include: * `operations` Returns the list of operations available for this version. * `issuesstatus` Returns the count of issues in this version for each of the status categories *to do*, *in progress*, *done*, and *unmapped*. The *unmapped* property contains a count of issues with a status other than *to do*, *in progress*, and *done*. Optional for create and update.
  --move-unfixed-issues-to: string # The URL of the self link to the version to which all unfixed issues are moved when a version is released. Not applicable when creating a version. Optional when updating a version. (format: uri)
  --name: string # The unique name of the version. Required when creating a version. Optional when updating a version. The maximum length is 255 characters.
  --project: string # Deprecated. Use `projectId`.
  --project-id: int # The ID of the project to which this version is attached. Required when creating a version. Not applicable when updating a version. (format: int64)
  --release-date: string # The release date of the version. Expressed in ISO 8601 format (yyyy-mm-dd). Optional when creating or updating a version. (format: date)
  --released: oneof<nothing, bool> # Indicates that the version is released. If the version is released a request to release again is ignored. Not applicable when creating a version. Optional when updating a version.
  --start-date: string # The start date of the version. Expressed in ISO 8601 format (yyyy-mm-dd). Optional when creating or updating a version. (format: date)
]: any -> record<archived: bool, description: string, expand: string, id: string, issuesStatusForFixVersion: record<done: int, inProgress: int, toDo: int, unmapped: int>, moveUnfixedIssuesTo: string, name: string, operations: table<href: string, iconClass: string, id: string, label: string, styleClass: string, title: string, weight: int>, overdue: bool, project: string, projectId: int, releaseDate: string, released: bool, self: string, startDate: string, userReleaseDate: string, userStartDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/version")
  let req_body = {"archived": $archived, "description": $description, "expand": $expand, "moveUnfixedIssuesTo": $move_unfixed_issues_to, "name": $name, "project": $project, "projectId": $project_id, "releaseDate": $release_date, "released": $released, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete version
#
# DELETE /rest/api/3/version/{id}
# DEPRECATED
# operationId: deleteVersion
@deprecated
export def "rest-3-version delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --move-fix-issues-to: string # The ID of the version to update `fixVersion` to when the field contains the deleted version. The replacement version must be in the same project as the version being deleted and cannot be the version being deleted.
  --move-affected-issues-to: string # The ID of the version to update `affectedVersion` to when the field contains the deleted version. The replacement version must be in the same project as the version being deleted and cannot be the version being deleted.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "moveFixIssuesTo" $move_fix_issues_to "scalar") (serialize-qp "moveAffectedIssuesTo" $move_affected_issues_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/version/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get version
#
# GET /rest/api/3/version/{id}
# operationId: getVersion
export def "rest-3-version get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about version in the response. This parameter accepts a comma-separated list. Expand options include: * `operations` Returns the list of operations available for this version. * `issuesstatus` Returns the count of issues in this version for each of the status categories *to do*, *in progress*, *done*, and *unmapped*. The *unmapped* property represents the number of issues with a status other than *to do*, *in progress*, and *done*.
]: nothing -> record<archived: bool, description: string, expand: string, id: string, issuesStatusForFixVersion: record<done: int, inProgress: int, toDo: int, unmapped: int>, moveUnfixedIssuesTo: string, name: string, operations: table<href: string, iconClass: string, id: string, label: string, styleClass: string, title: string, weight: int>, overdue: bool, project: string, projectId: int, releaseDate: string, released: bool, self: string, startDate: string, userReleaseDate: string, userStartDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/version/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update version
#
# PUT /rest/api/3/version/{id}
# operationId: updateVersion
# --operations item shape: {href?: string, iconClass?: string, id?: string, label?: string, styleClass?: string, title?: string, weight?: int}
export def "rest-3-version update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool> # Indicates that the version is archived. Optional when creating or updating a version.
  --description: string # The description of the version. Optional when creating or updating a version.
  --expand: string # Use [expand](em>#expansion) to include additional information about version in the response. This parameter accepts a comma-separated list. Expand options include: * `operations` Returns the list of operations available for this version. * `issuesstatus` Returns the count of issues in this version for each of the status categories *to do*, *in progress*, *done*, and *unmapped*. The *unmapped* property contains a count of issues with a status other than *to do*, *in progress*, and *done*. Optional for create and update.
  --move-unfixed-issues-to: string # The URL of the self link to the version to which all unfixed issues are moved when a version is released. Not applicable when creating a version. Optional when updating a version. (format: uri)
  --name: string # The unique name of the version. Required when creating a version. Optional when updating a version. The maximum length is 255 characters.
  --project: string # Deprecated. Use `projectId`.
  --project-id: int # The ID of the project to which this version is attached. Required when creating a version. Not applicable when updating a version. (format: int64)
  --release-date: string # The release date of the version. Expressed in ISO 8601 format (yyyy-mm-dd). Optional when creating or updating a version. (format: date)
  --released: oneof<nothing, bool> # Indicates that the version is released. If the version is released a request to release again is ignored. Not applicable when creating a version. Optional when updating a version.
  --start-date: string # The start date of the version. Expressed in ISO 8601 format (yyyy-mm-dd). Optional when creating or updating a version. (format: date)
]: any -> record<archived: bool, description: string, expand: string, id: string, issuesStatusForFixVersion: record<done: int, inProgress: int, toDo: int, unmapped: int>, moveUnfixedIssuesTo: string, name: string, operations: table<href: string, iconClass: string, id: string, label: string, styleClass: string, title: string, weight: int>, overdue: bool, project: string, projectId: int, releaseDate: string, released: bool, self: string, startDate: string, userReleaseDate: string, userStartDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/version/{id}"))
  let req_body = {"archived": $archived, "description": $description, "expand": $expand, "moveUnfixedIssuesTo": $move_unfixed_issues_to, "name": $name, "project": $project, "projectId": $project_id, "releaseDate": $release_date, "released": $released, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Merge versions
#
# PUT /rest/api/3/version/{id}/mergeto/{moveIssuesTo}
# operationId: mergeVersions
export def "rest-3-version-mergeto update-merge" [
  id: string
  move_issues_to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), move_issues_to: (encode-path-segment $move_issues_to)} | format pattern "/rest/api/3/version/{id}/mergeto/{move_issues_to}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move version
#
# POST /rest/api/3/version/{id}/move
# operationId: moveVersion
export def "rest-3-version-move move" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # The URL (self link) of the version after which to place the moved version. Cannot be used with `position`. (format: uri)
  --position: string@position-completer-1 # An absolute position in which to place the moved version. Cannot be used with `after`.
]: any -> record<archived: bool, description: string, expand: string, id: string, issuesStatusForFixVersion: record<done: int, inProgress: int, toDo: int, unmapped: int>, moveUnfixedIssuesTo: string, name: string, operations: table<href: string, iconClass: string, id: string, label: string, styleClass: string, title: string, weight: int>, overdue: bool, project: string, projectId: int, releaseDate: string, released: bool, self: string, startDate: string, userReleaseDate: string, userStartDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/version/{id}/move"))
  let req_body = {"after": $after, "position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get version's related issues count
#
# GET /rest/api/3/version/{id}/relatedIssueCounts
# operationId: getVersionRelatedIssues
export def "rest-3-version-related-issue-counts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customFieldUsage: table<customFieldId: int, fieldName: string, issueCountWithVersionInCustomField: int>, issueCountWithCustomFieldsShowingVersion: int, issuesAffectedCount: int, issuesFixedCount: int, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/version/{id}/relatedIssueCounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete and replace version
#
# POST /rest/api/3/version/{id}/removeAndSwap
# operationId: deleteAndReplaceVersion
# --customFieldReplacementList item shape: {customFieldId?: int, moveTo?: int}
export def "rest-3-version-remove-and-swap delete-update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-field-replacement-list: list # An array of custom field IDs (`customFieldId`) and version IDs (`moveTo`) to update when the fields contain the deleted version. — item shape: {customFieldId?: int, moveTo?: int}
  --move-affected-issues-to: int # The ID of the version to update `affectedVersion` to when the field contains the deleted version. (format: int64)
  --move-fix-issues-to: int # The ID of the version to update `fixVersion` to when the field contains the deleted version. (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/version/{id}/removeAndSwap"))
  let req_body = {"customFieldReplacementList": $custom_field_replacement_list, "moveAffectedIssuesTo": $move_affected_issues_to, "moveFixIssuesTo": $move_fix_issues_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get version's unresolved issues count
#
# GET /rest/api/3/version/{id}/unresolvedIssueCount
# operationId: getVersionUnresolvedIssues
export def "rest-3-version-unresolved-issue-count get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<issuesCount: int, issuesUnresolvedCount: int, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/version/{id}/unresolvedIssueCount"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete webhooks by ID
#
# DELETE /rest/api/3/webhook
# operationId: deleteWebhookById
export def "rest-3-webhook delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook_ids: list<int> # A list of webhook IDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/webhook")
  let req_body = {"webhookIds": $webhook_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get dynamic webhooks for app
#
# GET /rest/api/3/webhook
# operationId: getDynamicWebhooksForApp
export def "rest-3-webhook get-dynamic-for-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 100)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<events: list, expirationDate: int, fieldIdsFilter: list, id: int, issuePropertyKeysFilter: list, jqlFilter: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/webhook" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register dynamic webhooks
#
# POST /rest/api/3/webhook
# operationId: registerDynamicWebhooks
# --webhooks item shape: {events: list<string>, fieldIdsFilter?: list<string>, issuePropertyKeysFilter?: list<string>, jqlFilter: string}
export def "rest-3-webhook create-dynamic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string # The URL that specifies where to send the webhooks. This URL must use the same base URL as the Connect app. Only a single URL per app is allowed to be registered.
  webhooks: list # A list of webhooks. — item shape: {events: list<string>, fieldIdsFilter?: list<string>, issuePropertyKeysFilter?: list<string>, jqlFilter: string}
]: any -> record<webhookRegistrationResult: table<createdWebhookId: int, errors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/webhook")
  let req_body = {"url": $url, "webhooks": $webhooks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get failed webhooks
#
# GET /rest/api/3/webhook/failed
# operationId: getFailedWebhooks
export def "rest-3-webhook-failed get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of webhooks to return per page. If obeying the maxResults directive would result in records with the same failure time being split across pages, the directive is ignored and all records with the same failure time included on the page. (format: int32)
  --after: int # The time after which any webhook failure must have occurred for the record to be returned, expressed as milliseconds since the UNIX epoch. (format: int64)
]: nothing -> record<maxResults: int, next: string, values: table<body: string, failureTime: int, id: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/webhook/failed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Extend webhook life
#
# PUT /rest/api/3/webhook/refresh
# operationId: refreshWebhooks
export def "rest-3-webhook-refresh refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook_ids: list<int> # A list of webhook IDs.
]: any -> record<expirationDate: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/webhook/refresh")
  let req_body = {"webhookIds": $webhook_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all workflows
#
# GET /rest/api/3/workflow
# DEPRECATED
# operationId: getAllWorkflows
@deprecated
export def "rest-3-workflow get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # The name of the workflow to be returned. Only one workflow can be specified.
]: nothing -> table<default: bool, description: string, lastModifiedDate: string, lastModifiedUser: string, lastModifiedUserAccountId: string, name: string, scope: record<project: record, type: string>, steps: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflowName" $workflow_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/workflow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create workflow
#
# POST /rest/api/3/workflow
# operationId: createWorkflow
# --statuses item shape: {id: string, properties?: record}
# --transitions item shape: {description?: string, from?: list<string>, name: string, properties?: record, rules?: any, screen?: any, to: string, type: "global"|"initial"|"directed"}
export def "rest-3-workflow create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the workflow. The maximum length is 1000 characters.
  name: string # The name of the workflow. The name must be unique. The maximum length is 255 characters. Characters can be separated by a whitespace but the name cannot start or end with a whitespace.
  statuses: list # The statuses of the workflow. Any status that does not include a transition is added to the workflow without a transition. — item shape: {id: string, properties?: record}
  transitions: list # The transitions of the workflow. For the request to be valid, these transitions must: * include one *initial* transition. * not use the same name for a *global* and *directed* transition. * have a unique name for each *global* transition. * have a unique 'to' status for each *global* transition. * have unique names for each transition from a status. * not have a 'from' status on *initial* and *global* transitions. * have a 'from' status on *directed* transitions. All the transition statuses must be included in `statuses`. — item shape: {description?: string, from?: list<string>, name: string, properties?: record, rules?: any, screen?: any, to: string, type: "global"|"initial"|"directed"}
]: any -> record<entityId: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/workflow")
  let req_body = {"description": $description, "name": $name, "statuses": $statuses, "transitions": $transitions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get workflow transition rule configurations
#
# GET /rest/api/3/workflow/rule/config
# operationId: getWorkflowTransitionRuleConfigurations
export def "rest-3-workflow-rule-config get-transition-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 10)
  --types: list<string> # The types of the transition rules to return.
  --keys: list<string> # The transition rule class keys, as defined in the Connect app descriptor, of the transition rules to return.
  --workflow-names: list<string> # EXPERIMENTAL: The list of workflow names to filter by.
  --with-tags: list<string> # EXPERIMENTAL: The list of `tags` to filter by.
  --draft: oneof<nothing, bool> # EXPERIMENTAL: Whether draft or published workflows are returned. If not provided, both workflow types are returned.
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts `transition`, which, for each rule, returns information about the transition the rule is assigned to.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<conditions: list, postFunctions: list, validators: list, workflowId: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "types" $types "multi") (serialize-qp "keys" $keys "multi") (serialize-qp "workflowNames" $workflow_names "multi") (serialize-qp "withTags" $with_tags "multi") (serialize-qp "draft" $draft "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/workflow/rule/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update workflow transition rule configurations
#
# PUT /rest/api/3/workflow/rule/config
# operationId: updateWorkflowTransitionRuleConfigurations
# --workflows item shape: {conditions?: list, postFunctions?: list, validators?: list, workflowId: record}
export def "rest-3-workflow-rule-config update-transition-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  workflows: list # The list of workflows with transition rules to update. — item shape: {conditions?: list, postFunctions?: list, validators?: list, workflowId: record}
]: any -> record<updateResults: table<ruleUpdateErrors: record, updateErrors: list, workflowId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/workflow/rule/config")
  let req_body = {"workflows": $workflows} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete workflow transition rule configurations
#
# PUT /rest/api/3/workflow/rule/config/delete
# operationId: deleteWorkflowTransitionRuleConfigurations
# --workflows item shape: {workflowId: record, workflowRuleIds: list<string>}
export def "rest-3-workflow-rule-config-delete delete-transition-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  workflows: list # The list of workflows with transition rules to delete. — item shape: {workflowId: record, workflowRuleIds: list<string>}
]: any -> record<updateResults: table<ruleUpdateErrors: record, updateErrors: list, workflowId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/workflow/rule/config/delete")
  let req_body = {"workflows": $workflows} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get workflows paginated
#
# GET /rest/api/3/workflow/search
# operationId: getWorkflowsPaginated
export def "rest-3-workflow-search get-paginated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
  --workflow-name: list<string> # The name of a workflow to return. To include multiple workflows, provide an ampersand-separated list. For example, `workflowName=name1&workflowName=name2`.
  --expand: string # Use [expand](#expansion) to include additional information in the response. This parameter accepts a comma-separated list. Expand options include: * `transitions` For each workflow, returns information about the transitions inside the workflow. * `transitions.rules` For each workflow transition, returns information about its rules. Transitions are included automatically if this expand is requested. * `transitions.properties` For each workflow transition, returns information about its properties. Transitions are included automatically if this expand is requested. * `statuses` For each workflow, returns information about the statuses inside the workflow. * `statuses.properties` For each workflow status, returns information about its properties. Statuses are included automatically if this expand is requested. * `default` For each workflow, returns information about whether this is the default workflow. * `schemes` For each workflow, returns information about the workflow schemes the workflow is assigned to. * `projects` For each workflow, returns information about the projects the workflow is assigned to, through workflow schemes. * `hasDraftWorkflow` For each workflow, returns information about whether the workflow has a draft version. * `operations` For each workflow, returns information about the actions that can be undertaken on the workflow.
  --query-string: string # String used to perform a case-insensitive partial match with workflow name.
  --order-by: string@order-by-completer-8 # [Order](#ordering) the results by a field: * `name` Sorts by workflow name. * `created` Sorts by create time. * `updated` Sorts by update time.
  --is-active: oneof<nothing, bool> # Filters active and inactive workflows.
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<created: string, description: string, hasDraftWorkflow: bool, id: record, isDefault: bool, operations: record, projects: list, schemes: list, statuses: list, transitions: list, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "workflowName" $workflow_name "multi") (serialize-qp "expand" $expand "scalar") (serialize-qp "queryString" $query_string "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "isActive" $is_active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/workflow/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete workflow transition property
#
# DELETE /rest/api/3/workflow/transitions/{transitionId}/properties
# operationId: deleteWorkflowTransitionProperty
export def "rest-3-workflow-transitions-properties delete-property" [
  transition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The name of the transition property to delete, also known as the name of the property.
  --workflow-name: string # The name of the workflow that the transition belongs to.
  --workflow-mode: string@workflow-mode-completer # The workflow status. Set to `live` for inactive workflows or `draft` for draft workflows. Active workflows cannot be edited.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "workflowName" $workflow_name "scalar") (serialize-qp "workflowMode" $workflow_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transition_id: (encode-path-segment $transition_id)} | format pattern "/rest/api/3/workflow/transitions/{transition_id}/properties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get workflow transition properties
#
# GET /rest/api/3/workflow/transitions/{transitionId}/properties
# operationId: getWorkflowTransitionProperties
export def "rest-3-workflow-transitions-properties get" [
  transition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-reserved-keys: oneof<nothing, bool> # Some properties with keys that have the *jira.* prefix are reserved, which means they are not editable. To include these properties in the results, set this parameter to *true*. (default: false)
  --key: string # The key of the property being returned, also known as the name of the property. If this parameter is not specified, all properties on the transition are returned.
  --workflow-name: string # The name of the workflow that the transition belongs to.
  --workflow-mode: string@workflow-mode-completer # The workflow status. Set to *live* for active and inactive workflows, or *draft* for draft workflows. (default: live)
]: nothing -> record<id: string, key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeReservedKeys" $include_reserved_keys "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "workflowName" $workflow_name "scalar") (serialize-qp "workflowMode" $workflow_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transition_id: (encode-path-segment $transition_id)} | format pattern "/rest/api/3/workflow/transitions/{transition_id}/properties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create workflow transition property
#
# POST /rest/api/3/workflow/transitions/{transitionId}/properties
# operationId: createWorkflowTransitionProperty
export def "rest-3-workflow-transitions-properties create-property" [
  transition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The key of the property being added, also known as the name of the property. Set this to the same value as the `key` defined in the request body.
  --workflow-name: string # The name of the workflow that the transition belongs to.
  --workflow-mode: string@workflow-mode-completer # The workflow status. Set to *live* for inactive workflows or *draft* for draft workflows. Active workflows cannot be edited. (default: live)
  value: string # The value of the transition property.
]: any -> record<id: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "workflowName" $workflow_name "scalar") (serialize-qp "workflowMode" $workflow_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transition_id: (encode-path-segment $transition_id)} | format pattern "/rest/api/3/workflow/transitions/{transition_id}/properties") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update workflow transition property
#
# PUT /rest/api/3/workflow/transitions/{transitionId}/properties
# operationId: updateWorkflowTransitionProperty
export def "rest-3-workflow-transitions-properties update-property" [
  transition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The key of the property being updated, also known as the name of the property. Set this to the same value as the `key` defined in the request body.
  --workflow-name: string # The name of the workflow that the transition belongs to.
  --workflow-mode: string@workflow-mode-completer # The workflow status. Set to `live` for inactive workflows or `draft` for draft workflows. Active workflows cannot be edited.
  value: string # The value of the transition property.
]: any -> record<id: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "workflowName" $workflow_name "scalar") (serialize-qp "workflowMode" $workflow_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transition_id: (encode-path-segment $transition_id)} | format pattern "/rest/api/3/workflow/transitions/{transition_id}/properties") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete inactive workflow
#
# DELETE /rest/api/3/workflow/{entityId}
# operationId: deleteInactiveWorkflow
export def "rest-3-workflow delete-inactive" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/rest/api/3/workflow/{entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all workflow schemes
#
# GET /rest/api/3/workflowscheme
# operationId: getAllWorkflowSchemes
export def "rest-3-workflowscheme get-list-workflow-schemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: int # The index of the first item to return in a page of results (page offset). (format: int64, default: 0)
  --max-results: int # The maximum number of items to return per page. (format: int32, default: 50)
]: nothing -> record<isLast: bool, maxResults: int, nextPage: string, self: string, startAt: int, total: int, values: table<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAt" $start_at "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/workflowscheme" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create workflow scheme
#
# POST /rest/api/3/workflowscheme
# operationId: createWorkflowScheme
export def "rest-3-workflowscheme create-workflow-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-workflow: string # The name of the default workflow for the workflow scheme. The default workflow has *All Unassigned Issue Types* assigned to it in Jira. If `defaultWorkflow` is not specified when creating a workflow scheme, it is set to *Jira Workflow (jira)*.
  --description: string # The description of the workflow scheme.
  --issue-type-mappings: record # The issue type to workflow mappings, where each mapping is an issue type ID and workflow name pair. Note that an issue type can only be mapped to one workflow in a workflow scheme.
  --name: string # The name of the workflow scheme. The name must be unique. The maximum length is 255 characters. Required when creating a workflow scheme.
  --update-draft-if-needed: oneof<nothing, bool> # Whether to create or update a draft workflow scheme when updating an active workflow scheme. An active workflow scheme is a workflow scheme that is used by at least one project. The following examples show how this property works: * Update an active workflow scheme with `updateDraftIfNeeded` set to `true`: If a draft workflow scheme exists, it is updated. Otherwise, a draft workflow scheme is created. * Update an active workflow scheme with `updateDraftIfNeeded` set to `false`: An error is returned, as active workflow schemes cannot be updated. * Update an inactive workflow scheme with `updateDraftIfNeeded` set to `true`: The workflow scheme is updated, as inactive workflow schemes do not require drafts to update. Defaults to `false`.
]: any -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/workflowscheme")
  let req_body = {"defaultWorkflow": $default_workflow, "description": $description, "issueTypeMappings": $issue_type_mappings, "name": $name, "updateDraftIfNeeded": $update_draft_if_needed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get workflow scheme project associations
#
# GET /rest/api/3/workflowscheme/project
# operationId: getWorkflowSchemeProjectAssociations
export def "rest-3-workflowscheme-project get-workflow-scheme-associations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: list<int> # The ID of a project to return the workflow schemes for. To include multiple projects, provide an ampersand-Jim: oneseparated list. For example, `projectId=10000&projectId=10001`.
]: nothing -> record<values: table<projectIds: list, workflowScheme: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/workflowscheme/project" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign workflow scheme to project
#
# PUT /rest/api/3/workflowscheme/project
# operationId: assignSchemeToProject
export def "rest-3-workflowscheme-project assign-scheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project_id: string # The ID of the project.
  --workflow-scheme-id: string # The ID of the workflow scheme. If the workflow scheme ID is `null`, the operation assigns the default workflow scheme.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/api/3/workflowscheme/project")
  let req_body = {"projectId": $project_id, "workflowSchemeId": $workflow_scheme_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete workflow scheme
#
# DELETE /rest/api/3/workflowscheme/{id}
# operationId: deleteWorkflowScheme
export def "rest-3-workflowscheme delete-workflow-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get workflow scheme
#
# GET /rest/api/3/workflowscheme/{id}
# operationId: getWorkflowScheme
export def "rest-3-workflowscheme get-workflow-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-draft-if-exists: oneof<nothing, bool> # Returns the workflow scheme's draft rather than scheme itself, if set to true. If the workflow scheme does not have a draft, then the workflow scheme is returned. (default: false)
]: nothing -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "returnDraftIfExists" $return_draft_if_exists "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update workflow scheme
#
# PUT /rest/api/3/workflowscheme/{id}
# operationId: updateWorkflowScheme
export def "rest-3-workflowscheme update-workflow-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-workflow: string # The name of the default workflow for the workflow scheme. The default workflow has *All Unassigned Issue Types* assigned to it in Jira. If `defaultWorkflow` is not specified when creating a workflow scheme, it is set to *Jira Workflow (jira)*.
  --description: string # The description of the workflow scheme.
  --issue-type-mappings: record # The issue type to workflow mappings, where each mapping is an issue type ID and workflow name pair. Note that an issue type can only be mapped to one workflow in a workflow scheme.
  --name: string # The name of the workflow scheme. The name must be unique. The maximum length is 255 characters. Required when creating a workflow scheme.
  --update-draft-if-needed: oneof<nothing, bool> # Whether to create or update a draft workflow scheme when updating an active workflow scheme. An active workflow scheme is a workflow scheme that is used by at least one project. The following examples show how this property works: * Update an active workflow scheme with `updateDraftIfNeeded` set to `true`: If a draft workflow scheme exists, it is updated. Otherwise, a draft workflow scheme is created. * Update an active workflow scheme with `updateDraftIfNeeded` set to `false`: An error is returned, as active workflow schemes cannot be updated. * Update an inactive workflow scheme with `updateDraftIfNeeded` set to `true`: The workflow scheme is updated, as inactive workflow schemes do not require drafts to update. Defaults to `false`.
]: any -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}"))
  let req_body = {"defaultWorkflow": $default_workflow, "description": $description, "issueTypeMappings": $issue_type_mappings, "name": $name, "updateDraftIfNeeded": $update_draft_if_needed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create draft workflow scheme
#
# POST /rest/api/3/workflowscheme/{id}/createdraft
# operationId: createWorkflowSchemeDraftFromParent
export def "rest-3-workflowscheme-createdraft create-workflow-scheme-draft-from-parent" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/createdraft"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete default workflow
#
# DELETE /rest/api/3/workflowscheme/{id}/default
# operationId: deleteDefaultWorkflow
export def "rest-3-workflowscheme-default delete-workflow" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-draft-if-needed: oneof<nothing, bool> # Set to true to create or update the draft of a workflow scheme and delete the mapping from the draft, when the workflow scheme cannot be edited. Defaults to `false`.
]: nothing -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateDraftIfNeeded" $update_draft_if_needed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/default") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default workflow
#
# GET /rest/api/3/workflowscheme/{id}/default
# operationId: getDefaultWorkflow
export def "rest-3-workflowscheme-default get-workflow" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-draft-if-exists: oneof<nothing, bool> # Set to `true` to return the default workflow for the workflow scheme's draft rather than scheme itself. If the workflow scheme does not have a draft, then the default workflow for the workflow scheme is returned. (default: false)
]: nothing -> record<updateDraftIfNeeded: bool, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "returnDraftIfExists" $return_draft_if_exists "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/default") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update default workflow
#
# PUT /rest/api/3/workflowscheme/{id}/default
# operationId: updateDefaultWorkflow
export def "rest-3-workflowscheme-default update-workflow" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-draft-if-needed: oneof<nothing, bool> # Whether a draft workflow scheme is created or updated when updating an active workflow scheme. The draft is updated with the new default workflow. Defaults to `false`.
  workflow: string # The name of the workflow to set as the default workflow.
]: any -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/default"))
  let req_body = {"updateDraftIfNeeded": $update_draft_if_needed, "workflow": $workflow} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete draft workflow scheme
#
# DELETE /rest/api/3/workflowscheme/{id}/draft
# operationId: deleteWorkflowSchemeDraft
export def "rest-3-workflowscheme-draft delete-workflow-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/draft"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get draft workflow scheme
#
# GET /rest/api/3/workflowscheme/{id}/draft
# operationId: getWorkflowSchemeDraft
export def "rest-3-workflowscheme-draft get-workflow-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/draft"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update draft workflow scheme
#
# PUT /rest/api/3/workflowscheme/{id}/draft
# operationId: updateWorkflowSchemeDraft
export def "rest-3-workflowscheme-draft update-workflow-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-workflow: string # The name of the default workflow for the workflow scheme. The default workflow has *All Unassigned Issue Types* assigned to it in Jira. If `defaultWorkflow` is not specified when creating a workflow scheme, it is set to *Jira Workflow (jira)*.
  --description: string # The description of the workflow scheme.
  --issue-type-mappings: record # The issue type to workflow mappings, where each mapping is an issue type ID and workflow name pair. Note that an issue type can only be mapped to one workflow in a workflow scheme.
  --name: string # The name of the workflow scheme. The name must be unique. The maximum length is 255 characters. Required when creating a workflow scheme.
  --update-draft-if-needed: oneof<nothing, bool> # Whether to create or update a draft workflow scheme when updating an active workflow scheme. An active workflow scheme is a workflow scheme that is used by at least one project. The following examples show how this property works: * Update an active workflow scheme with `updateDraftIfNeeded` set to `true`: If a draft workflow scheme exists, it is updated. Otherwise, a draft workflow scheme is created. * Update an active workflow scheme with `updateDraftIfNeeded` set to `false`: An error is returned, as active workflow schemes cannot be updated. * Update an inactive workflow scheme with `updateDraftIfNeeded` set to `true`: The workflow scheme is updated, as inactive workflow schemes do not require drafts to update. Defaults to `false`.
]: any -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/draft"))
  let req_body = {"defaultWorkflow": $default_workflow, "description": $description, "issueTypeMappings": $issue_type_mappings, "name": $name, "updateDraftIfNeeded": $update_draft_if_needed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete draft default workflow
#
# DELETE /rest/api/3/workflowscheme/{id}/draft/default
# operationId: deleteDraftDefaultWorkflow
export def "rest-3-workflowscheme-draft-default delete-workflow" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/draft/default"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get draft default workflow
#
# GET /rest/api/3/workflowscheme/{id}/draft/default
# operationId: getDraftDefaultWorkflow
export def "rest-3-workflowscheme-draft-default get-workflow" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<updateDraftIfNeeded: bool, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/draft/default"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update draft default workflow
#
# PUT /rest/api/3/workflowscheme/{id}/draft/default
# operationId: updateDraftDefaultWorkflow
export def "rest-3-workflowscheme-draft-default update-workflow" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-draft-if-needed: oneof<nothing, bool> # Whether a draft workflow scheme is created or updated when updating an active workflow scheme. The draft is updated with the new default workflow. Defaults to `false`.
  workflow: string # The name of the workflow to set as the default workflow.
]: any -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/draft/default"))
  let req_body = {"updateDraftIfNeeded": $update_draft_if_needed, "workflow": $workflow} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete workflow for issue type in draft workflow scheme
#
# DELETE /rest/api/3/workflowscheme/{id}/draft/issuetype/{issueType}
# operationId: deleteWorkflowSchemeDraftIssueType
export def "rest-3-workflowscheme-draft-issuetype delete-workflow-scheme-issue-type" [
  id: int
  issue_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), issue_type: (encode-path-segment $issue_type)} | format pattern "/rest/api/3/workflowscheme/{id}/draft/issuetype/{issue_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get workflow for issue type in draft workflow scheme
#
# GET /rest/api/3/workflowscheme/{id}/draft/issuetype/{issueType}
# operationId: getWorkflowSchemeDraftIssueType
export def "rest-3-workflowscheme-draft-issuetype get-workflow-scheme-issue-type" [
  id: int
  issue_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<issueType: string, updateDraftIfNeeded: bool, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), issue_type: (encode-path-segment $issue_type)} | format pattern "/rest/api/3/workflowscheme/{id}/draft/issuetype/{issue_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set workflow for issue type in draft workflow scheme
#
# PUT /rest/api/3/workflowscheme/{id}/draft/issuetype/{issueType}
# operationId: setWorkflowSchemeDraftIssueType
export def "rest-3-workflowscheme-draft-issuetype update-workflow-scheme-issue-type" [
  id: int
  issue_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-issue-type: string # The ID of the issue type. Not required if updating the issue type-workflow mapping.
  --update-draft-if-needed: oneof<nothing, bool> # Set to true to create or update the draft of a workflow scheme and update the mapping in the draft, when the workflow scheme cannot be edited. Defaults to `false`. Only applicable when updating the workflow-issue types mapping.
  --workflow: string # The name of the workflow.
]: any -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), issue_type: (encode-path-segment $issue_type)} | format pattern "/rest/api/3/workflowscheme/{id}/draft/issuetype/{issue_type}"))
  let req_body = {"issueType": $body_issue_type, "updateDraftIfNeeded": $update_draft_if_needed, "workflow": $workflow} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Publish draft workflow scheme
#
# POST /rest/api/3/workflowscheme/{id}/draft/publish
# operationId: publishDraftWorkflowScheme
# --statusMappings item shape: {issueTypeId: string, newStatusId: string, statusId: string}
export def "rest-3-workflowscheme-draft-publish publish-workflow-scheme" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate-only: oneof<nothing, bool> # Whether the request only performs a validation. (default: false)
  --status-mappings: list # Mappings of statuses to new statuses for issue types. — item shape: {issueTypeId: string, newStatusId: string, statusId: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validateOnly" $validate_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/draft/publish") $qp)
  let req_body = {"statusMappings": $status_mappings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete issue types for workflow in draft workflow scheme
#
# DELETE /rest/api/3/workflowscheme/{id}/draft/workflow
# operationId: deleteDraftWorkflowMapping
export def "rest-3-workflowscheme-draft-workflow delete-mapping" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # The name of the workflow.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflowName" $workflow_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/draft/workflow") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue types for workflows in draft workflow scheme
#
# GET /rest/api/3/workflowscheme/{id}/draft/workflow
# operationId: getDraftWorkflow
export def "rest-3-workflowscheme-draft-workflow get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # The name of a workflow in the scheme. Limits the results to the workflow-issue type mapping for the specified workflow.
]: nothing -> record<defaultMapping: bool, issueTypes: list<string>, updateDraftIfNeeded: bool, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflowName" $workflow_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/draft/workflow") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set issue types for workflow in workflow scheme
#
# PUT /rest/api/3/workflowscheme/{id}/draft/workflow
# operationId: updateDraftWorkflowMapping
export def "rest-3-workflowscheme-draft-workflow update-mapping" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # The name of the workflow.
  --default-mapping: oneof<nothing, bool> # Whether the workflow is the default workflow for the workflow scheme.
  --issue-types: list<string> # The list of issue type IDs.
  --update-draft-if-needed: oneof<nothing, bool> # Whether a draft workflow scheme is created or updated when updating an active workflow scheme. The draft is updated with the new workflow-issue types mapping. Defaults to `false`.
  --workflow: string # The name of the workflow. Optional if updating the workflow-issue types mapping.
]: any -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflowName" $workflow_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/draft/workflow") $qp)
  let req_body = {"defaultMapping": $default_mapping, "issueTypes": $issue_types, "updateDraftIfNeeded": $update_draft_if_needed, "workflow": $workflow} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete workflow for issue type in workflow scheme
#
# DELETE /rest/api/3/workflowscheme/{id}/issuetype/{issueType}
# operationId: deleteWorkflowSchemeIssueType
export def "rest-3-workflowscheme-issuetype delete-workflow-scheme-issue-type" [
  id: int
  issue_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-draft-if-needed: oneof<nothing, bool> # Set to true to create or update the draft of a workflow scheme and update the mapping in the draft, when the workflow scheme cannot be edited. Defaults to `false`.
]: nothing -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateDraftIfNeeded" $update_draft_if_needed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), issue_type: (encode-path-segment $issue_type)} | format pattern "/rest/api/3/workflowscheme/{id}/issuetype/{issue_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get workflow for issue type in workflow scheme
#
# GET /rest/api/3/workflowscheme/{id}/issuetype/{issueType}
# operationId: getWorkflowSchemeIssueType
export def "rest-3-workflowscheme-issuetype get-workflow-scheme-issue-type" [
  id: int
  issue_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-draft-if-exists: oneof<nothing, bool> # Returns the mapping from the workflow scheme's draft rather than the workflow scheme, if set to true. If no draft exists, the mapping from the workflow scheme is returned. (default: false)
]: nothing -> record<issueType: string, updateDraftIfNeeded: bool, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "returnDraftIfExists" $return_draft_if_exists "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), issue_type: (encode-path-segment $issue_type)} | format pattern "/rest/api/3/workflowscheme/{id}/issuetype/{issue_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set workflow for issue type in workflow scheme
#
# PUT /rest/api/3/workflowscheme/{id}/issuetype/{issueType}
# operationId: setWorkflowSchemeIssueType
export def "rest-3-workflowscheme-issuetype update-workflow-scheme-issue-type" [
  id: int
  issue_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-issue-type: string # The ID of the issue type. Not required if updating the issue type-workflow mapping.
  --update-draft-if-needed: oneof<nothing, bool> # Set to true to create or update the draft of a workflow scheme and update the mapping in the draft, when the workflow scheme cannot be edited. Defaults to `false`. Only applicable when updating the workflow-issue types mapping.
  --workflow: string # The name of the workflow.
]: any -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), issue_type: (encode-path-segment $issue_type)} | format pattern "/rest/api/3/workflowscheme/{id}/issuetype/{issue_type}"))
  let req_body = {"issueType": $body_issue_type, "updateDraftIfNeeded": $update_draft_if_needed, "workflow": $workflow} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete issue types for workflow in workflow scheme
#
# DELETE /rest/api/3/workflowscheme/{id}/workflow
# operationId: deleteWorkflowMapping
export def "rest-3-workflowscheme-workflow delete-mapping" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # The name of the workflow.
  --update-draft-if-needed: oneof<nothing, bool> # Set to true to create or update the draft of a workflow scheme and delete the mapping from the draft, when the workflow scheme cannot be edited. Defaults to `false`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflowName" $workflow_name "scalar") (serialize-qp "updateDraftIfNeeded" $update_draft_if_needed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/workflow") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue types for workflows in workflow scheme
#
# GET /rest/api/3/workflowscheme/{id}/workflow
# operationId: getWorkflow
export def "rest-3-workflowscheme-workflow get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # The name of a workflow in the scheme. Limits the results to the workflow-issue type mapping for the specified workflow.
  --return-draft-if-exists: oneof<nothing, bool> # Returns the mapping from the workflow scheme's draft rather than the workflow scheme, if set to true. If no draft exists, the mapping from the workflow scheme is returned. (default: false)
]: nothing -> record<defaultMapping: bool, issueTypes: list<string>, updateDraftIfNeeded: bool, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflowName" $workflow_name "scalar") (serialize-qp "returnDraftIfExists" $return_draft_if_exists "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/workflow") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set issue types for workflow in workflow scheme
#
# PUT /rest/api/3/workflowscheme/{id}/workflow
# operationId: updateWorkflowMapping
export def "rest-3-workflowscheme-workflow update-mapping" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-name: string # The name of the workflow.
  --default-mapping: oneof<nothing, bool> # Whether the workflow is the default workflow for the workflow scheme.
  --issue-types: list<string> # The list of issue type IDs.
  --update-draft-if-needed: oneof<nothing, bool> # Whether a draft workflow scheme is created or updated when updating an active workflow scheme. The draft is updated with the new workflow-issue types mapping. Defaults to `false`.
  --workflow: string # The name of the workflow. Optional if updating the workflow-issue types mapping.
]: any -> record<defaultWorkflow: string, description: string, draft: bool, id: int, issueTypeMappings: record, issueTypes: record, lastModified: string, lastModifiedUser: record<accountId: string, accountType: string, active: bool, applicationRoles: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, avatarUrls: record<16x16: string, 24x24: string, 32x32: string, 48x48: string>, displayName: string, emailAddress: string, expand: string, groups: record<callback: record, items: list, max_results: int, pagingCallback: record, size: int>, key: string, locale: string, name: string, self: string, timeZone: string>, name: string, originalDefaultWorkflow: string, originalIssueTypeMappings: record, self: string, updateDraftIfNeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflowName" $workflow_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/api/3/workflowscheme/{id}/workflow") $qp)
  let req_body = {"defaultMapping": $default_mapping, "issueTypes": $issue_types, "updateDraftIfNeeded": $update_draft_if_needed, "workflow": $workflow} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get IDs of deleted worklogs
#
# GET /rest/api/3/worklog/deleted
# operationId: getIdsOfWorklogsDeletedSince
export def "rest-3-worklog-deleted get-of-since" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: int # The date and time, as a UNIX timestamp in milliseconds, after which deleted worklogs are returned. (format: int64, default: 0)
]: nothing -> record<lastPage: bool, nextPage: string, self: string, since: int, until: int, values: table<properties: list, updatedTime: int, worklogId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/worklog/deleted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get worklogs
#
# POST /rest/api/3/worklog/list
# operationId: getWorklogsForIds
export def "rest-3-worklog-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Use [expand](#expansion) to include additional information about worklogs in the response. This parameter accepts `properties` that returns the properties of each worklog. (default: )
  ids: list<int> # A list of worklog IDs.
]: any -> table<author: record<accountId: string, accountType: string, active: bool, avatarUrls: record, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, comment: any, created: string, id: string, issueId: string, properties: list<record>, self: string, started: string, timeSpent: string, timeSpentSeconds: int, updateAuthor: record<accountId: string, accountType: string, active: bool, avatarUrls: record, displayName: string, emailAddress: string, key: string, name: string, self: string, timeZone: string>, updated: string, visibility: record<identifier: string, type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/worklog/list" $qp)
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get IDs of updated worklogs
#
# GET /rest/api/3/worklog/updated
# operationId: getIdsOfWorklogsModifiedSince
export def "rest-3-worklog-updated get-of-modified-since" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: int # The date and time, as a UNIX timestamp in milliseconds, after which updated worklogs are returned. (format: int64, default: 0)
  --expand: string # Use [expand](#expansion) to include additional information about worklogs in the response. This parameter accepts `properties` that returns the properties of each worklog. (default: )
]: nothing -> record<lastPage: bool, nextPage: string, self: string, since: int, until: int, values: table<properties: list, updatedTime: int, worklogId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/api/3/worklog/updated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get app properties
#
# GET /rest/atlassian-connect/1/addons/{addonKey}/properties
# operationId: AddonPropertiesResource.getAddonProperties_get
export def "rest-atlassian-connect-1-addons-properties get-get" [
  addon_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keys: table<key: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({addon_key: (encode-path-segment $addon_key)} | format pattern "/rest/atlassian-connect/1/addons/{addon_key}/properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete app property
#
# DELETE /rest/atlassian-connect/1/addons/{addonKey}/properties/{propertyKey}
# operationId: AddonPropertiesResource.deleteAddonProperty_delete
export def "rest-atlassian-connect-1-addons-properties delete-property-delete" [
  addon_key: string
  property_key: string
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
  let full_url = (build-url $base ({addon_key: (encode-path-segment $addon_key), property_key: (encode-path-segment $property_key)} | format pattern "/rest/atlassian-connect/1/addons/{addon_key}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get app property
#
# GET /rest/atlassian-connect/1/addons/{addonKey}/properties/{propertyKey}
# operationId: AddonPropertiesResource.getAddonProperty_get
export def "rest-atlassian-connect-1-addons-properties get-property-get" [
  addon_key: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({addon_key: (encode-path-segment $addon_key), property_key: (encode-path-segment $property_key)} | format pattern "/rest/atlassian-connect/1/addons/{addon_key}/properties/{property_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set app property
#
# PUT /rest/atlassian-connect/1/addons/{addonKey}/properties/{propertyKey}
# operationId: AddonPropertiesResource.putAddonProperty_put
export def "rest-atlassian-connect-1-addons-properties update-property-update" [
  addon_key: string
  property_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({addon_key: (encode-path-segment $addon_key), property_key: (encode-path-segment $property_key)} | format pattern "/rest/atlassian-connect/1/addons/{addon_key}/properties/{property_key}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove modules
#
# DELETE /rest/atlassian-connect/1/app/module/dynamic
# operationId: DynamicModulesResource.removeModules_delete
export def "rest-atlassian-connect-1-app-module-dynamic delete-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --module-key: list<string> # The key of the module to remove. To include multiple module keys, provide multiple copies of this parameter. For example, `moduleKey=dynamic-attachment-entity-property&moduleKey=dynamic-select-field`. Nonexistent keys are ignored.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "moduleKey" $module_key "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/atlassian-connect/1/app/module/dynamic" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get modules
#
# GET /rest/atlassian-connect/1/app/module/dynamic
# operationId: DynamicModulesResource.getModules_get
export def "rest-atlassian-connect-1-app-module-dynamic get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<modules: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/atlassian-connect/1/app/module/dynamic")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register modules
#
# POST /rest/atlassian-connect/1/app/module/dynamic
# operationId: DynamicModulesResource.registerModules_post
export def "rest-atlassian-connect-1-app-module-dynamic create-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  modules: list # A list of app modules in the same format as the `modules` property in the [app descriptor](https://developer.atlassian.com/cloud/jira/platform/app-descriptor/).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/atlassian-connect/1/app/module/dynamic")
  let req_body = {"modules": $modules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk update custom field value
#
# PUT /rest/atlassian-connect/1/migration/field
# operationId: AppIssueFieldValueUpdateResource.updateIssueFields_put
# --updateValueList item shape: {_type: "StringIssueField"|"NumberIssueField"|"RichTextIssueField"|"SingleSelectIssueField"|"MultiSelectIssueField"|"TextIssueField", fieldID: int, issueID: int, number?: float, optionID?: string, richText?: string, string?: string, text?: string}
export def "rest-atlassian-connect-1-migration-field update-issue-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --atlassian-transfer-id: string # The ID of the transfer.
  --update-value-list: list # The list of custom field update details. — item shape: {_type: "StringIssueField"|"NumberIssueField"|"RichTextIssueField"|"SingleSelectIssueField"|"MultiSelectIssueField"|"TextIssueField", fieldID: int, issueID: int, number?: float, optionID?: string, richText?: string, string?: string, text?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/atlassian-connect/1/migration/field")
  let req_body = {"updateValueList": $update_value_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Atlassian-Transfer-Id": $atlassian_transfer_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk update entity properties
#
# PUT /rest/atlassian-connect/1/migration/properties/{entityType}
# operationId: MigrationResource.updateEntityPropertiesValue_put
export def "rest-atlassian-connect-1-migration-properties update-entity-value-update" [
  entity_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --atlassian-transfer-id: string # The app migration transfer ID.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({entity_type: (encode-path-segment $entity_type)} | format pattern "/rest/atlassian-connect/1/migration/properties/{entity_type}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Atlassian-Transfer-Id": $atlassian_transfer_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get workflow transition rule configurations
#
# POST /rest/atlassian-connect/1/migration/workflow/rule/search
# operationId: MigrationResource.workflowRuleSearch_post
export def "rest-atlassian-connect-1-migration-workflow-rule-search create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --atlassian-transfer-id: string # The app migration transfer ID.
  --expand: string # Use expand to include additional information in the response. This parameter accepts `transition` which, for each rule, returns information about the transition the rule is assigned to. (e.g. transition)
  rule_ids: list<string> # The list of workflow rule IDs.
  workflow_entity_id: string # The workflow ID. (format: uuid, e.g. a498d711-685d-428d-8c3e-bc03bb450ea7)
]: any -> record<invalidRules: list<string>, validRules: table<conditions: list, postFunctions: list, validators: list, workflowId: record>, workflowEntityId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/atlassian-connect/1/migration/workflow/rule/search")
  let req_body = {"expand": $expand, "ruleIds": $rule_ids, "workflowEntityId": $workflow_entity_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Atlassian-Transfer-Id": $atlassian_transfer_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
