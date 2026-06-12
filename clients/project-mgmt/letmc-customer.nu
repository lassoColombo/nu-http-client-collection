# Auto-generated client for agentOS Api V2, Customer Login Call Group vv2-customer
# Source: https://api.apis.guru/v2/specs/letmc.com/customer/v2-customer/openapi.json
# Auth: --token flag or $env.AGENTOS_API_V2_CUSTOMER_LOGIN_CALL_GROUP_TOKEN

const BASE_URL = "https://live-api.letmc.com"
const DEFAULT_AUTH = "apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AGENTOS_API_V2_CUSTOMER_LOGIN_CALL_GROUP_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "apikey" => { {headers: {ApiKey: $token_val}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://live-api.letmc.com"] }
def auth-scheme-completer [] { ["apikey" "basic"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "customer-branch-branches GetBranches" } } | get name | first)
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

# All branches defined for a company
#
# GET /v2/customer/{shortName}/branch/branches
# operationId: BranchController_GetBranches
export def "customer-branch-branches GetBranches" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/branch/branches" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific branch given its unique Object ID (OID)
#
# GET /v2/customer/{shortName}/branch/branches/{branchID}
export def "customer-branch-branches get" [
  shortName: string
  branchID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/customer/($shortName)/branch/branches/($branchID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the accounting details for the landlord.
#
# GET /v2/customer/{shortName}/landlord/accounting
# operationId: LandlordController_GetAccounts
export def "customer-landlord-accounting GetAccounts" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --qp-token: string # The login token returned from the /session POST call
]: nothing -> record<AccountBalance: float, LastPayment: string, PaymentHistory: table<Amount: float, Date: string, Description: string, TransactionNumber: int>, Statements: table<Date: string, InvoiceID: string, IsMaintenanceInvoice: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/accounting" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a Document
#
# GET /v2/customer/{shortName}/landlord/document
# operationId: LandlordController_GetDocument
export def "customer-landlord-document GetDocument" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # The login token returned from the /session POST call
  --ID: string # The Document ID
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "ID" $ID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/document" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a Inventory PDF for a tenancy
#
# GET /v2/customer/{shortName}/landlord/inventory
# operationId: LandlordController_GetInvetoryReport
export def "customer-landlord-inventory GetInvetoryReport" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # The login token returned from the /session POST call
  --tenancyID: string # The Tenancy ID
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "tenancyID" $tenancyID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/inventory" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an invoice pdf belonging to the landlord.
#
# GET /v2/customer/{shortName}/landlord/invoice
# operationId: LandlordController_GetInvoice
export def "customer-landlord-invoice GetInvoice" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # The login token returned from the /session POST call
  --invoiceID: string # The invoice ID to load.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "invoiceID" $invoiceID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/invoice" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve landlord's CRM ID
#
# GET /v2/customer/{shortName}/landlord/landlordcrmentries
# operationId: LandlordController_GetLandlordCrmEntries
export def "customer-landlord-landlordcrmentries GetLandlordCrmEntries" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # The login token returned from the /session POST call
]: nothing -> table<BranchID: string, GlobalReference: string, Name: string, OID: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/landlordcrmentries" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Active maintenance jobs.
#
# GET /v2/customer/{shortName}/landlord/maintenance
# operationId: LandlordController_GetMaintenanceJobs
export def "customer-landlord-maintenance GetMaintenanceJobs" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --qp-token: string # The login token returned from the /session POST call
]: nothing -> record<Jobs: table<AssignedTo: string, ClosedDate: string, Description: string, MaintenanceNotes: list, Property: string, Reported: string, Status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/maintenance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a Profit and Loss Report
#
# GET /v2/customer/{shortName}/landlord/profitloss
# operationId: LandlordController_GetProfitLossReport
export def "customer-landlord-profitloss GetProfitLossReport" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --qp-token: string # The login token returned from the /session POST call
]: nothing -> record<DirectCosts: record<Rows: list<record>>, GrossProfitLoss: record<Rows: list<record>>, Income: record<Rows: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/profitloss" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rent Arrears
#
# GET /v2/customer/{shortName}/landlord/rentarrears
# operationId: LandlordController_GetRentArrears
export def "customer-landlord-rentarrears GetRentArrears" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --qp-token: string # The login token returned from the /session POST call
]: nothing -> record<ChaseNotes: table<Date: string, Note: string, NoteType: string, TenantID: string>, RentCollected: float, RentOutstanding: table<DebtDays: int, OutstandingRent: float, Property: string, Tenant: string, TenantID: string>, TotalRentArrears: float> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/rentarrears" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a Self Assessment Tax Report
#
# GET /v2/customer/{shortName}/landlord/sas
# operationId: LandlordController_GetSASReport
export def "customer-landlord-sas GetSASReport" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # The login token returned from the /session POST call
  --yearEnd: int # The Tax Year End. (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "yearEnd" $yearEnd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/sas" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contact details of all linked landlords.
#
# GET /v2/customer/{shortName}/landlord/settings
# operationId: LandlordController_GetSettings
export def "customer-landlord-settings GetSettings" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --qp-token: string # The login token returned from the /session POST call
]: nothing -> record<LinkedAccounts: table<Address: string, Email: string, GlobalReference: string, ID: string, Mobile: string, Name: string, Phone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/settings" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the summary details for the landlord.
#
# GET /v2/customer/{shortName}/landlord/summary
# operationId: LandlordController_GetSummaryDetails
export def "customer-landlord-summary GetSummaryDetails" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --qp-token: string # The login token returned from the /session POST call
]: nothing -> record<AccountBalance: float, LastPayment: string, Tenancies: table<Bond: float, BranchID: string, Description: string, GlobalReference: string, ID: string, MaintenanceJobs: int, ManagedRent: bool, PropertyAddress: string, Rent: string, RentArrears: float, RentCollected: float, TenancyProperty: string, TenancyState: string>, TotalRentArrears: float> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/summary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tenancy details.
#
# GET /v2/customer/{shortName}/landlord/tenancy
# operationId: LandlordController_GetTenancy
export def "customer-landlord-tenancy GetTenancy" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --qp-token: string # The login token returned from the /session POST call
  --tenancyID: string # The Tenancy ID
]: nothing -> record<ActualEndDate: string, Beds: int, Bond: float, BranchID: string, Certificates: table<Due: string, Files: list, Status: string, Type: string>, Documents: table<FileName: string, FileSize: int, ID: string, MIMEType: string, Note: string>, FixedDate: string, GlobalReference: string, ID: string, Inspections: table<InspectionDate: string, Notes: string>, ManagedRent: bool, Preferences: table<Name: string, Notes: string, Type: string>, PreviousRentAmount: float, PropertyAddress: string, Rent: string, RentAmount: float, StartDate: string, TenancyProperty: string, TenancyState: string, Tenants: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "tenancyID" $tenancyID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/tenancy" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post tenancy maintenance preferences:-
#
# POST /v2/customer/{shortName}/landlord/tenancy/maintenance/preference
# operationId: LandlordController_CreateMaintenancePreference
export def "customer-landlord-tenancy-maintenance-preference CreateMaintenancePreference" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # The login token returned from the /session POST call
  --tenancyID: string # The Tenancy ID
  --name: string # Name of the maintenance preference to add
  --notes: string # Notes of the maintenance preference to add
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "tenancyID" $tenancyID "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "notes" $notes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/tenancy/maintenance/preference" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a Tenancy Agreement Copy (PDF)
#
# GET /v2/customer/{shortName}/landlord/tenancyagreement
# operationId: LandlordController_GetTenancyAgreementReport
export def "customer-landlord-tenancyagreement GetTenancyAgreementReport" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # The login token returned from the /session POST call
  --tenancyID: string # The Tenancy ID
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "tenancyID" $tenancyID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/landlord/tenancyagreement" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads the photo of a property given the photo ID.
#
# GET /v2/customer/{shortName}/photo/download
# operationId: PhotoController_GetPhotoDownload
export def "customer-photo-download GetPhotoDownload" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # The login token returned from the /session POST call
  --photoID: string # The unique ID of the photo on the property
  --width: int # An optional parameter specifying the image width (format: int32)
  --height: int # An optional parameter specifying the image height (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "photoID" $photoID "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/photo/download" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection showing all the photos linked to a specific block, property or room
#
# GET /v2/customer/{shortName}/property/{propertyID}/photos
# operationId: PropertyController_GetPropertiesPhotos
export def "customer-property-photos GetPropertiesPhotos" [
  shortName: string
  propertyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # The login token returned from the /session POST call
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, FileName: string, OID: string, PhotoType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/property/($propertyID)/photos" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Logout a customer previously logged in via the Login endpoint.
#
# DELETE /v2/customer/{shortName}/session
# operationId: SessionController_Logout
export def "customer-session Logout" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # The login token returned from the /session POST call
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/session" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the currently logged on customer.
#
# GET /v2/customer/{shortName}/session
# operationId: SessionController_GetSessionInfo
export def "customer-session GetSessionInfo" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # The login token returned from the /session POST call
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/session" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login as a customer given their username and password.
#
# POST /v2/customer/{shortName}/session
# operationId: SessionController_Login
export def "customer-session Login" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --username: string # The user's username.
  --password: string # The user's password.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/session" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send a request to the in-tray to create a landlord login.
#
# POST /v2/customer/{shortName}/session/createlandlordlogin
# operationId: SessionController_CreateLandlordLogin
export def "customer-session-createlandlordlogin CreateLandlordLogin" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the landlord
  --title: string # The title of the landlord
  --forename: string # The forename of the landlord
  --surname: string # The surname of the landlord
  --propertyAddress: string # Address of the property linked to the landlord
  --contactDetails: string # Contact details of the landlord
  --branchID: string # (Optional) The branch ID linked to the login. This will determine which in tray the request display in
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "forename" $forename "scalar") (serialize-qp "surname" $surname "scalar") (serialize-qp "propertyAddress" $propertyAddress "scalar") (serialize-qp "contactDetails" $contactDetails "scalar") (serialize-qp "branchID" $branchID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/session/createlandlordlogin" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change the password of a customer given their existing and new password.
#
# PUT /v2/customer/{shortName}/session/password
# operationId: SessionController_ChangePassword
export def "customer-session-password ChangePassword" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # The login token returned from the /session POST call
  --oldPassword: string # The customer's existing password.
  --newPassword: string # The customer's new password.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "oldPassword" $oldPassword "scalar") (serialize-qp "newPassword" $newPassword "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/session/password" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset the customer's password. An email will be sent out to reset.
#
# POST /v2/customer/{shortName}/session/resetpassword
# operationId: SessionController_ResetPassword
export def "customer-session-resetpassword ResetPassword" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The login Email Address.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/customer/($shortName)/session/resetpassword" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
