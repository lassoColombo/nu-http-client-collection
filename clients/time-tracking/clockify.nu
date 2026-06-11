# Auto-generated client for Clockify API vv1
# Source: https://docs.clockify.me/openapi.json
# Auth: --token flag or $env.CLOCKIFY_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "x-addon-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOCKIFY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-addon-token" => { {headers: {x-addon-token: $token_val}, query: ""} }
    "x-api-key" => { {headers: {x-api-key: $token_val}, query: ""} }
    "x-marketplace-token" => { {headers: {x-marketplace-token: $token_val}, query: ""} }
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
def base-url-completer [] { ["http://localhost" "https://api.clockify.me/api" "https://reports.api.clockify.me" "https://auditlog-api.api.clockify.me"] }
def auth-scheme-completer [] { ["x-addon-token" "x-api-key" "x-marketplace-token"] }

# Completers for enum parameters
def roles-completer [] { ["OWNER" "PROJECT_MANAGER" "TEAM_MANAGER" "WORKSPACE_ADMIN"] }
def status-completer [] { ["APPROVED" "PENDING" "WITHDRAWN_APPROVAL"] }
def sort-column-completer [] { ["ID" "START" "UPDATED_AT" "USER_ID"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def period-completer [] { ["MONTHLY" "SEMI_MONTHLY" "WEEKLY"] }
def state-completer [] { ["APPROVED" "PENDING" "REJECTED" "WITHDRAWN_APPROVAL" "WITHDRAWN_SUBMISSION"] }
def status-completer-1 [] { ["INACTIVE" "INVISIBLE" "VISIBLE"] }
def entityType-completer [] { ["TIMEENTRY" "USER"] }
def type-completer [] { ["CHECKBOX" "DROPDOWN_MULTIPLE" "DROPDOWN_SINGLE" "LINK" "NUMBER" "TXT"] }
def sort-column-completer-1 [] { ["NAME"] }
def statuses-completer [] { ["OVERDUE" "PAID" "PARTIALLY_PAID" "SENT" "UNSENT" "VOID"] }
def sort-column-completer-2 [] { ["AMOUNT" "BALANCE" "CLIENT" "DUE_ON" "ID" "ISSUE_DATE"] }
def timeViewMode-completer [] { ["AGGREGATED_TIME_VIEW" "TIME_SENSITIVE_VIEW"] }
def sortColumn-completer [] { ["AMOUNT" "BALANCE" "CLIENT" "DUE_ON" "ID" "ISSUE_DATE"] }
def sortOrder-completer [] { ["ASCENDING" "DESCENDING"] }
def visibleZeroFields-completer [] { ["DISCOUNT" "TAX" "TAX_2"] }
def applyTaxes-completer [] { ["NONE" "TAX1" "TAX1TAX2" "TAX2"] }
def expensesGroupBy-completer [] { ["CATEGORY" "PROJECT" "USER"] }
def expensesGroupType-completer [] { ["DETAILED" "GROUPED"] }
def timeEntryGroupType-completer [] { ["DETAILED" "GROUPED" "SINGLE_ITEM"] }
def timeEntryPrimaryGroupBy-completer [] { ["DATE" "PROJECT" "USER"] }
def timeEntrySecondaryGroupBy-completer [] { ["DATE" "DESCRIPTION" "NONE" "PROJECT" "TASK" "USER"] }
def invoiceStatus-completer [] { ["OVERDUE" "PAID" "PARTIALLY_PAID" "SENT" "UNSENT" "VOID"] }
def weekStart-completer [] { ["FRIDAY" "MONDAY" "SATURDAY" "SUNDAY" "THURSDAY" "TUESDAY" "WEDNESDAY"] }
def workingDays-completer [] { ["FRIDAY" "MONDAY" "SATURDAY" "SUNDAY" "THURSDAY" "TUESDAY" "WEDNESDAY"] }
def client-status-completer [] { ["ACTIVE" "ALL" "ARCHIVED"] }
def user-status-completer [] { ["ACTIVE" "ALL" "DECLINED" "INACTIVE" "PENDING"] }
def sort-column-completer-3 [] { ["BUDGET" "CLIENT_NAME" "DURATION" "ID" "NAME" "PROGRESS"] }
def access-completer [] { ["PRIVATE" "PUBLIC"] }
def sort-column-completer-4 [] { ["ID" "NAME"] }
def status-completer-2 [] { ["ACTIVE" "ALL" "DONE"] }
def membership-status-completer [] { ["ACTIVE" "ALL" "DECLINED" "INACTIVE" "PENDING"] }
def sort-column-completer-5 [] { ["ID" "PROJECT" "USER"] }
def statusFilter-completer [] { ["ALL" "PUBLISHED" "UNPUBLISHED"] }
def viewType-completer [] { ["ALL" "PROJECTS" "TEAM"] }
def seriesUpdateOption-completer [] { ["ALL" "THIS_AND_FOLLOWING" "THIS_ONE"] }
def type-completer-1 [] { ["BREAK" "REGULAR"] }
def sort-completer [] { ["BALANCE" "POLICY" "TOTAL" "USED" "USER"] }
def status-completer-3 [] { ["ACTIVE" "ALL" "ARCHIVED"] }
def icon-completer [] { ["CALENDAR" "CHILDCARE" "FAMILY" "HEALTH_METRICS" "LUGGAGE" "MONETIZATION" "PLANE" "SNOWFLAKE" "STETHOSCOPE" "UMBRELLA"] }
def timeUnit-completer [] { ["DAYS" "HOURS"] }
def status-completer-4 [] { ["APPROVED" "REJECTED"] }
def status-completer-5 [] { ["ACTIVE" "ALL" "DECLINED" "INACTIVE" "PENDING"] }
def sort-column-completer-6 [] { ["ACCESS" "COSTRATE" "EMAIL" "HOURLYRATE" "ID" "NAME" "NAME_LOWERCASE"] }
def memberships-completer [] { ["ALL" "NONE" "PROJECT" "USERGROUP" "WORKSPACE"] }
def sortColumn-completer-1 [] { ["ACCESS" "COSTRATE" "EMAIL" "HOURLYRATE" "ID" "NAME" "NAME_LOWERCASE"] }
def status-completer-6 [] { ["ACTIVE" "INACTIVE"] }
def role-completer [] { ["PROJECT_MANAGER" "TEAM_MANAGER" "WORKSPACE_ADMIN"] }
def sourceType-completer [] { ["USER_GROUP"] }
def type-completer-2 [] { ["ADDON" "SYSTEM" "USER_CREATED"] }
def triggerSourceType-completer [] { ["ASSIGNMENT_ID" "EXPENSE_ID" "PROJECT_ID" "TAG_ID" "TASK_ID" "USER_ID" "WORKSPACE_ID"] }
def webhookEvent-completer [] { ["APPROVAL_REQUEST_STATUS_UPDATED" "ASSIGNMENT_CREATED" "ASSIGNMENT_DELETED" "ASSIGNMENT_PUBLISHED" "ASSIGNMENT_UPDATED" "BALANCE_UPDATED" "BILLABLE_RATE_UPDATED" "CLIENT_DELETED" "CLIENT_UPDATED" "COST_RATE_UPDATED" "EXPENSE_CREATED" "EXPENSE_DELETED" "EXPENSE_RESTORED" "EXPENSE_UPDATED" "INVOICE_UPDATED" "LIMITED_USERS_ADDED_TO_WORKSPACE" "NEW_APPROVAL_REQUEST" "NEW_CLIENT" "NEW_INVOICE" "NEW_PROJECT" "NEW_TAG" "NEW_TASK" "NEW_TIMER_STARTED" "NEW_TIME_ENTRY" "PROJECT_DELETED" "PROJECT_UPDATED" "TAG_DELETED" "TAG_UPDATED" "TASK_DELETED" "TASK_UPDATED" "TIMER_STOPPED" "TIME_ENTRY_DELETED" "TIME_ENTRY_RESTORED" "TIME_ENTRY_SPLIT" "TIME_ENTRY_UPDATED" "TIME_OFF_REQUESTED" "TIME_OFF_REQUEST_APPROVED" "TIME_OFF_REQUEST_REJECTED" "TIME_OFF_REQUEST_STARTED" "TIME_OFF_REQUEST_UPDATED" "TIME_OFF_REQUEST_WITHDRAWN" "USERS_INVITED_TO_WORKSPACE" "USER_ACTIVATED_ON_WORKSPACE" "USER_DEACTIVATED_ON_WORKSPACE" "USER_DELETED_FROM_WORKSPACE" "USER_EMAIL_CHANGED" "USER_GROUP_CREATED" "USER_GROUP_DELETED" "USER_GROUP_UPDATED" "USER_JOINED_WORKSPACE" "USER_UPDATED"] }
def status-completer-7 [] { ["ALL" "FAILED" "SUCCEEDED"] }
def statuses-completer-1 [] { ["FAILED" "RETRYING" "SUCCEEDED"] }
def amountShown-completer [] { ["COST" "EARNED" "EXPORT" "HIDE_AMOUNT" "PROFIT"] }
def approvalState-completer [] { ["ALL" "APPROVED" "UNAPPROVED"] }
def dateRangeType-completer [] { ["ABSOLUTE" "LAST_MONTH" "LAST_WEEK" "LAST_YEAR" "PAST_TWO_WEEKS" "THIS_MONTH" "THIS_WEEK" "THIS_YEAR" "TODAY" "YESTERDAY"] }
def exportType-completer [] { ["CSV" "JSON" "JSON_V1" "PDF" "XLSX" "ZIP"] }
def invoicingState-completer [] { ["ALL" "INVOICED" "UNINVOICED"] }
def zoomLevel-completer [] { ["MONTH" "WEEK" "YEAR"] }
def sortColumn-completer-2 [] { ["AMOUNT" "CATEGORY" "DATE" "ID" "PROJECT" "USER"] }
def sharedReportsFilter-completer [] { ["ALL" "ALL_ADMIN" "CREATED_BY_ME" "SHARED_WITH_ME"] }
def type-completer-3 [] { ["ATTENDANCE" "DETAILED" "EXPENSE_DETAILED" "EXPENSE_RECEIPT" "INVOICES" "INVOICE_EXPENSE" "INVOICE_TIME" "KIOSK_ASSIGNEES" "KIOSK_PIN_LIST" "PROJECT" "PTO_BALANCE" "PTO_REQUESTS" "SCHEDULED" "SUMMARY" "TEAM_FULL" "TEAM_GROUPS" "TEAM_LIMITED" "USER_DATA_EXPORT" "WEEKLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "file-image uploadImage" } } | get name | first)
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

# Add a photo
#
# POST /v1/file/image
# operationId: uploadImage
export def "file-image uploadImage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # Image to be uploaded (format: binary)
]: any -> record<name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base "/v1/file/image")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get currently logged-in user's info
#
# GET /v1/user
# operationId: getLoggedUser
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-memberships: string@bool-completer # If set to true, memberships will be included. (default: false, e.g. true)
]: nothing -> record<activeWorkspace: string, customFields: table<customFieldId: string, customFieldName: string, customFieldType: record, userId: string, value: record>, defaultWorkspace: string, email: string, id: string, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, profilePicture: string, settings: record<alerts: bool, approval: bool, collapseAllProjectLists: bool, dashboardPinToTop: bool, dashboardSelection: string, dashboardViewType: string, dateFormat: string, groupSimilarEntriesDisabled: bool, invoiceReminders: bool, isCompactViewOn: bool, lang: string, longRunning: bool, multiFactorEnabled: bool, myStartOfDay: string, onboarding: bool, projectListCollapse: int, projectPickerTaskFilter: bool, pto: bool, reminders: bool, scheduledReports: bool, scheduling: bool, sendNewsletter: bool, showOnlyWorkingDays: bool, summaryReportSettings: record<group: string, subgroup: string>, theme: string, timeFormat: string, timeTrackingManual: bool, timeZone: string, weekStart: string, weeklyUpdates: bool>, status: record<ACTIVE: string, DELETED: string, LIMITED: string, LIMITED_DELETED: string, NOT_REGISTERED: string, PENDING_EMAIL_VERIFICATION: string, active: bool, limitedAccount: bool, notRegistered: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-marketplace-token"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "include-memberships" $include_memberships "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all my workspaces
#
# GET /v1/workspaces
# operationId: getWorkspacesOfUser
export def "workspaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --roles: string@roles-completer # If provided, you'll get a filtered list of workspaces where you have any of the specified roles. Owners are not counted as admins when filtering. (e.g. [WORKSPACE_ADMIN, OWNER])
]: nothing -> table<cakeOrganizationId: string, costRate: record<amount: int, currency: string>, currencies: list<record>, featureSubscriptionType: record<addonSubscriptionPlan: string, featurePermissions: list, legacy: bool, paidPlan: bool, regionalAllowed: bool, weight: int>, features: record<ADD_TIME_FOR_OTHERS: string, ADMIN_PANEL: string, ALERTS: string, APPROVAL: string, ATTENDANCE_REPORT: string, AUDIT_LOG: string, AUTOMATIC_LOCK: string, BILLABLE_HOURS: string, BRANDED_REPORTS: string, BREAKS: string, BULK_EDIT: string, CLIENT_CURRENCY: string, CREATION_PERMISSIONS: string, CSV_EXPORT: string, CUSTOM_FIELDS: string, CUSTOM_REPORTING: string, CUSTOM_SUBDOMAIN: string, DECIMAL_FORMAT: string, DISABLE_MANUAL_MODE: string, EDIT_MEMBER_PROFILE: string, EXCLUDE_NON_BILLABLE_FROM_ESTIMATE: string, EXPENSES: string, FAVORITE_ENTRIES: string, FILE_IMPORT: string, FORECASTING: string, GRANT_PROJECT_MANAGER_ROLE: string, HIDE_PAGES: string, HISTORIC_RATES: string, INVOICE_EMAILS: string, INVOICE_REMINDERS: string, INVOICING: string, KIOSK: string, KIOSK_PIN_REQUIRED: string, KIOSK_QR_CODE: string, KIOSK_SESSION_DURATION: string, KIOSK_SIX_DIGIT_PIN: string, LABOR_COST: string, LIMITED_USERS: string, LOCATIONS: string, MANAGER_ROLE: string, MONTHLY_OVERTIME_CALCULATION_PERIOD: string, MULTI_FACTOR_AUTHENTICATION: string, ONE_MONTH_RANGE_REPORTS: string, ONE_YEAR_RANGE_REPORTS: string, PRIVATE_PROJECT_ACCESS: string, PROJECT_BUDGET: string, PROJECT_ESTIMATE: string, PROJECT_TEMPLATES: string, QUICKBOOKS_INTEGRATION: string, RECURRING_ESTIMATES: string, RECURRING_INVOICES: string, REQUIRED_FIELDS: string, SCHEDULED_REPORTS: string, SCHEDULING: string, SCHEDULING_FORECASTING: string, SCIM: string, SCREENSHOTS: string, SHARED_REPORTS: string, SPLIT_TIME_ENTRY: string, SSO: string, SUMMARY_ESTIMATE: string, TARGETS_AND_REMINDERS: string, TASK_RATES: string, TIMESHEET_IMPORT: string, TIME_OFF: string, TIME_TRACKING: string, UNLIMITED_REPORTS: string, UNLIMITED_USER_SEATS: string, USER_CUSTOM_FIELDS: string, USER_IMPORT: string, WEEKLY_OVERTIME_CALCULATION_PERIOD: string, WHO_CAN_CHANGE_TIMEENTRY_BILLABILITY: string, WHO_CAN_SEE_ALL_TIME_ENTRIES: string, WHO_CAN_SEE_PROJECT_STATUS: string, WHO_CAN_SEE_PUBLIC_PROJECTS_ENTRIES: string, WHO_CAN_SEE_TEAMS_DASHBOARD: string, WORKSPACE_LOCK_TIMEENTRIES: string, WORKSPACE_TIME_AUDIT: string, WORKSPACE_TIME_ROUNDING: string, WORKSPACE_TRANSFER: string, XLSX_EXPORT: string>, hourlyRate: record<amount: int, currency: string>, id: string, imageUrl: string, memberships: list<record>, name: string, subdomain: record<enabled: bool, name: string>, workspaceSettings: record<activeBillableHours: bool, adminOnlyPages: string, automaticLock: record, canSeeTimeSheet: bool, canSeeTracker: bool, currencyFormat: string, defaultBillableProjects: bool, durationFormat: string, entityCreationPermissions: record, forceDescription: bool, forceProjects: bool, forceTags: bool, forceTasks: bool, isProjectPublicByDefault: bool, lockTimeEntries: string, lockTimeZone: string, multiFactorEnabled: bool, numberFormat: string, onlyAdminsCanChangeBillableStatus: bool, onlyAdminsCreateProject: bool, onlyAdminsCreateTag: bool, onlyAdminsCreateTask: bool, onlyAdminsSeeAllTimeEntries: bool, onlyAdminsSeeBillableRates: bool, onlyAdminsSeeDashboard: bool, onlyAdminsSeePublicProjectsEntries: bool, projectFavorites: bool, projectGroupingLabel: string, projectLabel: string, projectPickerSpecialFilter: bool, round: record, taskLabel: string, timeRoundingInReports: bool, timeTrackingMode: string, trackTimeDownToSecond: bool, workingDays: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-marketplace-token"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "roles" $roles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a workspace
#
# POST /v1/workspaces
# operationId: createWorkspace
export def "workspaces createWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Represents a workspace name. (e.g. Cool Company)
  --organizationId: string # Represents the Cake organization identifier across the system. (e.g. 67d471fb56aa9668b7bfa295)
]: any -> record<cakeOrganizationId: string, costRate: record<amount: int, currency: string>, currencies: table<code: string, id: string, isDefault: bool>, featureSubscriptionType: record<addonSubscriptionPlan: string, featurePermissions: list<string>, legacy: bool, paidPlan: bool, regionalAllowed: bool, weight: int>, features: record<ADD_TIME_FOR_OTHERS: string, ADMIN_PANEL: string, ALERTS: string, APPROVAL: string, ATTENDANCE_REPORT: string, AUDIT_LOG: string, AUTOMATIC_LOCK: string, BILLABLE_HOURS: string, BRANDED_REPORTS: string, BREAKS: string, BULK_EDIT: string, CLIENT_CURRENCY: string, CREATION_PERMISSIONS: string, CSV_EXPORT: string, CUSTOM_FIELDS: string, CUSTOM_REPORTING: string, CUSTOM_SUBDOMAIN: string, DECIMAL_FORMAT: string, DISABLE_MANUAL_MODE: string, EDIT_MEMBER_PROFILE: string, EXCLUDE_NON_BILLABLE_FROM_ESTIMATE: string, EXPENSES: string, FAVORITE_ENTRIES: string, FILE_IMPORT: string, FORECASTING: string, GRANT_PROJECT_MANAGER_ROLE: string, HIDE_PAGES: string, HISTORIC_RATES: string, INVOICE_EMAILS: string, INVOICE_REMINDERS: string, INVOICING: string, KIOSK: string, KIOSK_PIN_REQUIRED: string, KIOSK_QR_CODE: string, KIOSK_SESSION_DURATION: string, KIOSK_SIX_DIGIT_PIN: string, LABOR_COST: string, LIMITED_USERS: string, LOCATIONS: string, MANAGER_ROLE: string, MONTHLY_OVERTIME_CALCULATION_PERIOD: string, MULTI_FACTOR_AUTHENTICATION: string, ONE_MONTH_RANGE_REPORTS: string, ONE_YEAR_RANGE_REPORTS: string, PRIVATE_PROJECT_ACCESS: string, PROJECT_BUDGET: string, PROJECT_ESTIMATE: string, PROJECT_TEMPLATES: string, QUICKBOOKS_INTEGRATION: string, RECURRING_ESTIMATES: string, RECURRING_INVOICES: string, REQUIRED_FIELDS: string, SCHEDULED_REPORTS: string, SCHEDULING: string, SCHEDULING_FORECASTING: string, SCIM: string, SCREENSHOTS: string, SHARED_REPORTS: string, SPLIT_TIME_ENTRY: string, SSO: string, SUMMARY_ESTIMATE: string, TARGETS_AND_REMINDERS: string, TASK_RATES: string, TIMESHEET_IMPORT: string, TIME_OFF: string, TIME_TRACKING: string, UNLIMITED_REPORTS: string, UNLIMITED_USER_SEATS: string, USER_CUSTOM_FIELDS: string, USER_IMPORT: string, WEEKLY_OVERTIME_CALCULATION_PERIOD: string, WHO_CAN_CHANGE_TIMEENTRY_BILLABILITY: string, WHO_CAN_SEE_ALL_TIME_ENTRIES: string, WHO_CAN_SEE_PROJECT_STATUS: string, WHO_CAN_SEE_PUBLIC_PROJECTS_ENTRIES: string, WHO_CAN_SEE_TEAMS_DASHBOARD: string, WORKSPACE_LOCK_TIMEENTRIES: string, WORKSPACE_TIME_AUDIT: string, WORKSPACE_TIME_ROUNDING: string, WORKSPACE_TRANSFER: string, XLSX_EXPORT: string>, hourlyRate: record<amount: int, currency: string>, id: string, imageUrl: string, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, subdomain: record<enabled: bool, name: string>, workspaceSettings: record<activeBillableHours: bool, adminOnlyPages: string, automaticLock: record<changeDay: string, dayOfMonth: int, firstDay: string, olderThanPeriod: string, olderThanValue: int, type: string>, canSeeTimeSheet: bool, canSeeTracker: bool, currencyFormat: string, defaultBillableProjects: bool, durationFormat: string, entityCreationPermissions: record<whoCanCreateProjectsAndClients: record, whoCanCreateTags: record, whoCanCreateTasks: record>, forceDescription: bool, forceProjects: bool, forceTags: bool, forceTasks: bool, isProjectPublicByDefault: bool, lockTimeEntries: string, lockTimeZone: string, multiFactorEnabled: bool, numberFormat: string, onlyAdminsCanChangeBillableStatus: bool, onlyAdminsCreateProject: bool, onlyAdminsCreateTag: bool, onlyAdminsCreateTask: bool, onlyAdminsSeeAllTimeEntries: bool, onlyAdminsSeeBillableRates: bool, onlyAdminsSeeDashboard: bool, onlyAdminsSeePublicProjectsEntries: bool, projectFavorites: bool, projectGroupingLabel: string, projectLabel: string, projectPickerSpecialFilter: bool, round: record<minutes: string, round: string>, taskLabel: string, timeRoundingInReports: bool, timeTrackingMode: string, trackTimeDownToSecond: bool, workingDays: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base "/v1/workspaces")
  let body = {name: $name, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workspace info
#
# GET /v1/workspaces/{workspaceId}
# operationId: getWorkspaceOfUser
export def "workspaces get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cakeOrganizationId: string, costRate: record<amount: int, currency: string>, currencies: table<code: string, id: string, isDefault: bool>, featureSubscriptionType: record<addonSubscriptionPlan: string, featurePermissions: list<string>, legacy: bool, paidPlan: bool, regionalAllowed: bool, weight: int>, features: record<ADD_TIME_FOR_OTHERS: string, ADMIN_PANEL: string, ALERTS: string, APPROVAL: string, ATTENDANCE_REPORT: string, AUDIT_LOG: string, AUTOMATIC_LOCK: string, BILLABLE_HOURS: string, BRANDED_REPORTS: string, BREAKS: string, BULK_EDIT: string, CLIENT_CURRENCY: string, CREATION_PERMISSIONS: string, CSV_EXPORT: string, CUSTOM_FIELDS: string, CUSTOM_REPORTING: string, CUSTOM_SUBDOMAIN: string, DECIMAL_FORMAT: string, DISABLE_MANUAL_MODE: string, EDIT_MEMBER_PROFILE: string, EXCLUDE_NON_BILLABLE_FROM_ESTIMATE: string, EXPENSES: string, FAVORITE_ENTRIES: string, FILE_IMPORT: string, FORECASTING: string, GRANT_PROJECT_MANAGER_ROLE: string, HIDE_PAGES: string, HISTORIC_RATES: string, INVOICE_EMAILS: string, INVOICE_REMINDERS: string, INVOICING: string, KIOSK: string, KIOSK_PIN_REQUIRED: string, KIOSK_QR_CODE: string, KIOSK_SESSION_DURATION: string, KIOSK_SIX_DIGIT_PIN: string, LABOR_COST: string, LIMITED_USERS: string, LOCATIONS: string, MANAGER_ROLE: string, MONTHLY_OVERTIME_CALCULATION_PERIOD: string, MULTI_FACTOR_AUTHENTICATION: string, ONE_MONTH_RANGE_REPORTS: string, ONE_YEAR_RANGE_REPORTS: string, PRIVATE_PROJECT_ACCESS: string, PROJECT_BUDGET: string, PROJECT_ESTIMATE: string, PROJECT_TEMPLATES: string, QUICKBOOKS_INTEGRATION: string, RECURRING_ESTIMATES: string, RECURRING_INVOICES: string, REQUIRED_FIELDS: string, SCHEDULED_REPORTS: string, SCHEDULING: string, SCHEDULING_FORECASTING: string, SCIM: string, SCREENSHOTS: string, SHARED_REPORTS: string, SPLIT_TIME_ENTRY: string, SSO: string, SUMMARY_ESTIMATE: string, TARGETS_AND_REMINDERS: string, TASK_RATES: string, TIMESHEET_IMPORT: string, TIME_OFF: string, TIME_TRACKING: string, UNLIMITED_REPORTS: string, UNLIMITED_USER_SEATS: string, USER_CUSTOM_FIELDS: string, USER_IMPORT: string, WEEKLY_OVERTIME_CALCULATION_PERIOD: string, WHO_CAN_CHANGE_TIMEENTRY_BILLABILITY: string, WHO_CAN_SEE_ALL_TIME_ENTRIES: string, WHO_CAN_SEE_PROJECT_STATUS: string, WHO_CAN_SEE_PUBLIC_PROJECTS_ENTRIES: string, WHO_CAN_SEE_TEAMS_DASHBOARD: string, WORKSPACE_LOCK_TIMEENTRIES: string, WORKSPACE_TIME_AUDIT: string, WORKSPACE_TIME_ROUNDING: string, WORKSPACE_TRANSFER: string, XLSX_EXPORT: string>, hourlyRate: record<amount: int, currency: string>, id: string, imageUrl: string, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, subdomain: record<enabled: bool, name: string>, workspaceSettings: record<activeBillableHours: bool, adminOnlyPages: string, automaticLock: record<changeDay: string, dayOfMonth: int, firstDay: string, olderThanPeriod: string, olderThanValue: int, type: string>, canSeeTimeSheet: bool, canSeeTracker: bool, currencyFormat: string, defaultBillableProjects: bool, durationFormat: string, entityCreationPermissions: record<whoCanCreateProjectsAndClients: record, whoCanCreateTags: record, whoCanCreateTasks: record>, forceDescription: bool, forceProjects: bool, forceTags: bool, forceTasks: bool, isProjectPublicByDefault: bool, lockTimeEntries: string, lockTimeZone: string, multiFactorEnabled: bool, numberFormat: string, onlyAdminsCanChangeBillableStatus: bool, onlyAdminsCreateProject: bool, onlyAdminsCreateTag: bool, onlyAdminsCreateTask: bool, onlyAdminsSeeAllTimeEntries: bool, onlyAdminsSeeBillableRates: bool, onlyAdminsSeeDashboard: bool, onlyAdminsSeePublicProjectsEntries: bool, projectFavorites: bool, projectGroupingLabel: string, projectLabel: string, projectPickerSpecialFilter: bool, round: record<minutes: string, round: string>, taskLabel: string, timeRoundingInReports: bool, timeTrackingMode: string, trackTimeDownToSecond: bool, workingDays: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all webhooks for addon on a workspace
#
# GET /v1/workspaces/{workspaceId}/addons/{addonId}/webhooks
# operationId: getAddonWebhooks
export def "workspaces-addons-webhooks get" [
  workspaceId: string
  addonId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhooks: table<authToken: string, deliveryEnabled: bool, enabled: bool, id: string, name: string, planEnabled: bool, triggerSource: list, triggerSourceType: record, url: string, userId: string, webhookEvent: record, workspaceId: string>, workspaceWebhookCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/addons/($addonId)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get approval requests
#
# GET /v1/workspaces/{workspaceId}/approval-requests
# operationId: getApprovalRequests
export def "workspaces-approval-requests get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer # Filters results based on the provided approval state. (e.g. PENDING)
  --sort-column: string@sort-column-completer # Represents the column name to be used as sorting criteria. (e.g. START)
  --sort-order: string@sort-order-completer # Represents the sorting order. (e.g. ASCENDING)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
]: nothing -> table<approvalRequest: record<creator: record, dateRange: record, id: string, owner: record, status: record, workspaceId: string>, approvedTime: string, billableAmount: float, billableTime: string, breakTime: string, costAmount: float, entries: list<record>, expenseTotal: float, expenses: list<record>, pendingTime: string, trackedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/approval-requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit approval request
#
# POST /v1/workspaces/{workspaceId}/approval-requests
# operationId: createApprrovalRequest
export def "workspaces-approval-requests createApprrovalRequest" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string@period-completer # Specifies the approval period. It has to match the workspace approval period setting. (e.g. MONTHLY)
  periodStart: string # Specifies an approval period start date in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00.000Z)
]: any -> record<creator: record<userEmail: string, userId: string, userName: string>, dateRange: record<end: string, start: string>, id: string, owner: record<startOfWeek: string, timeZone: string, userId: string, userName: string>, status: record<note: string, state: string, updatedAt: string, updatedBy: string, updatedByUserName: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/approval-requests")
  let body = {period: $period, periodStart: $periodStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit non pending/approved entries/expenses for approval to an existing approval request
#
# POST /v1/workspaces/{workspaceId}/approval-requests/resubmit-entries-for-approval
# operationId: resubmitApprovalRequest
export def "workspaces-approval-requests-resubmit-entries-for-approval resubmitApprovalRequest" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string@period-completer # Specifies the approval period. It has to match the workspace approval period setting. (e.g. MONTHLY)
  periodStart: string # Specifies an approval period start date in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00.000Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/approval-requests/resubmit-entries-for-approval")
  let body = {period: $period, periodStart: $periodStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit an approval request for a user
#
# POST /v1/workspaces/{workspaceId}/approval-requests/users/{userId}
# operationId: createApprovalForOther
export def "workspaces-approval-requests-users createApprovalForOther" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string@period-completer # Specifies the approval period. It has to match the workspace approval period setting. (e.g. MONTHLY)
  periodStart: string # Specifies an approval period start date in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00.000Z)
]: any -> record<creator: record<userEmail: string, userId: string, userName: string>, dateRange: record<end: string, start: string>, id: string, owner: record<startOfWeek: string, timeZone: string, userId: string, userName: string>, status: record<note: string, state: string, updatedAt: string, updatedBy: string, updatedByUserName: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/approval-requests/users/($userId)")
  let body = {period: $period, periodStart: $periodStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Re-submit rejected/withdrawn entries/expenses for an approval of a user
#
# POST /v1/workspaces/{workspaceId}/approval-requests/users/{userId}/resubmit-entries-for-approval
# operationId: resubmitApprovalRequestForOther
export def "workspaces-approval-requests-users-resubmit-entries-for-approval resubmitApprovalRequestForOther" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string@period-completer # Specifies the approval period. It has to match the workspace approval period setting. (e.g. MONTHLY)
  periodStart: string # Specifies an approval period start date in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00.000Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/approval-requests/users/($userId)/resubmit-entries-for-approval")
  let body = {period: $period, periodStart: $periodStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an approval request
#
# PATCH /v1/workspaces/{workspaceId}/approval-requests/{approvalRequestId}
# operationId: updateApprovalStatus
export def "workspaces-approval-requests updateApprovalStatus" [
  workspaceId: string
  approvalRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --note: string # Additional notes for the approval request. (e.g. This is a sample note.)
  state: string@state-completer # Specifies the approval state to set. (e.g. PENDING)
]: any -> record<creator: record<userEmail: string, userId: string, userName: string>, dateRange: record<end: string, start: string>, id: string, owner: record<startOfWeek: string, timeZone: string, userId: string, userName: string>, status: record<note: string, state: string, updatedAt: string, updatedBy: string, updatedByUserName: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/approval-requests/($approvalRequestId)")
  let body = {note: $note, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find clients on a workspace
#
# GET /v1/workspaces/{workspaceId}/clients
# operationId: getClients
export def "workspaces-clients list" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Filters client results that matches with the string provided in their client name. (e.g. Client X)
  --sort-column: string # Column name that will be used as criteria for sorting results. (default: NAME, e.g. NAME)
  --sort-order: string # Sorting mode (e.g. ASCENDING)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --archived: string # Filter whether to include archived clients or not. (e.g. false)
]: nothing -> table<address: string, archived: bool, ccEmails: list<string>, currencyCode: string, currencyId: string, email: string, id: string, name: string, note: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new client
#
# POST /v1/workspaces/{workspaceId}/clients
# operationId: createClient
export def "workspaces-clients createClient" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # Represents a client's address. (e.g. Ground Floor, ABC Bldg., Palo Alto, California, USA 94020)
  --email: string # Represents a client email. (format: email, e.g. clientx@example.com)
  --name: string # Represents a client name. (e.g. Client X)
  --note: string # Represents additional notes for the client. (e.g. This is a sample note for the client.)
]: any -> record<address: string, archived: bool, ccEmails: list<string>, currencyCode: string, currencyId: string, email: string, id: string, name: string, note: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/clients")
  let body = {address: $address, email: $email, name: $name, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a client
#
# DELETE /v1/workspaces/{workspaceId}/clients/{id}
# operationId: deleteClient
export def "workspaces-clients delete" [
  id: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, archived: bool, ccEmails: list<string>, currencyId: string, email: string, id: string, name: string, note: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/clients/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a client by ID
#
# GET /v1/workspaces/{workspaceId}/clients/{id}
# operationId: getClient
export def "workspaces-clients get" [
  id: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, archived: bool, ccEmails: list<string>, currencyCode: string, currencyId: string, email: string, id: string, name: string, note: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/clients/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a client
#
# PUT /v1/workspaces/{workspaceId}/clients/{id}
# operationId: updateClient
export def "workspaces-clients updateClient" [
  id: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archive-projects: string@bool-completer
  --mark-tasks-as-done: string@bool-completer
  --address: string # Represents a client's address. (e.g. Ground Floor, ABC Bldg., Palo Alto, California, USA 94020)
  --archived: string@bool-completer # Indicates if client will be archived or not. (default: false)
  --ccEmails: list
  --currencyId: string # Represents a currency identifier across the system. (e.g. 53a687e29ae1f428e7ebe888)
  --email: string # Represents a client email. (format: email, e.g. clientx@example.com)
  --name: string # Represents a client name. (e.g. Client X)
  --note: string # Represents additional notes for the client. (e.g. This is a sample note for the client.)
]: any -> record<address: string, archived: bool, ccEmails: list<string>, currencyId: string, email: string, id: string, name: string, note: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "archive-projects" $archive_projects "scalar") (serialize-qp "mark-tasks-as-done" $mark_tasks_as_done "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/clients/($id)" $qp)
  let body = {address: $address, archived: $archived, ccEmails: $ccEmails, currencyId: $currencyId, email: $email, name: $name, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update workspace cost rate
#
# PUT /v1/workspaces/{workspaceId}/cost-rate
# operationId: setWorkspaceCostRate
export def "workspaces-cost-rate setWorkspaceCostRate" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: int # Represents an amount as integer. (format: int32, e.g. 20000)
  --since: string # Represents a date and time in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
]: any -> record<cakeOrganizationId: string, costRate: record<amount: int, currency: string>, currencies: table<code: string, id: string, isDefault: bool>, featureSubscriptionType: record<addonSubscriptionPlan: string, featurePermissions: list<string>, legacy: bool, paidPlan: bool, regionalAllowed: bool, weight: int>, features: record<ADD_TIME_FOR_OTHERS: string, ADMIN_PANEL: string, ALERTS: string, APPROVAL: string, ATTENDANCE_REPORT: string, AUDIT_LOG: string, AUTOMATIC_LOCK: string, BILLABLE_HOURS: string, BRANDED_REPORTS: string, BREAKS: string, BULK_EDIT: string, CLIENT_CURRENCY: string, CREATION_PERMISSIONS: string, CSV_EXPORT: string, CUSTOM_FIELDS: string, CUSTOM_REPORTING: string, CUSTOM_SUBDOMAIN: string, DECIMAL_FORMAT: string, DISABLE_MANUAL_MODE: string, EDIT_MEMBER_PROFILE: string, EXCLUDE_NON_BILLABLE_FROM_ESTIMATE: string, EXPENSES: string, FAVORITE_ENTRIES: string, FILE_IMPORT: string, FORECASTING: string, GRANT_PROJECT_MANAGER_ROLE: string, HIDE_PAGES: string, HISTORIC_RATES: string, INVOICE_EMAILS: string, INVOICE_REMINDERS: string, INVOICING: string, KIOSK: string, KIOSK_PIN_REQUIRED: string, KIOSK_QR_CODE: string, KIOSK_SESSION_DURATION: string, KIOSK_SIX_DIGIT_PIN: string, LABOR_COST: string, LIMITED_USERS: string, LOCATIONS: string, MANAGER_ROLE: string, MONTHLY_OVERTIME_CALCULATION_PERIOD: string, MULTI_FACTOR_AUTHENTICATION: string, ONE_MONTH_RANGE_REPORTS: string, ONE_YEAR_RANGE_REPORTS: string, PRIVATE_PROJECT_ACCESS: string, PROJECT_BUDGET: string, PROJECT_ESTIMATE: string, PROJECT_TEMPLATES: string, QUICKBOOKS_INTEGRATION: string, RECURRING_ESTIMATES: string, RECURRING_INVOICES: string, REQUIRED_FIELDS: string, SCHEDULED_REPORTS: string, SCHEDULING: string, SCHEDULING_FORECASTING: string, SCIM: string, SCREENSHOTS: string, SHARED_REPORTS: string, SPLIT_TIME_ENTRY: string, SSO: string, SUMMARY_ESTIMATE: string, TARGETS_AND_REMINDERS: string, TASK_RATES: string, TIMESHEET_IMPORT: string, TIME_OFF: string, TIME_TRACKING: string, UNLIMITED_REPORTS: string, UNLIMITED_USER_SEATS: string, USER_CUSTOM_FIELDS: string, USER_IMPORT: string, WEEKLY_OVERTIME_CALCULATION_PERIOD: string, WHO_CAN_CHANGE_TIMEENTRY_BILLABILITY: string, WHO_CAN_SEE_ALL_TIME_ENTRIES: string, WHO_CAN_SEE_PROJECT_STATUS: string, WHO_CAN_SEE_PUBLIC_PROJECTS_ENTRIES: string, WHO_CAN_SEE_TEAMS_DASHBOARD: string, WORKSPACE_LOCK_TIMEENTRIES: string, WORKSPACE_TIME_AUDIT: string, WORKSPACE_TIME_ROUNDING: string, WORKSPACE_TRANSFER: string, XLSX_EXPORT: string>, hourlyRate: record<amount: int, currency: string>, id: string, imageUrl: string, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, subdomain: record<enabled: bool, name: string>, workspaceSettings: record<activeBillableHours: bool, adminOnlyPages: string, automaticLock: record<changeDay: string, dayOfMonth: int, firstDay: string, olderThanPeriod: string, olderThanValue: int, type: string>, canSeeTimeSheet: bool, canSeeTracker: bool, currencyFormat: string, defaultBillableProjects: bool, durationFormat: string, entityCreationPermissions: record<whoCanCreateProjectsAndClients: record, whoCanCreateTags: record, whoCanCreateTasks: record>, forceDescription: bool, forceProjects: bool, forceTags: bool, forceTasks: bool, isProjectPublicByDefault: bool, lockTimeEntries: string, lockTimeZone: string, multiFactorEnabled: bool, numberFormat: string, onlyAdminsCanChangeBillableStatus: bool, onlyAdminsCreateProject: bool, onlyAdminsCreateTag: bool, onlyAdminsCreateTask: bool, onlyAdminsSeeAllTimeEntries: bool, onlyAdminsSeeBillableRates: bool, onlyAdminsSeeDashboard: bool, onlyAdminsSeePublicProjectsEntries: bool, projectFavorites: bool, projectGroupingLabel: string, projectLabel: string, projectPickerSpecialFilter: bool, round: record<minutes: string, round: string>, taskLabel: string, timeRoundingInReports: bool, timeTrackingMode: string, trackTimeDownToSecond: bool, workingDays: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/cost-rate")
  let body = {amount: $amount, since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get custom fields on a workspace
#
# GET /v1/workspaces/{workspaceId}/custom-fields
# operationId: ofWorkspace
export def "workspaces-custom-fields ofWorkspace" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # If provided, you'll get a filtered list of custom fields that contain the provided string in their name. (e.g. location)
  --status: string@status-completer-1 # If provided, you'll get a filtered list of custom fields that matches the provided string with the custom field status. (e.g. VISIBLE)
  --entity-type: string # If provided, you'll get a filtered list of custom fields that matches the provided string with the custom field entity type. (e.g. [TIMEENTRY, USER])
]: nothing -> table<allowedValues: list<string>, description: string, entityType: string, id: string, name: string, onlyAdminCanEdit: bool, placeholder: string, projectDefaultValues: list<record>, required: bool, status: string, type: string, workspaceDefaultValue: record, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "entity-type" $entity_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/custom-fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create custom fields on a workspace
#
# POST /v1/workspaces/{workspaceId}/custom-fields
# operationId: create
export def "workspaces-custom-fields create" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowedValues: list # Represents a list of custom field's allowed values. (e.g. [New York, London, Manila, Sydney, Belgrade])
  --description: string # Represents custom field description. (e.g. This field contains a location.)
  --entityType: string@entityType-completer # Represents custom field entity type (e.g. TIMEENTRY)
  name: string # Represents custom field name. (e.g. location)
  --onlyAdminCanEdit: string@bool-completer # Flag to set whether custom field is modifiable only by admin users. (default: false)
  --placeholder: string # Represents custom field placeholder value. (e.g. Location)
  --status: string@status-completer-1 # Represents custom field status (e.g. VISIBLE)
  type: string@type-completer # Represents custom field type. (e.g. DROPDOWN_MULTIPLE)
  --workspaceDefaultValue: record # Represents a custom field's default value in the workspace.<li>if type = NUMBER, then value must be a number</li><li>if type = DROPDOWN_MULTIPLE, value must be a list</li><li>if type = CHECKBOX, value must be true/false</li><li>otherwise any string</li> (e.g. Manila)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/custom-fields")
  let body = {allowedValues: $allowedValues, description: $description, entityType: $entityType, name: $name, onlyAdminCanEdit: $onlyAdminCanEdit, placeholder: $placeholder, status: $status, type: $type, workspaceDefaultValue: $workspaceDefaultValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom field
#
# DELETE /v1/workspaces/{workspaceId}/custom-fields/{customFieldId}
# operationId: delete
export def "workspaces-custom-fields delete" [
  workspaceId: string
  customFieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/custom-fields/($customFieldId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update custom field on workspace
#
# PUT /v1/workspaces/{workspaceId}/custom-fields/{customFieldId}
# operationId: editCustomField
export def "workspaces-custom-fields editCustomField" [
  workspaceId: string
  customFieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowedValues: list # Represents a list of custom field's allowed values. (e.g. [New York, London, Manila, Sydney, Belgrade])
  --description: string # Represents a custom field description. (e.g. This field contains a location.)
  name: string # Represents a custom field name. (e.g. location)
  --onlyAdminCanEdit: string@bool-completer # Flag to set whether custom field is modifiable only by admin users. (default: false)
  --placeholder: string # Represents a custom field placeholder value. (e.g. This is a sample placeholder.)
  --required: string@bool-completer # Flag to set whether custom field is mandatory or not. (default: false)
  --status: string@status-completer-1 # Represents a custom field status (e.g. VISIBLE)
  type: string@type-completer # Represents a custom field type. (e.g. DROPDOWN_MULTIPLE)
  --workspaceDefaultValue: record # Represents a custom field's default value in the workspace. (e.g. Manila)
]: any -> record<allowedValues: list<string>, description: string, entityType: string, id: string, name: string, onlyAdminCanEdit: bool, placeholder: string, projectDefaultValues: table<projectId: string, status: string, value: record>, required: bool, status: string, type: string, workspaceDefaultValue: record, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/custom-fields/($customFieldId)")
  let body = {allowedValues: $allowedValues, description: $description, name: $name, onlyAdminCanEdit: $onlyAdminCanEdit, placeholder: $placeholder, required: $required, status: $status, type: $type, workspaceDefaultValue: $workspaceDefaultValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Created entities (Experimental)
#
# GET /v1/workspaces/{workspaceId}/entities/created
# operationId: getCreatedEntityInfo
export def "workspaces-entities-created get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Specifies the type of document to be retrieved. Expected values are CLIENTS, PROJECTS, TAGS, TASKS, SCHEDULED_ASSIGNMENT, TIME_ENTRY, TIME_ENTRY_RATE, TIME_ENTRY_CUSTOM_FIELD_VALUE, CUSTOM_FIELDS, USER, USER_GROUPS, INVOICES, APPROVAL_REQUESTS, BALANCE, HOLIDAYS, PTO_POLICY, TIME_OFF_REQUEST.This parameter can accept multiple values, and at least one option must be provided. Based on the input, the application will return results corresponding to the selected document types. (e.g. TIME_ENTRY)
  --start: string # Represents the start date in yyyy-MM-ddThh:mm:ssZ format. This parameter is optional; if no start date is provided, the application will set a default start date that matches the end date to create a date range of 30 days. If the end date is not specified either, the default behavior will apply from the current date. (e.g. 2024-10-29T10:00:00Z)
  --end: string # Represents the end date in yyyy-MM-ddThh:mm:ssZ format. This parameter is optional; if no end date is provided, the application will set a default end date that matches the start date to create a date range of 30 days. (e.g. 2024-11-28T10:00:00Z)
  --page: string # default: 0
  --limit: string # default: 50
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/entities/created" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deleted entities (Experimental)
#
# GET /v1/workspaces/{workspaceId}/entities/deleted
# operationId: getDeletedEntityInfo
export def "workspaces-entities-deleted get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Specifies the type of document to be retrieved. Expected values are CLIENTS, PROJECTS, TAGS, TASKS, SCHEDULED_ASSIGNMENT, TIME_ENTRY, TIME_ENTRY_RATE, TIME_ENTRY_CUSTOM_FIELD_VALUE, CUSTOM_FIELDS, USER, USER_GROUPS, INVOICES, APPROVAL_REQUESTS, BALANCE, HOLIDAYS, PTO_POLICY, TIME_OFF_REQUEST.This parameter can accept multiple values, and at least one option must be provided. Based on the input, the application will return results corresponding to the selected document types. (e.g. TIME_ENTRY)
  --start: string # Represents the start date in yyyy-MM-ddThh:mm:ssZ format. This parameter is optional; if no start date is provided, the application will set a default start date that matches the end date to create a date range of 30 days. If the end date is not specified either, the default behavior will apply from the current date. (e.g. 2024-10-29T10:00:00Z)
  --end: string # Represents the end date in yyyy-MM-ddThh:mm:ssZ format. This parameter is optional; if no end date is provided, the application will set a default end date that matches the start date to create a date range of 30 days. (e.g. 2024-11-28T10:00:00Z)
  --page: string # default: 0
  --limit: string # default: 50
]: nothing -> record<response: table<deletedAt: string, document: record, documentCode: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/entities/deleted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updated entities (Experimental)
#
# GET /v1/workspaces/{workspaceId}/entities/updated
# operationId: getUpdatedEntityInfo
export def "workspaces-entities-updated get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Specifies the type of document to be retrieved. Expected values are CLIENTS, PROJECTS, TAGS, TASKS, SCHEDULED_ASSIGNMENT, TIME_ENTRY, TIME_ENTRY_RATE, TIME_ENTRY_CUSTOM_FIELD_VALUE, CUSTOM_FIELDS, USER, USER_GROUPS, INVOICES, APPROVAL_REQUESTS, BALANCE, HOLIDAYS, PTO_POLICY, TIME_OFF_REQUEST.This parameter can accept multiple values, and at least one option must be provided. Based on the input, the application will return results corresponding to the selected document types. (e.g. TIME_ENTRY)
  --start: string # Represents the start date in yyyy-MM-ddThh:mm:ssZ format. This parameter is optional; if no start date is provided, the application will set a default start date that matches the end date to create a date range of 30 days. If the end date is not specified either, the default behavior will apply from the current date. (e.g. 2024-10-29T10:00:00Z)
  --end: string # Represents the end date in yyyy-MM-ddThh:mm:ssZ format. This parameter is optional; if no end date is provided, the application will set a default end date that matches the start date to create a date range of 30 days. (e.g. 2024-11-28T10:00:00Z)
  --page: string # default: 0
  --limit: string # default: 50
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/entities/updated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all expenses on a workspace
#
# GET /v1/workspaces/{workspaceId}/expenses
# operationId: getExpenses
export def "workspaces-expenses list" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --user-id: string # If provided, you'll get a filtered list of expenses which match the provided string in the user ID linked to the expense. (e.g. 5a0ab5acb07987125438b60f)
]: nothing -> record<dailyTotals: table<date: string, dateAsInstant: string, total: float>, expenses: record<count: int, expenses: list<record>>, weeklyTotals: table<date: string, total: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "user-id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/expenses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an expense
#
# POST /v1/workspaces/{workspaceId}/expenses
# operationId: createExpense
export def "workspaces-expenses createExpense" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: float # Represents an expense amount as the double data type. (format: double, e.g. 99.5)
  --billable: string@bool-completer # Indicates whether expense is billable or not. (default: false)
  categoryId: string # Represents a category identifier across the system. (e.g. 45y687e29ae1f428e7ebe890)
  date: string # Provides a valid yyyy-MM-ddThh:mm:ssZ format date. (format: date-time, e.g. 2020-01-01T00:00:00Z)
  file: string # format: binary
  --notes: string # Represents notes for an expense. (e.g. This is a sample note for this expense.)
  projectId: string # Represents a project identifier across the system. (e.g. 25b687e29ae1f428e7ebe123)
  --taskId: string # Represents a task identifier across the system. (e.g. 54m377ddd3fcab07cfbb432w)
  userId: string # Represents a user identifier across the system. (e.g. 89b687e29ae1f428e7ebe912)
]: any -> record<billable: bool, categoryId: string, date: string, fileId: string, id: string, isLocked: bool, locked: bool, notes: string, projectId: string, quantity: float, taskId: string, total: float, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/expenses")
  let body = {amount: $amount, billable: $billable, categoryId: $categoryId, date: $date, file: $file, notes: $notes, projectId: $projectId, taskId: $taskId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get all expense categories
#
# GET /v1/workspaces/{workspaceId}/expenses/categories
# operationId: getCategories
export def "workspaces-expenses-categories get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-column: string@sort-column-completer-1 # Represents the column name to be used as sorting criteria. (e.g. NAME)
  --sort-order: string@sort-order-completer # Represents the sorting order. (e.g. ASCENDING)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --archived: string@bool-completer # Flag to filter results based on whether category is archived or not. (default: false, e.g. true)
  --name: string # If provided, you'll get a filtered list of expense categories that matches the provided string in their name. (e.g. procurement)
]: nothing -> record<categories: table<archived: bool, hasUnitPrice: bool, id: string, name: string, priceInCents: int, unit: string, workspaceId: string>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/expenses/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an expense category
#
# POST /v1/workspaces/{workspaceId}/expenses/categories
# operationId: createExpenseCategory
export def "workspaces-expenses-categories createExpenseCategory" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hasUnitPrice: string@bool-completer # Flag whether expense category has unit price or none. (default: false)
  name: string # Represents a valid expense category name. (e.g. Procurement)
  --priceInCents: int # Represents price in cents as integer. (format: int32, e.g. 1000)
  --unit: string # Represents a valid expense category unit. (e.g. piece)
]: any -> record<archived: bool, hasUnitPrice: bool, id: string, name: string, priceInCents: int, unit: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/expenses/categories")
  let body = {hasUnitPrice: $hasUnitPrice, name: $name, priceInCents: $priceInCents, unit: $unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an expense category
#
# DELETE /v1/workspaces/{workspaceId}/expenses/categories/{categoryId}
# operationId: deleteCategory
export def "workspaces-expenses-categories delete" [
  workspaceId: string
  categoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/expenses/categories/($categoryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an expense category
#
# PUT /v1/workspaces/{workspaceId}/expenses/categories/{categoryId}
# operationId: updateCategory
export def "workspaces-expenses-categories updateCategory" [
  workspaceId: string
  categoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hasUnitPrice: string@bool-completer # Flag whether expense category has unit price or none. (default: false)
  name: string # Represents a valid expense category name. (e.g. Procurement)
  --priceInCents: int # Represents price in cents as integer. (format: int32, e.g. 1000)
  --unit: string # Represents a valid expense category unit. (e.g. piece)
]: any -> record<archived: bool, hasUnitPrice: bool, id: string, name: string, priceInCents: int, unit: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/expenses/categories/($categoryId)")
  let body = {hasUnitPrice: $hasUnitPrice, name: $name, priceInCents: $priceInCents, unit: $unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive an expense category
#
# PATCH /v1/workspaces/{workspaceId}/expenses/categories/{categoryId}/status
# operationId: updateExpenseCategoryStatus
export def "workspaces-expenses-categories-status updateExpenseCategoryStatus" [
  workspaceId: string
  categoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: string@bool-completer # Flag whether to archive the expense category or not. (default: false)
]: any -> record<archived: bool, hasUnitPrice: bool, id: string, name: string, priceInCents: int, unit: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/expenses/categories/($categoryId)/status")
  let body = {archived: $archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an expense
#
# DELETE /v1/workspaces/{workspaceId}/expenses/{expenseId}
# operationId: deleteExpense
export def "workspaces-expenses delete" [
  workspaceId: string
  expenseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/expenses/($expenseId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an expense by ID
#
# GET /v1/workspaces/{workspaceId}/expenses/{expenseId}
# operationId: getExpense
export def "workspaces-expenses get" [
  workspaceId: string
  expenseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<billable: bool, categoryId: string, date: string, fileId: string, id: string, isLocked: bool, locked: bool, notes: string, projectId: string, quantity: float, taskId: string, total: float, userId: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/expenses/($expenseId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an expense
#
# PUT /v1/workspaces/{workspaceId}/expenses/{expenseId}
# operationId: updateExpense
export def "workspaces-expenses updateExpense" [
  workspaceId: string
  expenseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: float # Represents an expense amount as the double data type. (format: double, e.g. 99.5)
  --billable: string@bool-completer # Indicates whether expense is billable or not. (default: false)
  categoryId: string # Represents a category identifier across the system. (e.g. 45y687e29ae1f428e7ebe890)
  changeFields: list # Represents a list of expense change fields. (e.g. [USER, DATE, PROJECT])
  date: string # Provides a valid yyyy-MM-ddThh:mm:ssZ format date. (format: date-time, e.g. 2020-01-01T00:00:00Z)
  file: string # format: binary
  --notes: string # Represents notes for an expense. (e.g. This is a sample note for this expense.)
  --projectId: string # Represents a project identifier across the system. (e.g. 25b687e29ae1f428e7ebe123)
  --taskId: string # Represents a task identifier across the system. (e.g. 25b687e29ae1f428e7ebe123)
  userId: string # Represents a user identifier across the system. (e.g. 89b687e29ae1f428e7ebe912)
]: any -> record<billable: bool, categoryId: string, date: string, fileId: string, id: string, isLocked: bool, locked: bool, notes: string, projectId: string, quantity: float, taskId: string, total: float, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/expenses/($expenseId)")
  let body = {amount: $amount, billable: $billable, categoryId: $categoryId, changeFields: $changeFields, date: $date, file: $file, notes: $notes, projectId: $projectId, taskId: $taskId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Download a receipt
#
# GET /v1/workspaces/{workspaceId}/expenses/{expenseId}/files/{fileId}
# operationId: downloadFile
export def "workspaces-expenses-files downloadFile" [
  fileId: string
  expenseId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/expenses/($expenseId)/files/($fileId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get holidays on a workspace
#
# GET /v1/workspaces/{workspaceId}/holidays
# operationId: getHolidays
export def "workspaces-holidays get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assigned-to: string # If provided, you'll get a filtered list of holidays assigned to user. (e.g. 60f924bafdaf031696ec6218)
]: nothing -> table<automaticTimeEntryCreation: bool, datePeriod: record<endDate: string, startDate: string>, everyoneIncludingNew: bool, id: string, name: string, occursAnnually: bool, projectId: string, taskId: string, userGroupIds: list<string>, userIds: list<string>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "assigned-to" $assigned_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/holidays" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a holiday
#
# POST /v1/workspaces/{workspaceId}/holidays
# operationId: createHoliday
# --automaticTimeEntryCreation shape: {defaultEntities: record, enabled?: bool}
# --datePeriod shape: {endDate: string, startDate: string}
# --userGroups shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
# --users shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
export def "workspaces-holidays createHoliday" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --automaticTimeEntryCreation: record # Provides automatic time entry creation settings. — shape: {defaultEntities: record, enabled?: bool}
  --color: string # Provide color in format ^#(?:[0-9a-fA-F]{6}){1}$. Explanation: A valid color code should start with '#' and consist of six hexadecimal characters, representing a color in hexadecimal format. Color value is in standard RGB hexadecimal format. (e.g. #8BC34A)
  datePeriod: record # Provide startDate and endDate for the holiday. — shape: {endDate: string, startDate: string}
  --everyoneIncludingNew: string@bool-completer # Indicates whether the holiday is shown to new users. (default: false, e.g. true)
  name: string # Provide the name of the holiday. (e.g. Labour Day)
  --occursAnnually: string@bool-completer # Indicates whether the holiday occurs annually. (default: false, e.g. true)
  --userGroups: record # Provide list with user group ids and corresponding status. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
  --users: record # Provide list with user ids and corresponding status. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
]: any -> record<automaticTimeEntryCreation: bool, datePeriod: record<endDate: string, startDate: string>, everyoneIncludingNew: bool, id: string, name: string, occursAnnually: bool, projectId: string, taskId: string, userGroupIds: list<string>, userIds: list<string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/holidays")
  let body = {automaticTimeEntryCreation: $automaticTimeEntryCreation, color: $color, datePeriod: $datePeriod, everyoneIncludingNew: $everyoneIncludingNew, name: $name, occursAnnually: $occursAnnually, userGroups: $userGroups, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get holidays in a specific period
#
# GET /v1/workspaces/{workspaceId}/holidays/in-period
# operationId: getHolidaysInPeriod
export def "workspaces-holidays-in-period get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assigned-to: string # Filter list of holidays assigned to user. (e.g. 60f924bafdaf031696ec6218)
  --start: string # Filter list of holidays starting from start date. Expected date format yyyy-MM-ddThh:mm:ssZ (e.g. 2022-12-03T10:59:59.999Z)
  --end: string # Filter list of holidays ending by end date. Expected date format yyyy-MM-ddThh:mm:ssZ (e.g. 2022-12-05T23:59:59.999Z)
]: nothing -> table<automaticTimeEntryCreation: bool, datePeriod: record<endDate: string, startDate: string>, everyoneIncludingNew: bool, id: string, name: string, occursAnnually: bool, projectId: string, taskId: string, userGroupIds: list<string>, userIds: list<string>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "assigned-to" $assigned_to "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/holidays/in-period" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a holiday
#
# DELETE /v1/workspaces/{workspaceId}/holidays/{holidayId}
# operationId: deleteHoliday
export def "workspaces-holidays delete" [
  workspaceId: string
  holidayId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<automaticTimeEntryCreation: record<defaultEntities: record<projectId: string, taskId: string>, enabled: bool>, color: string, datePeriod: record<endDate: string, startDate: string>, everyoneIncludingNew: bool, id: string, name: string, occursAnnually: bool, userGroupIds: list<string>, userGroups: table<id: string, name: string>, userIds: list<string>, users: table<id: string, name: string>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/holidays/($holidayId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a holiday
#
# PUT /v1/workspaces/{workspaceId}/holidays/{holidayId}
# operationId: updateHoliday
# --automaticTimeEntryCreation shape: {defaultEntities: record, enabled?: bool}
# --datePeriod shape: {endDate: string, startDate: string}
# --userGroups shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL"}
# --users shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE", statuses?: list}
export def "workspaces-holidays updateHoliday" [
  workspaceId: string
  holidayId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --automaticTimeEntryCreation: record # Provides automatic time entry creation settings. — shape: {defaultEntities: record, enabled?: bool}
  --color: string # Provide color in format ^#(?:[0-9a-fA-F]{6}){1}$. Explanation: A valid color code should start with '#' and consist of six hexadecimal characters, representing a color in hexadecimal format. Color value is in standard RGB hexadecimal format. (e.g. #8BC34A)
  datePeriod: record # Provide startDate and endDate for the holiday. — shape: {endDate: string, startDate: string}
  --everyoneIncludingNew: string@bool-completer # Indicates whether the holiday is shown to new users. (default: false, e.g. false)
  name: string # Provide the name you would like to use for updating the holiday. (e.g. New Year's Day)
  --occursAnnually: string@bool-completer # Indicates whether the holiday occurs annually. (default: false, e.g. true)
  --userGroups: record # Provide list with user group ids and corresponding status. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL"}
  --users: record # Provide list with users ids and corresponding status. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE", statuses?: list}
]: any -> record<automaticTimeEntryCreation: bool, datePeriod: record<endDate: string, startDate: string>, everyoneIncludingNew: bool, id: string, name: string, occursAnnually: bool, projectId: string, taskId: string, userGroupIds: list<string>, userIds: list<string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/holidays/($holidayId)")
  let body = {automaticTimeEntryCreation: $automaticTimeEntryCreation, color: $color, datePeriod: $datePeriod, everyoneIncludingNew: $everyoneIncludingNew, name: $name, occursAnnually: $occursAnnually, userGroups: $userGroups, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update workspace billable rate
#
# PUT /v1/workspaces/{workspaceId}/hourly-rate
# operationId: setWorkspaceHourlyRate
export def "workspaces-hourly-rate setWorkspaceHourlyRate" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: int # Represents an amount as integer. (format: int32, e.g. 2000)
  currency: string # Represents a currency. (default: USD, e.g. USD)
  --since: string # Represents a date and time in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
]: any -> record<cakeOrganizationId: string, costRate: record<amount: int, currency: string>, currencies: table<code: string, id: string, isDefault: bool>, featureSubscriptionType: record<addonSubscriptionPlan: string, featurePermissions: list<string>, legacy: bool, paidPlan: bool, regionalAllowed: bool, weight: int>, features: record<ADD_TIME_FOR_OTHERS: string, ADMIN_PANEL: string, ALERTS: string, APPROVAL: string, ATTENDANCE_REPORT: string, AUDIT_LOG: string, AUTOMATIC_LOCK: string, BILLABLE_HOURS: string, BRANDED_REPORTS: string, BREAKS: string, BULK_EDIT: string, CLIENT_CURRENCY: string, CREATION_PERMISSIONS: string, CSV_EXPORT: string, CUSTOM_FIELDS: string, CUSTOM_REPORTING: string, CUSTOM_SUBDOMAIN: string, DECIMAL_FORMAT: string, DISABLE_MANUAL_MODE: string, EDIT_MEMBER_PROFILE: string, EXCLUDE_NON_BILLABLE_FROM_ESTIMATE: string, EXPENSES: string, FAVORITE_ENTRIES: string, FILE_IMPORT: string, FORECASTING: string, GRANT_PROJECT_MANAGER_ROLE: string, HIDE_PAGES: string, HISTORIC_RATES: string, INVOICE_EMAILS: string, INVOICE_REMINDERS: string, INVOICING: string, KIOSK: string, KIOSK_PIN_REQUIRED: string, KIOSK_QR_CODE: string, KIOSK_SESSION_DURATION: string, KIOSK_SIX_DIGIT_PIN: string, LABOR_COST: string, LIMITED_USERS: string, LOCATIONS: string, MANAGER_ROLE: string, MONTHLY_OVERTIME_CALCULATION_PERIOD: string, MULTI_FACTOR_AUTHENTICATION: string, ONE_MONTH_RANGE_REPORTS: string, ONE_YEAR_RANGE_REPORTS: string, PRIVATE_PROJECT_ACCESS: string, PROJECT_BUDGET: string, PROJECT_ESTIMATE: string, PROJECT_TEMPLATES: string, QUICKBOOKS_INTEGRATION: string, RECURRING_ESTIMATES: string, RECURRING_INVOICES: string, REQUIRED_FIELDS: string, SCHEDULED_REPORTS: string, SCHEDULING: string, SCHEDULING_FORECASTING: string, SCIM: string, SCREENSHOTS: string, SHARED_REPORTS: string, SPLIT_TIME_ENTRY: string, SSO: string, SUMMARY_ESTIMATE: string, TARGETS_AND_REMINDERS: string, TASK_RATES: string, TIMESHEET_IMPORT: string, TIME_OFF: string, TIME_TRACKING: string, UNLIMITED_REPORTS: string, UNLIMITED_USER_SEATS: string, USER_CUSTOM_FIELDS: string, USER_IMPORT: string, WEEKLY_OVERTIME_CALCULATION_PERIOD: string, WHO_CAN_CHANGE_TIMEENTRY_BILLABILITY: string, WHO_CAN_SEE_ALL_TIME_ENTRIES: string, WHO_CAN_SEE_PROJECT_STATUS: string, WHO_CAN_SEE_PUBLIC_PROJECTS_ENTRIES: string, WHO_CAN_SEE_TEAMS_DASHBOARD: string, WORKSPACE_LOCK_TIMEENTRIES: string, WORKSPACE_TIME_AUDIT: string, WORKSPACE_TIME_ROUNDING: string, WORKSPACE_TRANSFER: string, XLSX_EXPORT: string>, hourlyRate: record<amount: int, currency: string>, id: string, imageUrl: string, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, subdomain: record<enabled: bool, name: string>, workspaceSettings: record<activeBillableHours: bool, adminOnlyPages: string, automaticLock: record<changeDay: string, dayOfMonth: int, firstDay: string, olderThanPeriod: string, olderThanValue: int, type: string>, canSeeTimeSheet: bool, canSeeTracker: bool, currencyFormat: string, defaultBillableProjects: bool, durationFormat: string, entityCreationPermissions: record<whoCanCreateProjectsAndClients: record, whoCanCreateTags: record, whoCanCreateTasks: record>, forceDescription: bool, forceProjects: bool, forceTags: bool, forceTasks: bool, isProjectPublicByDefault: bool, lockTimeEntries: string, lockTimeZone: string, multiFactorEnabled: bool, numberFormat: string, onlyAdminsCanChangeBillableStatus: bool, onlyAdminsCreateProject: bool, onlyAdminsCreateTag: bool, onlyAdminsCreateTask: bool, onlyAdminsSeeAllTimeEntries: bool, onlyAdminsSeeBillableRates: bool, onlyAdminsSeeDashboard: bool, onlyAdminsSeePublicProjectsEntries: bool, projectFavorites: bool, projectGroupingLabel: string, projectLabel: string, projectPickerSpecialFilter: bool, round: record<minutes: string, round: string>, taskLabel: string, timeRoundingInReports: bool, timeTrackingMode: string, trackTimeDownToSecond: bool, workingDays: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/hourly-rate")
  let body = {amount: $amount, currency: $currency, since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all invoices on a workspace
#
# GET /v1/workspaces/{workspaceId}/invoices
# operationId: getInvoices
export def "workspaces-invoices list" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --statuses: string@statuses-completer # If provided, you'll get a filtered result of invoices that matches the provided string in the user ID linked to the expense. (e.g. [UNSENT, PAID])
  --sort-column: string@sort-column-completer-2 # Valid column name as sorting criteria. Default: ID (e.g. CLIENT)
  --sort-order: string@sort-order-completer # Sort order. Default: ASCENDING (e.g. ASCENDING)
]: nothing -> record<invoices: table<amount: int, balance: int, clientId: string, clientName: string, currency: string, dueDate: string, id: string, issuedDate: string, number: string, paid: int, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "statuses" $statuses "scalar") (serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an invoice
#
# POST /v1/workspaces/{workspaceId}/invoices
# operationId: createInvoice
export def "workspaces-invoices createInvoice" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  clientId: string # Represents a client identifier across the system. (e.g. 98h687e29ae1f428e7ebe707)
  currency: string # Represents the currency used by the invoice. (e.g. USD)
  dueDate: string # Represents an invoice due date in yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2020-06-01T08:00:00Z)
  issuedDate: string # Represents an invoice issued date in yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2020-01-01T08:00:00Z)
  number: string # Represents an invoice number. (e.g. 202306121129)
  --timeViewMode: string@timeViewMode-completer
]: any -> record<billFrom: string, clientId: string, currency: string, dueDate: string, id: string, issuedDate: string, number: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices")
  let body = {clientId: $clientId, currency: $currency, dueDate: $dueDate, issuedDate: $issuedDate, number: $number, timeViewMode: $timeViewMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Filter out invoices
#
# POST /v1/workspaces/{workspaceId}/invoices/info
# operationId: getInvoicesInfo
# --clients shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --companies shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list}
# --issueDate shape: {issue-date-end?: string, issue-date-start?: string}
export def "workspaces-invoices-info post" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clients: record # Represents a project filter for imported items. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --companies: record # Represents a company filter object. If provided, you'll get a filtered list of invoices that matches the specified company filter. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list}
  --exactAmount: int # Represents an invoice amount. If provided, you'll get a filtered list of invoices that has the equal amount as specified. (format: int64, e.g. 1000)
  --exactBalance: int # Represents an invoice balance. If provided, you'll get a filtered list of invoices that has the equal balance as specified. (format: int64, e.g. 1000)
  --greaterThanAmount: int # Represents an invoice amount. If provided, you'll get a filtered list of invoices that has amount greater than specified. (format: int64, e.g. 500)
  --greaterThanBalance: int # Represents an invoice balance. If provided, you'll get a filtered list of invoices that has balance greater than specified. (format: int64, e.g. 500)
  --invoiceNumber: string # If provided, you'll get a filtered list of invoices that contain the provided string in their invoice number. (e.g. Invoice-01)
  --issueDate: record # Represents a time range object. If provided, you'll get a filtered list of invoices that has issue date within the time range specified. — shape: {issue-date-end?: string, issue-date-start?: string}
  --lessThanAmount: int # Represents an invoice amount. If provided, you'll get a filtered list of invoices that has amount less than specified. (format: int64, e.g. 500)
  --lessThanBalance: int # Represents an invoice balance. If provided, you'll get a filtered list of invoices that has balance less than specified. (format: int64, e.g. 500)
  --page: int # Page number. (format: int32, default: 1)
  --pageSize: int # Page size. (format: int32, default: 50)
  --sortColumn: string@sortColumn-completer # Represents the column name to be used as sorting criteria. (e.g. ID)
  --sortOrder: string@sortOrder-completer # Represents the sorting order. (e.g. ASCENDING)
  --statuses: list # Represents a list of invoice statuses. If provided, you'll get a filtered list of invoices that matches any of the invoice status provided. (e.g. [SENT, PAID, PARTIALLY_PAID])
  --strictSearch: string@bool-completer # Flag to toggle on/off strict search mode. When set to true, search by invoice number only will return invoices whose number exactly matches the string value given for the 'invoiceNumber' parameter. When set to false, results will also include invoices whose number contain the string value, but could be longer than the string value itself. For example, if there is an invoice with the number '123456', and the search value is '123', setting strict-name-search to true will not return that invoice in the results, whereas setting it to false will. (default: false)
]: any -> record<invoices: table<amount: int, balance: int, billFrom: string, clientId: string, clientName: string, currency: string, daysOverdue: int, dueDate: string, id: string, issuedDate: string, number: string, paid: int, status: string, visibleZeroFields: record>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/info")
  let body = {clients: $clients, companies: $companies, exactAmount: $exactAmount, exactBalance: $exactBalance, greaterThanAmount: $greaterThanAmount, greaterThanBalance: $greaterThanBalance, invoiceNumber: $invoiceNumber, issueDate: $issueDate, lessThanAmount: $lessThanAmount, lessThanBalance: $lessThanBalance, page: $page, pageSize: $pageSize, sortColumn: $sortColumn, sortOrder: $sortOrder, statuses: $statuses, strictSearch: $strictSearch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an invoice in another language
#
# GET /v1/workspaces/{workspaceId}/invoices/settings
# operationId: getInvoiceSettings
export def "workspaces-invoices-settings get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<defaults: record<companyId: string, defaultImportExpenseItemTypeId: string, defaultImportTimeItemTypeId: string, dueDays: int, itemType: string, itemTypeId: string, notes: string, subject: string, tax: int, tax2: int, tax2Percent: float, taxPercent: float, taxType: string>, exportFields: record<RTL: bool, itemType: bool, quantity: bool, rtl: bool, tax: bool, tax2: bool, unitPrice: bool>, labels: record<amount: string, billFrom: string, billTo: string, description: string, discount: string, dueDate: string, issueDate: string, itemType: string, notes: string, paid: string, quantity: string, subtotal: string, tax: string, tax2: string, total: string, totalAmount: string, unitPrice: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change an invoice language
#
# PUT /v1/workspaces/{workspaceId}/invoices/settings
# operationId: updateInvoiceSettings
# --defaults shape: {companyId?: string, dueDays?: int, itemTypeId?: string, notes: string, subject: string, tax2Percent?: float, taxPercent?: float, taxType?: "COMPOUND"|"SIMPLE"|"NONE"}
# --exportFields shape: {itemType?: bool, quantity?: bool, rtl?: bool, tax?: bool, tax2?: bool, unitPrice?: bool}
# --labels shape: {amount: string, billFrom: string, billTo: string, description: string, discount: string, dueDate: string, issueDate: string, itemType: string, notes: string, paid: string, quantity: string, subtotal: string, tax: string, tax2: string, total: string, totalAmountDue: string, unitPrice: string}
export def "workspaces-invoices-settings updateInvoiceSettings" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --defaults: record # Represents an invoice default settings object. — shape: {companyId?: string, dueDays?: int, itemTypeId?: string, notes: string, subject: string, tax2Percent?: float, taxPercent?: float, taxType?: "COMPOUND"|"SIMPLE"|"NONE"}
  --exportFields: record # Represents an invoice export fields object. — shape: {itemType?: bool, quantity?: bool, rtl?: bool, tax?: bool, tax2?: bool, unitPrice?: bool}
  labels: record # Represents a label customization object. — shape: {amount: string, billFrom: string, billTo: string, description: string, discount: string, dueDate: string, issueDate: string, itemType: string, notes: string, paid: string, quantity: string, subtotal: string, tax: string, tax2: string, total: string, totalAmountDue: string, unitPrice: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/settings")
  let body = {defaults: $defaults, exportFields: $exportFields, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an invoice
#
# DELETE /v1/workspaces/{workspaceId}/invoices/{invoiceId}
# operationId: deleteInvoice
export def "workspaces-invoices delete" [
  workspaceId: string
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an invoice by ID
#
# GET /v1/workspaces/{workspaceId}/invoices/{invoiceId}
# operationId: getInvoice
export def "workspaces-invoices get" [
  workspaceId: string
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<amount: int, balance: int, billFrom: string, calculationType: record<INVOICE_BASED: string, ITEM_BASED: string, value: string>, clientAddress: string, clientId: string, clientName: string, companyId: string, containsImportedExpenses: bool, containsImportedTimes: bool, currency: string, discount: float, discountAmount: int, dueDate: string, id: string, issuedDate: string, items: table<amount: int, applyTaxes: record, description: string, expenseIds: list, importType: string, itemType: string, order: int, quantity: int, timeEntryIds: list, unitPrice: int>, note: string, number: string, paid: int, status: string, subject: string, subtotal: int, tax: float, tax2: float, tax2Amount: int, taxAmount: int, taxType: record<COMPOUND: string, NONE: string, SIMPLE: string, value: string>, userId: string, visibleZeroFields: record<DISCOUNT: string, TAX: string, TAX_2: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an invoice
#
# PUT /v1/workspaces/{workspaceId}/invoices/{invoiceId}
# operationId: updateInvoice
# --taxType shape: {COMPOUND?: "COMPOUND"|"SIMPLE"|"NONE", NONE?: "COMPOUND"|"SIMPLE"|"NONE", SIMPLE?: "COMPOUND"|"SIMPLE"|"NONE", value?: string}
export def "workspaces-invoices updateInvoice" [
  workspaceId: string
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clientId: string # Represents client identifier across the system. (e.g. 98h687e29ae1f428e7ebe707)
  --companyId: string # Represents company identifier across the system. (e.g. 04g687e29ae1f428e7ebe123)
  currency: string # Represents the currency used by the invoice. (e.g. USD)
  discountPercent: float # Represents an invoice discount percent as double. (format: double, e.g. 1.5)
  dueDate: string # Represents an invoice due date in yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2020-06-01T08:00:00Z)
  issuedDate: string # Represents an invoice issued date in yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2020-01-01T08:00:00Z)
  --note: string # Represents an invoice note. (e.g. This is a sample note for this invoice.)
  number: string # Represents an invoice number. (e.g. 202306121129)
  --subject: string # Represents an invoice subject. (e.g. January salary)
  tax2Percent: float # Represents an invoice tax 2 percent as double. (format: double, e.g. 0)
  taxPercent: float # Represents an invoice tax percent as double. (format: double, e.g. 0.5)
  --taxType: record # Represents an invoice taxation type. (e.g. SIMPLE) — shape: {COMPOUND?: "COMPOUND"|"SIMPLE"|"NONE", NONE?: "COMPOUND"|"SIMPLE"|"NONE", SIMPLE?: "COMPOUND"|"SIMPLE"|"NONE", value?: string}
  --visibleZeroFields: string@visibleZeroFields-completer # Represents a list of zero value invoice fields that will be visible. (e.g. ["TAX","TAX_2","DISCOUNT"])
]: any -> record<amount: int, balance: int, billFrom: string, calculationType: record<INVOICE_BASED: string, ITEM_BASED: string, value: string>, clientAddress: string, clientId: string, clientName: string, companyId: string, containsImportedExpenses: bool, containsImportedTimes: bool, currency: string, discount: float, discountAmount: int, dueDate: string, id: string, issuedDate: string, items: table<amount: int, applyTaxes: record, description: string, expenseIds: list, importType: string, itemType: string, order: int, quantity: int, timeEntryIds: list, unitPrice: int>, note: string, number: string, paid: int, status: string, subject: string, subtotal: int, tax: float, tax2: float, tax2Amount: int, taxAmount: int, taxType: record<COMPOUND: string, NONE: string, SIMPLE: string, value: string>, userId: string, visibleZeroFields: record<DISCOUNT: string, TAX: string, TAX_2: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)")
  let body = {clientId: $clientId, companyId: $companyId, currency: $currency, discountPercent: $discountPercent, dueDate: $dueDate, issuedDate: $issuedDate, note: $note, number: $number, subject: $subject, tax2Percent: $tax2Percent, taxPercent: $taxPercent, taxType: $taxType, visibleZeroFields: $visibleZeroFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Duplicate an invoice
#
# POST /v1/workspaces/{workspaceId}/invoices/{invoiceId}/duplicate
# operationId: duplicateInvoice
export def "workspaces-invoices-duplicate duplicateInvoice" [
  invoiceId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<amount: int, balance: int, billFrom: string, calculationType: record<INVOICE_BASED: string, ITEM_BASED: string, value: string>, clientAddress: string, clientId: string, clientName: string, companyId: string, containsImportedExpenses: bool, containsImportedTimes: bool, currency: string, discount: float, discountAmount: int, dueDate: string, id: string, issuedDate: string, items: table<amount: int, applyTaxes: record, description: string, expenseIds: list, importType: string, itemType: string, order: int, quantity: int, timeEntryIds: list, unitPrice: int>, note: string, number: string, paid: int, status: string, subject: string, subtotal: int, tax: float, tax2: float, tax2Amount: int, taxAmount: int, taxType: record<COMPOUND: string, NONE: string, SIMPLE: string, value: string>, userId: string, visibleZeroFields: record<DISCOUNT: string, TAX: string, TAX_2: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)/duplicate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export an invoice
#
# GET /v1/workspaces/{workspaceId}/invoices/{invoiceId}/export
# operationId: exportInvoice
export def "workspaces-invoices-export exportInvoice" [
  invoiceId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userLocale: string # Represents a locale. (e.g. en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "userLocale" $userLocale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)/export" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add item to an invoice
#
# POST /v1/workspaces/{workspaceId}/invoices/{invoiceId}/items
# operationId: addInvoiceItem
export def "workspaces-invoices-items addInvoiceItem" [
  workspaceId: string
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  applyTaxes: string@applyTaxes-completer # Represents taxes applied to the invoice item. Applies only when the specified taxes are active on the invoice. (e.g. TAX1TAX2)
  description: string # Represents an invoice item description. (e.g. This is a description of an invoice item.)
  itemType: string # Represents an item type. (e.g. Service)
  quantity: int # Represents an item quantity. (format: int64, e.g. 10000)
  unitPrice: int # Represents an item unit price. (format: int64, e.g. 500)
]: any -> record<amount: int, balance: int, billFrom: string, calculationType: record<INVOICE_BASED: string, ITEM_BASED: string, value: string>, clientAddress: string, clientId: string, clientName: string, companyId: string, containsImportedExpenses: bool, containsImportedTimes: bool, currency: string, discount: float, discountAmount: int, dueDate: string, id: string, issuedDate: string, items: table<amount: int, applyTaxes: record, description: string, expenseIds: list, importType: string, itemType: string, order: int, quantity: int, timeEntryIds: list, unitPrice: int>, note: string, number: string, paid: int, status: string, subject: string, subtotal: int, tax: float, tax2: float, tax2Amount: int, taxAmount: int, taxType: record<COMPOUND: string, NONE: string, SIMPLE: string, value: string>, userId: string, visibleZeroFields: record<DISCOUNT: string, TAX: string, TAX_2: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)/items")
  let body = {applyTaxes: $applyTaxes, description: $description, itemType: $itemType, quantity: $quantity, unitPrice: $unitPrice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import time entries and expenses to an invoice
#
# POST /v1/workspaces/{workspaceId}/invoices/{invoiceId}/items/import
# operationId: importTimeEntriesAndExpenses
# --projectFilter shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
export def "workspaces-invoices-items-import importTimeEntriesAndExpenses" [
  workspaceId: string
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expenseFieldsForDetailedGroup: list # Represents a set of expense fields to include when using the DETAILED expense grouping type. (default: NOTE, e.g. [NOTE])
  --expensesGroupBy: string@expensesGroupBy-completer # Represents a group field when using the GROUPED expense group type. (default: PROJECT, e.g. CATEGORY)
  --expensesGroupType: string@expensesGroupType-completer # Represents an expense group type. (default: DETAILED)
  --body-from: string # Represents date and time in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2025-06-01T00:00:00Z)
  --importExpenses: string@bool-completer # Indicates if billable expenses should be imported alongside time entries. (default: false)
  projectFilter: record # Represents a project filter for imported items. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --roundTimeEntryDuration: string@bool-completer # Indicates if imported time entry durations should be rounded to the nearest 15 minute interval. (default: false)
  --timeEntryFieldsForDetailedGroup: list # Represents a set of time entry fields to include when using DETAILED time entry grouping type. (e.g. [PROJECT, DESCRIPTION])
  timeEntryGroupType: string@timeEntryGroupType-completer # Represents a time entry group type. (e.g. GROUPED)
  --timeEntryPrimaryGroupBy: string@timeEntryPrimaryGroupBy-completer # Represents a primary group field when using the GROUPED time entry grouping type. (e.g. PROJECT)
  --timeEntrySecondaryGroupBy: string@timeEntrySecondaryGroupBy-completer # Represents a secondary group field when using the GROUPED time entry grouping type. Should not have the same grouping type as the primary group field. (e.g. TASK)
  --body-to: string # Represents date and time in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2025-06-07T00:00:00Z)
]: any -> record<amount: int, balance: int, billFrom: string, calculationType: record<INVOICE_BASED: string, ITEM_BASED: string, value: string>, clientAddress: string, clientId: string, clientName: string, companyId: string, containsImportedExpenses: bool, containsImportedTimes: bool, currency: string, discount: float, discountAmount: int, dueDate: string, id: string, issuedDate: string, items: table<amount: int, applyTaxes: record, description: string, expenseIds: list, importType: string, itemType: string, order: int, quantity: int, timeEntryIds: list, unitPrice: int>, note: string, number: string, paid: int, status: string, subject: string, subtotal: int, tax: float, tax2: float, tax2Amount: int, taxAmount: int, taxType: record<COMPOUND: string, NONE: string, SIMPLE: string, value: string>, userId: string, visibleZeroFields: record<DISCOUNT: string, TAX: string, TAX_2: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)/items/import")
  let body = {expenseFieldsForDetailedGroup: $expenseFieldsForDetailedGroup, expensesGroupBy: $expensesGroupBy, expensesGroupType: $expensesGroupType, from: $body_from, importExpenses: $importExpenses, projectFilter: $projectFilter, roundTimeEntryDuration: $roundTimeEntryDuration, timeEntryFieldsForDetailedGroup: $timeEntryFieldsForDetailedGroup, timeEntryGroupType: $timeEntryGroupType, timeEntryPrimaryGroupBy: $timeEntryPrimaryGroupBy, timeEntrySecondaryGroupBy: $timeEntrySecondaryGroupBy, to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete item from an invoice
#
# DELETE /v1/workspaces/{workspaceId}/invoices/{invoiceId}/items/{order}
# operationId: removeInvoiceItem
export def "workspaces-invoices-items removeInvoiceItem" [
  workspaceId: string
  invoiceId: string
  order: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<amount: int, balance: int, billFrom: string, calculationType: record<INVOICE_BASED: string, ITEM_BASED: string, value: string>, clientAddress: string, clientId: string, clientName: string, companyId: string, containsImportedExpenses: bool, containsImportedTimes: bool, currency: string, discount: float, discountAmount: int, dueDate: string, id: string, issuedDate: string, items: table<amount: int, applyTaxes: record, description: string, expenseIds: list, importType: string, itemType: string, order: int, quantity: int, timeEntryIds: list, unitPrice: int>, note: string, number: string, paid: int, status: string, subject: string, subtotal: int, tax: float, tax2: float, tax2Amount: int, taxAmount: int, taxType: record<COMPOUND: string, NONE: string, SIMPLE: string, value: string>, userId: string, visibleZeroFields: record<DISCOUNT: string, TAX: string, TAX_2: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)/items/($order)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get payments for an invoice
#
# GET /v1/workspaces/{workspaceId}/invoices/{invoiceId}/payments
# operationId: getPaymentsForInvoice
export def "workspaces-invoices-payments get" [
  workspaceId: string
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
]: nothing -> table<amount: int, author: string, date: string, id: string, note: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add payment to an invoice
#
# POST /v1/workspaces/{workspaceId}/invoices/{invoiceId}/payments
# operationId: createInvoicePayment
export def "workspaces-invoices-payments createInvoicePayment" [
  workspaceId: string
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amount: int # Represents an invoice payment amount as long. (format: int64, e.g. 100)
  --note: string # Represents an invoice payment note. (e.g. This is a sample note for this invoice payment.)
  --paymentDate: string # Represents an invoice payment date in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2021-01-01T12:00:00Z)
]: any -> record<amount: int, balance: int, billFrom: string, calculationType: record<INVOICE_BASED: string, ITEM_BASED: string, value: string>, clientAddress: string, clientId: string, clientName: string, companyId: string, containsImportedExpenses: bool, containsImportedTimes: bool, currency: string, discount: float, discountAmount: int, dueDate: string, id: string, issuedDate: string, items: table<amount: int, applyTaxes: record, description: string, expenseIds: list, importType: string, itemType: string, order: int, quantity: int, timeEntryIds: list, unitPrice: int>, note: string, number: string, paid: int, status: string, subject: string, subtotal: int, tax: float, tax2: float, tax2Amount: int, taxAmount: int, taxType: record<COMPOUND: string, NONE: string, SIMPLE: string, value: string>, userId: string, visibleZeroFields: record<DISCOUNT: string, TAX: string, TAX_2: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)/payments")
  let body = {amount: $amount, note: $note, paymentDate: $paymentDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete payment from an invoice
#
# DELETE /v1/workspaces/{workspaceId}/invoices/{invoiceId}/payments/{paymentId}
# operationId: deletePaymentById
export def "workspaces-invoices-payments delete" [
  invoiceId: string
  workspaceId: string
  paymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<amount: int, balance: int, billFrom: string, calculationType: record<INVOICE_BASED: string, ITEM_BASED: string, value: string>, clientAddress: string, clientId: string, clientName: string, companyId: string, containsImportedExpenses: bool, containsImportedTimes: bool, currency: string, discount: float, discountAmount: int, dueDate: string, id: string, issuedDate: string, items: table<amount: int, applyTaxes: record, description: string, expenseIds: list, importType: string, itemType: string, order: int, quantity: int, timeEntryIds: list, unitPrice: int>, note: string, number: string, paid: int, status: string, subject: string, subtotal: int, tax: float, tax2: float, tax2Amount: int, taxAmount: int, taxType: record<COMPOUND: string, NONE: string, SIMPLE: string, value: string>, userId: string, visibleZeroFields: record<DISCOUNT: string, TAX: string, TAX_2: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)/payments/($paymentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change an invoice status
#
# PATCH /v1/workspaces/{workspaceId}/invoices/{invoiceId}/status
# operationId: changeInvoiceStatus
export def "workspaces-invoices-status changeInvoiceStatus" [
  workspaceId: string
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --invoiceStatus: string@invoiceStatus-completer # Represents the invoice status to be set. (e.g. PAID)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/invoices/($invoiceId)/status")
  let body = {invoiceStatus: $invoiceStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /v1/workspaces/{workspaceId}/limited-users
#
# operationId: addLimitedUsersWithInfo
# --users item shape: {costRate?: int, hourlyRate?: int, name: string, userCustomFields?: list, userGroups?: list, weekStart?: "MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", workCapacity?: string, workingDays?: list}
export def "workspaces-limited-users addLimitedUsersWithInfo" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  users: list # item shape: {costRate?: int, hourlyRate?: int, name: string, userCustomFields?: list, userGroups?: list, weekStart?: "MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", workCapacity?: string, workingDays?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/limited-users")
  let body = {users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a member's profile
#
# GET /v1/workspaces/{workspaceId}/member-profile/{userId}
# operationId: getMemberProfile
export def "workspaces-member-profile get" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<email: string, hasPassword: bool, hasPendingApprovalRequest: bool, imageUrl: string, name: string, userCustomFieldValues: table<customField: record, customFieldId: string, name: string, sourceType: string, type: string, userId: string, value: record>, weekStart: string, workCapacity: string, workingDays: string, workspaceNumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/member-profile/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a member's profile
#
# PATCH /v1/workspaces/{workspaceId}/member-profile/{userId}
# operationId: updateMemberProfileWithAdditionalData
# --userCustomFields item shape: {customFieldId: string, value?: record}
@deprecated --flag name
export def "workspaces-member-profile updateMemberProfileWithAdditionalData" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --imageUrl: string # Represents an image url. A field that can only be updated for limited users. (e.g. https://www.url.com/imageurl-1234567890.jpg)
  --name: string # This body field is deprecated and can only be updated for limited users. Represents name of the user and can be changed on the CAKE.com Account profile page. (DEPRECATED, e.g. John Doe)
  --removeProfileImage: string@bool-completer # Indicates whether to remove profile image or not. A field that can only be updated for limited users. (default: false)
  --userCustomFields: list # Represents a list of upsert user custom field objects. — item shape: {customFieldId: string, value?: record}
  --weekStart: string@weekStart-completer # Represents a day of the week. (e.g. MONDAY)
  --workCapacity: string # Represents work capacity as a time duration in the ISO-8601 format. For example, for a 7hr work day, input should be PT7H. (e.g. PT7H)
  --workingDays: string@workingDays-completer # Represents a list of days of the week. (e.g. ["MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY"])
]: any -> record<email: string, hasPassword: bool, hasPendingApprovalRequest: bool, imageUrl: string, name: string, userCustomFieldValues: table<customField: record, customFieldId: string, name: string, sourceType: string, type: string, userId: string, value: record>, weekStart: string, workCapacity: string, workingDays: string, workspaceNumber: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/member-profile/($userId)")
  let body = {imageUrl: $imageUrl, name: $name, removeProfileImage: $removeProfileImage, userCustomFields: $userCustomFields, weekStart: $weekStart, workCapacity: $workCapacity, workingDays: $workingDays} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all projects on a workspace
#
# GET /v1/workspaces/{workspaceId}/projects
# operationId: getProjects
export def "workspaces-projects list" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # If provided, you'll get a filtered list of projects that contains the provided string in the project name. (e.g. Software Development)
  --strict-name-search: string@bool-completer # Flag to toggle on/off strict search mode. When set to true, search by name will only return projects whose name exactly matches the string value given for the 'name' parameter. When set to false, results will also include projects whose name contain the string value, but could be longer than the string value itself. For example, if there is a project with the name 'applications', and the search value is 'app', setting strict-name-search to true will not return that project in the results, whereas setting it to false will. (default: false)
  --archived: string@bool-completer # If provided and set to true, you'll only get archived projects. If omitted, you'll get both archived and non-archived projects. (default: false)
  --billable: string@bool-completer # If provided and set to true, you'll only get billable projects. If omitted, you'll get both billable and non-billable projects. (default: false)
  --clients: list # If provided, you'll get a filtered list of projects that contain clients which match any of the provided ids. (e.g. [5a0ab5acb07987125438b60f, 64c777ddd3fcab07cfbb210c])
  --contains-client: string@bool-completer # If set to true, you'll get a filtered list of projects that contain clients which match the provided id(s) in 'clients' field. If set to false, you'll get a filtered list of projects which do NOT contain clients that match the provided id(s) in 'clients' field. (default: true)
  --client-status: string@client-status-completer # Filters projects based on client status provided. (e.g. ACTIVE)
  --users: list # If provided, you'll get a filtered list of projects that contain users which match any of the provided ids. (e.g. [5a0ab5acb07987125438b60f, 64c777ddd3fcab07cfbb210c])
  --contains-user: string@bool-completer # If set to true, you'll get a filtered list of projects that contain users which match the provided id(s) in 'users' field. If set to false, you'll get a filtered list of projects which do NOT contain users which match the provided id(s) in 'users' field. (default: true)
  --user-status: string@user-status-completer # Filters projects based on user status provided. (e.g. ALL)
  --is-template: string@bool-completer # Filters projects based on whether they are used as a template or not. (default: false)
  --sort-column: string@sort-column-completer-3 # Sorts the results by the given column/field. (e.g. NAME)
  --sort-order: string@sort-order-completer # Sorting mode. (e.g. ASCENDING)
  --hydrated: string@bool-completer # If set to true, results will contain additional information about the project. (default: false)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --access: string@access-completer # Valid set of string(s). If provided, you'll get a filtered list of projects that matches the provided access. (e.g. PUBLIC)
  --expense-limit: int # Represents the maximum number of expenses to fetch. (format: int32, default: 20, e.g. 10)
  --expense-date: string # If provided, you will get expenses dated before the provided value in yyyy-MM-dd format. (e.g. 2024-12-31)
  --userGroups: list # If provided, you'll get a filtered list of projects that contain groups which match any of the provided ids. (e.g. [5a0ab5acb07987125438b60f, 64c777ddd3fcab07cfbb210c])
  --contains-group: string@bool-completer # If set to true, you'll get a filtered list of projects that contain groups which match the provided id(s) in 'userGroups' field. If set to false, you'll get a filtered list of projects which do NOT contain groups which match the provided id(s) in 'userGroups' field. (default: true)
]: nothing -> table<archived: bool, billable: bool, budgetEstimate: record<active: bool, estimate: int, includeExpenses: bool, resetOption: string, type: string>, color: string, costRate: record<amount: int, currency: string>, duration: string, estimate: record<estimate: string, type: string>, hourlyRate: record<amount: int, currency: string>, id: string, memberships: list<record>, name: string, note: string, public: bool, template: bool, timeEstimate: record<active: bool, estimate: string, includeNonBillable: bool, resetOption: string, type: string>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "strict-name-search" $strict_name_search "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "billable" $billable "scalar") (serialize-qp "clients" $clients "multi") (serialize-qp "contains-client" $contains_client "scalar") (serialize-qp "client-status" $client_status "scalar") (serialize-qp "users" $users "multi") (serialize-qp "contains-user" $contains_user "scalar") (serialize-qp "user-status" $user_status "scalar") (serialize-qp "is-template" $is_template "scalar") (serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar") (serialize-qp "hydrated" $hydrated "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "access" $access "scalar") (serialize-qp "expense-limit" $expense_limit "scalar") (serialize-qp "expense-date" $expense_date "scalar") (serialize-qp "userGroups" $userGroups "multi") (serialize-qp "contains-group" $contains_group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new project
#
# POST /v1/workspaces/{workspaceId}/projects
# operationId: createNewProject
# --costRate shape: {amount: int, since?: string}
# --estimate shape: {estimate?: string, type?: "AUTO"|"MANUAL"}
# --hourlyRate shape: {amount: int, since?: string}
# --memberships item shape: {hourlyRate?: record, membershipStatus?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL", membershipType?: "WORKSPACE"|"PROJECT"|"USERGROUP", userId?: string}
# --tasks item shape: {assigneeId?: string, assigneeIds?: list, billable?: bool, budgetEstimate?: int, costRate?: record, estimate?: string, hourlyRate?: record, id?: string, name: string, projectId?: string, status?: string, userGroupIds?: list}
export def "workspaces-projects createNewProject" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --billable: string@bool-completer # Indicates whether project is billable or not. (default: false)
  --clientId: string # Represents client identifier across the system. (e.g. 9t641568b07987035750704)
  --color: string # Color format ^#(?:[0-9a-fA-F]{6}){1}$. Explanation: A valid color code should start with '#' and consist of six hexadecimal characters, representing a color in hexadecimal format. Color value is in standard RGB hexadecimal format. (e.g. #000000)
  --costRate: record # shape: {amount: int, since?: string}
  --estimate: record # Represents an estimate request object. — shape: {estimate?: string, type?: "AUTO"|"MANUAL"}
  --hourlyRate: record # shape: {amount: int, since?: string}
  --isPublic: string@bool-completer # Indicates whether project is public or not. (default: false)
  --memberships: list # Represents a list of membership request objects. — item shape: {hourlyRate?: record, membershipStatus?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL", membershipType?: "WORKSPACE"|"PROJECT"|"USERGROUP", userId?: string}
  name: string # Represents a project name. (e.g. Software Development)
  --note: string # Represents project note. (e.g. This is a sample note for the project.)
  --tasks: list # Represents a list of task request objects. — item shape: {assigneeId?: string, assigneeIds?: list, billable?: bool, budgetEstimate?: int, costRate?: record, estimate?: string, hourlyRate?: record, id?: string, name: string, projectId?: string, status?: string, userGroupIds?: list}
]: any -> record<archived: bool, billable: bool, budgetEstimate: record<active: bool, estimate: int, includeExpenses: bool, resetOption: string, type: string>, clientId: string, clientName: string, color: string, costRate: record<amount: int, currency: string>, duration: string, estimate: record<estimate: string, type: string>, estimateReset: record<dayOfMonth: int, dayOfWeek: string, hour: int, interval: string, month: string>, hourlyRate: record<amount: int, currency: string>, id: string, isPublic: bool, isTemplate: bool, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, note: string, public: bool, template: bool, timeEstimate: record<active: bool, estimate: string, includeNonBillable: bool, resetOption: string, type: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects")
  let body = {billable: $billable, clientId: $clientId, color: $color, costRate: $costRate, estimate: $estimate, hourlyRate: $hourlyRate, isPublic: $isPublic, memberships: $memberships, name: $name, note: $note, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create project from a template
#
# POST /v1/workspaces/{workspaceId}/projects/from-template
# operationId: createProjectFromTemplate
export def "workspaces-projects-from-template createProjectFromTemplate" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clientId: string # Represents a client identifier across the system. (e.g. 9t641568b07987035750704)
  --color: string # Color format ^#(?:[0-9a-fA-F]{6}){1}$. Explanation: A valid color code should start with '#' and consist of six hexadecimal characters, representing a color in hexadecimal format. Color value is in standard RGB hexadecimal format. (e.g. #000000)
  --isPublic: string@bool-completer # Indicates whether the project is public or not. (default: false)
  name: string # Represents a project name. (e.g. Software Development)
  templateProjectId: string # Represents a project identifier across the system. (e.g. 5b641568b07987035750505e)
]: any -> record<archived: bool, billable: bool, budgetEstimate: record<active: bool, estimate: int, includeExpenses: bool, resetOption: string, type: string>, clientId: string, clientName: string, color: string, costRate: record<amount: int, currency: string>, duration: string, estimate: record<estimate: string, type: string>, estimateReset: record<dayOfMonth: int, dayOfWeek: string, hour: int, interval: string, month: string>, hourlyRate: record<amount: int, currency: string>, id: string, isPublic: bool, isTemplate: bool, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, note: string, public: bool, template: bool, timeEstimate: record<active: bool, estimate: string, includeNonBillable: bool, resetOption: string, type: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/from-template")
  let body = {clientId: $clientId, color: $color, isPublic: $isPublic, name: $name, templateProjectId: $templateProjectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a project from a workspace
#
# DELETE /v1/workspaces/{workspaceId}/projects/{projectId}
# operationId: deleteProject
export def "workspaces-projects delete" [
  workspaceId: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, billable: bool, budgetEstimate: record<active: bool, estimate: int, includeExpenses: bool, resetOption: string, type: string>, clientId: string, clientName: string, color: string, costRate: record<amount: int, currency: string>, duration: string, estimate: record<estimate: string, type: string>, estimateReset: record<dayOfMonth: int, dayOfWeek: string, hour: int, interval: string, month: string>, hourlyRate: record<amount: int, currency: string>, id: string, isPublic: bool, isTemplate: bool, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, note: string, public: bool, template: bool, timeEstimate: record<active: bool, estimate: string, includeNonBillable: bool, resetOption: string, type: string>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find a project by ID
#
# GET /v1/workspaces/{workspaceId}/projects/{projectId}
# operationId: getProject
export def "workspaces-projects get" [
  workspaceId: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hydrated: string@bool-completer # If set to true, results will contain additional information about the project (default: false)
  --custom-field-entity-type: string # If provided, you'll get a filtered list of custom fields that matches the provided string with the custom field entity type. (default: TIMEENTRY, e.g. TIMEENTRY)
  --expense-limit: int # Represents the maximum number of expenses to fetch. (format: int32, default: 20, e.g. 10)
  --expense-date: string # If provided, you will get expenses dated before the provided value in yyyy-MM-dd format. (e.g. 2024-12-31)
]: nothing -> record<archived: bool, billable: bool, budgetEstimate: record<active: bool, estimate: int, includeExpenses: bool, resetOption: string, type: string>, color: string, costRate: record<amount: int, currency: string>, duration: string, estimate: record<estimate: string, type: string>, hourlyRate: record<amount: int, currency: string>, id: string, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, note: string, public: bool, template: bool, timeEstimate: record<active: bool, estimate: string, includeNonBillable: bool, resetOption: string, type: string>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "hydrated" $hydrated "scalar") (serialize-qp "custom-field-entity-type" $custom_field_entity_type "scalar") (serialize-qp "expense-limit" $expense_limit "scalar") (serialize-qp "expense-date" $expense_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a project on a workspace
#
# PUT /v1/workspaces/{workspaceId}/projects/{projectId}
# operationId: updateProject
# --costRate shape: {amount: int, since?: string}
# --hourlyRate shape: {amount: int, since?: string}
export def "workspaces-projects updateProject" [
  workspaceId: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: string@bool-completer # Indicates whether project is archived or not. (default: false)
  --billable: string@bool-completer # Indicates whether project is billable or not. (default: false)
  --clientId: string # Represents client identifier across the system. (e.g. 9t641568b07987035750704)
  --color: string # Color format ^#(?:[0-9a-fA-F]{6}){1}$. Explanation: A valid color code should start with '#' and consist of six hexadecimal characters, representing a color in hexadecimal format. Color value is in standard RGB hexadecimal format. (e.g. #000000)
  --costRate: record # shape: {amount: int, since?: string}
  --hourlyRate: record # shape: {amount: int, since?: string}
  --isPublic: string@bool-completer # Indicates whether project is public or not. (default: false)
  --name: string # Represents a project name. (e.g. Software Development)
  --note: string # Represents project note. (e.g. This is a sample note for the project.)
]: any -> record<archived: bool, billable: bool, budgetEstimate: record<active: bool, estimate: int, includeExpenses: bool, resetOption: string, type: string>, clientId: string, clientName: string, color: string, costRate: record<amount: int, currency: string>, duration: string, estimate: record<estimate: string, type: string>, estimateReset: record<dayOfMonth: int, dayOfWeek: string, hour: int, interval: string, month: string>, hourlyRate: record<amount: int, currency: string>, id: string, isPublic: bool, isTemplate: bool, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, note: string, public: bool, template: bool, timeEstimate: record<active: bool, estimate: string, includeNonBillable: bool, resetOption: string, type: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)")
  let body = {archived: $archived, billable: $billable, clientId: $clientId, color: $color, costRate: $costRate, hourlyRate: $hourlyRate, isPublic: $isPublic, name: $name, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get custom fields on a project
#
# GET /v1/workspaces/{workspaceId}/projects/{projectId}/custom-fields
# operationId: getCustomFieldsOfProject
export def "workspaces-projects-custom-fields get" [
  workspaceId: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # If provided, you'll get a filtered list of custom fields that matches the provided string with the custom field status. (e.g. INACTIVE)
  --entity-type: string # If provided, you'll get a filtered list of custom fields that matches the provided string with the custom field entity type. (e.g. TIMEENTRY)
]: nothing -> table<allowedValues: list<string>, description: string, entityType: string, id: string, name: string, onlyAdminCanEdit: bool, placeholder: string, projectDefaultValues: list<record>, required: bool, status: string, type: string, workspaceDefaultValue: record, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "entity-type" $entity_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/custom-fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove custom field from a project
#
# DELETE /v1/workspaces/{workspaceId}/projects/{projectId}/custom-fields/{customFieldId}
# operationId: removeDefaultValueOfProject
export def "workspaces-projects-custom-fields removeDefaultValueOfProject" [
  workspaceId: string
  projectId: string
  customFieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allowedValues: list<string>, description: string, entityType: string, id: string, name: string, onlyAdminCanEdit: bool, placeholder: string, projectDefaultValues: table<projectId: string, status: string, value: record>, required: bool, status: string, type: string, workspaceDefaultValue: record, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/custom-fields/($customFieldId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update custom field on a project
#
# PATCH /v1/workspaces/{workspaceId}/projects/{projectId}/custom-fields/{customFieldId}
# operationId: editProjectCustomFieldDefaultValue
export def "workspaces-projects-custom-fields editProjectCustomFieldDefaultValue" [
  workspaceId: string
  projectId: string
  customFieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --defaultValue: record # Represents a custom field's default value. (e.g. Manila)
  --status: string@status-completer-1 # Represents a custom field status. (e.g. VISIBLE)
]: any -> record<allowedValues: list<string>, description: string, entityType: string, id: string, name: string, onlyAdminCanEdit: bool, placeholder: string, projectDefaultValues: table<projectId: string, status: string, value: record>, required: bool, status: string, type: string, workspaceDefaultValue: record, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/custom-fields/($customFieldId)")
  let body = {defaultValue: $defaultValue, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update project estimate
#
# PATCH /v1/workspaces/{workspaceId}/projects/{projectId}/estimate
# operationId: updateEstimate
# --budgetEstimate shape: {active?: bool, estimate?: int, includeExpenses?: bool, resetOption?: "WEEKLY"|"MONTHLY"|"YEARLY", type?: "AUTO"|"MANUAL"}
# --estimateReset shape: {active?: bool, dayOfMonth?: int, dayOfWeek?: "MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", hour?: int, interval?: "WEEKLY"|"MONTHLY"|"YEARLY", isActive?: bool, month?: "JANUARY"|"FEBRUARY"|"MARCH"|"APRIL"|"MAY"|"JUNE"|"JULY"|"AUGUST"|"SEPTEMBER"|"OCTOBER"|"NOVEMBER"|"DECEMBER"}
# --timeEstimate shape: {active?: bool, estimate?: string, includeNonBillable?: bool, resetOption?: "WEEKLY"|"MONTHLY"|"YEARLY", type?: "AUTO"|"MANUAL"}
export def "workspaces-projects-estimate updateEstimate" [
  workspaceId: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --budgetEstimate: record # Represents estimate with options request object. — shape: {active?: bool, estimate?: int, includeExpenses?: bool, resetOption?: "WEEKLY"|"MONTHLY"|"YEARLY", type?: "AUTO"|"MANUAL"}
  --estimateReset: record # Represents estimate reset request object. — shape: {active?: bool, dayOfMonth?: int, dayOfWeek?: "MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", hour?: int, interval?: "WEEKLY"|"MONTHLY"|"YEARLY", isActive?: bool, month?: "JANUARY"|"FEBRUARY"|"MARCH"|"APRIL"|"MAY"|"JUNE"|"JULY"|"AUGUST"|"SEPTEMBER"|"OCTOBER"|"NOVEMBER"|"DECEMBER"}
  --timeEstimate: record # Represents project time estimate request object. — shape: {active?: bool, estimate?: string, includeNonBillable?: bool, resetOption?: "WEEKLY"|"MONTHLY"|"YEARLY", type?: "AUTO"|"MANUAL"}
]: any -> record<archived: bool, billable: bool, budgetEstimate: record<active: bool, estimate: int, includeExpenses: bool, resetOption: string, type: string>, clientId: string, clientName: string, color: string, costRate: record<amount: int, currency: string>, duration: string, estimate: record<estimate: string, type: string>, estimateReset: record<dayOfMonth: int, dayOfWeek: string, hour: int, interval: string, month: string>, hourlyRate: record<amount: int, currency: string>, id: string, isPublic: bool, isTemplate: bool, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, note: string, public: bool, template: bool, timeEstimate: record<active: bool, estimate: string, includeNonBillable: bool, resetOption: string, type: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/estimate")
  let body = {budgetEstimate: $budgetEstimate, estimateReset: $estimateReset, timeEstimate: $timeEstimate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update project memberships
#
# PATCH /v1/workspaces/{workspaceId}/projects/{projectId}/memberships
# operationId: updateMemberships
# --memberships item shape: {costRate?: record, hourlyRate?: record, userId: string}
# --userGroups shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
export def "workspaces-projects-memberships updateMemberships" [
  workspaceId: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  memberships: list # Represents a list of users with id and rates request objects. — item shape: {costRate?: record, hourlyRate?: record, userId: string}
  --userGroups: record # Provide list with user group ids and corresponding status. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
]: any -> record<archived: bool, billable: bool, budgetEstimate: record<active: bool, estimate: int, includeExpenses: bool, resetOption: string, type: string>, clientId: string, clientName: string, color: string, costRate: record<amount: int, currency: string>, duration: string, estimate: record<estimate: string, type: string>, estimateReset: record<dayOfMonth: int, dayOfWeek: string, hour: int, interval: string, month: string>, hourlyRate: record<amount: int, currency: string>, id: string, isPublic: bool, isTemplate: bool, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, note: string, public: bool, template: bool, timeEstimate: record<active: bool, estimate: string, includeNonBillable: bool, resetOption: string, type: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/memberships")
  let body = {memberships: $memberships, userGroups: $userGroups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign/remove users to/from the project
#
# POST /v1/workspaces/{workspaceId}/projects/{projectId}/memberships
# operationId: addUsersToProject
# --userGroups shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
export def "workspaces-projects-memberships addUsersToProject" [
  workspaceId: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --remove: string@bool-completer # Setting this flag to 'true' will remove the given users from the project. (default: false)
  --userGroups: record # Provide list with user group ids and corresponding status. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
  --userIds: list # Represents array of user ids which should be added/removed. (e.g. [45b687e29ae1f428e7ebe123, 67s687e29ae1f428e7ebe678])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/memberships")
  let body = {remove: $remove, userGroups: $userGroups, userIds: $userIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find tasks on a project
#
# GET /v1/workspaces/{workspaceId}/projects/{projectId}/tasks
# operationId: getTasks
export def "workspaces-projects-tasks list" [
  projectId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # If provided, you'll get a filtered list of tasks that matches the provided string in their name. (e.g. Bugfixing)
  --strict-name-search: string@bool-completer # Flag to toggle on/off strict search mode. When set to true, search by name only will return tasks whose name exactly matches the string value given for the 'name' parameter. When set to false, results will also include tasks whose name contain the string value, but could be longer than the string value itself. For example, if there is a task with the name 'applications', and the search value is 'app', setting strict-name-search to true will not return that task in the results, whereas setting it to false will. (default: false)
  --is-active: string@bool-completer # Filters search results whether task is active or not. (default: false)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --sort-column: string@sort-column-completer-4 # Represents the column as criteria for sorting tasks. (e.g. ID)
  --sort-order: string@sort-order-completer # Sorting mode. (e.g. ASCENDING)
]: nothing -> table<assigneeId: string, assigneeIds: list<string>, billable: bool, budgetEstimate: int, costRate: record<amount: int, currency: string>, duration: string, estimate: string, hourlyRate: record<amount: int, currency: string>, id: string, name: string, projectId: string, status: record<ACTIVE: string, ALL: string, DONE: string, active: bool>, userGroupIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "strict-name-search" $strict_name_search "scalar") (serialize-qp "is-active" $is_active "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new task on a project
#
# POST /v1/workspaces/{workspaceId}/projects/{projectId}/tasks
# operationId: createTask
@deprecated --flag assigneeId
export def "workspaces-projects-tasks createTask" [
  projectId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contains-assignee: string@bool-completer # Flag to set whether task will have assignee or none. (default: true)
  --assigneeId: string # DEPRECATED
  --assigneeIds: list # Represents list of assignee ids for the task. (e.g. [45b687e29ae1f428e7ebe123, 67s687e29ae1f428e7ebe678])
  --budgetEstimate: int # Represents a task budget estimate as long. (format: int64, e.g. 10000)
  --estimate: string # Represents a task duration estimate in ISO-8601 format. (e.g. PT1H30M)
  --id: string # Represents task identifier across the system. (e.g. 57a687e29ae1f428e7ebe107)
  name: string # Represents task name. (e.g. Bugfixing)
  --status: string@status-completer-2 # Represents task status. (e.g. DONE)
  --userGroupIds: list # Represents list of user group ids for the task. (e.g. [67b687e29ae1f428e7ebe123, 12s687e29ae1f428e7ebe678])
]: any -> record<assigneeId: string, assigneeIds: list<string>, billable: bool, budgetEstimate: int, costRate: record<amount: int, currency: string>, duration: string, estimate: string, hourlyRate: record<amount: int, currency: string>, id: string, name: string, projectId: string, status: record<ACTIVE: string, ALL: string, DONE: string, active: bool>, userGroupIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "contains-assignee" $contains_assignee "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/tasks" $qp)
  let body = {assigneeId: $assigneeId, assigneeIds: $assigneeIds, budgetEstimate: $budgetEstimate, estimate: $estimate, id: $id, name: $name, status: $status, userGroupIds: $userGroupIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a task's cost rate
#
# PUT /v1/workspaces/{workspaceId}/projects/{projectId}/tasks/{id}/cost-rate
# operationId: setTaskCostRate
export def "workspaces-projects-tasks-cost-rate setTaskCostRate" [
  projectId: string
  workspaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: int # Represents an amount as integer. (format: int32, e.g. 20000)
  --since: string # Represents a date and time in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
]: any -> record<assigneeId: string, assigneeIds: list<string>, billable: bool, budgetEstimate: int, costRate: record<amount: int, currency: string>, duration: string, estimate: string, hourlyRate: record<amount: int, currency: string>, id: string, name: string, projectId: string, status: record<ACTIVE: string, ALL: string, DONE: string, active: bool>, userGroupIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/tasks/($id)/cost-rate")
  let body = {amount: $amount, since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a task's billable rate
#
# PUT /v1/workspaces/{workspaceId}/projects/{projectId}/tasks/{id}/hourly-rate
# operationId: setTaskHourlyRate
export def "workspaces-projects-tasks-hourly-rate setTaskHourlyRate" [
  projectId: string
  workspaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: int # Represents an hourly rate amount as integer. (format: int32, e.g. 20000)
  --since: string # Represents a date and time in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
]: any -> record<assigneeId: string, assigneeIds: list<string>, billable: bool, budgetEstimate: int, costRate: record<amount: int, currency: string>, duration: string, estimate: string, hourlyRate: record<amount: int, currency: string>, id: string, name: string, projectId: string, status: record<ACTIVE: string, ALL: string, DONE: string, active: bool>, userGroupIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/tasks/($id)/hourly-rate")
  let body = {amount: $amount, since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a task from a project
#
# DELETE /v1/workspaces/{workspaceId}/projects/{projectId}/tasks/{taskId}
# operationId: deleteTask
export def "workspaces-projects-tasks delete" [
  taskId: string
  workspaceId: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<assigneeId: string, assigneeIds: list<string>, billable: bool, budgetEstimate: int, costRate: record<amount: int, currency: string>, duration: string, estimate: string, hourlyRate: record<amount: int, currency: string>, id: string, name: string, projectId: string, status: record<ACTIVE: string, ALL: string, DONE: string, active: bool>, userGroupIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a task by id
#
# GET /v1/workspaces/{workspaceId}/projects/{projectId}/tasks/{taskId}
# operationId: getTask
export def "workspaces-projects-tasks get" [
  taskId: string
  projectId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<assigneeId: string, assigneeIds: list<string>, billable: bool, budgetEstimate: int, costRate: record<amount: int, currency: string>, duration: string, estimate: string, hourlyRate: record<amount: int, currency: string>, id: string, name: string, projectId: string, status: record<ACTIVE: string, ALL: string, DONE: string, active: bool>, userGroupIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a task on a project
#
# PUT /v1/workspaces/{workspaceId}/projects/{projectId}/tasks/{taskId}
# operationId: updateTask
@deprecated --flag assigneeId
export def "workspaces-projects-tasks updateTask" [
  taskId: string
  workspaceId: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contains-assignee: string@bool-completer # Flag to set whether task will have assignee or none. (default: true)
  --membership-status: string@membership-status-completer # Represents a membership status. (e.g. ACTIVE)
  --assigneeId: string # DEPRECATED
  --assigneeIds: list # Represents list of assignee ids for the task. (e.g. [45b687e29ae1f428e7ebe123, 67s687e29ae1f428e7ebe678])
  --billable: string@bool-completer # Indicates whether a task is billable or not. (default: false)
  --budgetEstimate: int # Represents a task budget estimate as integer. (format: int64, e.g. 10000)
  --estimate: string # Represents a task duration estimate. (e.g. PT1H30M)
  name: string # Represents task name. (e.g. Bugfixing)
  --status: string@status-completer-2 # Represents task status. (e.g. DONE)
  --userGroupIds: list # Represents list of user group ids for the task. (e.g. [67b687e29ae1f428e7ebe123, 12s687e29ae1f428e7ebe678])
]: any -> record<assigneeId: string, assigneeIds: list<string>, billable: bool, budgetEstimate: int, costRate: record<amount: int, currency: string>, duration: string, estimate: string, hourlyRate: record<amount: int, currency: string>, id: string, name: string, projectId: string, status: record<ACTIVE: string, ALL: string, DONE: string, active: bool>, userGroupIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "contains-assignee" $contains_assignee "scalar") (serialize-qp "membership-status" $membership_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/tasks/($taskId)" $qp)
  let body = {assigneeId: $assigneeId, assigneeIds: $assigneeIds, billable: $billable, budgetEstimate: $budgetEstimate, estimate: $estimate, name: $name, status: $status, userGroupIds: $userGroupIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a project template
#
# PATCH /v1/workspaces/{workspaceId}/projects/{projectId}/template
# operationId: updateIsProjectTemplate
export def "workspaces-projects-template updateIsProjectTemplate" [
  workspaceId: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isTemplate: string@bool-completer # Indicates whether project is a template or not. (default: false)
]: any -> record<archived: bool, billable: bool, budgetEstimate: record<active: bool, estimate: int, includeExpenses: bool, resetOption: string, type: string>, clientId: string, clientName: string, color: string, costRate: record<amount: int, currency: string>, duration: string, estimate: record<estimate: string, type: string>, estimateReset: record<dayOfMonth: int, dayOfWeek: string, hour: int, interval: string, month: string>, hourlyRate: record<amount: int, currency: string>, id: string, isPublic: bool, isTemplate: bool, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, note: string, public: bool, template: bool, timeEstimate: record<active: bool, estimate: string, includeNonBillable: bool, resetOption: string, type: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/template")
  let body = {isTemplate: $isTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update project user's cost rate
#
# PUT /v1/workspaces/{workspaceId}/projects/{projectId}/users/{userId}/cost-rate
# operationId: addUsersCostRate
export def "workspaces-projects-users-cost-rate addUsersCostRate" [
  workspaceId: string
  projectId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: int # Represents an amount as integer. (format: int32, e.g. 20000)
  --since: string # Represents a date and time in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
]: any -> record<archived: bool, billable: bool, budgetEstimate: record<active: bool, estimate: int, includeExpenses: bool, resetOption: string, type: string>, clientId: string, clientName: string, color: string, costRate: record<amount: int, currency: string>, duration: string, estimate: record<estimate: string, type: string>, estimateReset: record<dayOfMonth: int, dayOfWeek: string, hour: int, interval: string, month: string>, hourlyRate: record<amount: int, currency: string>, id: string, isPublic: bool, isTemplate: bool, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, note: string, public: bool, template: bool, timeEstimate: record<active: bool, estimate: string, includeNonBillable: bool, resetOption: string, type: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/users/($userId)/cost-rate")
  let body = {amount: $amount, since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a project user's billable rate
#
# PUT /v1/workspaces/{workspaceId}/projects/{projectId}/users/{userId}/hourly-rate
# operationId: addUsersHourlyRate
export def "workspaces-projects-users-hourly-rate addUsersHourlyRate" [
  workspaceId: string
  projectId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: int # Represents an amount as integer. (format: int32, e.g. 20000)
  --since: string # Represents a date and time in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
]: any -> record<archived: bool, billable: bool, budgetEstimate: record<active: bool, estimate: int, includeExpenses: bool, resetOption: string, type: string>, clientId: string, clientName: string, color: string, costRate: record<amount: int, currency: string>, duration: string, estimate: record<estimate: string, type: string>, estimateReset: record<dayOfMonth: int, dayOfWeek: string, hour: int, interval: string, month: string>, hourlyRate: record<amount: int, currency: string>, id: string, isPublic: bool, isTemplate: bool, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, note: string, public: bool, template: bool, timeEstimate: record<active: bool, estimate: string, includeNonBillable: bool, resetOption: string, type: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/projects/($projectId)/users/($userId)/hourly-rate")
  let body = {amount: $amount, since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all assignments
#
# GET /v1/workspaces/{workspaceId}/scheduling/assignments/all
# operationId: getAllAssignments
export def "workspaces-scheduling-assignments-all get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # If provided, assignments will be filtered by name (default: , e.g. Bugfixing)
  --start: string # Represents a start date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
  --end: string # Represents a start date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2021-01-01T00:00:00Z)
  --sort-column: string@sort-column-completer-5 # Represents the column as the sorting criteria. (e.g. USER)
  --sort-order: string@sort-order-completer # Represents the sorting mode. (e.g. ASCENDING)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
]: nothing -> table<billable: bool, clientId: string, clientName: string, hoursPerDay: float, id: string, note: string, period: record<end: string, start: string>, projectArchived: bool, projectBillable: bool, projectColor: string, projectId: string, projectName: string, startTime: string, taskId: string, taskName: string, userId: string, userName: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all scheduled assignments per project
#
# GET /v1/workspaces/{workspaceId}/scheduling/assignments/projects/totals
# DEPRECATED
# operationId: getProjectTotals
@deprecated
export def "workspaces-scheduling-assignments-projects-totals list" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Represents a term for searching projects and clients by name. (default: , e.g. Project name)
  --start: string # Represents a start date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
  --end: string # Represents an end date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2021-01-01T00:00:00Z)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
]: nothing -> table<assignments: list<record>, clientName: string, milestones: list<record>, projectArchived: bool, projectBillable: bool, projectColor: string, projectId: string, projectName: string, taskId: string, taskName: string, totalHours: float, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/projects/totals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all scheduled assignments per project
#
# POST /v1/workspaces/{workspaceId}/scheduling/assignments/projects/totals
# operationId: getFilteredProjectTotals
export def "workspaces-scheduling-assignments-projects-totals post" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: string # Represents an end date in the yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --pageSize: int # Page size. (format: int32, default: 50, e.g. 50)
  --search: string # Represents a term for searching projects and clients by name. (e.g. Project name)
  start: string # Represents a start date in the yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2020-01-01T00:00:00Z)
  --statusFilter: string@statusFilter-completer # Filters assignments by status. (e.g. PUBLISHED)
]: any -> table<assignments: list<record>, clientName: string, milestones: list<record>, projectArchived: bool, projectBillable: bool, projectColor: string, projectId: string, projectName: string, taskId: string, taskName: string, totalHours: float, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/projects/totals")
  let body = {end: $end, page: $page, pageSize: $pageSize, search: $search, start: $start, statusFilter: $statusFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all scheduled assignments on project
#
# GET /v1/workspaces/{workspaceId}/scheduling/assignments/projects/totals/{projectId}
# operationId: getProjectTotalsForSingleProject
export def "workspaces-scheduling-assignments-projects-totals get" [
  workspaceId: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # Represents a start date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
  --end: string # Represents an end date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2021-01-01T00:00:00Z)
]: nothing -> record<assignments: table<date: string, hasAssignment: bool>, clientName: string, milestones: table<date: string, id: string, name: string, projectId: string, workspaceId: string>, projectArchived: bool, projectBillable: bool, projectColor: string, projectId: string, projectName: string, taskId: string, taskName: string, totalHours: float, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/projects/totals/($projectId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish assignments
#
# PUT /v1/workspaces/{workspaceId}/scheduling/assignments/publish
# operationId: publishAssignments
# --userFilter shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, sourceType?: "USER_GROUP", status?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL", statuses?: list}
# --userGroupFilter shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL"}
export def "workspaces-scheduling-assignments-publish publishAssignments" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: string # Represents end date in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2021-01-01T00:00:00Z)
  --notifyUsers: string@bool-completer # Indicates whether to notify users when assignment is published. (default: false)
  --search: string # Represents a search string. (e.g. search keyword)
  start: string # Represents start date in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
  --userFilter: record # Represents a user filter request object. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, sourceType?: "USER_GROUP", status?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL", statuses?: list}
  --userGroupFilter: record # Represents a user group filter request object. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL"}
  --viewType: string@viewType-completer # Represents view type. (e.g. PROJECTS)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/publish")
  let body = {end: $end, notifyUsers: $notifyUsers, search: $search, start: $start, userFilter: $userFilter, userGroupFilter: $userGroupFilter, viewType: $viewType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create assignment
#
# POST /v1/workspaces/{workspaceId}/scheduling/assignments/recurring
# operationId: createRecurring
# --recurringAssignment shape: {repeat?: bool, weeks: int}
export def "workspaces-scheduling-assignments-recurring createRecurring" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --billable: string@bool-completer # Indicates whether assignment is billable or not. (default: false)
  end: string # Represents an end date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2021-01-01T00:00:00Z)
  hoursPerDay: float # Represents assignment total hours per day. (format: double, e.g. 7.5)
  --includeNonWorkingDays: string@bool-completer # Indicates whether to include non-working days or not. (default: false)
  --note: string # Represents an assignment note. (e.g. This is a sample note for an assignment.)
  projectId: string # Represents a project identifier across the system. (e.g. 56b687e29ae1f428e7ebe504)
  --recurringAssignment: record # Represents a recurring assignment object. This parameter is optional. — shape: {repeat?: bool, weeks: int}
  start: string # Represents a start date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
  --startTime: string # Represents a start time in the hh:mm:ss format. (e.g. 10:00:00)
  --taskId: string # Represents a task identifier across the system. (e.g. 56b687e29ae1f428e7ebe505)
  userId: string # Represents a user identifier across the system. (e.g. 72k687e29ae1f428e7ebe109)
]: any -> table<billable: bool, excludeDays: list<record>, hoursPerDay: float, id: string, includeNonWorkingDays: bool, note: string, period: record<end: string, start: string>, projectId: string, published: bool, recurring: record<repeat: bool, seriesId: string, weeks: int>, startTime: string, taskId: string, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/recurring")
  let body = {billable: $billable, end: $end, hoursPerDay: $hoursPerDay, includeNonWorkingDays: $includeNonWorkingDays, note: $note, projectId: $projectId, recurringAssignment: $recurringAssignment, start: $start, startTime: $startTime, taskId: $taskId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete assignment
#
# DELETE /v1/workspaces/{workspaceId}/scheduling/assignments/recurring/{assignmentId}
# operationId: deleteRRecurringAssignment
export def "workspaces-scheduling-assignments-recurring delete" [
  workspaceId: string
  assignmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --seriesUpdateOption: string@seriesUpdateOption-completer # Represents a series option. (e.g. ALL)
]: nothing -> table<billable: bool, excludeDays: list<record>, hoursPerDay: float, id: string, includeNonWorkingDays: bool, note: string, period: record<end: string, start: string>, projectId: string, published: bool, recurring: record<repeat: bool, seriesId: string, weeks: int>, startTime: string, taskId: string, userId: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "seriesUpdateOption" $seriesUpdateOption "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/recurring/($assignmentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update assignment
#
# PATCH /v1/workspaces/{workspaceId}/scheduling/assignments/recurring/{assignmentId}
# operationId: editRecurring
export def "workspaces-scheduling-assignments-recurring editRecurring" [
  workspaceId: string
  assignmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --billable: string@bool-completer # Indicates whether assignment is billable or not. (default: false)
  end: string # Represents an end date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2021-01-01T00:00:00Z)
  --hoursPerDay: float # Represents assignment total hours per day. (format: double, e.g. 7.5)
  --includeNonWorkingDays: string@bool-completer # Indicates whether to include non-working days or not. (default: false)
  --note: string # Represents an assignment note. (e.g. This is a sample note for an assignment.)
  --seriesUpdateOption: string@seriesUpdateOption-completer # Valid series option (e.g. THIS_ONE)
  start: string # Represents start date in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
  --startTime: string # Represents a start time in the hh:mm:ss format. (e.g. 10:00:00)
  --taskId: string # Represents task identifier across the system. (e.g. 56b687e29ae1f428e7ebe505)
]: any -> table<billable: bool, excludeDays: list<record>, hoursPerDay: float, id: string, includeNonWorkingDays: bool, note: string, period: record<end: string, start: string>, projectId: string, published: bool, recurring: record<repeat: bool, seriesId: string, weeks: int>, startTime: string, taskId: string, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/recurring/($assignmentId)")
  let body = {billable: $billable, end: $end, hoursPerDay: $hoursPerDay, includeNonWorkingDays: $includeNonWorkingDays, note: $note, seriesUpdateOption: $seriesUpdateOption, start: $start, startTime: $startTime, taskId: $taskId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change the recurring period
#
# PUT /v1/workspaces/{workspaceId}/scheduling/assignments/series/{assignmentId}
# operationId: editRecurringPeriod
export def "workspaces-scheduling-assignments-series editRecurringPeriod" [
  workspaceId: string
  assignmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --repeat: string@bool-completer # Indicates whether assignment is recurring or not. (default: false)
  weeks: int # Indicates number of weeks for assignment. (format: int32, e.g. 5)
]: any -> table<billable: bool, excludeDays: list<record>, hoursPerDay: float, id: string, includeNonWorkingDays: bool, note: string, period: record<end: string, start: string>, projectId: string, published: bool, recurring: record<repeat: bool, seriesId: string, weeks: int>, startTime: string, taskId: string, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/series/($assignmentId)")
  let body = {repeat: $repeat, weeks: $weeks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get total of users' capacity on workspace
#
# POST /v1/workspaces/{workspaceId}/scheduling/assignments/user-filter/totals
# operationId: getUserTotals
# --userFilter shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, sourceType?: "USER_GROUP", status?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL", statuses?: list}
# --userGroupFilter shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL"}
export def "workspaces-scheduling-assignments-user-filter-totals post" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: string # Represents an end date in the yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --pageSize: int # Page size. (format: int32, default: 50, e.g. 50)
  --search: string # Represents the keyword for searching users by name or email. (e.g. keyword)
  start: string # Represents a start date in the yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2020-01-01T00:00:00Z)
  --statusFilter: string@statusFilter-completer # Filters assignments by status. (e.g. PUBLISHED)
  --userFilter: record # Represents a user filter request object. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, sourceType?: "USER_GROUP", status?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL", statuses?: list}
  --userGroupFilter: record # Represents a user group filter request object. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "PENDING"|"ACTIVE"|"DECLINED"|"INACTIVE"|"ALL"}
]: any -> table<capacityPerDay: float, totalHoursPerDay: list<record>, userId: string, userImage: string, userName: string, userStatus: string, workingDays: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/user-filter/totals")
  let body = {end: $end, page: $page, pageSize: $pageSize, search: $search, start: $start, statusFilter: $statusFilter, userFilter: $userFilter, userGroupFilter: $userGroupFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get total capacity of a user
#
# GET /v1/workspaces/{workspaceId}/scheduling/assignments/users/{userId}/totals
# operationId: getUserTotalsForSingleUser
export def "workspaces-scheduling-assignments-users-totals get" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --start: string # Represents a start date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
  --end: string # Represents an end date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2021-01-01T00:00:00Z)
]: nothing -> record<capacityPerDay: float, totalHoursPerDay: table<date: string, totalHours: float>, userId: string, userImage: string, userName: string, userStatus: string, workingDays: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/users/($userId)/totals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy a scheduled assignment
#
# POST /v1/workspaces/{workspaceId}/scheduling/assignments/{assignmentId}/copy
# operationId: copyAssignment
export def "workspaces-scheduling-assignments-copy copyAssignment" [
  workspaceId: string
  assignmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --seriesUpdateOption: string@seriesUpdateOption-completer # Represents a series update option. (e.g. THIS_ONE)
  userId: string # Represents a user identifier across the system. (e.g. 72k687e29ae1f428e7ebe109)
]: any -> table<billable: bool, excludeDays: list<record>, hoursPerDay: float, id: string, includeNonWorkingDays: bool, note: string, period: record<end: string, start: string>, projectId: string, published: bool, recurring: record<repeat: bool, seriesId: string, weeks: int>, startTime: string, taskId: string, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/scheduling/assignments/($assignmentId)/copy")
  let body = {seriesUpdateOption: $seriesUpdateOption, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find tags on a workspace
#
# GET /v1/workspaces/{workspaceId}/tags
# operationId: getTags
export def "workspaces-tags list" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # If provided, you'll get a filtered list of tags that matches the provided string in their name. (e.g. feature_X)
  --strict-name-search: string@bool-completer # Flag to toggle on/off strict search mode. When set to true, search by name will only return tags whose name exactly matches the string value given for the 'name' parameter. When set to false, results will also include tags whose name contain the string value, but could be longer than the string value itself. For example, if there is a tag with the name 'applications', and the search value is 'app', setting strict-name-search to true will not return that tag in the results, whereas setting it to false will. (default: false)
  --excluded-ids: string # Represents a list of excluded ids (e.g. [90p687e29ae1f428e7ebe657, 3r8687e29ae1f428e7eg567y])
  --sort-column: string@sort-column-completer-4 # Represents a column to be used as sorting criteria. (e.g. NAME)
  --sort-order: string@sort-order-completer # Represents a sorting mode. (e.g. ASCENDING)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --archived: string@bool-completer # Filters the result whether tags are archived or not. (default: false, e.g. false)
]: nothing -> table<archived: bool, id: string, name: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "strict-name-search" $strict_name_search "scalar") (serialize-qp "excluded-ids" $excluded_ids "scalar") (serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new tag
#
# POST /v1/workspaces/{workspaceId}/tags
# operationId: createNewTag
export def "workspaces-tags createNewTag" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Represents a tag name. (e.g. Sprint1)
]: any -> record<archived: bool, id: string, name: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/tags")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tag
#
# DELETE /v1/workspaces/{workspaceId}/tags/{id}
# operationId: deleteTag
export def "workspaces-tags delete" [
  id: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, id: string, name: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/tags/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a tag by ID
#
# GET /v1/workspaces/{workspaceId}/tags/{id}
# operationId: getTag
export def "workspaces-tags get" [
  id: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, id: string, name: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/tags/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a tag
#
# PUT /v1/workspaces/{workspaceId}/tags/{id}
# operationId: updateTag
export def "workspaces-tags updateTag" [
  id: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: string@bool-completer # Indicates whether a tag will be archived or not. (default: false)
  --name: string # Represents a tag name. (e.g. Sprint1)
]: any -> record<archived: bool, id: string, name: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/tags/($id)")
  let body = {archived: $archived, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all templates on a workspace
#
# GET /v1/workspaces/{workspaceId}/templates
# DEPRECATED
# operationId: getTemplates
@deprecated
export def "workspaces-templates list" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # If provided, you'll get a filtered list of templates that contain the provided string in their name.
  --cleansed: string@bool-completer # If set to true will filter out inactive template projects and tasks. (default: false)
  --hydrated: string@bool-completer # If set to true will return hydrated template projects and tasks. (default: false)
  --page: int # format: int32, default: 1
  --page-size: int # format: int32, default: 50
]: nothing -> table<id: string, name: string, userId: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "cleansed" $cleansed "scalar") (serialize-qp "hydrated" $hydrated "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create templates on a workspace
#
# POST /v1/workspaces/{workspaceId}/templates
# DEPRECATED
# operationId: createMany
@deprecated
export def "workspaces-templates createMany" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<entries: list<record>, id: string, name: string, projectsAndTasks: list<record>, userId: string, weekStart: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/templates")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a template
#
# DELETE /v1/workspaces/{workspaceId}/templates/{templateId}
# DEPRECATED
# operationId: delete_1
@deprecated
export def "workspaces-templates delete-by-workspaceId-templateId" [
  workspaceId: string
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entries: table<billable: bool, customFieldValues: list, description: string, id: string, projectId: string, tagIds: list, taskId: string, timeInterval: record, type: string, userId: string, workspaceId: string>, id: string, name: string, projectsAndTasks: table<projectId: string, taskId: string>, userId: string, weekStart: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/templates/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get template by ID on a workspace
#
# GET /v1/workspaces/{workspaceId}/templates/{templateId}
# DEPRECATED
# operationId: getTemplate
@deprecated
export def "workspaces-templates get" [
  workspaceId: string
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cleansed: string@bool-completer # If set to true will filter out inactive template projects and tasks. (default: false)
  --hydrated: string@bool-completer # If set to true will return hydrated template projects and tasks. (default: false)
]: nothing -> record<id: string, name: string, userId: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "cleansed" $cleansed "scalar") (serialize-qp "hydrated" $hydrated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/templates/($templateId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a template
#
# PATCH /v1/workspaces/{workspaceId}/templates/{templateId}
# DEPRECATED
# operationId: update
@deprecated
export def "workspaces-templates update" [
  workspaceId: string
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Represents a template name. (e.g. exampleTemplate)
]: any -> record<entries: table<billable: bool, customFieldValues: list, description: string, id: string, projectId: string, tagIds: list, taskId: string, timeInterval: record, type: string, userId: string, workspaceId: string>, id: string, name: string, projectsAndTasks: table<projectId: string, taskId: string>, userId: string, weekStart: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/templates/($templateId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a new time entry
#
# POST /v1/workspaces/{workspaceId}/time-entries
# operationId: createTimeEntry
# --customAttributes item shape: {name: string, namespace: string, value: string}
# --customFields item shape: {customFieldId: string, sourceType?: "WORKSPACE"|"PROJECT"|"TIMEENTRY", value?: record}
export def "workspaces-time-entries createTimeEntry" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --billable: string@bool-completer # Indicates whether a time entry is billable or not. (default: false)
  --customAttributes: list # Represents a list of create custom field request objects. — item shape: {name: string, namespace: string, value: string}
  --customFields: list # Represents a list of value objects for user’s custom fields. — item shape: {customFieldId: string, sourceType?: "WORKSPACE"|"PROJECT"|"TIMEENTRY", value?: record}
  --description: string # Represents time entry description. (e.g. This is a sample time entry description.)
  --end: string # Represents an end date in yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --projectId: string # Represents a project identifier across the system. (e.g. 25b687e29ae1f428e7ebe123)
  --start: string # Represents a start date in yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2020-01-01T00:00:00Z)
  --tagIds: list # Represents a list of tag ids. (e.g. [321r77ddd3fcab07cfbb567y, 44x777ddd3fcab07cfbb88f])
  --taskId: string # Represents a task identifier across the system. (e.g. 54m377ddd3fcab07cfbb432w)
  --type: string@type-completer-1 # Valid time entry type.
]: any -> record<billable: bool, customFieldValues: table<customFieldId: string, name: string, timeEntryId: string, type: string, value: record>, description: string, id: string, isLocked: bool, kioskId: string, projectId: string, tagIds: list<string>, taskId: string, timeInterval: record<duration: string, end: string, start: string>, type: string, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-entries")
  let body = {billable: $billable, customAttributes: $customAttributes, customFields: $customFields, description: $description, end: $end, projectId: $projectId, start: $start, tagIds: $tagIds, taskId: $taskId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark time entries as invoiced
#
# PATCH /v1/workspaces/{workspaceId}/time-entries/invoiced
# operationId: updateInvoicedStatus
# --timeEntryIds item shape: {dateOfCreationFromObjectId?: string}
export def "workspaces-time-entries-invoiced updateInvoicedStatus" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --invoiced: string@bool-completer # Indicates whether time entry is invoiced or not. (default: false)
  timeEntryIds: list # Represents a list of invoiced time entry ids (e.g. [54m377ddd3fcab07cfbb432w, 25b687e29ae1f428e7ebe123]) — item shape: {dateOfCreationFromObjectId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-entries/invoiced")
  let body = {invoiced: $invoiced, timeEntryIds: $timeEntryIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all in progress time entries on a workspace
#
# GET /v1/workspaces/{workspaceId}/time-entries/status/in-progress
# operationId: getInProgressTimeEntries
export def "workspaces-time-entries-status-in-progress get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --page-size: int # format: int32, default: 10
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-entries/status/in-progress" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a time entry from a workspace
#
# DELETE /v1/workspaces/{workspaceId}/time-entries/{id}
# operationId: deleteTimeEntry
export def "workspaces-time-entries delete" [
  workspaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-entries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific time entry on a workspace
#
# GET /v1/workspaces/{workspaceId}/time-entries/{id}
# operationId: getTimeEntry
export def "workspaces-time-entries get" [
  workspaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hydrated: string@bool-completer # Flag to set whether to include additional information of a time entry or not. (default: false)
]: nothing -> record<billable: bool, costRate: record<amount: int, currency: string>, customFieldValues: table<customFieldId: string, name: string, timeEntryId: string, type: string, value: record>, description: string, hourlyRate: record<amount: int, currency: string>, id: string, isLocked: bool, kioskId: string, projectId: string, tagIds: list<string>, taskId: string, timeInterval: record<duration: string, end: string, start: string>, type: string, userId: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "hydrated" $hydrated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-entries/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update time entry on a workspace
#
# PUT /v1/workspaces/{workspaceId}/time-entries/{id}
# operationId: updateTimeEntry
# --customFields item shape: {customFieldId: string, sourceType?: "WORKSPACE"|"PROJECT"|"TIMEENTRY", value?: record}
export def "workspaces-time-entries updateTimeEntry" [
  workspaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --billable: string@bool-completer # Indicates whether a time entry is billable or not. (default: false)
  --customFields: list # Represents a list of value objects for user’s custom fields. — item shape: {customFieldId: string, sourceType?: "WORKSPACE"|"PROJECT"|"TIMEENTRY", value?: record}
  --description: string # Represents time entry description. (e.g. This is a sample time entry description.)
  --end: string # Represents an end date in yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --projectId: string # Represents a project identifier across the system. (e.g. 25b687e29ae1f428e7ebe123)
  start: string # Represents a start date in yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2020-01-01T00:00:00Z)
  --tagIds: list # Represents a list of tag ids. (e.g. [321r77ddd3fcab07cfbb567y, 44x777ddd3fcab07cfbb88f])
  --taskId: string # Represents a task identifier across the system. (e.g. 54m377ddd3fcab07cfbb432w)
  --type: string@type-completer-1
]: any -> record<billable: bool, customFieldValues: table<customFieldId: string, name: string, timeEntryId: string, type: string, value: record>, description: string, id: string, isLocked: bool, kioskId: string, projectId: string, tagIds: list<string>, taskId: string, timeInterval: record<duration: string, end: string, start: string>, type: string, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-entries/($id)")
  let body = {billable: $billable, customFields: $customFields, description: $description, end: $end, projectId: $projectId, start: $start, tagIds: $tagIds, taskId: $taskId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get balances for a policy
#
# GET /v1/workspaces/{workspaceId}/time-off/balance/policy/{policyId}
# operationId: getBalancesForPolicy
export def "workspaces-time-off-balance-policy get" [
  workspaceId: string
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1, e.g. 1
  --page-size: int # format: int32, default: 50, e.g. 50
  --qp-sort: string@sort-completer # If provided, you'll get result sorted by sort column. (e.g. USER)
  --sort-order: string@sort-order-completer # Sort results in ascending or descending order. (e.g. ASCENDING)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort-order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/balance/policy/($policyId)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a balance
#
# PATCH /v1/workspaces/{workspaceId}/time-off/balance/policy/{policyId}
# operationId: updateBalance
export def "workspaces-time-off-balance-policy updateBalance" [
  workspaceId: string
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --note: string # Represents a new balance note value. (e.g. Bonus days added.)
  userIds: list # Represents the list of users' identifiers whose balance is to be updated. (e.g. [5b715448b079875110792222, 5b715448b079875110791111])
  value: float # Represents a new balance value. (format: double, e.g. 22)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/balance/policy/($policyId)")
  let body = {note: $note, userIds: $userIds, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get balance for a user
#
# GET /v1/workspaces/{workspaceId}/time-off/balance/user/{userId}
# operationId: getBalancesForUser
export def "workspaces-time-off-balance-user get" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Page number.
  --page-size: string # Page size.
  --qp-sort: string@sort-completer # Sort result based on given criteria (e.g. POLICY)
  --sort-order: string@sort-order-completer # Sort result by providing sort order. (e.g. ASCENDING)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort-order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/balance/user/($userId)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get policies on a workspace
#
# GET /v1/workspaces/{workspaceId}/time-off/policies
# operationId: findPoliciesForWorkspace
export def "workspaces-time-off-policies findPoliciesForWorkspace" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Page number.
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --name: string # If provided, you'll get a filtered list of policies that contain the provided string in their name. (e.g. Holidays)
  --status: string@status-completer-3 # If provided, you'll get a filtered list of policies with the corresponding status. (e.g. ACTIVE)
  --sort-column: string # default: DEFAULT_SORT
  --sort-order: string # default: ASCENDING
]: nothing -> table<allowHalfDay: bool, allowNegativeBalance: bool, approve: record<requiresApproval: bool, specificMembers: bool, teamManagers: bool, userIds: list>, archived: bool, automaticAccrual: record<amount: float, period: string, timeUnit: string>, automaticTimeEntryCreation: record<defaultEntities: record, enabled: bool>, everyoneIncludingNew: bool, id: string, name: string, negativeBalance: record<amount: float, period: string, shouldReset: bool, timeUnit: string>, projectId: string, timeUnit: string, userGroupIds: list<string>, userIds: list<string>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a time off policy
#
# POST /v1/workspaces/{workspaceId}/time-off/policies
# operationId: createPolicy
# --approve shape: {requiresApproval?: bool, specificMembers?: bool, teamManagers?: bool, userIds?: list}
# --automaticAccrual shape: {amount: float, period?: "MONTH"|"YEAR", timeUnit?: "DAYS"|"HOURS"}
# --automaticTimeEntryCreation shape: {defaultEntities: record, enabled?: bool}
# --negativeBalance shape: {amount: float, period?: "MONTH"|"YEAR", shouldReset?: bool}
# --userGroups shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
# --users shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
export def "workspaces-time-off-policies createPolicy" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowHalfDay: string@bool-completer # Indicates whether policy allows half days. (default: false, e.g. false)
  --allowNegativeBalance: string@bool-completer # Indicates whether policy allows negative balances. (default: false, e.g. true)
  approve: record # Represents approval settings. — shape: {requiresApproval?: bool, specificMembers?: bool, teamManagers?: bool, userIds?: list}
  --archived: string@bool-completer # Indicates whether policy is archived. (default: false, e.g. true)
  --automaticAccrual: record # Provide automatic accrual settings. — shape: {amount: float, period?: "MONTH"|"YEAR", timeUnit?: "DAYS"|"HOURS"}
  --automaticTimeEntryCreation: record # Provides automatic time entry creation settings. — shape: {defaultEntities: record, enabled?: bool}
  --color: string # Provide color in format ^#(?:[0-9a-fA-F]{6}){1}$. Explanation: A valid color code should start with '#' and consist of six hexadecimal characters, representing a color in hexadecimal format. Color value is in standard RGB hexadecimal format. (e.g. #8BC34A)
  --everyoneIncludingNew: string@bool-completer # Indicates whether the policy is to be applied to future new users. (default: false, e.g. false)
  --hasExpiration: string@bool-completer # Indicates whether the policy balance should have expiration (default: false, e.g. false)
  --icon: string@icon-completer # Provide icon. (e.g. UMBRELLA)
  name: string # Represents a name of new policy. (e.g. Mental health days)
  --negativeBalance: record # Provide the negative balance data you would like to use for updating the policy. — shape: {amount: float, period?: "MONTH"|"YEAR", shouldReset?: bool}
  --timeUnit: string@timeUnit-completer # Indicates time unit of the policy.  (e.g. DAYS)
  --userGroups: record # Provide list with user group ids and corresponding status. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
  --users: record # Provide list with user ids and corresponding status. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
]: any -> record<allowHalfDay: bool, allowNegativeBalance: bool, approve: record<requiresApproval: bool, specificMembers: bool, teamManagers: bool, userIds: list<string>>, archived: bool, automaticAccrual: record<amount: float, period: string, timeUnit: string>, automaticTimeEntryCreation: record<defaultEntities: record<projectId: string, taskId: string>, enabled: bool>, everyoneIncludingNew: bool, id: string, name: string, negativeBalance: record<amount: float, period: string, shouldReset: bool, timeUnit: string>, projectId: string, timeUnit: string, userGroupIds: list<string>, userIds: list<string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/policies")
  let body = {allowHalfDay: $allowHalfDay, allowNegativeBalance: $allowNegativeBalance, approve: $approve, archived: $archived, automaticAccrual: $automaticAccrual, automaticTimeEntryCreation: $automaticTimeEntryCreation, color: $color, everyoneIncludingNew: $everyoneIncludingNew, hasExpiration: $hasExpiration, icon: $icon, name: $name, negativeBalance: $negativeBalance, timeUnit: $timeUnit, userGroups: $userGroups, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a policy
#
# DELETE /v1/workspaces/{workspaceId}/time-off/policies/{id}
# operationId: deletePolicy
export def "workspaces-time-off-policies delete" [
  workspaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a time off policy
#
# GET /v1/workspaces/{workspaceId}/time-off/policies/{id}
# operationId: getPolicy
export def "workspaces-time-off-policies get" [
  workspaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allowHalfDay: bool, allowNegativeBalance: bool, approve: record<requiresApproval: bool, specificMembers: bool, teamManagers: bool, userIds: list<string>>, archived: bool, automaticAccrual: record<amount: float, period: string, timeUnit: string>, automaticTimeEntryCreation: record<defaultEntities: record<projectId: string, taskId: string>, enabled: bool>, everyoneIncludingNew: bool, id: string, name: string, negativeBalance: record<amount: float, period: string, shouldReset: bool, timeUnit: string>, projectId: string, timeUnit: string, userGroupIds: list<string>, userIds: list<string>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change a policy status
#
# PATCH /v1/workspaces/{workspaceId}/time-off/policies/{id}
# operationId: updatePolicyStatus
export def "workspaces-time-off-policies updatePolicyStatus" [
  workspaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer-3 # Provide the status you would like to use for changing the policy. (e.g. ACTIVE)
]: any -> record<allowHalfDay: bool, allowNegativeBalance: bool, approve: record<requiresApproval: bool, specificMembers: bool, teamManagers: bool, userIds: list<string>>, archived: bool, automaticAccrual: record<amount: float, period: string, timeUnit: string>, automaticTimeEntryCreation: record<defaultEntities: record<projectId: string, taskId: string>, enabled: bool>, everyoneIncludingNew: bool, id: string, name: string, negativeBalance: record<amount: float, period: string, shouldReset: bool, timeUnit: string>, projectId: string, timeUnit: string, userGroupIds: list<string>, userIds: list<string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/policies/($id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a policy
#
# PUT /v1/workspaces/{workspaceId}/time-off/policies/{id}
# operationId: updatePolicy
# --approve shape: {requiresApproval?: bool, specificMembers?: bool, teamManagers?: bool, userIds?: list}
# --automaticAccrual shape: {amount: float, period?: "MONTH"|"YEAR", timeUnit?: "DAYS"|"HOURS"}
# --automaticTimeEntryCreation shape: {defaultEntities: record, enabled?: bool}
# --negativeBalance shape: {amount: float, period?: "MONTH"|"YEAR", shouldReset?: bool}
# --userGroups shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
# --users shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
export def "workspaces-time-off-policies updatePolicy" [
  workspaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowHalfDay: string@bool-completer # Indicates whether policy allows half day. (default: false, e.g. true)
  --allowNegativeBalance: string@bool-completer # Indicates whether policy allows negative balance. (default: false, e.g. false)
  approve: record # Represents approval settings. — shape: {requiresApproval?: bool, specificMembers?: bool, teamManagers?: bool, userIds?: list}
  --archived: string@bool-completer # Indicates whether policy is archived. (default: false, e.g. false)
  --automaticAccrual: record # Provide automatic accrual settings. — shape: {amount: float, period?: "MONTH"|"YEAR", timeUnit?: "DAYS"|"HOURS"}
  --automaticTimeEntryCreation: record # Provides automatic time entry creation settings. — shape: {defaultEntities: record, enabled?: bool}
  --color: string # Provide color in format ^#(?:[0-9a-fA-F]{6}){1}$. Explanation: A valid color code should start with '#' and consist of six hexadecimal characters, representing a color in hexadecimal format. Color value is in standard RGB hexadecimal format. (e.g. #8BC34A)
  --everyoneIncludingNew: string@bool-completer # Indicates whether the policy is shown to new users. (default: false, e.g. false)
  --hasExpiration: string@bool-completer # Indicates whether the policy has expiration. (default: false, e.g. false)
  --icon: string@icon-completer # Provide icon. (e.g. UMBRELLA)
  name: string # Provide the name you would like to use for updating the policy. (e.g. Days)
  --negativeBalance: record # Provide the negative balance data you would like to use for updating the policy. — shape: {amount: float, period?: "MONTH"|"YEAR", shouldReset?: bool}
  userGroups: record # Provide list with user group ids and corresponding status. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
  users: record # Provide list with user ids and corresponding status. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN", ids?: list, status?: "ALL"|"ACTIVE"|"INACTIVE"}
]: any -> record<allowHalfDay: bool, allowNegativeBalance: bool, approve: record<requiresApproval: bool, specificMembers: bool, teamManagers: bool, userIds: list<string>>, archived: bool, automaticAccrual: record<amount: float, period: string, timeUnit: string>, automaticTimeEntryCreation: record<defaultEntities: record<projectId: string, taskId: string>, enabled: bool>, everyoneIncludingNew: bool, id: string, name: string, negativeBalance: record<amount: float, period: string, shouldReset: bool, timeUnit: string>, projectId: string, timeUnit: string, userGroupIds: list<string>, userIds: list<string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/policies/($id)")
  let body = {allowHalfDay: $allowHalfDay, allowNegativeBalance: $allowNegativeBalance, approve: $approve, archived: $archived, automaticAccrual: $automaticAccrual, automaticTimeEntryCreation: $automaticTimeEntryCreation, color: $color, everyoneIncludingNew: $everyoneIncludingNew, hasExpiration: $hasExpiration, icon: $icon, name: $name, negativeBalance: $negativeBalance, userGroups: $userGroups, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a time off request
#
# POST /v1/workspaces/{workspaceId}/time-off/policies/{policyId}/requests
# operationId: createTimeOffRequest
# --timeOffPeriod shape: {halfDayPeriod?: "FIRST_HALF"|"SECOND_HALF"|"NOT_DEFINED", isHalfDay?: bool, period: record, timeOffHalfDayPeriod?: "FIRST_HALF"|"SECOND_HALF"|"NOT_DEFINED"}
export def "workspaces-time-off-policies-requests createTimeOffRequest" [
  workspaceId: string
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --note: string # Provide the note you would like to use for creating the time off request. (e.g. Create Time Off Note)
  timeOffPeriod: record # Provide the period you would like to use for creating the time off request. If `timeZone` isn't set, should be aligned with time zone for user in settings. Can be shifted from user time zone with explicit setting of `timeZone`. — shape: {halfDayPeriod?: "FIRST_HALF"|"SECOND_HALF"|"NOT_DEFINED", isHalfDay?: bool, period: record, timeOffHalfDayPeriod?: "FIRST_HALF"|"SECOND_HALF"|"NOT_DEFINED"}
]: any -> record<balance: float, balanceDiff: float, createdAt: string, id: string, note: string, policyId: string, policyName: string, requesterUserId: string, requesterUserName: string, status: record<changedAt: string, changedByUserId: string, changedByUserName: string, changedForUserName: string, note: string, statusType: string>, timeOffPeriod: record<halfDay: bool, halfDayHours: record<end: string, start: string>, halfDayPeriod: string, period: record<end: string, start: string>>, timeUnit: string, userEmail: string, userId: string, userName: string, userTimeZone: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/policies/($policyId)/requests")
  let body = {note: $note, timeOffPeriod: $timeOffPeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a time off request
#
# DELETE /v1/workspaces/{workspaceId}/time-off/policies/{policyId}/requests/{requestId}
# operationId: deleteTimeOffRequest
export def "workspaces-time-off-policies-requests delete" [
  workspaceId: string
  policyId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<balanceDiff: float, createdAt: string, id: string, note: string, policyId: string, status: record<changedAt: string, changedByUserId: string, changedByUserName: string, changedForUserName: string, note: string, statusType: string>, timeOffPeriod: record<halfDay: bool, halfDayHours: record<end: string, start: string>, halfDayPeriod: string, period: record<end: string, start: string>>, userId: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/policies/($policyId)/requests/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change a time off request status
#
# PATCH /v1/workspaces/{workspaceId}/time-off/policies/{policyId}/requests/{requestId}
# operationId: changeTimeOffRequestStatus
export def "workspaces-time-off-policies-requests changeTimeOffRequestStatus" [
  workspaceId: string
  policyId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --note: string # Provide the note you would like to use for changing the time off request. (e.g. Time Off Request Note)
  --status: string@status-completer-4 # Provide the status you would like to use for changing the time off request. (e.g. APPROVED)
]: any -> record<balanceDiff: float, createdAt: string, id: string, note: string, policyId: string, status: record<changedAt: string, changedByUserId: string, changedByUserName: string, changedForUserName: string, note: string, statusType: string>, timeOffPeriod: record<halfDay: bool, halfDayHours: record<end: string, start: string>, halfDayPeriod: string, period: record<end: string, start: string>>, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/policies/($policyId)/requests/($requestId)")
  let body = {note: $note, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a time off request for a user
#
# POST /v1/workspaces/{workspaceId}/time-off/policies/{policyId}/users/{userId}/requests
# operationId: createTimeOffRequestForOther
# --timeOffPeriod shape: {halfDayPeriod?: "FIRST_HALF"|"SECOND_HALF"|"NOT_DEFINED", isHalfDay?: bool, period: record, timeOffHalfDayPeriod?: "FIRST_HALF"|"SECOND_HALF"|"NOT_DEFINED"}
export def "workspaces-time-off-policies-users-requests createTimeOffRequestForOther" [
  workspaceId: string
  policyId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --note: string # Provide the note you would like to use for creating the time off request. (e.g. Create Time Off Note)
  timeOffPeriod: record # Provide the period you would like to use for creating the time off request. If `timeZone` isn't set, should be aligned with time zone for user in settings. Can be shifted from user time zone with explicit setting of `timeZone`. — shape: {halfDayPeriod?: "FIRST_HALF"|"SECOND_HALF"|"NOT_DEFINED", isHalfDay?: bool, period: record, timeOffHalfDayPeriod?: "FIRST_HALF"|"SECOND_HALF"|"NOT_DEFINED"}
]: any -> record<balance: float, balanceDiff: float, createdAt: string, id: string, note: string, policyId: string, policyName: string, requesterUserId: string, requesterUserName: string, status: record<changedAt: string, changedByUserId: string, changedByUserName: string, changedForUserName: string, note: string, statusType: string>, timeOffPeriod: record<halfDay: bool, halfDayHours: record<end: string, start: string>, halfDayPeriod: string, period: record<end: string, start: string>>, timeUnit: string, userEmail: string, userId: string, userName: string, userTimeZone: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/policies/($policyId)/users/($userId)/requests")
  let body = {note: $note, timeOffPeriod: $timeOffPeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all time off requests on a workspace
#
# POST /v1/workspaces/{workspaceId}/time-off/requests
# operationId: getTimeOffRequest
export def "workspaces-time-off-requests post" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --end: string # Provide the end of the filtering period. Used with `start` to filter for time-off requests periods that occur (fully or partially) within this range. Both parameters must be provided for filtering to take effect. Provide end in format YYYY-MM-DDTHH:MM:SS.ssssssZ (format: date-time, e.g. 2022-08-26T23:55:06.281873Z)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --pageSize: int # Page size. (format: int32, default: 50, e.g. 50)
  --start: string # Provide the beginning of the filtering period. Used with `end` to filter for time-off requests periods that occur (fully or partially) within this range. Both parameters must be provided for filtering to take effect. Provide start in format YYYY-MM-DDTHH:MM:SS.ssssssZ (format: date-time, e.g. 2022-08-26T08:00:06.281873Z)
  --statuses: list # Filters time off requests by status. (e.g. [APPROVED, PENDING])
  --userGroups: list # Provide the user group ids of time off requests. (e.g. [5b715612b079875110791342, 5b715612b079875110791324, 5b715612b079875110793142])
  --users: list # Provide the user ids of time off requests. If empty, will return time off requests of all users (with a maximum of 5000 users). (e.g. [5b715612b079875110791432, b715612b079875110791234])
]: any -> record<count: int, requests: table<balance: float, balanceDiff: float, createdAt: string, id: string, note: string, policyId: string, policyName: string, requesterUserId: string, requesterUserName: string, status: record, timeOffPeriod: record, timeUnit: string, userEmail: string, userId: string, userName: string, userTimeZone: string, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/time-off/requests")
  let body = {end: $end, page: $page, pageSize: $pageSize, start: $start, statuses: $statuses, userGroups: $userGroups, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find all groups on a workspace
#
# GET /v1/workspaces/{workspaceId}/user-groups
# operationId: getUserGroups
export def "workspaces-user-groups get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-id: string # If provided, you'll get a filtered list of groups that matches the string provided in their project id. (e.g. 5a0ab5acb07987125438b60f)
  --name: string # If provided, you'll get a filtered list of groups that matches the string provided in their name. (e.g. development_team)
  --sort-column: string@sort-column-completer-4 # Column to be used as the sorting criteria. (e.g. NAME)
  --sort-order: string@sort-order-completer # Sorting mode. (e.g. ASCENDING)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --includeTeamManagers: string@bool-completer # If provided, you'll get a list of team managers assigned to this user group. (default: false, e.g. true)
]: nothing -> table<id: string, name: string, teamManagers: list<record>, userIds: list<string>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "project-id" $project_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "includeTeamManagers" $includeTeamManagers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new group
#
# POST /v1/workspaces/{workspaceId}/user-groups
# operationId: createUserGroup
export def "workspaces-user-groups createUserGroup" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Represents a user group name. (e.g. development_team)
]: any -> record<id: string, name: string, teamManagers: table<id: string, name: string>, userIds: list<string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user-groups")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a group
#
# DELETE /v1/workspaces/{workspaceId}/user-groups/{id}
# operationId: deleteUserGroup
export def "workspaces-user-groups delete" [
  workspaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, teamManagers: table<id: string, name: string>, userIds: list<string>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a group
#
# PUT /v1/workspaces/{workspaceId}/user-groups/{id}
# operationId: updateUserGroup
export def "workspaces-user-groups updateUserGroup" [
  id: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Represents a user group name. (e.g. development_team)
]: any -> record<id: string, name: string, teamManagers: table<id: string, name: string>, userIds: list<string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user-groups/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add users to a group
#
# POST /v1/workspaces/{workspaceId}/user-groups/{userGroupId}/users
# operationId: addUser
export def "workspaces-user-groups-users addUser" [
  workspaceId: string
  userGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: string # Represents a user identifier across the system. (e.g. 5a0ab5acb07987125438b60f)
]: any -> record<id: string, name: string, teamManagers: table<id: string, name: string>, userIds: list<string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user-groups/($userGroupId)/users")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a user from a group
#
# DELETE /v1/workspaces/{workspaceId}/user-groups/{userGroupId}/users/{userId}
# operationId: deleteUser
export def "workspaces-user-groups-users delete" [
  workspaceId: string
  userGroupId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, teamManagers: table<id: string, name: string>, userIds: list<string>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user-groups/($userGroupId)/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all time entries for a user on a workspace
#
# DELETE /v1/workspaces/{workspaceId}/user/{userId}/time-entries
# operationId: deleteMany
export def "workspaces-user-time-entries delete" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --time-entry-ids: list # Represents a list of time entry ids to delete. (e.g. 5a0ab5acb07987125438b60f)
]: nothing -> table<billable: bool, customFieldValues: list<record>, description: string, id: string, isLocked: bool, kioskId: string, projectId: string, tagIds: list<string>, taskId: string, timeInterval: record<duration: string, end: string, start: string>, type: string, userId: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "time-entry-ids" $time_entry_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user/($userId)/time-entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get time entries for a user on a workspace
#
# GET /v1/workspaces/{workspaceId}/user/{userId}/time-entries
# operationId: getTimeEntries
export def "workspaces-user-time-entries get" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Represents a term for searching time entries by description. (e.g. Description keywords)
  --start: string # Represents a start date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
  --end: string # Represents an end date in the yyyy-MM-ddThh:mm:ssZ format. (e.g. 2021-01-01T00:00:00Z)
  --project: string # If provided, you'll get a filtered list of time entries that matches the provided string in their project id. (e.g. 5b641568b07987035750505e)
  --task: string # If provided, you'll get a filtered list of time entries that matches the provided string in their task id. (e.g. 64c777ddd3fcab07cfbb210c)
  --tags: list # If provided, you'll get a filtered list of time entries that matches the provided string(s) in their tag id(s). (e.g. [5e4117fe8c625f38930d57b7, 7e4117fe8c625f38930d57b8])
  --project-required: string@bool-completer # Flag to set whether to only get time entries which have a project. (default: false)
  --task-required: string@bool-completer # Flag to set whether to only get time entries which have tasks. (default: false)
  --hydrated: string@bool-completer # Flag to set whether to include additional information on time entries or not. (default: false)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --in-progress: string # Flag to set whether to filter only in progress time entries.
  --get-week-before: string # Valid yyyy-MM-ddThh:mm:ssZ format date. If provided, filters results within the week before the datetime provided and only those entries with assigned project or task. (e.g. 2020-01-01T00:00:00Z)
]: nothing -> table<billable: bool, costRate: record<amount: int, currency: string>, customFieldValues: list<record>, description: string, hourlyRate: record<amount: int, currency: string>, id: string, isLocked: bool, kioskId: string, projectId: string, tagIds: list<string>, taskId: string, timeInterval: record<duration: string, end: string, start: string>, type: string, userId: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "description" $description "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "task" $task "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "project-required" $project_required "scalar") (serialize-qp "task-required" $task_required "scalar") (serialize-qp "hydrated" $hydrated "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "in-progress" $in_progress "scalar") (serialize-qp "get-week-before" $get_week_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user/($userId)/time-entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop a currently running timer on a workspace for a user
#
# PATCH /v1/workspaces/{workspaceId}/user/{userId}/time-entries
# operationId: stopRunningTimeEntry
export def "workspaces-user-time-entries stopRunningTimeEntry" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: string # Represents an end date in the yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2021-01-01T00:00:00Z)
]: any -> record<billable: bool, customFieldValues: table<customFieldId: string, name: string, timeEntryId: string, type: string, value: record>, description: string, id: string, isLocked: bool, kioskId: string, projectId: string, tagIds: list<string>, taskId: string, timeInterval: record<duration: string, end: string, start: string>, type: string, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user/($userId)/time-entries")
  let body = {end: $end} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a new time entry for another user on workspace
#
# POST /v1/workspaces/{workspaceId}/user/{userId}/time-entries
# operationId: createForOthers
# --customAttributes item shape: {name: string, namespace: string, value: string}
# --customFields item shape: {customFieldId: string, sourceType?: "WORKSPACE"|"PROJECT"|"TIMEENTRY", value?: record}
export def "workspaces-user-time-entries createForOthers" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --from-entry: string # Represents a time entry identifier across the system. (e.g. 64c777ddd3fcab07cfbb210c)
  --billable: string@bool-completer # Indicates whether a time entry is billable or not. (default: false)
  --customAttributes: list # Represents a list of create custom field request objects. — item shape: {name: string, namespace: string, value: string}
  --customFields: list # Represents a list of value objects for user’s custom fields. — item shape: {customFieldId: string, sourceType?: "WORKSPACE"|"PROJECT"|"TIMEENTRY", value?: record}
  --description: string # Represents time entry description. (e.g. This is a sample time entry description.)
  --end: string # Represents an end date in yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --projectId: string # Represents a project identifier across the system. (e.g. 25b687e29ae1f428e7ebe123)
  --start: string # Represents a start date in yyyy-MM-ddThh:mm:ssZ format. (format: date-time, e.g. 2020-01-01T00:00:00Z)
  --tagIds: list # Represents a list of tag ids. (e.g. [321r77ddd3fcab07cfbb567y, 44x777ddd3fcab07cfbb88f])
  --taskId: string # Represents a task identifier across the system. (e.g. 54m377ddd3fcab07cfbb432w)
  --type: string@type-completer-1 # Valid time entry type.
]: any -> record<billable: bool, customFieldValues: table<customFieldId: string, name: string, timeEntryId: string, type: string, value: record>, description: string, id: string, isLocked: bool, kioskId: string, projectId: string, tagIds: list<string>, taskId: string, timeInterval: record<duration: string, end: string, start: string>, type: string, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "from-entry" $from_entry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user/($userId)/time-entries" $qp)
  let body = {billable: $billable, customAttributes: $customAttributes, customFields: $customFields, description: $description, end: $end, projectId: $projectId, start: $start, tagIds: $tagIds, taskId: $taskId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk edit time entries
#
# PUT /v1/workspaces/{workspaceId}/user/{userId}/time-entries
# operationId: replaceMany
export def "workspaces-user-time-entries replaceMany" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hydrated: string@bool-completer # If set to true, results will contain additional information about the time entry. (default: false)
  --body: record
]: any -> table<billable: bool, customFieldValues: list<record>, description: string, id: string, isLocked: bool, kioskId: string, projectId: string, tagIds: list<string>, taskId: string, timeInterval: record<duration: string, end: string, start: string>, type: string, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "hydrated" $hydrated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user/($userId)/time-entries" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Duplicate a time entry
#
# POST /v1/workspaces/{workspaceId}/user/{userId}/time-entries/{id}/duplicate
# operationId: duplicateTimeEntry
export def "workspaces-user-time-entries-duplicate duplicateTimeEntry" [
  workspaceId: string
  userId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<billable: bool, customFieldValues: table<customFieldId: string, name: string, timeEntryId: string, type: string, value: record>, description: string, id: string, isLocked: bool, kioskId: string, projectId: string, tagIds: list<string>, taskId: string, timeInterval: record<duration: string, end: string, start: string>, type: string, userId: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/user/($userId)/time-entries/($id)/duplicate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find all users on a workspace
#
# GET /v1/workspaces/{workspaceId}/users
# operationId: getUsersOfWorkspace
export def "workspaces-users get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # If provided, you'll get a filtered list of users that contain the provided string in their email address. (e.g. mail@example.com)
  --project-id: string # If provided, you'll get a list of users that have access to the project. (e.g. 21a687e29ae1f428e7ebe606)
  --status: string@status-completer-5 # If provided, you'll get a filtered list of users with the corresponding status. (e.g. ACTIVE)
  --account-statuses: string # If provided, you'll get a filtered list of users with the corresponding account status filter. If not, this will only filter ACTIVE, PENDING_EMAIL_VERIFICATION, and NOT_REGISTERED Users. (e.g. LIMITED)
  --name: string # If provided, you'll get a filtered list of users that contain the provided string in their name (e.g. John)
  --sort-column: string@sort-column-completer-6 # Sorting column criteria. Default value: EMAIL (e.g. ID)
  --sort-order: string@sort-order-completer # Sorting mode. Default value: ASCENDING (e.g. ASCENDING)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
  --memberships: string@memberships-completer # If provided, you'll get all users along with workspaces, groups, or projects they have access to. Default value is NONE. (e.g. WORKSPACE)
  --include-roles: string # If you pass along includeRoles=true, you'll get each user's detailed manager role (including projects and members which they manage) (default: false)
]: nothing -> table<activeWorkspace: string, customFields: list<record>, defaultWorkspace: string, email: string, id: string, memberships: list<record>, name: string, profilePicture: string, settings: record<alerts: bool, approval: bool, collapseAllProjectLists: bool, dashboardPinToTop: bool, dashboardSelection: string, dashboardViewType: string, dateFormat: string, groupSimilarEntriesDisabled: bool, invoiceReminders: bool, isCompactViewOn: bool, lang: string, longRunning: bool, multiFactorEnabled: bool, myStartOfDay: string, onboarding: bool, projectListCollapse: int, projectPickerTaskFilter: bool, pto: bool, reminders: bool, scheduledReports: bool, scheduling: bool, sendNewsletter: bool, showOnlyWorkingDays: bool, summaryReportSettings: record, theme: string, timeFormat: string, timeTrackingManual: bool, timeZone: string, weekStart: string, weeklyUpdates: bool>, status: record<ACTIVE: string, DELETED: string, LIMITED: string, LIMITED_DELETED: string, NOT_REGISTERED: string, PENDING_EMAIL_VERIFICATION: string, active: bool, limitedAccount: bool, notRegistered: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "project-id" $project_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "account-statuses" $account_statuses "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "include-roles" $include_roles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add user to a workspace
#
# POST /v1/workspaces/{workspaceId}/users
# operationId: addUsers
export def "workspaces-users addUsers" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string # Indicates whether to send an email when user is added to the workspace. (default: true)
  email: string # Represents an email address of the user. (e.g. johndoe@example.com)
]: any -> record<cakeOrganizationId: string, costRate: record<amount: int, currency: string>, currencies: table<code: string, id: string, isDefault: bool>, featureSubscriptionType: record<addonSubscriptionPlan: string, featurePermissions: list<string>, legacy: bool, paidPlan: bool, regionalAllowed: bool, weight: int>, features: record<ADD_TIME_FOR_OTHERS: string, ADMIN_PANEL: string, ALERTS: string, APPROVAL: string, ATTENDANCE_REPORT: string, AUDIT_LOG: string, AUTOMATIC_LOCK: string, BILLABLE_HOURS: string, BRANDED_REPORTS: string, BREAKS: string, BULK_EDIT: string, CLIENT_CURRENCY: string, CREATION_PERMISSIONS: string, CSV_EXPORT: string, CUSTOM_FIELDS: string, CUSTOM_REPORTING: string, CUSTOM_SUBDOMAIN: string, DECIMAL_FORMAT: string, DISABLE_MANUAL_MODE: string, EDIT_MEMBER_PROFILE: string, EXCLUDE_NON_BILLABLE_FROM_ESTIMATE: string, EXPENSES: string, FAVORITE_ENTRIES: string, FILE_IMPORT: string, FORECASTING: string, GRANT_PROJECT_MANAGER_ROLE: string, HIDE_PAGES: string, HISTORIC_RATES: string, INVOICE_EMAILS: string, INVOICE_REMINDERS: string, INVOICING: string, KIOSK: string, KIOSK_PIN_REQUIRED: string, KIOSK_QR_CODE: string, KIOSK_SESSION_DURATION: string, KIOSK_SIX_DIGIT_PIN: string, LABOR_COST: string, LIMITED_USERS: string, LOCATIONS: string, MANAGER_ROLE: string, MONTHLY_OVERTIME_CALCULATION_PERIOD: string, MULTI_FACTOR_AUTHENTICATION: string, ONE_MONTH_RANGE_REPORTS: string, ONE_YEAR_RANGE_REPORTS: string, PRIVATE_PROJECT_ACCESS: string, PROJECT_BUDGET: string, PROJECT_ESTIMATE: string, PROJECT_TEMPLATES: string, QUICKBOOKS_INTEGRATION: string, RECURRING_ESTIMATES: string, RECURRING_INVOICES: string, REQUIRED_FIELDS: string, SCHEDULED_REPORTS: string, SCHEDULING: string, SCHEDULING_FORECASTING: string, SCIM: string, SCREENSHOTS: string, SHARED_REPORTS: string, SPLIT_TIME_ENTRY: string, SSO: string, SUMMARY_ESTIMATE: string, TARGETS_AND_REMINDERS: string, TASK_RATES: string, TIMESHEET_IMPORT: string, TIME_OFF: string, TIME_TRACKING: string, UNLIMITED_REPORTS: string, UNLIMITED_USER_SEATS: string, USER_CUSTOM_FIELDS: string, USER_IMPORT: string, WEEKLY_OVERTIME_CALCULATION_PERIOD: string, WHO_CAN_CHANGE_TIMEENTRY_BILLABILITY: string, WHO_CAN_SEE_ALL_TIME_ENTRIES: string, WHO_CAN_SEE_PROJECT_STATUS: string, WHO_CAN_SEE_PUBLIC_PROJECTS_ENTRIES: string, WHO_CAN_SEE_TEAMS_DASHBOARD: string, WORKSPACE_LOCK_TIMEENTRIES: string, WORKSPACE_TIME_AUDIT: string, WORKSPACE_TIME_ROUNDING: string, WORKSPACE_TRANSFER: string, XLSX_EXPORT: string>, hourlyRate: record<amount: int, currency: string>, id: string, imageUrl: string, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, subdomain: record<enabled: bool, name: string>, workspaceSettings: record<activeBillableHours: bool, adminOnlyPages: string, automaticLock: record<changeDay: string, dayOfMonth: int, firstDay: string, olderThanPeriod: string, olderThanValue: int, type: string>, canSeeTimeSheet: bool, canSeeTracker: bool, currencyFormat: string, defaultBillableProjects: bool, durationFormat: string, entityCreationPermissions: record<whoCanCreateProjectsAndClients: record, whoCanCreateTags: record, whoCanCreateTasks: record>, forceDescription: bool, forceProjects: bool, forceTags: bool, forceTasks: bool, isProjectPublicByDefault: bool, lockTimeEntries: string, lockTimeZone: string, multiFactorEnabled: bool, numberFormat: string, onlyAdminsCanChangeBillableStatus: bool, onlyAdminsCreateProject: bool, onlyAdminsCreateTag: bool, onlyAdminsCreateTask: bool, onlyAdminsSeeAllTimeEntries: bool, onlyAdminsSeeBillableRates: bool, onlyAdminsSeeDashboard: bool, onlyAdminsSeePublicProjectsEntries: bool, projectFavorites: bool, projectGroupingLabel: string, projectLabel: string, projectPickerSpecialFilter: bool, round: record<minutes: string, round: string>, taskLabel: string, timeRoundingInReports: bool, timeTrackingMode: string, trackTimeDownToSecond: bool, workingDays: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "send-email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/users" $qp)
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Filter workspace users
#
# POST /v1/workspaces/{workspaceId}/users/info
# operationId: filterUsersOfWorkspace
export def "workspaces-users-info filterUsersOfWorkspace" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountStatuses: list # If provided, you'll get a filtered list of users with the corresponding account status filter. If not, this will only filter ACTIVE, PENDING_EMAIL_VERIFICATION, and NOT_REGISTERED Users. (e.g. [LIMITED, ACTIVE])
  --email: string # If provided, you'll get a filtered list of users that contain the provided string in their email address. (e.g. mail@example.com)
  --includeRoles: string@bool-completer # If you pass along includeRoles=true, you'll get each user's detailed manager role (including projects and members for whom they're managers) (default: false)
  --memberships: string@memberships-completer # If provided, you'll get all users along with workspaces, groups, or projects they have access to. (default: NONE, e.g. NONE)
  --name: string # If provided, you'll get a filtered list of users that contain the provided string in their name. (e.g. John)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --pageSize: int # Page size. (format: int32, default: 50, e.g. 50)
  --projectId: string # If provided, you'll get a list of users that have access to the project. (e.g. 21a687e29ae1f428e7ebe606)
  --roles: list # If provided, you'll get a filtered list of users that have any of the specified roles. Owners are counted as admins when filtering. (e.g. [WORKSPACE_ADMIN, OWNER])
  --sortColumn: string@sortColumn-completer-1 # Sorting criteria (e.g. ID)
  --sortOrder: string@sortOrder-completer # Sorting mode (e.g. ASCENDING)
  --status: string@status-completer-5 # If provided, you'll get a filtered list of users with the corresponding status. (e.g. ACTIVE)
  --userGroups: list # If provided, you'll get a list of users that belong to the specified user group IDs. (e.g. [5a0ab5acb07987125438b60f, 72wab5acb07987125438b564])
]: any -> table<activeWorkspace: string, customFields: list<record>, defaultWorkspace: string, email: string, id: string, memberships: list<record>, name: string, profilePicture: string, settings: record<alerts: bool, approval: bool, collapseAllProjectLists: bool, dashboardPinToTop: bool, dashboardSelection: string, dashboardViewType: string, dateFormat: string, groupSimilarEntriesDisabled: bool, invoiceReminders: bool, isCompactViewOn: bool, lang: string, longRunning: bool, multiFactorEnabled: bool, myStartOfDay: string, onboarding: bool, projectListCollapse: int, projectPickerTaskFilter: bool, pto: bool, reminders: bool, scheduledReports: bool, scheduling: bool, sendNewsletter: bool, showOnlyWorkingDays: bool, summaryReportSettings: record, theme: string, timeFormat: string, timeTrackingManual: bool, timeZone: string, weekStart: string, weeklyUpdates: bool>, status: record<ACTIVE: string, DELETED: string, LIMITED: string, LIMITED_DELETED: string, NOT_REGISTERED: string, PENDING_EMAIL_VERIFICATION: string, active: bool, limitedAccount: bool, notRegistered: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-marketplace-token"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/users/info")
  let body = {accountStatuses: $accountStatuses, email: $email, includeRoles: $includeRoles, memberships: $memberships, name: $name, page: $page, pageSize: $pageSize, projectId: $projectId, roles: $roles, sortColumn: $sortColumn, sortOrder: $sortOrder, status: $status, userGroups: $userGroups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove user from a workspace
#
# DELETE /v1/workspaces/{workspaceId}/users/{userId}
# DEPRECATED
# operationId: removeMember
@deprecated
export def "workspaces-users removeMember" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cakeOrganizationId: string, costRate: record<amount: int, currency: string>, currencies: table<code: string, id: string, isDefault: bool>, featureSubscriptionType: record<addonSubscriptionPlan: string, featurePermissions: list<string>, legacy: bool, paidPlan: bool, regionalAllowed: bool, weight: int>, features: record<ADD_TIME_FOR_OTHERS: string, ADMIN_PANEL: string, ALERTS: string, APPROVAL: string, ATTENDANCE_REPORT: string, AUDIT_LOG: string, AUTOMATIC_LOCK: string, BILLABLE_HOURS: string, BRANDED_REPORTS: string, BREAKS: string, BULK_EDIT: string, CLIENT_CURRENCY: string, CREATION_PERMISSIONS: string, CSV_EXPORT: string, CUSTOM_FIELDS: string, CUSTOM_REPORTING: string, CUSTOM_SUBDOMAIN: string, DECIMAL_FORMAT: string, DISABLE_MANUAL_MODE: string, EDIT_MEMBER_PROFILE: string, EXCLUDE_NON_BILLABLE_FROM_ESTIMATE: string, EXPENSES: string, FAVORITE_ENTRIES: string, FILE_IMPORT: string, FORECASTING: string, GRANT_PROJECT_MANAGER_ROLE: string, HIDE_PAGES: string, HISTORIC_RATES: string, INVOICE_EMAILS: string, INVOICE_REMINDERS: string, INVOICING: string, KIOSK: string, KIOSK_PIN_REQUIRED: string, KIOSK_QR_CODE: string, KIOSK_SESSION_DURATION: string, KIOSK_SIX_DIGIT_PIN: string, LABOR_COST: string, LIMITED_USERS: string, LOCATIONS: string, MANAGER_ROLE: string, MONTHLY_OVERTIME_CALCULATION_PERIOD: string, MULTI_FACTOR_AUTHENTICATION: string, ONE_MONTH_RANGE_REPORTS: string, ONE_YEAR_RANGE_REPORTS: string, PRIVATE_PROJECT_ACCESS: string, PROJECT_BUDGET: string, PROJECT_ESTIMATE: string, PROJECT_TEMPLATES: string, QUICKBOOKS_INTEGRATION: string, RECURRING_ESTIMATES: string, RECURRING_INVOICES: string, REQUIRED_FIELDS: string, SCHEDULED_REPORTS: string, SCHEDULING: string, SCHEDULING_FORECASTING: string, SCIM: string, SCREENSHOTS: string, SHARED_REPORTS: string, SPLIT_TIME_ENTRY: string, SSO: string, SUMMARY_ESTIMATE: string, TARGETS_AND_REMINDERS: string, TASK_RATES: string, TIMESHEET_IMPORT: string, TIME_OFF: string, TIME_TRACKING: string, UNLIMITED_REPORTS: string, UNLIMITED_USER_SEATS: string, USER_CUSTOM_FIELDS: string, USER_IMPORT: string, WEEKLY_OVERTIME_CALCULATION_PERIOD: string, WHO_CAN_CHANGE_TIMEENTRY_BILLABILITY: string, WHO_CAN_SEE_ALL_TIME_ENTRIES: string, WHO_CAN_SEE_PROJECT_STATUS: string, WHO_CAN_SEE_PUBLIC_PROJECTS_ENTRIES: string, WHO_CAN_SEE_TEAMS_DASHBOARD: string, WORKSPACE_LOCK_TIMEENTRIES: string, WORKSPACE_TIME_AUDIT: string, WORKSPACE_TIME_ROUNDING: string, WORKSPACE_TRANSFER: string, XLSX_EXPORT: string>, hourlyRate: record<amount: int, currency: string>, id: string, imageUrl: string, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, subdomain: record<enabled: bool, name: string>, workspaceSettings: record<activeBillableHours: bool, adminOnlyPages: string, automaticLock: record<changeDay: string, dayOfMonth: int, firstDay: string, olderThanPeriod: string, olderThanValue: int, type: string>, canSeeTimeSheet: bool, canSeeTracker: bool, currencyFormat: string, defaultBillableProjects: bool, durationFormat: string, entityCreationPermissions: record<whoCanCreateProjectsAndClients: record, whoCanCreateTags: record, whoCanCreateTasks: record>, forceDescription: bool, forceProjects: bool, forceTags: bool, forceTasks: bool, isProjectPublicByDefault: bool, lockTimeEntries: string, lockTimeZone: string, multiFactorEnabled: bool, numberFormat: string, onlyAdminsCanChangeBillableStatus: bool, onlyAdminsCreateProject: bool, onlyAdminsCreateTag: bool, onlyAdminsCreateTask: bool, onlyAdminsSeeAllTimeEntries: bool, onlyAdminsSeeBillableRates: bool, onlyAdminsSeeDashboard: bool, onlyAdminsSeePublicProjectsEntries: bool, projectFavorites: bool, projectGroupingLabel: string, projectLabel: string, projectPickerSpecialFilter: bool, round: record<minutes: string, round: string>, taskLabel: string, timeRoundingInReports: bool, timeTrackingMode: string, trackTimeDownToSecond: bool, workingDays: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's status
#
# PUT /v1/workspaces/{workspaceId}/users/{userId}
# operationId: updateUserStatus
export def "workspaces-users updateUserStatus" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer-6 # Represents membership status. (e.g. ACTIVE)
]: any -> record<cakeOrganizationId: string, costRate: record<amount: int, currency: string>, currencies: table<code: string, id: string, isDefault: bool>, featureSubscriptionType: record<addonSubscriptionPlan: string, featurePermissions: list<string>, legacy: bool, paidPlan: bool, regionalAllowed: bool, weight: int>, features: record<ADD_TIME_FOR_OTHERS: string, ADMIN_PANEL: string, ALERTS: string, APPROVAL: string, ATTENDANCE_REPORT: string, AUDIT_LOG: string, AUTOMATIC_LOCK: string, BILLABLE_HOURS: string, BRANDED_REPORTS: string, BREAKS: string, BULK_EDIT: string, CLIENT_CURRENCY: string, CREATION_PERMISSIONS: string, CSV_EXPORT: string, CUSTOM_FIELDS: string, CUSTOM_REPORTING: string, CUSTOM_SUBDOMAIN: string, DECIMAL_FORMAT: string, DISABLE_MANUAL_MODE: string, EDIT_MEMBER_PROFILE: string, EXCLUDE_NON_BILLABLE_FROM_ESTIMATE: string, EXPENSES: string, FAVORITE_ENTRIES: string, FILE_IMPORT: string, FORECASTING: string, GRANT_PROJECT_MANAGER_ROLE: string, HIDE_PAGES: string, HISTORIC_RATES: string, INVOICE_EMAILS: string, INVOICE_REMINDERS: string, INVOICING: string, KIOSK: string, KIOSK_PIN_REQUIRED: string, KIOSK_QR_CODE: string, KIOSK_SESSION_DURATION: string, KIOSK_SIX_DIGIT_PIN: string, LABOR_COST: string, LIMITED_USERS: string, LOCATIONS: string, MANAGER_ROLE: string, MONTHLY_OVERTIME_CALCULATION_PERIOD: string, MULTI_FACTOR_AUTHENTICATION: string, ONE_MONTH_RANGE_REPORTS: string, ONE_YEAR_RANGE_REPORTS: string, PRIVATE_PROJECT_ACCESS: string, PROJECT_BUDGET: string, PROJECT_ESTIMATE: string, PROJECT_TEMPLATES: string, QUICKBOOKS_INTEGRATION: string, RECURRING_ESTIMATES: string, RECURRING_INVOICES: string, REQUIRED_FIELDS: string, SCHEDULED_REPORTS: string, SCHEDULING: string, SCHEDULING_FORECASTING: string, SCIM: string, SCREENSHOTS: string, SHARED_REPORTS: string, SPLIT_TIME_ENTRY: string, SSO: string, SUMMARY_ESTIMATE: string, TARGETS_AND_REMINDERS: string, TASK_RATES: string, TIMESHEET_IMPORT: string, TIME_OFF: string, TIME_TRACKING: string, UNLIMITED_REPORTS: string, UNLIMITED_USER_SEATS: string, USER_CUSTOM_FIELDS: string, USER_IMPORT: string, WEEKLY_OVERTIME_CALCULATION_PERIOD: string, WHO_CAN_CHANGE_TIMEENTRY_BILLABILITY: string, WHO_CAN_SEE_ALL_TIME_ENTRIES: string, WHO_CAN_SEE_PROJECT_STATUS: string, WHO_CAN_SEE_PUBLIC_PROJECTS_ENTRIES: string, WHO_CAN_SEE_TEAMS_DASHBOARD: string, WORKSPACE_LOCK_TIMEENTRIES: string, WORKSPACE_TIME_AUDIT: string, WORKSPACE_TIME_ROUNDING: string, WORKSPACE_TRANSFER: string, XLSX_EXPORT: string>, hourlyRate: record<amount: int, currency: string>, id: string, imageUrl: string, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, subdomain: record<enabled: bool, name: string>, workspaceSettings: record<activeBillableHours: bool, adminOnlyPages: string, automaticLock: record<changeDay: string, dayOfMonth: int, firstDay: string, olderThanPeriod: string, olderThanValue: int, type: string>, canSeeTimeSheet: bool, canSeeTracker: bool, currencyFormat: string, defaultBillableProjects: bool, durationFormat: string, entityCreationPermissions: record<whoCanCreateProjectsAndClients: record, whoCanCreateTags: record, whoCanCreateTasks: record>, forceDescription: bool, forceProjects: bool, forceTags: bool, forceTasks: bool, isProjectPublicByDefault: bool, lockTimeEntries: string, lockTimeZone: string, multiFactorEnabled: bool, numberFormat: string, onlyAdminsCanChangeBillableStatus: bool, onlyAdminsCreateProject: bool, onlyAdminsCreateTag: bool, onlyAdminsCreateTask: bool, onlyAdminsSeeAllTimeEntries: bool, onlyAdminsSeeBillableRates: bool, onlyAdminsSeeDashboard: bool, onlyAdminsSeePublicProjectsEntries: bool, projectFavorites: bool, projectGroupingLabel: string, projectLabel: string, projectPickerSpecialFilter: bool, round: record<minutes: string, round: string>, taskLabel: string, timeRoundingInReports: bool, timeTrackingMode: string, trackTimeDownToSecond: bool, workingDays: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/users/($userId)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a user's cost rate
#
# PUT /v1/workspaces/{workspaceId}/users/{userId}/cost-rate
# operationId: setCostRateForUser
export def "workspaces-users-cost-rate setCostRateForUser" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: int # Represents an amount as integer. (format: int32, e.g. 20000)
  --since: string # Represents a date and time in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
]: any -> record<cakeOrganizationId: string, costRate: record<amount: int, currency: string>, currencies: table<code: string, id: string, isDefault: bool>, featureSubscriptionType: record<addonSubscriptionPlan: string, featurePermissions: list<string>, legacy: bool, paidPlan: bool, regionalAllowed: bool, weight: int>, features: record<ADD_TIME_FOR_OTHERS: string, ADMIN_PANEL: string, ALERTS: string, APPROVAL: string, ATTENDANCE_REPORT: string, AUDIT_LOG: string, AUTOMATIC_LOCK: string, BILLABLE_HOURS: string, BRANDED_REPORTS: string, BREAKS: string, BULK_EDIT: string, CLIENT_CURRENCY: string, CREATION_PERMISSIONS: string, CSV_EXPORT: string, CUSTOM_FIELDS: string, CUSTOM_REPORTING: string, CUSTOM_SUBDOMAIN: string, DECIMAL_FORMAT: string, DISABLE_MANUAL_MODE: string, EDIT_MEMBER_PROFILE: string, EXCLUDE_NON_BILLABLE_FROM_ESTIMATE: string, EXPENSES: string, FAVORITE_ENTRIES: string, FILE_IMPORT: string, FORECASTING: string, GRANT_PROJECT_MANAGER_ROLE: string, HIDE_PAGES: string, HISTORIC_RATES: string, INVOICE_EMAILS: string, INVOICE_REMINDERS: string, INVOICING: string, KIOSK: string, KIOSK_PIN_REQUIRED: string, KIOSK_QR_CODE: string, KIOSK_SESSION_DURATION: string, KIOSK_SIX_DIGIT_PIN: string, LABOR_COST: string, LIMITED_USERS: string, LOCATIONS: string, MANAGER_ROLE: string, MONTHLY_OVERTIME_CALCULATION_PERIOD: string, MULTI_FACTOR_AUTHENTICATION: string, ONE_MONTH_RANGE_REPORTS: string, ONE_YEAR_RANGE_REPORTS: string, PRIVATE_PROJECT_ACCESS: string, PROJECT_BUDGET: string, PROJECT_ESTIMATE: string, PROJECT_TEMPLATES: string, QUICKBOOKS_INTEGRATION: string, RECURRING_ESTIMATES: string, RECURRING_INVOICES: string, REQUIRED_FIELDS: string, SCHEDULED_REPORTS: string, SCHEDULING: string, SCHEDULING_FORECASTING: string, SCIM: string, SCREENSHOTS: string, SHARED_REPORTS: string, SPLIT_TIME_ENTRY: string, SSO: string, SUMMARY_ESTIMATE: string, TARGETS_AND_REMINDERS: string, TASK_RATES: string, TIMESHEET_IMPORT: string, TIME_OFF: string, TIME_TRACKING: string, UNLIMITED_REPORTS: string, UNLIMITED_USER_SEATS: string, USER_CUSTOM_FIELDS: string, USER_IMPORT: string, WEEKLY_OVERTIME_CALCULATION_PERIOD: string, WHO_CAN_CHANGE_TIMEENTRY_BILLABILITY: string, WHO_CAN_SEE_ALL_TIME_ENTRIES: string, WHO_CAN_SEE_PROJECT_STATUS: string, WHO_CAN_SEE_PUBLIC_PROJECTS_ENTRIES: string, WHO_CAN_SEE_TEAMS_DASHBOARD: string, WORKSPACE_LOCK_TIMEENTRIES: string, WORKSPACE_TIME_AUDIT: string, WORKSPACE_TIME_ROUNDING: string, WORKSPACE_TRANSFER: string, XLSX_EXPORT: string>, hourlyRate: record<amount: int, currency: string>, id: string, imageUrl: string, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, subdomain: record<enabled: bool, name: string>, workspaceSettings: record<activeBillableHours: bool, adminOnlyPages: string, automaticLock: record<changeDay: string, dayOfMonth: int, firstDay: string, olderThanPeriod: string, olderThanValue: int, type: string>, canSeeTimeSheet: bool, canSeeTracker: bool, currencyFormat: string, defaultBillableProjects: bool, durationFormat: string, entityCreationPermissions: record<whoCanCreateProjectsAndClients: record, whoCanCreateTags: record, whoCanCreateTasks: record>, forceDescription: bool, forceProjects: bool, forceTags: bool, forceTasks: bool, isProjectPublicByDefault: bool, lockTimeEntries: string, lockTimeZone: string, multiFactorEnabled: bool, numberFormat: string, onlyAdminsCanChangeBillableStatus: bool, onlyAdminsCreateProject: bool, onlyAdminsCreateTag: bool, onlyAdminsCreateTask: bool, onlyAdminsSeeAllTimeEntries: bool, onlyAdminsSeeBillableRates: bool, onlyAdminsSeeDashboard: bool, onlyAdminsSeePublicProjectsEntries: bool, projectFavorites: bool, projectGroupingLabel: string, projectLabel: string, projectPickerSpecialFilter: bool, round: record<minutes: string, round: string>, taskLabel: string, timeRoundingInReports: bool, timeTrackingMode: string, trackTimeDownToSecond: bool, workingDays: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/users/($userId)/cost-rate")
  let body = {amount: $amount, since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a user's custom field
#
# PUT /v1/workspaces/{workspaceId}/users/{userId}/custom-field/{customFieldId}/value
# operationId: upsertUserCustomFieldValue
export def "workspaces-users-custom-field-value upsertUserCustomFieldValue" [
  workspaceId: string
  userId: string
  customFieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --value: record # Represents custom field value. (e.g. 20231211-12345)
]: any -> record<customFieldId: string, customFieldName: string, customFieldType: record<CHECKBOX: string, DROPDOWN_MULTIPLE: string, DROPDOWN_SINGLE: string, LINK: string, NUMBER: string, TXT: string>, userId: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/users/($userId)/custom-field/($customFieldId)/value")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a user's hourly rate
#
# PUT /v1/workspaces/{workspaceId}/users/{userId}/hourly-rate
# operationId: setHourlyRateForUser
export def "workspaces-users-hourly-rate setHourlyRateForUser" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: int # Represents an hourly rate amount as integer. (format: int32, e.g. 20000)
  --since: string # Represents a date and time in yyyy-MM-ddThh:mm:ssZ format. (e.g. 2020-01-01T00:00:00Z)
]: any -> record<cakeOrganizationId: string, costRate: record<amount: int, currency: string>, currencies: table<code: string, id: string, isDefault: bool>, featureSubscriptionType: record<addonSubscriptionPlan: string, featurePermissions: list<string>, legacy: bool, paidPlan: bool, regionalAllowed: bool, weight: int>, features: record<ADD_TIME_FOR_OTHERS: string, ADMIN_PANEL: string, ALERTS: string, APPROVAL: string, ATTENDANCE_REPORT: string, AUDIT_LOG: string, AUTOMATIC_LOCK: string, BILLABLE_HOURS: string, BRANDED_REPORTS: string, BREAKS: string, BULK_EDIT: string, CLIENT_CURRENCY: string, CREATION_PERMISSIONS: string, CSV_EXPORT: string, CUSTOM_FIELDS: string, CUSTOM_REPORTING: string, CUSTOM_SUBDOMAIN: string, DECIMAL_FORMAT: string, DISABLE_MANUAL_MODE: string, EDIT_MEMBER_PROFILE: string, EXCLUDE_NON_BILLABLE_FROM_ESTIMATE: string, EXPENSES: string, FAVORITE_ENTRIES: string, FILE_IMPORT: string, FORECASTING: string, GRANT_PROJECT_MANAGER_ROLE: string, HIDE_PAGES: string, HISTORIC_RATES: string, INVOICE_EMAILS: string, INVOICE_REMINDERS: string, INVOICING: string, KIOSK: string, KIOSK_PIN_REQUIRED: string, KIOSK_QR_CODE: string, KIOSK_SESSION_DURATION: string, KIOSK_SIX_DIGIT_PIN: string, LABOR_COST: string, LIMITED_USERS: string, LOCATIONS: string, MANAGER_ROLE: string, MONTHLY_OVERTIME_CALCULATION_PERIOD: string, MULTI_FACTOR_AUTHENTICATION: string, ONE_MONTH_RANGE_REPORTS: string, ONE_YEAR_RANGE_REPORTS: string, PRIVATE_PROJECT_ACCESS: string, PROJECT_BUDGET: string, PROJECT_ESTIMATE: string, PROJECT_TEMPLATES: string, QUICKBOOKS_INTEGRATION: string, RECURRING_ESTIMATES: string, RECURRING_INVOICES: string, REQUIRED_FIELDS: string, SCHEDULED_REPORTS: string, SCHEDULING: string, SCHEDULING_FORECASTING: string, SCIM: string, SCREENSHOTS: string, SHARED_REPORTS: string, SPLIT_TIME_ENTRY: string, SSO: string, SUMMARY_ESTIMATE: string, TARGETS_AND_REMINDERS: string, TASK_RATES: string, TIMESHEET_IMPORT: string, TIME_OFF: string, TIME_TRACKING: string, UNLIMITED_REPORTS: string, UNLIMITED_USER_SEATS: string, USER_CUSTOM_FIELDS: string, USER_IMPORT: string, WEEKLY_OVERTIME_CALCULATION_PERIOD: string, WHO_CAN_CHANGE_TIMEENTRY_BILLABILITY: string, WHO_CAN_SEE_ALL_TIME_ENTRIES: string, WHO_CAN_SEE_PROJECT_STATUS: string, WHO_CAN_SEE_PUBLIC_PROJECTS_ENTRIES: string, WHO_CAN_SEE_TEAMS_DASHBOARD: string, WORKSPACE_LOCK_TIMEENTRIES: string, WORKSPACE_TIME_AUDIT: string, WORKSPACE_TIME_ROUNDING: string, WORKSPACE_TRANSFER: string, XLSX_EXPORT: string>, hourlyRate: record<amount: int, currency: string>, id: string, imageUrl: string, memberships: table<costRate: record, hourlyRate: record, membershipStatus: string, membershipType: string, targetId: string, userId: string>, name: string, subdomain: record<enabled: bool, name: string>, workspaceSettings: record<activeBillableHours: bool, adminOnlyPages: string, automaticLock: record<changeDay: string, dayOfMonth: int, firstDay: string, olderThanPeriod: string, olderThanValue: int, type: string>, canSeeTimeSheet: bool, canSeeTracker: bool, currencyFormat: string, defaultBillableProjects: bool, durationFormat: string, entityCreationPermissions: record<whoCanCreateProjectsAndClients: record, whoCanCreateTags: record, whoCanCreateTasks: record>, forceDescription: bool, forceProjects: bool, forceTags: bool, forceTasks: bool, isProjectPublicByDefault: bool, lockTimeEntries: string, lockTimeZone: string, multiFactorEnabled: bool, numberFormat: string, onlyAdminsCanChangeBillableStatus: bool, onlyAdminsCreateProject: bool, onlyAdminsCreateTag: bool, onlyAdminsCreateTask: bool, onlyAdminsSeeAllTimeEntries: bool, onlyAdminsSeeBillableRates: bool, onlyAdminsSeeDashboard: bool, onlyAdminsSeePublicProjectsEntries: bool, projectFavorites: bool, projectGroupingLabel: string, projectLabel: string, projectPickerSpecialFilter: bool, round: record<minutes: string, round: string>, taskLabel: string, timeRoundingInReports: bool, timeTrackingMode: string, trackTimeDownToSecond: bool, workingDays: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/users/($userId)/hourly-rate")
  let body = {amount: $amount, since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find user's team manager
#
# GET /v1/workspaces/{workspaceId}/users/{userId}/managers
# operationId: getManagersOfUser
export def "workspaces-users-managers get" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-column: string@sort-column-completer-6 # Sorting column criteria (e.g. ID)
  --sort-order: string@sort-order-completer # Sorting mode (e.g. ASCENDING)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 50, e.g. 50)
]: nothing -> table<activeWorkspace: string, customFields: list<record>, defaultWorkspace: string, email: string, id: string, memberships: list<record>, name: string, profilePicture: string, settings: record<alerts: bool, approval: bool, collapseAllProjectLists: bool, dashboardPinToTop: bool, dashboardSelection: string, dashboardViewType: string, dateFormat: string, groupSimilarEntriesDisabled: bool, invoiceReminders: bool, isCompactViewOn: bool, lang: string, longRunning: bool, multiFactorEnabled: bool, myStartOfDay: string, onboarding: bool, projectListCollapse: int, projectPickerTaskFilter: bool, pto: bool, reminders: bool, scheduledReports: bool, scheduling: bool, sendNewsletter: bool, showOnlyWorkingDays: bool, summaryReportSettings: record, theme: string, timeFormat: string, timeTrackingManual: bool, timeZone: string, weekStart: string, weeklyUpdates: bool>, status: record<ACTIVE: string, DELETED: string, LIMITED: string, LIMITED_DELETED: string, NOT_REGISTERED: string, PENDING_EMAIL_VERIFICATION: string, active: bool, limitedAccount: bool, notRegistered: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "sort-column" $sort_column "scalar") (serialize-qp "sort-order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page-size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/users/($userId)/managers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove user's manager role
#
# DELETE /v1/workspaces/{workspaceId}/users/{userId}/roles
# operationId: deleteUserRole
export def "workspaces-users-roles delete" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entityId: string # Represents an entity identifier across the system. (e.g. 60f924bafdaf031696ec6218)
  role: string@role-completer # Represents a valid role. (e.g. TEAM_MANAGER)
  --sourceType: string@sourceType-completer # Optional field used to indicate that the target of the operation is a user group, in which case the value USER_GROUP should be used, alongside a valid user group ID for the entityId field. If omitted, a user ID should be used for the entityId field.  (e.g. USER_GROUP)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/users/($userId)/roles")
  let body = {entityId: $entityId, role: $role, sourceType: $sourceType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Give manager role to a user
#
# POST /v1/workspaces/{workspaceId}/users/{userId}/roles
# operationId: createUserRole
export def "workspaces-users-roles createUserRole" [
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entityId: string # Represents an entity identifier across the system. (e.g. 60f924bafdaf031696ec6218)
  role: string@role-completer # Represents a valid role. (e.g. TEAM_MANAGER)
  --sourceType: string@sourceType-completer # Optional field used to indicate that the target of the operation is a user group, in which case the value USER_GROUP should be used, alongside a valid user group ID for the entityId field. If omitted, a user ID should be used for the entityId field.  (e.g. USER_GROUP)
]: any -> table<role: record<id: string, name: string, source: record>, userId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/users/($userId)/roles")
  let body = {entityId: $entityId, role: $role, sourceType: $sourceType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all webhooks on a workspace
#
# GET /v1/workspaces/{workspaceId}/webhooks
# operationId: getWebhooks
export def "workspaces-webhooks list" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-2 # Represents a webhook type. (e.g. USER_CREATED)
]: nothing -> record<webhooks: table<authToken: string, deliveryEnabled: bool, enabled: bool, id: string, name: string, planEnabled: bool, triggerSource: list, triggerSourceType: record, url: string, userId: string, webhookEvent: record, workspaceId: string>, workspaceWebhookCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /v1/workspaces/{workspaceId}/webhooks
# operationId: createWebhook
export def "workspaces-webhooks createWebhook" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Represents a webhook name. (e.g. stripe)
  triggerSource: list # Represents a list of trigger sources. (e.g. [54a687e29ae1f428e7ebe909, 87p187e29ae1f428e7ebej56])
  triggerSourceType: string@triggerSourceType-completer # Represents a webhook event trigger source type. (e.g. PROJECT_ID)
  --body-url: string # Represents a webhook target url. (e.g. https://example-clockify.com/stripeEndpoint)
  webhookEvent: string@webhookEvent-completer # Represents a webhook event type. (e.g. NEW_PROJECT)
]: any -> record<authToken: string, deliveryEnabled: bool, enabled: bool, id: string, name: string, planEnabled: bool, triggerSource: list<string>, triggerSourceType: record<ASSIGNMENT_ID: string, EXPENSE_ID: string, PROJECT_ID: string, TAG_ID: string, TASK_ID: string, USER_ID: string, WORKSPACE_ID: string, entityType: string>, url: string, userId: string, webhookEvent: record<APPROVAL_REQUEST_STATUS_UPDATED: string, ASSIGNMENT_CREATED: string, ASSIGNMENT_DELETED: string, ASSIGNMENT_PUBLISHED: string, ASSIGNMENT_UPDATED: string, BALANCE_UPDATED: string, BILLABLE_RATE_UPDATED: string, CLIENT_DELETED: string, CLIENT_UPDATED: string, COST_RATE_UPDATED: string, EXPENSE_CREATED: string, EXPENSE_DELETED: string, EXPENSE_RESTORED: string, EXPENSE_UPDATED: string, INVOICE_UPDATED: string, LIMITED_USERS_ADDED_TO_WORKSPACE: string, NEW_APPROVAL_REQUEST: string, NEW_CLIENT: string, NEW_INVOICE: string, NEW_PROJECT: string, NEW_TAG: string, NEW_TASK: string, NEW_TIMER_STARTED: string, NEW_TIME_ENTRY: string, PROJECT_DELETED: string, PROJECT_UPDATED: string, TAG_DELETED: string, TAG_UPDATED: string, TASK_DELETED: string, TASK_UPDATED: string, TIMER_STOPPED: string, TIME_ENTRY_DELETED: string, TIME_ENTRY_RESTORED: string, TIME_ENTRY_SPLIT: string, TIME_ENTRY_UPDATED: string, TIME_OFF_REQUESTED: string, TIME_OFF_REQUEST_APPROVED: string, TIME_OFF_REQUEST_REJECTED: string, TIME_OFF_REQUEST_STARTED: string, TIME_OFF_REQUEST_UPDATED: string, TIME_OFF_REQUEST_WITHDRAWN: string, USERS_INVITED_TO_WORKSPACE: string, USER_ACTIVATED_ON_WORKSPACE: string, USER_DEACTIVATED_ON_WORKSPACE: string, USER_DELETED_FROM_WORKSPACE: string, USER_EMAIL_CHANGED: string, USER_GROUP_CREATED: string, USER_GROUP_DELETED: string, USER_GROUP_UPDATED: string, USER_JOINED_WORKSPACE: string, USER_UPDATED: string, feature: string, payloadType: string, validSourceTypes: list<string>>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/webhooks")
  let body = {name: $name, triggerSource: $triggerSource, triggerSourceType: $triggerSourceType, url: $body_url, webhookEvent: $webhookEvent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /v1/workspaces/{workspaceId}/webhooks/{webhookId}
# operationId: deleteWebhook
export def "workspaces-webhooks delete" [
  workspaceId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific webhook by id
#
# GET /v1/workspaces/{workspaceId}/webhooks/{webhookId}
# operationId: getWebhook
export def "workspaces-webhooks get" [
  workspaceId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authToken: string, deliveryEnabled: bool, enabled: bool, id: string, name: string, planEnabled: bool, triggerSource: list<string>, triggerSourceType: record<ASSIGNMENT_ID: string, EXPENSE_ID: string, PROJECT_ID: string, TAG_ID: string, TASK_ID: string, USER_ID: string, WORKSPACE_ID: string, entityType: string>, url: string, userId: string, webhookEvent: record<APPROVAL_REQUEST_STATUS_UPDATED: string, ASSIGNMENT_CREATED: string, ASSIGNMENT_DELETED: string, ASSIGNMENT_PUBLISHED: string, ASSIGNMENT_UPDATED: string, BALANCE_UPDATED: string, BILLABLE_RATE_UPDATED: string, CLIENT_DELETED: string, CLIENT_UPDATED: string, COST_RATE_UPDATED: string, EXPENSE_CREATED: string, EXPENSE_DELETED: string, EXPENSE_RESTORED: string, EXPENSE_UPDATED: string, INVOICE_UPDATED: string, LIMITED_USERS_ADDED_TO_WORKSPACE: string, NEW_APPROVAL_REQUEST: string, NEW_CLIENT: string, NEW_INVOICE: string, NEW_PROJECT: string, NEW_TAG: string, NEW_TASK: string, NEW_TIMER_STARTED: string, NEW_TIME_ENTRY: string, PROJECT_DELETED: string, PROJECT_UPDATED: string, TAG_DELETED: string, TAG_UPDATED: string, TASK_DELETED: string, TASK_UPDATED: string, TIMER_STOPPED: string, TIME_ENTRY_DELETED: string, TIME_ENTRY_RESTORED: string, TIME_ENTRY_SPLIT: string, TIME_ENTRY_UPDATED: string, TIME_OFF_REQUESTED: string, TIME_OFF_REQUEST_APPROVED: string, TIME_OFF_REQUEST_REJECTED: string, TIME_OFF_REQUEST_STARTED: string, TIME_OFF_REQUEST_UPDATED: string, TIME_OFF_REQUEST_WITHDRAWN: string, USERS_INVITED_TO_WORKSPACE: string, USER_ACTIVATED_ON_WORKSPACE: string, USER_DEACTIVATED_ON_WORKSPACE: string, USER_DELETED_FROM_WORKSPACE: string, USER_EMAIL_CHANGED: string, USER_GROUP_CREATED: string, USER_GROUP_DELETED: string, USER_GROUP_UPDATED: string, USER_JOINED_WORKSPACE: string, USER_UPDATED: string, feature: string, payloadType: string, validSourceTypes: list<string>>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PUT /v1/workspaces/{workspaceId}/webhooks/{webhookId}
# operationId: updateWebhook
export def "workspaces-webhooks updateWebhook" [
  workspaceId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Represents a webhook name. (e.g. Stripe)
  triggerSource: list # Represents a list of trigger sources. (e.g. [54a687e29ae1f428e7ebe909, 87p187e29ae1f428e7ebej56])
  triggerSourceType: string@triggerSourceType-completer # Represents a webhook event trigger source type. (e.g. PROJECT_ID)
  --body-url: string # Represents a workspace identifier across the system. (e.g. https://example-clockify.com/stripeEndpoint)
  webhookEvent: string@webhookEvent-completer # Represents a webhook event type. (e.g. NEW_PROJECT)
]: any -> record<authToken: string, deliveryEnabled: bool, enabled: bool, id: string, name: string, planEnabled: bool, triggerSource: list<string>, triggerSourceType: record<ASSIGNMENT_ID: string, EXPENSE_ID: string, PROJECT_ID: string, TAG_ID: string, TASK_ID: string, USER_ID: string, WORKSPACE_ID: string, entityType: string>, url: string, userId: string, webhookEvent: record<APPROVAL_REQUEST_STATUS_UPDATED: string, ASSIGNMENT_CREATED: string, ASSIGNMENT_DELETED: string, ASSIGNMENT_PUBLISHED: string, ASSIGNMENT_UPDATED: string, BALANCE_UPDATED: string, BILLABLE_RATE_UPDATED: string, CLIENT_DELETED: string, CLIENT_UPDATED: string, COST_RATE_UPDATED: string, EXPENSE_CREATED: string, EXPENSE_DELETED: string, EXPENSE_RESTORED: string, EXPENSE_UPDATED: string, INVOICE_UPDATED: string, LIMITED_USERS_ADDED_TO_WORKSPACE: string, NEW_APPROVAL_REQUEST: string, NEW_CLIENT: string, NEW_INVOICE: string, NEW_PROJECT: string, NEW_TAG: string, NEW_TASK: string, NEW_TIMER_STARTED: string, NEW_TIME_ENTRY: string, PROJECT_DELETED: string, PROJECT_UPDATED: string, TAG_DELETED: string, TAG_UPDATED: string, TASK_DELETED: string, TASK_UPDATED: string, TIMER_STOPPED: string, TIME_ENTRY_DELETED: string, TIME_ENTRY_RESTORED: string, TIME_ENTRY_SPLIT: string, TIME_ENTRY_UPDATED: string, TIME_OFF_REQUESTED: string, TIME_OFF_REQUEST_APPROVED: string, TIME_OFF_REQUEST_REJECTED: string, TIME_OFF_REQUEST_STARTED: string, TIME_OFF_REQUEST_UPDATED: string, TIME_OFF_REQUEST_WITHDRAWN: string, USERS_INVITED_TO_WORKSPACE: string, USER_ACTIVATED_ON_WORKSPACE: string, USER_DEACTIVATED_ON_WORKSPACE: string, USER_DELETED_FROM_WORKSPACE: string, USER_EMAIL_CHANGED: string, USER_GROUP_CREATED: string, USER_GROUP_DELETED: string, USER_GROUP_UPDATED: string, USER_JOINED_WORKSPACE: string, USER_UPDATED: string, feature: string, payloadType: string, validSourceTypes: list<string>>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/webhooks/($webhookId)")
  let body = {name: $name, triggerSource: $triggerSource, triggerSourceType: $triggerSourceType, url: $body_url, webhookEvent: $webhookEvent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get logs for a webhook
#
# POST /v1/workspaces/{workspaceId}/webhooks/{webhookId}/logs
# operationId: getLogsForWebhook
export def "workspaces-webhooks-logs post" [
  workspaceId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (format: int32, default: 0, e.g. 1)
  --size: int # Page size. (format: int32, default: 50, e.g. 50)
  --body-from: string # Represents date and time in yyyy-MM-ddThh:mm:ssZ format. If provided, results will include logs which occurred after this value. (format: date-time, e.g. 2023-02-01T13:00:46Z)
  --sortByNewest: string@bool-completer # If set to true, logs will be sorted with most recent first. (default: false)
  --status: string@status-completer-7 # Filters logs by status.
  --body-to: string # Represents date and time in yyyy-MM-ddThh:mm:ssZ format. If provided, results will include logs which occurred before this value. (format: date-time, e.g. 2023-02-05T13:00:46Z)
]: any -> table<id: string, requestBody: string, respondedAt: string, responseBody: string, statusCode: int, webhookEventStatusId: string, webhookId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/webhooks/($webhookId)/logs" $qp)
  let body = {from: $body_from, sortByNewest: $sortByNewest, status: $status, to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get webhook event statuses for a webhook
#
# GET /v1/workspaces/{workspaceId}/webhooks/{webhookId}/statuses
# operationId: getWebhookEventStatusesWithLatestLog
export def "workspaces-webhooks-statuses get" [
  workspaceId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number. (format: int32, default: 0, e.g. 1)
  --size: int # Page size. (format: int32, default: 50, e.g. 50)
  --statuses: string@statuses-completer-1 # Represents a filter for webhook event status. (e.g. FAILED)
]: nothing -> table<id: string, requestBody: string, respondedAt: string, responseBody: string, retryCount: int, status: string, statusCode: int, webhookId: string, webhookLogId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "statuses" $statuses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/webhooks/($webhookId)/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a new token
#
# PATCH /v1/workspaces/{workspaceId}/webhooks/{webhookId}/token
# operationId: generateNewToken
export def "workspaces-webhooks-token generateNewToken" [
  workspaceId: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authToken: string, deliveryEnabled: bool, enabled: bool, id: string, name: string, planEnabled: bool, triggerSource: list<string>, triggerSourceType: record<ASSIGNMENT_ID: string, EXPENSE_ID: string, PROJECT_ID: string, TAG_ID: string, TASK_ID: string, USER_ID: string, WORKSPACE_ID: string, entityType: string>, url: string, userId: string, webhookEvent: record<APPROVAL_REQUEST_STATUS_UPDATED: string, ASSIGNMENT_CREATED: string, ASSIGNMENT_DELETED: string, ASSIGNMENT_PUBLISHED: string, ASSIGNMENT_UPDATED: string, BALANCE_UPDATED: string, BILLABLE_RATE_UPDATED: string, CLIENT_DELETED: string, CLIENT_UPDATED: string, COST_RATE_UPDATED: string, EXPENSE_CREATED: string, EXPENSE_DELETED: string, EXPENSE_RESTORED: string, EXPENSE_UPDATED: string, INVOICE_UPDATED: string, LIMITED_USERS_ADDED_TO_WORKSPACE: string, NEW_APPROVAL_REQUEST: string, NEW_CLIENT: string, NEW_INVOICE: string, NEW_PROJECT: string, NEW_TAG: string, NEW_TASK: string, NEW_TIMER_STARTED: string, NEW_TIME_ENTRY: string, PROJECT_DELETED: string, PROJECT_UPDATED: string, TAG_DELETED: string, TAG_UPDATED: string, TASK_DELETED: string, TASK_UPDATED: string, TIMER_STOPPED: string, TIME_ENTRY_DELETED: string, TIME_ENTRY_RESTORED: string, TIME_ENTRY_SPLIT: string, TIME_ENTRY_UPDATED: string, TIME_OFF_REQUESTED: string, TIME_OFF_REQUEST_APPROVED: string, TIME_OFF_REQUEST_REJECTED: string, TIME_OFF_REQUEST_STARTED: string, TIME_OFF_REQUEST_UPDATED: string, TIME_OFF_REQUEST_WITHDRAWN: string, USERS_INVITED_TO_WORKSPACE: string, USER_ACTIVATED_ON_WORKSPACE: string, USER_DEACTIVATED_ON_WORKSPACE: string, USER_DELETED_FROM_WORKSPACE: string, USER_EMAIL_CHANGED: string, USER_GROUP_CREATED: string, USER_GROUP_DELETED: string, USER_GROUP_UPDATED: string, USER_JOINED_WORKSPACE: string, USER_UPDATED: string, feature: string, payloadType: string, validSourceTypes: list<string>>, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://api.clockify.me/api")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/webhooks/($webhookId)/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate shared report by ID
#
# GET /v1/shared-reports/{id}
# operationId: generateSharedReportV1
export def "shared-reports generateSharedReportV1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateRangeStart: string # e.g. 2018-11-01T00:00:00
  --dateRangeEnd: string # e.g. 2018-11-30T23:59:59.999
  --sortOrder: string # e.g. ASCENDING
  --sortColumn: string
  --exportType: string # e.g. JSON
  --page: int # format: int32, e.g. 1
  --pageSize: int # format: int32, e.g. 20
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://reports.api.clockify.me")
  let qp = [(serialize-qp "dateRangeStart" $dateRangeStart "scalar") (serialize-qp "dateRangeEnd" $dateRangeEnd "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "sortColumn" $sortColumn "scalar") (serialize-qp "exportType" $exportType "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/shared-reports/($id)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate an attendance report
#
# POST /v1/workspaces/{workspaceId}/reports/attendance
# operationId: generateAttendanceReport
# --attendanceFilter shape: {balanceFilters?: list, breakFilters?: list, capacityFilters?: list, endFilters?: list, groups?: list, hasTimeOff?: bool, overtimeFilters?: list, page?: int, pageSize?: int, sortColumn?: "GROUP"|"USER"|"DATE"|"START"|"END"|"BREAK"|"WORK"|"CAPACITY"|"OVERTIME"|"UNDERTIME"|"BALANCE"|"TIME_OFF", startFilters?: list, undertimeFilters?: list, workFilters?: list}
# --clients shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --currency shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --customFields item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
# --detailedFilter shape: {auditFilter?: record, options?: record, page?: int, pageSize?: int, sortColumn?: "ID"|"DESCRIPTION"|"USER"|"DURATION"|"DATE"|"ZONED_DATE"|"NATURAL"|"USER_DATE"}
# --projects shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --summaryFilter shape: {groups?: list, sortColumn?: "GROUP"|"DURATION"|"AMOUNT"|"EARNED"|"COST"|"PROFIT", summaryChartType?: "BILLABILITY"|"PROJECT"}
# --tags shape: {containedInTimeentry?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --tasks shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --userGroups shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
# --users shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
# --weeklyFilter shape: {group?: string, subgroup?: string}
export def "workspaces-reports-attendance generateAttendanceReport" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amountShown: string@amountShown-completer # If provided, you'll get filtered result including reports with provided amount shown. (e.g. COST)
  --amounts: list
  --approvalState: string@approvalState-completer # If provided, you'll get filtered result including reports with provided approval state. (e.g. APPROVED)
  --archived: string@bool-completer # Indicates whether the report is archived (e.g. false)
  attendanceFilter: record # Represents an attendance report filter. — shape: {balanceFilters?: list, breakFilters?: list, capacityFilters?: list, endFilters?: list, groups?: list, hasTimeOff?: bool, overtimeFilters?: list, page?: int, pageSize?: int, sortColumn?: "GROUP"|"USER"|"DATE"|"START"|"END"|"BREAK"|"WORK"|"CAPACITY"|"OVERTIME"|"UNDERTIME"|"BALANCE"|"TIME_OFF", startFilters?: list, undertimeFilters?: list, workFilters?: list}
  --billable: string@bool-completer # Indicates whether the report is billable (e.g. true)
  --clients: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --currency: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --customFields: list # item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
  --dateFormat: string # Provide date in format YYYY-MM-DD (e.g. 2018-11-01)
  dateRangeEnd: string # Provide date in format YYYY-MM-DDTHH:MM:SS.ssssss. The system interprets this value based on the user's timezone (provided in the timeZone request parameter or the timezone configured in the user profile) (e.g. 2018-11-30T23:59:59.999)
  dateRangeStart: string # Provide date in format YYYY-MM-DDTHH:MM:SS.ssssss. The system interprets this value based on the user's timezone (provided in the timeZone request parameter or the timezone configured in the user profile) (e.g. 2018-11-01T00:00:00)
  --dateRangeType: string@dateRangeType-completer # Provide the date range type (e.g. LAST_MONTH)
  --description: string # Represents search term for filtering report entries by description (e.g. some description keyword)
  --detailedFilter: record # Represents a detailed report filter. — shape: {auditFilter?: record, options?: record, page?: int, pageSize?: int, sortColumn?: "ID"|"DESCRIPTION"|"USER"|"DURATION"|"DATE"|"ZONED_DATE"|"NATURAL"|"USER_DATE"}
  --exportType: string@exportType-completer # If provided, you'll get filtered result including reports with provided export type. (e.g. JSON)
  --invoicingState: string@invoicingState-completer # If provided, you'll get filtered result including reports with provided invoicing state. (e.g. INVOICED)
  --projects: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --rounding: string@bool-completer # Indicates whether the report filter is rounding (e.g. false)
  --sortOrder: string@sortOrder-completer # If provided, you'll get sorted result by provided sort order. (e.g. ASCENDING)
  --summaryFilter: record # Represents a summary report filter. — shape: {groups?: list, sortColumn?: "GROUP"|"DURATION"|"AMOUNT"|"EARNED"|"COST"|"PROFIT", summaryChartType?: "BILLABILITY"|"PROJECT"}
  --tags: record # Represents an object for filtering entries by tags. — shape: {containedInTimeentry?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --tasks: record # Represents filter criteria for expenses associated with tasks. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --timeFormat: string # Provide time in format THH:MM:SS.ssssss (e.g. T00:00:00)
  --timeZone: string # If provided, you'll get filtered result including reports with provided time zone. (e.g. Europe/Belgrade)
  --userGroups: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
  --userLocale: string # If provided, you'll get filtered result including reports with provided user locale. (e.g. en)
  --users: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
  --weekStart: string@weekStart-completer # If provided, you'll get filtered result including reports with provided week start. (e.g. MONDAY)
  --weeklyFilter: record # Represents a weekly report filter. — shape: {group?: string, subgroup?: string}
  --withoutDescription: string@bool-completer # If set to 'true', report will only include entries with empty description (e.g. false)
  --zoomLevel: string@zoomLevel-completer # If provided, you'll get filtered result including reports with provided zoom level. (e.g. WEEK)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://reports.api.clockify.me")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/reports/attendance")
  let body = {amountShown: $amountShown, amounts: $amounts, approvalState: $approvalState, archived: $archived, attendanceFilter: $attendanceFilter, billable: $billable, clients: $clients, currency: $currency, customFields: $customFields, dateFormat: $dateFormat, dateRangeEnd: $dateRangeEnd, dateRangeStart: $dateRangeStart, dateRangeType: $dateRangeType, description: $description, detailedFilter: $detailedFilter, exportType: $exportType, invoicingState: $invoicingState, projects: $projects, rounding: $rounding, sortOrder: $sortOrder, summaryFilter: $summaryFilter, tags: $tags, tasks: $tasks, timeFormat: $timeFormat, timeZone: $timeZone, userGroups: $userGroups, userLocale: $userLocale, users: $users, weekStart: $weekStart, weeklyFilter: $weeklyFilter, withoutDescription: $withoutDescription, zoomLevel: $zoomLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a detailed report
#
# POST /v1/workspaces/{workspaceId}/reports/detailed
# operationId: generateDetailedReport
# --attendanceFilter shape: {balanceFilters?: list, breakFilters?: list, capacityFilters?: list, endFilters?: list, groups?: list, hasTimeOff?: bool, overtimeFilters?: list, page?: int, pageSize?: int, sortColumn?: "GROUP"|"USER"|"DATE"|"START"|"END"|"BREAK"|"WORK"|"CAPACITY"|"OVERTIME"|"UNDERTIME"|"BALANCE"|"TIME_OFF", startFilters?: list, undertimeFilters?: list, workFilters?: list}
# --clients shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --currency shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --customFields item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
# --detailedFilter shape: {auditFilter?: record, options?: record, page?: int, pageSize?: int, sortColumn?: "ID"|"DESCRIPTION"|"USER"|"DURATION"|"DATE"|"ZONED_DATE"|"NATURAL"|"USER_DATE"}
# --projects shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --summaryFilter shape: {groups?: list, sortColumn?: "GROUP"|"DURATION"|"AMOUNT"|"EARNED"|"COST"|"PROFIT", summaryChartType?: "BILLABILITY"|"PROJECT"}
# --tags shape: {containedInTimeentry?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --tasks shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --userCustomFields item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
# --userGroups shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
# --users shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
# --weeklyFilter shape: {group?: string, subgroup?: string}
export def "workspaces-reports-detailed generateDetailedReport" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amountShown: string@amountShown-completer # If provided, you'll get filtered result including reports with provided amount shown. (e.g. COST)
  --amounts: list
  --approvalState: string@approvalState-completer # If provided, you'll get filtered result including reports with provided approval state. (e.g. APPROVED)
  --archived: string@bool-completer # Indicates whether the report is archived (e.g. false)
  --attendanceFilter: record # Represents an attendance report filter. — shape: {balanceFilters?: list, breakFilters?: list, capacityFilters?: list, endFilters?: list, groups?: list, hasTimeOff?: bool, overtimeFilters?: list, page?: int, pageSize?: int, sortColumn?: "GROUP"|"USER"|"DATE"|"START"|"END"|"BREAK"|"WORK"|"CAPACITY"|"OVERTIME"|"UNDERTIME"|"BALANCE"|"TIME_OFF", startFilters?: list, undertimeFilters?: list, workFilters?: list}
  --billable: string@bool-completer # Indicates whether the report is billable (e.g. true)
  --clients: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --currency: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --customFields: list # item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
  --dateFormat: string # Provide date in format YYYY-MM-DD (e.g. 2018-11-01)
  dateRangeEnd: string # Provide date in format YYYY-MM-DDTHH:MM:SS.ssssss. The system interprets this value based on the user's timezone (provided in the timeZone request parameter or the timezone configured in the user profile) (e.g. 2018-11-30T23:59:59.999)
  dateRangeStart: string # Provide date in format YYYY-MM-DDTHH:MM:SS.ssssss. The system interprets this value based on the user's timezone (provided in the timeZone request parameter or the timezone configured in the user profile) (e.g. 2018-11-01T00:00:00)
  --dateRangeType: string@dateRangeType-completer # Provide the date range type (e.g. LAST_MONTH)
  --description: string # Represents search term for filtering report entries by description (e.g. some description keyword)
  detailedFilter: record # Represents a detailed report filter. — shape: {auditFilter?: record, options?: record, page?: int, pageSize?: int, sortColumn?: "ID"|"DESCRIPTION"|"USER"|"DURATION"|"DATE"|"ZONED_DATE"|"NATURAL"|"USER_DATE"}
  --exportType: string@exportType-completer # If provided, you'll get filtered result including reports with provided export type. (e.g. JSON)
  --invoicingState: string@invoicingState-completer # If provided, you'll get filtered result including reports with provided invoicing state. (e.g. INVOICED)
  --projects: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --rounding: string@bool-completer # Indicates whether the report filter is rounding (e.g. false)
  --sortOrder: string@sortOrder-completer # If provided, you'll get sorted result by provided sort order. (e.g. ASCENDING)
  --summaryFilter: record # Represents a summary report filter. — shape: {groups?: list, sortColumn?: "GROUP"|"DURATION"|"AMOUNT"|"EARNED"|"COST"|"PROFIT", summaryChartType?: "BILLABILITY"|"PROJECT"}
  --tags: record # Represents an object for filtering entries by tags. — shape: {containedInTimeentry?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --tasks: record # Represents filter criteria for expenses associated with tasks. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --timeFormat: string # Provide time in format THH:MM:SS.ssssss (e.g. T00:00:00)
  --timeZone: string # If provided, you'll get filtered result including reports with provided time zone. (e.g. Europe/Belgrade)
  --userCustomFields: list # item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
  --userGroups: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
  --userLocale: string # If provided, you'll get filtered result including reports with provided user locale. (e.g. en)
  --users: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
  --weekStart: string@weekStart-completer # If provided, you'll get filtered result including reports with provided week start. (e.g. MONDAY)
  --weeklyFilter: record # Represents a weekly report filter. — shape: {group?: string, subgroup?: string}
  --withoutDescription: string@bool-completer # If set to 'true', report will only include entries with empty description (e.g. false)
  --zoomLevel: string@zoomLevel-completer # If provided, you'll get filtered result including reports with provided zoom level. (e.g. WEEK)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://reports.api.clockify.me")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/reports/detailed")
  let body = {amountShown: $amountShown, amounts: $amounts, approvalState: $approvalState, archived: $archived, attendanceFilter: $attendanceFilter, billable: $billable, clients: $clients, currency: $currency, customFields: $customFields, dateFormat: $dateFormat, dateRangeEnd: $dateRangeEnd, dateRangeStart: $dateRangeStart, dateRangeType: $dateRangeType, description: $description, detailedFilter: $detailedFilter, exportType: $exportType, invoicingState: $invoicingState, projects: $projects, rounding: $rounding, sortOrder: $sortOrder, summaryFilter: $summaryFilter, tags: $tags, tasks: $tasks, timeFormat: $timeFormat, timeZone: $timeZone, userCustomFields: $userCustomFields, userGroups: $userGroups, userLocale: $userLocale, users: $users, weekStart: $weekStart, weeklyFilter: $weeklyFilter, withoutDescription: $withoutDescription, zoomLevel: $zoomLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate an expense report
#
# POST /v1/workspaces/{workspaceId}/reports/expenses/detailed
# operationId: generateDetailedReportV1
# --categories shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --clients shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --currency shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --projects shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --tasks shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --userGroups shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
# --users shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
export def "workspaces-reports-expenses-detailed generateDetailedReportV1" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --approvalState: string@approvalState-completer # Represents an approval state (e.g. APPROVED)
  --billable: string@bool-completer # Indicates whether report is billable (e.g. true)
  --categories: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --clients: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --currency: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  dateRangeEnd: string # Provide date in format YYYY-MM-DDTHH:MM:SS.ssssss. The system interprets this value based on the user's timezone (provided in the timeZone request parameter or the timezone configured in the user profile) (e.g. 2021-10-27T23:59:59.999)
  dateRangeStart: string # Provide date in format YYYY-MM-DDTHH:MM:SS.ssssss. The system interprets this value based on the user's timezone (provided in the timeZone request parameter or the timezone configured in the user profile) (e.g. 2021-10-27T00:00:00)
  --dateRangeType: string@dateRangeType-completer # Represents date range type of expense report (e.g. TODAY)
  --exportType: string@exportType-completer # Represents an export type (e.g. JSON)
  --invoicingState: string@invoicingState-completer # Represents an invoicing state (e.g. INVOICED)
  --note: string # Represents a search term for filtering report entries by note (e.g. some note keyword)
  --page: int # Page number. (format: int32, e.g. 1)
  --pageSize: int # Page size. (format: int32, e.g. 50)
  --projects: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --sortColumn: string@sortColumn-completer-2 # Represents expenses sort column (e.g. ID)
  --sortOrder: string@sortOrder-completer # Represents a sort order (e.g. ASCENDING)
  --tasks: record # Represents filter criteria for expenses associated with tasks. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --timeZone: string # Represents a time zone (e.g. Europe/Budapest)
  --userGroups: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
  --userLocale: string # Represents a user locale (e.g. en)
  --users: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
  --weekStart: string@weekStart-completer # Represents week start (e.g. MONDAY)
  --withoutNote: string@bool-completer # If set to 'true', report will only include entries with empty note (e.g. false)
  --zoomLevel: string@zoomLevel-completer # Represents a zoom level (e.g. WEEK)
]: any -> record<expenses: table<amount: float, approvalRequestId: string, billable: bool, categoryHasUnitPrice: bool, categoryId: string, categoryName: string, categoryUnit: string, date: string, exportFields: list, fileId: string, fileName: string, id: string, invoicingInfo: record, locked: bool, notes: string, projectColor: string, projectId: string, projectName: string, quantity: float, reportName: string, time: string, userEmail: string, userId: string, userName: string, userStatus: string, workspaceId: string>, totals: record<expensesCount: int, totalAmount: float, totalAmountBillable: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://reports.api.clockify.me")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/reports/expenses/detailed")
  let body = {approvalState: $approvalState, billable: $billable, categories: $categories, clients: $clients, currency: $currency, dateRangeEnd: $dateRangeEnd, dateRangeStart: $dateRangeStart, dateRangeType: $dateRangeType, exportType: $exportType, invoicingState: $invoicingState, note: $note, page: $page, pageSize: $pageSize, projects: $projects, sortColumn: $sortColumn, sortOrder: $sortOrder, tasks: $tasks, timeZone: $timeZone, userGroups: $userGroups, userLocale: $userLocale, users: $users, weekStart: $weekStart, withoutNote: $withoutNote, zoomLevel: $zoomLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a summary report
#
# POST /v1/workspaces/{workspaceId}/reports/summary
# operationId: generateSummaryReport
# --attendanceFilter shape: {balanceFilters?: list, breakFilters?: list, capacityFilters?: list, endFilters?: list, groups?: list, hasTimeOff?: bool, overtimeFilters?: list, page?: int, pageSize?: int, sortColumn?: "GROUP"|"USER"|"DATE"|"START"|"END"|"BREAK"|"WORK"|"CAPACITY"|"OVERTIME"|"UNDERTIME"|"BALANCE"|"TIME_OFF", startFilters?: list, undertimeFilters?: list, workFilters?: list}
# --clients shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --currency shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --customFields item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
# --detailedFilter shape: {auditFilter?: record, options?: record, page?: int, pageSize?: int, sortColumn?: "ID"|"DESCRIPTION"|"USER"|"DURATION"|"DATE"|"ZONED_DATE"|"NATURAL"|"USER_DATE"}
# --projects shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --summaryFilter shape: {groups?: list, sortColumn?: "GROUP"|"DURATION"|"AMOUNT"|"EARNED"|"COST"|"PROFIT", summaryChartType?: "BILLABILITY"|"PROJECT"}
# --tags shape: {containedInTimeentry?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --tasks shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --userCustomFields item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
# --userGroups shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
# --users shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
# --weeklyFilter shape: {group?: string, subgroup?: string}
export def "workspaces-reports-summary generateSummaryReport" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amountShown: string@amountShown-completer # If provided, you'll get filtered result including reports with provided amount shown. (e.g. COST)
  --amounts: list
  --approvalState: string@approvalState-completer # If provided, you'll get filtered result including reports with provided approval state. (e.g. APPROVED)
  --archived: string@bool-completer # Indicates whether the report is archived (e.g. false)
  --attendanceFilter: record # Represents an attendance report filter. — shape: {balanceFilters?: list, breakFilters?: list, capacityFilters?: list, endFilters?: list, groups?: list, hasTimeOff?: bool, overtimeFilters?: list, page?: int, pageSize?: int, sortColumn?: "GROUP"|"USER"|"DATE"|"START"|"END"|"BREAK"|"WORK"|"CAPACITY"|"OVERTIME"|"UNDERTIME"|"BALANCE"|"TIME_OFF", startFilters?: list, undertimeFilters?: list, workFilters?: list}
  --billable: string@bool-completer # Indicates whether the report is billable (e.g. true)
  --clients: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --currency: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --customFields: list # item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
  --dateFormat: string # Provide date in format YYYY-MM-DD (e.g. 2018-11-01)
  dateRangeEnd: string # Provide date in format YYYY-MM-DDTHH:MM:SS.ssssss. The system interprets this value based on the user's timezone (provided in the timeZone request parameter or the timezone configured in the user profile) (e.g. 2018-11-30T23:59:59.999)
  dateRangeStart: string # Provide date in format YYYY-MM-DDTHH:MM:SS.ssssss. The system interprets this value based on the user's timezone (provided in the timeZone request parameter or the timezone configured in the user profile) (e.g. 2018-11-01T00:00:00)
  --dateRangeType: string@dateRangeType-completer # Provide the date range type (e.g. LAST_MONTH)
  --description: string # Represents search term for filtering report entries by description (e.g. some description keyword)
  --detailedFilter: record # Represents a detailed report filter. — shape: {auditFilter?: record, options?: record, page?: int, pageSize?: int, sortColumn?: "ID"|"DESCRIPTION"|"USER"|"DURATION"|"DATE"|"ZONED_DATE"|"NATURAL"|"USER_DATE"}
  --exportType: string@exportType-completer # If provided, you'll get filtered result including reports with provided export type. (e.g. JSON)
  --invoicingState: string@invoicingState-completer # If provided, you'll get filtered result including reports with provided invoicing state. (e.g. INVOICED)
  --projects: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --rounding: string@bool-completer # Indicates whether the report filter is rounding (e.g. false)
  --sortOrder: string@sortOrder-completer # If provided, you'll get sorted result by provided sort order. (e.g. ASCENDING)
  summaryFilter: record # Represents a summary report filter. — shape: {groups?: list, sortColumn?: "GROUP"|"DURATION"|"AMOUNT"|"EARNED"|"COST"|"PROFIT", summaryChartType?: "BILLABILITY"|"PROJECT"}
  --tags: record # Represents an object for filtering entries by tags. — shape: {containedInTimeentry?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --tasks: record # Represents filter criteria for expenses associated with tasks. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --timeFormat: string # Provide time in format THH:MM:SS.ssssss (e.g. T00:00:00)
  --timeZone: string # If provided, you'll get filtered result including reports with provided time zone. (e.g. Europe/Belgrade)
  --userCustomFields: list # item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
  --userGroups: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
  --userLocale: string # If provided, you'll get filtered result including reports with provided user locale. (e.g. en)
  --users: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
  --weekStart: string@weekStart-completer # If provided, you'll get filtered result including reports with provided week start. (e.g. MONDAY)
  --weeklyFilter: record # Represents a weekly report filter. — shape: {group?: string, subgroup?: string}
  --withoutDescription: string@bool-completer # If set to 'true', report will only include entries with empty description (e.g. false)
  --zoomLevel: string@zoomLevel-completer # If provided, you'll get filtered result including reports with provided zoom level. (e.g. WEEK)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://reports.api.clockify.me")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/reports/summary")
  let body = {amountShown: $amountShown, amounts: $amounts, approvalState: $approvalState, archived: $archived, attendanceFilter: $attendanceFilter, billable: $billable, clients: $clients, currency: $currency, customFields: $customFields, dateFormat: $dateFormat, dateRangeEnd: $dateRangeEnd, dateRangeStart: $dateRangeStart, dateRangeType: $dateRangeType, description: $description, detailedFilter: $detailedFilter, exportType: $exportType, invoicingState: $invoicingState, projects: $projects, rounding: $rounding, sortOrder: $sortOrder, summaryFilter: $summaryFilter, tags: $tags, tasks: $tasks, timeFormat: $timeFormat, timeZone: $timeZone, userCustomFields: $userCustomFields, userGroups: $userGroups, userLocale: $userLocale, users: $users, weekStart: $weekStart, weeklyFilter: $weeklyFilter, withoutDescription: $withoutDescription, zoomLevel: $zoomLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a weekly report
#
# POST /v1/workspaces/{workspaceId}/reports/weekly
# operationId: generateWeeklyReport
# --attendanceFilter shape: {balanceFilters?: list, breakFilters?: list, capacityFilters?: list, endFilters?: list, groups?: list, hasTimeOff?: bool, overtimeFilters?: list, page?: int, pageSize?: int, sortColumn?: "GROUP"|"USER"|"DATE"|"START"|"END"|"BREAK"|"WORK"|"CAPACITY"|"OVERTIME"|"UNDERTIME"|"BALANCE"|"TIME_OFF", startFilters?: list, undertimeFilters?: list, workFilters?: list}
# --clients shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --currency shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --customFields item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
# --detailedFilter shape: {auditFilter?: record, options?: record, page?: int, pageSize?: int, sortColumn?: "ID"|"DESCRIPTION"|"USER"|"DURATION"|"DATE"|"ZONED_DATE"|"NATURAL"|"USER_DATE"}
# --projects shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --summaryFilter shape: {groups?: list, sortColumn?: "GROUP"|"DURATION"|"AMOUNT"|"EARNED"|"COST"|"PROFIT", summaryChartType?: "BILLABILITY"|"PROJECT"}
# --tags shape: {containedInTimeentry?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --tasks shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
# --userCustomFields item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
# --userGroups shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
# --users shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
# --weeklyFilter shape: {group?: string, subgroup?: string}
export def "workspaces-reports-weekly generateWeeklyReport" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amountShown: string@amountShown-completer # If provided, you'll get filtered result including reports with provided amount shown. (e.g. COST)
  --amounts: list
  --approvalState: string@approvalState-completer # If provided, you'll get filtered result including reports with provided approval state. (e.g. APPROVED)
  --archived: string@bool-completer # Indicates whether the report is archived (e.g. false)
  --attendanceFilter: record # Represents an attendance report filter. — shape: {balanceFilters?: list, breakFilters?: list, capacityFilters?: list, endFilters?: list, groups?: list, hasTimeOff?: bool, overtimeFilters?: list, page?: int, pageSize?: int, sortColumn?: "GROUP"|"USER"|"DATE"|"START"|"END"|"BREAK"|"WORK"|"CAPACITY"|"OVERTIME"|"UNDERTIME"|"BALANCE"|"TIME_OFF", startFilters?: list, undertimeFilters?: list, workFilters?: list}
  --billable: string@bool-completer # Indicates whether the report is billable (e.g. true)
  --clients: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --currency: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --customFields: list # item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
  --dateFormat: string # Provide date in format YYYY-MM-DD (e.g. 2018-11-01)
  dateRangeEnd: string # Provide date in format YYYY-MM-DDTHH:MM:SS.ssssss. The system interprets this value based on the user's timezone (provided in the timeZone request parameter or the timezone configured in the user profile) (e.g. 2018-11-30T23:59:59.999)
  dateRangeStart: string # Provide date in format YYYY-MM-DDTHH:MM:SS.ssssss. The system interprets this value based on the user's timezone (provided in the timeZone request parameter or the timezone configured in the user profile) (e.g. 2018-11-01T00:00:00)
  --dateRangeType: string@dateRangeType-completer # Provide the date range type (e.g. LAST_MONTH)
  --description: string # Represents search term for filtering report entries by description (e.g. some description keyword)
  --detailedFilter: record # Represents a detailed report filter. — shape: {auditFilter?: record, options?: record, page?: int, pageSize?: int, sortColumn?: "ID"|"DESCRIPTION"|"USER"|"DURATION"|"DATE"|"ZONED_DATE"|"NATURAL"|"USER_DATE"}
  --exportType: string@exportType-completer # If provided, you'll get filtered result including reports with provided export type. (e.g. JSON)
  --invoicingState: string@invoicingState-completer # If provided, you'll get filtered result including reports with provided invoicing state. (e.g. INVOICED)
  --projects: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --rounding: string@bool-completer # Indicates whether the report filter is rounding (e.g. false)
  --sortOrder: string@sortOrder-completer # If provided, you'll get sorted result by provided sort order. (e.g. ASCENDING)
  --summaryFilter: record # Represents a summary report filter. — shape: {groups?: list, sortColumn?: "GROUP"|"DURATION"|"AMOUNT"|"EARNED"|"COST"|"PROFIT", summaryChartType?: "BILLABILITY"|"PROJECT"}
  --tags: record # Represents an object for filtering entries by tags. — shape: {containedInTimeentry?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --tasks: record # Represents filter criteria for expenses associated with tasks. — shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ACTIVE"|"ARCHIVED"|"ALL"}
  --timeFormat: string # Provide time in format THH:MM:SS.ssssss (e.g. T00:00:00)
  --timeZone: string # If provided, you'll get filtered result including reports with provided time zone. (e.g. Europe/Belgrade)
  --userCustomFields: list # item shape: {id?: string, isEmpty?: bool, numberCondition?: "EQUAL"|"GREATER_THAN"|"LESS_THAN", type?: "TXT"|"NUMBER"|"DROPDOWN_SINGLE"|"DROPDOWN_MULTIPLE"|"CHECKBOX"|"LINK", value?: record}
  --userGroups: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
  --userLocale: string # If provided, you'll get filtered result including reports with provided user locale. (e.g. en)
  --users: record # shape: {contains?: "CONTAINS"|"DOES_NOT_CONTAIN"|"CONTAINS_ONLY", ids?: list, status?: "ALL"|"ACTIVE_WITH_PENDING"|"ACTIVE"|"PENDING"|"INACTIVE"}
  --weekStart: string@weekStart-completer # If provided, you'll get filtered result including reports with provided week start. (e.g. MONDAY)
  weeklyFilter: record # Represents a weekly report filter. — shape: {group?: string, subgroup?: string}
  --withoutDescription: string@bool-completer # If set to 'true', report will only include entries with empty description (e.g. false)
  --zoomLevel: string@zoomLevel-completer # If provided, you'll get filtered result including reports with provided zoom level. (e.g. WEEK)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://reports.api.clockify.me")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/reports/weekly")
  let body = {amountShown: $amountShown, amounts: $amounts, approvalState: $approvalState, archived: $archived, attendanceFilter: $attendanceFilter, billable: $billable, clients: $clients, currency: $currency, customFields: $customFields, dateFormat: $dateFormat, dateRangeEnd: $dateRangeEnd, dateRangeStart: $dateRangeStart, dateRangeType: $dateRangeType, description: $description, detailedFilter: $detailedFilter, exportType: $exportType, invoicingState: $invoicingState, projects: $projects, rounding: $rounding, sortOrder: $sortOrder, summaryFilter: $summaryFilter, tags: $tags, tasks: $tasks, timeFormat: $timeFormat, timeZone: $timeZone, userCustomFields: $userCustomFields, userGroups: $userGroups, userLocale: $userLocale, users: $users, weekStart: $weekStart, weeklyFilter: $weeklyFilter, withoutDescription: $withoutDescription, zoomLevel: $zoomLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all my shared reports
#
# GET /v1/workspaces/{workspaceId}/shared-reports
# operationId: getSharedReportsV1
export def "workspaces-shared-reports get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1, e.g. 2
  --pageSize: int # format: int32, default: 50, e.g. 20
  --sharedReportsFilter: string@sharedReportsFilter-completer # default: ALL, e.g. CREATED_BY_ME
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://reports.api.clockify.me")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sharedReportsFilter" $sharedReportsFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/shared-reports" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a shared report
#
# POST /v1/workspaces/{workspaceId}/shared-reports
# operationId: saveSharedReportV1
# --filter shape: {amountShown?: "EARNED"|"COST"|"PROFIT"|"HIDE_AMOUNT"|"EXPORT", amounts?: list, approvalState?: "APPROVED"|"UNAPPROVED"|"ALL", archived?: bool, attendanceFilter?: record, billable?: bool, clients?: record, currency?: record, customFields?: list, dateFormat?: string, dateRangeEnd: string, dateRangeStart: string, dateRangeType?: "ABSOLUTE"|"TODAY"|"YESTERDAY"|"THIS_WEEK"|"LAST_WEEK"|"PAST_TWO_WEEKS"|"THIS_MONTH"|"LAST_MONTH"|"THIS_YEAR"|"LAST_YEAR", description?: string, detailedFilter?: record, exportType?: "JSON"|"JSON_V1"|"PDF"|"CSV"|"XLSX"|"ZIP", invoicingState?: "INVOICED"|"UNINVOICED"|"ALL", projects?: record, rounding?: bool, sortOrder?: "ASCENDING"|"DESCENDING", summaryFilter?: record, tags?: record, tasks?: record, timeFormat?: string, timeZone?: string, userCustomFields?: list, userGroups?: record, userLocale?: string, users?: record, weekStart?: "MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", weeklyFilter?: record, withoutDescription?: bool, zoomLevel?: "WEEK"|"MONTH"|"YEAR"}
export def "workspaces-shared-reports saveSharedReportV1" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record # shape: {amountShown?: "EARNED"|"COST"|"PROFIT"|"HIDE_AMOUNT"|"EXPORT", amounts?: list, approvalState?: "APPROVED"|"UNAPPROVED"|"ALL", archived?: bool, attendanceFilter?: record, billable?: bool, clients?: record, currency?: record, customFields?: list, dateFormat?: string, dateRangeEnd: string, dateRangeStart: string, dateRangeType?: "ABSOLUTE"|"TODAY"|"YESTERDAY"|"THIS_WEEK"|"LAST_WEEK"|"PAST_TWO_WEEKS"|"THIS_MONTH"|"LAST_MONTH"|"THIS_YEAR"|"LAST_YEAR", description?: string, detailedFilter?: record, exportType?: "JSON"|"JSON_V1"|"PDF"|"CSV"|"XLSX"|"ZIP", invoicingState?: "INVOICED"|"UNINVOICED"|"ALL", projects?: record, rounding?: bool, sortOrder?: "ASCENDING"|"DESCENDING", summaryFilter?: record, tags?: record, tasks?: record, timeFormat?: string, timeZone?: string, userCustomFields?: list, userGroups?: record, userLocale?: string, users?: record, weekStart?: "MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", weeklyFilter?: record, withoutDescription?: bool, zoomLevel?: "WEEK"|"MONTH"|"YEAR"}
  --fixedDate: string@bool-completer # Indicates whether the shared report has a fixed date range.
  --isPublic: string@bool-completer # Indicates whether the shared report is public or not (e.g. false)
  --name: string # Represents a shared report's name (e.g. Weekly 1)
  --type: string@type-completer-3 # Represent the type of shared report. (e.g. WEEKLY)
  --visibleToUserGroups: list # Represents user group ids. (e.g. "[5b715448b079875110792222", "5b715448b079875110791111"])
  --visibleToUsers: list # Represents user ids. (e.g. [5b715448b079875110791234, 5b715448b079875110791432, 5b715448b079875110791324])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://reports.api.clockify.me")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/shared-reports")
  let body = {filter: $filter, fixedDate: $fixedDate, isPublic: $isPublic, name: $name, type: $type, visibleToUserGroups: $visibleToUserGroups, visibleToUsers: $visibleToUsers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a shared report
#
# DELETE /v1/workspaces/{workspaceId}/shared-reports/{id}
# operationId: deleteSharedReportV1
export def "workspaces-shared-reports delete" [
  id: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://reports.api.clockify.me")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/shared-reports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a shared report
#
# PUT /v1/workspaces/{workspaceId}/shared-reports/{id}
# operationId: updateSharedReportV1
export def "workspaces-shared-reports updateSharedReportV1" [
  workspaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fixedDate: string@bool-completer # Indicates whether the shared report has a fixed date range. (e.g. false)
  --isPublic: string@bool-completer # Indicates whether the shared report is public. (e.g. false)
  name: string # Represents a shared reports name. (e.g. Weekly Updated Report)
  --visibleToUserGroups: list # Provide user groups ids to which the shared report is visible. (e.g. "[5b715448b079875110792222", "5b715448b079875110791111"])
  --visibleToUsers: list # Provide user ids to which the shared report is visible. (e.g. [5b715448b079875110791234, 5b715448b079875110791432, 5b715448b079875110791324])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://reports.api.clockify.me")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/shared-reports/($id)")
  let body = {fixedDate: $fixedDate, isPublic: $isPublic, name: $name, visibleToUserGroups: $visibleToUserGroups, visibleToUsers: $visibleToUsers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate an audit log report
#
# POST /v1/workspaces/{workspaceId}/audit-log
# operationId: getAuditLogs
# --authors shape: {authorIds: list, contains: "CONTAINS"|"DOES_NOT_CONTAIN"}
export def "workspaces-audit-log post" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actions: list # Represents a set of audit log actions. (e.g. [CREATE_TIME_PERSONAL_MANUAL, CREATE_TIME_PERSONAL_TIMER, CREATE_PROJECT])
  authors: record # Represents the audit log author filter. — shape: {authorIds: list, contains: "CONTAINS"|"DOES_NOT_CONTAIN"}
  end: string # Represents an end date in the yyyy-MM-ddThh:mm:ssZ format. (default: , e.g. 2025-05-01T23:59:59Z)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. (format: int32, default: 20, e.g. 20)
  start: string # Represents a start date in the yyyy-MM-ddThh:mm:ssZ format. (default: , e.g. 2025-05-01T00:00:00Z)
]: any -> record<response: table<action: string, content: string, previousContent: string, timestamp: string, userEmail: string, userId: string, userName: string, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default "https://auditlog-api.api.clockify.me")
  let full_url = (build-url $base $"/v1/workspaces/($workspaceId)/audit-log")
  let body = {actions: $actions, authors: $authors, end: $end, page: $page, page-size: $page_size, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
