# Auto-generated client for Planner vv1.0
# Source: https://raw.githubusercontent.com/microsoftgraph/msgraph-sdk-powershell/main/openApiDocs/v1.0/Planner.yml
# Auth: --token flag or $env.PLANNER_TOKEN

const BASE_URL = "https://graph.microsoft.com/v1.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PLANNER_TOKEN | default "" }
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

def base-url-completer [] { ["https://graph.microsoft.com/v1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def previewType-completer [] { ["automatic" "checklist" "description" "noPreview" "reference"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "groups-planner GetPlanner" } } | get name | first)
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

# Get planner from groups
#
# GET /groups/{group-id}/planner
# operationId: group_GetPlanner
export def "groups-planner GetPlanner" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, plans: table<id: string, container: record, createdBy: record, createdDateTime: string, owner: string, title: string, buckets: list, details: record, tasks: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property planner in groups
#
# PATCH /groups/{group-id}/planner
# operationId: group_UpdatePlanner
# --plans item shape: {id?: string, container?: record, createdBy?: record, createdDateTime?: string, owner?: string, title?: string, buckets?: list, details?: any, tasks?: list}
export def "groups-planner UpdatePlanner" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --plans: list # Read-only. Nullable. Returns the plannerPlans owned by the group. — item shape: {id?: string, container?: record, createdBy?: record, createdDateTime?: string, owner?: string, title?: string, buckets?: list, details?: any, tasks?: list}
]: any -> record<id: string, plans: table<id: string, container: record, createdBy: record, createdDateTime: string, owner: string, title: string, buckets: list, details: record, tasks: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner")
  let body = {id: $id, plans: $plans} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property planner for groups
#
# DELETE /groups/{group-id}/planner
# operationId: group_DeletePlanner
export def "groups-planner DeletePlanner" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List plans
#
# GET /groups/{group-id}/planner/plans
# Docs: https://learn.microsoft.com/graph/api/plannergroup-list-plans?view=graph-rest-1.0 — Find more info here
# operationId: group.planner_ListPlan
export def "groups-planner-plans ListPlan" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to plans for groups
#
# POST /groups/{group-id}/planner/plans
# operationId: group.planner_CreatePlan
# --container shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
# --createdBy shape: {application?: record, device?: record, user?: record}
# --buckets item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "groups-planner-plans CreatePlan" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --container: record # shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the plan is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --owner: string # Use the container property instead. ID of the group that owns the plan. After it's set, this property can’t be updated. This property won't return a valid group ID if the container of the plan isn't a group. (nullable)
  --title: string # Required. Title of the plan.
  --buckets: list # Read-only. Nullable. Collection of buckets in the plan. — item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
  --details: any
  --tasks: list # Read-only. Nullable. Collection of tasks in the plan. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, container: record<containerId: string, type: string, url: string>, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, owner: string, title: string, buckets: table<id: string, name: string, orderHint: string, planId: string, tasks: list>, details: record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans")
  let body = {id: $id, container: $container, createdBy: $createdBy, createdDateTime: $createdDateTime, owner: $owner, title: $title, buckets: $buckets, details: $details, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get plans from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}
# operationId: group.planner_GetPlan
export def "groups-planner-plans GetPlan" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, container: record<containerId: string, type: string, url: string>, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, owner: string, title: string, buckets: table<id: string, name: string, orderHint: string, planId: string, tasks: list>, details: record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property plans in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}
# operationId: group.planner_UpdatePlan
# --container shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
# --createdBy shape: {application?: record, device?: record, user?: record}
# --buckets item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "groups-planner-plans UpdatePlan" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --container: record # shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the plan is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --owner: string # Use the container property instead. ID of the group that owns the plan. After it's set, this property can’t be updated. This property won't return a valid group ID if the container of the plan isn't a group. (nullable)
  --title: string # Required. Title of the plan.
  --buckets: list # Read-only. Nullable. Collection of buckets in the plan. — item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
  --details: any
  --tasks: list # Read-only. Nullable. Collection of tasks in the plan. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, container: record<containerId: string, type: string, url: string>, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, owner: string, title: string, buckets: table<id: string, name: string, orderHint: string, planId: string, tasks: list>, details: record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)")
  let body = {id: $id, container: $container, createdBy: $createdBy, createdDateTime: $createdDateTime, owner: $owner, title: $title, buckets: $buckets, details: $details, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property plans for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}
# operationId: group.planner_DeletePlan
export def "groups-planner-plans DeletePlan" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get buckets from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets
# operationId: group.planner.plan_ListBucket
export def "groups-planner-plans-buckets ListBucket" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to buckets for groups
#
# POST /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets
# operationId: group.planner.plan_CreateBucket
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "groups-planner-plans-buckets CreateBucket" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --name: string # Name of the bucket.
  --orderHint: string # Hint used to order items of this type in a list view. For details about the supported format, see Using order hints in Planner. (nullable)
  --planId: string # Plan ID to which the bucket belongs. (nullable)
  --tasks: list # Read-only. Nullable. The collection of tasks in the bucket. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets")
  let body = {id: $id, name: $name, orderHint: $orderHint, planId: $planId, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get buckets from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}
# operationId: group.planner.plan_GetBucket
export def "groups-planner-plans-buckets GetBucket" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property buckets in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}
# operationId: group.planner.plan_UpdateBucket
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "groups-planner-plans-buckets UpdateBucket" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --name: string # Name of the bucket.
  --orderHint: string # Hint used to order items of this type in a list view. For details about the supported format, see Using order hints in Planner. (nullable)
  --planId: string # Plan ID to which the bucket belongs. (nullable)
  --tasks: list # Read-only. Nullable. The collection of tasks in the bucket. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)")
  let body = {id: $id, name: $name, orderHint: $orderHint, planId: $planId, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property buckets for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}
# operationId: group.planner.plan_DeleteBucket
export def "groups-planner-plans-buckets DeleteBucket" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tasks from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks
# operationId: group.planner.plan.bucket_ListTask
export def "groups-planner-plans-buckets-tasks ListTask" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to tasks for groups
#
# POST /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks
# operationId: group.planner.plan.bucket_CreateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "groups-planner-plans-buckets-tasks CreateTask" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tasks from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: group.planner.plan.bucket_GetTask
export def "groups-planner-plans-buckets-tasks GetTask" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property tasks in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: group.planner.plan.bucket_UpdateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "groups-planner-plans-buckets-tasks UpdateTask" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property tasks for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: group.planner.plan.bucket_DeleteTask
export def "groups-planner-plans-buckets-tasks DeleteTask" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get assignedToTaskBoardFormat from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: group.planner.plan.bucket.task_GetAssignedToTaskBoardFormat
export def "groups-planner-plans-buckets-tasks-assigned-to-task-board-format GetAssignedToTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property assignedToTaskBoardFormat in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: group.planner.plan.bucket.task_UpdateAssignedToTaskBoardFormat
export def "groups-planner-plans-buckets-tasks-assigned-to-task-board-format UpdateAssignedToTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHintsByAssignee: record
  --unassignedOrderHint: string # Hint value used to order the task on the AssignedTo view of the Task Board when the task isn't assigned to anyone, or if the orderHintsByAssignee dictionary doesn't provide an order hint for the user the task is assigned to. The format is defined as outlined here. (nullable)
]: any -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let body = {id: $id, orderHintsByAssignee: $orderHintsByAssignee, unassignedOrderHint: $unassignedOrderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property assignedToTaskBoardFormat for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: group.planner.plan.bucket.task_DeleteAssignedToTaskBoardFormat
export def "groups-planner-plans-buckets-tasks-assigned-to-task-board-format DeleteAssignedToTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bucketTaskBoardFormat from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: group.planner.plan.bucket.task_GetBucketTaskBoardFormat
export def "groups-planner-plans-buckets-tasks-bucket-task-board-format GetBucketTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property bucketTaskBoardFormat in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: group.planner.plan.bucket.task_UpdateBucketTaskBoardFormat
export def "groups-planner-plans-buckets-tasks-bucket-task-board-format UpdateBucketTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint used to order tasks in the bucket view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property bucketTaskBoardFormat for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: group.planner.plan.bucket.task_DeleteBucketTaskBoardFormat
export def "groups-planner-plans-buckets-tasks-bucket-task-board-format DeleteBucketTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: group.planner.plan.bucket.task_GetDetail
export def "groups-planner-plans-buckets-tasks-details GetDetail" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property details in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: group.planner.plan.bucket.task_UpdateDetail
export def "groups-planner-plans-buckets-tasks-details UpdateDetail" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --checklist: record
  --description: string # Description of the task. (nullable)
  --previewType: string@previewType-completer
  --references: record
]: any -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details")
  let body = {id: $id, checklist: $checklist, description: $description, previewType: $previewType, references: $references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: group.planner.plan.bucket.task_DeleteDetail
export def "groups-planner-plans-buckets-tasks-details DeleteDetail" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get progressTaskBoardFormat from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: group.planner.plan.bucket.task_GetProgressTaskBoardFormat
export def "groups-planner-plans-buckets-tasks-progress-task-board-format GetProgressTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property progressTaskBoardFormat in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: group.planner.plan.bucket.task_UpdateProgressTaskBoardFormat
export def "groups-planner-plans-buckets-tasks-progress-task-board-format UpdateProgressTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint value used to order the task on the progress view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property progressTaskBoardFormat for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: group.planner.plan.bucket.task_DeleteProgressTaskBoardFormat
export def "groups-planner-plans-buckets-tasks-progress-task-board-format DeleteProgressTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/$count
# operationId: group.planner.plan.bucket.task_GetCount
export def "groups-planner-plans-buckets-tasks-count GetCount" [
  group_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/buckets/$count
# operationId: group.planner.plan.bucket_GetCount
export def "groups-planner-plans-buckets-count GetCount" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/buckets/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/details
# operationId: group.planner.plan_GetDetail
export def "groups-planner-plans-details GetDetail" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property details in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/details
# operationId: group.planner.plan_UpdateDetail
# --categoryDescriptions shape: {category1?: string, category10?: string, category11?: string, category12?: string, category13?: string, category14?: string, category15?: string, category16?: string, category17?: string, category18?: string, category19?: string, category2?: string, category20?: string, category21?: string, category22?: string, category23?: string, category24?: string, category25?: string, category3?: string, category4?: string, category5?: string, category6?: string, category7?: string, category8?: string, category9?: string}
export def "groups-planner-plans-details UpdateDetail" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --categoryDescriptions: record # shape: {category1?: string, category10?: string, category11?: string, category12?: string, category13?: string, category14?: string, category15?: string, category16?: string, category17?: string, category18?: string, category19?: string, category2?: string, category20?: string, category21?: string, category22?: string, category23?: string, category24?: string, category25?: string, category3?: string, category4?: string, category5?: string, category6?: string, category7?: string, category8?: string, category9?: string}
  --sharedWith: record
]: any -> record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/details")
  let body = {id: $id, categoryDescriptions: $categoryDescriptions, sharedWith: $sharedWith} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/details
# operationId: group.planner.plan_DeleteDetail
export def "groups-planner-plans-details DeleteDetail" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tasks from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks
# operationId: group.planner.plan_ListTask
export def "groups-planner-plans-tasks ListTask" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to tasks for groups
#
# POST /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks
# operationId: group.planner.plan_CreateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "groups-planner-plans-tasks CreateTask" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tasks from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}
# operationId: group.planner.plan_GetTask
export def "groups-planner-plans-tasks GetTask" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property tasks in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}
# operationId: group.planner.plan_UpdateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "groups-planner-plans-tasks UpdateTask" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property tasks for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}
# operationId: group.planner.plan_DeleteTask
export def "groups-planner-plans-tasks DeleteTask" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get assignedToTaskBoardFormat from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: group.planner.plan.task_GetAssignedToTaskBoardFormat
export def "groups-planner-plans-tasks-assigned-to-task-board-format GetAssignedToTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property assignedToTaskBoardFormat in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: group.planner.plan.task_UpdateAssignedToTaskBoardFormat
export def "groups-planner-plans-tasks-assigned-to-task-board-format UpdateAssignedToTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHintsByAssignee: record
  --unassignedOrderHint: string # Hint value used to order the task on the AssignedTo view of the Task Board when the task isn't assigned to anyone, or if the orderHintsByAssignee dictionary doesn't provide an order hint for the user the task is assigned to. The format is defined as outlined here. (nullable)
]: any -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let body = {id: $id, orderHintsByAssignee: $orderHintsByAssignee, unassignedOrderHint: $unassignedOrderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property assignedToTaskBoardFormat for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: group.planner.plan.task_DeleteAssignedToTaskBoardFormat
export def "groups-planner-plans-tasks-assigned-to-task-board-format DeleteAssignedToTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bucketTaskBoardFormat from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: group.planner.plan.task_GetBucketTaskBoardFormat
export def "groups-planner-plans-tasks-bucket-task-board-format GetBucketTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property bucketTaskBoardFormat in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: group.planner.plan.task_UpdateBucketTaskBoardFormat
export def "groups-planner-plans-tasks-bucket-task-board-format UpdateBucketTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint used to order tasks in the bucket view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property bucketTaskBoardFormat for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: group.planner.plan.task_DeleteBucketTaskBoardFormat
export def "groups-planner-plans-tasks-bucket-task-board-format DeleteBucketTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/details
# operationId: group.planner.plan.task_GetDetail
export def "groups-planner-plans-tasks-details GetDetail" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property details in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/details
# operationId: group.planner.plan.task_UpdateDetail
export def "groups-planner-plans-tasks-details UpdateDetail" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --checklist: record
  --description: string # Description of the task. (nullable)
  --previewType: string@previewType-completer
  --references: record
]: any -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/details")
  let body = {id: $id, checklist: $checklist, description: $description, previewType: $previewType, references: $references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/details
# operationId: group.planner.plan.task_DeleteDetail
export def "groups-planner-plans-tasks-details DeleteDetail" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get progressTaskBoardFormat from groups
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: group.planner.plan.task_GetProgressTaskBoardFormat
export def "groups-planner-plans-tasks-progress-task-board-format GetProgressTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/progressTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property progressTaskBoardFormat in groups
#
# PATCH /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: group.planner.plan.task_UpdateProgressTaskBoardFormat
export def "groups-planner-plans-tasks-progress-task-board-format UpdateProgressTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint value used to order the task on the progress view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property progressTaskBoardFormat for groups
#
# DELETE /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: group.planner.plan.task_DeleteProgressTaskBoardFormat
export def "groups-planner-plans-tasks-progress-task-board-format DeleteProgressTaskBoardFormat" [
  group_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /groups/{group-id}/planner/plans/{plannerPlan-id}/tasks/$count
# operationId: group.planner.plan.task_GetCount
export def "groups-planner-plans-tasks-count GetCount" [
  group_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/($plannerPlan_id)/tasks/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /groups/{group-id}/planner/plans/$count
# operationId: group.planner.plan_GetCount
export def "groups-planner-plans-count GetCount" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/planner/plans/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get planner
#
# GET /planner
# operationId: planner_GetPlanner
export def "planner GetPlanner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, buckets: table<id: string, name: string, orderHint: string, planId: string, tasks: list>, plans: table<id: string, container: record, createdBy: record, createdDateTime: string, owner: string, title: string, buckets: list, details: record, tasks: list>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/planner" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update planner
#
# PATCH /planner
# operationId: planner_UpdatePlanner
# --buckets item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
# --plans item shape: {id?: string, container?: record, createdBy?: record, createdDateTime?: string, owner?: string, title?: string, buckets?: list, details?: any, tasks?: list}
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "planner UpdatePlanner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --buckets: list # Read-only. Nullable. Returns a collection of the specified buckets — item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
  --plans: list # Read-only. Nullable. Returns a collection of the specified plans — item shape: {id?: string, container?: record, createdBy?: record, createdDateTime?: string, owner?: string, title?: string, buckets?: list, details?: any, tasks?: list}
  --tasks: list # Read-only. Nullable. Returns a collection of the specified tasks — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, buckets: table<id: string, name: string, orderHint: string, planId: string, tasks: list>, plans: table<id: string, container: record, createdBy: record, createdDateTime: string, owner: string, title: string, buckets: list, details: record, tasks: list>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/planner")
  let body = {id: $id, buckets: $buckets, plans: $plans, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List buckets
#
# GET /planner/buckets
# Docs: https://learn.microsoft.com/graph/api/planner-list-buckets?view=graph-rest-1.0 — Find more info here
# operationId: planner_ListBucket
export def "planner-buckets ListBucket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/planner/buckets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create plannerBucket
#
# POST /planner/buckets
# Docs: https://learn.microsoft.com/graph/api/planner-post-buckets?view=graph-rest-1.0 — Find more info here
# operationId: planner_CreateBucket
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "planner-buckets CreateBucket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --name: string # Name of the bucket.
  --orderHint: string # Hint used to order items of this type in a list view. For details about the supported format, see Using order hints in Planner. (nullable)
  --planId: string # Plan ID to which the bucket belongs. (nullable)
  --tasks: list # Read-only. Nullable. The collection of tasks in the bucket. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/planner/buckets")
  let body = {id: $id, name: $name, orderHint: $orderHint, planId: $planId, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get plannerBucket
#
# GET /planner/buckets/{plannerBucket-id}
# Docs: https://learn.microsoft.com/graph/api/plannerbucket-get?view=graph-rest-1.0 — Find more info here
# operationId: planner_GetBucket
export def "planner-buckets GetBucket" [
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update plannerbucket
#
# PATCH /planner/buckets/{plannerBucket-id}
# Docs: https://learn.microsoft.com/graph/api/plannerbucket-update?view=graph-rest-1.0 — Find more info here
# operationId: planner_UpdateBucket
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "planner-buckets UpdateBucket" [
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --name: string # Name of the bucket.
  --orderHint: string # Hint used to order items of this type in a list view. For details about the supported format, see Using order hints in Planner. (nullable)
  --planId: string # Plan ID to which the bucket belongs. (nullable)
  --tasks: list # Read-only. Nullable. The collection of tasks in the bucket. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)")
  let body = {id: $id, name: $name, orderHint: $orderHint, planId: $planId, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete plannerBucket
#
# DELETE /planner/buckets/{plannerBucket-id}
# Docs: https://learn.microsoft.com/graph/api/plannerbucket-delete?view=graph-rest-1.0 — Find more info here
# operationId: planner_DeleteBucket
export def "planner-buckets DeleteBucket" [
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tasks
#
# GET /planner/buckets/{plannerBucket-id}/tasks
# Docs: https://learn.microsoft.com/graph/api/plannerbucket-list-tasks?view=graph-rest-1.0 — Find more info here
# operationId: planner.bucket_ListTask
export def "planner-buckets-tasks ListTask" [
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to tasks for planner
#
# POST /planner/buckets/{plannerBucket-id}/tasks
# operationId: planner.bucket_CreateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "planner-buckets-tasks CreateTask" [
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tasks from planner
#
# GET /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: planner.bucket_GetTask
export def "planner-buckets-tasks GetTask" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property tasks in planner
#
# PATCH /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: planner.bucket_UpdateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "planner-buckets-tasks UpdateTask" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property tasks for planner
#
# DELETE /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: planner.bucket_DeleteTask
export def "planner-buckets-tasks DeleteTask" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get assignedToTaskBoardFormat from planner
#
# GET /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: planner.bucket.task_GetAssignedToTaskBoardFormat
export def "planner-buckets-tasks-assigned-to-task-board-format GetAssignedToTaskBoardFormat" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property assignedToTaskBoardFormat in planner
#
# PATCH /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: planner.bucket.task_UpdateAssignedToTaskBoardFormat
export def "planner-buckets-tasks-assigned-to-task-board-format UpdateAssignedToTaskBoardFormat" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHintsByAssignee: record
  --unassignedOrderHint: string # Hint value used to order the task on the AssignedTo view of the Task Board when the task isn't assigned to anyone, or if the orderHintsByAssignee dictionary doesn't provide an order hint for the user the task is assigned to. The format is defined as outlined here. (nullable)
]: any -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let body = {id: $id, orderHintsByAssignee: $orderHintsByAssignee, unassignedOrderHint: $unassignedOrderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property assignedToTaskBoardFormat for planner
#
# DELETE /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: planner.bucket.task_DeleteAssignedToTaskBoardFormat
export def "planner-buckets-tasks-assigned-to-task-board-format DeleteAssignedToTaskBoardFormat" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bucketTaskBoardFormat from planner
#
# GET /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: planner.bucket.task_GetBucketTaskBoardFormat
export def "planner-buckets-tasks-bucket-task-board-format GetBucketTaskBoardFormat" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property bucketTaskBoardFormat in planner
#
# PATCH /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: planner.bucket.task_UpdateBucketTaskBoardFormat
export def "planner-buckets-tasks-bucket-task-board-format UpdateBucketTaskBoardFormat" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint used to order tasks in the bucket view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property bucketTaskBoardFormat for planner
#
# DELETE /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: planner.bucket.task_DeleteBucketTaskBoardFormat
export def "planner-buckets-tasks-bucket-task-board-format DeleteBucketTaskBoardFormat" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details from planner
#
# GET /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: planner.bucket.task_GetDetail
export def "planner-buckets-tasks-details GetDetail" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property details in planner
#
# PATCH /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: planner.bucket.task_UpdateDetail
export def "planner-buckets-tasks-details UpdateDetail" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --checklist: record
  --description: string # Description of the task. (nullable)
  --previewType: string@previewType-completer
  --references: record
]: any -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details")
  let body = {id: $id, checklist: $checklist, description: $description, previewType: $previewType, references: $references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for planner
#
# DELETE /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: planner.bucket.task_DeleteDetail
export def "planner-buckets-tasks-details DeleteDetail" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get progressTaskBoardFormat from planner
#
# GET /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: planner.bucket.task_GetProgressTaskBoardFormat
export def "planner-buckets-tasks-progress-task-board-format GetProgressTaskBoardFormat" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property progressTaskBoardFormat in planner
#
# PATCH /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: planner.bucket.task_UpdateProgressTaskBoardFormat
export def "planner-buckets-tasks-progress-task-board-format UpdateProgressTaskBoardFormat" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint value used to order the task on the progress view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property progressTaskBoardFormat for planner
#
# DELETE /planner/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: planner.bucket.task_DeleteProgressTaskBoardFormat
export def "planner-buckets-tasks-progress-task-board-format DeleteProgressTaskBoardFormat" [
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /planner/buckets/{plannerBucket-id}/tasks/$count
# operationId: planner.bucket.task_GetCount
export def "planner-buckets-tasks-count GetCount" [
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/buckets/($plannerBucket_id)/tasks/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /planner/buckets/$count
# operationId: planner.bucket_GetCount
export def "planner-buckets-count GetCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/planner/buckets/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List plans
#
# GET /planner/plans
# Docs: https://learn.microsoft.com/graph/api/planner-list-plans?view=graph-rest-1.0 — Find more info here
# operationId: planner_ListPlan
export def "planner-plans ListPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/planner/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create plannerPlan
#
# POST /planner/plans
# Docs: https://learn.microsoft.com/graph/api/planner-post-plans?view=graph-rest-1.0 — Find more info here
# operationId: planner_CreatePlan
# --container shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
# --createdBy shape: {application?: record, device?: record, user?: record}
# --buckets item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "planner-plans CreatePlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --container: record # shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the plan is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --owner: string # Use the container property instead. ID of the group that owns the plan. After it's set, this property can’t be updated. This property won't return a valid group ID if the container of the plan isn't a group. (nullable)
  --title: string # Required. Title of the plan.
  --buckets: list # Read-only. Nullable. Collection of buckets in the plan. — item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
  --details: any
  --tasks: list # Read-only. Nullable. Collection of tasks in the plan. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, container: record<containerId: string, type: string, url: string>, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, owner: string, title: string, buckets: table<id: string, name: string, orderHint: string, planId: string, tasks: list>, details: record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/planner/plans")
  let body = {id: $id, container: $container, createdBy: $createdBy, createdDateTime: $createdDateTime, owner: $owner, title: $title, buckets: $buckets, details: $details, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get plannerPlan
#
# GET /planner/plans/{plannerPlan-id}
# Docs: https://learn.microsoft.com/graph/api/plannerplan-get?view=graph-rest-1.0 — Find more info here
# operationId: planner_GetPlan
export def "planner-plans GetPlan" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, container: record<containerId: string, type: string, url: string>, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, owner: string, title: string, buckets: table<id: string, name: string, orderHint: string, planId: string, tasks: list>, details: record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update plannerPlan
#
# PATCH /planner/plans/{plannerPlan-id}
# Docs: https://learn.microsoft.com/graph/api/plannerplan-update?view=graph-rest-1.0 — Find more info here
# operationId: planner_UpdatePlan
# --container shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
# --createdBy shape: {application?: record, device?: record, user?: record}
# --buckets item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "planner-plans UpdatePlan" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --container: record # shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the plan is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --owner: string # Use the container property instead. ID of the group that owns the plan. After it's set, this property can’t be updated. This property won't return a valid group ID if the container of the plan isn't a group. (nullable)
  --title: string # Required. Title of the plan.
  --buckets: list # Read-only. Nullable. Collection of buckets in the plan. — item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
  --details: any
  --tasks: list # Read-only. Nullable. Collection of tasks in the plan. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, container: record<containerId: string, type: string, url: string>, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, owner: string, title: string, buckets: table<id: string, name: string, orderHint: string, planId: string, tasks: list>, details: record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)")
  let body = {id: $id, container: $container, createdBy: $createdBy, createdDateTime: $createdDateTime, owner: $owner, title: $title, buckets: $buckets, details: $details, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete plannerPlan
#
# DELETE /planner/plans/{plannerPlan-id}
# Docs: https://learn.microsoft.com/graph/api/plannerplan-delete?view=graph-rest-1.0 — Find more info here
# operationId: planner_DeletePlan
export def "planner-plans DeletePlan" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List buckets
#
# GET /planner/plans/{plannerPlan-id}/buckets
# Docs: https://learn.microsoft.com/graph/api/plannerplan-list-buckets?view=graph-rest-1.0 — Find more info here
# operationId: planner.plan_ListBucket
export def "planner-plans-buckets ListBucket" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to buckets for planner
#
# POST /planner/plans/{plannerPlan-id}/buckets
# operationId: planner.plan_CreateBucket
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "planner-plans-buckets CreateBucket" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --name: string # Name of the bucket.
  --orderHint: string # Hint used to order items of this type in a list view. For details about the supported format, see Using order hints in Planner. (nullable)
  --planId: string # Plan ID to which the bucket belongs. (nullable)
  --tasks: list # Read-only. Nullable. The collection of tasks in the bucket. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets")
  let body = {id: $id, name: $name, orderHint: $orderHint, planId: $planId, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get buckets from planner
#
# GET /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}
# operationId: planner.plan_GetBucket
export def "planner-plans-buckets GetBucket" [
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property buckets in planner
#
# PATCH /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}
# operationId: planner.plan_UpdateBucket
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "planner-plans-buckets UpdateBucket" [
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --name: string # Name of the bucket.
  --orderHint: string # Hint used to order items of this type in a list view. For details about the supported format, see Using order hints in Planner. (nullable)
  --planId: string # Plan ID to which the bucket belongs. (nullable)
  --tasks: list # Read-only. Nullable. The collection of tasks in the bucket. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)")
  let body = {id: $id, name: $name, orderHint: $orderHint, planId: $planId, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property buckets for planner
#
# DELETE /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}
# operationId: planner.plan_DeleteBucket
export def "planner-plans-buckets DeleteBucket" [
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tasks from planner
#
# GET /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks
# operationId: planner.plan.bucket_ListTask
export def "planner-plans-buckets-tasks ListTask" [
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to tasks for planner
#
# POST /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks
# operationId: planner.plan.bucket_CreateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "planner-plans-buckets-tasks CreateTask" [
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tasks from planner
#
# GET /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: planner.plan.bucket_GetTask
export def "planner-plans-buckets-tasks GetTask" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property tasks in planner
#
# PATCH /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: planner.plan.bucket_UpdateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "planner-plans-buckets-tasks UpdateTask" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property tasks for planner
#
# DELETE /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: planner.plan.bucket_DeleteTask
export def "planner-plans-buckets-tasks DeleteTask" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get assignedToTaskBoardFormat from planner
#
# GET /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: planner.plan.bucket.task_GetAssignedToTaskBoardFormat
export def "planner-plans-buckets-tasks-assigned-to-task-board-format GetAssignedToTaskBoardFormat" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property assignedToTaskBoardFormat in planner
#
# PATCH /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: planner.plan.bucket.task_UpdateAssignedToTaskBoardFormat
export def "planner-plans-buckets-tasks-assigned-to-task-board-format UpdateAssignedToTaskBoardFormat" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHintsByAssignee: record
  --unassignedOrderHint: string # Hint value used to order the task on the AssignedTo view of the Task Board when the task isn't assigned to anyone, or if the orderHintsByAssignee dictionary doesn't provide an order hint for the user the task is assigned to. The format is defined as outlined here. (nullable)
]: any -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let body = {id: $id, orderHintsByAssignee: $orderHintsByAssignee, unassignedOrderHint: $unassignedOrderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property assignedToTaskBoardFormat for planner
#
# DELETE /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: planner.plan.bucket.task_DeleteAssignedToTaskBoardFormat
export def "planner-plans-buckets-tasks-assigned-to-task-board-format DeleteAssignedToTaskBoardFormat" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bucketTaskBoardFormat from planner
#
# GET /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: planner.plan.bucket.task_GetBucketTaskBoardFormat
export def "planner-plans-buckets-tasks-bucket-task-board-format GetBucketTaskBoardFormat" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property bucketTaskBoardFormat in planner
#
# PATCH /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: planner.plan.bucket.task_UpdateBucketTaskBoardFormat
export def "planner-plans-buckets-tasks-bucket-task-board-format UpdateBucketTaskBoardFormat" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint used to order tasks in the bucket view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property bucketTaskBoardFormat for planner
#
# DELETE /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: planner.plan.bucket.task_DeleteBucketTaskBoardFormat
export def "planner-plans-buckets-tasks-bucket-task-board-format DeleteBucketTaskBoardFormat" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details from planner
#
# GET /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: planner.plan.bucket.task_GetDetail
export def "planner-plans-buckets-tasks-details GetDetail" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property details in planner
#
# PATCH /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: planner.plan.bucket.task_UpdateDetail
export def "planner-plans-buckets-tasks-details UpdateDetail" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --checklist: record
  --description: string # Description of the task. (nullable)
  --previewType: string@previewType-completer
  --references: record
]: any -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details")
  let body = {id: $id, checklist: $checklist, description: $description, previewType: $previewType, references: $references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for planner
#
# DELETE /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: planner.plan.bucket.task_DeleteDetail
export def "planner-plans-buckets-tasks-details DeleteDetail" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get progressTaskBoardFormat from planner
#
# GET /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: planner.plan.bucket.task_GetProgressTaskBoardFormat
export def "planner-plans-buckets-tasks-progress-task-board-format GetProgressTaskBoardFormat" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property progressTaskBoardFormat in planner
#
# PATCH /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: planner.plan.bucket.task_UpdateProgressTaskBoardFormat
export def "planner-plans-buckets-tasks-progress-task-board-format UpdateProgressTaskBoardFormat" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint value used to order the task on the progress view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property progressTaskBoardFormat for planner
#
# DELETE /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: planner.plan.bucket.task_DeleteProgressTaskBoardFormat
export def "planner-plans-buckets-tasks-progress-task-board-format DeleteProgressTaskBoardFormat" [
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/$count
# operationId: planner.plan.bucket.task_GetCount
export def "planner-plans-buckets-tasks-count GetCount" [
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /planner/plans/{plannerPlan-id}/buckets/$count
# operationId: planner.plan.bucket_GetCount
export def "planner-plans-buckets-count GetCount" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/buckets/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plannerPlanDetails
#
# GET /planner/plans/{plannerPlan-id}/details
# Docs: https://learn.microsoft.com/graph/api/plannerplandetails-get?view=graph-rest-1.0 — Find more info here
# operationId: planner.plan_GetDetail
export def "planner-plans-details GetDetail" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update plannerplandetails
#
# PATCH /planner/plans/{plannerPlan-id}/details
# Docs: https://learn.microsoft.com/graph/api/plannerplandetails-update?view=graph-rest-1.0 — Find more info here
# operationId: planner.plan_UpdateDetail
# --categoryDescriptions shape: {category1?: string, category10?: string, category11?: string, category12?: string, category13?: string, category14?: string, category15?: string, category16?: string, category17?: string, category18?: string, category19?: string, category2?: string, category20?: string, category21?: string, category22?: string, category23?: string, category24?: string, category25?: string, category3?: string, category4?: string, category5?: string, category6?: string, category7?: string, category8?: string, category9?: string}
export def "planner-plans-details UpdateDetail" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --categoryDescriptions: record # shape: {category1?: string, category10?: string, category11?: string, category12?: string, category13?: string, category14?: string, category15?: string, category16?: string, category17?: string, category18?: string, category19?: string, category2?: string, category20?: string, category21?: string, category22?: string, category23?: string, category24?: string, category25?: string, category3?: string, category4?: string, category5?: string, category6?: string, category7?: string, category8?: string, category9?: string}
  --sharedWith: record
]: any -> record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/details")
  let body = {id: $id, categoryDescriptions: $categoryDescriptions, sharedWith: $sharedWith} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for planner
#
# DELETE /planner/plans/{plannerPlan-id}/details
# operationId: planner.plan_DeleteDetail
export def "planner-plans-details DeleteDetail" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tasks
#
# GET /planner/plans/{plannerPlan-id}/tasks
# Docs: https://learn.microsoft.com/graph/api/plannerplan-list-tasks?view=graph-rest-1.0 — Find more info here
# operationId: planner.plan_ListTask
export def "planner-plans-tasks ListTask" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to tasks for planner
#
# POST /planner/plans/{plannerPlan-id}/tasks
# operationId: planner.plan_CreateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "planner-plans-tasks CreateTask" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tasks from planner
#
# GET /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}
# operationId: planner.plan_GetTask
export def "planner-plans-tasks GetTask" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property tasks in planner
#
# PATCH /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}
# operationId: planner.plan_UpdateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "planner-plans-tasks UpdateTask" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property tasks for planner
#
# DELETE /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}
# operationId: planner.plan_DeleteTask
export def "planner-plans-tasks DeleteTask" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get assignedToTaskBoardFormat from planner
#
# GET /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: planner.plan.task_GetAssignedToTaskBoardFormat
export def "planner-plans-tasks-assigned-to-task-board-format GetAssignedToTaskBoardFormat" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property assignedToTaskBoardFormat in planner
#
# PATCH /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: planner.plan.task_UpdateAssignedToTaskBoardFormat
export def "planner-plans-tasks-assigned-to-task-board-format UpdateAssignedToTaskBoardFormat" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHintsByAssignee: record
  --unassignedOrderHint: string # Hint value used to order the task on the AssignedTo view of the Task Board when the task isn't assigned to anyone, or if the orderHintsByAssignee dictionary doesn't provide an order hint for the user the task is assigned to. The format is defined as outlined here. (nullable)
]: any -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let body = {id: $id, orderHintsByAssignee: $orderHintsByAssignee, unassignedOrderHint: $unassignedOrderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property assignedToTaskBoardFormat for planner
#
# DELETE /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: planner.plan.task_DeleteAssignedToTaskBoardFormat
export def "planner-plans-tasks-assigned-to-task-board-format DeleteAssignedToTaskBoardFormat" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bucketTaskBoardFormat from planner
#
# GET /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: planner.plan.task_GetBucketTaskBoardFormat
export def "planner-plans-tasks-bucket-task-board-format GetBucketTaskBoardFormat" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property bucketTaskBoardFormat in planner
#
# PATCH /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: planner.plan.task_UpdateBucketTaskBoardFormat
export def "planner-plans-tasks-bucket-task-board-format UpdateBucketTaskBoardFormat" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint used to order tasks in the bucket view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property bucketTaskBoardFormat for planner
#
# DELETE /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: planner.plan.task_DeleteBucketTaskBoardFormat
export def "planner-plans-tasks-bucket-task-board-format DeleteBucketTaskBoardFormat" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details from planner
#
# GET /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/details
# operationId: planner.plan.task_GetDetail
export def "planner-plans-tasks-details GetDetail" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property details in planner
#
# PATCH /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/details
# operationId: planner.plan.task_UpdateDetail
export def "planner-plans-tasks-details UpdateDetail" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --checklist: record
  --description: string # Description of the task. (nullable)
  --previewType: string@previewType-completer
  --references: record
]: any -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/details")
  let body = {id: $id, checklist: $checklist, description: $description, previewType: $previewType, references: $references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for planner
#
# DELETE /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/details
# operationId: planner.plan.task_DeleteDetail
export def "planner-plans-tasks-details DeleteDetail" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get progressTaskBoardFormat from planner
#
# GET /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: planner.plan.task_GetProgressTaskBoardFormat
export def "planner-plans-tasks-progress-task-board-format GetProgressTaskBoardFormat" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/progressTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property progressTaskBoardFormat in planner
#
# PATCH /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: planner.plan.task_UpdateProgressTaskBoardFormat
export def "planner-plans-tasks-progress-task-board-format UpdateProgressTaskBoardFormat" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint value used to order the task on the progress view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property progressTaskBoardFormat for planner
#
# DELETE /planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: planner.plan.task_DeleteProgressTaskBoardFormat
export def "planner-plans-tasks-progress-task-board-format DeleteProgressTaskBoardFormat" [
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /planner/plans/{plannerPlan-id}/tasks/$count
# operationId: planner.plan.task_GetCount
export def "planner-plans-tasks-count GetCount" [
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/plans/($plannerPlan_id)/tasks/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /planner/plans/$count
# operationId: planner.plan_GetCount
export def "planner-plans-count GetCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/planner/plans/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List plannerTask objects
#
# GET /planner/tasks
# Docs: https://learn.microsoft.com/graph/api/planner-list-tasks?view=graph-rest-1.0 — Find more info here
# operationId: planner_ListTask
export def "planner-tasks ListTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/planner/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create plannerTask
#
# POST /planner/tasks
# Docs: https://learn.microsoft.com/graph/api/planner-post-tasks?view=graph-rest-1.0 — Find more info here
# operationId: planner_CreateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "planner-tasks CreateTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/planner/tasks")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get plannerTask
#
# GET /planner/tasks/{plannerTask-id}
# Docs: https://learn.microsoft.com/graph/api/plannertask-get?view=graph-rest-1.0 — Find more info here
# operationId: planner_GetTask
export def "planner-tasks GetTask" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update plannerTask
#
# PATCH /planner/tasks/{plannerTask-id}
# Docs: https://learn.microsoft.com/graph/api/plannertask-update?view=graph-rest-1.0 — Find more info here
# operationId: planner_UpdateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "planner-tasks UpdateTask" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete plannerTask
#
# DELETE /planner/tasks/{plannerTask-id}
# Docs: https://learn.microsoft.com/graph/api/plannertask-delete?view=graph-rest-1.0 — Find more info here
# operationId: planner_DeleteTask
export def "planner-tasks DeleteTask" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plannerAssignedToTaskBoardTaskFormat
#
# GET /planner/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# Docs: https://learn.microsoft.com/graph/api/plannerassignedtotaskboardtaskformat-get?view=graph-rest-1.0 — Find more info here
# operationId: planner.task_GetAssignedToTaskBoardFormat
export def "planner-tasks-assigned-to-task-board-format GetAssignedToTaskBoardFormat" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/assignedToTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update plannerAssignedToTaskBoardTaskFormat
#
# PATCH /planner/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# Docs: https://learn.microsoft.com/graph/api/plannerassignedtotaskboardtaskformat-update?view=graph-rest-1.0 — Find more info here
# operationId: planner.task_UpdateAssignedToTaskBoardFormat
export def "planner-tasks-assigned-to-task-board-format UpdateAssignedToTaskBoardFormat" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHintsByAssignee: record
  --unassignedOrderHint: string # Hint value used to order the task on the AssignedTo view of the Task Board when the task isn't assigned to anyone, or if the orderHintsByAssignee dictionary doesn't provide an order hint for the user the task is assigned to. The format is defined as outlined here. (nullable)
]: any -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let body = {id: $id, orderHintsByAssignee: $orderHintsByAssignee, unassignedOrderHint: $unassignedOrderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property assignedToTaskBoardFormat for planner
#
# DELETE /planner/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: planner.task_DeleteAssignedToTaskBoardFormat
export def "planner-tasks-assigned-to-task-board-format DeleteAssignedToTaskBoardFormat" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plannerBucketTaskBoardTaskFormat
#
# GET /planner/tasks/{plannerTask-id}/bucketTaskBoardFormat
# Docs: https://learn.microsoft.com/graph/api/plannerbuckettaskboardtaskformat-get?view=graph-rest-1.0 — Find more info here
# operationId: planner.task_GetBucketTaskBoardFormat
export def "planner-tasks-bucket-task-board-format GetBucketTaskBoardFormat" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/bucketTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update plannerBucketTaskBoardTaskFormat
#
# PATCH /planner/tasks/{plannerTask-id}/bucketTaskBoardFormat
# Docs: https://learn.microsoft.com/graph/api/plannerbuckettaskboardtaskformat-update?view=graph-rest-1.0 — Find more info here
# operationId: planner.task_UpdateBucketTaskBoardFormat
export def "planner-tasks-bucket-task-board-format UpdateBucketTaskBoardFormat" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint used to order tasks in the bucket view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property bucketTaskBoardFormat for planner
#
# DELETE /planner/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: planner.task_DeleteBucketTaskBoardFormat
export def "planner-tasks-bucket-task-board-format DeleteBucketTaskBoardFormat" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plannerTaskDetails
#
# GET /planner/tasks/{plannerTask-id}/details
# Docs: https://learn.microsoft.com/graph/api/plannertaskdetails-get?view=graph-rest-1.0 — Find more info here
# operationId: planner.task_GetDetail
export def "planner-tasks-details GetDetail" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update plannertaskdetails
#
# PATCH /planner/tasks/{plannerTask-id}/details
# Docs: https://learn.microsoft.com/graph/api/plannertaskdetails-update?view=graph-rest-1.0 — Find more info here
# operationId: planner.task_UpdateDetail
export def "planner-tasks-details UpdateDetail" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --checklist: record
  --description: string # Description of the task. (nullable)
  --previewType: string@previewType-completer
  --references: record
]: any -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/details")
  let body = {id: $id, checklist: $checklist, description: $description, previewType: $previewType, references: $references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for planner
#
# DELETE /planner/tasks/{plannerTask-id}/details
# operationId: planner.task_DeleteDetail
export def "planner-tasks-details DeleteDetail" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plannerProgressTaskBoardTaskFormat
#
# GET /planner/tasks/{plannerTask-id}/progressTaskBoardFormat
# Docs: https://learn.microsoft.com/graph/api/plannerprogresstaskboardtaskformat-get?view=graph-rest-1.0 — Find more info here
# operationId: planner.task_GetProgressTaskBoardFormat
export def "planner-tasks-progress-task-board-format GetProgressTaskBoardFormat" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/progressTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update plannerProgressTaskBoardTaskFormat
#
# PATCH /planner/tasks/{plannerTask-id}/progressTaskBoardFormat
# Docs: https://learn.microsoft.com/graph/api/plannerprogresstaskboardtaskformat-update?view=graph-rest-1.0 — Find more info here
# operationId: planner.task_UpdateProgressTaskBoardFormat
export def "planner-tasks-progress-task-board-format UpdateProgressTaskBoardFormat" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint value used to order the task on the progress view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property progressTaskBoardFormat for planner
#
# DELETE /planner/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: planner.task_DeleteProgressTaskBoardFormat
export def "planner-tasks-progress-task-board-format DeleteProgressTaskBoardFormat" [
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/planner/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /planner/tasks/$count
# operationId: planner.task_GetCount
export def "planner-tasks-count GetCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/planner/tasks/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get planner from users
#
# GET /users/{user-id}/planner
# operationId: user_GetPlanner
export def "users-planner GetPlanner" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, plans: table<id: string, container: record, createdBy: record, createdDateTime: string, owner: string, title: string, buckets: list, details: record, tasks: list>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property planner in users
#
# PATCH /users/{user-id}/planner
# operationId: user_UpdatePlanner
# --plans item shape: {id?: string, container?: record, createdBy?: record, createdDateTime?: string, owner?: string, title?: string, buckets?: list, details?: any, tasks?: list}
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "users-planner UpdatePlanner" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --plans: list # Read-only. Nullable. Returns the plannerTasks assigned to the user. — item shape: {id?: string, container?: record, createdBy?: record, createdDateTime?: string, owner?: string, title?: string, buckets?: list, details?: any, tasks?: list}
  --tasks: list # Read-only. Nullable. Returns the plannerPlans shared with the user. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, plans: table<id: string, container: record, createdBy: record, createdDateTime: string, owner: string, title: string, buckets: list, details: record, tasks: list>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner")
  let body = {id: $id, plans: $plans, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property planner for users
#
# DELETE /users/{user-id}/planner
# operationId: user_DeletePlanner
export def "users-planner DeletePlanner" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plans from users
#
# GET /users/{user-id}/planner/plans
# operationId: user.planner_ListPlan
export def "users-planner-plans ListPlan" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to plans for users
#
# POST /users/{user-id}/planner/plans
# operationId: user.planner_CreatePlan
# --container shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
# --createdBy shape: {application?: record, device?: record, user?: record}
# --buckets item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "users-planner-plans CreatePlan" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --container: record # shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the plan is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --owner: string # Use the container property instead. ID of the group that owns the plan. After it's set, this property can’t be updated. This property won't return a valid group ID if the container of the plan isn't a group. (nullable)
  --title: string # Required. Title of the plan.
  --buckets: list # Read-only. Nullable. Collection of buckets in the plan. — item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
  --details: any
  --tasks: list # Read-only. Nullable. Collection of tasks in the plan. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, container: record<containerId: string, type: string, url: string>, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, owner: string, title: string, buckets: table<id: string, name: string, orderHint: string, planId: string, tasks: list>, details: record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans")
  let body = {id: $id, container: $container, createdBy: $createdBy, createdDateTime: $createdDateTime, owner: $owner, title: $title, buckets: $buckets, details: $details, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get plans from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}
# operationId: user.planner_GetPlan
export def "users-planner-plans GetPlan" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, container: record<containerId: string, type: string, url: string>, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, owner: string, title: string, buckets: table<id: string, name: string, orderHint: string, planId: string, tasks: list>, details: record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property plans in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}
# operationId: user.planner_UpdatePlan
# --container shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
# --createdBy shape: {application?: record, device?: record, user?: record}
# --buckets item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "users-planner-plans UpdatePlan" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --container: record # shape: {containerId?: string, type?: "group"|"unknownFutureValue"|"roster", url?: string}
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the plan is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --owner: string # Use the container property instead. ID of the group that owns the plan. After it's set, this property can’t be updated. This property won't return a valid group ID if the container of the plan isn't a group. (nullable)
  --title: string # Required. Title of the plan.
  --buckets: list # Read-only. Nullable. Collection of buckets in the plan. — item shape: {id?: string, name?: string, orderHint?: string, planId?: string, tasks?: list}
  --details: any
  --tasks: list # Read-only. Nullable. Collection of tasks in the plan. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, container: record<containerId: string, type: string, url: string>, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, owner: string, title: string, buckets: table<id: string, name: string, orderHint: string, planId: string, tasks: list>, details: record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record>, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)")
  let body = {id: $id, container: $container, createdBy: $createdBy, createdDateTime: $createdDateTime, owner: $owner, title: $title, buckets: $buckets, details: $details, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property plans for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}
# operationId: user.planner_DeletePlan
export def "users-planner-plans DeletePlan" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get buckets from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/buckets
# operationId: user.planner.plan_ListBucket
export def "users-planner-plans-buckets ListBucket" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to buckets for users
#
# POST /users/{user-id}/planner/plans/{plannerPlan-id}/buckets
# operationId: user.planner.plan_CreateBucket
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "users-planner-plans-buckets CreateBucket" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --name: string # Name of the bucket.
  --orderHint: string # Hint used to order items of this type in a list view. For details about the supported format, see Using order hints in Planner. (nullable)
  --planId: string # Plan ID to which the bucket belongs. (nullable)
  --tasks: list # Read-only. Nullable. The collection of tasks in the bucket. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets")
  let body = {id: $id, name: $name, orderHint: $orderHint, planId: $planId, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get buckets from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}
# operationId: user.planner.plan_GetBucket
export def "users-planner-plans-buckets GetBucket" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property buckets in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}
# operationId: user.planner.plan_UpdateBucket
# --tasks item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
export def "users-planner-plans-buckets UpdateBucket" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --name: string # Name of the bucket.
  --orderHint: string # Hint used to order items of this type in a list view. For details about the supported format, see Using order hints in Planner. (nullable)
  --planId: string # Plan ID to which the bucket belongs. (nullable)
  --tasks: list # Read-only. Nullable. The collection of tasks in the bucket. — item shape: {id?: string, activeChecklistItemCount?: float, appliedCategories?: record, assigneePriority?: string, assignments?: record, bucketId?: string, checklistItemCount?: float, completedBy?: record, completedDateTime?: string, conversationThreadId?: string, createdBy?: record, createdDateTime?: string, dueDateTime?: string, hasDescription?: bool, orderHint?: string, percentComplete?: float, planId?: string, previewType?: "automatic"|"noPreview"|"checklist"|"description"|"reference", priority?: float, referenceCount?: float, startDateTime?: string, title?: string, assignedToTaskBoardFormat?: any, bucketTaskBoardFormat?: any, details?: any, progressTaskBoardFormat?: any}
]: any -> record<id: string, name: string, orderHint: string, planId: string, tasks: table<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record, completedDateTime: string, conversationThreadId: string, createdBy: record, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record, bucketTaskBoardFormat: record, details: record, progressTaskBoardFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)")
  let body = {id: $id, name: $name, orderHint: $orderHint, planId: $planId, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property buckets for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}
# operationId: user.planner.plan_DeleteBucket
export def "users-planner-plans-buckets DeleteBucket" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tasks from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks
# operationId: user.planner.plan.bucket_ListTask
export def "users-planner-plans-buckets-tasks ListTask" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to tasks for users
#
# POST /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks
# operationId: user.planner.plan.bucket_CreateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "users-planner-plans-buckets-tasks CreateTask" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tasks from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: user.planner.plan.bucket_GetTask
export def "users-planner-plans-buckets-tasks GetTask" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property tasks in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: user.planner.plan.bucket_UpdateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "users-planner-plans-buckets-tasks UpdateTask" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property tasks for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}
# operationId: user.planner.plan.bucket_DeleteTask
export def "users-planner-plans-buckets-tasks DeleteTask" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get assignedToTaskBoardFormat from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: user.planner.plan.bucket.task_GetAssignedToTaskBoardFormat
export def "users-planner-plans-buckets-tasks-assigned-to-task-board-format GetAssignedToTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property assignedToTaskBoardFormat in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: user.planner.plan.bucket.task_UpdateAssignedToTaskBoardFormat
export def "users-planner-plans-buckets-tasks-assigned-to-task-board-format UpdateAssignedToTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHintsByAssignee: record
  --unassignedOrderHint: string # Hint value used to order the task on the AssignedTo view of the Task Board when the task isn't assigned to anyone, or if the orderHintsByAssignee dictionary doesn't provide an order hint for the user the task is assigned to. The format is defined as outlined here. (nullable)
]: any -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let body = {id: $id, orderHintsByAssignee: $orderHintsByAssignee, unassignedOrderHint: $unassignedOrderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property assignedToTaskBoardFormat for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: user.planner.plan.bucket.task_DeleteAssignedToTaskBoardFormat
export def "users-planner-plans-buckets-tasks-assigned-to-task-board-format DeleteAssignedToTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bucketTaskBoardFormat from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: user.planner.plan.bucket.task_GetBucketTaskBoardFormat
export def "users-planner-plans-buckets-tasks-bucket-task-board-format GetBucketTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property bucketTaskBoardFormat in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: user.planner.plan.bucket.task_UpdateBucketTaskBoardFormat
export def "users-planner-plans-buckets-tasks-bucket-task-board-format UpdateBucketTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint used to order tasks in the bucket view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property bucketTaskBoardFormat for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: user.planner.plan.bucket.task_DeleteBucketTaskBoardFormat
export def "users-planner-plans-buckets-tasks-bucket-task-board-format DeleteBucketTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: user.planner.plan.bucket.task_GetDetail
export def "users-planner-plans-buckets-tasks-details GetDetail" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property details in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: user.planner.plan.bucket.task_UpdateDetail
export def "users-planner-plans-buckets-tasks-details UpdateDetail" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --checklist: record
  --description: string # Description of the task. (nullable)
  --previewType: string@previewType-completer
  --references: record
]: any -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details")
  let body = {id: $id, checklist: $checklist, description: $description, previewType: $previewType, references: $references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/details
# operationId: user.planner.plan.bucket.task_DeleteDetail
export def "users-planner-plans-buckets-tasks-details DeleteDetail" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get progressTaskBoardFormat from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: user.planner.plan.bucket.task_GetProgressTaskBoardFormat
export def "users-planner-plans-buckets-tasks-progress-task-board-format GetProgressTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property progressTaskBoardFormat in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: user.planner.plan.bucket.task_UpdateProgressTaskBoardFormat
export def "users-planner-plans-buckets-tasks-progress-task-board-format UpdateProgressTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint value used to order the task on the progress view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property progressTaskBoardFormat for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: user.planner.plan.bucket.task_DeleteProgressTaskBoardFormat
export def "users-planner-plans-buckets-tasks-progress-task-board-format DeleteProgressTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/{plannerBucket-id}/tasks/$count
# operationId: user.planner.plan.bucket.task_GetCount
export def "users-planner-plans-buckets-tasks-count GetCount" [
  user_id: string
  plannerPlan_id: string
  plannerBucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/($plannerBucket_id)/tasks/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/buckets/$count
# operationId: user.planner.plan.bucket_GetCount
export def "users-planner-plans-buckets-count GetCount" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/buckets/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/details
# operationId: user.planner.plan_GetDetail
export def "users-planner-plans-details GetDetail" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property details in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/details
# operationId: user.planner.plan_UpdateDetail
# --categoryDescriptions shape: {category1?: string, category10?: string, category11?: string, category12?: string, category13?: string, category14?: string, category15?: string, category16?: string, category17?: string, category18?: string, category19?: string, category2?: string, category20?: string, category21?: string, category22?: string, category23?: string, category24?: string, category25?: string, category3?: string, category4?: string, category5?: string, category6?: string, category7?: string, category8?: string, category9?: string}
export def "users-planner-plans-details UpdateDetail" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --categoryDescriptions: record # shape: {category1?: string, category10?: string, category11?: string, category12?: string, category13?: string, category14?: string, category15?: string, category16?: string, category17?: string, category18?: string, category19?: string, category2?: string, category20?: string, category21?: string, category22?: string, category23?: string, category24?: string, category25?: string, category3?: string, category4?: string, category5?: string, category6?: string, category7?: string, category8?: string, category9?: string}
  --sharedWith: record
]: any -> record<id: string, categoryDescriptions: record<category1: string, category10: string, category11: string, category12: string, category13: string, category14: string, category15: string, category16: string, category17: string, category18: string, category19: string, category2: string, category20: string, category21: string, category22: string, category23: string, category24: string, category25: string, category3: string, category4: string, category5: string, category6: string, category7: string, category8: string, category9: string>, sharedWith: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/details")
  let body = {id: $id, categoryDescriptions: $categoryDescriptions, sharedWith: $sharedWith} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/details
# operationId: user.planner.plan_DeleteDetail
export def "users-planner-plans-details DeleteDetail" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tasks from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/tasks
# operationId: user.planner.plan_ListTask
export def "users-planner-plans-tasks ListTask" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to tasks for users
#
# POST /users/{user-id}/planner/plans/{plannerPlan-id}/tasks
# operationId: user.planner.plan_CreateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "users-planner-plans-tasks CreateTask" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tasks from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}
# operationId: user.planner.plan_GetTask
export def "users-planner-plans-tasks GetTask" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property tasks in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}
# operationId: user.planner.plan_UpdateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "users-planner-plans-tasks UpdateTask" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property tasks for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}
# operationId: user.planner.plan_DeleteTask
export def "users-planner-plans-tasks DeleteTask" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get assignedToTaskBoardFormat from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: user.planner.plan.task_GetAssignedToTaskBoardFormat
export def "users-planner-plans-tasks-assigned-to-task-board-format GetAssignedToTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property assignedToTaskBoardFormat in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: user.planner.plan.task_UpdateAssignedToTaskBoardFormat
export def "users-planner-plans-tasks-assigned-to-task-board-format UpdateAssignedToTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHintsByAssignee: record
  --unassignedOrderHint: string # Hint value used to order the task on the AssignedTo view of the Task Board when the task isn't assigned to anyone, or if the orderHintsByAssignee dictionary doesn't provide an order hint for the user the task is assigned to. The format is defined as outlined here. (nullable)
]: any -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let body = {id: $id, orderHintsByAssignee: $orderHintsByAssignee, unassignedOrderHint: $unassignedOrderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property assignedToTaskBoardFormat for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: user.planner.plan.task_DeleteAssignedToTaskBoardFormat
export def "users-planner-plans-tasks-assigned-to-task-board-format DeleteAssignedToTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bucketTaskBoardFormat from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: user.planner.plan.task_GetBucketTaskBoardFormat
export def "users-planner-plans-tasks-bucket-task-board-format GetBucketTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property bucketTaskBoardFormat in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: user.planner.plan.task_UpdateBucketTaskBoardFormat
export def "users-planner-plans-tasks-bucket-task-board-format UpdateBucketTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint used to order tasks in the bucket view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property bucketTaskBoardFormat for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: user.planner.plan.task_DeleteBucketTaskBoardFormat
export def "users-planner-plans-tasks-bucket-task-board-format DeleteBucketTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/details
# operationId: user.planner.plan.task_GetDetail
export def "users-planner-plans-tasks-details GetDetail" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property details in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/details
# operationId: user.planner.plan.task_UpdateDetail
export def "users-planner-plans-tasks-details UpdateDetail" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --checklist: record
  --description: string # Description of the task. (nullable)
  --previewType: string@previewType-completer
  --references: record
]: any -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/details")
  let body = {id: $id, checklist: $checklist, description: $description, previewType: $previewType, references: $references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/details
# operationId: user.planner.plan.task_DeleteDetail
export def "users-planner-plans-tasks-details DeleteDetail" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get progressTaskBoardFormat from users
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: user.planner.plan.task_GetProgressTaskBoardFormat
export def "users-planner-plans-tasks-progress-task-board-format GetProgressTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/progressTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property progressTaskBoardFormat in users
#
# PATCH /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: user.planner.plan.task_UpdateProgressTaskBoardFormat
export def "users-planner-plans-tasks-progress-task-board-format UpdateProgressTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint value used to order the task on the progress view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property progressTaskBoardFormat for users
#
# DELETE /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: user.planner.plan.task_DeleteProgressTaskBoardFormat
export def "users-planner-plans-tasks-progress-task-board-format DeleteProgressTaskBoardFormat" [
  user_id: string
  plannerPlan_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/planner/plans/{plannerPlan-id}/tasks/$count
# operationId: user.planner.plan.task_GetCount
export def "users-planner-plans-tasks-count GetCount" [
  user_id: string
  plannerPlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/($plannerPlan_id)/tasks/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/planner/plans/$count
# operationId: user.planner.plan_GetCount
export def "users-planner-plans-count GetCount" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/plans/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tasks from users
#
# GET /users/{user-id}/planner/tasks
# operationId: user.planner_ListTask
export def "users-planner-tasks ListTask" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to tasks for users
#
# POST /users/{user-id}/planner/tasks
# operationId: user.planner_CreateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "users-planner-tasks CreateTask" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tasks from users
#
# GET /users/{user-id}/planner/tasks/{plannerTask-id}
# operationId: user.planner_GetTask
export def "users-planner-tasks GetTask" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property tasks in users
#
# PATCH /users/{user-id}/planner/tasks/{plannerTask-id}
# operationId: user.planner_UpdateTask
# --completedBy shape: {application?: record, device?: record, user?: record}
# --createdBy shape: {application?: record, device?: record, user?: record}
export def "users-planner-tasks UpdateTask" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --activeChecklistItemCount: float # Number of checklist items with value set to false, representing incomplete items. (nullable, format: int32)
  --appliedCategories: record
  --assigneePriority: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --assignments: record
  --bucketId: string # Bucket ID to which the task belongs. The bucket needs to be in the plan that the task is in. It's 28 characters long and case-sensitive. Format validation is done on the service. (nullable)
  --checklistItemCount: float # Number of checklist items that are present on the task. (nullable, format: int32)
  --completedBy: record # shape: {application?: record, device?: record, user?: record}
  --completedDateTime: string # Read-only. Date and time at which the 'percentComplete' of the task is set to '100'. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --conversationThreadId: string # Thread ID of the conversation on the task. This is the ID of the conversation thread object created in the group. (nullable)
  --createdBy: record # shape: {application?: record, device?: record, user?: record}
  --createdDateTime: string # Read-only. Date and time at which the task is created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --dueDateTime: string # Date and time at which the task is due. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --hasDescription: oneof<nothing, bool> # Read-only. Value is true if the details object of the task has a nonempty description and false otherwise. (nullable)
  --orderHint: string # Hint used to order items of this type in a list view. The format is defined as outlined here. (nullable)
  --percentComplete: float # Percentage of task completion. When set to 100, the task is considered completed. (nullable, format: int32)
  --planId: string # Plan ID to which the task belongs. (nullable)
  --previewType: string@previewType-completer
  --priority: float # Priority of the task. The valid range of values is between 0 and 10, with the increasing value being lower priority (0 has the highest priority and 10 has the lowest priority).  Currently, Planner interprets values 0 and 1 as 'urgent', 2, 3 and 4 as 'important', 5, 6, and 7 as 'medium', and 8, 9, and 10 as 'low'.  Additionally, Planner sets the value 1 for 'urgent', 3 for 'important', 5 for 'medium', and 9 for 'low'. (nullable, format: int32)
  --referenceCount: float # Number of external references that exist on the task. (nullable, format: int32)
  --startDateTime: string # Date and time at which the task starts. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --title: string # Title of the task.
  --assignedToTaskBoardFormat: any
  --bucketTaskBoardFormat: any
  --details: any
  --progressTaskBoardFormat: any
]: any -> record<id: string, activeChecklistItemCount: float, appliedCategories: record, assigneePriority: string, assignments: record, bucketId: string, checklistItemCount: float, completedBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, completedDateTime: string, conversationThreadId: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>>, createdDateTime: string, dueDateTime: string, hasDescription: bool, orderHint: string, percentComplete: float, planId: string, previewType: string, priority: float, referenceCount: float, startDateTime: string, title: string, assignedToTaskBoardFormat: record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string>, bucketTaskBoardFormat: record<id: string, orderHint: string>, details: record<id: string, checklist: record, description: string, previewType: string, references: record>, progressTaskBoardFormat: record<id: string, orderHint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)")
  let body = {id: $id, activeChecklistItemCount: $activeChecklistItemCount, appliedCategories: $appliedCategories, assigneePriority: $assigneePriority, assignments: $assignments, bucketId: $bucketId, checklistItemCount: $checklistItemCount, completedBy: $completedBy, completedDateTime: $completedDateTime, conversationThreadId: $conversationThreadId, createdBy: $createdBy, createdDateTime: $createdDateTime, dueDateTime: $dueDateTime, hasDescription: $hasDescription, orderHint: $orderHint, percentComplete: $percentComplete, planId: $planId, previewType: $previewType, priority: $priority, referenceCount: $referenceCount, startDateTime: $startDateTime, title: $title, assignedToTaskBoardFormat: $assignedToTaskBoardFormat, bucketTaskBoardFormat: $bucketTaskBoardFormat, details: $details, progressTaskBoardFormat: $progressTaskBoardFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property tasks for users
#
# DELETE /users/{user-id}/planner/tasks/{plannerTask-id}
# operationId: user.planner_DeleteTask
export def "users-planner-tasks DeleteTask" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get assignedToTaskBoardFormat from users
#
# GET /users/{user-id}/planner/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: user.planner.task_GetAssignedToTaskBoardFormat
export def "users-planner-tasks-assigned-to-task-board-format GetAssignedToTaskBoardFormat" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/assignedToTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property assignedToTaskBoardFormat in users
#
# PATCH /users/{user-id}/planner/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: user.planner.task_UpdateAssignedToTaskBoardFormat
export def "users-planner-tasks-assigned-to-task-board-format UpdateAssignedToTaskBoardFormat" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHintsByAssignee: record
  --unassignedOrderHint: string # Hint value used to order the task on the AssignedTo view of the Task Board when the task isn't assigned to anyone, or if the orderHintsByAssignee dictionary doesn't provide an order hint for the user the task is assigned to. The format is defined as outlined here. (nullable)
]: any -> record<id: string, orderHintsByAssignee: record, unassignedOrderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let body = {id: $id, orderHintsByAssignee: $orderHintsByAssignee, unassignedOrderHint: $unassignedOrderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property assignedToTaskBoardFormat for users
#
# DELETE /users/{user-id}/planner/tasks/{plannerTask-id}/assignedToTaskBoardFormat
# operationId: user.planner.task_DeleteAssignedToTaskBoardFormat
export def "users-planner-tasks-assigned-to-task-board-format DeleteAssignedToTaskBoardFormat" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/assignedToTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bucketTaskBoardFormat from users
#
# GET /users/{user-id}/planner/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: user.planner.task_GetBucketTaskBoardFormat
export def "users-planner-tasks-bucket-task-board-format GetBucketTaskBoardFormat" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/bucketTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property bucketTaskBoardFormat in users
#
# PATCH /users/{user-id}/planner/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: user.planner.task_UpdateBucketTaskBoardFormat
export def "users-planner-tasks-bucket-task-board-format UpdateBucketTaskBoardFormat" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint used to order tasks in the bucket view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property bucketTaskBoardFormat for users
#
# DELETE /users/{user-id}/planner/tasks/{plannerTask-id}/bucketTaskBoardFormat
# operationId: user.planner.task_DeleteBucketTaskBoardFormat
export def "users-planner-tasks-bucket-task-board-format DeleteBucketTaskBoardFormat" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/bucketTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details from users
#
# GET /users/{user-id}/planner/tasks/{plannerTask-id}/details
# operationId: user.planner.task_GetDetail
export def "users-planner-tasks-details GetDetail" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property details in users
#
# PATCH /users/{user-id}/planner/tasks/{plannerTask-id}/details
# operationId: user.planner.task_UpdateDetail
export def "users-planner-tasks-details UpdateDetail" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --checklist: record
  --description: string # Description of the task. (nullable)
  --previewType: string@previewType-completer
  --references: record
]: any -> record<id: string, checklist: record, description: string, previewType: string, references: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/details")
  let body = {id: $id, checklist: $checklist, description: $description, previewType: $previewType, references: $references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property details for users
#
# DELETE /users/{user-id}/planner/tasks/{plannerTask-id}/details
# operationId: user.planner.task_DeleteDetail
export def "users-planner-tasks-details DeleteDetail" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/details")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get progressTaskBoardFormat from users
#
# GET /users/{user-id}/planner/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: user.planner.task_GetProgressTaskBoardFormat
export def "users-planner-tasks-progress-task-board-format GetProgressTaskBoardFormat" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, orderHint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/progressTaskBoardFormat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property progressTaskBoardFormat in users
#
# PATCH /users/{user-id}/planner/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: user.planner.task_UpdateProgressTaskBoardFormat
export def "users-planner-tasks-progress-task-board-format UpdateProgressTaskBoardFormat" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag value.
  --id: string # The unique identifier for an entity. Read-only.
  --orderHint: string # Hint value used to order the task on the progress view of the task board. For details about the supported format, see Using order hints in Planner. (nullable)
]: any -> record<id: string, orderHint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let body = {id: $id, orderHint: $orderHint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property progressTaskBoardFormat for users
#
# DELETE /users/{user-id}/planner/tasks/{plannerTask-id}/progressTaskBoardFormat
# operationId: user.planner.task_DeleteProgressTaskBoardFormat
export def "users-planner-tasks-progress-task-board-format DeleteProgressTaskBoardFormat" [
  user_id: string
  plannerTask_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/($plannerTask_id)/progressTaskBoardFormat")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/planner/tasks/$count
# operationId: user.planner.task_GetCount
export def "users-planner-tasks-count GetCount" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/planner/tasks/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
