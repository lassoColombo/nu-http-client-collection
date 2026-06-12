# Auto-generated client for The Confluence Cloud REST API v1.0.0
# Source: https://developer.atlassian.com/cloud/confluence/swagger.v3.json
# Auth: --token flag or $env.THE_CONFLUENCE_CLOUD_REST_API_TOKEN

const BASE_URL = "http://localhost//your-domain.atlassian.net"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o THE_CONFLUENCE_CLOUD_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["http://localhost//your-domain.atlassian.net"] }
def auth-scheme-completer [] { ["basic" "bearer"] }

# Completers for enum parameters
def format-completer [] { ["csv" "zip"] }
def accept-completer [] { ["application/zip" "text/csv"] }
def units-completer [] { ["CENTURIES" "DAYS" "DECADES" "ERAS" "FOREVER" "HALF_DAYS" "HOURS" "MICROS" "MILLENNIA" "MILLIS" "MINUTES" "MONTHS" "NANOS" "SECONDS" "WEEKS" "YEARS"] }
def units-completer-1 [] { ["CENTURIES" "DAYS" "DECADES" "HALF_DAYS" "HOURS" "MICROS" "MILLIS" "MINUTES" "MONTHS" "NANOS" "SECONDS" "WEEKS" "YEARS"] }
def type-completer [] { ["page"] }
def status-completer [] { ["current"] }
def status-completer-1 [] { ["current" "draft"] }
def depth-completer [] { ["<any positive integer argument in the range of 1 and 100>" "all" "root"] }
def embeddedContentRender-completer [] { ["current" "version-at-save"] }
def operation-completer [] { ["delete" "read" "update"] }
def status-completer-2 [] { ["archived" "current" "draft"] }
def operationKey-completer [] { ["restore"] }
def representation-completer [] { ["anonymous_export_view" "atlas_doc_format" "editor" "editor2" "export_view" "plain" "raw" "storage" "styled_view" "view" "wiki"] }
def type-completer-1 [] { ["attachment" "blogpost" "page" "page_template"] }
def accessType-completer [] { ["admin" "site-admin" "user"] }
def excerpt-completer [] { ["highlight" "highlight_unescaped" "indexed" "indexed_unescaped" "none"] }
def sitePermissionTypeFilter-completer [] { ["all" "externalCollaborator" "none"] }
def lookAndFeelType-completer [] { ["custom" "global" "theme"] }
def contentMode-completer [] { ["compact" "standard"] }
def prefix-completer [] { ["global" "my" "team"] }
def templateType-completer [] { ["page"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "wiki-rest-audit get" } } | get name | first)
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

# Get audit records
#
# GET /wiki/rest/api/audit
# operationId: getAuditRecords
export def "wiki-rest-audit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # Filters the results to the records on or after the `startDate`. The `startDate` must be specified as [epoch time](https://www.epochconverter.com/) in milliseconds.
  --endDate: string # Filters the results to the records on or before the `endDate`. The `endDate` must be specified as [epoch time](https://www.epochconverter.com/) in milliseconds.
  --searchString: string # Filters the results to records that have string property values matching the `searchString`.
  --start: int # The starting index of the returned records. (format: int32, default: 0)
  --limit: int # The maximum number of records to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 1000)
]: nothing -> record<results: table<author: record, remoteAddress: string, creationDate: int, summary: string, description: string, category: string, sysAdmin: bool, superAdmin: bool, affectedObject: record, changedValues: list, associatedObjects: list>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "searchString" $searchString "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/audit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create audit record
#
# POST /wiki/rest/api/audit
# operationId: createAuditRecord
# --author shape: {type: "user", displayName?: string, operations?: list, username?: string, userKey?: string}
# --affectedObject shape: {name: string, objectType: string}
# --changedValues item shape: {name: string, oldValue: string, hiddenOldValue?: string, newValue: string, hiddenNewValue?: string}
# --associatedObjects item shape: {name: string, objectType: string}
export def "wiki-rest-audit createAuditRecord" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # The user that actioned the event. If `author` is not specified, then all `author` properties will be set to null/empty, except for `type` which will be set to 'user'. — shape: {type: "user", displayName?: string, operations?: list, username?: string, userKey?: string}
  remoteAddress: string # The IP address of the computer where the event was initiated from.
  --creationDate: int # The creation date-time of the audit record, as a timestamp. This is converted to a date-time display in the Confluence UI. If the `creationDate` is not specified, then it will be set to the timestamp for the current date-time. (format: int64)
  --summary: string # The summary of the event, which is displayed in the 'Change' column on the audit log in the Confluence UI.
  --description: string # A long description of the event, which is displayed in the 'Description' field on the audit log in the Confluence UI.
  --category: string # The category of the event, which is displayed in the 'Event type' column on the audit log in the Confluence UI.
  --sysAdmin: oneof<nothing, bool> # Indicates whether the event was actioned by a system administrator. (default: false)
  --affectedObject: record # shape: {name: string, objectType: string}
  --changedValues: list # The values that were changed in the event. — item shape: {name: string, oldValue: string, hiddenOldValue?: string, newValue: string, hiddenNewValue?: string}
  --associatedObjects: list # Objects that were associated with the event. For example, if the event was a space permission change then the associated object would be the space. — item shape: {name: string, objectType: string}
]: any -> record<author: record<type: string, displayName: string, operations: list<record>, username: string, userKey: string, accountId: string, accountType: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, publicName: string>, remoteAddress: string, creationDate: int, summary: string, description: string, category: string, sysAdmin: bool, superAdmin: bool, affectedObject: record<name: string, objectType: string>, changedValues: table<name: string, oldValue: string, hiddenOldValue: string, newValue: string, hiddenNewValue: string>, associatedObjects: table<name: string, objectType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/audit")
  let body = {author: $author, remoteAddress: $remoteAddress, creationDate: $creationDate, summary: $summary, description: $description, category: $category, sysAdmin: $sysAdmin, affectedObject: $affectedObject, changedValues: $changedValues, associatedObjects: $associatedObjects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export audit records
#
# GET /wiki/rest/api/audit/export
# operationId: exportAuditRecords
export def "wiki-rest-audit-export exportAuditRecords" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --startDate: string # Filters the exported results to the records on or after the `startDate`. The `startDate` must be specified as [epoch time](https://www.epochconverter.com/) in milliseconds.
  --endDate: string # Filters the exported results to the records on or before the `endDate`. The `endDate` must be specified as [epoch time](https://www.epochconverter.com/) in milliseconds.
  --searchString: string # Filters the exported results to records that have string property values matching the `searchString`.
  --format: string@format-completer # The format of the export file for the audit records. (default: csv)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "searchString" $searchString "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/audit/export" $qp)
  let accept_val = ($accept | default "application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get retention period
#
# GET /wiki/rest/api/audit/retention
# operationId: getRetentionPeriod
export def "wiki-rest-audit-retention get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<number: int, units: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/audit/retention")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set retention period
#
# PUT /wiki/rest/api/audit/retention
# operationId: setRetentionPeriod
export def "wiki-rest-audit-retention setRetentionPeriod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  number: int # The number of units for the retention period. (format: int32)
  units: string@units-completer # The unit of time that the retention period is measured in.
]: any -> record<number: int, units: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/audit/retention")
  let body = {number: $number, units: $units} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get audit records for time period
#
# GET /wiki/rest/api/audit/since
# operationId: getAuditRecordsForTimePeriod
export def "wiki-rest-audit-since get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # The number of units for the time period. (format: int64, default: 3)
  --units: string@units-completer-1 # The unit of time that the time period is measured in. (default: MONTHS)
  --searchString: string # Filters the results to records that have string property values matching the `searchString`.
  --start: int # The starting index of the returned records. (format: int32, default: 0)
  --limit: int # The maximum number of records to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 1000)
]: nothing -> record<results: table<author: record, remoteAddress: string, creationDate: int, summary: string, description: string, category: string, sysAdmin: bool, superAdmin: bool, affectedObject: record, changedValues: list, associatedObjects: list>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "searchString" $searchString "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/audit/since" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive pages
#
# POST /wiki/rest/api/content/archive
# operationId: archivePages
# --pages item shape: {id: int}
export def "wiki-rest-content-archive archivePages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pages: list # item shape: {id: int}
]: any -> record<ari: string, id: string, links: record<status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/content/archive")
  let body = {pages: $pages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Publish shared draft
#
# PUT /wiki/rest/api/content/blueprint/instance/{draftId}
# operationId: publishSharedDraft
# --version shape: {number: int}
# --space shape: {key: string}
# --ancestors item shape: {id: string}
export def "wiki-rest-content-blueprint-instance publishSharedDraft" [
  draftId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # The status of the content to be updated, i.e. the draft. This is set to 'draft' by default, so you shouldn't need to specify it. (default: draft)
  --expand: list # A multi-value parameter indicating which properties of the content to expand.  - `childTypes.all` returns whether the content has attachments, comments, or child pages/whiteboards. Use this if you only need to check whether the content has children of a particular type. - `childTypes.attachment` returns whether the content has attachments. - `childTypes.comment` returns whether the content has comments. - `childTypes.page` returns whether the content has child pages. - `childTypes.whiteboard` returns whether the content has child whiteboards. - `childTypes.database` returns whether the content has child databases. - `childTypes.embed` returns whether the content has child embeds (smartlinks). - `childTypes.folder` returns whether the content has child folders. - `container` returns the space that the content is in. This is the same as the information returned by [Get space](#api-space-spaceKey-get). - `metadata.currentuser` returns information about the current user in relation to the content, including when they last viewed it, modified it, contributed to it, or added it as a favorite. - `metadata.properties` returns content properties that have been set via the Confluence REST API. - `metadata.labels` returns the labels that have been added to the content. - `metadata.frontend` this property is only used by Atlassian. - `operations` returns the operations for the content, which are used when setting permissions. - `children.page` returns pages that are descendants at the level immediately below the content. - `children.whiteboard` returns whiteboards that are descendants at the level immediately below the content. - `children.database` returns databases that are descendants at the level immediately below the content. - `children.embed` returns embeds (smartlinks) that are descendants at the level immediately below the content. - `children.folder` returns folders that are descendants at the level immediately below the content. - `children.attachment` returns all attachments for the content. - `children.comment` returns all comments on the content. - `restrictions.read.restrictions.user` returns the users that have permission to read the content. - `restrictions.read.restrictions.group` returns the groups that have permission to read the content. Note that this may return deleted groups, because deleting a group doesn't remove associated restrictions. - `restrictions.update.restrictions.user` returns the users that have permission to update the content. - `restrictions.update.restrictions.group` returns the groups that have permission to update the content. Note that this may return deleted groups because deleting a group doesn't remove associated restrictions. - `history` returns the history of the content, including the date it was created. - `history.lastUpdated` returns information about the most recent update of the content, including who updated it and when it was updated. - `history.previousVersion` returns information about the update prior to the current content update. - `history.contributors` returns all of the users who have contributed to the content. - `history.nextVersion` returns information about the update after to the current content update. - `ancestors` returns the parent content, if the content is a page or whiteboard. - `body` returns the body of the content in different formats, including the editor format, view format, and export format. - `body.storage` returns the body of content in storage format. - `body.view` returns the body of content in view format. - `version` returns information about the most recent update of the content, including who updated it and when it was updated. - `descendants.page` returns pages that are descendants at any level below the content. - `descendants.whiteboard` returns whiteboards that are descendants at any level below the content. - `descendants.database` returns databases that are descendants at any level below the content. - `descendants.embed` returns embeds (smartlinks) that are descendants at any level below the content. - `descendants.folder` returns folders that are descendants at any level below the content. - `descendants.attachment` returns all attachments for the content, same as `children.attachment`. - `descendants.comment` returns all comments on the content, same as `children.comment`. - `space` returns the space that the content is in. This is the same as the information returned by [Get space](#api-space-spaceKey-get).  In addition, the following comment-specific expansions can be used: - `extensions.inlineProperties` returns inline comment-specific properties. - `extensions.resolution` returns the resolution status of each comment.
  version: record # The version for the new content. — shape: {number: int}
  title: string # The title of the content. If you don't want to change the title, set this to the current title of the draft.
  type: string@type-completer # The type of content. Set this to `page`.
  --status: string@status-completer # The status of the content. Set this to `current` or omit it altogether. (default: current)
  --space: record # The space for the content. — shape: {key: string}
  --ancestors: list # The new ancestor (i.e. parent page) for the content. If you have specified an ancestor, you must also specify a `space` property in the request body for the space that the ancestor is in.  Note, if you specify more than one ancestor, the last ID in the array will be selected as the parent page for the content. (nullable) — item shape: {id: string}
]: any -> record<id: string, type: string, status: string, title: string, space: record<id: int, key: string, alias: string, name: string, icon: record<path: string, width: int, height: int, isDefault: bool>, description: record<plain: record, view: record, _expandable: record>, homepage: any, type: string, metadata: record<labels: record, _expandable: record>, operations: list<record>, permissions: list<record>, status: string, settings: record<routeOverrideEnabled: bool, editor: record, contentMode: string, spaceKey: string, _links: record>, theme: record<themeKey: string, name: string, description: string, icon: record, _links: record>, lookAndFeel: record<headings: record, links: record, menus: record, header: record, horizontalHeader: record, content: record, bordersAndDividers: record, spaceReference: record>, history: record<createdDate: string, createdBy: record>, _expandable: record<settings: string, metadata: string, operations: string, lookAndFeel: string, permissions: string, icon: string, description: string, theme: string, history: string, homepage: string, identifiers: string>, _links: record>, history: record<latest: bool, createdBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, ownedBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, lastOwnedBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, createdDate: string, lastUpdated: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, previousVersion: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, contributors: record<publishers: record>, nextVersion: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, _expandable: record<lastUpdated: string, previousVersion: string, contributors: string, nextVersion: string, ownedBy: string, lastOwnedBy: string>, _links: record>, version: record<by: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record<users: list, userKeys: list, _links: record>, _expandable: record<content: string, collaborators: string>, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, ancestors: list<any>, operations: table<operation: string, targetType: string>, children: record<attachment: record<results: list, start: int, limit: int, size: int, _links: record>, comment: record<results: list, start: int, limit: int, size: int, _links: record>, page: record<results: list, start: int, limit: int, size: int, _links: record>, whiteboard: record<results: list, start: int, limit: int, size: int, _links: record>, database: record<results: list, start: int, limit: int, size: int, _links: record>, embed: record<results: list, start: int, limit: int, size: int, _links: record>, folder: record<results: list, start: int, limit: int, size: int, _links: record>, _expandable: record<attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>, _links: record>, childTypes: record<attachment: record<value: bool, _links: record>, comment: record<value: bool, _links: record>, page: record<value: bool, _links: record>, _expandable: record<all: string, attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>>, descendants: record<attachment: record<results: list, start: int, limit: int, size: int, _links: record>, comment: record<results: list, start: int, limit: int, size: int, _links: record>, page: record<results: list, start: int, limit: int, size: int, _links: record>, whiteboard: record<results: list, start: int, limit: int, size: int, _links: record>, database: record<results: list, start: int, limit: int, size: int, _links: record>, embed: record<results: list, start: int, limit: int, size: int, _links: record>, folder: record<results: list, start: int, limit: int, size: int, _links: record>, _expandable: record<attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>, _links: record>, container: record, body: record<view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, styled_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, storage: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, wiki: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor2: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, anonymous_export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, atlas_doc_format: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, dynamic: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, raw: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, _expandable: record<editor: string, view: string, export_view: string, styled_view: string, storage: string, editor2: string, anonymous_export_view: string, atlas_doc_format: string, wiki: string, dynamic: string, raw: string>>, restrictions: record<read: record<operation: string, restrictions: record, content: any, _expandable: record, _links: record>, update: record<operation: string, restrictions: record, content: any, _expandable: record, _links: record>, _expandable: record<read: string, update: string>, _links: record>, metadata: record<currentuser: record<favourited: record, lastmodified: record, lastcontributed: record, viewed: record, scheduled: record, _expandable: record>, properties: record, frontend: record, labels: any>, macroRenderedOutput: record, extensions: record, _expandable: record<childTypes: string, container: string, metadata: string, operations: string, children: string, restrictions: string, history: string, ancestors: string, body: string, version: string, descendants: string, space: string, extensions: string, schedulePublishDate: string, schedulePublishInfo: string, macroRenderedOutput: string>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/blueprint/instance/($draftId)" $qp)
  let body = {version: $version, title: $title, type: $type, status: $status, space: $space, ancestors: $ancestors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Publish legacy draft
#
# POST /wiki/rest/api/content/blueprint/instance/{draftId}
# operationId: publishLegacyDraft
# --version shape: {number: int}
# --space shape: {key: string}
# --ancestors item shape: {id: string}
export def "wiki-rest-content-blueprint-instance publishLegacyDraft" [
  draftId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # The status of the content to be updated, i.e. the draft. This is set to 'draft' by default, so you shouldn't need to specify it. (default: draft)
  --expand: list # A multi-value parameter indicating which properties of the content to expand.  - `childTypes.all` returns whether the content has attachments, comments, or child pages/whiteboards. Use this if you only need to check whether the content has children of a particular type. - `childTypes.attachment` returns whether the content has attachments. - `childTypes.comment` returns whether the content has comments. - `childTypes.page` returns whether the content has child pages. - `childTypes.whiteboard` returns whether the content has child whiteboards. - `childTypes.database` returns whether the content has child databases. - `childTypes.embed` returns whether the content has child embeds (smartlinks). - `childTypes.folder` returns whether the content has child folders. - `container` returns the space that the content is in. This is the same as the information returned by [Get space](#api-space-spaceKey-get). - `metadata.currentuser` returns information about the current user in relation to the content, including when they last viewed it, modified it, contributed to it, or added it as a favorite. - `metadata.properties` returns content properties that have been set via the Confluence REST API. - `metadata.labels` returns the labels that have been added to the content. - `metadata.frontend` this property is only used by Atlassian. - `operations` returns the operations for the content, which are used when setting permissions. - `children.page` returns pages that are descendants at the level immediately below the content. - `children.whiteboard` returns whiteboards that are descendants at the level immediately below the content. - `children.database` returns databases that are descendants at the level immediately below the content. - `children.embed` returns embeds (smartlinks) that are descendants at the level immediately below the content. - `children.folder` returns folders that are descendants at the level immediately below the content. - `children.attachment` returns all attachments for the content. - `children.comment` returns all comments on the content. - `restrictions.read.restrictions.user` returns the users that have permission to read the content. - `restrictions.read.restrictions.group` returns the groups that have permission to read the content. Note that this may return deleted groups, because deleting a group doesn't remove associated restrictions. - `restrictions.update.restrictions.user` returns the users that have permission to update the content. - `restrictions.update.restrictions.group` returns the groups that have permission to update the content. Note that this may return deleted groups because deleting a group doesn't remove associated restrictions. - `history` returns the history of the content, including the date it was created. - `history.lastUpdated` returns information about the most recent update of the content, including who updated it and when it was updated. - `history.previousVersion` returns information about the update prior to the current content update. - `history.contributors` returns all of the users who have contributed to the content. - `history.nextVersion` returns information about the update after to the current content update. - `ancestors` returns the parent content, if the content is a page or whiteboard. - `body` returns the body of the content in different formats, including the editor format, view format, and export format. - `body.storage` returns the body of content in storage format. - `body.view` returns the body of content in view format. - `version` returns information about the most recent update of the content, including who updated it and when it was updated. - `descendants.page` returns pages that are descendants at any level below the content. - `descendants.whiteboard` returns whiteboards that are descendants at any level below the content. - `descendants.database` returns databases that are descendants at any level below the content. - `descendants.embed` returns embeds (smartlinks) that are descendants at any level below the content. - `descendants.folder` returns folders that are descendants at any level below the content. - `descendants.attachment` returns all attachments for the content, same as `children.attachment`. - `descendants.comment` returns all comments on the content, same as `children.comment`. - `space` returns the space that the content is in. This is the same as the information returned by [Get space](#api-space-spaceKey-get).  In addition, the following comment-specific expansions can be used: - `extensions.inlineProperties` returns inline comment-specific properties. - `extensions.resolution` returns the resolution status of each comment.
  version: record # The version for the new content. — shape: {number: int}
  title: string # The title of the content. If you don't want to change the title, set this to the current title of the draft.
  type: string@type-completer # The type of content. Set this to `page`.
  --status: string@status-completer # The status of the content. Set this to `current` or omit it altogether. (default: current)
  --space: record # The space for the content. — shape: {key: string}
  --ancestors: list # The new ancestor (i.e. parent page) for the content. If you have specified an ancestor, you must also specify a `space` property in the request body for the space that the ancestor is in.  Note, if you specify more than one ancestor, the last ID in the array will be selected as the parent page for the content. (nullable) — item shape: {id: string}
]: any -> record<id: string, type: string, status: string, title: string, space: record<id: int, key: string, alias: string, name: string, icon: record<path: string, width: int, height: int, isDefault: bool>, description: record<plain: record, view: record, _expandable: record>, homepage: any, type: string, metadata: record<labels: record, _expandable: record>, operations: list<record>, permissions: list<record>, status: string, settings: record<routeOverrideEnabled: bool, editor: record, contentMode: string, spaceKey: string, _links: record>, theme: record<themeKey: string, name: string, description: string, icon: record, _links: record>, lookAndFeel: record<headings: record, links: record, menus: record, header: record, horizontalHeader: record, content: record, bordersAndDividers: record, spaceReference: record>, history: record<createdDate: string, createdBy: record>, _expandable: record<settings: string, metadata: string, operations: string, lookAndFeel: string, permissions: string, icon: string, description: string, theme: string, history: string, homepage: string, identifiers: string>, _links: record>, history: record<latest: bool, createdBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, ownedBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, lastOwnedBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, createdDate: string, lastUpdated: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, previousVersion: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, contributors: record<publishers: record>, nextVersion: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, _expandable: record<lastUpdated: string, previousVersion: string, contributors: string, nextVersion: string, ownedBy: string, lastOwnedBy: string>, _links: record>, version: record<by: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record<users: list, userKeys: list, _links: record>, _expandable: record<content: string, collaborators: string>, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, ancestors: list<any>, operations: table<operation: string, targetType: string>, children: record<attachment: record<results: list, start: int, limit: int, size: int, _links: record>, comment: record<results: list, start: int, limit: int, size: int, _links: record>, page: record<results: list, start: int, limit: int, size: int, _links: record>, whiteboard: record<results: list, start: int, limit: int, size: int, _links: record>, database: record<results: list, start: int, limit: int, size: int, _links: record>, embed: record<results: list, start: int, limit: int, size: int, _links: record>, folder: record<results: list, start: int, limit: int, size: int, _links: record>, _expandable: record<attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>, _links: record>, childTypes: record<attachment: record<value: bool, _links: record>, comment: record<value: bool, _links: record>, page: record<value: bool, _links: record>, _expandable: record<all: string, attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>>, descendants: record<attachment: record<results: list, start: int, limit: int, size: int, _links: record>, comment: record<results: list, start: int, limit: int, size: int, _links: record>, page: record<results: list, start: int, limit: int, size: int, _links: record>, whiteboard: record<results: list, start: int, limit: int, size: int, _links: record>, database: record<results: list, start: int, limit: int, size: int, _links: record>, embed: record<results: list, start: int, limit: int, size: int, _links: record>, folder: record<results: list, start: int, limit: int, size: int, _links: record>, _expandable: record<attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>, _links: record>, container: record, body: record<view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, styled_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, storage: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, wiki: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor2: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, anonymous_export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, atlas_doc_format: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, dynamic: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, raw: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, _expandable: record<editor: string, view: string, export_view: string, styled_view: string, storage: string, editor2: string, anonymous_export_view: string, atlas_doc_format: string, wiki: string, dynamic: string, raw: string>>, restrictions: record<read: record<operation: string, restrictions: record, content: any, _expandable: record, _links: record>, update: record<operation: string, restrictions: record, content: any, _expandable: record, _links: record>, _expandable: record<read: string, update: string>, _links: record>, metadata: record<currentuser: record<favourited: record, lastmodified: record, lastcontributed: record, viewed: record, scheduled: record, _expandable: record>, properties: record, frontend: record, labels: any>, macroRenderedOutput: record, extensions: record, _expandable: record<childTypes: string, container: string, metadata: string, operations: string, children: string, restrictions: string, history: string, ancestors: string, body: string, version: string, descendants: string, space: string, extensions: string, schedulePublishDate: string, schedulePublishInfo: string, macroRenderedOutput: string>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/blueprint/instance/($draftId)" $qp)
  let body = {version: $version, title: $title, type: $type, status: $status, space: $space, ancestors: $ancestors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search content by CQL
#
# GET /wiki/rest/api/content/search
# operationId: searchContentByCQL
export def "wiki-rest-content-search searchContentByCQL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cql: string # The CQL string that is used to find the requested content.
  --cqlcontext: string # The space, content, and content status to execute the search against. Specify this as an object with the following properties:  - `spaceKey` Key of the space to search against. Optional. - `contentId` ID of the content to search against. Optional. Must be in the space spacified by `spaceKey`. - `contentStatuses` Content statuses to search against. Optional.
  --expand: list # A multi-value parameter indicating which properties of the content to expand.  - `childTypes.all` returns whether the content has attachments, comments, or child pages/whiteboards. Use this if you only need to check whether the content has children of a particular type. - `childTypes.attachment` returns whether the content has attachments. - `childTypes.comment` returns whether the content has comments. - `childTypes.page` returns whether the content has child pages. - `childTypes.whiteboard` returns whether the content has child whiteboards. - `childTypes.database` returns whether the content has child databases. - `childTypes.embed` returns whether the content has child embeds (smartlinks). - `childTypes.folder` returns whether the content has child folders. - `container` returns the space that the content is in. This is the same as the information returned by [Get space](#api-space-spaceKey-get). - `metadata.currentuser` returns information about the current user in relation to the content, including when they last viewed it, modified it, contributed to it, or added it as a favorite. - `metadata.properties` returns content properties that have been set via the Confluence REST API. - `metadata.labels` returns the labels that have been added to the content. - `metadata.frontend` this property is only used by Atlassian. - `operations` returns the operations for the content, which are used when setting permissions. - `children.page` returns pages that are descendants at the level immediately below the content. - `children.whiteboard` returns whiteboards that are descendants at the level immediately below the content. - `children.database` returns databases that are descendants at the level immediately below the content. - `children.embed` returns embeds (smartlinks) that are descendants at the level immediately below the content. - `children.folder` returns folders that are descendants at the level immediately below the content. - `children.attachment` returns all attachments for the content. - `children.comment` returns all comments on the content. - `restrictions.read.restrictions.user` returns the users that have permission to read the content. - `restrictions.read.restrictions.group` returns the groups that have permission to read the content. Note that this may return deleted groups, because deleting a group doesn't remove associated restrictions. - `restrictions.update.restrictions.user` returns the users that have permission to update the content. - `restrictions.update.restrictions.group` returns the groups that have permission to update the content. Note that this may return deleted groups because deleting a group doesn't remove associated restrictions. - `history` returns the history of the content, including the date it was created. - `history.lastUpdated` returns information about the most recent update of the content, including who updated it and when it was updated. - `history.previousVersion` returns information about the update prior to the current content update. - `history.contributors` returns all of the users who have contributed to the content. - `history.nextVersion` returns information about the update after to the current content update. - `ancestors` returns the parent content, if the content is a page or whiteboard. - `body` returns the body of the content in different formats, including the editor format, view format, and export format. - `body.storage` returns the body of content in storage format. - `body.view` returns the body of content in view format. - `version` returns information about the most recent update of the content, including who updated it and when it was updated. - `descendants.page` returns pages that are descendants at any level below the content. - `descendants.whiteboard` returns whiteboards that are descendants at any level below the content. - `descendants.database` returns databases that are descendants at any level below the content. - `descendants.embed` returns embeds (smartlinks) that are descendants at any level below the content. - `descendants.folder` returns folders that are descendants at any level below the content. - `descendants.attachment` returns all attachments for the content, same as `children.attachment`. - `descendants.comment` returns all comments on the content, same as `children.comment`. - `space` returns the space that the content is in. This is the same as the information returned by [Get space](#api-space-spaceKey-get).  In addition, the following comment-specific expansions can be used: - `extensions.inlineProperties` returns inline comment-specific properties. - `extensions.resolution` returns the resolution status of each comment.
  --cursor: string # Pointer to a set of search results, returned as part of the `next` or `prev` URL from the previous search call.
  --limit: int # The maximum number of content objects to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 25)
]: nothing -> record<results: table<id: string, type: string, status: string, title: string, space: record, history: record, version: record, ancestors: list, operations: list, children: record, childTypes: record, descendants: record, container: record, body: record, restrictions: record, metadata: record, macroRenderedOutput: record, extensions: record, _expandable: record, _links: record>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cql" $cql "scalar") (serialize-qp "cqlcontext" $cqlcontext "scalar") (serialize-qp "expand" $expand "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/content/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete page tree
#
# DELETE /wiki/rest/api/content/{id}/pageTree
# operationId: deletePageTree
export def "wiki-rest-content-page-tree delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ari: string, id: string, links: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/pageTree")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move a page to a new location relative to a target page
#
# PUT /wiki/rest/api/content/{pageId}/move/{position}/{targetId}
# operationId: movePage
export def "wiki-rest-content-move movePage" [
  pageId: string
  position: string
  targetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pageId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/content/($pageId)/move/($position)/($targetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update attachment
#
# PUT /wiki/rest/api/content/{id}/child/attachment
# operationId: createOrUpdateAttachments
export def "wiki-rest-content-child-attachment createOrUpdateAttachments" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # The status of the content that the attachment is being added to. This should always be set to 'current'. (default: current)
  file: string # The relative location and name of the attachment to be added to the content. (format: binary)
  --comment: string # The comment for the attachment that is being added. If you specify a comment, then every file must have a comment and the comments must be in the same order as the files. Alternatively, don't specify any comments. (format: binary)
  minorEdit: string # If `minorEdits` is set to 'true', no notification email or activity stream will be generated when the attachment is added to the content. (format: binary)
]: any -> record<results: table<id: string, type: string, status: string, title: string, space: record, history: record, version: record, ancestors: list, operations: list, children: record, childTypes: record, descendants: record, container: record, body: record, restrictions: record, metadata: record, macroRenderedOutput: record, extensions: record, _expandable: record, _links: record>, start: int, limit: int, size: int, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/child/attachment" $qp)
  let body = {file: $file, comment: $comment, minorEdit: $minorEdit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Create attachment
#
# POST /wiki/rest/api/content/{id}/child/attachment
# operationId: createAttachment
export def "wiki-rest-content-child-attachment createAttachment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # The status of the content that the attachment is being added to. (default: current)
  file: string # The relative location and name of the attachment to be added to the content. (format: binary)
  --comment: string # The comment for the attachment that is being added. If you specify a comment, then every file must have a comment and the comments must be in the same order as the files. Alternatively, don't specify any comments. (format: binary)
  minorEdit: string # If `minorEdits` is set to 'true', no notification email or activity stream will be generated when the attachment is added to the content. (format: binary)
]: any -> record<results: table<id: string, type: string, status: string, title: string, space: record, history: record, version: record, ancestors: list, operations: list, children: record, childTypes: record, descendants: record, container: record, body: record, restrictions: record, metadata: record, macroRenderedOutput: record, extensions: record, _expandable: record, _links: record>, start: int, limit: int, size: int, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/child/attachment" $qp)
  let body = {file: $file, comment: $comment, minorEdit: $minorEdit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Update attachment properties
#
# PUT /wiki/rest/api/content/{id}/child/attachment/{attachmentId}
# operationId: updateAttachmentProperties
# --metadata shape: {mediaType?: string}
# --version shape: {by?: record, when: string, friendlyWhen?: string, message?: string, number: int, minorEdit: bool, content?: record, collaborators?: record, _expandable?: record, _links?: record, contentTypeModified?: bool, confRev?: string, syncRev?: string, syncRevSource?: string}
export def "wiki-rest-content-child-attachment updateAttachmentProperties" [
  id: string
  attachmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  type: string # Set this to "attachment"
  --status: string
  --title: string
  --container: record # Container for content. This can be either a space (containing a page or blogpost) or a page/blog post (containing an attachment or comment) (nullable)
  --metadata: record # shape: {mediaType?: string}
  --extensions: record
  --version: record # nullable — shape: {by?: record, when: string, friendlyWhen?: string, message?: string, number: int, minorEdit: bool, content?: record, collaborators?: record, _expandable?: record, _links?: record, contentTypeModified?: bool, confRev?: string, syncRev?: string, syncRevSource?: string}
]: any -> record<id: string, type: string, status: string, title: string, space: record<id: int, key: string, alias: string, name: string, icon: record<path: string, width: int, height: int, isDefault: bool>, description: record<plain: record, view: record, _expandable: record>, homepage: any, type: string, metadata: record<labels: record, _expandable: record>, operations: list<record>, permissions: list<record>, status: string, settings: record<routeOverrideEnabled: bool, editor: record, contentMode: string, spaceKey: string, _links: record>, theme: record<themeKey: string, name: string, description: string, icon: record, _links: record>, lookAndFeel: record<headings: record, links: record, menus: record, header: record, horizontalHeader: record, content: record, bordersAndDividers: record, spaceReference: record>, history: record<createdDate: string, createdBy: record>, _expandable: record<settings: string, metadata: string, operations: string, lookAndFeel: string, permissions: string, icon: string, description: string, theme: string, history: string, homepage: string, identifiers: string>, _links: record>, history: record<latest: bool, createdBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, ownedBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, lastOwnedBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, createdDate: string, lastUpdated: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, previousVersion: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, contributors: record<publishers: record>, nextVersion: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, _expandable: record<lastUpdated: string, previousVersion: string, contributors: string, nextVersion: string, ownedBy: string, lastOwnedBy: string>, _links: record>, version: record<by: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record<users: list, userKeys: list, _links: record>, _expandable: record<content: string, collaborators: string>, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, ancestors: list<any>, operations: table<operation: string, targetType: string>, children: record<attachment: record<results: list, start: int, limit: int, size: int, _links: record>, comment: record<results: list, start: int, limit: int, size: int, _links: record>, page: record<results: list, start: int, limit: int, size: int, _links: record>, whiteboard: record<results: list, start: int, limit: int, size: int, _links: record>, database: record<results: list, start: int, limit: int, size: int, _links: record>, embed: record<results: list, start: int, limit: int, size: int, _links: record>, folder: record<results: list, start: int, limit: int, size: int, _links: record>, _expandable: record<attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>, _links: record>, childTypes: record<attachment: record<value: bool, _links: record>, comment: record<value: bool, _links: record>, page: record<value: bool, _links: record>, _expandable: record<all: string, attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>>, descendants: record<attachment: record<results: list, start: int, limit: int, size: int, _links: record>, comment: record<results: list, start: int, limit: int, size: int, _links: record>, page: record<results: list, start: int, limit: int, size: int, _links: record>, whiteboard: record<results: list, start: int, limit: int, size: int, _links: record>, database: record<results: list, start: int, limit: int, size: int, _links: record>, embed: record<results: list, start: int, limit: int, size: int, _links: record>, folder: record<results: list, start: int, limit: int, size: int, _links: record>, _expandable: record<attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>, _links: record>, container: record, body: record<view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, styled_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, storage: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, wiki: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor2: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, anonymous_export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, atlas_doc_format: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, dynamic: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, raw: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, _expandable: record<editor: string, view: string, export_view: string, styled_view: string, storage: string, editor2: string, anonymous_export_view: string, atlas_doc_format: string, wiki: string, dynamic: string, raw: string>>, restrictions: record<read: record<operation: string, restrictions: record, content: any, _expandable: record, _links: record>, update: record<operation: string, restrictions: record, content: any, _expandable: record, _links: record>, _expandable: record<read: string, update: string>, _links: record>, metadata: record<currentuser: record<favourited: record, lastmodified: record, lastcontributed: record, viewed: record, scheduled: record, _expandable: record>, properties: record, frontend: record, labels: any>, macroRenderedOutput: record, extensions: record, _expandable: record<childTypes: string, container: string, metadata: string, operations: string, children: string, restrictions: string, history: string, ancestors: string, body: string, version: string, descendants: string, space: string, extensions: string, schedulePublishDate: string, schedulePublishInfo: string, macroRenderedOutput: string>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/child/attachment/($attachmentId)")
  let body = {id: $body_id, type: $type, status: $status, title: $title, container: $container, metadata: $metadata, extensions: $extensions, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update attachment data
#
# POST /wiki/rest/api/content/{id}/child/attachment/{attachmentId}/data
# operationId: updateAttachmentData
export def "wiki-rest-content-child-attachment-data updateAttachmentData" [
  id: string
  attachmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The relative location and name of the attachment to be added to the content. (format: binary)
  --comment: string # The comment for the attachment that is being added. If you specify a comment, then every file must have a comment and the comments must be in the same order as the files. Alternatively, don't specify any comments. (format: binary)
  minorEdit: string # If `minorEdits` is set to 'true', no notification email or activity stream will be generated when the attachment is added to the content. (format: binary)
]: any -> record<id: string, type: string, status: string, title: string, space: record<id: int, key: string, alias: string, name: string, icon: record<path: string, width: int, height: int, isDefault: bool>, description: record<plain: record, view: record, _expandable: record>, homepage: any, type: string, metadata: record<labels: record, _expandable: record>, operations: list<record>, permissions: list<record>, status: string, settings: record<routeOverrideEnabled: bool, editor: record, contentMode: string, spaceKey: string, _links: record>, theme: record<themeKey: string, name: string, description: string, icon: record, _links: record>, lookAndFeel: record<headings: record, links: record, menus: record, header: record, horizontalHeader: record, content: record, bordersAndDividers: record, spaceReference: record>, history: record<createdDate: string, createdBy: record>, _expandable: record<settings: string, metadata: string, operations: string, lookAndFeel: string, permissions: string, icon: string, description: string, theme: string, history: string, homepage: string, identifiers: string>, _links: record>, history: record<latest: bool, createdBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, ownedBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, lastOwnedBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, createdDate: string, lastUpdated: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, previousVersion: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, contributors: record<publishers: record>, nextVersion: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, _expandable: record<lastUpdated: string, previousVersion: string, contributors: string, nextVersion: string, ownedBy: string, lastOwnedBy: string>, _links: record>, version: record<by: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record<users: list, userKeys: list, _links: record>, _expandable: record<content: string, collaborators: string>, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, ancestors: list<any>, operations: table<operation: string, targetType: string>, children: record<attachment: record<results: list, start: int, limit: int, size: int, _links: record>, comment: record<results: list, start: int, limit: int, size: int, _links: record>, page: record<results: list, start: int, limit: int, size: int, _links: record>, whiteboard: record<results: list, start: int, limit: int, size: int, _links: record>, database: record<results: list, start: int, limit: int, size: int, _links: record>, embed: record<results: list, start: int, limit: int, size: int, _links: record>, folder: record<results: list, start: int, limit: int, size: int, _links: record>, _expandable: record<attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>, _links: record>, childTypes: record<attachment: record<value: bool, _links: record>, comment: record<value: bool, _links: record>, page: record<value: bool, _links: record>, _expandable: record<all: string, attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>>, descendants: record<attachment: record<results: list, start: int, limit: int, size: int, _links: record>, comment: record<results: list, start: int, limit: int, size: int, _links: record>, page: record<results: list, start: int, limit: int, size: int, _links: record>, whiteboard: record<results: list, start: int, limit: int, size: int, _links: record>, database: record<results: list, start: int, limit: int, size: int, _links: record>, embed: record<results: list, start: int, limit: int, size: int, _links: record>, folder: record<results: list, start: int, limit: int, size: int, _links: record>, _expandable: record<attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>, _links: record>, container: record, body: record<view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, styled_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, storage: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, wiki: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor2: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, anonymous_export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, atlas_doc_format: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, dynamic: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, raw: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, _expandable: record<editor: string, view: string, export_view: string, styled_view: string, storage: string, editor2: string, anonymous_export_view: string, atlas_doc_format: string, wiki: string, dynamic: string, raw: string>>, restrictions: record<read: record<operation: string, restrictions: record, content: any, _expandable: record, _links: record>, update: record<operation: string, restrictions: record, content: any, _expandable: record, _links: record>, _expandable: record<read: string, update: string>, _links: record>, metadata: record<currentuser: record<favourited: record, lastmodified: record, lastcontributed: record, viewed: record, scheduled: record, _expandable: record>, properties: record, frontend: record, labels: any>, macroRenderedOutput: record, extensions: record, _expandable: record<childTypes: string, container: string, metadata: string, operations: string, children: string, restrictions: string, history: string, ancestors: string, body: string, version: string, descendants: string, space: string, extensions: string, schedulePublishDate: string, schedulePublishInfo: string, macroRenderedOutput: string>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/child/attachment/($attachmentId)/data")
  let body = {file: $file, comment: $comment, minorEdit: $minorEdit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get URI to download attachment
#
# GET /wiki/rest/api/content/{id}/child/attachment/{attachmentId}/download
# operationId: downloadAttatchment
export def "wiki-rest-content-child-attachment-download downloadAttatchment" [
  id: string
  attachmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The version of the attachment. If this parameter is absent, the redirect URI will download the latest version of the attachment.
  --status: list # The statuses allowed on the retrieved attachment. If this parameter is absent, it will default to `current`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "status" $status "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/child/attachment/($attachmentId)/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content descendants
#
# GET /wiki/rest/api/content/{id}/descendant
# DEPRECATED
# operationId: getContentDescendants
@deprecated
export def "wiki-rest-content-descendant list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the children to expand, where:  - `attachment` returns all attachments for the content. - `comments` returns all comments for the content. - `page` returns all child pages of the content. - `whiteboard` returns all child whiteboards of the content. - `database` returns all child databases of the content. - `embed` returns all child embeds of the content. - `folder` returns all child folders of the content.
]: nothing -> record<attachment: record<results: list<record>, start: int, limit: int, size: int, _links: record>, comment: record<results: list<record>, start: int, limit: int, size: int, _links: record>, page: record<results: list<record>, start: int, limit: int, size: int, _links: record>, whiteboard: record<results: list<record>, start: int, limit: int, size: int, _links: record>, database: record<results: list<record>, start: int, limit: int, size: int, _links: record>, embed: record<results: list<record>, start: int, limit: int, size: int, _links: record>, folder: record<results: list<record>, start: int, limit: int, size: int, _links: record>, _expandable: record<attachment: string, comment: string, page: string, whiteboard: string, database: string, embed: string, folder: string>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/descendant" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content descendants by type
#
# GET /wiki/rest/api/content/{id}/descendant/{type}
# DEPRECATED
# operationId: getDescendantsOfType
@deprecated
export def "wiki-rest-content-descendant get" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --depth: string@depth-completer # Filter the results to descendants upto a desired level of the content. Note, the maximum value supported is 100. root level of the content means immediate (level 1) descendants of the type requested. all represents returning all descendants of the type requested. (default: all)
  --expand: list # A multi-value parameter indicating which properties of the content to expand.  - `childTypes.all` returns whether the content has attachments, comments, or child pages/whiteboards. Use this if you only need to check whether the content has children of a particular type. - `childTypes.attachment` returns whether the content has attachments. - `childTypes.comment` returns whether the content has comments. - `childTypes.page` returns whether the content has child pages. - `childTypes.whiteboard` returns whether the content has child whiteboards. - `childTypes.database` returns whether the content has child databases. - `childTypes.embed` returns whether the content has child embeds (smartlinks). - `childTypes.folder` returns whether the content has child folders. - `container` returns the space that the content is in. This is the same as the information returned by [Get space](#api-space-spaceKey-get). - `metadata.currentuser` returns information about the current user in relation to the content, including when they last viewed it, modified it, contributed to it, or added it as a favorite. - `metadata.properties` returns content properties that have been set via the Confluence REST API. - `metadata.labels` returns the labels that have been added to the content. - `metadata.frontend` this property is only used by Atlassian. - `operations` returns the operations for the content, which are used when setting permissions. - `children.page` returns pages that are descendants at the level immediately below the content. - `children.whiteboard` returns whiteboards that are descendants at the level immediately below the content. - `children.database` returns databases that are descendants at the level immediately below the content. - `children.embed` returns embeds (smartlinks) that are descendants at the level immediately below the content. - `children.folder` returns folders that are descendants at the level immediately below the content. - `children.attachment` returns all attachments for the content. - `children.comment` returns all comments on the content. - `restrictions.read.restrictions.user` returns the users that have permission to read the content. - `restrictions.read.restrictions.group` returns the groups that have permission to read the content. Note that this may return deleted groups, because deleting a group doesn't remove associated restrictions. - `restrictions.update.restrictions.user` returns the users that have permission to update the content. - `restrictions.update.restrictions.group` returns the groups that have permission to update the content. Note that this may return deleted groups because deleting a group doesn't remove associated restrictions. - `history` returns the history of the content, including the date it was created. - `history.lastUpdated` returns information about the most recent update of the content, including who updated it and when it was updated. - `history.previousVersion` returns information about the update prior to the current content update. - `history.contributors` returns all of the users who have contributed to the content. - `history.nextVersion` returns information about the update after to the current content update. - `ancestors` returns the parent content, if the content is a page or whiteboard. - `body` returns the body of the content in different formats, including the editor format, view format, and export format. - `body.storage` returns the body of content in storage format. - `body.view` returns the body of content in view format. - `version` returns information about the most recent update of the content, including who updated it and when it was updated. - `descendants.page` returns pages that are descendants at any level below the content. - `descendants.whiteboard` returns whiteboards that are descendants at any level below the content. - `descendants.database` returns databases that are descendants at any level below the content. - `descendants.embed` returns embeds (smartlinks) that are descendants at any level below the content. - `descendants.folder` returns folders that are descendants at any level below the content. - `descendants.attachment` returns all attachments for the content, same as `children.attachment`. - `descendants.comment` returns all comments on the content, same as `children.comment`. - `space` returns the space that the content is in. This is the same as the information returned by [Get space](#api-space-spaceKey-get).  In addition, the following comment-specific expansions can be used: - `extensions.inlineProperties` returns inline comment-specific properties. - `extensions.resolution` returns the resolution status of each comment.
  --start: int # The starting index of the returned content. (format: int32, default: 0)
  --limit: int # The maximum number of content to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 25)
]: nothing -> record<results: table<id: string, type: string, status: string, title: string, space: record, history: record, version: record, ancestors: list, operations: list, children: record, childTypes: record, descendants: record, container: record, body: record, restrictions: record, metadata: record, macroRenderedOutput: record, extensions: record, _expandable: record, _links: record>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "depth" $depth "scalar") (serialize-qp "expand" $expand "csv") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/descendant/($type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get macro body by macro ID
#
# GET /wiki/rest/api/content/{id}/history/{version}/macro/id/{macroId}
# operationId: getMacroBodyByMacroId
export def "wiki-rest-content-history-macro-id get" [
  id: string
  version: int
  macroId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, body: string, parameters: record, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/history/($version)/macro/id/($macroId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get macro body by macro ID and convert the representation synchronously
#
# GET /wiki/rest/api/content/{id}/history/{version}/macro/id/{macroId}/convert/{to}
# operationId: getAndConvertMacroBodyByMacroId
export def "wiki-rest-content-history-macro-id-convert get" [
  id: string
  version: int
  macroId: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the content to expand and populate. Expands are dependent on the `to` conversion format and may be irrelevant for certain conversions (e.g. `macroRenderedOutput` is redundant when converting to `view` format).   If rendering to `view` format, and the body content being converted includes arbitrary nested content (such as macros); then it is  necessary to include webresource expands in the request. Webresources for content body are the batched JS and CSS dependencies for any nested dynamic content (i.e. macros).  - `embeddedContent` returns metadata for nested content (e.g. page included using page include macro) - `mediaToken` returns JWT token for retrieving attachment data from Media API - `macroRenderedOutput` additionally converts body to view format - `webresource.superbatch.uris.js` returns all common JS dependencies as static URLs - `webresource.superbatch.uris.css` returns all common CSS dependencies as static URLs - `webresource.superbatch.uris.all` returns all common dependencies as static URLs - `webresource.superbatch.tags.all` returns all common JS dependencies as html `<script>` tags - `webresource.superbatch.tags.css` returns all common CSS dependencies as html `<style>` tags - `webresource.superbatch.tags.js` returns all common dependencies as html `<script>` and `<style>` tags - `webresource.uris.js` returns JS dependencies specific to conversion - `webresource.uris.css` returns CSS dependencies specific to conversion - `webresource.uris.all` returns all dependencies specific to conversion      - `webresource.tags.all` returns common JS dependencies as html `<script>` tags - `webresource.tags.css` returns common CSS dependencies as html `<style>` tags - `webresource.tags.js` returns common dependencies as html `<script>` and `<style>` tags
  --spaceKeyContext: string # The space key used for resolving embedded content (page includes, files, and links) in the content body. For example, if the source content contains the link `<ac:link><ri:page ri:content-title="Example page" /><ac:link>` and the `spaceKeyContext=TEST` parameter is provided, then the link will be converted to a link to the "Example page" page in the "TEST" space.
  --embeddedContentRender: string@embeddedContentRender-completer # Mode used for rendering embedded content, like attachments.  - `current` renders the embedded content using the latest version. - `version-at-save` renders the embedded content using the version at the time of save. (default: current)
]: nothing -> record<value: string, representation: string, embeddedContent: table<entityId: int, entityType: string, entity: record>, webresource: record<_expandable: record<uris: any>, keys: list<string>, contexts: list<string>, uris: record<all: any, css: any, js: any, _expandable: record>, tags: record<all: string, css: string, data: string, js: string, _expandable: record>, superbatch: record<uris: record, tags: record, metatags: string, _expandable: record>>, mediaToken: record<collectionIds: list<string>, contentId: string, expiryDateTime: string, fileIds: list<string>, token: string>, _expandable: record<content: string, embeddedContent: string, webresource: string, mediaToken: string>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv") (serialize-qp "spaceKeyContext" $spaceKeyContext "scalar") (serialize-qp "embeddedContentRender" $embeddedContentRender "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/history/($version)/macro/id/($macroId)/convert/($to)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get macro body by macro ID and convert representation Asynchronously
#
# GET /wiki/rest/api/content/{id}/history/{version}/macro/id/{macroId}/convert/async/{to}
# operationId: getAndAsyncConvertMacroBodyByMacroId
export def "wiki-rest-content-history-macro-id-convert-async get" [
  id: string
  version: int
  macroId: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the content to expand and populate. Expands are dependent on the `to` conversion format and may be irrelevant for certain conversions (e.g. `macroRenderedOutput` is redundant when converting to `view` format).   If rendering to `view` format, and the body content being converted includes arbitrary nested content (such as macros); then it is  necessary to include webresource expands in the request. Webresources for content body are the batched JS and CSS dependencies for any nested dynamic content (i.e. macros).  - `embeddedContent` returns metadata for nested content (e.g. page included using page include macro) - `mediaToken` returns JWT token for retrieving attachment data from Media API - `macroRenderedOutput` additionally converts body to view format - `webresource.superbatch.uris.js` returns all common JS dependencies as static URLs - `webresource.superbatch.uris.css` returns all common CSS dependencies as static URLs - `webresource.superbatch.uris.all` returns all common dependencies as static URLs - `webresource.superbatch.tags.all` returns all common JS dependencies as html `<script>` tags - `webresource.superbatch.tags.css` returns all common CSS dependencies as html `<style>` tags - `webresource.superbatch.tags.js` returns all common dependencies as html `<script>` and `<style>` tags - `webresource.uris.js` returns JS dependencies specific to conversion - `webresource.uris.css` returns CSS dependencies specific to conversion - `webresource.uris.all` returns all dependencies specific to conversion      - `webresource.tags.all` returns common JS dependencies as html `<script>` tags - `webresource.tags.css` returns common CSS dependencies as html `<style>` tags - `webresource.tags.js` returns common dependencies as html `<script>` and `<style>` tags
  --allowCache: oneof<nothing, bool> # Controls whether conversion results are cached and reused for identical requests.  - `false`: Each request creates a new conversion task, even if an identical request was made previously. - `true`: Enables caching behavior for identical requests from the same user.   - If no cached result exists, a new conversion task is created   - If a cached result exists, the existing task is marked as RERUNNING and will complete with status COMPLETED   - Returns the same task ID for identical requests, allowing you to retrieve the cached result  For large macros that are slow to convert and for which it is acceptable to show cached data, set this field to `true`. (default: false)
  --spaceKeyContext: string # The space key used for resolving embedded content (page includes, files, and links) in the content body. For example, if the source content contains the link `<ac:link><ri:page ri:content-title="Example page" /><ac:link>` and the `spaceKeyContext=TEST` parameter is provided, then the link will be converted to a link to the "Example page" page in the "TEST" space.
  --embeddedContentRender: string@embeddedContentRender-completer # Mode used for rendering embedded content, like attachments.  - `current` renders the embedded content using the latest version. - `version-at-save` renders the embedded content using the version at the time of save. (default: current)
]: nothing -> record<asyncId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv") (serialize-qp "allowCache" $allowCache "scalar") (serialize-qp "spaceKeyContext" $spaceKeyContext "scalar") (serialize-qp "embeddedContentRender" $embeddedContentRender "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/history/($version)/macro/id/($macroId)/convert/async/($to)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add labels to content
#
# POST /wiki/rest/api/content/{id}/label
# operationId: addLabelsToContent
export def "wiki-rest-content-label addLabelsToContent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --prefix: string # The prefix for the label. `global`, `my` `team`, etc.
  --name: string # The name of the label, which will be shown in the UI.
]: any -> record<results: table<prefix: string, name: string, id: string, label: string>, start: int, limit: int, size: int, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/label")
  let body = {prefix: $prefix, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove label from content using query parameter
#
# DELETE /wiki/rest/api/content/{id}/label
# operationId: removeLabelFromContentUsingQueryParameter
export def "wiki-rest-content-label removeLabelFromContentUsingQueryParameter" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the label to be removed.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/label" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove label from content
#
# DELETE /wiki/rest/api/content/{id}/label/{label}
# operationId: removeLabelFromContent
export def "wiki-rest-content-label removeLabelFromContent" [
  id: string
  label: string
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
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/label/($label)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get watches for page
#
# GET /wiki/rest/api/content/{id}/notification/child-created
# operationId: getWatchesForPage
export def "wiki-rest-content-notification-child-created get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # The starting index of the returned watches. (format: int32, default: 0)
  --limit: int # The maximum number of watches to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 200)
]: nothing -> record<results: table<type: string, watcher: record, contentId: int>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/notification/child-created" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get watches for space
#
# GET /wiki/rest/api/content/{id}/notification/created
# operationId: getWatchesForSpace
export def "wiki-rest-content-notification-created get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # The starting index of the returned watches. (format: int32, default: 0)
  --limit: int # The maximum number of watches to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 200)
]: nothing -> record<results: table<type: string, watcher: record, spaceKey: string, labelName: string, prefix: string>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/notification/created" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Copy page hierarchy
#
# POST /wiki/rest/api/content/{id}/pagehierarchy/copy
# operationId: copyPageHierarchy
# --titleOptions shape: {prefix?: string, replace?: string, search?: string}
export def "wiki-rest-content-pagehierarchy-copy copyPageHierarchy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --copyAttachments: oneof<nothing, bool> # If set to `true`, attachments are copied to the destination page. (default: false)
  --copyPermissions: oneof<nothing, bool> # If set to `true`, page permissions are copied to the destination page. (default: false)
  --copyProperties: oneof<nothing, bool> # If set to `true`, content properties are copied to the destination page. (default: false)
  --copyLabels: oneof<nothing, bool> # If set to `true`, labels are copied to the destination page. (default: false)
  --copyCustomContents: oneof<nothing, bool> # If set to `true`, custom contents are copied to the destination page. (default: false)
  --copyDescendants: oneof<nothing, bool> # If set to `true`, descendants are copied to the destination page. (default: true)
  destinationPageId: string
  --titleOptions: record # Required for copying page in the same space. — shape: {prefix?: string, replace?: string, search?: string}
]: any -> record<ari: string, id: string, links: record<status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/pagehierarchy/copy")
  let body = {copyAttachments: $copyAttachments, copyPermissions: $copyPermissions, copyProperties: $copyProperties, copyLabels: $copyLabels, copyCustomContents: $copyCustomContents, copyDescendants: $copyDescendants, destinationPageId: $destinationPageId, titleOptions: $titleOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copy single page
#
# POST /wiki/rest/api/content/{id}/copy
# operationId: copyPage
# --destination shape: {type: "space"|"existing_page"|"parent_page"|"parent_content", value: string}
# --body shape: {storage?: record, editor2?: record}
export def "wiki-rest-content-copy copyPage" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the content to expand. Maximum sub-expansions allowed is `8`.  - `childTypes.all` returns whether the content has attachments, comments, or child pages/whiteboards. Use this if you only need to check whether the content has children of a particular type. - `childTypes.attachment` returns whether the content has attachments. - `childTypes.comment` returns whether the content has comments. - `childTypes.page` returns whether the content has child pages. - `childTypes.whiteboard` returns whether the content has child whiteboards. - `childTypes.database` returns whether the content has child databases. - `childTypes.embed` returns whether the content has child embeds (smartlinks). - `childTypes.folder` returns whether the content has child folder. - `container` returns the space that the content is in. This is the same as the information returned by [Get space](#api-space-spaceKey-get). - `metadata.currentuser` returns information about the current user in relation to the content, including when they last viewed it, modified it, contributed to it, or added it as a favorite. - `metadata.properties` returns content properties that have been set via the Confluence REST API. - `metadata.labels` returns the labels that have been added to the content. - `metadata.frontend` this property is only used by Atlassian. - `operations` returns the operations for the content, which are used when setting permissions. - `children.page` returns pages that are descendants at the level immediately below the content. - `children.whiteboard` returns whiteboards that are descendants at the level immediately below the content. - `children.database` returns databases that are descendants at the level immediately below the content. - `children.embed` returns embeds (smartlinks) that are descendants at the level immediately below the content. - `children.folder` returns folders that are descendants at the level immediately below the content. - `children.attachment` returns all attachments for the content. - `children.comment` returns all comments on the content. - `restrictions.read.restrictions.user` returns the users that have permission to read the content. - `restrictions.read.restrictions.group` returns the groups that have permission to read the content. Note that this may return deleted groups, because deleting a group doesn't remove associated restrictions. - `restrictions.update.restrictions.user` returns the users that have permission to update the content. - `restrictions.update.restrictions.group` returns the groups that have permission to update the content. Note that this may return deleted groups because deleting a group doesn't remove associated restrictions. - `history` returns the history of the content, including the date it was created. - `history.lastUpdated` returns information about the most recent update of the content, including who updated it and when it was updated. - `history.previousVersion` returns information about the update prior to the current content update. - `history.contributors` returns all of the users who have contributed to the content. - `history.nextVersion` returns information about the update after to the current content update. - `ancestors` returns the parent content, if the content is a page or whiteboard. - `body` returns the body of the content in different formats, including the editor format, view format, and export format. - `body.storage` returns the body of content in storage format. - `body.view` returns the body of content in view format. - `version` returns information about the most recent update of the content, including who updated it and when it was updated. - `descendants.page` returns pages that are descendants at any level below the content. - `descendants.whiteboard` returns whiteboards that are descendants at any level below the content. - `descendants.database` returns databases that are descendants at any level below the content. - `descendants.embed` returns embeds (smartlinks) that are descendants at any level below the content. - `descendants.folder` returns folders that are descendants at any level below the content. - `descendants.attachment` returns all attachments for the content, same as `children.attachment`. - `descendants.comment` returns all comments on the content, same as `children.comment`. - `space` returns the space that the content is in. This is the same as the information returned by [Get space](#api-space-spaceKey-get).  In addition, the following comment-specific expansions can be used: - `extensions.inlineProperties` returns inline comment-specific properties. - `extensions.resolution` returns the resolution status of each comment.
  --copyAttachments: oneof<nothing, bool> # If set to `true`, attachments are copied to the destination page. (default: false)
  --copyPermissions: oneof<nothing, bool> # If set to `true`, page permissions are copied to the destination page. (default: false)
  --copyProperties: oneof<nothing, bool> # If set to `true`, content properties are copied to the destination page. (default: false)
  --copyLabels: oneof<nothing, bool> # If set to `true`, labels are copied to the destination page. (default: false)
  --copyCustomContents: oneof<nothing, bool> # If set to `true`, custom contents are copied to the destination page. (default: false)
  destination: record # Defines where the page will be copied to, and can be one of the following types.    - `parent_page`: page will be copied as a child of the specified parent page   - `parent_content`: page will be copied as a child of the specified parent content   - `space`: page will be copied to the specified space as a root page on the space   - `existing_page`: page will be copied and replace the specified page — shape: {type: "space"|"existing_page"|"parent_page"|"parent_content", value: string}
  --pageTitle: string # If defined, this will replace the title of the destination page.
  --body-body: record # If defined, this will replace the body of the destination page. — shape: {storage?: record, editor2?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/copy" $qp)
  let body = {copyAttachments: $copyAttachments, copyPermissions: $copyPermissions, copyProperties: $copyProperties, copyLabels: $copyLabels, copyCustomContents: $copyCustomContents, destination: $destination, pageTitle: $pageTitle, body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check content permissions
#
# POST /wiki/rest/api/content/{id}/permission/check
# operationId: checkContentPermission
# --subject shape: {type: "user"|"group", identifier: string}
export def "wiki-rest-content-permission-check checkContentPermission" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  subject: record # The user or group that the permission applies to. — shape: {type: "user"|"group", identifier: string}
  operation: string@operation-completer # The content permission operation to check.
]: any -> record<hasPermission: bool, errors: table<translation: string, args: list>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/permission/check")
  let body = {subject: $subject, operation: $operation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get restrictions
#
# GET /wiki/rest/api/content/{id}/restriction
# operationId: getRestrictions
export def "wiki-rest-content-restriction get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the content restrictions to expand. By default, the following objects are expanded: `restrictions.user`, `restrictions.group`.  - `restrictions.user` returns the piece of content that the restrictions are applied to. - `restrictions.group` returns the piece of content that the restrictions are applied to. - `content` returns the piece of content that the restrictions are applied to.
  --start: int # The starting index of the users and groups in the returned restrictions. (format: int32, default: 0)
  --limit: int # The maximum number of users and the maximum number of groups, in the returned restrictions, to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 100)
]: nothing -> record<results: table<operation: string, restrictions: record, content: record, _expandable: record, _links: record>, start: int, limit: int, size: int, restrictionsHash: string, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update restrictions
#
# PUT /wiki/rest/api/content/{id}/restriction
# operationId: updateRestrictions
# --results item shape: {operation: "administer"|"copy"|"create"|"delete"|"export"|"move"|"purge"|"purge_version"|"read"|"restore"|"update"|"use", restrictions: record, content?: record}
export def "wiki-rest-content-restriction updateRestrictions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the content restrictions (returned in response) to expand.  - `restrictions.user` returns the piece of content that the restrictions are applied to. Expanded by default. - `restrictions.group` returns the piece of content that the restrictions are applied to. Expanded by default. - `content` returns the piece of content that the restrictions are applied to.
  --results: list # item shape: {operation: "administer"|"copy"|"create"|"delete"|"export"|"move"|"purge"|"purge_version"|"read"|"restore"|"update"|"use", restrictions: record, content?: record}
  --start: int # format: int32
  --limit: int # format: int32
  --size: int # format: int32
  --restrictionsHash: string # This property is used by the UI to figure out whether a set of restrictions has changed.
  --links: record
]: any -> record<results: table<operation: string, restrictions: record, content: record, _expandable: record, _links: record>, start: int, limit: int, size: int, restrictionsHash: string, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction" $qp)
  let body = {results: $results, start: $start, limit: $limit, size: $size, restrictionsHash: $restrictionsHash, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add restrictions
#
# POST /wiki/rest/api/content/{id}/restriction
# operationId: addRestrictions
# --results item shape: {operation: "administer"|"copy"|"create"|"delete"|"export"|"move"|"purge"|"purge_version"|"read"|"restore"|"update"|"use", restrictions: record, content?: record}
export def "wiki-rest-content-restriction addRestrictions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the content restrictions (returned in response) to expand.  - `restrictions.user` returns the piece of content that the restrictions are applied to. Expanded by default. - `restrictions.group` returns the piece of content that the restrictions are applied to. Expanded by default. - `content` returns the piece of content that the restrictions are applied to.
  --results: list # item shape: {operation: "administer"|"copy"|"create"|"delete"|"export"|"move"|"purge"|"purge_version"|"read"|"restore"|"update"|"use", restrictions: record, content?: record}
  --start: int # format: int32
  --limit: int # format: int32
  --size: int # format: int32
  --restrictionsHash: string # This property is used by the UI to figure out whether a set of restrictions has changed.
  --links: record
]: any -> record<results: table<operation: string, restrictions: record, content: record, _expandable: record, _links: record>, start: int, limit: int, size: int, restrictionsHash: string, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction" $qp)
  let body = {results: $results, start: $start, limit: $limit, size: $size, restrictionsHash: $restrictionsHash, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete restrictions
#
# DELETE /wiki/rest/api/content/{id}/restriction
# operationId: deleteRestrictions
export def "wiki-rest-content-restriction delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the content restrictions (returned in response) to expand.  - `restrictions.user` returns the piece of content that the restrictions are applied to. Expanded by default. - `restrictions.group` returns the piece of content that the restrictions are applied to. Expanded by default. - `content` returns the piece of content that the restrictions are applied to.
]: nothing -> record<results: table<operation: string, restrictions: record, content: record, _expandable: record, _links: record>, start: int, limit: int, size: int, restrictionsHash: string, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get restrictions by operation
#
# GET /wiki/rest/api/content/{id}/restriction/byOperation
# operationId: getRestrictionsByOperation
export def "wiki-rest-content-restriction-by-operation list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the content restrictions to expand.  - `restrictions.user` returns the piece of content that the restrictions are applied to. Expanded by default. - `restrictions.group` returns the piece of content that the restrictions are applied to. Expanded by default. - `content` returns the piece of content that the restrictions are applied to.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction/byOperation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get restrictions for operation
#
# GET /wiki/rest/api/content/{id}/restriction/byOperation/{operationKey}
# operationId: getRestrictionsForOperation
export def "wiki-rest-content-restriction-by-operation get" [
  id: string
  operationKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the content restrictions to expand.  - `restrictions.user` returns the piece of content that the restrictions are applied to. Expanded by default. - `restrictions.group` returns the piece of content that the restrictions are applied to. Expanded by default. - `content` returns the piece of content that the restrictions are applied to.
  --start: int # The starting index of the users and groups in the returned restrictions. (format: int32, default: 0)
  --limit: int # The maximum number of users and the maximum number of groups, in the returned restrictions, to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 100)
]: nothing -> record<operation: string, restrictions: record<user: record<results: list, start: int, limit: int, size: int, totalSize: int, _links: record>, group: record<results: list, start: int, limit: int, size: int>, _expandable: record<user: string, group: string>>, content: record<id: string, type: string, status: string, title: string, space: record<id: int, key: string, alias: string, name: string, icon: record, description: record, homepage: any, type: string, metadata: record, operations: list, permissions: list, status: string, settings: record, theme: record, lookAndFeel: record, history: record, _expandable: record, _links: record>, history: record<latest: bool, createdBy: record, ownedBy: record, lastOwnedBy: record, createdDate: string, lastUpdated: record, previousVersion: record, contributors: record, nextVersion: record, _expandable: record, _links: record>, version: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, ancestors: list<any>, operations: list<record>, children: record<attachment: record, comment: record, page: record, whiteboard: record, database: record, embed: record, folder: record, _expandable: record, _links: record>, childTypes: record<attachment: record, comment: record, page: record, _expandable: record>, descendants: record<attachment: record, comment: record, page: record, whiteboard: record, database: record, embed: record, folder: record, _expandable: record, _links: record>, container: record, body: record<view: record, export_view: record, styled_view: record, storage: record, wiki: record, editor: record, editor2: record, anonymous_export_view: record, atlas_doc_format: record, dynamic: record, raw: record, _expandable: record>, restrictions: record<read: any, update: any, _expandable: record, _links: record>, metadata: record<currentuser: record, properties: record, frontend: record, labels: any>, macroRenderedOutput: record, extensions: record, _expandable: record<childTypes: string, container: string, metadata: string, operations: string, children: string, restrictions: string, history: string, ancestors: string, body: string, version: string, descendants: string, space: string, extensions: string, schedulePublishDate: string, schedulePublishInfo: string, macroRenderedOutput: string>, _links: record>, _expandable: record<restrictions: string, content: string>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction/byOperation/($operationKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content restriction status for group
#
# GET /wiki/rest/api/content/{id}/restriction/byOperation/{operationKey}/byGroupId/{groupId}
# operationId: getIndividualGroupRestrictionStatusByGroupId
export def "wiki-rest-content-restriction-by-operation-by-group-id get" [
  id: string
  operationKey: string
  groupId: string
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
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction/byOperation/($operationKey)/byGroupId/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add group to content restriction
#
# PUT /wiki/rest/api/content/{id}/restriction/byOperation/{operationKey}/byGroupId/{groupId}
# operationId: addGroupToContentRestrictionByGroupId
export def "wiki-rest-content-restriction-by-operation-by-group-id addGroupToContentRestrictionByGroupId" [
  id: string
  operationKey: string
  groupId: string
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
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction/byOperation/($operationKey)/byGroupId/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove group from content restriction
#
# DELETE /wiki/rest/api/content/{id}/restriction/byOperation/{operationKey}/byGroupId/{groupId}
# operationId: removeGroupFromContentRestriction
export def "wiki-rest-content-restriction-by-operation-by-group-id removeGroupFromContentRestriction" [
  id: string
  operationKey: string
  groupId: string
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
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction/byOperation/($operationKey)/byGroupId/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content restriction status for user
#
# GET /wiki/rest/api/content/{id}/restriction/byOperation/{operationKey}/user
# operationId: getContentRestrictionStatusForUser
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-content-restriction-by-operation-user get" [
  id: string
  operationKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction/byOperation/($operationKey)/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add user to content restriction
#
# PUT /wiki/rest/api/content/{id}/restriction/byOperation/{operationKey}/user
# operationId: addUserToContentRestriction
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-content-restriction-by-operation-user addUserToContentRestriction" [
  id: string
  operationKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction/byOperation/($operationKey)/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove user from content restriction
#
# DELETE /wiki/rest/api/content/{id}/restriction/byOperation/{operationKey}/user
# operationId: removeUserFromContentRestriction
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-content-restriction-by-operation-user removeUserFromContentRestriction" [
  id: string
  operationKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/restriction/byOperation/($operationKey)/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content state
#
# GET /wiki/rest/api/content/{id}/state
# operationId: getContentState
export def "wiki-rest-content-state get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-2 # Set status to one of [current,draft,archived]. Default value is current. (default: current)
]: nothing -> record<contentState: record<id: int, name: string, color: string>, lastUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/state" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the content state of a content and publishes a new version of the content.
#
# PUT /wiki/rest/api/content/{id}/state
# operationId: setContentState
export def "wiki-rest-content-state setContentState" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Status of content onto which state will be placed. If draft, then draft state will change. If current, state will be placed onto a new version of the content with same body as previous version.
  --name: string # Name of content state. Maximum 20 characters.
  --color: string # Color of state. Must be in 6 digit hex form (#FFFFFF). The default colors offered in the UI are:  #ff7452 (red),  #2684ff (blue),  #ffc400 (yellow),  #57d9a3 (green), and  #8777d9 (purple)
  --body-id: int # id of state. This can be 0,1, or 2 if you wish to specify a default space state. (format: int64)
]: any -> record<contentState: record<id: int, name: string, color: string>, lastUpdated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/state" $qp)
  let body = {name: $name, color: $color, id: $body_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes the content state of a content and publishes a new version.
#
# DELETE /wiki/rest/api/content/{id}/state
# operationId: removeContentState
export def "wiki-rest-content-state removeContentState" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # status of content state from which to delete state. Can be draft or archived
]: nothing -> record<contentState: record<id: int, name: string, color: string>, lastUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/state" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets available content states for content.
#
# GET /wiki/rest/api/content/{id}/state/available
# operationId: getAvailableContentStates
export def "wiki-rest-content-state-available get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<spaceContentStates: table<id: int, name: string, color: string>, customContentStates: table<id: int, name: string, color: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/state/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restore content version
#
# POST /wiki/rest/api/content/{id}/version
# operationId: restoreContentVersion
# --params shape: {versionNumber: int, message: string, restoreTitle?: bool}
export def "wiki-rest-content-version restoreContentVersion" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the content to expand. By default, the `content` object is expanded.  - `collaborators` returns the users that collaborated on the version. - `content` returns the content for the version.
  operationKey: string@operationKey-completer # Set to 'restore'.
  params: record # shape: {versionNumber: int, message: string, restoreTitle?: bool}
]: any -> record<by: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record<path: string, width: int, height: int, isDefault: bool>, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list<record>, details: record<business: record, personal: record>, personalSpace: record<id: int, key: string, alias: string, name: string, icon: record, description: record, homepage: record, type: string, metadata: record, operations: list, permissions: list, status: string, settings: record, theme: record, lookAndFeel: record, history: record, _expandable: record, _links: record>, _expandable: record<operations: string, details: string, personalSpace: string>, _links: record>, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: record<id: string, type: string, status: string, title: string, space: record<id: int, key: string, alias: string, name: string, icon: record, description: record, homepage: any, type: string, metadata: record, operations: list, permissions: list, status: string, settings: record, theme: record, lookAndFeel: record, history: record, _expandable: record, _links: record>, history: record<latest: bool, createdBy: record, ownedBy: record, lastOwnedBy: record, createdDate: string, lastUpdated: any, previousVersion: any, contributors: record, nextVersion: any, _expandable: record, _links: record>, version: any, ancestors: list<any>, operations: list<record>, children: record<attachment: record, comment: record, page: record, whiteboard: record, database: record, embed: record, folder: record, _expandable: record, _links: record>, childTypes: record<attachment: record, comment: record, page: record, _expandable: record>, descendants: record<attachment: record, comment: record, page: record, whiteboard: record, database: record, embed: record, folder: record, _expandable: record, _links: record>, container: record, body: record<view: record, export_view: record, styled_view: record, storage: record, wiki: record, editor: record, editor2: record, anonymous_export_view: record, atlas_doc_format: record, dynamic: record, raw: record, _expandable: record>, restrictions: record<read: record, update: record, _expandable: record, _links: record>, metadata: record<currentuser: record, properties: record, frontend: record, labels: any>, macroRenderedOutput: record, extensions: record, _expandable: record<childTypes: string, container: string, metadata: string, operations: string, children: string, restrictions: string, history: string, ancestors: string, body: string, version: string, descendants: string, space: string, extensions: string, schedulePublishDate: string, schedulePublishInfo: string, macroRenderedOutput: string>, _links: record>, collaborators: record<users: list<record>, userKeys: list<string>, _links: record>, _expandable: record<content: string, collaborators: string>, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/version" $qp)
  let body = {operationKey: $operationKey, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete content version
#
# DELETE /wiki/rest/api/content/{id}/version/{versionNumber}
# operationId: deleteContentVersion
export def "wiki-rest-content-version delete" [
  id: string
  versionNumber: int
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
  let full_url = (build-url $base $"/wiki/rest/api/content/($id)/version/($versionNumber)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Custom Content States
#
# GET /wiki/rest/api/content-states
# operationId: getCustomContentStates
export def "wiki-rest-content-states get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string, color: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/content-states")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Asynchronously convert content body
#
# POST /wiki/rest/api/contentbody/convert/async/{to}
# operationId: asyncConvertContentBodyRequest
export def "wiki-rest-contentbody-convert-async asyncConvertContentBodyRequest" [
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the content to expand and populate. Expands are dependent on the `to` conversion format and may be irrelevant for certain conversions (e.g. `macroRenderedOutput` is redundant when converting to `view` format).   If rendering to `view` format, and the body content being converted includes arbitrary nested content (such as macros); then it is  necessary to include webresource expands in the request. Webresources for content body are the batched JS and CSS dependencies for any nested dynamic content (i.e. macros).  - `embeddedContent` returns metadata for nested content (e.g. page included using page include macro) - `mediaToken` returns JWT token for retrieving attachment data from Media API - `macroRenderedOutput` additionally converts body to view format - `webresource.superbatch.uris.js` returns all common JS dependencies as static URLs - `webresource.superbatch.uris.css` returns all common CSS dependencies as static URLs - `webresource.superbatch.uris.all` returns all common dependencies as static URLs - `webresource.superbatch.tags.all` returns all common JS dependencies as html `<script>` tags - `webresource.superbatch.tags.css` returns all common CSS dependencies as html `<style>` tags - `webresource.superbatch.tags.js` returns all common dependencies as html `<script>` and `<style>` tags - `webresource.uris.js` returns JS dependencies specific to conversion - `webresource.uris.css` returns CSS dependencies specific to conversion - `webresource.uris.all` returns all dependencies specific to conversion      - `webresource.tags.all` returns common JS dependencies as html `<script>` tags - `webresource.tags.css` returns common CSS dependencies as html `<style>` tags - `webresource.tags.js` returns common dependencies as html `<script>` and `<style>` tags
  --spaceKeyContext: string # The space key used for resolving embedded content (page includes, files, and links) in the content body. For example, if the source content contains the link `<ac:link><ri:page ri:content-title="Example page" /><ac:link>` and the `spaceKeyContext=TEST` parameter is provided, then the link will be converted to a link to the "Example page" page in the "TEST" space.
  --contentIdContext: string # The content ID used to find the space for resolving embedded content (page includes, files, and links) in the content body. For example, if the source content contains the link `<ac:link><ri:page ri:content-title="Example page" /><ac:link>` and the `contentIdContext=123` parameter is provided, then the link will be converted to a link to the "Example page" page in the same space that has the content with ID=123. Note, `spaceKeyContext` will be ignored if this parameter is provided.
  --allowCache: oneof<nothing, bool> # Controls whether conversion results are cached and reused for identical requests.  - `false`: Each request creates a new conversion task, even if an identical request was made previously. - `true`: Enables caching behavior for identical requests from the same user.   - If no cached result exists, a new conversion task is created   - If a cached result exists, the existing task is marked as RERUNNING and will complete with status COMPLETED   - Returns the same task ID for identical requests, allowing you to retrieve the cached result (default: false)
  --embeddedContentRender: string@embeddedContentRender-completer # Mode used for rendering embedded content, like attachments.  - `current` renders the embedded content using the latest version. - `version-at-save` renders the embedded content using the version at the time of save. (default: current)
  value: string # The body of the content in the relevant format.
  representation: string@representation-completer # The content format type. Set the value of this property to the name of the format being used, e.g. 'storage'.
]: any -> record<asyncId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv") (serialize-qp "spaceKeyContext" $spaceKeyContext "scalar") (serialize-qp "contentIdContext" $contentIdContext "scalar") (serialize-qp "allowCache" $allowCache "scalar") (serialize-qp "embeddedContentRender" $embeddedContentRender "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/contentbody/convert/async/($to)" $qp)
  let body = {value: $value, representation: $representation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get asynchronously converted content body from the id or the current status of the task.
#
# GET /wiki/rest/api/contentbody/convert/async/{id}
# operationId: asyncConvertContentBodyResponse
export def "wiki-rest-contentbody-convert-async asyncConvertContentBodyResponse" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: string, representation: string, renderTaskId: string, error: string, status: string, embeddedContent: table<entityId: int, entityType: string, entity: record>, webresource: record<_expandable: record<uris: any>, keys: list<string>, contexts: list<string>, uris: record<all: any, css: any, js: any, _expandable: record>, tags: record<all: string, css: string, data: string, js: string, _expandable: record>, superbatch: record<uris: record, tags: record, metatags: string, _expandable: record>>, mediaToken: record<collectionIds: list<string>, contentId: string, expiryDateTime: string, fileIds: list<string>, token: string>, _expandable: record<content: string, embeddedContent: string, webresource: string, mediaToken: string>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/contentbody/convert/async/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create asynchronous content body conversion tasks in bulk
#
# POST /wiki/rest/api/contentbody/convert/async/bulk/tasks
# operationId: bulkAsyncConvertContentBodyRequest
# --conversionInputs item shape: {to: string, allowCache?: bool, spaceKeyContext?: string, contentIdContext?: string, embeddedContentRender?: "current"|"version-at-save", expand?: list, body: record}
export def "wiki-rest-contentbody-convert-async-bulk-tasks bulkAsyncConvertContentBodyRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conversionInputs: list # item shape: {to: string, allowCache?: bool, spaceKeyContext?: string, contentIdContext?: string, embeddedContentRender?: "current"|"version-at-save", expand?: list, body: record}
]: any -> table<asyncId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/contentbody/convert/async/bulk/tasks")
  let body = {conversionInputs: $conversionInputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get asynchronous content body conversion task result in bulk
#
# GET /wiki/rest/api/contentbody/convert/async/bulk/tasks
# operationId: bulkAsyncConvertContentBodyResponse
export def "wiki-rest-contentbody-convert-async-bulk-tasks bulkAsyncConvertContentBodyResponse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # The asyncIds of the conversion tasks.
]: nothing -> table<value: string, representation: string, renderTaskId: string, error: string, status: string, embeddedContent: list<record>, webresource: record<_expandable: record, keys: list, contexts: list, uris: record, tags: record, superbatch: record>, mediaToken: record<collectionIds: list, contentId: string, expiryDateTime: string, fileIds: list, token: string>, _expandable: record<content: string, embeddedContent: string, webresource: string, mediaToken: string>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/contentbody/convert/async/bulk/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get label information
#
# GET /wiki/rest/api/label
# operationId: getAllLabelContent
export def "wiki-rest-label get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the label to query.
  --type: string@type-completer-1 # The type of contents that are to be returned.
  --start: int # The starting offset for the results. (format: int32, default: 0)
  --limit: int # The number of results to be returned. (format: int32, default: 200)
]: nothing -> record<label: record<prefix: string, name: string, id: string, label: string>, associatedContents: record<results: list<record>, start: int, limit: int, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/label" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get groups
#
# GET /wiki/rest/api/group
# operationId: getGroups
export def "wiki-rest-group get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # The starting index of the returned groups. (format: int32, default: 0)
  --limit: int # The maximum number of groups to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 200)
  --accessType: string@accessType-completer # The group permission level for which to filter results.
]: nothing -> record<results: table<type: string, name: string, id: string, usageType: string, managedBy: string, _links: record>, start: int, limit: int, size: int, totalSize: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "accessType" $accessType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new user group
#
# POST /wiki/rest/api/group
# operationId: createGroup
export def "wiki-rest-group createGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<type: string, name: string, id: string, usageType: string, managedBy: string, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/group")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get group
#
# GET /wiki/rest/api/group/by-id
# operationId: getGroupByGroupId
export def "wiki-rest-group-by-id get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The id of the group.
]: nothing -> record<type: string, name: string, id: string, usageType: string, managedBy: string, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/group/by-id" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user group
#
# DELETE /wiki/rest/api/group/by-id
# operationId: removeGroupById
export def "wiki-rest-group-by-id removeGroupById" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Id of the group to delete.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/group/by-id" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search groups by partial query
#
# GET /wiki/rest/api/group/picker
# operationId: searchGroups
export def "wiki-rest-group-picker searchGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # the search term used to query results.
  --start: int # The starting index of the returned groups. (format: int32, default: 0)
  --limit: int # The maximum number of groups to return per page. Note, this is restricted to a maximum limit of 200 groups. (format: int32, default: 200)
  --shouldReturnTotalSize: oneof<nothing, bool> # Whether to include total size parameter in the results. Note, fetching total size property is an expensive operation; use it if your use case needs this value. (default: false)
]: nothing -> record<results: table<type: string, name: string, id: string, usageType: string, managedBy: string, _links: record>, start: int, limit: int, size: int, totalSize: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "shouldReturnTotalSize" $shouldReturnTotalSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/group/picker" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group members
#
# GET /wiki/rest/api/group/{groupId}/membersByGroupId
# operationId: getGroupMembersByGroupId
export def "wiki-rest-group-members-by-group-id get" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # The starting index of the returned users. (format: int32, default: 0)
  --limit: int # The maximum number of users to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 200)
  --shouldReturnTotalSize: oneof<nothing, bool> # Whether to include total size parameter in the results. Note, fetching total size property is an expensive operation; use it if your use case needs this value. (default: false)
  --expand: list # A multi-value parameter indicating which properties of the user to expand.    - `operations` returns the operations that the user is allowed to do.   - `personalSpace` returns the user's personal space, if it exists.   - `isExternalCollaborator`(@deprecated) see `isGuest` in response to find out whether the user is a guest.
]: nothing -> record<results: table<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, start: int, limit: int, size: int, totalSize: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "shouldReturnTotalSize" $shouldReturnTotalSize "scalar") (serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/group/($groupId)/membersByGroupId" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add member to group by groupId
#
# POST /wiki/rest/api/group/userByGroupId
# operationId: addUserToGroupByGroupId
export def "wiki-rest-group-user-by-group-id addUserToGroupByGroupId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupId: string # GroupId of the group whose membership is updated
  accountId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupId" $groupId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/group/userByGroupId" $qp)
  let body = {accountId: $accountId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove member from group using group id
#
# DELETE /wiki/rest/api/group/userByGroupId
# operationId: removeMemberFromGroupByGroupId
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-group-user-by-group-id removeMemberFromGroupByGroupId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupId: string # Id of the group whose membership is updated.
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupId" $groupId "scalar") (serialize-qp "accountId" $accountId "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/group/userByGroupId" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get long-running tasks
#
# GET /wiki/rest/api/longtask
# operationId: getTasks
export def "wiki-rest-longtask list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The key of the tasks.
  --start: int # The starting index of the returned tasks. (format: int32, default: 0)
  --limit: int # The maximum number of tasks to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 100)
]: nothing -> record<results: table<ari: string, id: string, name: record, elapsedTime: int, percentageComplete: int, successful: bool, finished: bool, messages: list, status: string, errors: list, additionalDetails: record>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/longtask" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get long-running task
#
# GET /wiki/rest/api/longtask/{id}
# operationId: getTask
export def "wiki-rest-longtask get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ari: string, id: string, name: record<key: string, args: list<record>>, elapsedTime: int, percentageComplete: int, successful: bool, finished: bool, messages: table<translation: string, args: list>, _links: record, status: string, errors: table<translation: string, args: list>, additionalDetails: record<destinationId: string, destinationUrl: string, totalPageNeedToCopy: int, additionalProperties: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/longtask/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find target entities related to a source entity
#
# GET /wiki/rest/api/relation/{relationName}/from/{sourceType}/{sourceKey}/to/{targetType}
# operationId: findTargetFromSource
export def "wiki-rest-relation-from-to findTargetFromSource" [
  relationName: string
  sourceType: string
  sourceKey: string
  targetType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sourceStatus: string # The status of the source. This parameter is only used when the `sourceType` is 'content'.
  --targetStatus: string # The status of the target. This parameter is only used when the `targetType` is 'content'.
  --sourceVersion: int # The version of the source. This parameter is only used when the `sourceType` is 'content' and the `sourceStatus` is 'historical'. (format: int32)
  --targetVersion: int # The version of the target. This parameter is only used when the `targetType` is 'content' and the `targetStatus` is 'historical'. (format: int32)
  --expand: list # A multi-value parameter indicating which properties of the response object to expand.  - `relationData` returns information about the relationship, such as who created it and when it was created. - `source` returns the source entity. - `target` returns the target entity.
  --start: int # The starting index of the returned relationships. (format: int32, default: 0)
  --limit: int # The maximum number of relationships to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 25)
]: nothing -> record<results: table<name: string, relationData: record, source: any, target: any, _expandable: record, _links: record>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceStatus" $sourceStatus "scalar") (serialize-qp "targetStatus" $targetStatus "scalar") (serialize-qp "sourceVersion" $sourceVersion "scalar") (serialize-qp "targetVersion" $targetVersion "scalar") (serialize-qp "expand" $expand "csv") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/relation/($relationName)/from/($sourceType)/($sourceKey)/to/($targetType)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find relationship from source to target
#
# GET /wiki/rest/api/relation/{relationName}/from/{sourceType}/{sourceKey}/to/{targetType}/{targetKey}
# operationId: getRelationship
export def "wiki-rest-relation-from-to get" [
  relationName: string
  sourceType: string
  sourceKey: string
  targetType: string
  targetKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sourceStatus: string # The status of the source. This parameter is only used when the `sourceType` is 'content'.
  --targetStatus: string # The status of the target. This parameter is only used when the `targetType` is 'content'.
  --sourceVersion: int # The version of the source. This parameter is only used when the `sourceType` is 'content' and the `sourceStatus` is 'historical'. (format: int32)
  --targetVersion: int # The version of the target. This parameter is only used when the `targetType` is 'content' and the `targetStatus` is 'historical'. (format: int32)
  --expand: list # A multi-value parameter indicating which properties of the response object to expand.  - `relationData` returns information about the relationship, such as who created it and when it was created. - `source` returns the source entity. - `target` returns the target entity.
]: nothing -> record<name: string, relationData: record<createdBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, createdDate: string, friendlyCreatedDate: string>, source: any, target: any, _expandable: record<relationData: string, source: string, target: string>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceStatus" $sourceStatus "scalar") (serialize-qp "targetStatus" $targetStatus "scalar") (serialize-qp "sourceVersion" $sourceVersion "scalar") (serialize-qp "targetVersion" $targetVersion "scalar") (serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/relation/($relationName)/from/($sourceType)/($sourceKey)/to/($targetType)/($targetKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create relationship
#
# PUT /wiki/rest/api/relation/{relationName}/from/{sourceType}/{sourceKey}/to/{targetType}/{targetKey}
# operationId: createRelationship
export def "wiki-rest-relation-from-to createRelationship" [
  relationName: string
  sourceType: string
  sourceKey: string
  targetType: string
  targetKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sourceStatus: string # The status of the source. This parameter is only used when the `sourceType` is 'content'.
  --targetStatus: string # The status of the target. This parameter is only used when the `targetType` is 'content'.
  --sourceVersion: int # The version of the source. This parameter is only used when the `sourceType` is 'content' and the `sourceStatus` is 'historical'. (format: int32)
  --targetVersion: int # The version of the target. This parameter is only used when the `targetType` is 'content' and the `targetStatus` is 'historical'. (format: int32)
]: nothing -> record<name: string, relationData: record<createdBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, createdDate: string, friendlyCreatedDate: string>, source: any, target: any, _expandable: record<relationData: string, source: string, target: string>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceStatus" $sourceStatus "scalar") (serialize-qp "targetStatus" $targetStatus "scalar") (serialize-qp "sourceVersion" $sourceVersion "scalar") (serialize-qp "targetVersion" $targetVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/relation/($relationName)/from/($sourceType)/($sourceKey)/to/($targetType)/($targetKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete relationship
#
# DELETE /wiki/rest/api/relation/{relationName}/from/{sourceType}/{sourceKey}/to/{targetType}/{targetKey}
# operationId: deleteRelationship
export def "wiki-rest-relation-from-to delete" [
  relationName: string
  sourceType: string
  sourceKey: string
  targetType: string
  targetKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sourceStatus: string # The status of the source. This parameter is only used when the `sourceType` is 'content'.
  --targetStatus: string # The status of the target. This parameter is only used when the `targetType` is 'content'.
  --sourceVersion: int # The version of the source. This parameter is only used when the `sourceType` is 'content' and the `sourceStatus` is 'historical'. (format: int32)
  --targetVersion: int # The version of the target. This parameter is only used when the `targetType` is 'content' and the `targetStatus` is 'historical'. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceStatus" $sourceStatus "scalar") (serialize-qp "targetStatus" $targetStatus "scalar") (serialize-qp "sourceVersion" $sourceVersion "scalar") (serialize-qp "targetVersion" $targetVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/relation/($relationName)/from/($sourceType)/($sourceKey)/to/($targetType)/($targetKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find source entities related to a target entity
#
# GET /wiki/rest/api/relation/{relationName}/to/{targetType}/{targetKey}/from/{sourceType}
# operationId: findSourcesForTarget
export def "wiki-rest-relation-to-from findSourcesForTarget" [
  relationName: string
  sourceType: string
  targetType: string
  targetKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sourceStatus: string # The status of the source. This parameter is only used when the `sourceType` is 'content'.
  --targetStatus: string # The status of the target. This parameter is only used when the `targetType` is 'content'.
  --sourceVersion: int # The version of the source. This parameter is only used when the `sourceType` is 'content' and the `sourceStatus` is 'historical'. (format: int32)
  --targetVersion: int # The version of the target. This parameter is only used when the `targetType` is 'content' and the `targetStatus` is 'historical'. (format: int32)
  --expand: list # A multi-value parameter indicating which properties of the response object to expand.  - `relationData` returns information about the relationship, such as who created it and when it was created. - `source` returns the source entity. - `target` returns the target entity.
  --start: int # The starting index of the returned relationships. (format: int32, default: 0)
  --limit: int # The maximum number of relationships to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 25)
]: nothing -> record<results: table<name: string, relationData: record, source: any, target: any, _expandable: record, _links: record>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceStatus" $sourceStatus "scalar") (serialize-qp "targetStatus" $targetStatus "scalar") (serialize-qp "sourceVersion" $sourceVersion "scalar") (serialize-qp "targetVersion" $targetVersion "scalar") (serialize-qp "expand" $expand "csv") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/relation/($relationName)/to/($targetType)/($targetKey)/from/($sourceType)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search content
#
# GET /wiki/rest/api/search
# operationId: searchByCQL
export def "wiki-rest-search searchByCQL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cql: string # The CQL query to be used for the search. See [Advanced Searching using CQL](https://developer.atlassian.com/cloud/confluence/advanced-searching-using-cql/) for instructions on how to build a CQL query.
  --cqlcontext: string # The space, content, and content status to execute the search against.  - `spaceKey` Key of the space to search against. Optional. - `contentId` ID of the content to search against. Optional. Must be in the space specified by `spaceKey`. - `contentStatuses` Content statuses to search against. Optional.  Specify these values in an object. For example, `cqlcontext={%22spaceKey%22:%22TEST%22, %22contentId%22:%22123%22}`
  --cursor: string # Pointer to a set of search results, returned as part of the `next` or `prev` URL from the previous search call.
  --next: oneof<nothing, bool> # default: false
  --prev: oneof<nothing, bool> # default: false
  --limit: int # The maximum number of content objects to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 25)
  --start: int # The start point of the collection to return (format: int32, default: 0)
  --includeArchivedSpaces: oneof<nothing, bool> # Whether to include content from archived spaces in the results. (default: false)
  --excludeCurrentSpaces: oneof<nothing, bool> # Whether to exclude current spaces and only show archived spaces. (default: false)
  --excerpt: string@excerpt-completer # The excerpt strategy to apply to the result (default: highlight)
  --sitePermissionTypeFilter: string@sitePermissionTypeFilter-completer # Filters users by permission type. Use `none` to default to licensed users, `externalCollaborator` for external/guest users, and `all` to include all permission types. (default: none)
  --param: int # format: int64
  --expand: list
]: nothing -> record<results: table<content: record, user: record, space: record, title: string, excerpt: string, url: string, resultParentContainer: record, resultGlobalContainer: record, breadcrumbs: list, entityType: string, iconCssClass: string, lastModified: string, friendlyLastModified: string, score: float>, start: int, limit: int, size: int, totalSize: int, cqlQuery: string, searchDuration: int, archivedResultCount: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cql" $cql "scalar") (serialize-qp "cqlcontext" $cqlcontext "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "prev" $prev "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "includeArchivedSpaces" $includeArchivedSpaces "scalar") (serialize-qp "excludeCurrentSpaces" $excludeCurrentSpaces "scalar") (serialize-qp "excerpt" $excerpt "scalar") (serialize-qp "sitePermissionTypeFilter" $sitePermissionTypeFilter "scalar") (serialize-qp "_" $param "scalar") (serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search users
#
# GET /wiki/rest/api/search/user
# operationId: searchUser
export def "wiki-rest-search-user searchUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cql: string # The CQL query to be used for the search. See [Advanced Searching using CQL](https://developer.atlassian.com/cloud/confluence/advanced-searching-using-cql/) for instructions on how to build a CQL query.  Example queries:           cql=type=user will return up to 10k users           cql=user="1234" will return user with accountId "1234"           You can also use IN, NOT IN, != operators           cql=user IN ("12", "34") will return users with accountids "12" and "34"           cql=user.fullname~jo will return users with nickname/full name starting with "jo"           cql=user.accountid="123" will return user with accountId "123"
  --start: int # The starting index of the returned users. (format: int32, default: 0)
  --limit: int # The maximum number of user objects to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 25)
  --expand: list # A multi-value parameter indicating which properties of the user to expand.  - `operations` returns the operations for the user, which are used when setting permissions. - `personalSpace` returns the personal space of the user.
  --sitePermissionTypeFilter: string@sitePermissionTypeFilter-completer # Filters users by permission type. Use `none` to default to licensed users, `externalCollaborator` for external/guest users, and `all` to include all permission types. (default: none)
]: nothing -> record<results: table<content: record, user: record, space: record, title: string, excerpt: string, url: string, resultParentContainer: record, resultGlobalContainer: record, breadcrumbs: list, entityType: string, iconCssClass: string, lastModified: string, friendlyLastModified: string, score: float>, start: int, limit: int, size: int, totalSize: int, cqlQuery: string, searchDuration: int, archivedResultCount: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cql" $cql "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "expand" $expand "csv") (serialize-qp "sitePermissionTypeFilter" $sitePermissionTypeFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/search/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get look and feel settings
#
# GET /wiki/rest/api/settings/lookandfeel
# operationId: getLookAndFeelSettings
export def "wiki-rest-settings-lookandfeel get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --spaceKey: string # The key of the space for which the look and feel settings will be returned. If this is not set, only the global look and feel settings are returned.
]: nothing -> record<selected: string, global: record<headings: record<color: string>, links: record<color: string>, menus: record<hoverOrFocus: record, color: string>, header: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, horizontalHeader: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, content: record<screen: record, container: record, header: record, body: record>, bordersAndDividers: record<color: string>, spaceReference: record>, theme: record<headings: record<color: string>, links: record<color: string>, menus: record<hoverOrFocus: record, color: string>, header: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, horizontalHeader: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, content: record<screen: record, container: record, header: record, body: record>, bordersAndDividers: record<color: string>, spaceReference: record>, custom: record<headings: record<color: string>, links: record<color: string>, menus: record<hoverOrFocus: record, color: string>, header: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, horizontalHeader: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, content: record<screen: record, container: record, header: record, body: record>, bordersAndDividers: record<color: string>, spaceReference: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "spaceKey" $spaceKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/settings/lookandfeel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Select look and feel settings
#
# PUT /wiki/rest/api/settings/lookandfeel
# operationId: updateLookAndFeel
export def "wiki-rest-settings-lookandfeel updateLookAndFeel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  spaceKey: string # The key of the space for which the look and feel settings will be set.
  lookAndFeelType: string@lookAndFeelType-completer
]: any -> record<spaceKey: string, lookAndFeelType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/settings/lookandfeel")
  let body = {spaceKey: $spaceKey, lookAndFeelType: $lookAndFeelType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update look and feel settings
#
# POST /wiki/rest/api/settings/lookandfeel/custom
# operationId: updateLookAndFeelSettings
# --headings shape: {color: string}
# --links shape: {color: string}
# --menus shape: {hoverOrFocus: record, color: string}
# --header shape: {backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record}
# --horizontalHeader shape: {backgroundColor: string, button?: record, primaryNavigation: record, secondaryNavigation?: record, search?: record}
# --content shape: {screen?: record, container?: record, header?: record, body?: record}
# --bordersAndDividers shape: {color: string}
export def "wiki-rest-settings-lookandfeel-custom updateLookAndFeelSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --spaceKey: string # The key of the space for which the look and feel settings will be updated. If this is not set, the global look and feel settings will be updated.
  headings: record # shape: {color: string}
  links: record # shape: {color: string}
  menus: record # shape: {hoverOrFocus: record, color: string}
  header: record # shape: {backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record}
  --horizontalHeader: record # shape: {backgroundColor: string, button?: record, primaryNavigation: record, secondaryNavigation?: record, search?: record}
  content: record # shape: {screen?: record, container?: record, header?: record, body?: record}
  bordersAndDividers: record # shape: {color: string}
  --spaceReference: record # nullable
]: any -> record<headings: record<color: string>, links: record<color: string>, menus: record<hoverOrFocus: record<backgroundColor: string>, color: string>, header: record<backgroundColor: string, button: record<backgroundColor: string, color: string>, primaryNavigation: record<color: string, highlightColor: string, hoverOrFocus: record>, secondaryNavigation: record<color: string, highlightColor: string, hoverOrFocus: record>, search: record<backgroundColor: string, color: string>>, horizontalHeader: record<backgroundColor: string, button: record<backgroundColor: string, color: string>, primaryNavigation: record<color: string, highlightColor: string, hoverOrFocus: record>, secondaryNavigation: record<color: string, highlightColor: string, hoverOrFocus: record>, search: record<backgroundColor: string, color: string>>, content: record<screen: record<background: string, backgroundAttachment: string, backgroundBlendMode: string, backgroundClip: string, backgroundColor: string, backgroundImage: string, backgroundOrigin: string, backgroundPosition: string, backgroundRepeat: string, backgroundSize: string, layer: record, gutterTop: string, gutterRight: string, gutterBottom: string, gutterLeft: string>, container: record<background: string, backgroundAttachment: string, backgroundBlendMode: string, backgroundClip: string, backgroundColor: string, backgroundImage: string, backgroundOrigin: string, backgroundPosition: string, backgroundRepeat: string, backgroundSize: string, padding: string, borderRadius: string>, header: record<background: string, backgroundAttachment: string, backgroundBlendMode: string, backgroundClip: string, backgroundColor: string, backgroundImage: string, backgroundOrigin: string, backgroundPosition: string, backgroundRepeat: string, backgroundSize: string, padding: string, borderRadius: string>, body: record<background: string, backgroundAttachment: string, backgroundBlendMode: string, backgroundClip: string, backgroundColor: string, backgroundImage: string, backgroundOrigin: string, backgroundPosition: string, backgroundRepeat: string, backgroundSize: string, padding: string, borderRadius: string>>, bordersAndDividers: record<color: string>, spaceReference: record, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "spaceKey" $spaceKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/settings/lookandfeel/custom" $qp)
  let body = {headings: $headings, links: $links, menus: $menus, header: $header, horizontalHeader: $horizontalHeader, content: $content, bordersAndDividers: $bordersAndDividers, spaceReference: $spaceReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset look and feel settings
#
# DELETE /wiki/rest/api/settings/lookandfeel/custom
# operationId: resetLookAndFeelSettings
export def "wiki-rest-settings-lookandfeel-custom resetLookAndFeelSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --spaceKey: string # The key of the space for which the look and feel settings will be reset. If this is not set, the global look and feel settings will be reset.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "spaceKey" $spaceKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/settings/lookandfeel/custom" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get system info
#
# GET /wiki/rest/api/settings/systemInfo
# operationId: getSystemInfo
export def "wiki-rest-settings-system-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cloudId: string, commitHash: string, baseUrl: string, fallbackBaseUrl: string, edition: string, siteTitle: string, defaultLocale: string, defaultTimeZone: string, microsPerimeter: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/settings/systemInfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get themes
#
# GET /wiki/rest/api/settings/theme
# operationId: getThemes
export def "wiki-rest-settings-theme list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # The starting index of the returned themes. (format: int32, default: 0)
  --limit: int # The maximum number of themes to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 100)
]: nothing -> record<results: table<themeKey: string, name: string, description: string, icon: record>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/settings/theme" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get global theme
#
# GET /wiki/rest/api/settings/theme/selected
# operationId: getGlobalTheme
export def "wiki-rest-settings-theme-selected get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<themeKey: string, name: string, description: string, icon: record<path: string, width: int, height: int, isDefault: bool>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/settings/theme/selected")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get theme
#
# GET /wiki/rest/api/settings/theme/{themeKey}
# operationId: getTheme
export def "wiki-rest-settings-theme get" [
  themeKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<themeKey: string, name: string, description: string, icon: record<path: string, width: int, height: int, isDefault: bool>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/settings/theme/($themeKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create space
#
# POST /wiki/rest/api/space
# operationId: createSpace
# --description shape: {plain: record}
# --permissions item shape: {subjects?: record, operation: record, anonymousAccess: bool, unlicensedAccess: bool}
export def "wiki-rest-space createSpace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new space.
  --key: string # The key for the new space. Format: See [Space keys](https://confluence.atlassian.com/x/lqNMMQ). If `alias` is not provided, this is required.
  --alias: string # This field will be used as the new identifier for the space in confluence page URLs. If the property is not provided the alias will be the provided key. This property is experimental and may be changed or removed in the future.
  --description: record # The description of the new/updated space. Note, only the 'plain' representation can be used for the description when creating or updating a space. (nullable) — shape: {plain: record}
  --permissions: list # The permissions for the new space. If no permissions are provided, the [Confluence default space permissions](https://confluence.atlassian.com/x/UAgzKw#CreateaSpace-Spacepermissions) are applied. Note that if permissions are provided, the space is created with only the provided set of permissions, not including the default space permissions. Space permissions can be modified after creation using the space permissions endpoints, and a private space can be created using the create private space endpoint. (nullable) — item shape: {subjects?: record, operation: record, anonymousAccess: bool, unlicensedAccess: bool}
]: any -> record<id: int, key: string, alias: string, name: string, icon: record<path: string, width: int, height: int, isDefault: bool>, description: record<plain: record<value: string, representation: string, embeddedContent: list>, view: record<value: string, representation: string, embeddedContent: list>, _expandable: record<view: string, plain: string>>, homepage: record<id: string, type: string, status: string, title: string, space: any, history: record<latest: bool, createdBy: record, ownedBy: record, lastOwnedBy: record, createdDate: string, lastUpdated: record, previousVersion: record, contributors: record, nextVersion: record, _expandable: record, _links: record>, version: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, ancestors: list<any>, operations: list<record>, children: record<attachment: record, comment: record, page: record, whiteboard: record, database: record, embed: record, folder: record, _expandable: record, _links: record>, childTypes: record<attachment: record, comment: record, page: record, _expandable: record>, descendants: record<attachment: record, comment: record, page: record, whiteboard: record, database: record, embed: record, folder: record, _expandable: record, _links: record>, container: record, body: record<view: record, export_view: record, styled_view: record, storage: record, wiki: record, editor: record, editor2: record, anonymous_export_view: record, atlas_doc_format: record, dynamic: record, raw: record, _expandable: record>, restrictions: record<read: record, update: record, _expandable: record, _links: record>, metadata: record<currentuser: record, properties: record, frontend: record, labels: any>, macroRenderedOutput: record, extensions: record, _expandable: record<childTypes: string, container: string, metadata: string, operations: string, children: string, restrictions: string, history: string, ancestors: string, body: string, version: string, descendants: string, space: string, extensions: string, schedulePublishDate: string, schedulePublishInfo: string, macroRenderedOutput: string>, _links: record>, type: string, metadata: record<labels: record<results: list, start: int, limit: int, size: int, _links: record>, _expandable: record>, operations: table<operation: string, targetType: string>, permissions: table<id: int, subjects: record, operation: record, anonymousAccess: bool, unlicensedAccess: bool>, status: string, settings: record<routeOverrideEnabled: bool, editor: record<page: string, blogpost: string, default: string>, contentMode: string, spaceKey: string, _links: record>, theme: record<themeKey: string, name: string, description: string, icon: record<path: string, width: int, height: int, isDefault: bool>, _links: record>, lookAndFeel: record<headings: record<color: string>, links: record<color: string>, menus: record<hoverOrFocus: record, color: string>, header: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, horizontalHeader: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, content: record<screen: record, container: record, header: record, body: record>, bordersAndDividers: record<color: string>, spaceReference: record>, history: record<createdDate: string, createdBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: any, _expandable: record, _links: record>>, _expandable: record<settings: string, metadata: string, operations: string, lookAndFeel: string, permissions: string, icon: string, description: string, theme: string, history: string, homepage: string, identifiers: string>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/space")
  let body = {name: $name, key: $key, alias: $alias, description: $description, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create private space
#
# POST /wiki/rest/api/space/_private
# operationId: createPrivateSpace
# --description shape: {plain: record}
# --permissions item shape: {subjects?: record, operation: record, anonymousAccess: bool, unlicensedAccess: bool}
export def "wiki-rest-space-private createPrivateSpace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new space.
  --key: string # The key for the new space. Format: See [Space keys](https://confluence.atlassian.com/x/lqNMMQ). If `alias` is not provided, this is required.
  --alias: string # This field will be used as the new identifier for the space in confluence page URLs. If the property is not provided the alias will be the provided key. This property is experimental and may be changed or removed in the future.
  --description: record # The description of the new/updated space. Note, only the 'plain' representation can be used for the description when creating or updating a space. (nullable) — shape: {plain: record}
  --permissions: list # The permissions for the new space. If no permissions are provided, the [Confluence default space permissions](https://confluence.atlassian.com/x/UAgzKw#CreateaSpace-Spacepermissions) are applied. Note that if permissions are provided, the space is created with only the provided set of permissions, not including the default space permissions. Space permissions can be modified after creation using the space permissions endpoints, and a private space can be created using the create private space endpoint. (nullable) — item shape: {subjects?: record, operation: record, anonymousAccess: bool, unlicensedAccess: bool}
]: any -> record<id: int, key: string, alias: string, name: string, icon: record<path: string, width: int, height: int, isDefault: bool>, description: record<plain: record<value: string, representation: string, embeddedContent: list>, view: record<value: string, representation: string, embeddedContent: list>, _expandable: record<view: string, plain: string>>, homepage: record<id: string, type: string, status: string, title: string, space: any, history: record<latest: bool, createdBy: record, ownedBy: record, lastOwnedBy: record, createdDate: string, lastUpdated: record, previousVersion: record, contributors: record, nextVersion: record, _expandable: record, _links: record>, version: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, ancestors: list<any>, operations: list<record>, children: record<attachment: record, comment: record, page: record, whiteboard: record, database: record, embed: record, folder: record, _expandable: record, _links: record>, childTypes: record<attachment: record, comment: record, page: record, _expandable: record>, descendants: record<attachment: record, comment: record, page: record, whiteboard: record, database: record, embed: record, folder: record, _expandable: record, _links: record>, container: record, body: record<view: record, export_view: record, styled_view: record, storage: record, wiki: record, editor: record, editor2: record, anonymous_export_view: record, atlas_doc_format: record, dynamic: record, raw: record, _expandable: record>, restrictions: record<read: record, update: record, _expandable: record, _links: record>, metadata: record<currentuser: record, properties: record, frontend: record, labels: any>, macroRenderedOutput: record, extensions: record, _expandable: record<childTypes: string, container: string, metadata: string, operations: string, children: string, restrictions: string, history: string, ancestors: string, body: string, version: string, descendants: string, space: string, extensions: string, schedulePublishDate: string, schedulePublishInfo: string, macroRenderedOutput: string>, _links: record>, type: string, metadata: record<labels: record<results: list, start: int, limit: int, size: int, _links: record>, _expandable: record>, operations: table<operation: string, targetType: string>, permissions: table<id: int, subjects: record, operation: record, anonymousAccess: bool, unlicensedAccess: bool>, status: string, settings: record<routeOverrideEnabled: bool, editor: record<page: string, blogpost: string, default: string>, contentMode: string, spaceKey: string, _links: record>, theme: record<themeKey: string, name: string, description: string, icon: record<path: string, width: int, height: int, isDefault: bool>, _links: record>, lookAndFeel: record<headings: record<color: string>, links: record<color: string>, menus: record<hoverOrFocus: record, color: string>, header: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, horizontalHeader: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, content: record<screen: record, container: record, header: record, body: record>, bordersAndDividers: record<color: string>, spaceReference: record>, history: record<createdDate: string, createdBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: any, _expandable: record, _links: record>>, _expandable: record<settings: string, metadata: string, operations: string, lookAndFeel: string, permissions: string, icon: string, description: string, theme: string, history: string, homepage: string, identifiers: string>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/space/_private")
  let body = {name: $name, key: $key, alias: $alias, description: $description, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update space
#
# PUT /wiki/rest/api/space/{spaceKey}
# operationId: updateSpace
# --description shape: {plain: record}
export def "wiki-rest-space updateSpace" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The updated name of the space. (nullable)
  --description: record # The description of the new/updated space. Note, only the 'plain' representation can be used for the description when creating or updating a space. (nullable) — shape: {plain: record}
  --homepage: record # The updated homepage for this space (nullable)
  --type: string # The updated type for this space.
  --status: string # The updated status for this space. (nullable)
]: any -> record<id: int, key: string, alias: string, name: string, icon: record<path: string, width: int, height: int, isDefault: bool>, description: record<plain: record<value: string, representation: string, embeddedContent: list>, view: record<value: string, representation: string, embeddedContent: list>, _expandable: record<view: string, plain: string>>, homepage: record<id: string, type: string, status: string, title: string, space: any, history: record<latest: bool, createdBy: record, ownedBy: record, lastOwnedBy: record, createdDate: string, lastUpdated: record, previousVersion: record, contributors: record, nextVersion: record, _expandable: record, _links: record>, version: record<by: record, when: string, friendlyWhen: string, message: string, number: int, minorEdit: bool, content: any, collaborators: record, _expandable: record, _links: record, contentTypeModified: bool, confRev: string, syncRev: string, syncRevSource: string>, ancestors: list<any>, operations: list<record>, children: record<attachment: record, comment: record, page: record, whiteboard: record, database: record, embed: record, folder: record, _expandable: record, _links: record>, childTypes: record<attachment: record, comment: record, page: record, _expandable: record>, descendants: record<attachment: record, comment: record, page: record, whiteboard: record, database: record, embed: record, folder: record, _expandable: record, _links: record>, container: record, body: record<view: record, export_view: record, styled_view: record, storage: record, wiki: record, editor: record, editor2: record, anonymous_export_view: record, atlas_doc_format: record, dynamic: record, raw: record, _expandable: record>, restrictions: record<read: record, update: record, _expandable: record, _links: record>, metadata: record<currentuser: record, properties: record, frontend: record, labels: any>, macroRenderedOutput: record, extensions: record, _expandable: record<childTypes: string, container: string, metadata: string, operations: string, children: string, restrictions: string, history: string, ancestors: string, body: string, version: string, descendants: string, space: string, extensions: string, schedulePublishDate: string, schedulePublishInfo: string, macroRenderedOutput: string>, _links: record>, type: string, metadata: record<labels: record<results: list, start: int, limit: int, size: int, _links: record>, _expandable: record>, operations: table<operation: string, targetType: string>, permissions: table<id: int, subjects: record, operation: record, anonymousAccess: bool, unlicensedAccess: bool>, status: string, settings: record<routeOverrideEnabled: bool, editor: record<page: string, blogpost: string, default: string>, contentMode: string, spaceKey: string, _links: record>, theme: record<themeKey: string, name: string, description: string, icon: record<path: string, width: int, height: int, isDefault: bool>, _links: record>, lookAndFeel: record<headings: record<color: string>, links: record<color: string>, menus: record<hoverOrFocus: record, color: string>, header: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, horizontalHeader: record<backgroundColor: string, button: record, primaryNavigation: record, secondaryNavigation: record, search: record>, content: record<screen: record, container: record, header: record, body: record>, bordersAndDividers: record<color: string>, spaceReference: record>, history: record<createdDate: string, createdBy: record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: any, _expandable: record, _links: record>>, _expandable: record<settings: string, metadata: string, operations: string, lookAndFeel: string, permissions: string, icon: string, description: string, theme: string, history: string, homepage: string, identifiers: string>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)")
  let body = {name: $name, description: $description, homepage: $homepage, type: $type, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete space
#
# DELETE /wiki/rest/api/space/{spaceKey}
# operationId: deleteSpace
export def "wiki-rest-space delete" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ari: string, id: string, links: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new permission to space
#
# POST /wiki/rest/api/space/{spaceKey}/permission
# operationId: addPermissionToSpace
# --subject shape: {type: "user"|"group", identifier: string}
# --operation shape: {key: "administer"|"archive"|"copy"|"create"|"delete"|"export"|"move"|"purge"|"purge_version"|"read"|"restore"|"restrict_content"|"update"|"use", target: "page"|"blogpost"|"comment"|"attachment"|"space"}
export def "wiki-rest-space-permission addPermissionToSpace" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  subject: record # The user or group that the permission applies to. — shape: {type: "user"|"group", identifier: string}
  operation: record # shape: {key: "administer"|"archive"|"copy"|"create"|"delete"|"export"|"move"|"purge"|"purge_version"|"read"|"restore"|"restrict_content"|"update"|"use", target: "page"|"blogpost"|"comment"|"attachment"|"space"}
  --links: record
]: any -> record<id: int, subject: record<type: string, identifier: string>, operation: record<key: string, target: string>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/permission")
  let body = {subject: $subject, operation: $operation, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add new custom content permission to space
#
# POST /wiki/rest/api/space/{spaceKey}/permission/custom-content
# operationId: addCustomContentPermissions
# --subject shape: {type: "user"|"group", identifier: string}
# --operations item shape: {key: "read"|"create"|"delete", target: string, access: bool}
export def "wiki-rest-space-permission-custom-content addCustomContentPermissions" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  subject: record # The user or group that the permission applies to. — shape: {type: "user"|"group", identifier: string}
  operations: list # item shape: {key: "read"|"create"|"delete", target: string, access: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/permission/custom-content")
  let body = {subject: $subject, operations: $operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a space permission
#
# DELETE /wiki/rest/api/space/{spaceKey}/permission/{id}
# operationId: removePermission
export def "wiki-rest-space-permission removePermission" [
  spaceKey: string
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
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/permission/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get space settings
#
# GET /wiki/rest/api/space/{spaceKey}/settings
# operationId: getSpaceSettings
export def "wiki-rest-space-settings get" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<routeOverrideEnabled: bool, editor: record<page: string, blogpost: string, default: string>, contentMode: string, spaceKey: string, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update space settings
#
# PUT /wiki/rest/api/space/{spaceKey}/settings
# operationId: updateSpaceSettings
export def "wiki-rest-space-settings updateSpaceSettings" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --routeOverrideEnabled: oneof<nothing, bool> # Defines whether an override for the space home should be used. This is used in conjunction with a space theme provided by an app. For example, if this property is set to true, a theme can display a page other than the space homepage when users visit the root URL for a space. This property allows apps to provide content-only theming without overriding the space home.
  --contentMode: string@contentMode-completer # The content rendering mode for the space. Controls spacing and typography in the editor and renderer. Valid values are "standard" and "compact". When set to "compact", content is rendered more densely with smaller spacing and typography. (nullable)
]: any -> record<routeOverrideEnabled: bool, editor: record<page: string, blogpost: string, default: string>, contentMode: string, spaceKey: string, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/settings")
  let body = {routeOverrideEnabled: $routeOverrideEnabled, contentMode: $contentMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get space suggested content states
#
# GET /wiki/rest/api/space/{spaceKey}/state
# operationId: getSpaceContentStates
export def "wiki-rest-space-state get" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string, color: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/state")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content state settings for space
#
# GET /wiki/rest/api/space/{spaceKey}/state/settings
# operationId: getContentStateSettings
export def "wiki-rest-space-state-settings get" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contentStatesAllowed: bool, customContentStatesAllowed: bool, spaceContentStatesAllowed: bool, spaceContentStates: table<id: int, name: string, color: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/state/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content in space with given content state
#
# GET /wiki/rest/api/space/{spaceKey}/state/content
# operationId: getContentsWithState
export def "wiki-rest-space-state-content get" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state-id: int # The id of the content state to filter content by (format: int32)
  --expand: list # A multi-value parameter indicating which properties of the content to expand. Options include: space, version, history, children, etc.  Ex: space,version
  --limit: int # Maximum number of results to return (format: int32, default: 25)
  --start: int # Number of result to start returning. (0 indexed) (format: int32)
]: nothing -> record<results: table<id: string, type: string, status: string, title: string, space: record, history: record, version: record, ancestors: list, operations: list, children: record, childTypes: record, descendants: record, container: record, body: record, restrictions: record, metadata: record, macroRenderedOutput: record, extensions: record, _expandable: record, _links: record>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state-id" $state_id "scalar") (serialize-qp "expand" $expand "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/state/content" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get space theme
#
# GET /wiki/rest/api/space/{spaceKey}/theme
# operationId: getSpaceTheme
export def "wiki-rest-space-theme get" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<themeKey: string, name: string, description: string, icon: record<path: string, width: int, height: int, isDefault: bool>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/theme")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set space theme
#
# PUT /wiki/rest/api/space/{spaceKey}/theme
# operationId: setSpaceTheme
export def "wiki-rest-space-theme setSpaceTheme" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  themeKey: string # The key of the theme to be set as the space theme.
]: any -> record<themeKey: string, name: string, description: string, icon: record<path: string, width: int, height: int, isDefault: bool>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/theme")
  let body = {themeKey: $themeKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset space theme
#
# DELETE /wiki/rest/api/space/{spaceKey}/theme
# operationId: resetSpaceTheme
export def "wiki-rest-space-theme resetSpaceTheme" [
  spaceKey: string
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
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/theme")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get space watchers
#
# GET /wiki/rest/api/space/{spaceKey}/watch
# operationId: getWatchersForSpace
export def "wiki-rest-space-watch get" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # The start point of the collection to return.
  --limit: string # The limit of the number of items to return, this may be restricted by fixed system limits.
]: nothing -> record<results: table<type: string, watcher: record, spaceKey: string, labelName: string, prefix: string>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/watch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Space Labels
#
# GET /wiki/rest/api/space/{spaceKey}/label
# operationId: getLabelsForSpace
export def "wiki-rest-space-label get" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --prefix: string@prefix-completer # Filters the results to labels with the specified prefix. If this parameter is not specified, then labels with any prefix will be returned.  - `global` prefix is used by labels that are on content within the provided space. - `my` prefix can be explicitly added by a user when adding a label via the UI, e.g. 'my:example-label'. - `team` prefix is used for labels applied to the space.
  --start: int # The starting index of the returned labels. (format: int32, default: 0)
  --limit: int # The maximum number of labels to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 200)
]: nothing -> record<results: table<prefix: string, name: string, id: string, label: string>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prefix" $prefix "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/label" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add labels to a space
#
# POST /wiki/rest/api/space/{spaceKey}/label
# operationId: addLabelsToSpace
export def "wiki-rest-space-label addLabelsToSpace" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<results: table<prefix: string, name: string, id: string, label: string>, start: int, limit: int, size: int, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/label")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove label from a space
#
# DELETE /wiki/rest/api/space/{spaceKey}/label
# operationId: deleteLabelFromSpace
export def "wiki-rest-space-label delete" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the label to remove
  --prefix: string # The prefix of the label to remove. If not provided defaults to global.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "prefix" $prefix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/space/($spaceKey)/label" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update content template
#
# PUT /wiki/rest/api/template
# operationId: updateContentTemplate
# --body shape: {view?: record, export_view?: record, styled_view?: record, storage?: record, editor?: record, editor2?: record, wiki?: record, atlas_doc_format?: record, anonymous_export_view?: record}
# --labels item shape: {prefix: string, name: string, id: string, label: string}
# --space shape: {key: string}
export def "wiki-rest-template updateContentTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  templateId: string # The ID of the template being updated.
  name: string # The name of the template. Set to the current `name` if this field is not being updated.
  templateType: string@templateType-completer # The type of the template. Set to `page`.
  --body-body: record # The body of the new content. Does not apply to attachments. Only one body format should be specified as the property for this object, e.g. `storage`.  Note, `editor2` format is used by Atlassian only. `anonymous_export_view` is the same as `export_view` format but only content viewable by an anonymous user is included. — shape: {view?: record, export_view?: record, styled_view?: record, storage?: record, editor?: record, editor2?: record, wiki?: record, atlas_doc_format?: record, anonymous_export_view?: record}
  --description: string # A description of the template.
  --labels: list # Labels for the template. — item shape: {prefix: string, name: string, id: string, label: string}
  --space: record # The key for the space of the template. Required if the template is a space template. Set this to the current `space.key`. (nullable) — shape: {key: string}
]: any -> record<templateId: string, originalTemplate: record<pluginKey: string, moduleKey: string>, referencingBlueprint: string, name: string, description: string, space: record, labels: table<prefix: string, name: string, id: string, label: string>, templateType: string, editorVersion: string, body: record<view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, styled_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, storage: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor2: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, wiki: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, atlas_doc_format: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, anonymous_export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>>, _expandable: record<body: string>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/template")
  let body = {templateId: $templateId, name: $name, templateType: $templateType, body: $body_body, description: $description, labels: $labels, space: $space} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create content template
#
# POST /wiki/rest/api/template
# operationId: createContentTemplate
# --body shape: {view?: record, export_view?: record, styled_view?: record, storage?: record, editor?: record, editor2?: record, wiki?: record, atlas_doc_format?: record, anonymous_export_view?: record}
# --labels item shape: {prefix: string, name: string, id: string, label: string}
# --space shape: {key: string}
export def "wiki-rest-template createContentTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new template.
  templateType: string # The type of the new template. Set to `page`.
  --body-body: record # The body of the new content. Does not apply to attachments. Only one body format should be specified as the property for this object, e.g. `storage`.  Note, `editor2` format is used by Atlassian only. `anonymous_export_view` is the same as `export_view` format but only content viewable by an anonymous user is included. — shape: {view?: record, export_view?: record, styled_view?: record, storage?: record, editor?: record, editor2?: record, wiki?: record, atlas_doc_format?: record, anonymous_export_view?: record}
  --description: string # A description of the new template.
  --labels: list # Labels for the new template. — item shape: {prefix: string, name: string, id: string, label: string}
  --space: record # The key for the space of the new template. Only applies to space templates. If the spaceKey is not specified, the template will be created as a global template. (nullable) — shape: {key: string}
]: any -> record<templateId: string, originalTemplate: record<pluginKey: string, moduleKey: string>, referencingBlueprint: string, name: string, description: string, space: record, labels: table<prefix: string, name: string, id: string, label: string>, templateType: string, editorVersion: string, body: record<view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, styled_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, storage: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor2: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, wiki: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, atlas_doc_format: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, anonymous_export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>>, _expandable: record<body: string>, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wiki/rest/api/template")
  let body = {name: $name, templateType: $templateType, body: $body_body, description: $description, labels: $labels, space: $space} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get blueprint templates
#
# GET /wiki/rest/api/template/blueprint
# operationId: getBlueprintTemplates
export def "wiki-rest-template-blueprint get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --spaceKey: string # The key of the space to be queried for templates. If the `spaceKey` is not specified, global blueprint templates will be returned.
  --start: int # The starting index of the returned templates. (format: int32, default: 0)
  --limit: int # The maximum number of templates to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 25)
  --expand: list # A multi-value parameter indicating which properties of the template to expand.  - `body` or `body.storage` returns the content of the template in storage format.
]: nothing -> record<results: table<templateId: string, originalTemplate: record, referencingBlueprint: string, name: string, description: string, space: record, labels: list, templateType: string, editorVersion: string, body: record, _expandable: record, _links: record>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "spaceKey" $spaceKey "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/template/blueprint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content templates
#
# GET /wiki/rest/api/template/page
# operationId: getContentTemplates
export def "wiki-rest-template-page get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --spaceKey: string # The key of the space to be queried for templates. If the `spaceKey` is not specified, global templates will be returned.
  --start: int # The starting index of the returned templates. (format: int32, default: 0)
  --limit: int # The maximum number of templates to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 25)
  --expand: list # A multi-value parameter indicating which properties of the template to expand.  - `body` or `body.storage` returns the content of the template in storage format.
]: nothing -> record<results: table<templateId: string, originalTemplate: record, referencingBlueprint: string, name: string, description: string, space: record, labels: list, templateType: string, editorVersion: string, body: record, _expandable: record, _links: record>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "spaceKey" $spaceKey "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/template/page" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content template
#
# GET /wiki/rest/api/template/{contentTemplateId}
# operationId: getContentTemplate
export def "wiki-rest-template get" [
  contentTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the template to expand.  - `body` or `body.storage` returns the content of the template in storage format.
]: nothing -> record<templateId: string, originalTemplate: record<pluginKey: string, moduleKey: string>, referencingBlueprint: string, name: string, description: string, space: record, labels: table<prefix: string, name: string, id: string, label: string>, templateType: string, editorVersion: string, body: record<view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, styled_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, storage: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, editor2: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, wiki: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, atlas_doc_format: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>, anonymous_export_view: record<value: string, representation: string, embeddedContent: list, webresource: record, mediaToken: record, _expandable: record, _links: record>>, _expandable: record<body: string>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/template/($contentTemplateId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove template
#
# DELETE /wiki/rest/api/template/{contentTemplateId}
# operationId: removeTemplate
export def "wiki-rest-template removeTemplate" [
  contentTemplateId: string
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
  let full_url = (build-url $base $"/wiki/rest/api/template/($contentTemplateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user
#
# GET /wiki/rest/api/user
# operationId: getUser
export def "wiki-rest-user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
  --expand: list # A multi-value parameter indicating which properties of the user to expand.    - `operations` returns the operations that the user is allowed to do.   - `personalSpace` returns the user's personal space, if it exists.   - `isExternalCollaborator`(@deprecated) see `isGuest` in response to find out whether the user is a guest.
]: nothing -> record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record<path: string, width: int, height: int, isDefault: bool>, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: table<operation: string, targetType: string>, details: record<business: record<position: string, department: string, location: string>, personal: record<phone: string, im: string, website: string, email: string>>, personalSpace: record<id: int, key: string, alias: string, name: string, icon: record<path: string, width: int, height: int, isDefault: bool>, description: record<plain: record, view: record, _expandable: record>, homepage: record<id: string, type: string, status: string, title: string, space: any, history: record, version: record, ancestors: list, operations: list, children: record, childTypes: record, descendants: record, container: record, body: record, restrictions: record, metadata: record, macroRenderedOutput: record, extensions: record, _expandable: record, _links: record>, type: string, metadata: record<labels: record, _expandable: record>, operations: list<record>, permissions: list<record>, status: string, settings: record<routeOverrideEnabled: bool, editor: record, contentMode: string, spaceKey: string, _links: record>, theme: record<themeKey: string, name: string, description: string, icon: record, _links: record>, lookAndFeel: record<headings: record, links: record, menus: record, header: record, horizontalHeader: record, content: record, bordersAndDividers: record, spaceReference: record>, history: record<createdDate: string, createdBy: any>, _expandable: record<settings: string, metadata: string, operations: string, lookAndFeel: string, permissions: string, icon: string, description: string, theme: string, history: string, homepage: string, identifiers: string>, _links: record>, _expandable: record<operations: string, details: string, personalSpace: string>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $accountId "scalar") (serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get anonymous user
#
# GET /wiki/rest/api/user/anonymous
# operationId: getAnonymousUser
export def "wiki-rest-user-anonymous get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the user to expand.    - `operations` returns the operations that the user is allowed to do.
]: nothing -> record<type: string, profilePicture: record<path: string, width: int, height: int, isDefault: bool>, displayName: string, operations: table<operation: string, targetType: string>, _expandable: record<operations: string>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/user/anonymous" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current user
#
# GET /wiki/rest/api/user/current
# operationId: getCurrentUser
export def "wiki-rest-user-current get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: list # A multi-value parameter indicating which properties of the user to expand.    - `operations` returns the operations that the user is allowed to do.   - `personalSpace` returns the user's personal space, if it exists.   - `isExternalCollaborator`(@deprecated) see `isGuest` in response to find out whether the user is a guest.
]: nothing -> record<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record<path: string, width: int, height: int, isDefault: bool>, displayName: string, timeZone: string, externalCollaborator: bool, isExternalCollaborator: bool, isGuest: bool, operations: table<operation: string, targetType: string>, details: record<business: record<position: string, department: string, location: string>, personal: record<phone: string, im: string, website: string, email: string>>, personalSpace: record<id: int, key: string, alias: string, name: string, icon: record<path: string, width: int, height: int, isDefault: bool>, description: record<plain: record, view: record, _expandable: record>, homepage: record<id: string, type: string, status: string, title: string, space: any, history: record, version: record, ancestors: list, operations: list, children: record, childTypes: record, descendants: record, container: record, body: record, restrictions: record, metadata: record, macroRenderedOutput: record, extensions: record, _expandable: record, _links: record>, type: string, metadata: record<labels: record, _expandable: record>, operations: list<record>, permissions: list<record>, status: string, settings: record<routeOverrideEnabled: bool, editor: record, contentMode: string, spaceKey: string, _links: record>, theme: record<themeKey: string, name: string, description: string, icon: record, _links: record>, lookAndFeel: record<headings: record, links: record, menus: record, header: record, horizontalHeader: record, content: record, bordersAndDividers: record, spaceReference: record>, history: record<createdDate: string, createdBy: any>, _expandable: record<settings: string, metadata: string, operations: string, lookAndFeel: string, permissions: string, icon: string, description: string, theme: string, history: string, homepage: string, identifiers: string>, _links: record>, _expandable: record<operations: string, details: string, personalSpace: string>, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/user/current" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group memberships for user
#
# GET /wiki/rest/api/user/memberof
# operationId: getGroupMembershipsForUser
export def "wiki-rest-user-memberof get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
  --start: int # The starting index of the returned groups. (format: int32, default: 0)
  --limit: int # The maximum number of groups to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 200)
]: nothing -> record<results: table<type: string, name: string, id: string, usageType: string, managedBy: string, _links: record>, start: int, limit: int, size: int, totalSize: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $accountId "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/user/memberof" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple users using ids
#
# GET /wiki/rest/api/user/bulk
# operationId: getBulkUserLookup
export def "wiki-rest-user-bulk get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountId: string # A list of accountId's of users to be returned.
  --expand: list # A multi-value parameter indicating which properties of the user to expand.    - `operations` returns the operations that the user is allowed to do.   - `personalSpace` returns the user's personal space, if it exists.   - `isExternalCollaborator`(@deprecated) use `isGuest` instead to return whether the user is a guest.
]: nothing -> record<results: table<type: string, username: string, userKey: string, accountId: string, accountType: string, email: string, publicName: string, profilePicture: record, displayName: string, timeZone: string, isExternalCollaborator: bool, isGuest: bool, operations: list, details: record, personalSpace: record, _expandable: record, _links: record>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $accountId "scalar") (serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/user/bulk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content watch status
#
# GET /wiki/rest/api/user/watch/content/{contentId}
# operationId: getContentWatchStatus
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-user-watch-content get" [
  contentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
]: nothing -> record<watching: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/user/watch/content/($contentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add content watcher
#
# POST /wiki/rest/api/user/watch/content/{contentId}
# operationId: addContentWatcher
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-user-watch-content addContentWatcher" [
  contentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/user/watch/content/($contentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove content watcher
#
# DELETE /wiki/rest/api/user/watch/content/{contentId}
# operationId: removeContentWatcher
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-user-watch-content removeContentWatcher" [
  contentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
  --X-Atlassian-Token: string # Note, you must add header when making a request, as this operation has XSRF protection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/user/watch/content/($contentId)" $qp)
  let extra_headers = {"X-Atlassian-Token": $X_Atlassian_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get label watch status
#
# GET /wiki/rest/api/user/watch/label/{labelName}
# operationId: isWatchingLabel
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-user-watch-label isWatchingLabel" [
  labelName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
]: nothing -> record<watching: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/user/watch/label/($labelName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add label watcher
#
# POST /wiki/rest/api/user/watch/label/{labelName}
# operationId: addLabelWatcher
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-user-watch-label addLabelWatcher" [
  labelName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
  --X-Atlassian-Token: string # Note, you must add header when making a request, as this operation has XSRF protection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/user/watch/label/($labelName)" $qp)
  let extra_headers = {"X-Atlassian-Token": $X_Atlassian_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove label watcher
#
# DELETE /wiki/rest/api/user/watch/label/{labelName}
# operationId: removeLabelWatcher
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-user-watch-label removeLabelWatcher" [
  labelName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/user/watch/label/($labelName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get space watch status
#
# GET /wiki/rest/api/user/watch/space/{spaceKey}
# operationId: isWatchingSpace
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-user-watch-space isWatchingSpace" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
]: nothing -> record<watching: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/user/watch/space/($spaceKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add space watcher
#
# POST /wiki/rest/api/user/watch/space/{spaceKey}
# operationId: addSpaceWatcher
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-user-watch-space addSpaceWatcher" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
  --X-Atlassian-Token: string # Note, you must add header when making a request, as this operation has XSRF protection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/user/watch/space/($spaceKey)" $qp)
  let extra_headers = {"X-Atlassian-Token": $X_Atlassian_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove space watch
#
# DELETE /wiki/rest/api/user/watch/space/{spaceKey}
# operationId: removeSpaceWatch
@deprecated --flag key
@deprecated --flag username
export def "wiki-rest-user-watch-space removeSpaceWatch" [
  spaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --username: string # This parameter is no longer available and will be removed from the documentation soon. Use `accountId` instead. See the [deprecation notice](/cloud/confluence/deprecation-notice-user-privacy-api-migration-guide/) for details. (DEPRECATED)
  --accountId: string # The account ID of the user. The accountId uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/user/watch/space/($spaceKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user email address
#
# GET /wiki/rest/api/user/email
# operationId: getPrivacyUnsafeUserEmail
export def "wiki-rest-user-email get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountId: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, `384093:32b4d9w0-f6a5-3535-11a3-9c8c88d10192`. Required.
]: nothing -> record<accountId: string, email: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/user/email" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user email addresses in batch
#
# GET /wiki/rest/api/user/email/bulk
# operationId: getPrivacyUnsafeUserEmailBulk
export def "wiki-rest-user-email-bulk get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountId: list # The account IDs of the users.
]: nothing -> table<accountId: string, email: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $accountId "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/api/user/email/bulk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get modules
#
# GET /wiki/rest/atlassian-connect/1/app/module/dynamic
# operationId: getModules
export def "wiki-rest-atlassian-connect-1-app-module-dynamic get" [
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
  let full_url = (build-url $base "/wiki/rest/atlassian-connect/1/app/module/dynamic")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register modules
#
# POST /wiki/rest/atlassian-connect/1/app/module/dynamic
# operationId: registerModules
export def "wiki-rest-atlassian-connect-1-app-module-dynamic registerModules" [
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
  let full_url = (build-url $base "/wiki/rest/atlassian-connect/1/app/module/dynamic")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Remove modules
#
# DELETE /wiki/rest/atlassian-connect/1/app/module/dynamic
# operationId: removeModules
export def "wiki-rest-atlassian-connect-1-app-module-dynamic removeModules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --moduleKey: list # The key of the module to remove. To include multiple module keys, provide multiple copies of this parameter. For example, `moduleKey=dynamic-attachment-entity-property&moduleKey=dynamic-select-field`. Nonexistent keys are ignored.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "moduleKey" $moduleKey "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/wiki/rest/atlassian-connect/1/app/module/dynamic" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get views
#
# GET /wiki/rest/api/analytics/content/{contentId}/views
# operationId: getViews
export def "wiki-rest-analytics-content-views get" [
  contentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromDate: string # The number of views for the content since the date. (e.g. 2021-03-21T00:00:00.000Z)
]: nothing -> record<id: int, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/analytics/content/($contentId)/views" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get viewers
#
# GET /wiki/rest/api/analytics/content/{contentId}/viewers
# operationId: getViewers
export def "wiki-rest-analytics-content-viewers get" [
  contentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromDate: string # The number of views for the content since the date. (e.g. 2021-03-21T00:00:00.000Z)
]: nothing -> record<id: int, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/analytics/content/($contentId)/viewers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user properties
#
# GET /wiki/rest/api/user/{userId}/property
# operationId: getUserProperties
export def "wiki-rest-user-property list" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # The starting index of the returned properties. (format: int32, default: 0)
  --limit: int # The maximum number of properties to return per page. Note, this may be restricted by fixed system limits. (format: int32, default: 5)
]: nothing -> record<results: table<key: string>, start: int, limit: int, size: int, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wiki/rest/api/user/($userId)/property" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user property
#
# GET /wiki/rest/api/user/{userId}/property/{key}
# operationId: getUserProperty
export def "wiki-rest-user-property get" [
  userId: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: record, id: string, lastModifiedDate: string, createdDate: string, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/user/($userId)/property/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user property
#
# PUT /wiki/rest/api/user/{userId}/property/{key}
# operationId: updateUserProperty
export def "wiki-rest-user-property updateUserProperty" [
  userId: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  value: record # The value of the user property.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/user/($userId)/property/($key)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create user property by key
#
# POST /wiki/rest/api/user/{userId}/property/{key}
# operationId: createUserProperty
export def "wiki-rest-user-property createUserProperty" [
  userId: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  value: record # The value of the user property.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wiki/rest/api/user/($userId)/property/($key)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete user property
#
# DELETE /wiki/rest/api/user/{userId}/property/{key}
# operationId: deleteUserProperty
export def "wiki-rest-user-property delete" [
  userId: string
  key: string
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
  let full_url = (build-url $base $"/wiki/rest/api/user/($userId)/property/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
