# Auto-generated client for Wrike API v4.0
# Source: https://developers.wrike.com/openapi/wrike_api_v4_ver154.yaml
# Auth: --token flag or $env.WRIKE_API_TOKEN

const BASE_URL = "https://www.wrike.com/api/v4"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WRIKE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.wrike.com/api/v4" "https://app-eu.wrike.com/api/v4" "https://app-us2.wrike.com/api/v4"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def statuses-completer [] { ["Approved" "Cancelled" "Draft" "Pending" "Rejected"] }
def type-completer [] { ["FilesOnly" "Regular"] }
def size-completer [] { ["h400" "w100" "w200" "w300" "w400" "w44"] }
def objectType-completer [] { ["AccessRole" "Account" "AnalyzeReport" "AnalyzeReportWidget" "Attachment" "CalendarExternalLink" "Comment" "CustomField" "DataExport" "Folder" "Group" "Invitation" "Oauth2Client" "PowerBIEntity" "Project" "PublicLink" "RequestForm" "Space" "Task" "Timesheet" "TimesheetTimeframeSettings" "User" "UserRole" "UserType" "Whiteboard" "Workflow" "WorkspaceSnapshot"] }
def type-completer-1 [] { ["CalculatedDate" "CalculatedNumeric" "Checkbox" "Contacts" "Currency" "Date" "DropDown" "Duration" "LinkToDatabase" "Multiple" "Numeric" "Percentage" "Text"] }
def changeScope-completer [] { ["Account" "Space"] }
def type-completer-2 [] { ["Project" "Task"] }
def version-completer [] { ["V0" "V1" "V2" "V3" "V4"] }
def relationType-completer [] { ["FinishToFinish" "FinishToStart" "StartToFinish" "StartToStart"] }
def rescheduleMode-completer [] { ["End" "Start"] }
def type-completer-3 [] { ["ApiV2Account" "ApiV2Attachment" "ApiV2Comment" "ApiV2Folder" "ApiV2RequestForm" "ApiV2Task" "ApiV2Timelog" "ApiV2User"] }
def role-completer [] { ["Collaborator" "User"] }
def avatarColor-completer [] { ["Blue1" "Blue2" "DarkBlue1" "DarkBlue2" "DarkCyan1" "DarkCyan2" "Green1" "Green2" "Orange1" "Orange2" "Pink1" "Pink2" "Purple1" "Purple2" "Red1" "Red2" "Turquoise1" "Turquoise2" "Yellow1" "Yellow2" "YellowGreen1" "YellowGreen2"] }
def accessType-completer [] { ["Locked" "Private" "Public"] }
def accessType-completer-1 [] { ["Private" "Public"] }
def importance-completer [] { ["High" "Low" "Normal"] }
def type-completer-4 [] { ["Backlog" "Milestone" "Planned"] }
def sortField-completer [] { ["CompletedDate" "CreatedDate" "DueDate" "Importance" "LastAccessDate" "StartFinishInterval" "Status" "Title" "UpdatedDate"] }
def sortOrder-completer [] { ["Asc" "Desc"] }
def status-completer [] { ["Active" "Cancelled" "Completed" "Deferred"] }
def billingType-completer [] { ["Billable" "NonBillable"] }
def ruleType-completer [] { ["Hard" "Soft"] }
def frequency-completer [] { ["Day" "Month" "Week"] }
def trackExceptionsMode-completer [] { ["ActualCapacity" "TotalCapacity"] }
def timeframe-completer [] { ["Monthly" "Weekly"] }
def approvalStatus-completer [] { ["Approved" "NotSubmitted" "Pending" "Rejected"] }
def exclusionType-completer [] { ["OtherNonWorking" "Overtime" "VacationPTO"] }
def exclusionType-completer-1 [] { ["OtherNonWorking" "VacationPTO"] }
def exclusionType-completer-2 [] { ["AdditionalWorkDays" "OtherEvent" "PublicHolidays"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "access-roles roles/empty" } } | get name | first)
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

# Get Access Roles
#
# GET /access_roles
# operationId: GET:/access_roles/empty
export def "access-roles roles/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<description: string, id: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/access_roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Accounts
#
# GET /account
# operationId: GET:/account/empty
export def "account GET:/account/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: string # Metadata filter, exact match for metadata key or key-value pair
  --qp-fields: string # Json string array of optional fields to be included in the response model * `metadata` - Account metadata * `customFields` - Account custom fields * `subscription` - Account subscription
]: nothing -> record<data: table<metadata: list, createdDate: string, workDays: list, dateFormat: string, firstDayOfWeek: string, customFields: list, name: string, recycleBinId: string, rootFolderId: string, id: string, subscription: record, joinedDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata" $metadata "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify Account
#
# PUT /account
# operationId: PUT:/account/empty
export def "account PUT:/account/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: string # Metadata to be updated. Limit : `100`
]: nothing -> record<data: table<metadata: list, createdDate: string, workDays: list, dateFormat: string, firstDayOfWeek: string, customFields: list, name: string, recycleBinId: string, rootFolderId: string, id: string, subscription: record, joinedDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata" $metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Approvals (Account)
#
# GET /approvals
# operationId: GET:/approvals/empty
export def "approvals GET:/approvals/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statuses: string@statuses-completer # Get approvals for specified statuses * `Draft` * `Approved` * `Rejected` * `Cancelled` * `Pending`
  --updatedDate: string # Last updated date filter, exact match or range
  --approvers: string # Approvers filter, match of any
  --pendingApprovers: string # Pending approvers filter, match of any
  --type: string@type-completer # Get approvals for specified types * `FilesOnly` * `Regular`
  --dueDate: string # Due date filter, exact match or range
  --limit: float # Limit on number of returned approvals
  --pageSize: float # Page size
  --nextPageToken: string # Next page token, overrides any other parameters in request
]: nothing -> record<data: table<dueDate: string, description: string, finished: bool, updatedDate: string, authorId: string, title: string, type: string, autoFinishOnReject: bool, folderId: string, finisherId: string, autoFinishOnApprove: bool, decisions: list, attachmentIds: list, id: string, taskId: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statuses" $statuses "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "approvers" $approvers "scalar") (serialize-qp "pendingApprovers" $pendingApprovers "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "dueDate" $dueDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/approvals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Approvals (Folder)
#
# GET /folders/{folderId}/approvals
# operationId: GET:/folders/single/approvals
export def "folders-approvals GET:/folders/single/approvals" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<dueDate: string, description: string, finished: bool, updatedDate: string, authorId: string, title: string, type: string, autoFinishOnReject: bool, folderId: string, finisherId: string, autoFinishOnApprove: bool, decisions: list, attachmentIds: list, id: string, taskId: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folderId)/approvals")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Approvals (Folder)
#
# POST /folders/{folderId}/approvals
# operationId: POST:/folders/single/approvals
export def "folders-approvals POST:/folders/single/approvals" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description
  --dueDate: string # Due date Format: yyyy-MM-dd
  --approvers: string # Assign approvers
  --attachments: string # List of origin version attachments to set in approval
  --autoFinishOnApprove: string # Is finish approval automatically when all approvers have approved. Set to true by default
  --autoFinishOnReject: string # Is finish approval automatically when some of approvers have rejected. Set to true by default
]: nothing -> record<data: table<dueDate: string, description: string, finished: bool, updatedDate: string, authorId: string, title: string, type: string, autoFinishOnReject: bool, folderId: string, finisherId: string, autoFinishOnApprove: bool, decisions: list, attachmentIds: list, id: string, taskId: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "description" $description "scalar") (serialize-qp "dueDate" $dueDate "scalar") (serialize-qp "approvers" $approvers "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "autoFinishOnApprove" $autoFinishOnApprove "scalar") (serialize-qp "autoFinishOnReject" $autoFinishOnReject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/approvals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Approvals (Task)
#
# GET /tasks/{taskId}/approvals
# operationId: GET:/tasks/single/approvals
export def "tasks-approvals GET:/tasks/single/approvals" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<dueDate: string, description: string, finished: bool, updatedDate: string, authorId: string, title: string, type: string, autoFinishOnReject: bool, folderId: string, finisherId: string, autoFinishOnApprove: bool, decisions: list, attachmentIds: list, id: string, taskId: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)/approvals")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Approvals (Task)
#
# POST /tasks/{taskId}/approvals
# operationId: POST:/tasks/single/approvals
export def "tasks-approvals POST:/tasks/single/approvals" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description
  --dueDate: string # Due date Format: yyyy-MM-dd
  --approvers: string # Assign approvers
  --attachments: string # List of origin version attachments to set in approval
  --autoFinishOnApprove: string # Is finish approval automatically when all approvers have approved. Set to true by default
  --autoFinishOnReject: string # Is finish approval automatically when some of approvers have rejected. Set to true by default
]: nothing -> record<data: table<dueDate: string, description: string, finished: bool, updatedDate: string, authorId: string, title: string, type: string, autoFinishOnReject: bool, folderId: string, finisherId: string, autoFinishOnApprove: bool, decisions: list, attachmentIds: list, id: string, taskId: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "description" $description "scalar") (serialize-qp "dueDate" $dueDate "scalar") (serialize-qp "approvers" $approvers "scalar") (serialize-qp "attachments" $attachments "scalar") (serialize-qp "autoFinishOnApprove" $autoFinishOnApprove "scalar") (serialize-qp "autoFinishOnReject" $autoFinishOnReject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/approvals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Approvals By ID
#
# GET /approvals/{approvalIds}
# operationId: GET:/approvals/multi
export def "approvals GET:/approvals/multi" [
  approvalIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<dueDate: string, description: string, finished: bool, updatedDate: string, authorId: string, title: string, type: string, autoFinishOnReject: bool, folderId: string, finisherId: string, autoFinishOnApprove: bool, decisions: list, attachmentIds: list, id: string, taskId: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/approvals/($approvalIds)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update approval
#
# PUT /approvals/{approvalId}
# operationId: PUT:/approvals/single
export def "approvals PUT:/approvals/single" [
  approvalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # description
  --dueDate: string # due date Format: yyyy-MM-dd
  --addApprovers: string # Assign approvers
  --removeApprovers: string # Remove approvers
  --addAttachments: string # Add origin version attachments to approval
  --removeAttachments: string # Remove origin version attachments from approval
  --autoFinishOnApprove: string # Is finish approval automatically when all approvers have approved
  --autoFinishOnReject: string # Is finish approval automatically when some of approvers have rejected
]: nothing -> record<data: table<dueDate: string, description: string, finished: bool, updatedDate: string, authorId: string, title: string, type: string, autoFinishOnReject: bool, folderId: string, finisherId: string, autoFinishOnApprove: bool, decisions: list, attachmentIds: list, id: string, taskId: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "description" $description "scalar") (serialize-qp "dueDate" $dueDate "scalar") (serialize-qp "addApprovers" $addApprovers "scalar") (serialize-qp "removeApprovers" $removeApprovers "scalar") (serialize-qp "addAttachments" $addAttachments "scalar") (serialize-qp "removeAttachments" $removeAttachments "scalar") (serialize-qp "autoFinishOnApprove" $autoFinishOnApprove "scalar") (serialize-qp "autoFinishOnReject" $autoFinishOnReject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/approvals/($approvalId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel approval
#
# DELETE /approvals/{approvalId}
# operationId: DELETE:/approvals/single
export def "approvals DELETE:/approvals/single" [
  approvalId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<dueDate: string, description: string, finished: bool, updatedDate: string, authorId: string, title: string, type: string, autoFinishOnReject: bool, folderId: string, finisherId: string, autoFinishOnApprove: bool, decisions: list, attachmentIds: list, id: string, taskId: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/approvals/($approvalId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Equipment
#
# POST /assets
# operationId: POST:/assets/empty
export def "assets POST:/assets/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of asset, required
]: nothing -> record<data: table<name: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Equipment
#
# PUT /assets/{assetId}
# operationId: PUT:/assets/single
export def "assets PUT:/assets/single" [
  assetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of asset, required
]: nothing -> record<data: table<name: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/assets/($assetId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Equipment
#
# DELETE /assets/{assetId}
# operationId: DELETE:/assets/single
export def "assets DELETE:/assets/single" [
  assetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<name: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/assets/($assetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get async job
#
# GET /async_job/{asyncJobId}
# operationId: GET:/async_job/single
export def "async-job job/single" [
  asyncJobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<result: record, processedCount: float, errorMessage: string, progressPercent: float, id: string, totalCount: float, type: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/async_job/($asyncJobId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Attachments (Account)
#
# GET /attachments
# operationId: GET:/attachments/empty
export def "attachments GET:/attachments/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versions: oneof<nothing, bool> # Get attachments with previous versions
  --createdDate: string # Created date filter. Required to request attachments in account. Time range duration should be less than 31 day
  --withUrls: oneof<nothing, bool> # Get attachment URLs. The link for attachment from Wrike is valid for 24 hours from when you make the request
]: nothing -> record<data: table<currentAttachmentId: string, originVersionId: string, reviewIds: list, previewUrl: string, playlistUrl: string, authorId: string, type: string, version: float, folderId: string, url: string, createdDate: string, size: float, name: string, width: float, commentId: string, id: string, contentType: string, taskId: string, height: float>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versions" $versions "scalar") (serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "withUrls" $withUrls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Attachments (Folder)
#
# GET /folders/{folderId}/attachments
# operationId: GET:/folders/single/attachments
export def "folders-attachments GET:/folders/single/attachments" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versions: oneof<nothing, bool> # Get attachments with previous versions
  --createdDate: string # Created date filter. Required to request attachments in account. Time range duration should be less than 31 day
  --withUrls: oneof<nothing, bool> # Get attachment URLs. The link for attachment from Wrike is valid for 24 hours from when you make the request
]: nothing -> record<data: table<currentAttachmentId: string, originVersionId: string, reviewIds: list, previewUrl: string, playlistUrl: string, authorId: string, type: string, version: float, folderId: string, url: string, createdDate: string, size: float, name: string, width: float, commentId: string, id: string, contentType: string, taskId: string, height: float>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versions" $versions "scalar") (serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "withUrls" $withUrls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Attachment (Folder)
#
# POST /folders/{folderId}/attachments
# operationId: POST:/folders/single/attachments
export def "folders-attachments POST:/folders/single/attachments" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<currentAttachmentId: string, originVersionId: string, reviewIds: list, previewUrl: string, playlistUrl: string, authorId: string, type: string, version: float, folderId: string, url: string, createdDate: string, size: float, name: string, width: float, commentId: string, id: string, contentType: string, taskId: string, height: float>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folderId)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Attachments (Task)
#
# GET /tasks/{taskId}/attachments
# operationId: GET:/tasks/single/attachments
export def "tasks-attachments GET:/tasks/single/attachments" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versions: oneof<nothing, bool> # Get attachments with previous versions
  --createdDate: string # Created date filter. Required to request attachments in account. Time range duration should be less than 31 day
  --withUrls: oneof<nothing, bool> # Get attachment URLs. The link for attachment from Wrike is valid for 24 hours from when you make the request
]: nothing -> record<data: table<currentAttachmentId: string, originVersionId: string, reviewIds: list, previewUrl: string, playlistUrl: string, authorId: string, type: string, version: float, folderId: string, url: string, createdDate: string, size: float, name: string, width: float, commentId: string, id: string, contentType: string, taskId: string, height: float>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versions" $versions "scalar") (serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "withUrls" $withUrls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Attachment (Task)
#
# POST /tasks/{taskId}/attachments
# operationId: POST:/tasks/single/attachments
export def "tasks-attachments POST:/tasks/single/attachments" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<currentAttachmentId: string, originVersionId: string, reviewIds: list, previewUrl: string, playlistUrl: string, authorId: string, type: string, version: float, folderId: string, url: string, createdDate: string, size: float, name: string, width: float, commentId: string, id: string, contentType: string, taskId: string, height: float>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Attachments By ID
#
# GET /attachments/{attachmentIds}
# operationId: GET:/attachments/multi
export def "attachments GET:/attachments/multi" [
  attachmentIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versions: oneof<nothing, bool> # Get attachments with previous versions
]: nothing -> record<data: table<currentAttachmentId: string, originVersionId: string, reviewIds: list, previewUrl: string, playlistUrl: string, authorId: string, type: string, version: float, folderId: string, url: string, createdDate: string, size: float, name: string, width: float, commentId: string, id: string, contentType: string, taskId: string, height: float>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versions" $versions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/attachments/($attachmentIds)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Attachment
#
# GET /attachments/{attachmentId}/download
# operationId: GET:/attachments/single/download
export def "attachments-download GET:/attachments/single/download" [
  attachmentId: string
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
  let full_url = (build-url $base $"/attachments/($attachmentId)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Preview Attachment
#
# GET /attachments/{attachmentId}/preview
# operationId: GET:/attachments/single/preview
export def "attachments-preview GET:/attachments/single/preview" [
  attachmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --size: string@size-completer # Preview dimensions * `w44` - Width = 44, height = auto * `w300` - Width = 300, height = auto * `w400` - Width = 400, height = auto * `w100` - Width = 100, height = auto * `h400` - Width = auto, height = 400 * `w200` - Width = 200, height = auto
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/attachments/($attachmentId)/preview" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Attachment URL
#
# GET /attachments/{attachmentId}/url
# operationId: GET:/attachments/single/url
export def "attachments-url GET:/attachments/single/url" [
  attachmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<playlistUrl: string, url: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attachments/($attachmentId)/url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Attachment
#
# PUT /attachments/{attachmentId}
# operationId: PUT:/attachments/single
export def "attachments PUT:/attachments/single" [
  attachmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-url: string # Download attachment by url
]: nothing -> record<data: table<currentAttachmentId: string, originVersionId: string, reviewIds: list, previewUrl: string, playlistUrl: string, authorId: string, type: string, version: float, folderId: string, url: string, createdDate: string, size: float, name: string, width: float, commentId: string, id: string, contentType: string, taskId: string, height: float>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/attachments/($attachmentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Attachment
#
# DELETE /attachments/{attachmentId}
# operationId: DELETE:/attachments/single
export def "attachments DELETE:/attachments/single" [
  attachmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: list<string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attachments/($attachmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Audit Log
#
# GET /audit_log
# operationId: GET:/audit_log/empty
export def "audit-log log/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --eventDate: string # Event date filter, range
  --operations: string # Operations filter * `SecondFactorEnabled` * `CustomFieldRemoved` * `CalendarExternalLinksActivated` * `TaskDuplication` * `GanttSnapshotDeleted` * `CalendarExternalLinkDeleted` * `TaskRestored` * `CalendarExternalLinksDeactivated` * `PowerBIPublicLinkDeleted` * `ApprovalCanceled` * `RequestFormCreated` * `SamlClearPasswordForSamlUsers` * `OneTimePasswordUsed` * `AnalyzeWidgetPublicLinkCreated` * `TaskErased` * `InvitationPolicyChanged` * `CalendarExternalLinkCreated` * `UserTaskGroupRolesChanged` * `UserJoinedSpace` * `SamlSSOSettingsChanged` * `UserFailLogin` * `SamlSSODisabled` * `AdminMailSettingsChanged` * `CustomFieldRemovedFromFolder` * `UserLoggedIn` * `UserRoleChanged` * `CustomFieldAddedToFolder` * `UserTypeModified` * `AccessCodeAccepted` * `PublicLinkExpirationChanged` * `UserLogout` * `PowerBIPublicLinkCreated` * `GuestReviewerRevoked` * `ApprovedIpRangesOrSubnetsChanged` * `TaskScheduleChanged` * `CustomFieldRestored` * `AccountDeleted` * `UserAdminPermissionsChanged` * `AttachDeleted` * `SpaceDeleted` * `AuditReportCreated` * `UserTypeCreated` * `ExcelExportCreated` * `AdminLoggedInAsUser` * `WorkflowCreated` * `TaskUnsharedFromAuthor` * `AccessAuditReportCsvExport` * `AttachMarkAsFinal` * `OneTimePasswordStatusSwitched` * `ApproverAdded` * `UserLeftSpace` * `TaskUnarchived` * `ApprovalDescriptionChanged` * `GroupParentRemoved` * `GuestReviewAccountSettingsChanged` * `WorkflowDeleted` * `PasswordPolicyModified` * `GroupInviteeAdded` * `UserRestored` * `WorkflowArchived` * `ApprovalDueDateChanged` * `AnalyzeWidgetPublicLinkDeleted` * `SpaceArchivedUnarchived` * `TaskStatusChanged` * `TaskCommentChanged` * `AccessRoleDeleted` * `TaskUnassigned` * `AnalyzePublicLinkCreated` * `GuestReviewRejected` * `TaskUnshared` * `PasswordChanged` * `RequestFormDeleted` * `AttemptDownloadInfectedAttach` * `InvitationSend` * `AccessRoleModified` * `SpaceCreated` * `ApprovedDomainsChanged` * `TimesheetStatusChanged` * `TimelogLocked` * `UserRevokeAdmin` * `RecycleBinErased` * `ApproverRemoved` * `UserDeleted` * `GanttSnapshotCreated` * `GroupMemberRemoved` * `UserProfileUpdated` * `SecondFactorUsageReportCreated` * `SecondFactorDisabled` * `WhiteboardCreated` * `AttachViewed` * `AccessRoleCreated` * `GroupMemberAdded` * `AccountDataExportRequested` * `SamlSSOMetadataChanged` * `GroupRenamed` * `PublicLinkCreated` * `TaskShared` * `AccountModified` * `PublicLinkPasswordRequested` * `WorkflowModified` * `PublicLinkDeleted` * `AccessCodeDeclined` * `AnalyzeWidgetPublicLinkAccessed` * `ApprovalCreated` * `Oauth2AccessRevoked` * `TaskParentRemoved` * `AntivirusDeletedInfectedAttach` * `RequestFormModified` * `GroupInviteeRemoved` * `GuestReviewerInvited` * `TaskArchived` * `AccountBackupCreated` * `FeedCreated` * `AccessCodeGenerated` * `UserDeactivated` * `AttachCopied` * `GroupParentAdded` * `GuestReviewerChanged` * `TimelogUnlocked` * `TaskCreated` * `WhiteboardRemoved` * `OneTimePasswordRevoked` * `ApprovalFinished` * `TaskAssigned` * `OneTimePasswordCreated` * `GroupCreated` * `TimesheetCreated` * `UsersAndGroupsExported` * `AttachMoved` * `CustomFieldCreated` * `AutomatedIntegrationsExecution` * `PowerBIPublicLinkAccessed` * `AttachUnmarkAsFinal` * `AnalyzePublicLinkAccessed` * `TimesheetTimeframeSettingsModified` * `GroupDeleted` * `CustomFieldModified` * `TaskCommentDeleted` * `AnalyzePublicLinkDeleted` * `UserTypeDeleted` * `TimesheetTimeframeSettingsCreated` * `Oauth2AccessGranted` * `UserGrantAdmin` * `PublicLinksAccountSettingsChanged` * `WorkflowUnarchived` * `TaskDeleted` * `InvitationAccepted` * `AccountDataExportGenerated` * `SamlSSOEnabled` * `PublicLinkPasswordChanged` * `TaskParentAdded` * `ApprovalDecisionMade` * `GuestReviewAccepted` * `UserCustomFieldValueChanged` * `UserActivated` * `AttachUploaded` * `AttachDownloaded`
  --pageSize: float # Page size
  --nextPageToken: string # Next page token, overrides any other parameters in request
  --objectType: string@objectType-completer # Filter by object type. Requires both eventDate and operations to be specified. * `Account` * `Group` * `AnalyzeReportWidget` * `Task` * `User` * `WorkspaceSnapshot` * `TimesheetTimeframeSettings` * `CalendarExternalLink` * `Attachment` * `Folder` * `DataExport` * `PowerBIEntity` * `Whiteboard` * `Space` * `Comment` * `RequestForm` * `AccessRole` * `Timesheet` * `Invitation` * `Workflow` * `AnalyzeReport` * `Oauth2Client` * `Project` * `PublicLink` * `UserRole` * `CustomField` * `UserType`
  --objectIds: string # Filter by object ids. Requires objectType to be specified. Accepts up to 10 ids.
  --users: string # Filter by users ids. Accepts up to 10 ids.
]: nothing -> record<data: table<ipAddress: string, objectName: string, userEmail: string, details: record, id: string, operation: string, userId: string, objectId: string, eventDate: string, objectType: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventDate" $eventDate "scalar") (serialize-qp "operations" $operations "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "objectType" $objectType "scalar") (serialize-qp "objectIds" $objectIds "scalar") (serialize-qp "users" $users "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/audit_log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Batch Operation
#
# POST /batch
# operationId: POST:/batch/empty
export def "batch POST:/batch/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --operations: string # Array of operations to execute. Limit : `100`
]: nothing -> record<data: table<result: record, processedCount: float, errorMessage: string, progressPercent: float, id: string, totalCount: float, type: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "operations" $operations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Bookings By ID
#
# GET /bookings/{bookingIds}
# operationId: GET:/bookings/multi
export def "bookings GET:/bookings/multi" [
  bookingIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<responsiblePlaceholderId: string, bookingDates: record, responsibleId: string, id: string, effortAllocation: record, title: string, folderId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bookings/($bookingIds)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Bookings (Account)
#
# GET /bookings
# operationId: GET:/bookings/empty
export def "bookings GET:/bookings/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # Start date Format: yyyy-MM-dd
  --finishDate: string # Finish date Format: yyyy-MM-dd
  --responsibleIds: string # IDs of responsible users. Limit : `15000`
  --responsiblePlaceholderIds: string # IDs of responsible placeholders. Limit : `15000`
  --showDescendants: string # If true return bookings from descendant folders (default: false)
]: nothing -> record<data: table<responsiblePlaceholderId: string, bookingDates: record, responsibleId: string, id: string, effortAllocation: record, title: string, folderId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "finishDate" $finishDate "scalar") (serialize-qp "responsibleIds" $responsibleIds "scalar") (serialize-qp "responsiblePlaceholderIds" $responsiblePlaceholderIds "scalar") (serialize-qp "showDescendants" $showDescendants "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bookings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Bookings (Folder)
#
# GET /folders/{folderId}/bookings
# operationId: GET:/folders/single/bookings
export def "folders-bookings GET:/folders/single/bookings" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # Start date Format: yyyy-MM-dd
  --finishDate: string # Finish date Format: yyyy-MM-dd
  --responsibleIds: string # IDs of responsible users. Limit : `15000`
  --responsiblePlaceholderIds: string # IDs of responsible placeholders. Limit : `15000`
  --showDescendants: string # If true return bookings from descendant folders (default: false)
]: nothing -> record<data: table<responsiblePlaceholderId: string, bookingDates: record, responsibleId: string, id: string, effortAllocation: record, title: string, folderId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "finishDate" $finishDate "scalar") (serialize-qp "responsibleIds" $responsibleIds "scalar") (serialize-qp "responsiblePlaceholderIds" $responsiblePlaceholderIds "scalar") (serialize-qp "showDescendants" $showDescendants "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/bookings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Booking
#
# POST /folders/{folderId}/bookings
# operationId: POST:/folders/single/bookings
export def "folders-bookings POST:/folders/single/bookings" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookingDates: string # Booking dates
  --responsibleId: string # ID of responsible
  --responsiblePlaceholderId: string # ID of responsible placeholder
  --effortAllocation: string # Effort allocation
]: nothing -> record<data: table<responsiblePlaceholderId: string, bookingDates: record, responsibleId: string, id: string, effortAllocation: record, title: string, folderId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookingDates" $bookingDates "scalar") (serialize-qp "responsibleId" $responsibleId "scalar") (serialize-qp "responsiblePlaceholderId" $responsiblePlaceholderId "scalar") (serialize-qp "effortAllocation" $effortAllocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/bookings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Booking
#
# PUT /bookings/{bookingId}
# operationId: PUT:/bookings/single
export def "bookings PUT:/bookings/single" [
  bookingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookingDates: string # Booking dates
  --responsibleId: string # ID of responsible
  --responsiblePlaceholderId: string # ID of responsible placeholder
  --effortAllocation: string # Effort allocation
]: nothing -> record<data: table<responsiblePlaceholderId: string, bookingDates: record, responsibleId: string, id: string, effortAllocation: record, title: string, folderId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookingDates" $bookingDates "scalar") (serialize-qp "responsibleId" $responsibleId "scalar") (serialize-qp "responsiblePlaceholderId" $responsiblePlaceholderId "scalar") (serialize-qp "effortAllocation" $effortAllocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bookings/($bookingId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Booking
#
# DELETE /bookings/{bookingId}
# operationId: DELETE:/bookings/single
export def "bookings DELETE:/bookings/single" [
  bookingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<responsiblePlaceholderId: string, bookingDates: record, responsibleId: string, id: string, effortAllocation: record, title: string, folderId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bookings/($bookingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger field cascading
#
# POST /folders/{folderId}/cascading_field_settings
# operationId: POST:/folders/single/cascading_field_settings
export def "folders-cascading-field-settings settings-by-folderId" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fieldId: string # Field id
]: nothing -> record<data: table<systemField: bool, enabledBy: string, enabledAt: string, fieldId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldId" $fieldId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/cascading_field_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete active cascading field settings
#
# DELETE /folders/{folderId}/cascading_field_settings
# operationId: DELETE:/folders/single/cascading_field_settings
export def "folders-cascading-field-settings settings-by-folderId-1" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fieldId: string # Field id
]: nothing -> record<data: table<systemField: bool, enabledBy: string, enabledAt: string, fieldId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldId" $fieldId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/cascading_field_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger field cascading
#
# POST /tasks/{taskId}/cascading_field_settings
# operationId: POST:/tasks/single/cascading_field_settings
export def "tasks-cascading-field-settings settings-by-taskId" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fieldId: string # Field id
]: nothing -> record<data: table<systemField: bool, enabledBy: string, enabledAt: string, fieldId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldId" $fieldId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/cascading_field_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete active cascading field settings
#
# DELETE /tasks/{taskId}/cascading_field_settings
# operationId: DELETE:/tasks/single/cascading_field_settings
export def "tasks-cascading-field-settings settings-by-taskId-1" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fieldId: string # Field id
]: nothing -> record<data: table<systemField: bool, enabledBy: string, enabledAt: string, fieldId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldId" $fieldId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/cascading_field_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Colors
#
# GET /colors
# operationId: GET:/colors/empty
export def "colors GET:/colors/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<name: string, hex: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/colors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Comments (Account)
#
# GET /comments
# operationId: GET:/comments/empty
export def "comments GET:/comments/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --types: string # Comment type filter * `Email` * `Regular`
  --updatedDate: string # Deprecated because this parameter filters by created date instead of updated date. Please use the createdDate parameter instead
  --createdDate: string # Use the createdDate parameter to get all comments created within a specific date range. The date range must be 7 days or shorter
  --limit: float # Maximum number of returned comments (default: 1000)
  --qp-fields: string # Json string array of optional fields to be included in the response model * `type` - Comment type
]: nothing -> record<data: table<externalRequester: record, createdDate: string, id: string, text: string, updatedDate: string, authorId: string, type: string, emailSubject: string, taskId: string, folderId: string, direction: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "plainText" $plainText "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Comments (Folder)
#
# GET /folders/{folderId}/comments
# operationId: GET:/folders/single/comments
export def "folders-comments GET:/folders/single/comments" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --types: string # Comment type filter * `Email` * `Regular`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `type` - Comment type
]: nothing -> record<data: table<externalRequester: record, createdDate: string, id: string, text: string, updatedDate: string, authorId: string, type: string, emailSubject: string, taskId: string, folderId: string, direction: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "plainText" $plainText "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Comment (Folder)
#
# POST /folders/{folderId}/comments
# operationId: POST:/folders/single/comments
export def "folders-comments POST:/folders/single/comments" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # Comment text, can not be empty. Supported HTML tags can be found in <a href="https://developers.wrike.com/special-syntax">Special syntax</a>
  --plainText: oneof<nothing, bool> # Treat comment text as plain text, HTML otherwise (default: false)
]: nothing -> record<data: table<externalRequester: record, createdDate: string, id: string, text: string, updatedDate: string, authorId: string, type: string, emailSubject: string, taskId: string, folderId: string, direction: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "plainText" $plainText "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Comments (Task)
#
# GET /tasks/{taskId}/comments
# operationId: GET:/tasks/single/comments
export def "tasks-comments GET:/tasks/single/comments" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --types: string # Comment type filter * `Email` * `Regular`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `type` - Comment type
]: nothing -> record<data: table<externalRequester: record, createdDate: string, id: string, text: string, updatedDate: string, authorId: string, type: string, emailSubject: string, taskId: string, folderId: string, direction: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "plainText" $plainText "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Comment (Task)
#
# POST /tasks/{taskId}/comments
# operationId: POST:/tasks/single/comments
export def "tasks-comments POST:/tasks/single/comments" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # Comment text, can not be empty. Supported HTML tags can be found in <a href="https://developers.wrike.com/special-syntax">Special syntax</a>
  --plainText: oneof<nothing, bool> # Treat comment text as plain text, HTML otherwise (default: false)
]: nothing -> record<data: table<externalRequester: record, createdDate: string, id: string, text: string, updatedDate: string, authorId: string, type: string, emailSubject: string, taskId: string, folderId: string, direction: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "plainText" $plainText "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Comments By ID
#
# GET /comments/{commentIds}
# operationId: GET:/comments/multi
export def "comments GET:/comments/multi" [
  commentIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --types: string # Comment type filter * `Email` * `Regular`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `type` - Comment type
]: nothing -> record<data: table<externalRequester: record, createdDate: string, id: string, text: string, updatedDate: string, authorId: string, type: string, emailSubject: string, taskId: string, folderId: string, direction: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "plainText" $plainText "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/comments/($commentIds)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Comment
#
# PUT /comments/{commentId}
# operationId: PUT:/comments/single
export def "comments PUT:/comments/single" [
  commentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # Comment text, can not be empty. Supported HTML tags can be found in <a href="https://developers.wrike.com/special-syntax">Special syntax</a>
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
]: nothing -> record<data: table<externalRequester: record, createdDate: string, id: string, text: string, updatedDate: string, authorId: string, type: string, emailSubject: string, taskId: string, folderId: string, direction: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "plainText" $plainText "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/comments/($commentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Comment
#
# DELETE /comments/{commentId}
# operationId: DELETE:/comments/single
export def "comments DELETE:/comments/single" [
  commentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: list<string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Contacts
#
# GET /contacts
# operationId: GET:/contacts/empty
export def "contacts GET:/contacts/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --me: oneof<nothing, bool> # If present - only contact info of requesting user is returned
  --metadata: string # Metadata filter, exact match for metadata key or key-value pair
  --deleted: oneof<nothing, bool> # Deleted flag filter
  --customFields: string # Custom field filter
  --emails: string # Email contacts filter. Limit : `100`
  --active: oneof<nothing, bool> # Active status filter
  --name: string # Contact name filter
  --types: string # Contact type filter * `Group` - Group of users. Group userId can be used in folder/task sharing requests only. It has no effect in other operations * `Asset` - Asset * `Person` - Person * `Robot` - Robot user for automated operations
  --qp-fields: string # Json string array of optional fields to be included in the response model * `metadata` - Contact metadata * `currentCostRate` - Current user's cost rate * `customFields` - User's custom fields * `currentBillRate` - Current user's bill rate * `jobRoleId` - Current user's jobRoleId * `workScheduleId` - Contact work schedule id
]: nothing -> record<data: table<lastName: string, metadata: list, avatarUrl: string, timezone: string, currentCostRate: record, customFields: list, companyName: string, profiles: list, type: string, locale: string, title: string, firstName: string, deleted: bool, phone: string, currentBillRate: record, me: bool, myTeam: bool, jobRoleId: string, location: string, workScheduleId: string, id: string, memberIds: list, primaryEmail: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "me" $me "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "emails" $emails "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Contacts
#
# GET /contacts/{contactIds}
# operationId: GET:/contacts/multi
export def "contacts GET:/contacts/multi" [
  contactIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: string # Metadata filter, exact match for metadata key or key-value pair
  --types: string # Contact type filter * `Group` - Group of users. Group userId can be used in folder/task sharing requests only. It has no effect in other operations * `Asset` - Asset * `Person` - Person * `Robot` - Robot user for automated operations
  --qp-fields: string # Json string array of optional fields to be included in the response model * `metadata` - Contact metadata * `currentCostRate` - Current user's cost rate * `customFields` - User's custom fields * `currentBillRate` - Current user's bill rate * `jobRoleId` - Current user's jobRoleId * `workScheduleId` - Contact work schedule id
]: nothing -> record<data: table<lastName: string, metadata: list, avatarUrl: string, timezone: string, currentCostRate: record, customFields: list, companyName: string, profiles: list, type: string, locale: string, title: string, firstName: string, deleted: bool, phone: string, currentBillRate: record, me: bool, myTeam: bool, jobRoleId: string, location: string, workScheduleId: string, id: string, memberIds: list, primaryEmail: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata" $metadata "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/($contactIds)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Contacts fields history
#
# GET /contacts/{contactIds}/contacts_history
# operationId: GET:/contacts/multi/contacts_history
export def "contacts-contacts-history history" [
  contactIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updatedDate: string # Update date filter
  --qp-fields: string # Json string array of optional fields to be included in the response model * `billRate` - User's bill rate * `costRate` - User's cost rate
]: nothing -> record<data: table<costRateHistory: list, billRateHistory: list, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/($contactIds)/contacts_history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify Contact
#
# PUT /contacts/{contactId}
# operationId: PUT:/contacts/single
export def "contacts PUT:/contacts/single" [
  contactId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: string # Metadata to be updated. Requesting user has read/write access to his own metadata, other entries are read-only. Limit : `100`
  --currentBillRate: string # Update current user's bill rate
  --currentCostRate: string # Update current user's cost rate
  --jobRoleId: string # Update current user's job role id
  --customFields: string # Custom fields to be updated or deleted (null value removes field). Limit : `100`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `currentCostRate` - Current user's cost rate * `customFields` - User's custom fields * `currentBillRate` - Current user's bill rate * `jobRoleId` - Current user's job role id
]: nothing -> record<data: table<lastName: string, metadata: list, avatarUrl: string, timezone: string, currentCostRate: record, customFields: list, companyName: string, profiles: list, type: string, locale: string, title: string, firstName: string, deleted: bool, phone: string, currentBillRate: record, me: bool, myTeam: bool, jobRoleId: string, location: string, workScheduleId: string, id: string, memberIds: list, primaryEmail: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata" $metadata "scalar") (serialize-qp "currentBillRate" $currentBillRate "scalar") (serialize-qp "currentCostRate" $currentCostRate "scalar") (serialize-qp "jobRoleId" $jobRoleId "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/($contactId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy Work Schedule
#
# POST /workschedules/{workscheduleId}/duplicate
# operationId: POST:/workschedules/single/duplicate
export def "workschedules-duplicate POST:/workschedules/single/duplicate" [
  workscheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Name of work schedule
]: nothing -> record<data: table<scheduleType: string, workweek: list, userIds: list, id: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workschedules/($workscheduleId)/duplicate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Custom Fields (Account)
#
# GET /customfields
# operationId: GET:/customfields/empty
export def "customfields GET:/customfields/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicableEntityTypes: string # Applicable entity types * `User` * `WorkItem`
  --types: string # Custom field types * `Multiple` - Collection field * `Percentage` - Comparable field * `Text` - String field, Comparable field * `Duration` - Comparable field * `CalculatedNumeric` - Calculated comparable field * `Date` - Comparable field * `CalculatedDate` - Calculated comparable field * `Numeric` - Comparable field * `Contacts` - Collection field * `Checkbox` - Boolean field * `Currency` - Comparable field * `DropDown` - String field, Comparable field * `LinkToDatabase` - Link to database field
  --inheritanceTypes: string # Custom field inheritance types * `All` * `Tasks` * `Projects` * `Folders`
  --title: string # Custom field title
  --qp-fields: string # Json string array of optional fields to be included in the response model * `dataUsageStatistics` - Return collection of data usage statistics
]: nothing -> record<data: table<settings: record, archivedOn: string, sharedIds: list, description: string, title: string, type: string, sharing: record, dataUsageStatistics: record, accountId: string, spaceId: string, archived: bool, id: string, archivedBy: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicableEntityTypes" $applicableEntityTypes "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "inheritanceTypes" $inheritanceTypes "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customfields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Field (Account)
#
# POST /customfields
# operationId: POST:/customfields/empty
export def "customfields POST:/customfields/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Custom field title
  --type: string@type-completer-1 # Custom field type * `Multiple` - Collection field * `Percentage` - Comparable field * `Text` - String field, Comparable field * `Duration` - Comparable field * `CalculatedNumeric` - Calculated comparable field * `Date` - Comparable field * `CalculatedDate` - Calculated comparable field * `Numeric` - Comparable field * `Contacts` - Collection field * `Checkbox` - Boolean field * `Currency` - Comparable field * `DropDown` - String field, Comparable field * `LinkToDatabase` - Link to database field
  --spaceId: string # Custom field space ID
  --sharing: string # Custom field access settings
  --shareds: string # Users to share custom field with. Parameter is obsolete, use 'sharing' instead
  --settings: string # Custom field settings
  --description: string # Custom field description
]: nothing -> record<data: table<settings: record, archivedOn: string, sharedIds: list, description: string, title: string, type: string, sharing: record, dataUsageStatistics: record, accountId: string, spaceId: string, archived: bool, id: string, archivedBy: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "spaceId" $spaceId "scalar") (serialize-qp "sharing" $sharing "scalar") (serialize-qp "shareds" $shareds "scalar") (serialize-qp "settings" $settings "scalar") (serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customfields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Custom Fields By ID
#
# GET /customfields/{customfieldIds}
# operationId: GET:/customfields/multi
export def "customfields GET:/customfields/multi" [
  customfieldIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicableEntityTypes: string # Applicable entity types * `User` * `WorkItem`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `dataUsageStatistics` - Return collection of data usage statistics
]: nothing -> record<data: table<settings: record, archivedOn: string, sharedIds: list, description: string, title: string, type: string, sharing: record, dataUsageStatistics: record, accountId: string, spaceId: string, archived: bool, id: string, archivedBy: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicableEntityTypes" $applicableEntityTypes "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customfields/($customfieldIds)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Custom Fields (Space)
#
# GET /spaces/{spaceId}/customfields
# operationId: GET:/spaces/single/customfields
export def "spaces-customfields GET:/spaces/single/customfields" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicableEntityTypes: string # Applicable entity types * `User` * `WorkItem`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `dataUsageStatistics` - Return collection of data usage statistics
]: nothing -> record<data: table<settings: record, archivedOn: string, sharedIds: list, description: string, title: string, type: string, sharing: record, dataUsageStatistics: record, accountId: string, spaceId: string, archived: bool, id: string, archivedBy: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicableEntityTypes" $applicableEntityTypes "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/customfields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify Custom Field
#
# PUT /customfields/{customfieldId}
# operationId: PUT:/customfields/single
export def "customfields PUT:/customfields/single" [
  customfieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Custom field title
  --type: string@type-completer-1 # Custom field type. Conversion from any type of field to LinkToDatabase is not supported * `Multiple` - Collection field * `Percentage` - Comparable field * `Text` - String field, Comparable field * `Duration` - Comparable field * `CalculatedNumeric` - Calculated comparable field * `Date` - Comparable field * `CalculatedDate` - Calculated comparable field * `Numeric` - Comparable field * `Contacts` - Collection field * `Checkbox` - Boolean field * `Currency` - Comparable field * `DropDown` - String field, Comparable field * `LinkToDatabase` - Link to database field
  --changeScope: string@changeScope-completer # Custom field scope * `Space` - Use it with valid 'spaceId' parameter to move custom field to space level * `Account` - Use it with null 'spaceId' parameter to move custom field to account level
  --spaceId: string # Custom field space ID
  --sharing: string # Custom field access settings
  --addShareds: string # Share custom field with specified users. Parameter is obsolete, use 'sharing' instead
  --removeShareds: string # Unshare custom field from specified users. Parameter is obsolete, use 'sharing' instead
  --settings: string # Custom field type settings
  --addMirrors: string # Add mirror fields to LinkToDatabase field
  --removeMirrors: string # Remove mirror fields from to LinkToDatabase field
  --description: string # Custom field description
]: nothing -> record<data: table<settings: record, archivedOn: string, sharedIds: list, description: string, title: string, type: string, sharing: record, dataUsageStatistics: record, accountId: string, spaceId: string, archived: bool, id: string, archivedBy: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "changeScope" $changeScope "scalar") (serialize-qp "spaceId" $spaceId "scalar") (serialize-qp "sharing" $sharing "scalar") (serialize-qp "addShareds" $addShareds "scalar") (serialize-qp "removeShareds" $removeShareds "scalar") (serialize-qp "settings" $settings "scalar") (serialize-qp "addMirrors" $addMirrors "scalar") (serialize-qp "removeMirrors" $removeMirrors "scalar") (serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customfields/($customfieldId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query All Custom Item Types
#
# GET /custom_item_types
# operationId: GET:/custom_item_types/empty
export def "custom-item-types types/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Filter search results by title
  --limit: float # Result entries limit (default: 10000)
  --withDeleted: oneof<nothing, bool> # Include deleted custom item types in the result (default: false)
  --type: string@type-completer-2 # Related type of returned custom item types * `Project` - Project based * `Task` - Task based
  --qp-fields: string # Json string array of optional fields to be included in the response model * `dataUsageStatistics` - Return collection of data usage statistics
]: nothing -> record<data: table<spaceId: string, relatedType: string, customFieldIds: list, isDeleted: bool, archivedOn: string, icon: record, description: string, id: string, title: string, dataUsageStatistics: record, archivedBy: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "withDeleted" $withDeleted "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_item_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query All Custom Item Types
#
# GET /spaces/{spaceId}/custom_item_types
# operationId: GET:/spaces/single/custom_item_types
export def "spaces-custom-item-types types" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Filter search results by title
  --limit: float # Result entries limit (default: 10000)
  --withDeleted: oneof<nothing, bool> # Include deleted custom item types in the result (default: false)
  --type: string@type-completer-2 # Related type of returned custom item types * `Project` - Project based * `Task` - Task based
  --qp-fields: string # Json string array of optional fields to be included in the response model * `dataUsageStatistics` - Return collection of data usage statistics
]: nothing -> record<data: table<spaceId: string, relatedType: string, customFieldIds: list, isDeleted: bool, archivedOn: string, icon: record, description: string, id: string, title: string, dataUsageStatistics: record, archivedBy: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "withDeleted" $withDeleted "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/custom_item_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Specific Custom Item Type by ID
#
# GET /custom_item_types/{customItemTypeIds}
# operationId: GET:/custom_item_types/multi
export def "custom-item-types types/multi" [
  customItemTypeIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withDeleted: oneof<nothing, bool> # Include deleted custom item types in the result (default: false)
  --qp-fields: string # Json string array of optional fields to be included in the response model * `dataUsageStatistics` - Return collection of data usage statistics
]: nothing -> record<data: table<spaceId: string, relatedType: string, customFieldIds: list, isDeleted: bool, archivedOn: string, icon: record, description: string, id: string, title: string, dataUsageStatistics: record, archivedBy: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withDeleted" $withDeleted "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_item_types/($customItemTypeIds)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Work from Custom Item Type
#
# POST /custom_item_types/{customItemTypeId}/instantiate
# operationId: POST:/custom_item_types/single/instantiate
export def "custom-item-types-instantiate types/single/instantiate" [
  customItemTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --superTaskId: string # ID of parent task. Set this to add work from the task-based custom item type as a subtask. Either this parameter or parentId  is required. parentId and superTaskId cannot be set simultaneously.
  --parentId: string # ID of parent folder or project.  Set this to put work from the custom item type to the specific folder or project. Either this parameter or superTaskId  is required. parentId and superTaskId cannot be set simultaneously
  --title: string # Title
]: nothing -> record<data: table<relatedType: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "superTaskId" $superTaskId "scalar") (serialize-qp "parentId" $parentId "scalar") (serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_item_types/($customItemTypeId)/instantiate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Data Export
#
# GET /data_export
# operationId: GET:/data_export/empty
export def "data-export export/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<resources: list, id: string, completedDate: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data_export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh Data Export
#
# POST /data_export
# operationId: POST:/data_export/empty
export def "data-export export/empty-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<resources: list, id: string, completedDate: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data_export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Data Export
#
# GET /data_export/{dataExportId}
# operationId: GET:/data_export/single
export def "data-export export/single" [
  dataExportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<resources: list, id: string, completedDate: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data_export/($dataExportId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Data Export Schema
#
# GET /data_export_schema
# operationId: GET:/data_export_schema/empty
export def "data-export-schema schema/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string@version-completer # Version * `V0` * `V1` * `V2` * `V3` * `V4`
]: nothing -> record<data: table<columns: list, alias: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data_export_schema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Dependencies (Task)
#
# GET /tasks/{taskId}/dependencies
# operationId: GET:/tasks/single/dependencies
export def "tasks-dependencies GET:/tasks/single/dependencies" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<relationType: string, successorId: string, lagTime: float, id: string, predecessorId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)/dependencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Dependency
#
# POST /tasks/{taskId}/dependencies
# operationId: POST:/tasks/single/dependencies
export def "tasks-dependencies POST:/tasks/single/dependencies" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --predecessorId: string # Add predecessor task, only one of predecessorId/successorId fields can be specified
  --successorId: string # Add successor task, only one of predecessorId/successorId fields can be specified
  --relationType: string@relationType-completer # Relation between Predecessor and Successor * `FinishToFinish` - Finish to finish. Allowed only when predecessor and successor are Planned or Milestone tasks * `StartToStart` - Start to start. Allowed only when both predecessor and successor are Planned tasks * `StartToFinish` - Start to finish. Allowed only when predecessor is Planned, and successor is Planned or Milestone task * `FinishToStart` - Finish to start. Allowed only when predecessor is Planned or Milestone, and successor is Planned task
  --lagTime: float # Always in minutes, positive numbers are lag time and negative numbers are lead time (default: 0)
]: nothing -> record<data: table<relationType: string, successorId: string, lagTime: float, id: string, predecessorId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "predecessorId" $predecessorId "scalar") (serialize-qp "successorId" $successorId "scalar") (serialize-qp "relationType" $relationType "scalar") (serialize-qp "lagTime" $lagTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/dependencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Dependencies By ID
#
# GET /dependencies/{dependencyIds}
# operationId: GET:/dependencies/multi
export def "dependencies GET:/dependencies/multi" [
  dependencyIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<relationType: string, successorId: string, lagTime: float, id: string, predecessorId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dependencies/($dependencyIds)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify Dependency
#
# PUT /dependencies/{dependencyId}
# operationId: PUT:/dependencies/single
export def "dependencies PUT:/dependencies/single" [
  dependencyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --relationType: string@relationType-completer # Relation between Predecessor and Successor * `FinishToFinish` - Finish to finish. Allowed only when predecessor and successor are Planned or Milestone tasks * `StartToStart` - Start to start. Allowed only when both predecessor and successor are Planned tasks * `StartToFinish` - Start to finish. Allowed only when predecessor is Planned, and successor is Planned or Milestone task * `FinishToStart` - Finish to start. Allowed only when predecessor is Planned or Milestone, and successor is Planned task
  --lagTime: float # Always in minutes, positive numbers are lag time and negative numbers are lead time
]: nothing -> record<data: table<relationType: string, successorId: string, lagTime: float, id: string, predecessorId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "relationType" $relationType "scalar") (serialize-qp "lagTime" $lagTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dependencies/($dependencyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Dependency
#
# DELETE /dependencies/{dependencyId}
# operationId: DELETE:/dependencies/single
export def "dependencies DELETE:/dependencies/single" [
  dependencyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<relationType: string, successorId: string, lagTime: float, id: string, predecessorId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dependencies/($dependencyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# eDiscovery Search
#
# POST /ediscovery_search
# operationId: POST:/ediscovery_search/empty
export def "ediscovery-search search/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scopes: string # Scopes to limit the result. Limit : `1000` * `task` * `folder` * `attachment` * `project` * `space`
  --terms: string # Terms to search
  --targetUserId: string # User id to limit the result
  --timeout: string # Maximum approximate duration to handle requests
]: nothing -> record<data: list<string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopes" $scopes "scalar") (serialize-qp "terms" $terms "scalar") (serialize-qp "targetUserId" $targetUserId "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ediscovery_search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Folder Blueprints (Account)
#
# GET /folder_blueprints
# operationId: GET:/folder_blueprints/empty
export def "folder-blueprints blueprints/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permalink: string # Folder permalink, exact match
  --title: string # Title search
  --customFields: string # Custom field filters, exact match. Limit : `25`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `customFields` - Custom Fields
]: nothing -> record<data: table<childIds: list, customFields: list, scope: string, id: string, permalink: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permalink" $permalink "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/folder_blueprints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Folder Blueprints (Space)
#
# GET /spaces/{spaceId}/folder_blueprints
# operationId: GET:/spaces/single/folder_blueprints
export def "spaces-folder-blueprints blueprints" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permalink: string # Folder permalink, exact match
  --qp-fields: string # Json string array of optional fields to be included in the response model * `customFields` - Custom Fields
]: nothing -> record<data: table<childIds: list, customFields: list, scope: string, id: string, permalink: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permalink" $permalink "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folder_blueprints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Async Work Creation
#
# POST /folder_blueprints/{folderBlueprintId}/launch_async
# operationId: POST:/folder_blueprints/single/launch_async
export def "folder-blueprints-launch-async async" [
  folderBlueprintId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent: string # ID of parent folder
  --title: string # Title (required)
  --titlePrefix: string # Title prefix for all copied tasks
  --copyDescriptions: oneof<nothing, bool> # Copy descriptions or leave empty (default: true)
  --notifyResponsibles: oneof<nothing, bool> # Notify those responsible (default: true)
  --copyResponsibles: oneof<nothing, bool> # Copy those responsible (default: true)
  --copyCustomFields: oneof<nothing, bool> # Copy custom fields (default: true)
  --copyAttachments: oneof<nothing, bool> # Copy attachments (default: false)
  --rescheduleDate: string # Date to use in task rescheduling. Note: Only active tasks can be rescheduled. Format: yyyy-MM-dd Format: yyyy-MM-dd
  --rescheduleMode: string@rescheduleMode-completer # Mode to be used for rescheduling (based on first or last date). Used only if reschedule date is specified. * `Start` - Tasks in scope are rescheduled starting from reschedule date * `End` - Tasks in scope are rescheduled ending with reschedule date
  --entryLimit: float # Maximum number of tasks/folders in tree for copy. The operation will fail if limit is exceeded. This should be 1..250 (default: 250)
]: nothing -> record<data: table<result: record, processedCount: float, errorMessage: string, progressPercent: float, id: string, totalCount: float, type: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "titlePrefix" $titlePrefix "scalar") (serialize-qp "copyDescriptions" $copyDescriptions "scalar") (serialize-qp "notifyResponsibles" $notifyResponsibles "scalar") (serialize-qp "copyResponsibles" $copyResponsibles "scalar") (serialize-qp "copyCustomFields" $copyCustomFields "scalar") (serialize-qp "copyAttachments" $copyAttachments "scalar") (serialize-qp "rescheduleDate" $rescheduleDate "scalar") (serialize-qp "rescheduleMode" $rescheduleMode "scalar") (serialize-qp "entryLimit" $entryLimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folder_blueprints/($folderBlueprintId)/launch_async" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Folders (Account)
#
# GET /folders
# operationId: GET:/folders/empty
export def "folders GET:/folders/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permalink: string # Folder permalink, exact match
  --descendants: oneof<nothing, bool> # Adds all descendant folders to search scope (default: true)
  --metadata: string # Folders metadata filter
  --customField: string # [Deprecated] It is recommended to use 'customFields' parameter. Custom field filter
  --customFields: string # Custom field filters, exact match. Limit : `25`
  --updatedDate: string # Updated date filter, range
  --withInvitations: oneof<nothing, bool> # Include invitations in sharedIds list
  --project: oneof<nothing, bool> # Filter only projects (true) / only folders (false)
  --deleted: oneof<nothing, bool> # Get folders from Root (false) / Recycle Bin (true). This parameter does not affect method's mode.
  --contractTypes: string # Contract type filter * `Billable` - Billable * `NonBillable` - Non-Billable
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --customItemTypes: string # Custom item types filter. Standard types (project, folder) IDs are not allowed. Limit : `1000`
  --pageSize: float # The number of folders to return (max 1000 items per page). Only 'folders' kind is supported
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case. If you included optional fields to the first request, you will need to include those in each new call. Only 'folders' kind is supported
  --customStatuses: string # Custom statuses filter
  --authors: string # Authors filter, match of any
  --owners: string # Assignees filter with specified users, match of any
  --startDate: string # Start date filter, date match or range
  --endDate: string # End date filter, date match or range
  --completedDate: string # Completed date filter, date match or range
  --title: string # Title filter, contains match and accepts non-blank values only
  --qp-fields: string # Json string array of optional fields to be included in the response model * `superParentIds` - List of super parent folder IDs (applicable to 'Selective Sharing' labs feature) * `metadata` - Folder metadata entries * `customItemTypeId` - Work Item custom item type Id * `customFields` - Custom fields * `customColumnIds` - Associated custom field IDs * `contractType` - Contract type * `description` - Description * `attachmentCount` - Attachment count * `hasAttachments` - Has attachments * `briefDescription` - Brief description * `space` - Is folder a space
]: nothing -> record<data: table<color: string, customItemTypeId: string, childIds: list, scope: string, project: record, id: string, title: string, space: bool>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permalink" $permalink "scalar") (serialize-qp "descendants" $descendants "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "customField" $customField "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "contractTypes" $contractTypes "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "customItemTypes" $customItemTypes "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "customStatuses" $customStatuses "scalar") (serialize-qp "authors" $authors "scalar") (serialize-qp "owners" $owners "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "completedDate" $completedDate "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Folders (Folder)
#
# GET /folders/{folderId}/folders
# operationId: GET:/folders/single/folders
export def "folders-folders GET:/folders/single/folders" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permalink: string # Folder permalink, exact match
  --descendants: oneof<nothing, bool> # Adds all descendant folders to search scope (default: true)
  --metadata: string # Folders metadata filter
  --customField: string # [Deprecated] It is recommended to use 'customFields' parameter. Custom field filter
  --customFields: string # Custom field filters, exact match. Limit : `25`
  --updatedDate: string # Updated date filter, range
  --withInvitations: oneof<nothing, bool> # Include invitations in sharedIds list
  --project: oneof<nothing, bool> # Filter only projects (true) / only folders (false)
  --contractTypes: string # Contract type filter * `Billable` - Billable * `NonBillable` - Non-Billable
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --customItemTypes: string # Custom item types filter. Standard types (project, folder) IDs are not allowed. Limit : `1000`
  --pageSize: float # The number of folders to return (max 1000 items per page). Only 'folders' kind is supported
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case. If you included optional fields to the first request, you will need to include those in each new call. Only 'folders' kind is supported
  --customStatuses: string # Custom statuses filter
  --authors: string # Authors filter, match of any
  --owners: string # Assignees filter with specified users, match of any
  --startDate: string # Start date filter, date match or range
  --endDate: string # End date filter, date match or range
  --completedDate: string # Completed date filter, date match or range
  --title: string # Title filter, contains match and accepts non-blank values only
  --qp-fields: string # Json string array of optional fields to be included in the response model * `superParentIds` - List of super parent folder IDs (applicable to 'Selective Sharing' labs feature) * `metadata` - Folder metadata entries * `customItemTypeId` - Work Item custom item type Id * `customFields` - Custom fields * `customColumnIds` - Associated custom field IDs * `contractType` - Contract type * `description` - Description * `attachmentCount` - Attachment count * `hasAttachments` - Has attachments * `briefDescription` - Brief description * `space` - Is folder a space * `finance` - Project Finance fields
]: nothing -> record<data: table<color: string, customItemTypeId: string, childIds: list, scope: string, project: record, id: string, title: string, space: bool>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permalink" $permalink "scalar") (serialize-qp "descendants" $descendants "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "customField" $customField "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "contractTypes" $contractTypes "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "customItemTypes" $customItemTypes "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "customStatuses" $customStatuses "scalar") (serialize-qp "authors" $authors "scalar") (serialize-qp "owners" $owners "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "completedDate" $completedDate "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Folder
#
# POST /folders/{folderId}/folders
# operationId: POST:/folders/single/folders
export def "folders-folders POST:/folders/single/folders" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title, cannot be empty
  --description: string # Folder description. If not specified, will be left blank
  --shareds: string # Users or invited users to share folder with. Folder is always shared with creator
  --metadata: string # Metadata to be added to newly created folder. Limit : `100`
  --customFields: string # List of custom fields to be set upon task creation. Limit : `100`
  --customColumns: string # List of custom fields associated with folder
  --project: string # Project settings in order to create project
  --userAccessRoles: string # Access Roles assigned to users with which folder will be shared
  --withInvitations: oneof<nothing, bool> # Include invitations in ownerIds & sharedIds list
  --customItemTypeId: string # Custom Item Type ID to create a project from
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --qp-fields: string # Json string array of optional fields to be included in the response model * `customItemTypeId` - Custom Item Type ID * `contractType` - Contract type
]: nothing -> record<data: table<color: string, customItemTypeId: string, childIds: list, scope: string, project: record, id: string, title: string, space: bool>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "shareds" $shareds "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "customColumns" $customColumns "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "userAccessRoles" $userAccessRoles "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "customItemTypeId" $customItemTypeId "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Folders (Space)
#
# GET /spaces/{spaceId}/folders
# operationId: GET:/spaces/single/folders
export def "spaces-folders GET:/spaces/single/folders" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permalink: string # Folder permalink, exact match
  --descendants: oneof<nothing, bool> # Adds all descendant folders to search scope (default: true)
  --metadata: string # Folders metadata filter
  --customField: string # [Deprecated] It is recommended to use 'customFields' parameter. Custom field filter
  --customFields: string # Custom field filters, exact match. Limit : `25`
  --updatedDate: string # Updated date filter, range
  --withInvitations: oneof<nothing, bool> # Include invitations in sharedIds list
  --project: oneof<nothing, bool> # Filter only projects (true) / only folders (false)
  --deleted: oneof<nothing, bool> # Get folders from Root (false) / Recycle Bin (true). This parameter does not affect method's mode.
  --contractTypes: string # Contract type filter * `Billable` - Billable * `NonBillable` - Non-Billable
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --customItemTypes: string # Custom item types filter. Standard types (project, folder) IDs are not allowed. Limit : `1000`
  --pageSize: float # The number of folders to return (max 1000 items per page). Only 'folders' kind is supported
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case. If you included optional fields to the first request, you will need to include those in each new call. Only 'folders' kind is supported
  --customStatuses: string # Custom statuses filter
  --authors: string # Authors filter, match of any
  --owners: string # Assignees filter with specified users, match of any
  --startDate: string # Start date filter, date match or range
  --endDate: string # End date filter, date match or range
  --completedDate: string # Completed date filter, date match or range
  --title: string # Title filter, contains match and accepts non-blank values only
  --qp-fields: string # Json string array of optional fields to be included in the response model * `superParentIds` - List of super parent folder IDs (applicable to 'Selective Sharing' labs feature) * `metadata` - Folder metadata entries * `customItemTypeId` - Work Item custom item type Id * `customFields` - Custom fields * `customColumnIds` - Associated custom field IDs * `contractType` - Contract type * `description` - Description * `attachmentCount` - Attachment count * `hasAttachments` - Has attachments * `briefDescription` - Brief description * `space` - Is folder a space
]: nothing -> record<data: table<color: string, customItemTypeId: string, childIds: list, scope: string, project: record, id: string, title: string, space: bool>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permalink" $permalink "scalar") (serialize-qp "descendants" $descendants "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "customField" $customField "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "contractTypes" $contractTypes "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "customItemTypes" $customItemTypes "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "customStatuses" $customStatuses "scalar") (serialize-qp "authors" $authors "scalar") (serialize-qp "owners" $owners "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "completedDate" $completedDate "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Folders fields history
#
# GET /folders/{folderIds}/folders_history
# operationId: GET:/folders/multi/folders_history
export def "folders-folders-history history" [
  folderIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updatedDate: string # Update date filter
  --qp-fields: string # Json string array of optional fields to be included in the response model * `plannedCost` - Planned cost change history * `plannedFees` - Planned fees change history * `actualFees` - Actual fees change history * `actualCost` - Actual cost change history * `budget` - Budget change history
]: nothing -> record<data: table<project: record, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderIds)/folders_history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Folder By ID
#
# GET /folders/{folderIds}
# operationId: GET:/folders/multi
export def "folders GET:/folders/multi" [
  folderIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withInvitations: oneof<nothing, bool> # Include invitations in sharedIds list
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --qp-fields: string # Json string array of optional fields to be included in the response model * `cascadingFields` - Active cascading fields settings * `accessRoles` - Folder Access Roles * `customItemTypeId` - Work Item custom item type Id * `customColumnIds` - Associated custom field IDs * `contractType` - Contract type * `attachmentCount` - Attachment count * `briefDescription` - Get brief description * `finance` - Project Finance fields
]: nothing -> record<data: table<color: string, customItemTypeId: string, childIds: list, scope: string, project: record, id: string, title: string, space: bool>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderIds)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Folders (Bulk)
#
# PUT /folders/{folderIds}
# operationId: PUT:/folders/multi
export def "folders PUT:/folders/multi" [
  folderIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --customFields: string # Custom fields to be updated or deleted (null value removes field). Limit : `100`
  --convertToCustomItemType: string # Custom Item Type id
  --project: string # Project settings (update project or convert folder to project). Use null value to convert project to folder
  --qp-fields: string # Json string array of optional fields to be included in the response model * `contractType` - Contract type
]: nothing -> record<data: table<color: string, customItemTypeId: string, childIds: list, scope: string, project: record, id: string, title: string, space: bool>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customFields" $customFields "scalar") (serialize-qp "convertToCustomItemType" $convertToCustomItemType "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderIds)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy Folder
#
# POST /copy_folder/{folderId}
# operationId: POST:/copy_folder/single
export def "copy-folder folder/single" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent: string # ID of parent folder
  --title: string # Title, cannot be empty
  --titlePrefix: string # Title prefix for all copied tasks
  --copyDescriptions: oneof<nothing, bool> # Copy descriptions or leave empty (default: true)
  --copyResponsibles: oneof<nothing, bool> # Copy responsibles (default: true)
  --addResponsibles: string # Add specified users to task responsible list
  --removeResponsibles: string # Remove specified users from task responsible list
  --copyCustomFields: oneof<nothing, bool> # Copy custom fields (default: true)
  --copyCustomStatuses: oneof<nothing, bool> # Copy custom statuses or set according to workflow otherwise (default: true)
  --copyStatuses: oneof<nothing, bool> # Copy task statuses or set to Active otherwise (default: true)
  --copyParents: oneof<nothing, bool> # Preserve parent folders (default: false)
  --rescheduleDate: string # Date to use in task rescheduling. Note that only active tasks can be rescheduled. To activate and reschedule all tasks, use 'rescheduleDate' in combination with copyStatuses = false Format: yyyy-MM-dd
  --rescheduleMode: string@rescheduleMode-completer # Mode to be used for rescheduling (based on first or last date), has effect only if reschedule date is specified. * `Start` - Tasks in scope are rescheduled starting from reschedule date * `End` - Tasks in scope are rescheduled ending with reschedule date
  --entryLimit: float # Limit maximum allowed number for tasks/folders in tree for copy, operation will fail if limit is exceeded, should be 1..250 (default: 250)
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
]: nothing -> record<data: table<color: string, customItemTypeId: string, childIds: list, scope: string, project: record, id: string, title: string, space: bool>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "titlePrefix" $titlePrefix "scalar") (serialize-qp "copyDescriptions" $copyDescriptions "scalar") (serialize-qp "copyResponsibles" $copyResponsibles "scalar") (serialize-qp "addResponsibles" $addResponsibles "scalar") (serialize-qp "removeResponsibles" $removeResponsibles "scalar") (serialize-qp "copyCustomFields" $copyCustomFields "scalar") (serialize-qp "copyCustomStatuses" $copyCustomStatuses "scalar") (serialize-qp "copyStatuses" $copyStatuses "scalar") (serialize-qp "copyParents" $copyParents "scalar") (serialize-qp "rescheduleDate" $rescheduleDate "scalar") (serialize-qp "rescheduleMode" $rescheduleMode "scalar") (serialize-qp "entryLimit" $entryLimit "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/copy_folder/($folderId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy Folder async
#
# POST /copy_folder_async/{folderId}
# operationId: POST:/copy_folder_async/single
export def "copy-folder-async async/single" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent: string # ID of parent folder
  --title: string # Title, cannot be empty
  --titlePrefix: string # Title prefix for all copied tasks
  --copyDescriptions: oneof<nothing, bool> # Copy descriptions or leave empty (default: true)
  --copyResponsibles: oneof<nothing, bool> # Copy responsibles (default: true)
  --addResponsibles: string # Add specified users to task responsible list
  --removeResponsibles: string # Remove specified users from task responsible list
  --copyCustomFields: oneof<nothing, bool> # Copy custom fields (default: true)
  --copyCustomStatuses: oneof<nothing, bool> # Copy custom statuses or set according to workflow otherwise (default: true)
  --copyStatuses: oneof<nothing, bool> # Copy task statuses or set to Active otherwise (default: true)
  --copyParents: oneof<nothing, bool> # Preserve parent folders (default: false)
  --rescheduleDate: string # Date to use in task rescheduling. Note that only active tasks can be rescheduled. To activate and reschedule all tasks, use 'rescheduleDate' in combination with copyStatuses = false Format: yyyy-MM-dd
  --rescheduleMode: string@rescheduleMode-completer # Mode to be used for rescheduling (based on first or last date), has effect only if reschedule date is specified. * `Start` - Tasks in scope are rescheduled starting from reschedule date * `End` - Tasks in scope are rescheduled ending with reschedule date
  --entryLimit: float # Limit maximum allowed number for tasks/folders in tree for copy, operation will fail if limit is exceeded, should be 1..250 (default: 250)
]: nothing -> record<data: table<result: record, processedCount: float, errorMessage: string, progressPercent: float, id: string, totalCount: float, type: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "titlePrefix" $titlePrefix "scalar") (serialize-qp "copyDescriptions" $copyDescriptions "scalar") (serialize-qp "copyResponsibles" $copyResponsibles "scalar") (serialize-qp "addResponsibles" $addResponsibles "scalar") (serialize-qp "removeResponsibles" $removeResponsibles "scalar") (serialize-qp "copyCustomFields" $copyCustomFields "scalar") (serialize-qp "copyCustomStatuses" $copyCustomStatuses "scalar") (serialize-qp "copyStatuses" $copyStatuses "scalar") (serialize-qp "copyParents" $copyParents "scalar") (serialize-qp "rescheduleDate" $rescheduleDate "scalar") (serialize-qp "rescheduleMode" $rescheduleMode "scalar") (serialize-qp "entryLimit" $entryLimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/copy_folder_async/($folderId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Folder
#
# PUT /folders/{folderId}
# operationId: PUT:/folders/single
export def "folders PUT:/folders/single" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title
  --description: string # Folder description
  --addParents: string # Parent folders from same account to add, cannot contain rootFolderId and recycleBinId
  --removeParents: string # Parent folders from same account to remove, cannot contain rootFolderId and recycleBinId
  --addShareds: string # Share folder with specified users or invitations
  --removeShareds: string # Unshare folder from specified users or invitations
  --metadata: string # Metadata to be updated. Limit : `100`
  --restore: oneof<nothing, bool> # Restore folder from Recycled Bin
  --customFields: string # Custom fields to be updated or deleted (null value removes field). Limit : `100`
  --customColumns: string # List of custom fields associated with folder
  --clearCustomColumns: oneof<nothing, bool> # Remove all custom fields associated with folder
  --project: string # Project settings (update project or convert folder to project). Use null value to convert project to folder
  --addAccessRoles: string # Specifies users with Access Roles for folder
  --removeAccessRoles: string # Specifies users whose Access Roles should be removed
  --withInvitations: oneof<nothing, bool> # Include invitations in ownerIds & sharedIds list
  --convertToCustomItemType: string # Custom Item Type id
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --qp-fields: string # Json string array of optional fields to be included in the response model * `contractType` - Contract type
]: nothing -> record<data: table<color: string, customItemTypeId: string, childIds: list, scope: string, project: record, id: string, title: string, space: bool>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "addParents" $addParents "scalar") (serialize-qp "removeParents" $removeParents "scalar") (serialize-qp "addShareds" $addShareds "scalar") (serialize-qp "removeShareds" $removeShareds "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "restore" $restore "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "customColumns" $customColumns "scalar") (serialize-qp "clearCustomColumns" $clearCustomColumns "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "addAccessRoles" $addAccessRoles "scalar") (serialize-qp "removeAccessRoles" $removeAccessRoles "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "convertToCustomItemType" $convertToCustomItemType "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Folder
#
# DELETE /folders/{folderId}
# operationId: DELETE:/folders/single
export def "folders DELETE:/folders/single" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<color: string, customItemTypeId: string, childIds: list, scope: string, project: record, id: string, title: string, space: bool>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Groups
#
# GET /groups/{groupId}
# operationId: GET:/groups/single
export def "groups GET:/groups/single" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Json string array of optional fields to be included in the response model * `metadata` - Group metadata entries
]: nothing -> record<data: table<accountId: string, metadata: list, childIds: list, avatarUrl: string, parentIds: list, myTeam: bool, id: string, title: string, memberIds: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($groupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify Groups
#
# PUT /groups/{groupId}
# operationId: PUT:/groups/single
export def "groups PUT:/groups/single" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title of group
  --addMembers: string # Add specified users to group
  --removeMembers: string # Remove specified users from group
  --addInvitations: string # Add specified invitations to group
  --removeInvitations: string # Remove specified invitations from group
  --parent: string # Parent group
  --avatar: string # Info for group avatar creation
  --metadata: string # Metadata to be updated. Limit : `100`
]: nothing -> record<data: table<accountId: string, metadata: list, childIds: list, avatarUrl: string, parentIds: list, myTeam: bool, id: string, title: string, memberIds: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "addMembers" $addMembers "scalar") (serialize-qp "removeMembers" $removeMembers "scalar") (serialize-qp "addInvitations" $addInvitations "scalar") (serialize-qp "removeInvitations" $removeInvitations "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "avatar" $avatar "scalar") (serialize-qp "metadata" $metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($groupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Groups
#
# DELETE /groups/{groupId}
# operationId: DELETE:/groups/single
export def "groups DELETE:/groups/single" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --test: oneof<nothing, bool> # Check that group can be removed
]: nothing -> record<data: table<accountId: string, metadata: list, childIds: list, avatarUrl: string, parentIds: list, myTeam: bool, id: string, title: string, memberIds: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "test" $test "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($groupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Groups
#
# GET /groups
# operationId: GET:/groups/empty
export def "groups GET:/groups/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: string # Metadata filter, exact match for metadata key or key-value pair
  --pageSize: float # Page size
  --pageToken: string # Page token, overrides any other parameters in request
  --qp-fields: string # Json string array of optional fields to be included in the response model * `metadata` - Group metadata
]: nothing -> record<data: table<accountId: string, metadata: list, childIds: list, avatarUrl: string, parentIds: list, myTeam: bool, id: string, title: string, memberIds: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata" $metadata "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Groups
#
# POST /groups
# operationId: POST:/groups/empty
export def "groups POST:/groups/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title of group, required
  --members: string # Group users
  --parent: string # Parent group
  --avatar: string # Info for group avatar creation
  --metadata: string # Metadata to be added to newly created group. Limit : `100`
]: nothing -> record<data: table<accountId: string, metadata: list, childIds: list, avatarUrl: string, parentIds: list, myTeam: bool, id: string, title: string, memberIds: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "avatar" $avatar "scalar") (serialize-qp "metadata" $metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk modify groups
#
# PUT /groups_bulk
# operationId: PUT:/groups_bulk/empty
export def "groups-bulk bulk/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --members: string # Update group members. Limit 20. Limit : `20`
]: nothing -> record<data: table<accountId: string, metadata: list, childIds: list, avatarUrl: string, parentIds: list, myTeam: bool, id: string, title: string, memberIds: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "members" $members "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups_bulk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Budget Rates (Contacts)
#
# GET /contacts/{contactIds}/hourly_rates
# operationId: GET:/contacts/multi/hourly_rates
export def "contacts-hourly-rates rates" [
  contactIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<billRate: record, costRate: record, rateSubjectId: string, rateSubjectType: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contactIds)/hourly_rates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Budget Rates (Folder)
#
# GET /folders/{folderId}/hourly_rates
# operationId: GET:/folders/single/hourly_rates
export def "folders-hourly-rates rates-by-folderId" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<billRate: record, costRate: record, rateSubjectId: string, rateSubjectType: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folderId)/hourly_rates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Budget Rates (Folder)
#
# PUT /folders/{folderId}/hourly_rates
# operationId: PUT:/folders/single/hourly_rates
export def "folders-hourly-rates rates-by-folderId-1" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rates: string # Provision hourly rates to users. Max 100 users per request. Limit : `100`
  --enableCalculations: oneof<nothing, bool> # Trigger rates recalculation
]: nothing -> record<data: table<billRate: record, costRate: record, rateSubjectId: string, rateSubjectType: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rates" $rates "scalar") (serialize-qp "enableCalculations" $enableCalculations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/hourly_rates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Budget Rates (Placeholders)
#
# GET /placeholders/{placeholderIds}/hourly_rates
# operationId: GET:/placeholders/multi/hourly_rates
export def "placeholders-hourly-rates rates" [
  placeholderIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<billRate: record, costRate: record, rateSubjectId: string, rateSubjectType: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/placeholders/($placeholderIds)/hourly_rates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Budget Rates (Account)
#
# PUT /hourly_rates
# operationId: PUT:/hourly_rates/empty
export def "hourly-rates rates/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rates: string # Provision hourly rates to users. Max 100 users per request. Limit : `100`
]: nothing -> record<data: table<billRate: record, costRate: record, rateSubjectId: string, rateSubjectType: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rates" $rates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hourly_rates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exclude team members
#
# DELETE /folders/{folderId}/project_team_members
# operationId: DELETE:/folders/single/project_team_members
export def "folders-project-team-members members" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rateSubjects: string # Project team members to remove. Max 100 per request. Limit : `100`
]: nothing -> record<data: list<string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rateSubjects" $rateSubjects "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/project_team_members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provision
#
# PUT /contacts/{contactIds}/hourly_rates_provision
# operationId: PUT:/contacts/multi/hourly_rates_provision
export def "contacts-hourly-rates-provision provision" [
  contactIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userRates: string # Provision hourly rates to users. Max 100 users per request. Limit : `100`
]: nothing -> record<data: table<rateValue: float, rateType: string, contact: string, rateSource: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userRates" $userRates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/($contactIds)/hourly_rates_provision" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Legacy API v2 IDs converter
#
# GET /ids
# operationId: GET:/ids/empty
export def "ids GET:/ids/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-3 # Entity type * `ApiV2Task` - API v2 task * `ApiV2Attachment` - API v2 attachment * `ApiV2Comment` - API v2 comment * `ApiV2Folder` - API v2 folder * `ApiV2Timelog` - API v2 timelog entry * `ApiV2User` - API v2 user or group * `ApiV2Account` - API v2 account * `ApiV2RequestForm` - API v2 request form
  --ids: string # List of APIv2 legacy IDs. Limit : `1000`
]: nothing -> record<data: table<id: string, apiV2Id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Invitations
#
# GET /invitations
# operationId: GET:/invitations/empty
export def "invitations GET:/invitations/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<userTypeId: string, accountId: string, firstName: string, lastName: string, external: bool, inviterUserId: string, role: string, id: string, email: string, status: string, invitationDate: string, resolvedDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invitations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Invitation
#
# POST /invitations
# operationId: POST:/invitations/empty
export def "invitations POST:/invitations/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Create an invitation for current email
  --firstName: string # First name of invited user
  --lastName: string # Last name of invited user
  --role: string@role-completer # [Deprecated] It is recommended to use 'userTypeId' parameter instead. Set user role in account. Mutually exclusive with userTypeId param * `User` * `Collaborator`
  --external: oneof<nothing, bool> # [Deprecated] It is recommended to use 'userTypeId' parameter instead. Set external flag for invited user. Flag 'External' can be applied only to the role 'User'. Mutually exclusive with userTypeId param (default: false)
  --subject: string # Custom message subject. Not available for free accounts
  --message: string # Custom message body. Not available for free accounts
  --userTypeId: string # Set user type in account. Mutually exclusive with role and external params
]: nothing -> record<data: table<userTypeId: string, accountId: string, firstName: string, lastName: string, external: bool, inviterUserId: string, role: string, id: string, email: string, status: string, invitationDate: string, resolvedDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "firstName" $firstName "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "external" $external "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "userTypeId" $userTypeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Invitation
#
# PUT /invitations/{invitationId}
# operationId: PUT:/invitations/single
export def "invitations PUT:/invitations/single" [
  invitationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resend: oneof<nothing, bool> # Resend invitation
  --role: string@role-completer # [Deprecated] It is recommended to use 'userTypeId' parameter instead. Change role of user in account for pending invitation. Mutually exclusive with userTypeId param.  * `User` * `Collaborator`
  --external: oneof<nothing, bool> # [Deprecated] It is recommended to use 'userTypeId' parameter instead. Change external flag for pending invitation. Flag 'External' can be applied only to the role 'User'. Mutually exclusive with userTypeId param
  --userTypeId: string # Change user type of user in account for pending invitation. Mutually exclusive with role and external params
]: nothing -> record<data: table<userTypeId: string, accountId: string, firstName: string, lastName: string, external: bool, inviterUserId: string, role: string, id: string, email: string, status: string, invitationDate: string, resolvedDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resend" $resend "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "external" $external "scalar") (serialize-qp "userTypeId" $userTypeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/invitations/($invitationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Invitation
#
# DELETE /invitations/{invitationId}
# operationId: DELETE:/invitations/single
export def "invitations DELETE:/invitations/single" [
  invitationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<userTypeId: string, accountId: string, firstName: string, lastName: string, external: bool, inviterUserId: string, role: string, id: string, email: string, status: string, invitationDate: string, resolvedDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invitations/($invitationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Job Roles (Account)
#
# GET /jobroles
# operationId: GET:/jobroles/empty
export def "jobroles GET:/jobroles/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<isDeleted: bool, avatarUrl: string, id: string, shortTitle: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jobroles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Job Role
#
# POST /jobroles
# operationId: POST:/jobroles/empty
export def "jobroles POST:/jobroles/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Name of Job Role
  --shortTitle: string # Short name of Job Role
  --avatarColor: string@avatarColor-completer # Job Role Avatar color * `Purple1` - #BA68C8 * `Purple2` - #8E24AA * `Blue1` - #64B5F6 * `Pink1` - #F06292 * `Pink2` - #D81B60 * `Red1` - #E57373 * `Red2` - #E53935 * `Turquoise1` - #4DD0E1 * `Turquoise2` - #00ACC1 * `Blue2` - #1E88E5 * `DarkBlue1` - #7986CB * `Green2` - #43A047 * `DarkBlue2` - #3949AB * `Green1` - #81C784 * `Yellow1` - #FBC02D * `Yellow2` - #F9A825 * `Orange2` - #F57C00 * `DarkCyan2` - #00897B * `Orange1` - #FF9800 * `DarkCyan1` - #4DB6AC * `YellowGreen2` - #AFB42B * `YellowGreen1` - #C0CA33
]: nothing -> record<data: table<isDeleted: bool, avatarUrl: string, id: string, shortTitle: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "shortTitle" $shortTitle "scalar") (serialize-qp "avatarColor" $avatarColor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobroles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Job Roles By ID
#
# GET /jobroles/{jobroleIds}
# operationId: GET:/jobroles/multi
export def "jobroles GET:/jobroles/multi" [
  jobroleIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<isDeleted: bool, avatarUrl: string, id: string, shortTitle: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobroles/($jobroleIds)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Job Role
#
# PUT /jobroles/{jobroleId}
# operationId: PUT:/jobroles/single
export def "jobroles PUT:/jobroles/single" [
  jobroleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Name of Job Role
  --shortTitle: string # Short name of Job Role
  --avatarColor: string # Job Role Avatar color
]: nothing -> record<data: table<isDeleted: bool, avatarUrl: string, id: string, shortTitle: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "shortTitle" $shortTitle "scalar") (serialize-qp "avatarColor" $avatarColor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobroles/($jobroleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Job Role
#
# DELETE /jobroles/{jobroleId}
# operationId: DELETE:/jobroles/single
export def "jobroles DELETE:/jobroles/single" [
  jobroleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<isDeleted: bool, avatarUrl: string, id: string, shortTitle: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobroles/($jobroleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Placeholders (Account)
#
# GET /placeholders
# operationId: GET:/placeholders/empty
export def "placeholders GET:/placeholders/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<deleted: bool, avatarUrl: string, jobRoleId: string, id: string, shortTitle: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/placeholders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Placeholders By ID
#
# GET /placeholders/{placeholderIds}
# operationId: GET:/placeholders/multi
export def "placeholders GET:/placeholders/multi" [
  placeholderIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<deleted: bool, avatarUrl: string, jobRoleId: string, id: string, shortTitle: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/placeholders/($placeholderIds)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate prefilled Request Form URL
#
# POST /request_forms/{requestFormId}/prefill_url
# operationId: POST:/request_forms/single/prefill_url
export def "request-forms-prefill-url url" [
  requestFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --formFields: string # Form fields
]: nothing -> record<data: table<url: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "formFields" $formFields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/request_forms/($requestFormId)/prefill_url" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Request Form
#
# POST /request_forms/{requestFormId}/submit
# operationId: POST:/request_forms/single/submit
export def "request-forms-submit forms/single/submit" [
  requestFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --formFields: string # Form fields. Mandatory fields must be included.
]: nothing -> record<data: table<formId: string, projectId: string, taskId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "formFields" $formFields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/request_forms/($requestFormId)/submit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Request Forms
#
# GET /request_forms
# operationId: GET:/request_forms/empty
export def "request-forms forms/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plainTextDescription: oneof<nothing, bool> # Get form description as plain text, HTML otherwise (default: false)
  --limit: float # Limit on number of returned forms
  --pageSize: float # The number of forms to return (max 100 items per page)
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case.
  --qp-fields: string # Json string array of optional fields to be included in the response model * `dataUsageStatistics` - Return collection of data usage statistics
]: nothing -> record<data: table<spaceId: string, pages: list, description: string, id: string, title: string, dataUsageStatistics: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "plainTextDescription" $plainTextDescription "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/request_forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Request Forms
#
# GET /spaces/{spaceId}/request_forms
# operationId: GET:/spaces/single/request_forms
export def "spaces-request-forms forms" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plainTextDescription: oneof<nothing, bool> # Get form description as plain text, HTML otherwise (default: false)
  --limit: float # Limit on number of returned forms
  --pageSize: float # The number of forms to return (max 100 items per page)
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case.
  --qp-fields: string # Json string array of optional fields to be included in the response model * `dataUsageStatistics` - Return collection of data usage statistics
]: nothing -> record<data: table<spaceId: string, pages: list, description: string, id: string, title: string, dataUsageStatistics: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "plainTextDescription" $plainTextDescription "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/request_forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Request Form by ID
#
# GET /request_forms/{requestFormId}
# operationId: GET:/request_forms/single
export def "request-forms forms/single" [
  requestFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plainTextDescription: oneof<nothing, bool> # When true, returns description as plain text (line breaks stripped). When false (default), description is plain text with <br> tags for line breaks. (default: false)
  --qp-fields: string # Json string array of optional fields to be included in the response model * `dataUsageStatistics` - Return collection of data usage statistics
]: nothing -> record<data: table<spaceId: string, pages: list, description: string, id: string, title: string, dataUsageStatistics: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "plainTextDescription" $plainTextDescription "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/request_forms/($requestFormId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Rollup Settings (Folder)
#
# GET /folders/{folderId}/rollups
# operationId: GET:/folders/single/rollups
export def "folders-rollups GET:/folders/single/rollups" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --descendants: oneof<nothing, bool> # Adds all descendant folders to search scope (default: false)
  --filter: string # Filter rollup results by field configurations
  --pageSize: float # The number of rollup settings to return (max 100 items per page)
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case. If you included optional fields to the first request, you will need to include those in each new call.
]: nothing -> record<data: table<itemId: string, rollupSettings: list, childIds: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "descendants" $descendants "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/rollups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Rollup Settings (Folder)
#
# PUT /folders/{folderId}/rollups
# operationId: PUT:/folders/single/rollups
export def "folders-rollups PUT:/folders/single/rollups" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rollups: string # Rollup settings updates. Limit : `20`
]: nothing -> record<data: table<itemId: string, rollupSettings: list, childIds: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rollups" $rollups "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/rollups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Rollup Settings (Task)
#
# GET /tasks/{taskId}/rollups
# operationId: GET:/tasks/single/rollups
export def "tasks-rollups GET:/tasks/single/rollups" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Filter rollup results by field configurations
]: nothing -> record<data: table<itemId: string, rollupSettings: list, childIds: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/rollups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Rollup Settings (Task)
#
# PUT /tasks/{taskId}/rollups
# operationId: PUT:/tasks/single/rollups
export def "tasks-rollups PUT:/tasks/single/rollups" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rollups: string # Rollup settings updates. Limit : `20`
]: nothing -> record<data: table<itemId: string, rollupSettings: list, childIds: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rollups" $rollups "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/rollups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Spaces (Account)
#
# GET /spaces
# operationId: GET:/spaces/empty
export def "spaces GET:/spaces/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withArchived: oneof<nothing, bool> # Include archived spaces (default: false)
  --userIsMember: oneof<nothing, bool> # Include only spaces where user is member
  --withInvitations: oneof<nothing, bool> # Include invitations in space members list (default: false)
  --title: string # Title filter, contains match and accepts non-blank values only
  --accessTypes: string # Access type filter * `Locked` * `Personal` * `Private` * `Public`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `members` - Space members * `workScheduleId` - Id of work schedule assigned to space
]: nothing -> record<data: table<defaultTaskWorkflowId: string, guestRoleId: string, avatarUrl: string, description: string, suggestedProjectWorkflowIds: list, suggestedTaskWorkflowIds: list, title: string, defaultProjectWorkflowId: string, accessType: string, archived: bool, members: list, workScheduleId: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withArchived" $withArchived "scalar") (serialize-qp "userIsMember" $userIsMember "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "accessTypes" $accessTypes "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Space
#
# POST /spaces
# operationId: POST:/spaces/empty
export def "spaces POST:/spaces/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessType: string@accessType-completer # Type of the space * `Locked` * `Private` * `Public`
  --title: string # Title of the space
  --description: string # Description of the space
  --members: string # Space members. More than 1 member with the same ID is not allowed. Limit : `1000`
  --guestRoleId: string # Space guest role. Available only for a public space
  --defaultProjectWorkflowId: string # Set default project workflow for a space
  --suggestedProjectWorkflows: string # Suggested project workflows for a space. A workflow can only be included in a request once. Limit : `100`
  --defaultTaskWorkflowId: string # Set default task workflow for a space
  --suggestedTaskWorkflows: string # Suggested task workflows for a space. A workflow can only be included in a request once
  --withInvitations: oneof<nothing, bool> # Include invitations in space members list (default: false)
  --workScheduleId: string # Id of work schedule to assign to space
  --qp-fields: string # Json string array of optional fields to be included in the response model * `suggestedTaskWorkflows` - Suggested task workflows for a space * `suggestedProjectWorkflows` - Suggested project workflows for a space * `members` - Space members * `workScheduleId` - Id of work schedule assigned to space
]: nothing -> record<data: table<defaultTaskWorkflowId: string, guestRoleId: string, avatarUrl: string, description: string, suggestedProjectWorkflowIds: list, suggestedTaskWorkflowIds: list, title: string, defaultProjectWorkflowId: string, accessType: string, archived: bool, members: list, workScheduleId: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessType" $accessType "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "guestRoleId" $guestRoleId "scalar") (serialize-qp "defaultProjectWorkflowId" $defaultProjectWorkflowId "scalar") (serialize-qp "suggestedProjectWorkflows" $suggestedProjectWorkflows "scalar") (serialize-qp "defaultTaskWorkflowId" $defaultTaskWorkflowId "scalar") (serialize-qp "suggestedTaskWorkflows" $suggestedTaskWorkflows "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "workScheduleId" $workScheduleId "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Space By ID
#
# GET /spaces/{spaceId}
# operationId: GET:/spaces/single
export def "spaces GET:/spaces/single" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withInvitations: oneof<nothing, bool> # Include invitations in space members list (default: false)
  --qp-fields: string # Json string array of optional fields to be included in the response model * `suggestedTaskWorkflows` - Suggested task workflows for a space * `suggestedProjectWorkflows` - Suggested project workflows for a space * `members` - Space members * `workScheduleId` - Id of work schedule assigned to space
]: nothing -> record<data: table<defaultTaskWorkflowId: string, guestRoleId: string, avatarUrl: string, description: string, suggestedProjectWorkflowIds: list, suggestedTaskWorkflowIds: list, title: string, defaultProjectWorkflowId: string, accessType: string, archived: bool, members: list, workScheduleId: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Space
#
# PUT /spaces/{spaceId}
# operationId: PUT:/spaces/single
export def "spaces PUT:/spaces/single" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessType: string@accessType-completer-1 # Type of the space * `Private` * `Public`
  --title: string # Title of the space
  --description: string # Description of the space
  --membersAdd: string # Space members to add. A member should be passed only once in request. Limit : `1000`
  --membersUpdate: string # Space members to update. A member should be passed only once in request
  --membersRemove: string # Space members to remove. A member should be passed only once in request. Limit : `1000`
  --guestRoleId: string # Space guest role. Available only for a public space
  --defaultProjectWorkflowId: string # Set default project workflow for a space
  --suggestedProjectWorkflowsAdd: string # Add workflows to Suggested project workflows. A workflow can only be included in a request once. Limit : `100`
  --suggestedProjectWorkflowsRemove: string # Remove workflows from Suggested project workflows. A workflow can only be included in a request once
  --defaultTaskWorkflowId: string # Set default task workflow for a space
  --suggestedTaskWorkflowsAdd: string # Add workflows to Suggested task workflows. A workflow can only be included in a request once
  --suggestedTaskWorkflowsRemove: string # Remove workflows from Suggested task workflows. A workflow can only be included in a request once
  --withInvitations: oneof<nothing, bool> # Include invitations in space members list (default: false)
  --workScheduleId: string # Id of work schedule to assign to space
  --qp-fields: string # Json string array of optional fields to be included in the response model * `suggestedTaskWorkflows` - Space task suggested workflows * `suggestedProjectWorkflows` - Space project suggested workflows * `members` - Space members * `workScheduleId` - Id of work schedule assigned to space
]: nothing -> record<data: table<defaultTaskWorkflowId: string, guestRoleId: string, avatarUrl: string, description: string, suggestedProjectWorkflowIds: list, suggestedTaskWorkflowIds: list, title: string, defaultProjectWorkflowId: string, accessType: string, archived: bool, members: list, workScheduleId: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessType" $accessType "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "membersAdd" $membersAdd "scalar") (serialize-qp "membersUpdate" $membersUpdate "scalar") (serialize-qp "membersRemove" $membersRemove "scalar") (serialize-qp "guestRoleId" $guestRoleId "scalar") (serialize-qp "defaultProjectWorkflowId" $defaultProjectWorkflowId "scalar") (serialize-qp "suggestedProjectWorkflowsAdd" $suggestedProjectWorkflowsAdd "scalar") (serialize-qp "suggestedProjectWorkflowsRemove" $suggestedProjectWorkflowsRemove "scalar") (serialize-qp "defaultTaskWorkflowId" $defaultTaskWorkflowId "scalar") (serialize-qp "suggestedTaskWorkflowsAdd" $suggestedTaskWorkflowsAdd "scalar") (serialize-qp "suggestedTaskWorkflowsRemove" $suggestedTaskWorkflowsRemove "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "workScheduleId" $workScheduleId "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Space
#
# DELETE /spaces/{spaceId}
# operationId: DELETE:/spaces/single
export def "spaces DELETE:/spaces/single" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: list<string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Task Blueprints (Account)
#
# GET /task_blueprints
# operationId: GET:/task_blueprints/empty
export def "task-blueprints blueprints/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permalink: string # Task permalink, exact match
  --title: string # Title search
  --limit: float # Limit on number of returned task blueprints. It is ignored if pagination is requested (default: 1000)
  --pageSize: float # Page size
  --nextPageToken: string # Next page token
  --customFields: string # Custom field filters, exact match. Limit : `25`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `customFields` - Custom Fields
]: nothing -> record<data: table<childIds: list, customFields: list, scope: string, id: string, permalink: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permalink" $permalink "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/task_blueprints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Task Blueprints (Space)
#
# GET /spaces/{spaceId}/task_blueprints
# operationId: GET:/spaces/single/task_blueprints
export def "spaces-task-blueprints blueprints" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permalink: string # Task permalink, exact match
  --limit: float # Limit on number of returned task blueprints. It is ignored if pagination is requested (default: 1000)
  --pageSize: float # Page size
  --nextPageToken: string # Next page token
  --qp-fields: string # Json string array of optional fields to be included in the response model * `customFields` - Custom Fields
]: nothing -> record<data: table<childIds: list, customFields: list, scope: string, id: string, permalink: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permalink" $permalink "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/task_blueprints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Async Work Creation
#
# POST /task_blueprints/{taskBlueprintId}/launch_async
# operationId: POST:/task_blueprints/single/launch_async
export def "task-blueprints-launch-async async" [
  taskBlueprintId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --superTaskId: string # ID of parent task. Set this to add work from the task-based template as a subtask. Either this parameter or parentId  is required. parentId and superTaskId cannot be set simultaneously.
  --parentId: string # ID of parent folder or project.  Set this to put work from the template to the specific folder or project. Either this parameter or superTaskId  is required. parentId and superTaskId cannot be set simultaneously
  --title: string # Title (required)
  --titlePrefix: string # Title prefix for all copied tasks
  --copyDescriptions: oneof<nothing, bool> # Copy descriptions or leave empty (default: true)
  --notifyResponsibles: oneof<nothing, bool> # Notify those responsible (default: true)
  --copyResponsibles: oneof<nothing, bool> # Copy those responsible (default: true)
  --copyCustomFields: oneof<nothing, bool> # Copy custom fields (default: true)
  --copyAttachments: oneof<nothing, bool> # Copy attachments (default: false)
  --rescheduleDate: string # Date to use in task rescheduling. Note: Only active tasks can be rescheduled. Format: yyyy-MM-dd Format: yyyy-MM-dd
  --rescheduleMode: string@rescheduleMode-completer # Mode to be used for rescheduling (based on first or last date). Used only if reschedule date is specified. * `Start` - Tasks in scope are rescheduled starting from reschedule date * `End` - Tasks in scope are rescheduled ending with reschedule date
  --entryLimit: float # Maximum number of tasks/folders in tree for copy. The operation will fail if limit is exceeded. This should be 1..250 (default: 250)
]: nothing -> record<data: table<result: record, processedCount: float, errorMessage: string, progressPercent: float, id: string, totalCount: float, type: string, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "superTaskId" $superTaskId "scalar") (serialize-qp "parentId" $parentId "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "titlePrefix" $titlePrefix "scalar") (serialize-qp "copyDescriptions" $copyDescriptions "scalar") (serialize-qp "notifyResponsibles" $notifyResponsibles "scalar") (serialize-qp "copyResponsibles" $copyResponsibles "scalar") (serialize-qp "copyCustomFields" $copyCustomFields "scalar") (serialize-qp "copyAttachments" $copyAttachments "scalar") (serialize-qp "rescheduleDate" $rescheduleDate "scalar") (serialize-qp "rescheduleMode" $rescheduleMode "scalar") (serialize-qp "entryLimit" $entryLimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/task_blueprints/($taskBlueprintId)/launch_async" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Tasks (Account)
#
# GET /tasks
# operationId: GET:/tasks/empty
export def "tasks GET:/tasks/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --descendants: oneof<nothing, bool> # Adds all descendant folders to search scope. Applicable only for GET/folders/{folderId}/tasks and GET/spaces/{spaceId}/tasks endpoints
  --title: string # Title filter, contains match
  --status: string # Status filter, match with any of specified constants * `Active` - Active * `Deferred` - Deferred * `Completed` - Completed * `Cancelled` - Cancelled
  --importance: string@importance-completer # Importance filter, exact match * `High` * `Low` * `Normal`
  --startDate: string # Start date filter, date match or range
  --dueDate: string # Due date filter, date match or range
  --scheduledDate: string # Scheduled date filter. Both dates should be set in ranged version. Returns all tasks that have schedule intersecting with specified interval, date match or range
  --createdDate: string # Created date filter, range
  --updatedDate: string # Updated date filter, range
  --completedDate: string # Completed date filter, range
  --authors: string # Authors filter, match of any
  --responsibles: string # Assignees filter with specified users or invitations, match of any
  --responsiblePlaceholders: string # Assignee Placeholders filter, match of any
  --permalink: string # Task permalink, exact match
  --type: string@type-completer-4 # Task type * `Milestone` * `Backlog` * `Planned`
  --limit: float # Limit on number of returned tasks
  --sortField: string@sortField-completer # Sort field * `Status` - Sort by status * `Importance` - Sort by importance * `UpdatedDate` - Sort by updated date * `CreatedDate` - Sort by created date * `Title` - Lexicographic sorting by title * `StartFinishInterval` - Sort by start-finish interval * `DueDate` - Sort by due date * `LastAccessDate` - Sort by last access date * `CompletedDate` - Sort by completed date
  --sortOrder: string@sortOrder-completer # Sort order * `Asc` - Ascending sort order * `Desc` - Descending sort order
  --subTasks: oneof<nothing, bool> # Adds subtasks to search scope
  --pageSize: float # The number of tasks to return (max 1000 items per page)
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case. If you included optional fields to the first request, you will need to include those  in each new call
  --metadata: string # Task metadata filter
  --customField: string # [Deprecated] It is recommended to use 'customFields' parameter. Custom field filter
  --customFields: string # Custom field filters, exact match
  --customStatuses: string # Custom statuses filter
  --withInvitations: oneof<nothing, bool> # Include invitations in sharedIds & responsibleIds lists
  --billingTypes: string # Timelog billing types filter * `Billable` - Billable * `NonBillable` - Non-Billable
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --customItemTypes: string # Custom item types filter. Standard type (task) ID is not allowed. Filtering by deleted custom item types is not supported. Limit : `1000`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `metadata` - Task metadata entries * `responsibleIds` - List of assignee user IDs * `customItemTypeId` - Work Item custom item type Id * `customFields` - Custom fields * `followerIds` - List of user IDs, who follows task, and the additional flag "followedByMe", that indicates if a task is followed by user * `parentIds` - List of task parent folder * `sharedIds` - List of user IDs, who have task share * `description` - Description * `superTaskIds` - List of supertask IDs * `responsiblePlaceholderIds` - List of placeholder assignee IDs * `superParentIds` - List of folder IDs inherited from parent task * `dependencyIds` - Dependency IDs * `billingType` - Billing type * `attachmentCount` - Attachment count * `workScheduleId` - Id of work schedule assigned to task * `effortAllocation` - Effort Allocation * `hasAttachments` - Has attachments * `subTaskIds` - List of subtask IDs * `recurrent` - Is a task recurrent * `authorIds` - Author IDs * `briefDescription` - Brief description
]: nothing -> record<data: table<metadata: list, importance: string, customFields: list, followerIds: list, parentIds: list, description: string, responsiblePlaceholderIds: list, updatedDate: string, title: string, followedByMe: bool, billingType: string, scope: string, id: string, effortAllocation: record, hasAttachments: bool, subTaskIds: list, recurrent: bool, authorIds: list, responsibleIds: list, customItemTypeId: string, sharedIds: list, dates: record, superTaskIds: list, priority: string, completedDate: string, superParentIds: list, accountId: string, dependencyIds: list, createdDate: string, cascadingFieldSettings: list, customStatusId: string, attachmentCount: float, workScheduleId: string, permalink: string, briefDescription: string, finance: record, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "descendants" $descendants "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "importance" $importance "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "dueDate" $dueDate "scalar") (serialize-qp "scheduledDate" $scheduledDate "scalar") (serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "completedDate" $completedDate "scalar") (serialize-qp "authors" $authors "scalar") (serialize-qp "responsibles" $responsibles "scalar") (serialize-qp "responsiblePlaceholders" $responsiblePlaceholders "scalar") (serialize-qp "permalink" $permalink "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "subTasks" $subTasks "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "customField" $customField "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "customStatuses" $customStatuses "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "billingTypes" $billingTypes "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "customItemTypes" $customItemTypes "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Tasks (Folder)
#
# GET /folders/{folderId}/tasks
# operationId: GET:/folders/single/tasks
export def "folders-tasks GET:/folders/single/tasks" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --descendants: oneof<nothing, bool> # Adds all descendant folders to search scope. Applicable only for GET/folders/{folderId}/tasks and GET/spaces/{spaceId}/tasks endpoints
  --title: string # Title filter, contains match
  --status: string # Status filter, match with any of specified constants * `Active` - Active * `Deferred` - Deferred * `Completed` - Completed * `Cancelled` - Cancelled
  --importance: string@importance-completer # Importance filter, exact match * `High` * `Low` * `Normal`
  --startDate: string # Start date filter, date match or range
  --dueDate: string # Due date filter, date match or range
  --scheduledDate: string # Scheduled date filter. Both dates should be set in ranged version. Returns all tasks that have schedule intersecting with specified interval, date match or range
  --createdDate: string # Created date filter, range
  --updatedDate: string # Updated date filter, range
  --completedDate: string # Completed date filter, range
  --authors: string # Authors filter, match of any
  --responsibles: string # Assignees filter with specified users or invitations, match of any
  --responsiblePlaceholders: string # Assignee Placeholders filter, match of any
  --permalink: string # Task permalink, exact match
  --type: string@type-completer-4 # Task type * `Milestone` * `Backlog` * `Planned`
  --limit: float # Limit on number of returned tasks
  --sortField: string@sortField-completer # Sort field * `Status` - Sort by status * `Importance` - Sort by importance * `UpdatedDate` - Sort by updated date * `CreatedDate` - Sort by created date * `Title` - Lexicographic sorting by title * `StartFinishInterval` - Sort by start-finish interval * `DueDate` - Sort by due date * `LastAccessDate` - Sort by last access date * `CompletedDate` - Sort by completed date
  --sortOrder: string@sortOrder-completer # Sort order * `Asc` - Ascending sort order * `Desc` - Descending sort order
  --subTasks: oneof<nothing, bool> # Adds subtasks to search scope
  --pageSize: float # The number of tasks to return (max 1000 items per page)
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case. If you included optional fields to the first request, you will need to include those  in each new call
  --metadata: string # Task metadata filter
  --customField: string # [Deprecated] It is recommended to use 'customFields' parameter. Custom field filter
  --customFields: string # Custom field filters, exact match
  --customStatuses: string # Custom statuses filter
  --withInvitations: oneof<nothing, bool> # Include invitations in sharedIds & responsibleIds lists
  --billingTypes: string # Timelog billing types filter * `Billable` - Billable * `NonBillable` - Non-Billable
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --customItemTypes: string # Custom item types filter. Standard type (task) ID is not allowed. Filtering by deleted custom item types is not supported. Limit : `1000`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `metadata` - Task metadata entries * `responsibleIds` - List of assignee user IDs * `customItemTypeId` - Work Item custom item type Id * `customFields` - Custom fields * `followerIds` - List of user IDs, who follows task, and the additional flag "followedByMe", that indicates if a task is followed by user * `parentIds` - List of task parent folder * `sharedIds` - List of user IDs, who have task share * `description` - Description * `superTaskIds` - List of supertask IDs * `responsiblePlaceholderIds` - List of placeholder assignee IDs * `superParentIds` - List of folder IDs inherited from parent task * `dependencyIds` - Dependency IDs * `billingType` - Billing type * `attachmentCount` - Attachment count * `workScheduleId` - Id of work schedule assigned to task * `effortAllocation` - Effort Allocation * `hasAttachments` - Has attachments * `subTaskIds` - List of subtask IDs * `recurrent` - Is a task recurrent * `authorIds` - Author IDs * `briefDescription` - Brief description * `finance` - Task Finance fields
]: nothing -> record<data: table<metadata: list, importance: string, customFields: list, followerIds: list, parentIds: list, description: string, responsiblePlaceholderIds: list, updatedDate: string, title: string, followedByMe: bool, billingType: string, scope: string, id: string, effortAllocation: record, hasAttachments: bool, subTaskIds: list, recurrent: bool, authorIds: list, responsibleIds: list, customItemTypeId: string, sharedIds: list, dates: record, superTaskIds: list, priority: string, completedDate: string, superParentIds: list, accountId: string, dependencyIds: list, createdDate: string, cascadingFieldSettings: list, customStatusId: string, attachmentCount: float, workScheduleId: string, permalink: string, briefDescription: string, finance: record, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "descendants" $descendants "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "importance" $importance "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "dueDate" $dueDate "scalar") (serialize-qp "scheduledDate" $scheduledDate "scalar") (serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "completedDate" $completedDate "scalar") (serialize-qp "authors" $authors "scalar") (serialize-qp "responsibles" $responsibles "scalar") (serialize-qp "responsiblePlaceholders" $responsiblePlaceholders "scalar") (serialize-qp "permalink" $permalink "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "subTasks" $subTasks "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "customField" $customField "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "customStatuses" $customStatuses "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "billingTypes" $billingTypes "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "customItemTypes" $customItemTypes "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Task (Folder)
#
# POST /folders/{folderId}/tasks
# operationId: POST:/folders/single/tasks
export def "folders-tasks POST:/folders/single/tasks" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title of task, required
  --description: string # Description of task, will be left blank, if not set
  --status: string@status-completer # Status of task. Not available for the Team plan * `Active` - Active * `Deferred` - Deferred * `Completed` - Completed * `Cancelled` - Cancelled
  --importance: string@importance-completer # Importance of task * `High` * `Low` * `Normal`
  --dates: string # Task dates. If not specified, a backlogged task is created
  --shareds: string # Shares task with specified users or invitations. The task is always shared with the author.
  --parents: string # Parent folders for newly created task. Can not contain recycleBinId
  --responsibles: string # Makes specified users or invitations assignee for the task
  --responsiblePlaceholders: string # Makes specified placeholders assignee for the task
  --followers: string # Add specified users to task followers
  --follow: oneof<nothing, bool> # Follow task
  --priorityBefore: string # Put newly created task before specified task in task list
  --priorityAfter: string # Put newly created task after specified task in task list
  --superTasks: string # Add the task as subtask to specified tasks
  --metadata: string # Metadata to be added to newly created task. Limit : `100`
  --customFields: string # List of custom fields to set in newly created task. Limit : `100`
  --customStatus: string # Custom status ID
  --effortAllocation: string # Set Task Effort fields: mode, total Effort
  --billingType: string@billingType-completer # Task's timelogs billing type * `Billable` - Billable * `NonBillable` - Non-Billable
  --withInvitations: oneof<nothing, bool> # Include invitations in sharedIds & responsibleIds lists
  --customItemTypeId: string # Custom Item Type ID to create a task from
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --workScheduleId: string # Id of work schedule to assign to task
  --qp-fields: string # Json string array of optional fields to be included in the response model * `customItemTypeId` - Custom Item Type ID * `billingType` - Billing type * `workScheduleId` - Id of work schedule assigned to task * `effortAllocation` - Effort Allocation * `responsiblePlaceholderIds` - List of placeholder assignee IDs
]: nothing -> record<data: table<metadata: list, importance: string, customFields: list, followerIds: list, parentIds: list, description: string, responsiblePlaceholderIds: list, updatedDate: string, title: string, followedByMe: bool, billingType: string, scope: string, id: string, effortAllocation: record, hasAttachments: bool, subTaskIds: list, recurrent: bool, authorIds: list, responsibleIds: list, customItemTypeId: string, sharedIds: list, dates: record, superTaskIds: list, priority: string, completedDate: string, superParentIds: list, accountId: string, dependencyIds: list, createdDate: string, cascadingFieldSettings: list, customStatusId: string, attachmentCount: float, workScheduleId: string, permalink: string, briefDescription: string, finance: record, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "importance" $importance "scalar") (serialize-qp "dates" $dates "scalar") (serialize-qp "shareds" $shareds "scalar") (serialize-qp "parents" $parents "scalar") (serialize-qp "responsibles" $responsibles "scalar") (serialize-qp "responsiblePlaceholders" $responsiblePlaceholders "scalar") (serialize-qp "followers" $followers "scalar") (serialize-qp "follow" $follow "scalar") (serialize-qp "priorityBefore" $priorityBefore "scalar") (serialize-qp "priorityAfter" $priorityAfter "scalar") (serialize-qp "superTasks" $superTasks "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "customStatus" $customStatus "scalar") (serialize-qp "effortAllocation" $effortAllocation "scalar") (serialize-qp "billingType" $billingType "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "customItemTypeId" $customItemTypeId "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "workScheduleId" $workScheduleId "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Tasks (Space)
#
# GET /spaces/{spaceId}/tasks
# operationId: GET:/spaces/single/tasks
export def "spaces-tasks GET:/spaces/single/tasks" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --descendants: oneof<nothing, bool> # Adds all descendant folders to search scope. Applicable only for GET/folders/{folderId}/tasks and GET/spaces/{spaceId}/tasks endpoints
  --title: string # Title filter, contains match
  --status: string # Status filter, match with any of specified constants * `Active` - Active * `Deferred` - Deferred * `Completed` - Completed * `Cancelled` - Cancelled
  --importance: string@importance-completer # Importance filter, exact match * `High` * `Low` * `Normal`
  --startDate: string # Start date filter, date match or range
  --dueDate: string # Due date filter, date match or range
  --scheduledDate: string # Scheduled date filter. Both dates should be set in ranged version. Returns all tasks that have schedule intersecting with specified interval, date match or range
  --createdDate: string # Created date filter, range
  --updatedDate: string # Updated date filter, range
  --completedDate: string # Completed date filter, range
  --authors: string # Authors filter, match of any
  --responsibles: string # Assignees filter with specified users or invitations, match of any
  --responsiblePlaceholders: string # Assignee Placeholders filter, match of any
  --permalink: string # Task permalink, exact match
  --type: string@type-completer-4 # Task type * `Milestone` * `Backlog` * `Planned`
  --limit: float # Limit on number of returned tasks
  --sortField: string@sortField-completer # Sort field * `Status` - Sort by status * `Importance` - Sort by importance * `UpdatedDate` - Sort by updated date * `CreatedDate` - Sort by created date * `Title` - Lexicographic sorting by title * `StartFinishInterval` - Sort by start-finish interval * `DueDate` - Sort by due date * `LastAccessDate` - Sort by last access date * `CompletedDate` - Sort by completed date
  --sortOrder: string@sortOrder-completer # Sort order * `Asc` - Ascending sort order * `Desc` - Descending sort order
  --subTasks: oneof<nothing, bool> # Adds subtasks to search scope
  --pageSize: float # The number of tasks to return (max 1000 items per page)
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case. If you included optional fields to the first request, you will need to include those  in each new call
  --metadata: string # Task metadata filter
  --customField: string # [Deprecated] It is recommended to use 'customFields' parameter. Custom field filter
  --customFields: string # Custom field filters, exact match
  --customStatuses: string # Custom statuses filter
  --withInvitations: oneof<nothing, bool> # Include invitations in sharedIds & responsibleIds lists
  --billingTypes: string # Timelog billing types filter * `Billable` - Billable * `NonBillable` - Non-Billable
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --customItemTypes: string # Custom item types filter. Standard type (task) ID is not allowed. Filtering by deleted custom item types is not supported. Limit : `1000`
  --qp-fields: string # Json string array of optional fields to be included in the response model * `metadata` - Task metadata entries * `responsibleIds` - List of assignee user IDs * `customItemTypeId` - Work Item custom item type Id * `customFields` - Custom fields * `followerIds` - List of user IDs, who follows task, and the additional flag "followedByMe", that indicates if a task is followed by user * `parentIds` - List of task parent folder * `sharedIds` - List of user IDs, who have task share * `description` - Description * `superTaskIds` - List of supertask IDs * `responsiblePlaceholderIds` - List of placeholder assignee IDs * `superParentIds` - List of folder IDs inherited from parent task * `dependencyIds` - Dependency IDs * `billingType` - Billing type * `attachmentCount` - Attachment count * `workScheduleId` - Id of work schedule assigned to task * `effortAllocation` - Effort Allocation * `hasAttachments` - Has attachments * `subTaskIds` - List of subtask IDs * `recurrent` - Is a task recurrent * `authorIds` - Author IDs * `briefDescription` - Brief description
]: nothing -> record<data: table<metadata: list, importance: string, customFields: list, followerIds: list, parentIds: list, description: string, responsiblePlaceholderIds: list, updatedDate: string, title: string, followedByMe: bool, billingType: string, scope: string, id: string, effortAllocation: record, hasAttachments: bool, subTaskIds: list, recurrent: bool, authorIds: list, responsibleIds: list, customItemTypeId: string, sharedIds: list, dates: record, superTaskIds: list, priority: string, completedDate: string, superParentIds: list, accountId: string, dependencyIds: list, createdDate: string, cascadingFieldSettings: list, customStatusId: string, attachmentCount: float, workScheduleId: string, permalink: string, briefDescription: string, finance: record, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "descendants" $descendants "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "importance" $importance "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "dueDate" $dueDate "scalar") (serialize-qp "scheduledDate" $scheduledDate "scalar") (serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "completedDate" $completedDate "scalar") (serialize-qp "authors" $authors "scalar") (serialize-qp "responsibles" $responsibles "scalar") (serialize-qp "responsiblePlaceholders" $responsiblePlaceholders "scalar") (serialize-qp "permalink" $permalink "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "subTasks" $subTasks "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "customField" $customField "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "customStatuses" $customStatuses "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "billingTypes" $billingTypes "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "customItemTypes" $customItemTypes "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Tasks By IDs
#
# GET /tasks/{taskIds}
# operationId: GET:/tasks/multi
export def "tasks GET:/tasks/multi" [
  taskIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withInvitations: oneof<nothing, bool> # Include invitations in sharedIds & responsibleIds lists
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --qp-fields: string # Json string array of optional fields to be included in the response model * `cascadingFields` - Active cascading fields settings * `customItemTypeId` - Work Item custom item type Id * `billingType` - Billing type * `attachmentCount` - Attachment count * `workScheduleId` - Id of work schedule assigned to task * `responsiblePlaceholderIds` - List of placeholder responsible IDs * `effortAllocation` - Effort Allocation * `recurrent` - Add field to indicate if task is recurrent * `finance` - Task Finance fields
]: nothing -> record<data: table<metadata: list, importance: string, customFields: list, followerIds: list, parentIds: list, description: string, responsiblePlaceholderIds: list, updatedDate: string, title: string, followedByMe: bool, billingType: string, scope: string, id: string, effortAllocation: record, hasAttachments: bool, subTaskIds: list, recurrent: bool, authorIds: list, responsibleIds: list, customItemTypeId: string, sharedIds: list, dates: record, superTaskIds: list, priority: string, completedDate: string, superParentIds: list, accountId: string, dependencyIds: list, createdDate: string, cascadingFieldSettings: list, customStatusId: string, attachmentCount: float, workScheduleId: string, permalink: string, briefDescription: string, finance: record, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskIds)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Tasks (Bulk)
#
# PUT /tasks/{taskIds}
# operationId: PUT:/tasks/multi
export def "tasks PUT:/tasks/multi" [
  taskIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --customFields: string # Custom fields to be updated or deleted (null value removes field). Limit : `100`
  --effortAllocation: string # Set Task Effort fields: mode, total Effort
  --setResponsibleAllocation: string # Update responsible allocations
  --convertToCustomItemType: string # Custom Item Type id
  --addParents: string # Put task into specified folders of same account. Cannot contain RecycleBin folder
  --removeParents: string # Remove task from specified folders. Can not contain RecycleBin folder
  --addResponsibles: string # Add specified users or invitations to assignee list
  --removeResponsibles: string # Remove specified users or invitations from assignee list
  --addResponsiblePlaceholders: string # Add specified placeholders to placeholder assignee list
  --removeResponsiblePlaceholders: string # Remove specified placeholders from placeholder assignee list
  --customStatus: string # Custom status ID
]: nothing -> record<data: table<metadata: list, importance: string, customFields: list, followerIds: list, parentIds: list, description: string, responsiblePlaceholderIds: list, updatedDate: string, title: string, followedByMe: bool, billingType: string, scope: string, id: string, effortAllocation: record, hasAttachments: bool, subTaskIds: list, recurrent: bool, authorIds: list, responsibleIds: list, customItemTypeId: string, sharedIds: list, dates: record, superTaskIds: list, priority: string, completedDate: string, superParentIds: list, accountId: string, dependencyIds: list, createdDate: string, cascadingFieldSettings: list, customStatusId: string, attachmentCount: float, workScheduleId: string, permalink: string, briefDescription: string, finance: record, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customFields" $customFields "scalar") (serialize-qp "effortAllocation" $effortAllocation "scalar") (serialize-qp "setResponsibleAllocation" $setResponsibleAllocation "scalar") (serialize-qp "convertToCustomItemType" $convertToCustomItemType "scalar") (serialize-qp "addParents" $addParents "scalar") (serialize-qp "removeParents" $removeParents "scalar") (serialize-qp "addResponsibles" $addResponsibles "scalar") (serialize-qp "removeResponsibles" $removeResponsibles "scalar") (serialize-qp "addResponsiblePlaceholders" $addResponsiblePlaceholders "scalar") (serialize-qp "removeResponsiblePlaceholders" $removeResponsiblePlaceholders "scalar") (serialize-qp "customStatus" $customStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskIds)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Tasks fields history
#
# GET /tasks/{taskIds}/tasks_history
# operationId: GET:/tasks/multi/tasks_history
export def "tasks-tasks-history history" [
  taskIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updatedDate: string # Update date filter
  --qp-fields: string # Json string array of optional fields to be included in the response model * `plannedCost` - Planned cost change history * `plannedFees` - Planned fees change history * `actualFees` - Actual fees change history * `actualCost` - Actual cost change history
]: nothing -> record<data: table<plannedCost: list, plannedFees: list, id: string, actualFees: list, actualCost: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskIds)/tasks_history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Task
#
# PUT /tasks/{taskId}
# operationId: PUT:/tasks/single
export def "tasks PUT:/tasks/single" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title of task
  --description: string # Task Description
  --status: string@status-completer # Task status. Not available for the Team plan * `Active` - Active * `Deferred` - Deferred * `Completed` - Completed * `Cancelled` - Cancelled
  --importance: string@importance-completer # Task importance * `High` * `Low` * `Normal`
  --dates: string # Reschedule task and/or change task type
  --addParents: string # Put task into specified folders of same account. Cannot contain RecycleBin folder
  --removeParents: string # Remove task from specified folders. Can not contain RecycleBin folder
  --addShareds: string # Shared task with specified users or invitations
  --removeShareds: string # Unshare task from specified users or invitations
  --addResponsibles: string # Add specified users or invitations to assignee list
  --removeResponsibles: string # Remove specified users or invitations from assignee list
  --addResponsiblePlaceholders: string # Add specified placeholders to placeholder assignee list
  --removeResponsiblePlaceholders: string # Remove specified placeholders from placeholder assignee list
  --addFollowers: string # Add specified users to task followers
  --follow: oneof<nothing, bool> # Follow task
  --priorityBefore: string # Put task in task list before specified task
  --priorityAfter: string # Put task in task list after specified task
  --addSuperTasks: string # Add the task as subtask to specified tasks
  --removeSuperTasks: string # Remove the task form specified tasks subtasks
  --metadata: string # Metadata to be updated (null value removes entry). Limit : `100`
  --customFields: string # Custom fields to be updated or deleted (null value removes field). Limit : `100`
  --customStatus: string # Custom status ID
  --restore: oneof<nothing, bool> # Restore task from Recycled Bin
  --effortAllocation: string # Set Task Effort fields: mode, total Effort
  --setResponsibleAllocation: string # Update responsible allocations
  --billingType: string@billingType-completer # Task's timelogs billing type * `Billable` - Billable * `NonBillable` - Non-Billable
  --withInvitations: oneof<nothing, bool> # Include invitations in sharedIds & responsibleIds lists
  --convertToCustomItemType: string # Custom Item Type id
  --plainTextCustomFields: oneof<nothing, bool> # Strip HTML tags from custom fields
  --workScheduleId: string # Id of work schedule to assign to task
  --qp-fields: string # Json string array of optional fields to be included in the response model * `billingType` - Billing type * `workScheduleId` - Id of work schedule assigned to task * `effortAllocation` - Effort Allocation * `responsiblePlaceholderIds` - List of placeholder assignee IDs
]: nothing -> record<data: table<metadata: list, importance: string, customFields: list, followerIds: list, parentIds: list, description: string, responsiblePlaceholderIds: list, updatedDate: string, title: string, followedByMe: bool, billingType: string, scope: string, id: string, effortAllocation: record, hasAttachments: bool, subTaskIds: list, recurrent: bool, authorIds: list, responsibleIds: list, customItemTypeId: string, sharedIds: list, dates: record, superTaskIds: list, priority: string, completedDate: string, superParentIds: list, accountId: string, dependencyIds: list, createdDate: string, cascadingFieldSettings: list, customStatusId: string, attachmentCount: float, workScheduleId: string, permalink: string, briefDescription: string, finance: record, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "importance" $importance "scalar") (serialize-qp "dates" $dates "scalar") (serialize-qp "addParents" $addParents "scalar") (serialize-qp "removeParents" $removeParents "scalar") (serialize-qp "addShareds" $addShareds "scalar") (serialize-qp "removeShareds" $removeShareds "scalar") (serialize-qp "addResponsibles" $addResponsibles "scalar") (serialize-qp "removeResponsibles" $removeResponsibles "scalar") (serialize-qp "addResponsiblePlaceholders" $addResponsiblePlaceholders "scalar") (serialize-qp "removeResponsiblePlaceholders" $removeResponsiblePlaceholders "scalar") (serialize-qp "addFollowers" $addFollowers "scalar") (serialize-qp "follow" $follow "scalar") (serialize-qp "priorityBefore" $priorityBefore "scalar") (serialize-qp "priorityAfter" $priorityAfter "scalar") (serialize-qp "addSuperTasks" $addSuperTasks "scalar") (serialize-qp "removeSuperTasks" $removeSuperTasks "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "customFields" $customFields "scalar") (serialize-qp "customStatus" $customStatus "scalar") (serialize-qp "restore" $restore "scalar") (serialize-qp "effortAllocation" $effortAllocation "scalar") (serialize-qp "setResponsibleAllocation" $setResponsibleAllocation "scalar") (serialize-qp "billingType" $billingType "scalar") (serialize-qp "withInvitations" $withInvitations "scalar") (serialize-qp "convertToCustomItemType" $convertToCustomItemType "scalar") (serialize-qp "plainTextCustomFields" $plainTextCustomFields "scalar") (serialize-qp "workScheduleId" $workScheduleId "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Tasks By ID
#
# DELETE /tasks/{taskId}
# operationId: DELETE:/tasks/single
export def "tasks DELETE:/tasks/single" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<metadata: list, importance: string, customFields: list, followerIds: list, parentIds: list, description: string, responsiblePlaceholderIds: list, updatedDate: string, title: string, followedByMe: bool, billingType: string, scope: string, id: string, effortAllocation: record, hasAttachments: bool, subTaskIds: list, recurrent: bool, authorIds: list, responsibleIds: list, customItemTypeId: string, sharedIds: list, dates: record, superTaskIds: list, priority: string, completedDate: string, superParentIds: list, accountId: string, dependencyIds: list, createdDate: string, cascadingFieldSettings: list, customStatusId: string, attachmentCount: float, workScheduleId: string, permalink: string, briefDescription: string, finance: record, status: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Timelog categories
#
# GET /timelog_categories
# operationId: GET:/timelog_categories/empty
export def "timelog-categories categories/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<hidden: bool, name: string, id: string, order: float>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/timelog_categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timelog Locks (Folder)
#
# GET /folders/{folderId}/timelog_lock_periods
# operationId: GET:/folders/single/timelog_lock_periods
export def "folders-timelog-lock-periods periods-by-folderId" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string # Dates (from, to, a specific day) for which you want to get lock periods. If no 'period' param was found in the request we will try to find lock periods for 1 year (6 months in the past and 6 months in the future from the current date)
]: nothing -> record<data: table<start: string, end: string, source: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/timelog_lock_periods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Timelog Lock (Folder)
#
# POST /folders/{folderId}/timelog_lock_periods
# operationId: POST:/folders/single/timelog_lock_periods
export def "folders-timelog-lock-periods periods-by-folderId-1" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string # Date range to lock (from, to, or a specific day).
]: nothing -> record<data: table<start: string, end: string, source: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/timelog_lock_periods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Timelog Lock (Folder)
#
# DELETE /folders/{folderId}/timelog_lock_periods
# operationId: DELETE:/folders/single/timelog_lock_periods
export def "folders-timelog-lock-periods periods-by-folderId-2" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string # Date range to unlock (from, to, or a specific day).
]: nothing -> record<data: table<start: string, end: string, source: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/timelog_lock_periods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timelog Locks (Task)
#
# GET /tasks/{taskId}/timelog_lock_periods
# operationId: GET:/tasks/single/timelog_lock_periods
export def "tasks-timelog-lock-periods periods" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string # Dates (from, to, a specific day) for which you want to get lock periods. If no 'period' param was found in the request we will try to find lock periods for 1 year (6 months in the past and 6 months in the future from the current date)
]: nothing -> record<data: table<start: string, end: string, source: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/timelog_lock_periods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timelog Locks (Space)
#
# GET /spaces/{spaceId}/timelog_lock_periods
# operationId: GET:/spaces/single/timelog_lock_periods
export def "spaces-timelog-lock-periods periods-by-spaceId" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string # Dates (from, to, a specific day) for which you want to get lock periods. If no 'period' param was found in the request we will try to find lock periods for 1 year (6 months in the past and 6 months in the future from the current date)
]: nothing -> record<data: table<start: string, end: string, source: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/timelog_lock_periods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Timelog Lock (Space)
#
# POST /spaces/{spaceId}/timelog_lock_periods
# operationId: POST:/spaces/single/timelog_lock_periods
export def "spaces-timelog-lock-periods periods-by-spaceId-1" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string # Date range to lock (from, to, or a specific day).
]: nothing -> record<data: table<start: string, end: string, source: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/timelog_lock_periods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Timelog Lock (Space)
#
# DELETE /spaces/{spaceId}/timelog_lock_periods
# operationId: DELETE:/spaces/single/timelog_lock_periods
export def "spaces-timelog-lock-periods periods-by-spaceId-2" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string # Date range to unlock (from, to, or a specific day).
]: nothing -> record<data: table<start: string, end: string, source: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/timelog_lock_periods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timelogs (Account)
#
# GET /timelogs
# operationId: GET:/timelogs/empty
export def "timelogs GET:/timelogs/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdDate: string # Created date filter, exact match or range
  --updatedDate: string # Last updated date filter, exact match or range
  --trackedDate: string # Tracked date filter, exact match or range
  --me: oneof<nothing, bool> # If present - only timelogs created by current user are returned
  --descendants: oneof<nothing, bool> # Adds all descendant tasks to search scope (default: true)
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --timelogCategories: string # Get timelog records for specified categories. Limit : `1000`
  --exportStatuses: string # Get timelog records with specified export statuses * `NotExported` - Not Exported * `Exported` - Exported * `ReadyForExport` - Ready For Export
  --billingTypes: string # Billing type filter * `Billable` - Billable * `NonBillable` - Non-Billable
  --approvalStatuses: string # Approval status filter * `Draft` * `Approved` * `Rejected` * `Cancelled` * `Pending`
  --limit: float # Limit on number of returned timelogs
  --pageSize: float # Page size for pagination (1-1000 items per page). When not specified, all matching timelogs are returned in a single response. When specified, results are paginated and nextPageToken is provided for subsequent pages.
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case.
  --qp-fields: string # Json string array of optional fields to be included in the response model * `approvalStatus` - Timesheet approval status * `lockStatus` - Timelog lock status * `exportStatus` - Timelog export status field * `billingType` - Timelog billing type
]: nothing -> record<data: table<approvalStatus: string, hours: float, exportStatus: string, updatedDate: string, userId: string, createdDate: string, lockStatus: string, billingType: string, trackedDate: string, comment: string, id: string, taskId: string, categoryId: string, finance: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "trackedDate" $trackedDate "scalar") (serialize-qp "me" $me "scalar") (serialize-qp "descendants" $descendants "scalar") (serialize-qp "plainText" $plainText "scalar") (serialize-qp "timelogCategories" $timelogCategories "scalar") (serialize-qp "exportStatuses" $exportStatuses "scalar") (serialize-qp "billingTypes" $billingTypes "scalar") (serialize-qp "approvalStatuses" $approvalStatuses "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timelogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timelogs (User)
#
# GET /contacts/{contactId}/timelogs
# operationId: GET:/contacts/single/timelogs
export def "contacts-timelogs GET:/contacts/single/timelogs" [
  contactId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdDate: string # Created date filter, exact match or range
  --updatedDate: string # Last updated date filter, exact match or range
  --trackedDate: string # Tracked date filter, exact match or range
  --me: oneof<nothing, bool> # If present - only timelogs created by current user are returned
  --descendants: oneof<nothing, bool> # Adds all descendant tasks to search scope (default: true)
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --timelogCategories: string # Get timelog records for specified categories. Limit : `1000`
  --exportStatuses: string # Get timelog records with specified export statuses * `NotExported` - Not Exported * `Exported` - Exported * `ReadyForExport` - Ready For Export
  --billingTypes: string # Billing type filter * `Billable` - Billable * `NonBillable` - Non-Billable
  --approvalStatuses: string # Approval status filter * `Draft` * `Approved` * `Rejected` * `Cancelled` * `Pending`
  --limit: float # Limit on number of returned timelogs
  --pageSize: float # Page size for pagination (1-1000 items per page). When not specified, all matching timelogs are returned in a single response. When specified, results are paginated and nextPageToken is provided for subsequent pages.
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case.
  --qp-fields: string # Json string array of optional fields to be included in the response model * `approvalStatus` - Timesheet approval status * `lockStatus` - Timelog lock status * `exportStatus` - Timelog export status field * `billingType` - Timelog billing type * `finance` - Timelog Finance fields
]: nothing -> record<data: table<approvalStatus: string, hours: float, exportStatus: string, updatedDate: string, userId: string, createdDate: string, lockStatus: string, billingType: string, trackedDate: string, comment: string, id: string, taskId: string, categoryId: string, finance: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "trackedDate" $trackedDate "scalar") (serialize-qp "me" $me "scalar") (serialize-qp "descendants" $descendants "scalar") (serialize-qp "plainText" $plainText "scalar") (serialize-qp "timelogCategories" $timelogCategories "scalar") (serialize-qp "exportStatuses" $exportStatuses "scalar") (serialize-qp "billingTypes" $billingTypes "scalar") (serialize-qp "approvalStatuses" $approvalStatuses "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/($contactId)/timelogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timelogs (Folder)
#
# GET /folders/{folderId}/timelogs
# operationId: GET:/folders/single/timelogs
export def "folders-timelogs GET:/folders/single/timelogs" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdDate: string # Created date filter, exact match or range
  --updatedDate: string # Last updated date filter, exact match or range
  --trackedDate: string # Tracked date filter, exact match or range
  --me: oneof<nothing, bool> # If present - only timelogs created by current user are returned
  --descendants: oneof<nothing, bool> # Adds all descendant tasks to search scope (default: true)
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --timelogCategories: string # Get timelog records for specified categories. Limit : `1000`
  --exportStatuses: string # Get timelog records with specified export statuses * `NotExported` - Not Exported * `Exported` - Exported * `ReadyForExport` - Ready For Export
  --billingTypes: string # Billing type filter * `Billable` - Billable * `NonBillable` - Non-Billable
  --approvalStatuses: string # Approval status filter * `Draft` * `Approved` * `Rejected` * `Cancelled` * `Pending`
  --limit: float # Limit on number of returned timelogs
  --pageSize: float # Page size for pagination (1-1000 items per page). When not specified, all matching timelogs are returned in a single response. When specified, results are paginated and nextPageToken is provided for subsequent pages.
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case.
  --qp-fields: string # Json string array of optional fields to be included in the response model * `approvalStatus` - Timesheet approval status * `lockStatus` - Timelog lock status * `exportStatus` - Timelog export status field * `billingType` - Timelog billing type * `finance` - Timelog Finance fields
]: nothing -> record<data: table<approvalStatus: string, hours: float, exportStatus: string, updatedDate: string, userId: string, createdDate: string, lockStatus: string, billingType: string, trackedDate: string, comment: string, id: string, taskId: string, categoryId: string, finance: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "trackedDate" $trackedDate "scalar") (serialize-qp "me" $me "scalar") (serialize-qp "descendants" $descendants "scalar") (serialize-qp "plainText" $plainText "scalar") (serialize-qp "timelogCategories" $timelogCategories "scalar") (serialize-qp "exportStatuses" $exportStatuses "scalar") (serialize-qp "billingTypes" $billingTypes "scalar") (serialize-qp "approvalStatuses" $approvalStatuses "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folderId)/timelogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timelogs (Task)
#
# GET /tasks/{taskId}/timelogs
# operationId: GET:/tasks/single/timelogs
export def "tasks-timelogs GET:/tasks/single/timelogs" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdDate: string # Created date filter, exact match or range
  --updatedDate: string # Last updated date filter, exact match or range
  --trackedDate: string # Tracked date filter, exact match or range
  --me: oneof<nothing, bool> # If present - only timelogs created by current user are returned
  --descendants: oneof<nothing, bool> # Adds all descendant tasks to search scope (default: true)
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --timelogCategories: string # Get timelog records for specified categories. Limit : `1000`
  --exportStatuses: string # Get timelog records with specified export statuses * `NotExported` - Not Exported * `Exported` - Exported * `ReadyForExport` - Ready For Export
  --billingTypes: string # Billing type filter * `Billable` - Billable * `NonBillable` - Non-Billable
  --approvalStatuses: string # Approval status filter * `Draft` * `Approved` * `Rejected` * `Cancelled` * `Pending`
  --limit: float # Limit on number of returned timelogs
  --pageSize: float # Page size for pagination (1-1000 items per page). When not specified, all matching timelogs are returned in a single response. When specified, results are paginated and nextPageToken is provided for subsequent pages.
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case.
  --qp-fields: string # Json string array of optional fields to be included in the response model * `approvalStatus` - Timesheet approval status * `lockStatus` - Timelog lock status * `exportStatus` - Timelog export status field * `billingType` - Timelog billing type * `finance` - Timelog Finance fields
]: nothing -> record<data: table<approvalStatus: string, hours: float, exportStatus: string, updatedDate: string, userId: string, createdDate: string, lockStatus: string, billingType: string, trackedDate: string, comment: string, id: string, taskId: string, categoryId: string, finance: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "trackedDate" $trackedDate "scalar") (serialize-qp "me" $me "scalar") (serialize-qp "descendants" $descendants "scalar") (serialize-qp "plainText" $plainText "scalar") (serialize-qp "timelogCategories" $timelogCategories "scalar") (serialize-qp "exportStatuses" $exportStatuses "scalar") (serialize-qp "billingTypes" $billingTypes "scalar") (serialize-qp "approvalStatuses" $approvalStatuses "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/timelogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Timelog
#
# POST /tasks/{taskId}/timelogs
# operationId: POST:/tasks/single/timelogs
export def "tasks-timelogs POST:/tasks/single/timelogs" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: string # Timelog record comment
  --hours: float # Time to log in hours
  --trackedDate: string # Date to register time Format: yyyy-MM-dd
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --categoryId: string # Timelog category
  --onBehalfOf: string # Create a time entry for another user
  --qp-fields: string # Json string array of optional fields to be included in the response model * `approvalStatus` - Timesheet approval status * `billingType` - Timelog billing type
]: nothing -> record<data: table<approvalStatus: string, hours: float, exportStatus: string, updatedDate: string, userId: string, createdDate: string, lockStatus: string, billingType: string, trackedDate: string, comment: string, id: string, taskId: string, categoryId: string, finance: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "comment" $comment "scalar") (serialize-qp "hours" $hours "scalar") (serialize-qp "trackedDate" $trackedDate "scalar") (serialize-qp "plainText" $plainText "scalar") (serialize-qp "categoryId" $categoryId "scalar") (serialize-qp "onBehalfOf" $onBehalfOf "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)/timelogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timelogs (Category)
#
# GET /timelog_categories/{timelogCategoryId}/timelogs
# operationId: GET:/timelog_categories/single/timelogs
export def "timelog-categories-timelogs categories/single/timelogs" [
  timelogCategoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdDate: string # Created date filter, exact match or range
  --updatedDate: string # Last updated date filter, exact match or range
  --trackedDate: string # Tracked date filter, exact match or range
  --me: oneof<nothing, bool> # If present - only timelogs created by current user are returned
  --descendants: oneof<nothing, bool> # Adds all descendant tasks to search scope (default: true)
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --timelogCategories: string # Get timelog records for specified categories. Limit : `1000`
  --exportStatuses: string # Get timelog records with specified export statuses * `NotExported` - Not Exported * `Exported` - Exported * `ReadyForExport` - Ready For Export
  --billingTypes: string # Billing type filter * `Billable` - Billable * `NonBillable` - Non-Billable
  --approvalStatuses: string # Approval status filter * `Draft` * `Approved` * `Rejected` * `Cancelled` * `Pending`
  --limit: float # Limit on number of returned timelogs
  --pageSize: float # Page size for pagination (1-1000 items per page). When not specified, all matching timelogs are returned in a single response. When specified, results are paginated and nextPageToken is provided for subsequent pages.
  --nextPageToken: string # A pagination request will return a token that applies an offset to the next page. The returned value should be used as an input parameter in the next request. Parameter pageSize can be omitted in this case.
  --qp-fields: string # Json string array of optional fields to be included in the response model * `approvalStatus` - Timesheet approval status * `lockStatus` - Timelog lock status * `exportStatus` - Timelog export status field * `billingType` - Timelog billing type * `finance` - Timelog Finance fields
]: nothing -> record<data: table<approvalStatus: string, hours: float, exportStatus: string, updatedDate: string, userId: string, createdDate: string, lockStatus: string, billingType: string, trackedDate: string, comment: string, id: string, taskId: string, categoryId: string, finance: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "updatedDate" $updatedDate "scalar") (serialize-qp "trackedDate" $trackedDate "scalar") (serialize-qp "me" $me "scalar") (serialize-qp "descendants" $descendants "scalar") (serialize-qp "plainText" $plainText "scalar") (serialize-qp "timelogCategories" $timelogCategories "scalar") (serialize-qp "exportStatuses" $exportStatuses "scalar") (serialize-qp "billingTypes" $billingTypes "scalar") (serialize-qp "approvalStatuses" $approvalStatuses "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/timelog_categories/($timelogCategoryId)/timelogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timelogs By ID
#
# GET /timelogs/{timelogIds}
# operationId: GET:/timelogs/multi
export def "timelogs GET:/timelogs/multi" [
  timelogIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --qp-fields: string # Json string array of optional fields to be included in the response model * `approvalStatus` - Timesheet approval status * `lockStatus` - Timelog lock status * `exportStatus` - Timelog export status field * `billingType` - Timelog billing type * `finance` - Timelog Finance fields
]: nothing -> record<data: table<approvalStatus: string, hours: float, exportStatus: string, updatedDate: string, userId: string, createdDate: string, lockStatus: string, billingType: string, trackedDate: string, comment: string, id: string, taskId: string, categoryId: string, finance: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "plainText" $plainText "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/timelogs/($timelogIds)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify Timelog
#
# PUT /timelogs/{timelogId}
# operationId: PUT:/timelogs/single
export def "timelogs PUT:/timelogs/single" [
  timelogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: string # Timelog comment
  --hours: float # New timelog tracked hours
  --trackedDate: string # New timelog date Format: yyyy-MM-dd
  --plainText: oneof<nothing, bool> # Get comment text as plain text, HTML otherwise (default: false)
  --categoryId: string # Timelog category
  --qp-fields: string # Json string array of optional fields to be included in the response model * `approvalStatus` - Timesheet approval status * `billingType` - Timelog billing type
]: nothing -> record<data: table<approvalStatus: string, hours: float, exportStatus: string, updatedDate: string, userId: string, createdDate: string, lockStatus: string, billingType: string, trackedDate: string, comment: string, id: string, taskId: string, categoryId: string, finance: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "comment" $comment "scalar") (serialize-qp "hours" $hours "scalar") (serialize-qp "trackedDate" $trackedDate "scalar") (serialize-qp "plainText" $plainText "scalar") (serialize-qp "categoryId" $categoryId "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/timelogs/($timelogId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Timelog
#
# DELETE /timelogs/{timelogId}
# operationId: DELETE:/timelogs/single
export def "timelogs DELETE:/timelogs/single" [
  timelogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: list<string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/timelogs/($timelogId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Timesheet Row
#
# PUT /timesheet_rows/{timesheetRowId}
# operationId: PUT:/timesheet_rows/single
export def "timesheet-rows rows/single" [
  timesheetRowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --categoryId: string # Category ID for the timesheet row
]: nothing -> record<data: table<parentIds: list, type: string, weeklyEntries: list, taskId: string, categoryId: string, rowId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryId" $categoryId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/timesheet_rows/($timesheetRowId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timesheet Submission Rules (Account)
#
# GET /timesheet_submission_rules
# operationId: GET:/timesheet_submission_rules/empty
export def "timesheet-submission-rules rules/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<trackExceptionsMode: string, ruleType: string, workScheduleId: string, enabled: bool, frequency: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/timesheet_submission_rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timesheet Submission Rules (Work Schedule)
#
# GET /workschedules/{workscheduleId}/timesheet_submission_rules
# operationId: GET:/workschedules/single/timesheet_submission_rules
export def "workschedules-timesheet-submission-rules rules-by-workscheduleId" [
  workscheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<trackExceptionsMode: string, ruleType: string, workScheduleId: string, enabled: bool, frequency: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workschedules/($workscheduleId)/timesheet_submission_rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Timesheet Submission Rules
#
# PUT /workschedules/{workscheduleId}/timesheet_submission_rules
# operationId: PUT:/workschedules/single/timesheet_submission_rules
export def "workschedules-timesheet-submission-rules rules-by-workscheduleId-1" [
  workscheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Switch to toggle on/off timesheet submission rule
  --ruleType: string@ruleType-completer # Type of timesheet submission rule * `Hard` - Hard * `Soft` - Soft
  --frequency: string@frequency-completer # Frequency for timesheet submission rule * `Month` - Week * `Week` - Week * `Day` - Day
  --trackExceptionsMode: string@trackExceptionsMode-completer # Track exceptions mode for timesheet submission rule * `TotalCapacity` - Total Capacity * `ActualCapacity` - Actual Capacity
]: nothing -> record<data: table<trackExceptionsMode: string, ruleType: string, workScheduleId: string, enabled: bool, frequency: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enabled" $enabled "scalar") (serialize-qp "ruleType" $ruleType "scalar") (serialize-qp "frequency" $frequency "scalar") (serialize-qp "trackExceptionsMode" $trackExceptionsMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workschedules/($workscheduleId)/timesheet_submission_rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Timesheets
#
# GET /timesheets
# operationId: GET:/timesheets/empty
export def "timesheets GET:/timesheets/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --periodStartDate: string # Returns timesheet for specified start date match or start date range filter
  --userIds: string # UserIds filter, match of any
  --approvalStatuses: string # Approval statuses filter, match of any
  --timeframes: string # Timeframes filter, match of any
]: nothing -> record<data: table<timesheetId: string, accountId: string, periodStartDate: string, timeframe: string, approval: record, rows: list, userId: string, periodEndDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodStartDate" $periodStartDate "scalar") (serialize-qp "userIds" $userIds "scalar") (serialize-qp "approvalStatuses" $approvalStatuses "scalar") (serialize-qp "timeframes" $timeframes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timesheets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Timesheet
#
# POST /timesheets
# operationId: POST:/timesheets/empty
export def "timesheets POST:/timesheets/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --periodStartDate: string # Timesheet period start date range (required)
  --userId: string # UserId for whom to create the timesheet
  --taskIds: string # Optional: TaskIds to create new rows
  --timeframe: string@timeframe-completer # Optional: Timeframe for the timesheet * `Monthly` * `Weekly`
]: nothing -> record<data: table<timesheetId: string, accountId: string, periodStartDate: string, timeframe: string, approval: record, rows: list, userId: string, periodEndDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodStartDate" $periodStartDate "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "taskIds" $taskIds "scalar") (serialize-qp "timeframe" $timeframe "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timesheets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Timesheet
#
# PUT /timesheets/{timesheetId}
# operationId: PUT:/timesheets/single
export def "timesheets PUT:/timesheets/single" [
  timesheetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --approvalStatus: string@approvalStatus-completer # Timesheet approval status * `NotSubmitted` * `Approved` * `Rejected` * `Pending`
]: nothing -> record<data: table<timesheetId: string, accountId: string, periodStartDate: string, timeframe: string, approval: record, rows: list, userId: string, periodEndDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "approvalStatus" $approvalStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/timesheets/($timesheetId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Work Schedule Capacity Changes (User)
#
# GET /user_schedule_capacity_change
# operationId: GET:/user_schedule_capacity_change/empty
export def "user-schedule-capacity-change change/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userIds: string # User IDs to query
  --dateRange: string # Date range to query
]: nothing -> record<data: table<finishDate: string, id: string, userId: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userIds" $userIds "scalar") (serialize-qp "dateRange" $dateRange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_schedule_capacity_change" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Work Schedule Capacity Change by ID
#
# GET /user_schedule_capacity_change/{userScheduleCapacityChangeIds}
# operationId: GET:/user_schedule_capacity_change/multi
export def "user-schedule-capacity-change change/multi" [
  userScheduleCapacityChangeIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<finishDate: string, id: string, userId: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_schedule_capacity_change/($userScheduleCapacityChangeIds)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User Schedule Capacity change
#
# POST /users/{userId}/user_schedule_capacity_change
# operationId: POST:/users/single/user_schedule_capacity_change
export def "users-user-schedule-capacity-change change" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # User ID
  --dateRange: string # Date range
  --capacityMinutes: float # Capacity in minutes
]: nothing -> record<data: table<finishDate: string, id: string, userId: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar") (serialize-qp "dateRange" $dateRange "scalar") (serialize-qp "capacityMinutes" $capacityMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/user_schedule_capacity_change" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Schedule Capacity change
#
# PUT /user_schedule_capacity_change/{userScheduleCapacityChangeId}
# operationId: PUT:/user_schedule_capacity_change/single
export def "user-schedule-capacity-change change/single-by-userScheduleCapacityChangeId" [
  userScheduleCapacityChangeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateRange: string # Date range
  --capacityMinutes: float # Capacity in minutes
]: nothing -> record<data: table<finishDate: string, id: string, userId: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateRange" $dateRange "scalar") (serialize-qp "capacityMinutes" $capacityMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_schedule_capacity_change/($userScheduleCapacityChangeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete User Schedule Capacity change
#
# DELETE /user_schedule_capacity_change/{userScheduleCapacityChangeId}
# operationId: DELETE:/user_schedule_capacity_change/single
export def "user-schedule-capacity-change change/single-by-userScheduleCapacityChangeId-1" [
  userScheduleCapacityChangeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: list<string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_schedule_capacity_change/($userScheduleCapacityChangeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query User Schedule exception
#
# GET /user_schedule_exclusions
# operationId: GET:/user_schedule_exclusions/empty
export def "user-schedule-exclusions exclusions/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateRange: string # Query exceptions for given date range
  --userIds: string # Query exceptions for given user ids. Limit : `100000`
]: nothing -> record<data: table<fromDate: string, isWorkDays: bool, toDate: string, exclusionType: string, id: string, userId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateRange" $dateRange "scalar") (serialize-qp "userIds" $userIds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_schedule_exclusions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User Schedule exception
#
# POST /user_schedule_exclusions
# operationId: POST:/user_schedule_exclusions/empty
export def "user-schedule-exclusions exclusions/empty-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # User id to add new exception
  --fromDate: string # New exception from date Format: yyyy-MM-dd
  --toDate: string # New exception to date Format: yyyy-MM-dd
  --exclusionType: string@exclusionType-completer # Type of new exception * `VacationPTO` - Paid vacations * `Overtime` - Additional working days * `OtherNonWorking` - Other non-working days
]: nothing -> record<data: table<fromDate: string, isWorkDays: bool, toDate: string, exclusionType: string, id: string, userId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar") (serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "exclusionType" $exclusionType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_schedule_exclusions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query User Schedule exception
#
# GET /user_schedule_exclusions/{userScheduleExclusionId}
# operationId: GET:/user_schedule_exclusions/single
export def "user-schedule-exclusions exclusions/single-by-userScheduleExclusionId" [
  userScheduleExclusionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<fromDate: string, isWorkDays: bool, toDate: string, exclusionType: string, id: string, userId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_schedule_exclusions/($userScheduleExclusionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Schedule exception
#
# PUT /user_schedule_exclusions/{userScheduleExclusionId}
# operationId: PUT:/user_schedule_exclusions/single
export def "user-schedule-exclusions exclusions/single-by-userScheduleExclusionId-1" [
  userScheduleExclusionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromDate: string # Exception from date Format: yyyy-MM-dd
  --toDate: string # Exception to date Format: yyyy-MM-dd
  --exclusionType: string@exclusionType-completer # Type of exception * `VacationPTO` - Paid vacations * `Overtime` - Additional working days * `OtherNonWorking` - Other non-working days
]: nothing -> record<data: table<fromDate: string, isWorkDays: bool, toDate: string, exclusionType: string, id: string, userId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "exclusionType" $exclusionType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_schedule_exclusions/($userScheduleExclusionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete User Schedule exception
#
# DELETE /user_schedule_exclusions/{userScheduleExclusionId}
# operationId: DELETE:/user_schedule_exclusions/single
export def "user-schedule-exclusions exclusions/single-by-userScheduleExclusionId-2" [
  userScheduleExclusionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<fromDate: string, isWorkDays: bool, toDate: string, exclusionType: string, id: string, userId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_schedule_exclusions/($userScheduleExclusionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query User Schedule partial exceptions
#
# GET /user_schedule_partial_exclusion
# operationId: GET:/user_schedule_partial_exclusion/empty
export def "user-schedule-partial-exclusion exclusion/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userIds: string # User IDs to query
  --dateRange: string # Date range to query
]: nothing -> record<data: table<exclusionType: string, finishDate: string, id: string, userId: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userIds" $userIds "scalar") (serialize-qp "dateRange" $dateRange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_schedule_partial_exclusion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User Schedule partial exception
#
# POST /user_schedule_partial_exclusion
# operationId: POST:/user_schedule_partial_exclusion/empty
export def "user-schedule-partial-exclusion exclusion/empty-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # User id
  --dateRange: string # Date range
  --exclusionType: string@exclusionType-completer-1 # Exclusion type * `VacationPTO` - Vacation or paid time off * `OtherNonWorking` - Other non-working time
  --capacityMinutes: float # Capacity minutes
]: nothing -> record<data: table<exclusionType: string, finishDate: string, id: string, userId: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar") (serialize-qp "dateRange" $dateRange "scalar") (serialize-qp "exclusionType" $exclusionType "scalar") (serialize-qp "capacityMinutes" $capacityMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_schedule_partial_exclusion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query User Schedule partial exceptions
#
# GET /user_schedule_partial_exclusion/{userSchedulePartialExclusionIds}
# operationId: GET:/user_schedule_partial_exclusion/multi
export def "user-schedule-partial-exclusion exclusion/multi" [
  userSchedulePartialExclusionIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<exclusionType: string, finishDate: string, id: string, userId: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_schedule_partial_exclusion/($userSchedulePartialExclusionIds)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Schedule partial exception
#
# PUT /user_schedule_partial_exclusion/{userSchedulePartialExclusionId}
# operationId: PUT:/user_schedule_partial_exclusion/single
export def "user-schedule-partial-exclusion exclusion/single-by-userSchedulePartialExclusionId" [
  userSchedulePartialExclusionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateRange: string # Date range
  --exclusionType: string@exclusionType-completer-1 # Exclusion type * `VacationPTO` - Vacation or paid time off * `OtherNonWorking` - Other non-working time
  --capacityMinutes: float # Capacity minutes
]: nothing -> record<data: table<exclusionType: string, finishDate: string, id: string, userId: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateRange" $dateRange "scalar") (serialize-qp "exclusionType" $exclusionType "scalar") (serialize-qp "capacityMinutes" $capacityMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_schedule_partial_exclusion/($userSchedulePartialExclusionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete User Schedule partial exception
#
# DELETE /user_schedule_partial_exclusion/{userSchedulePartialExclusionId}
# operationId: DELETE:/user_schedule_partial_exclusion/single
export def "user-schedule-partial-exclusion exclusion/single-by-userSchedulePartialExclusionId-1" [
  userSchedulePartialExclusionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: list<string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_schedule_partial_exclusion/($userSchedulePartialExclusionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Types
#
# GET /user_types
# operationId: GET:/user_types/empty
export def "user-types types/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<description: string, id: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query User
#
# GET /users/{userId}
# operationId: GET:/users/single
export def "users GET:/users/single" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<userTypeId: string, lastName: string, metadata: list, avatarUrl: string, timezone: string, companyName: string, profiles: list, type: string, locale: string, title: string, firstName: string, deleted: bool, phone: string, me: bool, myTeam: bool, location: string, id: string, memberIds: list, primaryEmail: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify User
#
# PUT /users/{userId}
# operationId: PUT:/users/single
export def "users PUT:/users/single" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --profile: string # [Deprecated] It is recommended to use 'userTypeId' parameter instead. Profile to be updated. Mutually exclusive with other params
  --userTypeId: string # Change user type of user in account. Mutually exclusive with other params
  --active: oneof<nothing, bool> # Activate or deactivate user. Mutually exclusive with other params
]: nothing -> record<data: table<userTypeId: string, lastName: string, metadata: list, avatarUrl: string, timezone: string, companyName: string, profiles: list, type: string, locale: string, title: string, firstName: string, deleted: bool, phone: string, me: bool, myTeam: bool, location: string, id: string, memberIds: list, primaryEmail: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "profile" $profile "scalar") (serialize-qp "userTypeId" $userTypeId "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify User
#
# PUT /users/{userIds}
# operationId: PUT:/users/multi
export def "users PUT:/users/multi" [
  userIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # Activate or deactivate user. Mutually exclusive with other params
]: nothing -> record<data: table<userTypeId: string, lastName: string, metadata: list, avatarUrl: string, timezone: string, companyName: string, profiles: list, type: string, locale: string, title: string, firstName: string, deleted: bool, phone: string, me: bool, myTeam: bool, location: string, id: string, memberIds: list, primaryEmail: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userIds)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API Version
#
# GET /version
# operationId: GET:/version/empty
export def "version GET:/version/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<major: float, minor: float>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Work Schedule Capacity Changes by Change ID
#
# GET /workschedule_capacity_change/{workscheduleCapacityChangeIds}
# operationId: GET:/workschedule_capacity_change/multi
export def "workschedule-capacity-change change/multi" [
  workscheduleCapacityChangeIds: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<workScheduleId: string, finishDate: string, id: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workschedule_capacity_change/($workscheduleCapacityChangeIds)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Work Schedule Capacity Changes (Work Schedule)
#
# GET /workschedules/{workscheduleId}/workschedule_capacity_change
# operationId: GET:/workschedules/single/workschedule_capacity_change
export def "workschedules-workschedule-capacity-change change-by-workscheduleId" [
  workscheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateRange: string # Date range to query
]: nothing -> record<data: table<workScheduleId: string, finishDate: string, id: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateRange" $dateRange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workschedules/($workscheduleId)/workschedule_capacity_change" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Work Schedule capacity change
#
# POST /workschedules/{workscheduleId}/workschedule_capacity_change
# operationId: POST:/workschedules/single/workschedule_capacity_change
export def "workschedules-workschedule-capacity-change change-by-workscheduleId-1" [
  workscheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateRange: string # Date range
  --capacityMinutes: float # Capacity in minutes
]: nothing -> record<data: table<workScheduleId: string, finishDate: string, id: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateRange" $dateRange "scalar") (serialize-qp "capacityMinutes" $capacityMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workschedules/($workscheduleId)/workschedule_capacity_change" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Work Schedule capacity change
#
# PUT /workschedule_capacity_change/{workscheduleCapacityChangeId}
# operationId: PUT:/workschedule_capacity_change/single
export def "workschedule-capacity-change change/single-by-workscheduleCapacityChangeId" [
  workscheduleCapacityChangeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateRange: string # Date range
  --capacityMinutes: float # Capacity in minutes
]: nothing -> record<data: table<workScheduleId: string, finishDate: string, id: string, capacityMinutes: float, startDate: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateRange" $dateRange "scalar") (serialize-qp "capacityMinutes" $capacityMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workschedule_capacity_change/($workscheduleCapacityChangeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Work Schedule capacity change
#
# DELETE /workschedule_capacity_change/{workscheduleCapacityChangeId}
# operationId: DELETE:/workschedule_capacity_change/single
export def "workschedule-capacity-change change/single-by-workscheduleCapacityChangeId-1" [
  workscheduleCapacityChangeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: list<string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workschedule_capacity_change/($workscheduleCapacityChangeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Work Schedule Exception by ID
#
# GET /workschedule_exclusions/{workscheduleExclusionId}
# operationId: GET:/workschedule_exclusions/single
export def "workschedule-exclusions exclusions/single-by-workscheduleExclusionId" [
  workscheduleExclusionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<fromDate: string, isWorkDays: bool, toDate: string, exclusionType: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workschedule_exclusions/($workscheduleExclusionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Work Schedule exception
#
# PUT /workschedule_exclusions/{workscheduleExclusionId}
# operationId: PUT:/workschedule_exclusions/single
export def "workschedule-exclusions exclusions/single-by-workscheduleExclusionId-1" [
  workscheduleExclusionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromDate: string # Exception from date Format: yyyy-MM-dd
  --toDate: string # Exception to date Format: yyyy-MM-dd
  --exclusionType: string@exclusionType-completer-2 # Type of exception * `PublicHolidays` - Non-working days because of public holidays * `OtherEvent` - Non-working days because of some company or private event * `AdditionalWorkDays` - Additional working days, i.e. during weekends
]: nothing -> record<data: table<fromDate: string, isWorkDays: bool, toDate: string, exclusionType: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "exclusionType" $exclusionType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workschedule_exclusions/($workscheduleExclusionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Work Schedule exception
#
# DELETE /workschedule_exclusions/{workscheduleExclusionId}
# operationId: DELETE:/workschedule_exclusions/single
export def "workschedule-exclusions exclusions/single-by-workscheduleExclusionId-2" [
  workscheduleExclusionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<fromDate: string, isWorkDays: bool, toDate: string, exclusionType: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workschedule_exclusions/($workscheduleExclusionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Work Schedule Exceptions (Work Schedule)
#
# GET /workschedules/{workscheduleId}/workschedule_exclusions
# operationId: GET:/workschedules/single/workschedule_exclusions
export def "workschedules-workschedule-exclusions exclusions-by-workscheduleId" [
  workscheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateRange: string # Date range to query exceptions
]: nothing -> record<data: table<fromDate: string, isWorkDays: bool, toDate: string, exclusionType: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateRange" $dateRange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workschedules/($workscheduleId)/workschedule_exclusions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Work Schedule exception
#
# POST /workschedules/{workscheduleId}/workschedule_exclusions
# operationId: POST:/workschedules/single/workschedule_exclusions
export def "workschedules-workschedule-exclusions exclusions-by-workscheduleId-1" [
  workscheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromDate: string # New exception from date Format: yyyy-MM-dd
  --toDate: string # New exception to date Format: yyyy-MM-dd
  --exclusionType: string@exclusionType-completer-2 # Type of new exception * `PublicHolidays` - Non-working days because of public holidays * `OtherEvent` - Non-working days because of some company or private event * `AdditionalWorkDays` - Additional working days, i.e. during weekends
]: nothing -> record<data: table<fromDate: string, isWorkDays: bool, toDate: string, exclusionType: string, id: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "exclusionType" $exclusionType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workschedules/($workscheduleId)/workschedule_exclusions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Work Schedules
#
# GET /workschedules
# operationId: GET:/workschedules/empty
export def "workschedules GET:/workschedules/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Json string array of optional fields to be included in the response model * `userIds` - Users assigned to WorkSchedule
]: nothing -> record<data: table<scheduleType: string, workweek: list, userIds: list, id: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workschedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Work Schedule
#
# POST /workschedules
# operationId: POST:/workschedules/empty
export def "workschedules POST:/workschedules/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Name of schedule
  --workweek: string # Work week: working and non-working days. Limit : `7`
  --addUsers: string # User ids to assign to the schedule. Limit : `100000`
  --capacityMinutes: float # Custom capacity in minutes
  --qp-fields: string # Json string array of optional fields to be included in the response model * `userIds` - Users assigned to WorkSchedule
]: nothing -> record<data: table<scheduleType: string, workweek: list, userIds: list, id: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "workweek" $workweek "scalar") (serialize-qp "addUsers" $addUsers "scalar") (serialize-qp "capacityMinutes" $capacityMinutes "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workschedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Work Schedules
#
# GET /workschedules/{workscheduleId}
# operationId: GET:/workschedules/single
export def "workschedules GET:/workschedules/single" [
  workscheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Json string array of optional fields to be included in the response model * `userIds` - Users assigned to WorkSchedule
]: nothing -> record<data: table<scheduleType: string, workweek: list, userIds: list, id: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workschedules/($workscheduleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Work Schedule
#
# PUT /workschedules/{workscheduleId}
# operationId: PUT:/workschedules/single
export def "workschedules PUT:/workschedules/single" [
  workscheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Name of work schedule
  --workweek: string # Work week: working and non-working days. Limit : `7`
  --addUsers: string # User ids to assign to the schedule. Limit : `100000`
  --removeUsers: string # User ids to unassign from the schedule
  --capacityMinutes: float # Custom capacity in minutes
  --qp-fields: string # Json string array of optional fields to be included in the response model * `userIds` - Users assigned to WorkSchedule
]: nothing -> record<data: table<scheduleType: string, workweek: list, userIds: list, id: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "workweek" $workweek "scalar") (serialize-qp "addUsers" $addUsers "scalar") (serialize-qp "removeUsers" $removeUsers "scalar") (serialize-qp "capacityMinutes" $capacityMinutes "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workschedules/($workscheduleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Work Schedule
#
# DELETE /workschedules/{workscheduleId}
# operationId: DELETE:/workschedules/single
export def "workschedules DELETE:/workschedules/single" [
  workscheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<scheduleType: string, workweek: list, userIds: list, id: string, title: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workschedules/($workscheduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Workflows
#
# GET /workflows
# operationId: GET:/workflows/empty
export def "workflows GET:/workflows/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Json string array of optional fields to be included in the response model * `dataUsageStatistics` - Return collection of data usage statistics
]: nothing -> record<data: table<standard: bool, hidden: bool, customStatuses: list, name: string, description: string, id: string, dataUsageStatistics: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Workflow
#
# POST /workflows
# operationId: POST:/workflows/empty
export def "workflows POST:/workflows/empty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of workflow, required
  --description: string # Description of workflow
]: nothing -> record<data: table<standard: bool, hidden: bool, customStatuses: list, name: string, description: string, id: string, dataUsageStatistics: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Workflows
#
# GET /spaces/{spaceId}/workflows
# operationId: GET:/spaces/single/workflows
export def "spaces-workflows GET:/spaces/single/workflows" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Json string array of optional fields to be included in the response model * `dataUsageStatistics` - Return collection of data usage statistics
]: nothing -> record<data: table<standard: bool, hidden: bool, customStatuses: list, name: string, description: string, id: string, dataUsageStatistics: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify Workflow
#
# PUT /workflows/{workflowId}
# operationId: PUT:/workflows/single
export def "workflows PUT:/workflows/single" [
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of workflow (128 symbols max)
  --description: string # Description of workflow (2000 symbols max)
  --hidden: oneof<nothing, bool> # Workflow is hidden
  --customStatus: string # Custom status
]: nothing -> record<data: table<standard: bool, hidden: bool, customStatuses: list, name: string, description: string, id: string, dataUsageStatistics: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "hidden" $hidden "scalar") (serialize-qp "customStatus" $customStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workflows/($workflowId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
