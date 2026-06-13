# Auto-generated client for Avaza API Documentation vv1
# Source: https://api.apis.guru/v2/specs/avaza.com/v1/swagger.json
# Auth: --token flag or $env.AVAZA_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.avaza.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AVAZA_API_DOCUMENTATION_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.avaza.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "schedule-series-add-booking AddBooking" } } | get name | first)
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

# Create new Schedule Booking
#
# POST /ScheduleSeries/AddBooking
# operationId: ScheduleSeries_AddBooking
export def "schedule-series-add-booking AddBooking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --CategoryIDFK: int # format: int32
  --DurationType: string
  --EndDate: string # format: date-time
  --HoursPerDay: float # format: double
  --Notes: string
  --ProjectIDFK: int # format: int32
  --ScheduleOnDaysOff: oneof<nothing, bool>
  --StartDate: string # format: date-time
  --TaskIDFK: int # format: int32
  --TotalDuration: float # format: double
  --UserIDFK: int # format: int32
]: any -> record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ScheduleSeries/AddBooking")
  let body = {CategoryIDFK: $CategoryIDFK, DurationType: $DurationType, EndDate: $EndDate, HoursPerDay: $HoursPerDay, Notes: $Notes, ProjectIDFK: $ProjectIDFK, ScheduleOnDaysOff: $ScheduleOnDaysOff, StartDate: $StartDate, TaskIDFK: $TaskIDFK, TotalDuration: $TotalDuration, UserIDFK: $UserIDFK} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create new Leave Booking
#
# POST /ScheduleSeries/AddLeave
# operationId: ScheduleSeries_AddLeave
export def "schedule-series-add-leave AddLeave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --LeaveEndDate: string # format: date-time
  --LeaveHoursPerDay: float # format: double
  --LeaveNotes: string
  --LeaveNotify: oneof<nothing, bool>
  --LeaveStartDate: string # format: date-time
  --LeaveTypeIDFK: int # format: int32
  --LeaveUserIDFK: int # format: int32
]: any -> record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ScheduleSeries/AddLeave")
  let body = {LeaveEndDate: $LeaveEndDate, LeaveHoursPerDay: $LeaveHoursPerDay, LeaveNotes: $LeaveNotes, LeaveNotify: $LeaveNotify, LeaveStartDate: $LeaveStartDate, LeaveTypeIDFK: $LeaveTypeIDFK, LeaveUserIDFK: $LeaveUserIDFK} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Edit Booking
#
# PUT /ScheduleSeries/EditBooking
# operationId: ScheduleSeries_EditBooking
export def "schedule-series-edit-booking EditBooking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --CategoryIDFK: int # format: int32
  --DurationType: string
  --EndDate: string # format: date-time
  --HoursPerDay: float # format: double
  --Notes: string
  --ProjectIDFK: int # format: int32
  --ScheduleOnDaysOff: oneof<nothing, bool>
  --ScheduleSeriesID: int # format: int64
  --StartDate: string # format: date-time
  --TaskIDFK: int # format: int32
  --TotalDuration: float # format: double
  --UserIDFK: int # format: int32
]: any -> record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ScheduleSeries/EditBooking")
  let body = {CategoryIDFK: $CategoryIDFK, DurationType: $DurationType, EndDate: $EndDate, HoursPerDay: $HoursPerDay, Notes: $Notes, ProjectIDFK: $ProjectIDFK, ScheduleOnDaysOff: $ScheduleOnDaysOff, ScheduleSeriesID: $ScheduleSeriesID, StartDate: $StartDate, TaskIDFK: $TaskIDFK, TotalDuration: $TotalDuration, UserIDFK: $UserIDFK} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Edit Leave Booking
#
# PUT /ScheduleSeries/EditLeave
# operationId: ScheduleSeries_EditLeave
export def "schedule-series-edit-leave EditLeave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --EndDate: string # format: date-time
  --HoursPerDay: float # format: double
  --LeaveTypeIDFK: int # format: int32
  --Notes: string
  --ScheduleSeriesID: int # format: int64
  --StartDate: string # format: date-time
  --UserIDFK: int # format: int32
]: any -> record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ScheduleSeries/EditLeave")
  let body = {EndDate: $EndDate, HoursPerDay: $HoursPerDay, LeaveTypeIDFK: $LeaveTypeIDFK, Notes: $Notes, ScheduleSeriesID: $ScheduleSeriesID, StartDate: $StartDate, UserIDFK: $UserIDFK} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Account Details
#
# GET /api/Account
# operationId: Account_Get
export def "account Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AccountEmail: string, AccountID: int, AllowHidingCompletedTasksOnTimesheet: bool, BrandPrimaryColor: string, BrandPrimaryColorLuminance: string, CompanyName: string, CurrentServerTimeISO: string, DefaultCurrencyCode: string, ExpenseApprovalRequired: bool, LockApprovedExpenses: bool, LockApprovedTimesheets: bool, SC: string, Subdomain: string, TimesheetDayOfWeek: int, TimesheetDisplayFormatCode: string, WeeklyTimesheetReminder: bool, has24HourTimesheetFormat: bool, hasStartEndTimesheets: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Account")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Bills
#
# GET /api/Bill
# operationId: Bill_Get
export def "bill Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --Sort: string
  --CompanyIDFK: int # format: int32
]: nothing -> record<Bills: table<AccountIDFK: int, Balance: float, BillNumber: string, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, DateVerified: string, DueDate: string, ExchangeRate: float, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, SupplierPONumber: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "Sort" $Sort "scalar") (serialize-qp "CompanyIDFK" $CompanyIDFK "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Bill" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new draft Bill
#
# POST /api/Bill
# operationId: Bill_Post
# --LineItems item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, ProjectIDFK?: int, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
export def "bill Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --BillNumber: string # Pass any string. If left blank it will use the next number in the auto incrementing sequence. If an integer is passed then the largest integer will be use as the seed to auto generate the next invoice number in the sequence.
  --BillTemplateIDFK: int # If left blank the account default invoice template will be used. (format: int32)
  --CompanyIDFK: int # If left blank then you must specify Company Name. (format: int32)
  --CompanyName: string # If left blank then you must specify Company ID. Specified Name will be used to match existing customer record. If not matched then it will be used to create a new customer. First Name, Last Name and Email will only be used if it is a new company. If the Company name appears multiple times we will check the email address to find a matching company. If email address doesn't identify a matching company then the invoice creation will be rejected.
  --CurrencyCode: string # Expects ISO Standard 3 character currency code. If left blank the currency will default to account's currency in general setting. For existing companies this field will be ignored and the invoice will use the currency of the customer. For new customers if the currency is not specified then account currency will be used otherwise the specified currency will be used.
  --DateIssued: string # If not specified it will use today's date. The date should be specified as local date. (format: date-time)
  --DueDate: string # It will be auto calculated based on the payment term and issue date. Due Date must be greater than or equal to Issue Date. If the Due Date is specified then Payment Terms will be set to -1 (Custom) (format: date-time)
  --Email: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --ExchangeRate: float # Exchange rate is only valid for invoices in currency other than default account currency. If not specified it will get the market rate based on the Date Issued. (format: double)
  --Firstname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --Lastname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --LineItems: list # item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, ProjectIDFK?: int, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
  --Notes: string # Plain UTF8 text. (no HTML). Max 2000 characters
  --PaymentTerms: int #  "If left blank we will set it to customer default. If specified then it must match one of your existing pre configured payment term periods. Your account starts with: (-1 --- Custom, 0 --- Upon Receipt, 7 --- 7 Days, 15 --- 15 Days, 30 --- 30 Days, 45 --- 45 Days, 60 --- 60 Days) (format: int32)
  --Subject: string # Plain UTF8 text. (no HTML). 255 characters max
  --SupplierPONumber: string # Plain UTF8 text. 100 characters max
  --TransactionPrefix: string # A prefix for the Invoice number. e.g. 'INV'. If left blank it will be set to the account default. Max length 20 characters.
  --TransactionTaxConfigCode: string # Possible values are (EX --- Tax Exclusive, INC --- Tax Inclusive). If left empty it will use the account default.
]: any -> record<AccountIDFK: int, Balance: float, BillNumber: string, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, DateVerified: string, DueDate: string, ExchangeRate: float, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, CompanyIDFK: int, CompanyName: string>, LineItems: table<Amount: float, Description: string, Discount: float, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, TransactionLineItemID: int, UnitPrice: float>, Links: record<Edit: string, View: string, WebView: string>, Notes: string, Recipient: record<RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, SupplierPONumber: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Bill")
  let body = {BillNumber: $BillNumber, BillTemplateIDFK: $BillTemplateIDFK, CompanyIDFK: $CompanyIDFK, CompanyName: $CompanyName, CurrencyCode: $CurrencyCode, DateIssued: $DateIssued, DueDate: $DueDate, Email: $Email, ExchangeRate: $ExchangeRate, Firstname: $Firstname, Lastname: $Lastname, LineItems: $LineItems, Notes: $Notes, PaymentTerms: $PaymentTerms, Subject: $Subject, SupplierPONumber: $SupplierPONumber, TransactionPrefix: $TransactionPrefix, TransactionTaxConfigCode: $TransactionTaxConfigCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a Bill by Bill ID
#
# GET /api/Bill/{id}
# operationId: Bill_GetByID
export def "bill GetByID" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Bill/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Bill Payments
#
# GET /api/BillPayment
# operationId: BillPayment_Get
export def "bill-payment Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
]: nothing -> record<PageNumber: int, PageSize: int, Payments: table<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: list, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/BillPayment" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new Bill Payment and optionally assign payment allocations to Bills
#
# POST /api/BillPayment
# operationId: BillPayment_Post
# --PaymentAllocations item shape: {AllocationAmount?: float, AllocationDate?: string, BillTransactionIDFK?: int}
export def "bill-payment Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Amount: float # format: double
  --CompanyIDFK: int # Only required if no invoice allocations specified. (format: int32)
  --CurrencyCode: string # Optional for specifying the Bill Payment's Currency (3 letter ISO Currency Code).
  --DateIssued: string # Date of Payment. If not specified, assumes today. (format: date-time)
  --ExchangeRate: float # Optional. Only used when the Company's currency is different from the Avaza account's base currency. Specifies the exchange rate that should apply between the Company currency and base currency. If not provided we will obtain an up to date exchange rate for the Payment Issue Date. (format: double)
  --Notes: string
  --PaymentAllocations: list # List of amounts within this payment that are allocated to invoices. The sum of these be less than or equal to the payment amount. — item shape: {AllocationAmount?: float, AllocationDate?: string, BillTransactionIDFK?: int}
  --PaymentNumber: string # Optional. If not specified will be automatically generated
  --PaymentProviderCode: string # Optional for storing the payment provider who was the source of funds.
  --TransactionPrefix: string # Optional to override the default prefix added to Payment Numbers
  --TransactionReference: string # Optional for storing the reference # of the payment method.
]: any -> record<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, BillTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/BillPayment")
  let body = {Amount: $Amount, CompanyIDFK: $CompanyIDFK, CurrencyCode: $CurrencyCode, DateIssued: $DateIssued, ExchangeRate: $ExchangeRate, Notes: $Notes, PaymentAllocations: $PaymentAllocations, PaymentNumber: $PaymentNumber, PaymentProviderCode: $PaymentProviderCode, TransactionPrefix: $TransactionPrefix, TransactionReference: $TransactionReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a Bill Payment by Payment Transaction ID
#
# GET /api/BillPayment/{id}
# operationId: BillPayment_GetByID
export def "bill-payment GetByID" [
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
]: nothing -> record<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, BillTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/BillPayment/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Companies
#
# GET /api/Company
# operationId: Company_Get
export def "company Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --pageSize: int # Number of results per page (format: int32)
  --pageNumber: int # 1 based page number to retrieve (format: int32)
  --Sort: string # (optional) Supply one of: "DateUpdated", "DateCreated", "CompanyName","DateUpdated desc","DateCreated desc", "CompanyName desc"
]: nothing -> record<Companies: table<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: list, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "Sort" $Sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Company" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Company
#
# POST /api/Company
# operationId: Company_Post
export def "company Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --BillingAddress: string
  --BillingAddressCity: string
  --BillingAddressLine: string
  --BillingAddressPostCode: string
  --BillingAddressState: string
  --BillingCountryCode: string
  --Comments: string
  CompanyName: string
  --CurrencyCode: string
  --Fax: string
  --Phone: string
  --TaxNumber: string
  --website: string
]: any -> record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Company")
  let body = {BillingAddress: $BillingAddress, BillingAddressCity: $BillingAddressCity, BillingAddressLine: $BillingAddressLine, BillingAddressPostCode: $BillingAddressPostCode, BillingAddressState: $BillingAddressState, BillingCountryCode: $BillingCountryCode, Comments: $Comments, CompanyName: $CompanyName, CurrencyCode: $CurrencyCode, Fax: $Fax, Phone: $Phone, TaxNumber: $TaxNumber, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a Company record.
#
# PUT /api/Company
# operationId: Company_Put
export def "company Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --BillingAddress: string
  --BillingAddressCity: string
  --BillingAddressLine: string
  --BillingAddressPostCode: string
  --BillingAddressState: string
  --BillingCountryCode: string
  --Comments: string
  --CompanyID: int # format: int32
  --CompanyName: string
  --Fax: string
  --FieldsToUpdate: list
  --Phone: string
  --TaxNumber: string
  --website: string
]: any -> record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Company")
  let body = {BillingAddress: $BillingAddress, BillingAddressCity: $BillingAddressCity, BillingAddressLine: $BillingAddressLine, BillingAddressPostCode: $BillingAddressPostCode, BillingAddressState: $BillingAddressState, BillingCountryCode: $BillingCountryCode, Comments: $Comments, CompanyID: $CompanyID, CompanyName: $CompanyName, Fax: $Fax, FieldsToUpdate: $FieldsToUpdate, Phone: $Phone, TaxNumber: $TaxNumber, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets minimal list of Companies.
#
# GET /api/Company/Lookup
# operationId: CompanyLookup
export def "company-lookup CompanyLookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --search: string # Search string to match against Company title
]: nothing -> record<Companies: table<CompanyID: int, CompanyName: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Company/Lookup" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Company by Company ID
#
# GET /api/Company/{id}
# operationId: Company_GetByID
export def "company GetByID" [
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
]: nothing -> record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Company/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Contacts
#
# GET /api/Contact
# operationId: Contact_Get
export def "contact Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --Sort: string
  --CompanyIDFK: int # format: int32
]: nothing -> record<Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "Sort" $Sort "scalar") (serialize-qp "CompanyIDFK" $CompanyIDFK "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Contact" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Contact
#
# POST /api/Contact
# operationId: Contact_Post
export def "contact Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --CompanyBillingAddress: string
  --CompanyBillingAddressCity: string
  --CompanyBillingAddressCountryCode: string
  --CompanyBillingAddressLine: string
  --CompanyBillingAddressPostCode: string
  --CompanyBillingAddressState: string
  --CompanyIDFK: int # format: int32
  --CompanyName: string
  ContactEmail: string
  --CurrencyCode: string
  Firstname: string
  Lastname: string
  --Mobile: string
  --Phone: string
  --PositionTitle: string
  --UpdateExisting: oneof<nothing, bool>
]: any -> record<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Contact")
  let body = {CompanyBillingAddress: $CompanyBillingAddress, CompanyBillingAddressCity: $CompanyBillingAddressCity, CompanyBillingAddressCountryCode: $CompanyBillingAddressCountryCode, CompanyBillingAddressLine: $CompanyBillingAddressLine, CompanyBillingAddressPostCode: $CompanyBillingAddressPostCode, CompanyBillingAddressState: $CompanyBillingAddressState, CompanyIDFK: $CompanyIDFK, CompanyName: $CompanyName, ContactEmail: $ContactEmail, CurrencyCode: $CurrencyCode, Firstname: $Firstname, Lastname: $Lastname, Mobile: $Mobile, Phone: $Phone, PositionTitle: $PositionTitle, UpdateExisting: $UpdateExisting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets Contact by Contact ID
#
# GET /api/Contact/{id}
# operationId: Contact_GetByID
export def "contact GetByID" [
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
]: nothing -> record<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Contact/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of CreditNotes
#
# GET /api/CreditNote
# operationId: CreditNote_Get
export def "credit-note Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
]: nothing -> record<CreditNotes: table<Balance: float, CreditNoteAllocations: list, CreditNoteLineItems: list, CreditNoteNumber: string, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, Notes: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/CreditNote" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Credit Note by CreditNoteID
#
# GET /api/CreditNote/{id}
# operationId: CreditNote_GetByID
export def "credit-note GetByID" [
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
]: nothing -> record<Balance: float, CreditNoteAllocations: table<AllocationAmount: float, AllocationDate: string, CreditNoteTransactionIDFK: int, InvoiceTransactionIDFK: int, TransactionAllocationID: int>, CreditNoteLineItems: table<Amount: float, Description: string, Discount: float, Quantity: float, TaxAmount: float, TaxIDFK: int, TransactionLineItemID: int, UnitPrice: float>, CreditNoteNumber: string, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, Notes: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/CreditNote/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Currencies
#
# GET /api/Currency
# operationId: Currency_Get
export def "currency Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Currencies: table<CurrencyCode: string, DecimalPlaces: int, Name: string, Symbol: string, Symbol2: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Currency")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Estimates
#
# GET /api/Estimate
# operationId: Estimate_Get
export def "estimate Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --Sort: string
  --CompanyIDFK: int # format: int32
]: nothing -> record<Estimates: table<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, EstimateID: int, EstimateItemNumber: string, EstimatePrefix: string, EstimateStatusCode: string, EstimateTaxConfigCode: string, ExchangeRate: float, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, TaxAmount: float, TotalAmount: float>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "Sort" $Sort "scalar") (serialize-qp "CompanyIDFK" $CompanyIDFK "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Estimate" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new draft Estimate
#
# POST /api/Estimate
# operationId: Estimate_Post
# --LineItems item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
export def "estimate Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --CompanyIDFK: int # If left blank then you must specify Company Name. (format: int32)
  --CompanyName: string # If left blank then you must specify Company ID. Specified Name will be used to match existing customer record. If not matched then it will be used to create a new customer. First Name, Last Name and Email will only be used if it is a new company. If the Company name appears multiple times we will check the email address to find a matching company. If email address doesn't identify a matching company then the Estimate creation will be rejected.
  --CurrencyCode: string # Expects ISO Standard 3 character currency code. If left blank the currency will default to account's currency in general setting. For existing companies this field will be ignored and the Estimate will use the currency of the customer. For new customers if the currency is not specified then account currency will be used otherwise the specified currency will be used.
  --CustomerPONumber: string # Plain UTF8 text. 100 characters max
  --DateIssued: string # If not specified it will use today's date. The date should be specified as local date. (format: date-time)
  --DueDate: string # It will be auto calculated based on the payment term and issue date. Due Date must be greater than or equal to Issue Date. If the Due Date is specified then Payment Terms will be set to -1 (Custom) (format: date-time)
  --Email: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --EstimateNumber: string # Pass any string. If left blank it will use the next number in the auto incrementing sequence. If an integer is passed then the largest integer will be use as the seed to auto generate the next Estimate number in the sequence.
  --EstimatePrefix: string # A prefix for the Estimate number. e.g. 'INV'. If left blank it will be set to the account default. Max length 20 characters.
  --EstimateTaxConfigCode: string # Possible values are (EX --- Tax Exclusive, INC --- Tax Inclusive). If left empty it will use the account default.
  --ExchangeRate: float # Exchange rate is only valid for Estimates in currency other than default account currency. If not specified it will get the market rate based on the Date Issued. (format: double)
  --Firstname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --InvoiceTemplateIDFK: int # If left blank the account default Estimate template will be used. (format: int32)
  --Lastname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --LineItems: list # item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
  --Notes: string # Plain UTF8 text. (no HTML). Max 2000 characters
  --Subject: string # Plain UTF8 text. (no HTML). 255 characters max
]: any -> record<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, EstimateID: int, EstimateItemNumber: string, EstimatePrefix: string, EstimateStatusCode: string, EstimateTaxConfigCode: string, ExchangeRate: float, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, TaxNumber: string>, LineItems: table<Amount: float, Description: string, Discount: float, EstimateLineItemID: int, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, UnitPrice: float>, Links: record<ClientView: string, Edit: string, View: string>, Notes: string, Recipient: record<CompanyIDFK: int, CompanyName: string, RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, TaxAmount: float, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Estimate")
  let body = {CompanyIDFK: $CompanyIDFK, CompanyName: $CompanyName, CurrencyCode: $CurrencyCode, CustomerPONumber: $CustomerPONumber, DateIssued: $DateIssued, DueDate: $DueDate, Email: $Email, EstimateNumber: $EstimateNumber, EstimatePrefix: $EstimatePrefix, EstimateTaxConfigCode: $EstimateTaxConfigCode, ExchangeRate: $ExchangeRate, Firstname: $Firstname, InvoiceTemplateIDFK: $InvoiceTemplateIDFK, Lastname: $Lastname, LineItems: $LineItems, Notes: $Notes, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets Estimate by Estimate ID
#
# GET /api/Estimate/{id}
# operationId: Estimate_GetByID
export def "estimate GetByID" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Estimate/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Timesheet Entry
#
# DELETE /api/Expense
# operationId: Expense_Delete
export def "expense Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> record<Results: table<ErrorMessage: string, ExpenseID: int, Success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Expense")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets list of Expenses
#
# GET /api/Expense
# operationId: Expense_Get
export def "expense Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --ExpenseDateFrom: string # format: date-time
  --ExpenseDateTo: string # format: date-time
  --UserEmail: string
  --UserID: int # format: int32
  --CategoryName: string
  --CustomerID: int # format: int32
  --ProjectID: int # format: int32
  --isChargeable: oneof<nothing, bool>
  --isInvoiced: oneof<nothing, bool>
  --ExpenseReimbursementIDFK: int # format: int64
  --ExpensePaymentMethodIDFK: int # format: int32
  --ExpenseApprovalStatusCode: string
  --Search: string
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --Sort: string
]: nothing -> record<Expenses: table<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "ExpenseDateFrom" $ExpenseDateFrom "scalar") (serialize-qp "ExpenseDateTo" $ExpenseDateTo "scalar") (serialize-qp "UserEmail" $UserEmail "scalar") (serialize-qp "UserID" $UserID "scalar") (serialize-qp "CategoryName" $CategoryName "scalar") (serialize-qp "CustomerID" $CustomerID "scalar") (serialize-qp "ProjectID" $ProjectID "scalar") (serialize-qp "isChargeable" $isChargeable "scalar") (serialize-qp "isInvoiced" $isInvoiced "scalar") (serialize-qp "ExpenseReimbursementIDFK" $ExpenseReimbursementIDFK "scalar") (serialize-qp "ExpensePaymentMethodIDFK" $ExpensePaymentMethodIDFK "scalar") (serialize-qp "ExpenseApprovalStatusCode" $ExpenseApprovalStatusCode "scalar") (serialize-qp "Search" $Search "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "Sort" $Sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Expense" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Expense
#
# POST /api/Expense
# operationId: Expense_Post
export def "expense Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Amount: float # Expense Amount (Required). Must be &gt;= 0 (format: double)
  --CurrencyCode: string # A 3-letter ISO CurrencyCode for the expense currency. (e.g. USD). If not provided, defaults to the Account base currency.
  --CustomerIDFK: int # The Avaza Customer ID to associate the Expense with. Either this field or CustomerName can be provided. (format: int32)
  --CustomerName: string # The name of an existing customer in Avaza. Must be an exact (case insensitive) match.
  --ExchangeRate: float # Optional (Only relevant if the expense currency is different to your account currency. If not provided we will look up the market exchange rate for you based on the expense date.) Exchange Rate = Expense Currency Amount / Base Currency Amount (e.g. if Expense currency is in AUD, and Base Currency is in USD, Exchange Rate = AUD $140 / USD $100 = 1.4) (format: double)
  --ExpenseCategoryIDFK: int # The expense category to link the Expense to. If not provided, ExpenseCategoryName must be provided (format: int32)
  --ExpenseCategoryName: string # Must match an existing expense category name otherwise a new category will be created. If left blank Expense Category ID must be provided.
  --ExpenseDate: string # The date of the expense entry (Required) (format: date-time)
  --ExpensePaymentMethodIDFK: int # (Optional) ID of Expense Payment Method. (format: int32)
  --FileAttachmentIDs: list # Array of File Attachment IDs to associate with this expense. The files need to have already been uploaded. Currently only accepts a single file.
  --GroupTripName: string # Links the expense to a Grouping/Trip report. If no matching name found, creates a new Group/Trip Report name.
  --Merchant: string # The name of the merchant.
  --MerchantTaxNumber: string # A Tax number identifier for the merchant.
  --Notes: string # Expense Notes
  --ProjectIDFK: int # The Avaza project ID to associate the Expense with. (format: int32)
  --ProjectName: string # Can work for matching an expense to a project, but only if it's an exact match for a single project under the customer.
  --Quantity: float # Conditional - available for expenses that are assigned a unit priced based expense category. e.g Mileage (format: double)
  --TaskIDFK: int # (optional) TaskID of a Task to link the new Expense to. A Customer and Project must be provided also. (format: int32)
  --TaxIDFK: int # Avaza Tax ID the expense belongs to. If left blank then Tax Name must be provided. (format: int32)
  --TaxName: string # Must exactly match an existing Tax Name that you have configured in Avaza Tax settings. If left blank then Tax ID must be provided.
  --TransactionTaxConfigCode: string # Optional - Enter "INC" if the tax amount is included in the expense amount otherwise enter "EX" when the amount exlcudes the tax. Defaults to "Ex". The tax amount on the expense will be autocalculated.
  --UserEmail: string # The email address of a Timesheet/Expense user in Avaza. If not provided, UserIDFK field must be provided.
  --UserIDFK: int # UserID for a Timesheet/Expense user in Avaza. If not provided, UserEmail field must be provided (format: int32)
  --VerifyAndSave: oneof<nothing, bool> # Pass false if creating a draft expense. True otherwise.
  --isChargeable: oneof<nothing, bool> # aka Billable. Defaults to false if not provided. If set to true, a CustomerIDFK or CustomerName must be provided.
  --isReimbursable: oneof<nothing, bool> # Defaults to false if not provided.
]: any -> record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Expense")
  let body = {Amount: $Amount, CurrencyCode: $CurrencyCode, CustomerIDFK: $CustomerIDFK, CustomerName: $CustomerName, ExchangeRate: $ExchangeRate, ExpenseCategoryIDFK: $ExpenseCategoryIDFK, ExpenseCategoryName: $ExpenseCategoryName, ExpenseDate: $ExpenseDate, ExpensePaymentMethodIDFK: $ExpensePaymentMethodIDFK, FileAttachmentIDs: $FileAttachmentIDs, GroupTripName: $GroupTripName, Merchant: $Merchant, MerchantTaxNumber: $MerchantTaxNumber, Notes: $Notes, ProjectIDFK: $ProjectIDFK, ProjectName: $ProjectName, Quantity: $Quantity, TaskIDFK: $TaskIDFK, TaxIDFK: $TaxIDFK, TaxName: $TaxName, TransactionTaxConfigCode: $TransactionTaxConfigCode, UserEmail: $UserEmail, UserIDFK: $UserIDFK, VerifyAndSave: $VerifyAndSave, isChargeable: $isChargeable, isReimbursable: $isReimbursable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an Expense
#
# PUT /api/Expense
# operationId: Expense_Put
export def "expense Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Amount: float # Expense Amount (Required). Must be &gt;= 0 (format: double)
  --CurrencyCode: string # A 3-letter ISO CurrencyCode for the expense currency. (e.g. USD). If not provided, defaults to the Account base currency.
  --CustomerIDFK: int # The Avaza Customer ID to associate the Expense with. (format: int32)
  --ExchangeRate: float # Optional (Only relevant if the expense currency is different to your account currency. If not provided we will look up the market exchange rate for you based on the expense date.) Exchange Rate = Expense Currency Amount / Base Currency Amount (e.g. if Expense currency is in AUD, and Base Currency is in USD, Exchange Rate = AUD $140 / USD $100 = 1.4) (format: double)
  --ExpenseCategoryIDFK: int # The expense category to link the Expense to. (format: int32)
  --ExpenseDate: string # The date of the expense entry (format: date-time)
  ExpenseID: int # format: int64
  --ExpensePaymentMethodIDFK: int # (Optional) ID of Expense Payment Method. (format: int32)
  FieldsToUpdate: list
  --FileAttachmentIDs: list # Array of File Attachment IDs to associate with this expense. The files need to have already been uploaded. Currently only accepts a single file.
  --GroupTripName: string # Links the expense to a Grouping/Trip report. If no matching name found, creates a new Group/Trip Report name.
  --Merchant: string # The name of the merchant.
  --MerchantTaxNumber: string # A Tax number identifier for the merchant.
  --Notes: string # Expense Notes
  --ProjectIDFK: int # The Avaza project ID to associate the Expense with. (format: int32)
  --Quantity: float # Conditional - available for expenses that are assigned a unit priced based expense category. e.g Mileage (format: double)
  --TaskIDFK: int # (optional) TaskID of a Task to link the new Expense to. A Customer and Project must be provided also. (format: int32)
  --TaxIDFK: int # Avaza Tax ID the expense belongs to. (format: int32)
  --TransactionTaxConfigCode: string # Optional - Enter "INC" if the tax amount is included in the expense amount otherwise enter "EX" when the amount exlcudes the tax. Defaults to "Ex". The tax amount on the expense will be autocalculated.
  --VerifyAndSave: oneof<nothing, bool> # Pass false if creating a draft expense. True otherwise.
  --isChargeable: oneof<nothing, bool> # aka Billable. Defaults to false if not provided. If set to true, a CustomerIDFK or CustomerName must be provided.
  --isReimbursable: oneof<nothing, bool> # Defaults to false if not provided.
]: any -> record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Expense")
  let body = {Amount: $Amount, CurrencyCode: $CurrencyCode, CustomerIDFK: $CustomerIDFK, ExchangeRate: $ExchangeRate, ExpenseCategoryIDFK: $ExpenseCategoryIDFK, ExpenseDate: $ExpenseDate, ExpenseID: $ExpenseID, ExpensePaymentMethodIDFK: $ExpensePaymentMethodIDFK, FieldsToUpdate: $FieldsToUpdate, FileAttachmentIDs: $FileAttachmentIDs, GroupTripName: $GroupTripName, Merchant: $Merchant, MerchantTaxNumber: $MerchantTaxNumber, Notes: $Notes, ProjectIDFK: $ProjectIDFK, Quantity: $Quantity, TaskIDFK: $TaskIDFK, TaxIDFK: $TaxIDFK, TransactionTaxConfigCode: $TransactionTaxConfigCode, VerifyAndSave: $VerifyAndSave, isChargeable: $isChargeable, isReimbursable: $isReimbursable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/Expense/Attachment
#
# operationId: ExpenseAttachment
export def "expense-attachment ExpenseAttachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  File: path # Upload software package
]: any -> record<FileAttachments: table<FileAttachmentID: int, OriginalFilename: string, PreviewBaseURL: string, PublicFileURL: string, SizeBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Expense/Attachment")
  let body = {File: $File} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($File | is-not-empty) { $body | upsert File (open -r $File) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Gets an Expense Entry by Expense ID
#
# GET /api/Expense/{id}
# operationId: Expense_GetByID
export def "expense GetByID" [
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
]: nothing -> record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Expense/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit Expenses for Approval.
#
# POST /api/ExpenseApproval/Submit
# operationId: ExpenseApproval
export def "expense-approval-submit ExpenseApproval" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UserID: int # The user to submit the Expenses for. Defaults to current user. Only allowed to be different from the current user when the current user has rights to Impersonate other users. (format: int32)
  --SendNotifications: oneof<nothing, bool> # Send email alerts to expense approvers. Defaults to true
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserID" $UserID "scalar") (serialize-qp "SendNotifications" $SendNotifications "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ExpenseApproval/Submit" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets list of Expense Categories
#
# GET /api/ExpenseCategory
# operationId: ExpenseCategory_Get
export def "expense-category Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --isEnabled: oneof<nothing, bool> # Optional filter on for enabled/disabled categories. Defaults to true.
]: nothing -> record<Categories: table<Enabled: bool, ExpenseCategoryID: int, Name: string, UnitName: string, UnitPrice: float, hasUnitPrice: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isEnabled" $isEnabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ExpenseCategory" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets minimal list of Expense Groups.
#
# GET /api/ExpenseGroup/Lookup
# operationId: ExpenseGroupLookup
export def "expense-group-lookup ExpenseGroupLookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --search: string # Search string to match against Expense Group Name
]: nothing -> record<ExpenseGroups: table<ExpenseGroupID: int, Name: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ExpenseGroup/Lookup" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets minimal list of Expense Merchants.
#
# GET /api/ExpenseMerchant/Lookup
# operationId: ExpenseMerchangeLookup
export def "expense-merchant-lookup ExpenseMerchangeLookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --search: string # Search string to match against Expense Group Name
]: nothing -> record<ExpenseMerchants: table<MerchantName: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ExpenseMerchant/Lookup" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets minimal list of Expense Payment Methods.
#
# GET /api/ExpensePaymentMethod/Lookup
# operationId: ExpensePaymentMethodLookup
export def "expense-payment-method-lookup ExpensePaymentMethodLookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ExpensePaymentMethods: table<ExpensePaymentMethodID: int, Name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ExpensePaymentMethod/Lookup")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Basic Summary of Expense Statistics
#
# GET /api/ExpenseSummary
# operationId: ExpenseSummary_Get
export def "expense-summary Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --modelgroupBy: list # (Optional) Combine one, two or three levels of Grouping. Combine these possible grouping values: "Category", "ChargeableStatus", "Merchant", "ApprovalStatus", "ReimbursementStatus", "Customer", "Project", "User", "Task", "Year", "Month", "Day", "Week".
  --modelexpenseDateFrom: string # (Required) Filter for expenses with expense dates greater or equal to the specified date. e.g. 2019-01-25. (format: date-time)
  --modelexpenseDateTo: string # (Required) Filter for expenses with an expense date smaller or equal to the specified  date. e.g. 2019-01-25. (format: date-time)
  --modeluserID: list # (Optional) Defaults to the current user. Provide one or more UserIDs of Users whose expenses should be retrieved. If the current user doesn't have impersonation rights, then they will only see their own data.
  --modelprojectID: int # (Optional) Filter by Project (format: int32)
]: nothing -> record<ExpenseDateFrom: string, ExpenseDateTo: string, GroupData: table<GroupData: list, GroupID: string, GroupName: string, TotalAmount: float>, GroupingLevels: list<string>, TotalAmount: float, UserID: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model.groupBy" $modelgroupBy "multi") (serialize-qp "model.expenseDateFrom" $modelexpenseDateFrom "scalar") (serialize-qp "model.expenseDateTo" $modelexpenseDateTo "scalar") (serialize-qp "model.userID" $modeluserID "multi") (serialize-qp "model.projectID" $modelprojectID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ExpenseSummary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Fixed Amounts
#
# GET /api/FixedAmount
# operationId: FixedAmount_Get
export def "fixed-amount Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --EntryDateFrom: string # format: date-time
  --EntryDateTo: string # format: date-time
  --ProjectID: int # (Optional) The ProjectID of a Project to filter Fixed Amounts for (format: int32)
  --TaskID: int # (Optional) The TaskID of a Task to filter Fixed Amounts for (format: int32)
  --isInvoiced: oneof<nothing, bool>
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --Sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc","EntryDate", "EntryDate desc", "StartTimeLocal","StartTimeLocal desc", "TimeSheetEntryID", "TimeSheetEntryID desc"
]: nothing -> record<FixedAmounts: table<Amount: float, DateCreated: string, DateUpdated: string, FixedAmountID: int, InventoryItemIDFK: int, InventoryItemName: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, TaskIDFK: int, TaskTitle: string, UpdatedByUserIDFK: int, isInvoiced: bool>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "EntryDateFrom" $EntryDateFrom "scalar") (serialize-qp "EntryDateTo" $EntryDateTo "scalar") (serialize-qp "ProjectID" $ProjectID "scalar") (serialize-qp "TaskID" $TaskID "scalar") (serialize-qp "isInvoiced" $isInvoiced "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "Sort" $Sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/FixedAmount" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Inventory
#
# GET /api/Inventory
# operationId: Inventory_Get
export def "inventory Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
]: nothing -> record<Inventory: table<CostPrice: float, DateCreated: string, DateUpdated: string, Description: string, InventoryItemID: int, Name: string, SKU: string, SalePrice: float, SaleTaxIDFK: int, isHidden: bool>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Inventory" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets InventoryItem by InventoryItem ID
#
# GET /api/Inventory/{id}
# operationId: Inventory_GetByID
export def "inventory GetByID" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Inventory/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Invoices
#
# GET /api/Invoice
# operationId: Invoice_Get
export def "invoice Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --Sort: string
  --CompanyIDFK: int # format: int32
]: nothing -> record<Invoices: table<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, CustomerPONumber: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, ExchangeRate: float, InvoiceNumber: string, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "Sort" $Sort "scalar") (serialize-qp "CompanyIDFK" $CompanyIDFK "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Invoice" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new draft invoice
#
# POST /api/Invoice
# operationId: Invoice_Post
# --LineItems item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, ProjectIDFK?: int, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
export def "invoice Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --CompanyIDFK: int # If left blank then you must specify Company Name. (format: int32)
  --CompanyName: string # If left blank then you must specify Company ID. Specified Name will be used to match existing customer record. If not matched then it will be used to create a new customer. First Name, Last Name and Email will only be used if it is a new company. If the Company name appears multiple times we will check the email address to find a matching company. If email address doesn't identify a matching company then the invoice creation will be rejected.
  --CurrencyCode: string # Expects ISO Standard 3 character currency code. If left blank the currency will default to account's currency in general setting. For existing companies this field will be ignored and the invoice will use the currency of the customer. For new customers if the currency is not specified then account currency will be used otherwise the specified currency will be used.
  --CustomerPONumber: string # Plain UTF8 text. 100 characters max
  --DateIssued: string # If not specified it will use today's date. The date should be specified as local date. (format: date-time)
  --DueDate: string # It will be auto calculated based on the payment term and issue date. Due Date must be greater than or equal to Issue Date. If the Due Date is specified then Payment Terms will be set to -1 (Custom) (format: date-time)
  --Email: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --ExchangeRate: float # Exchange rate is only valid for invoices in currency other than default account currency. If not specified it will get the market rate based on the Date Issued. (format: double)
  --Firstname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --InvoiceNumber: string # Pass any string. If left blank it will use the next number in the auto incrementing sequence. If an integer is passed then the largest integer will be use as the seed to auto generate the next invoice number in the sequence.
  --InvoiceTemplateIDFK: int # If left blank the account default invoice template will be used. (format: int32)
  --Lastname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --LineItems: list # item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, ProjectIDFK?: int, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
  --Notes: string # Plain UTF8 text. (no HTML). Max 2000 characters
  --PaymentTerms: int #  "If left blank we will set it to customer default. If specified then it must match one of your existing pre configured payment term periods. Your account starts with: (-1 --- Custom, 0 --- Upon Receipt, 7 --- 7 Days, 15 --- 15 Days, 30 --- 30 Days, 45 --- 45 Days, 60 --- 60 Days) (format: int32)
  --Subject: string # Plain UTF8 text. (no HTML). 255 characters max
  --TransactionPrefix: string # A prefix for the Invoice number. e.g. 'INV'. If left blank it will be set to the account default. Max length 20 characters.
  --TransactionTaxConfigCode: string # Possible values are (EX --- Tax Exclusive, INC --- Tax Inclusive). If left empty it will use the account default.
]: any -> record<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, CustomerPONumber: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, ExchangeRate: float, InvoiceNumber: string, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, TaxNumber: string>, LineItems: table<Amount: float, Description: string, Discount: float, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, TransactionLineItemID: int, UnitPrice: float>, Links: record<ClientView: string, Edit: string, View: string>, Notes: string, Recipient: record<CompanyIDFK: int, CompanyName: string, RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Invoice")
  let body = {CompanyIDFK: $CompanyIDFK, CompanyName: $CompanyName, CurrencyCode: $CurrencyCode, CustomerPONumber: $CustomerPONumber, DateIssued: $DateIssued, DueDate: $DueDate, Email: $Email, ExchangeRate: $ExchangeRate, Firstname: $Firstname, InvoiceNumber: $InvoiceNumber, InvoiceTemplateIDFK: $InvoiceTemplateIDFK, Lastname: $Lastname, LineItems: $LineItems, Notes: $Notes, PaymentTerms: $PaymentTerms, Subject: $Subject, TransactionPrefix: $TransactionPrefix, TransactionTaxConfigCode: $TransactionTaxConfigCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets Invoice by Invoice ID
#
# GET /api/Invoice/{id}
# operationId: Invoice_GetByID
export def "invoice GetByID" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Invoice/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Payments
#
# GET /api/Payment
# operationId: Payment_Get
export def "payment Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
]: nothing -> record<PageNumber: int, PageSize: int, Payments: table<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: list, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Payment" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new Payment and optionally assign payment allocations to Invoices
#
# POST /api/Payment
# operationId: Payment_Post
# --PaymentAllocations item shape: {AllocationAmount?: float, AllocationDate?: string, InvoiceTransactionIDFK?: int}
export def "payment Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Amount: float # format: double
  --CustomerIDFK: int # Only required if no invoice allocations specified. (format: int32)
  --DateIssued: string # Date of Payment. If not specified, assumes today. (format: date-time)
  --ExchangeRate: float # Optional. Only used when the Customer's currecy is different from the Avaza account's base currency. Specifies the exchange rate that should apply between the customer currency and base currency. If not provided we will obtain an up to date exchange rate for the Payment Issue Date. (format: double)
  --Notes: string
  --PaymentAllocations: list # List of amounts within this payment that are allocated to invoices. The sum of these be less than or equal to the payment amount. — item shape: {AllocationAmount?: float, AllocationDate?: string, InvoiceTransactionIDFK?: int}
  --PaymentNumber: string # Optional. If not specified will be automatically generated
  --PaymentProviderCode: string # Optional for storing the payment provider who was the source of funds.
  --TransactionPrefix: string # Optional to override the default prefix added to Payment Numbers
  --TransactionReference: string # Optional for storing the reference # of the payment method.
]: any -> record<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, InvoiceTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Payment")
  let body = {Amount: $Amount, CustomerIDFK: $CustomerIDFK, DateIssued: $DateIssued, ExchangeRate: $ExchangeRate, Notes: $Notes, PaymentAllocations: $PaymentAllocations, PaymentNumber: $PaymentNumber, PaymentProviderCode: $PaymentProviderCode, TransactionPrefix: $TransactionPrefix, TransactionReference: $TransactionReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets Payment by Payment Transaction ID
#
# GET /api/Payment/{id}
# operationId: Payment_GetByID
export def "payment GetByID" [
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
]: nothing -> record<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, InvoiceTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Payment/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Projects
#
# GET /api/Project
# operationId: Project_Get
export def "project Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # Only show project records updated after a certain date (UTC) (format: date-time)
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --Sort: string # A column to sort on. Current possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc"
  --TimesheetUserID: int # Filter to the projects that the supplied UserID can add timesheets to (format: int32)
  --includeArchived: oneof<nothing, bool> # Include Archived Projects in the results
]: nothing -> record<PageNumber: int, PageSize: int, Projects: table<CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, Notes: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectID: int, ProjectOwnerUserIDFK: int, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "Sort" $Sort "scalar") (serialize-qp "TimesheetUserID" $TimesheetUserID "scalar") (serialize-qp "includeArchived" $includeArchived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Project" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Project
#
# POST /api/Project
# operationId: Project_Post
export def "project Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --BudgetAmount: float # format: double
  --BudgetHours: float # format: double
  --CompanyIDFK: int # An ID of a company in Avaza to create the Project under. You must provide either a CompanyID, or a CompanyName (format: int32)
  --CompanyName: string # The name for a Company to create the project under. Will create company unless it matches an existing company name
  --CurrencyCode: string # The ISO 3 letter currency code to use when creating a new Company. If not provided, the account's default currency will be used.
  --EndDate: string # format: date-time
  --PopulateDefaultProjectMembers: oneof<nothing, bool> # Defaults to true.
  --ProjectCategoryIDFK: int # format: int32
  --ProjectCode: string # Used when Manual Project Codes are enabled
  --ProjectNotes: string # Any descriptive notes about the project. (2000 characters max)
  --ProjectStatusCode: string
  ProjectTitle: string # The title of the new project. (255 characters max)
  --StartDate: string # format: date-time
  --TimesheetApprovalRequiredbyDefault: oneof<nothing, bool>
  --isTaskRequiredOnTimesheet: oneof<nothing, bool>
]: any -> record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Project")
  let body = {BudgetAmount: $BudgetAmount, BudgetHours: $BudgetHours, CompanyIDFK: $CompanyIDFK, CompanyName: $CompanyName, CurrencyCode: $CurrencyCode, EndDate: $EndDate, PopulateDefaultProjectMembers: $PopulateDefaultProjectMembers, ProjectCategoryIDFK: $ProjectCategoryIDFK, ProjectCode: $ProjectCode, ProjectNotes: $ProjectNotes, ProjectStatusCode: $ProjectStatusCode, ProjectTitle: $ProjectTitle, StartDate: $StartDate, TimesheetApprovalRequiredbyDefault: $TimesheetApprovalRequiredbyDefault, isTaskRequiredOnTimesheet: $isTaskRequiredOnTimesheet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an Project
#
# PUT /api/Project
# operationId: Project_Put
export def "project Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --BudgetAmount: float # format: double
  --BudgetHours: float # format: double
  --EndDate: string # format: date-time
  --FieldsToUpdate: list
  --ProjectBillableTypeCode: string # The billing method of the project. (string, optional) Possible values: CategoryHourly, NoRate, NotBillable, PersonHourly, ProjectHourly
  --ProjectBudgetTypeCode: string # The project budgeting type. (string, optional) Possible values: NoBudget, PersonHours, ProjectFees, ProjectHours, CategoryHours
  --ProjectCategoryIDFK: int # format: int32
  --ProjectID: int # The ID of the Project to update (format: int32)
  --ProjectNotes: string # (optional) Any descriptive notes about the project. (2000 characters max)
  --ProjectStatusCode: string # Update the project status (string, optional): (Possible values: NotStarted, InProgress, Complete, OnHold)
  --ProjectTitle: string # (optional) An updated project title. (255 characters max)
  --StartDate: string # format: date-time
  --TimesheetApprovalRequiredbyDefault: oneof<nothing, bool> # Whether timesheet approval should be required by default for newly added project members.
  --isTaskRequiredOnTimesheet: oneof<nothing, bool> # Whether timesheets entered against this project require a task to be selected.
]: any -> record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Project")
  let body = {BudgetAmount: $BudgetAmount, BudgetHours: $BudgetHours, EndDate: $EndDate, FieldsToUpdate: $FieldsToUpdate, ProjectBillableTypeCode: $ProjectBillableTypeCode, ProjectBudgetTypeCode: $ProjectBudgetTypeCode, ProjectCategoryIDFK: $ProjectCategoryIDFK, ProjectID: $ProjectID, ProjectNotes: $ProjectNotes, ProjectStatusCode: $ProjectStatusCode, ProjectTitle: $ProjectTitle, StartDate: $StartDate, TimesheetApprovalRequiredbyDefault: $TimesheetApprovalRequiredbyDefault, isTaskRequiredOnTimesheet: $isTaskRequiredOnTimesheet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets minimal list of active Projects for the current user
#
# GET /api/Project/Lookup
# operationId: ProjectLookup
export def "project-lookup ProjectLookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --TimesheetUserID: int # Optionally Filter to the projects that the supplied UserID can add timesheets to (format: int32)
  --CompanyIDFK: int # Optionally Filter for a specific Company ID (format: int32)
  --search: string # Search string to match against Project title and Customer name
]: nothing -> record<PageSize: int, companies: table<CompanyID: int, CompanyName: string, projects: list>, hasMore: bool, pageNumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "TimesheetUserID" $TimesheetUserID "scalar") (serialize-qp "CompanyIDFK" $CompanyIDFK "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Project/Lookup" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Project by Project ID
#
# GET /api/Project/{id}
# operationId: Project_GetByID
export def "project GetByID" [
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
]: nothing -> record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Project/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Project Members
#
# GET /api/ProjectMember
# operationId: ProjectMember_Get
export def "project-member Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ProjectID: int # Get Project members filtered by ProjectID (format: int32)
  --UserID: int # Get Project members filtered by UserID (format: int32)
]: nothing -> record<ProjectMembers: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ProjectID" $ProjectID "scalar") (serialize-qp "UserID" $UserID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ProjectMember" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign a user as a Member of a Project
#
# POST /api/ProjectMember
# operationId: ProjectMember_Post
export def "project-member Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --BudgetAmount: float # Optional (format: double)
  --CostAmount: float # Optional. If not provided, defaults to the User's default Cost Amount. (format: double)
  --ProjectIDFK: int # Required. The ProjectID (format: int32)
  --RateAmount: float # Optional. If not provided, defaults to the User's default Rate Amount. (format: double)
  --UserIDFK: int # Required. The UserID to assign (format: int32)
  --canCommentOnTasks: oneof<nothing, bool>
  --canCreateTasks: oneof<nothing, bool>
  --canDeleteTasks: oneof<nothing, bool>
  --canUpdateTasks: oneof<nothing, bool>
  --isProjectManager: oneof<nothing, bool>
  --isTimesheetAllowed: oneof<nothing, bool>
  --isTimesheetApprovalRequired: oneof<nothing, bool>
  --isTimesheetApprover: oneof<nothing, bool>
]: any -> record<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ProjectMember")
  let body = {BudgetAmount: $BudgetAmount, CostAmount: $CostAmount, ProjectIDFK: $ProjectIDFK, RateAmount: $RateAmount, UserIDFK: $UserIDFK, canCommentOnTasks: $canCommentOnTasks, canCreateTasks: $canCreateTasks, canDeleteTasks: $canDeleteTasks, canUpdateTasks: $canUpdateTasks, isProjectManager: $isProjectManager, isTimesheetAllowed: $isTimesheetAllowed, isTimesheetApprovalRequired: $isTimesheetApprovalRequired, isTimesheetApprover: $isTimesheetApprover} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a Member of a Project
#
# PUT /api/ProjectMember
# operationId: ProjectMember_Put
export def "project-member Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --BudgetAmount: float # A new Budget Amount. Defaults to null. (format: double)
  --CostAmount: float # A new Cost Amount. Defaults to null. (format: double)
  FieldsToUpdate: list # A string array of field names to be updated.
  ProjectIDFK: int # Required. The ProjectID (format: int32)
  --RateAmount: float # A new Rate Amount. Defaults to null. (format: double)
  UserIDFK: int # Required. The UserID (format: int32)
  --canCommentOnTasks: oneof<nothing, bool>
  --canCreateTasks: oneof<nothing, bool>
  --canDeleteTasks: oneof<nothing, bool>
  --canUpdateTasks: oneof<nothing, bool>
  --isProjectManager: oneof<nothing, bool>
  --isTimesheetAllowed: oneof<nothing, bool>
  --isTimesheetApprovalRequired: oneof<nothing, bool>
  --isTimesheetApprover: oneof<nothing, bool>
]: any -> record<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ProjectMember")
  let body = {BudgetAmount: $BudgetAmount, CostAmount: $CostAmount, FieldsToUpdate: $FieldsToUpdate, ProjectIDFK: $ProjectIDFK, RateAmount: $RateAmount, UserIDFK: $UserIDFK, canCommentOnTasks: $canCommentOnTasks, canCreateTasks: $canCreateTasks, canDeleteTasks: $canDeleteTasks, canUpdateTasks: $canUpdateTasks, isProjectManager: $isProjectManager, isTimesheetAllowed: $isTimesheetAllowed, isTimesheetApprovalRequired: $isTimesheetApprovalRequired, isTimesheetApprover: $isTimesheetApprover} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets list of Project Timesheet Categories
#
# GET /api/ProjectTimesheetCategory
# operationId: ProjectTimesheetCategory_Get
export def "project-timesheet-category Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ProjectID: int # Get categories filtered by ProjectID (format: int32)
]: nothing -> record<Categories: table<AccountIDFK: int, BudgetHours: float, CostAmount: float, Name: string, ProjectIDFK: int, RateAmount: float, TimeSheetCategoryIDFK: int, isBillable: bool, isDisabled: bool, isPayable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ProjectID" $ProjectID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ProjectTimesheetCategory" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign a TimeSheetCategory to a Project.
#
# POST /api/ProjectTimesheetCategory
# operationId: ProjectTimesheetCategory_Post
export def "project-timesheet-category Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --BudgetHours: float # format: double
  --CostAmount: float # format: double
  --ProjectIDFK: int # format: int32
  --RateAmount: float # format: double
  --TimesheetCategoryIDFK: int # format: int32
  --isBillable: oneof<nothing, bool>
  --isPayable: oneof<nothing, bool>
]: any -> record<AccountIDFK: int, BudgetHours: float, CostAmount: float, Name: string, ProjectIDFK: int, RateAmount: float, TimeSheetCategoryIDFK: int, isBillable: bool, isDisabled: bool, isPayable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ProjectTimesheetCategory")
  let body = {BudgetHours: $BudgetHours, CostAmount: $CostAmount, ProjectIDFK: $ProjectIDFK, RateAmount: $RateAmount, TimesheetCategoryIDFK: $TimesheetCategoryIDFK, isBillable: $isBillable, isPayable: $isPayable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets list of Schedule Assignments.
#
# GET /api/ScheduleAssignment
# operationId: ScheduleAssignment_Get
export def "schedule-assignment Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # Limit results to records updated after the specified date (format: date-time)
  --ScheduleDateFrom: string # Filter for schedule assignement  that are  on or after a specific date (format: date-time)
  --ScheduleDateTo: string # Filter for schedules that are on or before a specific date (format: date-time)
  --ScheduleSeriesID: int # Filter to records for a particular Schedule Series (format: int64)
  --UserID: int # The UserID of a schedule user to filter assignments for. Only api users with Admin role can see all schedules across all users. Users with ScheduleUser role can access their own ScheduleSeries. (format: int32)
  --UserEmail: string # The email of the user who has been scheduled
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --Sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc"
]: nothing -> record<PageNumber: int, PageSize: int, ScheduleAssignments: table<AccountIDFK: int, DateCreated: string, DateUpdated: string, Duration: float, ScheduleAssignmentID: int, ScheduleDate: string, ScheduleSeriesIDFK: int, UserIDFK: int>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "ScheduleDateFrom" $ScheduleDateFrom "scalar") (serialize-qp "ScheduleDateTo" $ScheduleDateTo "scalar") (serialize-qp "ScheduleSeriesID" $ScheduleSeriesID "scalar") (serialize-qp "UserID" $UserID "scalar") (serialize-qp "UserEmail" $UserEmail "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "Sort" $Sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ScheduleAssignment" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Schedule Series
#
# GET /api/ScheduleSeries
# operationId: ScheduleSeries_Get
export def "schedule-series Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # Limit results to records updated after the specified date (format: date-time)
  --ScheduleStartDateFrom: string # Filter for schedules that start on or after a specific date (format: date-time)
  --ScheduleStartDateTo: string # Filter for schedules that start on or before a specific date (format: date-time)
  --ScheduleEndDateFrom: string # Filter for schedules that end on or after a specific date (format: date-time)
  --ScheduleEndDateTo: string # Filter for schedules that end on or before a specific date (format: date-time)
  --UserID: int # The UserID of a schedule user to filter assignments for. Only api users with Admin role can see all schedules across all users. Users with ScheduleUser role can access their own ScheduleSeries. (format: int32)
  --UserEmail: string # The email of the user who has been scheduled
  --TimeSheetCategoryID: int # Filter for schedule records linked to a specific timesheeet category (format: int32)
  --TimeSheetCategoryName: string # Filter for schedule records with a specific timesheeet category name (exact string match)
  --LeaveTypeID: int # Filter to records of a particular leave type (format: int32)
  --ProjectID: int # Filter to only include books linked to a specific project (format: int32)
  --CompanyID: int # Filter to only include records linked to projects, where that project belongs to a specific customer company (format: int32)
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --Sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc"
]: nothing -> record<PageNumber: int, PageSize: int, ScheduleSeries: table<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "ScheduleStartDateFrom" $ScheduleStartDateFrom "scalar") (serialize-qp "ScheduleStartDateTo" $ScheduleStartDateTo "scalar") (serialize-qp "ScheduleEndDateFrom" $ScheduleEndDateFrom "scalar") (serialize-qp "ScheduleEndDateTo" $ScheduleEndDateTo "scalar") (serialize-qp "UserID" $UserID "scalar") (serialize-qp "UserEmail" $UserEmail "scalar") (serialize-qp "TimeSheetCategoryID" $TimeSheetCategoryID "scalar") (serialize-qp "TimeSheetCategoryName" $TimeSheetCategoryName "scalar") (serialize-qp "LeaveTypeID" $LeaveTypeID "scalar") (serialize-qp "ProjectID" $ProjectID "scalar") (serialize-qp "CompanyID" $CompanyID "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "Sort" $Sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ScheduleSeries" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Section
#
# DELETE /api/Section
# operationId: Section_Delete
export def "section Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --SectionID: int # format: int64
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SectionID" $SectionID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Section" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Sections
#
# GET /api/Section
# operationId: Section_Get
export def "section Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ProjectID: int # Get sections for Project with ProjectID (format: int32)
]: nothing -> record<Sections: table<DisplayOrder: int, EndDate: string, EndDateUTC: string, ProjectIDFK: int, SectionID: int, StartDate: string, StartDateUTC: string, Title: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ProjectID" $ProjectID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Section" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Section
#
# POST /api/Section
# operationId: Section_Post
export def "section Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --EndDateUTC: string # format: date-time
  --ProjectIDFK: int # format: int32
  --StartDateUTC: string # format: date-time
  --Title: string
]: any -> record<DisplayOrder: int, EndDate: string, EndDateUTC: string, ProjectIDFK: int, SectionID: int, StartDate: string, StartDateUTC: string, Title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Section")
  let body = {EndDateUTC: $EndDateUTC, ProjectIDFK: $ProjectIDFK, StartDateUTC: $StartDateUTC, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Task
#
# DELETE /api/Task
# operationId: Task_Delete
export def "task Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --TaskID: int # format: int64
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TaskID" $TaskID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Task" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Tasks
#
# GET /api/Task
# operationId: Task_Get
export def "task Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # Optional filter to records updated after a specific date. (format: date-time)
  --pageSize: int # Number of items per page. Defaults to 20. (format: int32)
  --pageNumber: int # Page to display. Starts from 1. Defaults to 1 (format: int32)
  --Sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc", "SectionTitle", "Title"
  --isComplete: oneof<nothing, bool> # Optional filter to only display tasks linked to a Task Status where isComplete=false, or where isComplete=true
  --ProjectID: int # Optional filter to only display tasks belonging to a specific ProjectID (format: int32)
]: nothing -> record<PageNumber: int, PageSize: int, Tasks: table<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: list, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: list, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "Sort" $Sort "scalar") (serialize-qp "isComplete" $isComplete "scalar") (serialize-qp "ProjectID" $ProjectID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Task" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Task
#
# POST /api/Task
# operationId: Task_Post
# --Tags item shape: {Color?: string, Name?: string}
export def "task Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --AccountTaskTypeIDFK: int # format: int32
  --AssignedToUserIDFKs: list
  --DateDue: string # format: date-time
  --DateStart: string # format: date-time
  --Description: string
  --EstimatedEffort: float # Decimal hours (format: double)
  ProjectIDFK: int # format: int32
  SectionIDFK: int # format: int32
  --Tags: list # Collection of tags specifying Name and Color (Hex) — item shape: {Color?: string, Name?: string}
  --TaskPriorityCode: string
  Title: string
]: any -> record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Task")
  let body = {AccountTaskTypeIDFK: $AccountTaskTypeIDFK, AssignedToUserIDFKs: $AssignedToUserIDFKs, DateDue: $DateDue, DateStart: $DateStart, Description: $Description, EstimatedEffort: $EstimatedEffort, ProjectIDFK: $ProjectIDFK, SectionIDFK: $SectionIDFK, Tags: $Tags, TaskPriorityCode: $TaskPriorityCode, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a Task.
#
# PUT /api/Task
# operationId: Task_Put
# --Tags item shape: {Color?: string, Name?: string}
export def "task Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --AssignedToUserIDFK: list
  --DateDue: string # format: date-time
  --DateStart: string # format: date-time
  --Description: string
  --EstimatedEffort: float # Decimal hours (format: double)
  FieldsToUpdate: list
  --PercentComplete: int # format: int32
  --SectionIDFK: int # format: int32
  --Tags: list # item shape: {Color?: string, Name?: string}
  TaskID: int # format: int32
  --TaskPriorityCode: string
  --TaskStatusCode: string
  --Title: string
]: any -> record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Task")
  let body = {AssignedToUserIDFK: $AssignedToUserIDFK, DateDue: $DateDue, DateStart: $DateStart, Description: $Description, EstimatedEffort: $EstimatedEffort, FieldsToUpdate: $FieldsToUpdate, PercentComplete: $PercentComplete, SectionIDFK: $SectionIDFK, Tags: $Tags, TaskID: $TaskID, TaskPriorityCode: $TaskPriorityCode, TaskStatusCode: $TaskStatusCode, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets minimal list of Tasks for the current user
#
# GET /api/Task/Lookup
# operationId: TaskLookup
export def "task-lookup TaskLookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --projectID: int # (required) The ProjectID to use when filtering Tasks (format: int32)
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --hideCompleted: oneof<nothing, bool> # (optional) true/false to hide completed tasks. Defaults false
  --search: string # (optional) Search string to match against Task title. Performs begins-with match
]: nothing -> record<PageSize: int, hasMore: bool, pageNumber: int, sections: table<SectionTitle: string, tasks: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectID" $projectID "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "hideCompleted" $hideCompleted "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Task/Lookup" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Task by Task ID
#
# GET /api/Task/{id}
# operationId: Task_GetByID
export def "task GetByID" [
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
]: nothing -> record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Task/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Task Statuses
#
# GET /api/TaskStatus
# operationId: TaskStatus_Get
export def "task-status Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<statuses: table<AccountTaskTypeIDFK: int, Color: string, DisplayOrder: int, Name: string, TaskStatusCode: string, TaskTypeName: string, isComplete: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/TaskStatus")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Task Types
#
# GET /api/TaskType
# operationId: TaskType_Get
export def "task-type Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<tasktypes: table<AccountTaskTypeID: int, Icon: string, IconType: string, Name: string, isDefault: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/TaskType")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get List of Taxes configured in the Avaza account.
#
# GET /api/Tax
# operationId: Tax_Get
export def "tax Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Taxes: table<CalculatedPercent: float, Name: string, TaxCode: string, TaxComponents: list, TaxID: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Tax")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Timsheets
#
# GET /api/Timesheet
# operationId: Timesheet_Get
export def "timesheet Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UpdatedAfter: string # format: date-time
  --EntryDateFrom: string # format: date-time
  --EntryDateTo: string # format: date-time
  --UserID: int # The UserID of a timesheet user to filter timesheets for. Only api users with certain higher roles can see timesheets across multiple users. (format: int32)
  --UserEmail: string
  --CategoryName: string
  --ProjectID: int # format: int32
  --isBillable: oneof<nothing, bool>
  --isInvoiced: oneof<nothing, bool>
  --isTimerRunning: oneof<nothing, bool>
  --pageSize: int # Number of items per page (max 1000) (format: int32)
  --pageNumber: int # Page to display. Starts from 1. (format: int32)
  --includeInvoiceDetails: oneof<nothing, bool> # Defaults to false. When true, the InvoiceIDFK value will be included in the response.
  --Sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc","EntryDate", "EntryDate desc", "StartTimeLocal","StartTimeLocal desc", "TimeSheetEntryID", "TimeSheetEntryID desc"
]: nothing -> record<PageNumber: int, PageSize: int, Timesheets: table<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $UpdatedAfter "scalar") (serialize-qp "EntryDateFrom" $EntryDateFrom "scalar") (serialize-qp "EntryDateTo" $EntryDateTo "scalar") (serialize-qp "UserID" $UserID "scalar") (serialize-qp "UserEmail" $UserEmail "scalar") (serialize-qp "CategoryName" $CategoryName "scalar") (serialize-qp "ProjectID" $ProjectID "scalar") (serialize-qp "isBillable" $isBillable "scalar") (serialize-qp "isInvoiced" $isInvoiced "scalar") (serialize-qp "isTimerRunning" $isTimerRunning "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "includeInvoiceDetails" $includeInvoiceDetails "scalar") (serialize-qp "Sort" $Sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Timesheet" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Timesheet Entry
#
# POST /api/Timesheet
# operationId: Timesheet_Post
export def "timesheet Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --CustomMetadata: string # Optional. free nvarchar field available via Api to store any additional metadata against a timesheet. We suggest you use Json or your preferred serialisation format. 1000 characters max.
  --Duration: float # The duration of the timesheet, in decimal hours. If null or 0, a timer will be started. (format: double)
  --EntryDate: string # The date of the timesheet entry, with an optional start time component. (format: date-time)
  --Notes: string # Timesheet Notes
  --ProjectIDFK: int # The project to associate the timesheet with. (format: int32)
  --TaskIDFK: int # Optional. Link the timesheet to a specific task (format: int32)
  --TimesheetCategoryIDFK: int # The Project timesheet category to link the timesheet to (format: int32)
  --UserIDFK: int # UserID for a Timesheet user in Avaza (format: int32)
  --hasStartEndTime: oneof<nothing, bool> # If true, the start time will be take from the time component of the Entry Date field, and the end time will be calculated by adding the Duration to the StartDate
  --isInvoiced: oneof<nothing, bool> # Optional. False by default. Allows you to mark the timesheet as invoiced in an external system.
]: any -> record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Timesheet")
  let body = {CustomMetadata: $CustomMetadata, Duration: $Duration, EntryDate: $EntryDate, Notes: $Notes, ProjectIDFK: $ProjectIDFK, TaskIDFK: $TaskIDFK, TimesheetCategoryIDFK: $TimesheetCategoryIDFK, UserIDFK: $UserIDFK, hasStartEndTime: $hasStartEndTime, isInvoiced: $isInvoiced} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a Timesheet
#
# PUT /api/Timesheet
# operationId: Timesheet_Put
export def "timesheet Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --CustomMetadata: string # Optional. free nvarchar field available via Api to store any additional metadata against a timesheet. We suggest you use Json or your preferred serialisation format. 1000 characters max.
  --Duration: float # format: double
  --EntryDate: string # format: date-time
  FieldsToUpdate: list
  --Notes: string
  ProjectIDFK: int # format: int32
  --TaskIDFK: int # format: int32
  TimeSheetEntryID: int # format: int64
  --TimesheetCategoryIDFK: int # format: int32
  --hasStartEndTime: oneof<nothing, bool>
]: any -> record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Timesheet")
  let body = {CustomMetadata: $CustomMetadata, Duration: $Duration, EntryDate: $EntryDate, FieldsToUpdate: $FieldsToUpdate, Notes: $Notes, ProjectIDFK: $ProjectIDFK, TaskIDFK: $TaskIDFK, TimeSheetEntryID: $TimeSheetEntryID, TimesheetCategoryIDFK: $TimesheetCategoryIDFK, hasStartEndTime: $hasStartEndTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Timesheet Entry
#
# DELETE /api/Timesheet/{id}
# operationId: Timesheet_Delete
export def "timesheet Delete" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Timesheet/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a Timesheet Entry by Timesheet ID
#
# GET /api/Timesheet/{id}
# operationId: Timesheet_GetByID
export def "timesheet GetByID" [
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
]: nothing -> record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Timesheet/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit Timesheets for Approval.
#
# POST /api/TimesheetSubmission
# operationId: TimesheetSubmission_Post
export def "timesheet-submission Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --SendNotifications: oneof<nothing, bool> # Send email alerts to timesheet approvers. Defaults to true
  --WholeWeekOf: string # A date (yyyy-MM-dd) that falls within  a Week to have all timesheets in that week submitted. Respects the First Day of Week setting in your account Timesheet Settings to determine the week range. (format: date-time)
  --WholeDayOf: string # A date (yyyy-MM-dd) to submit all timesheets on this day (format: date-time)
  --UserID: int # The user to submit timesheets for. Defaults to current user. Only allowed to be different from the current user when the current user has rights to Impersonate other users. (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SendNotifications" $SendNotifications "scalar") (serialize-qp "WholeWeekOf" $WholeWeekOf "scalar") (serialize-qp "WholeDayOf" $WholeDayOf "scalar") (serialize-qp "UserID" $UserID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/TimesheetSubmission" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Basic Summary of Timesheet Statistics
#
# GET /api/TimesheetSummary
# operationId: TimesheetSummary_Get
export def "timesheet-summary Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --modelgroupBy: list # (Optional) Combine one, two or three levels of Grouping. Combine these possible grouping values: "Customer", "Project", "Category", "User", "Task", "Year", "Month", "Day", "Week".
  --modelentryDateFrom: string # (Required) Filter for timesheets greater or equal to the specified date. e.g. 2019-01-25. You can optionally include a time component, otherwise it assumes 00:00 (format: date-time)
  --modelentryDateTo: string # (Required) Filter for timesheets with an entry date smaller or equal to the specified  date. e.g. 2019-01-25. You can optionally include a time component, otherwise it assumes 00:00 (format: date-time)
  --modeluserID: list # (Optional) Defaults to the current user. Provide one or more UserIDs of Users whose timesheets should be retrieved. If the current user doesn't have impersonation rights, then they will only see their own data.
  --modelprojectID: int # (Optional) Filter by Project (format: int32)
  --modelisBillable: oneof<nothing, bool> # (Optional) Filter by the billable status of Timesheets.
  --modelisInvoiced: oneof<nothing, bool> # (Optional) Filter for timesheets by whether they have been Invoiced or not.
]: nothing -> record<BillableHours: float, EntryDateFrom: string, EntryDateTo: string, GroupData: table<BillableHours: float, GroupData: list, GroupID: string, GroupName: string, TotalHours: float>, GroupingLevels: list<string>, TotalHours: float, UserID: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model.groupBy" $modelgroupBy "multi") (serialize-qp "model.entryDateFrom" $modelentryDateFrom "scalar") (serialize-qp "model.entryDateTo" $modelentryDateTo "scalar") (serialize-qp "model.userID" $modeluserID "multi") (serialize-qp "model.projectID" $modelprojectID "scalar") (serialize-qp "model.isBillable" $modelisBillable "scalar") (serialize-qp "model.isInvoiced" $modelisInvoiced "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/TimesheetSummary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the  Running Timer if there is one for a user.
#
# GET /api/TimesheetTimer
# operationId: TimesheetTimer_GetRunningTimer
export def "timesheet-timer GetRunningTimer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --UserID: int # Optional - User ID number if impersonating a different user. Otherwise assumes the current user. Only users with certain security roles have permission to impersonate other users (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserID" $UserID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/TimesheetTimer" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop the timer running on an existing Timesheet Entry
#
# DELETE /api/TimesheetTimer/{id}
# operationId: TimesheetTimer_StopTimer
export def "timesheet-timer StopTimer" [
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
  --UserID: int # Optional - User ID number if impersonating a different user. Otherwise assumes the current user. Only users with certain security roles have permission to impersonate other users (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserID" $UserID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/TimesheetTimer/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Starts a Timer running on an existing Timesheet Entry
#
# POST /api/TimesheetTimer/{id}
# operationId: TimesheetTimer_StartTimer
export def "timesheet-timer StartTimer" [
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
  --UserID: int # Optional - User ID number if impersonating a different user. Otherwise assumes the current user. Only users with certain security roles have permission to impersonate other users (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserID" $UserID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/TimesheetTimer/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Collection of Users who have roles in the current Avaza account.
#
# GET /api/UserProfile
# operationId: UserProfile_Get
export def "user-profile Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Roles: string # Optional list of comma separated role codes to filter users by (e.g. "TimesheetUser,Admin")
  --Tags: string
  --CurrentUserOnly: oneof<nothing, bool> # Optional boolean (true/false) to filter to only show current authenticated user (always true for non Admin/InvoiceManager users)
  --CompanyIDFK: int # Optionally filter by Company ID (format: int32)
]: nothing -> record<Users: table<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DefaultBillableRate: float, DefaultCostRate: float, Email: string, Firstname: string, FridayAvailableHours: float, IANATimezone: string, Lastname: string, Mobile: string, MondayAvailableHours: float, Phone: string, PositionTitle: string, Roles: list, SaturdayAvailableHours: float, SundayAvailableHours: float, Tags: list, ThursdayAvailableHours: float, TimeZone: string, TuesdayAvailableHours: float, UserID: int, WednesdayAvailableHours: float, isTeamMember: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Roles" $Roles "scalar") (serialize-qp "Tags" $Tags "scalar") (serialize-qp "CurrentUserOnly" $CurrentUserOnly "scalar") (serialize-qp "CompanyIDFK" $CompanyIDFK "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/UserProfile" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete webhook subscription by URL
#
# DELETE /api/Webhook
# operationId: Webhook_DeleteByUrl
export def "webhook DeleteByUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --target-url: string # Target URL that should be used to delete subscriptions
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target_url" $target_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Webhook" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of Webhook Subscriptions
#
# GET /api/Webhook
# operationId: Webhook_Get
export def "webhook Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Webhooks: table<EventCode: string, NotificationURL: string, SubscriptionID: int, UserIDFK: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Webhook")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to Webhook. On success, returns ID of webhook subscription.
#
# POST /api/Webhook
# operationId: Webhook_Post
export def "webhook Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  event: string # The event code to be notified about. Possible values: company_created, contact_created, invoice_created, invoice_sent, project_created, task_created
  --secret: string # Optional Secret string (255 char max). If provided, the secret will be BASE 64 encoded and used as a basic authentication http header with webhook notifications. i.e. Authorization Basic [BASE64 of Secret]"
  target_url: string # The URL that should be notified of the event.
]: any -> record<ID: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Webhook")
  let body = {event: $event, secret: $secret, target_url: $target_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Webhook Subscription by ID
#
# DELETE /api/Webhook/{id}
# operationId: Webhook_Delete
export def "webhook Delete" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Webhook/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Webhook Subscription by SubscriptionID
#
# GET /api/Webhook/{id}
# operationId: Webhook_GetByID
export def "webhook GetByID" [
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
]: nothing -> record<Webhooks: table<EventCode: string, NotificationURL: string, SubscriptionID: int, UserIDFK: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/Webhook/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
