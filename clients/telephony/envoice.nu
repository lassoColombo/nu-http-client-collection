# Auto-generated client for API v1.0.0 vv1
# Source: https://api.apis.guru/v2/specs/envoice.in/v1/openapi.json
# Auth: --token flag or $env.API_V1_0_0_TOKEN

const BASE_URL = "https://www.envoice.in"
const DEFAULT_AUTH = "x-auth-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_V1_0_0_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-auth-key" => { {headers: {x-auth-key: $token_val}, query: ""} }
    "x-auth-secret" => { {headers: {x-auth-secret: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://www.envoice.in"] }
def auth-scheme-completer [] { ["x-auth-key" "x-auth-secret"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/html" "text/json" "text/xml"] }
def Status-completer [] { ["Accepted" "Draft" "Rejected"] }
def Status-completer-1 [] { ["Draft" "Overdue" "Paid" "Unpaid" "Void"] }
def Status-completer-2 [] { ["Cancelled" "Completed" "Failed" "OnHold" "PendingPayment" "Processing" "Refunded" "Shipped"] }
def Status-completer-3 [] { ["Active" "Inactive" "NotAvailable"] }
def queryOptionsorder-completer [] { ["Asc" "Desc" "None"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "client-all All" } } | get name | first)
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

# Return all clients for the account
#
# GET /api/client/all
# operationId: ClientApi_All
export def "client-all All" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client/all")
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if the provided client can be deleted
#
# GET /api/client/candelete
# operationId: ClientApi_CanDelete
export def "client-candelete CanDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/client/candelete" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an existing client
#
# POST /api/client/delete
# operationId: ClientApi_Delete
export def "client-delete Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Id of client to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client/delete")
  let body = {Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return client details. Activities and invoices included.
#
# GET /api/client/details
# operationId: ClientApi_Details
export def "client-details Details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<AdditionalEmails: table<Email: string>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/client/details" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a client
#
# POST /api/client/new
# operationId: ClientApi_New
# --AdditionalEmails item shape: {Email?: string}
export def "client-new New" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --AdditionalEmails: list # Client additional emails contact for CC — item shape: {Email?: string}
  --Address: string # Client business address
  --ClientCountryId: int # Indicates the country where the clients is from (format: int32)
  --ClientCurrencyId: int # Indicates the default system currency used by the user for the client (format: int32)
  --CompanyRegistrationNumber: string # Client's Company Registration Number
  --DefaultDueDateInDays: int # Client custom payment terms (format: int32)
  --Email: string # Client email
  --Name: string # Name of the client
  --PhoneNumber: string # Client phone numer
  --UiLanguageId: int # Hold a value of the language in which the invoice will be sent (format: int32)
  --Vat: string # Client's VAT number
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client/new")
  let body = {AdditionalEmails: $AdditionalEmails, Address: $Address, ClientCountryId: $ClientCountryId, ClientCurrencyId: $ClientCurrencyId, CompanyRegistrationNumber: $CompanyRegistrationNumber, DefaultDueDateInDays: $DefaultDueDateInDays, Email: $Email, Name: $Name, PhoneNumber: $PhoneNumber, UiLanguageId: $UiLanguageId, Vat: $Vat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing client
#
# POST /api/client/update
# operationId: ClientApi_Update
# --AdditionalEmails item shape: {Email?: string}
export def "client-update Update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-auth-key: string
  --x-auth-secret: string
  --AdditionalEmails: list # Client additional emails contact for CC — item shape: {Email?: string}
  --Address: string # Client business address
  --ClientCountryId: int # Indicates the country where the clients is from (format: int32)
  --ClientCurrencyId: int # Indicates the default system currency used by the user for the client (format: int32)
  --CompanyRegistrationNumber: string # Client's Company Registration Number
  --DefaultDueDateInDays: int # Client custom payment terms (format: int32)
  --Email: string # Client email
  --Id: int # Entity id (format: int32)
  --Name: string # Name of the client
  --PhoneNumber: string # Client phone numer
  --UiLanguageId: int # Hold a value of the language in which the invoice will be sent (format: int32)
  --Vat: string # Client's VAT number
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client/update")
  let body = {AdditionalEmails: $AdditionalEmails, Address: $Address, ClientCountryId: $ClientCountryId, ClientCurrencyId: $ClientCurrencyId, CompanyRegistrationNumber: $CompanyRegistrationNumber, DefaultDueDateInDays: $DefaultDueDateInDays, Email: $Email, Id: $Id, Name: $Name, PhoneNumber: $PhoneNumber, UiLanguageId: $UiLanguageId, Vat: $Vat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all estimation for the account
#
# GET /api/estimation/all
# operationId: EstimationApi_All
export def "estimation-all All" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --queryOptionspage: int # format: int32
  --queryOptionspageSize: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClonedFromId: int, Currency: record, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Notes: string, Number: string, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.page" $queryOptionspage "scalar") (serialize-qp "queryOptions.pageSize" $queryOptionspageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/estimation/all" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change estimation status
#
# POST /api/estimation/changestatus
# operationId: EstimationApi_ChangeStatus
export def "estimation-changestatus ChangeStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Estimation Id (format: int32)
  --Status: string@Status-completer # New status of the estimation
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/changestatus")
  let body = {Id: $Id, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Convert the estimation to an invoice
#
# POST /api/estimation/convert
# operationId: EstimationApi_Convert
export def "estimation-convert Convert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --body: record
]: any -> record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/convert")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing estimation
#
# POST /api/estimation/delete
# operationId: EstimationApi_Delete
export def "estimation-delete Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Id of estimation to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/delete")
  let body = {Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return estimation data
#
# GET /api/estimation/details
# operationId: EstimationApi_Details
export def "estimation-details Details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/estimation/details" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an estimation
#
# POST /api/estimation/new
# operationId: EstimationApi_New
# --Attachments item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Items item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
# --PaymentGateways item shape: {Name?: string}
export def "estimation-new New" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Attachments: list # List of estimation attachments — item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --ClientId: int # The client to whom this estimation is assigned (format: int32)
  --ClonedFromId: int # Indicate from which estimation this estimation has been cloned from (format: int32)
  --CurrencyId: int # Id of the currency for the estimation amounts (format: int32)
  --ExpiresOn: string # Indicates when the estimation will be proclamed as due (format: date-time)
  --IssuedOn: string # Indicates when the estimation was issued (format: date-time)
  --Items: list # List of estimation items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --Notes: string # Internal note regarding the estimation
  --Number: string # Unique estimation number
  --PaymentGateways: list # List of enabled payment gateways for this estimation — item shape: {Name?: string}
  --PoNumber: string # Unique number generated by the buyer
  --Status: string@Status-completer # Indicate the status of the estimation (paid/unpaid/overdue)
  --Terms: string # Terms of agreement
]: any -> record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/new")
  let body = {Attachments: $Attachments, ClientId: $ClientId, ClonedFromId: $ClonedFromId, CurrencyId: $CurrencyId, ExpiresOn: $ExpiresOn, IssuedOn: $IssuedOn, Items: $Items, Notes: $Notes, Number: $Number, PaymentGateways: $PaymentGateways, PoNumber: $PoNumber, Status: $Status, Terms: $Terms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send the provided estimation to the client
#
# POST /api/estimation/sendtoclient
# operationId: EstimationApi_SendToClient
export def "estimation-sendtoclient SendToClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --AttachPdf: oneof<nothing, bool> # Should attach pdf file
  --EstimationId: int # Id of the estimation (format: int32)
  --Id: int # Id of the estimation (format: int32)
  --Message: string # Message to be embedded in the email
  --SendToSelf: oneof<nothing, bool> # Should email copy be send to self
  --Subject: string # Subject for the email
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/sendtoclient")
  let body = {AttachPdf: $AttachPdf, EstimationId: $EstimationId, Id: $Id, Message: $Message, SendToSelf: $SendToSelf, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the status of the estimation
#
# GET /api/estimation/status
# operationId: EstimationApi_Status
export def "estimation-status Status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/estimation/status" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing estimation
#
# POST /api/estimation/update
# operationId: EstimationApi_Update
# --Attachments item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Items item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Id?: int, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
# --PaymentGateways item shape: {Name?: string}
export def "estimation-update Update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Attachments: list # List of estimation attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --ClientId: int # The client to whom this estimation is assigned (format: int32)
  --ClonedFromId: int # Indicate from which estimation this estimation has been cloned from (format: int32)
  --CurrencyId: int # Id of the currency for the estimation amounts (format: int32)
  --ExpiresOn: string # Indicates when the estimation will be proclamed as due (format: date-time)
  --Id: int # estimation id (format: int32)
  --IssuedOn: string # Indicates when the estimation was issued (format: date-time)
  --Items: list # List of estimation items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Id?: int, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --Notes: string # Internal note regarding the estimation
  --Number: string # Unique estimation number
  --PaymentGateways: list # List of enabled payment gateways for this estimation — item shape: {Name?: string}
  --PoNumber: string # Unique number generated by the buyer
  --Status: string@Status-completer # Indicate the status of the estimation (paid/unpaid/overdue)
  --Terms: string # Terms of agreement
]: any -> record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/update")
  let body = {Attachments: $Attachments, ClientId: $ClientId, ClonedFromId: $ClonedFromId, CurrencyId: $CurrencyId, ExpiresOn: $ExpiresOn, Id: $Id, IssuedOn: $IssuedOn, Items: $Items, Notes: $Notes, Number: $Number, PaymentGateways: $PaymentGateways, PoNumber: $PoNumber, Status: $Status, Terms: $Terms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return the unique url to the client's invoice
#
# GET /api/estimation/uri
# operationId: EstimationApi_Uri
export def "estimation-uri Uri" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Link: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/estimation/uri" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all of the platform supported countries
#
# GET /api/general/countries
# operationId: GeneralApi_Countries
export def "general-countries Countries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<Id: int, Name: string, Value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/general/countries")
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all of the platform supported currencies
#
# GET /api/general/currencies
# operationId: GeneralApi_Currencies
export def "general-currencies Currencies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<Code: string, Id: int, Name: string, Symbol: string, Value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/general/currencies")
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all of the platform supported Date Formats
#
# GET /api/general/dateformats
# operationId: GeneralApi_DateFormats
export def "general-dateformats DateFormats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/general/dateformats")
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all of the platform supported UI languages
#
# GET /api/general/uilanguages
# operationId: GeneralApi_UiLanguages
export def "general-uilanguages UiLanguages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<Id: int, Name: string, UiCulture: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/general/uilanguages")
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all invoices for the account
#
# GET /api/invoice/all
# operationId: InvoiceApi_All
export def "invoice-all All" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --queryOptionspage: int # format: int32
  --queryOptionspageSize: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClonedFromId: int, Currency: record, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Notes: string, Number: string, PoNumber: string, RecurringProfile: record, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.page" $queryOptionspage "scalar") (serialize-qp "queryOptions.pageSize" $queryOptionspageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/all" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all invoice categories for the account
#
# GET /api/invoice/allcategories
export def "invoice-allcategories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<Id: int, Name: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/allcategories" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change invoice status
#
# POST /api/invoice/changestatus
# operationId: InvoiceApi_ChangeStatus
export def "invoice-changestatus ChangeStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Invoice Id (format: int32)
  --Status: string@Status-completer-1 # New status of the invoice
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/changestatus")
  let body = {Id: $Id, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing invoice
#
# POST /api/invoice/delete
# operationId: InvoiceApi_Delete
export def "invoice-delete Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Id of invoice to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/delete")
  let body = {Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing invoice category
#
# POST /api/invoice/deletecategory
export def "invoice-deletecategory post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # format: int32
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/deletecategory")
  let body = {Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return invoice data
#
# GET /api/invoice/details
# operationId: InvoiceApi_Details
export def "invoice-details Details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/details" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an invoice
#
# POST /api/invoice/new
# operationId: InvoiceApi_New
# --Attachments item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Items item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
# --PaymentGateways item shape: {Name?: string}
# --RecurringProfile shape: {DayOfMonth?: int, DayOfWeek?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", DueDateInDays?: int, EndOfRecurrance?: string, Month?: int, RecurrancePattern?: "Daily"|"Weekly"|"Monthly"|"Yearly", RecurranceValue?: int, StartOfRecurrance?: string, Status?: "Pending"|"Active"|"Cancelled"|"Finished", Title?: string}
export def "invoice-new New" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Attachments: list # List of invoice attachments — item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --ClientId: int # The client to whom this invoice is assigned (format: int32)
  --ClonedFromId: int # Indicate from which invoice this invoice has been cloned from (format: int32)
  --CurrencyId: int # Id of the currency for the invoice amounts (format: int32)
  --Duedate: string # Indicates when the invoice will be proclamed as due (format: date-time)
  --InvoiceCategoryId: int # Hold the id of the invoice category (format: int32)
  --IssuedOn: string # Indicates when the invoice was issued (format: date-time)
  --Items: list # List of invoice items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --Notes: string # Internal note regarding the invoice
  --Number: string # Unique invoice number
  --PaymentGateways: list # List of enabled payment gateways for this invoice — item shape: {Name?: string}
  --PoNumber: string # Unique number generated by the buyer
  --RecurringProfile: record # Definition of invoice recurring profile — shape: {DayOfMonth?: int, DayOfWeek?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", DueDateInDays?: int, EndOfRecurrance?: string, Month?: int, RecurrancePattern?: "Daily"|"Weekly"|"Monthly"|"Yearly", RecurranceValue?: int, StartOfRecurrance?: string, Status?: "Pending"|"Active"|"Cancelled"|"Finished", Title?: string}
  --RecurringProfileId: int # Hold the id of the recurring profile (format: int32)
  --ShouldSendReminders: oneof<nothing, bool> # Should send email reminders to client?
  --Status: string@Status-completer-1 # Indicate the status of the invoice (paid/unpaid/overdue)
  --Terms: string # Terms of agreement
]: any -> record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/new")
  let body = {Attachments: $Attachments, ClientId: $ClientId, ClonedFromId: $ClonedFromId, CurrencyId: $CurrencyId, Duedate: $Duedate, InvoiceCategoryId: $InvoiceCategoryId, IssuedOn: $IssuedOn, Items: $Items, Notes: $Notes, Number: $Number, PaymentGateways: $PaymentGateways, PoNumber: $PoNumber, RecurringProfile: $RecurringProfile, RecurringProfileId: $RecurringProfileId, ShouldSendReminders: $ShouldSendReminders, Status: $Status, Terms: $Terms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an invoice category
#
# POST /api/invoice/newcategory
export def "invoice-newcategory post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Name: string # Category name
]: any -> record<Id: int, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/newcategory")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return the PDF for the invoice
#
# GET /api/invoice/pdf
# operationId: InvoiceApi_Pdf
export def "invoice-pdf Pdf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --signedVersion: oneof<nothing, bool>
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Link: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "signedVersion" $signedVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/pdf" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send the provided invoice to the accountant
#
# POST /api/invoice/sendtoaccountant
# operationId: InvoiceApi_SendToAccountant
export def "invoice-sendtoaccountant SendToAccountant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Id of the invoice (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/sendtoaccountant")
  let body = {Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send the provided invoice to the client
#
# POST /api/invoice/sendtoclient
# operationId: InvoiceApi_SendToClient
export def "invoice-sendtoclient SendToClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --AttachPdf: oneof<nothing, bool> # Should attach pdf file
  --Id: int # Id of the invoice (format: int32)
  --InvoiceId: int # Id of the invoice (format: int32)
  --Message: string # Message to be embedded in the email
  --SendToSelf: oneof<nothing, bool> # Should email copy be send to self
  --Subject: string # Subject for the email
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/sendtoclient")
  let body = {AttachPdf: $AttachPdf, Id: $Id, InvoiceId: $InvoiceId, Message: $Message, SendToSelf: $SendToSelf, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the status of the invoice
#
# GET /api/invoice/status
# operationId: InvoiceApi_Status
export def "invoice-status Status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/status" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing invoice
#
# POST /api/invoice/update
# operationId: InvoiceApi_Update
# --Attachments item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Items item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Id?: int, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
# --PaymentGateways item shape: {Name?: string}
# --RecurringProfile shape: {DayOfMonth?: int, DayOfWeek?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", DueDateInDays?: int, EndOfRecurrance?: string, Month?: int, RecurrancePattern?: "Daily"|"Weekly"|"Monthly"|"Yearly", RecurranceValue?: int, StartOfRecurrance?: string, Status?: "Pending"|"Active"|"Cancelled"|"Finished", Title?: string}
export def "invoice-update Update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Attachments: list # List of invoice attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --ClientId: int # The client to whom this invoice is assigned (format: int32)
  --ClonedFromId: int # Indicate from which invoice this invoice has been cloned from (format: int32)
  --CurrencyId: int # Id of the currency for the invoice amounts (format: int32)
  --Duedate: string # Indicates when the invoice will be proclamed as due (format: date-time)
  --Id: int # Invoice id (format: int32)
  --InvoiceCategoryId: int # Hold the id of the invoice category (format: int32)
  --IssuedOn: string # Indicates when the invoice was issued (format: date-time)
  --Items: list # List of invoice items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Id?: int, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --Notes: string # Internal note regarding the invoice
  --Number: string # Unique invoice number
  --PaymentGateways: list # List of enabled payment gateways for this invoice — item shape: {Name?: string}
  --PoNumber: string # Unique number generated by the buyer
  --RecurringProfile: record # Definition of invoice recurring profile — shape: {DayOfMonth?: int, DayOfWeek?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", DueDateInDays?: int, EndOfRecurrance?: string, Month?: int, RecurrancePattern?: "Daily"|"Weekly"|"Monthly"|"Yearly", RecurranceValue?: int, StartOfRecurrance?: string, Status?: "Pending"|"Active"|"Cancelled"|"Finished", Title?: string}
  --RecurringProfileId: int # Hold the id of the recurring profile (format: int32)
  --ShouldSendReminders: oneof<nothing, bool> # Should send email reminders to client?
  --Status: string@Status-completer-1 # Indicate the status of the invoice (paid/unpaid/overdue)
  --Terms: string # Terms of agreement
]: any -> record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/update")
  let body = {Attachments: $Attachments, ClientId: $ClientId, ClonedFromId: $ClonedFromId, CurrencyId: $CurrencyId, Duedate: $Duedate, Id: $Id, InvoiceCategoryId: $InvoiceCategoryId, IssuedOn: $IssuedOn, Items: $Items, Notes: $Notes, Number: $Number, PaymentGateways: $PaymentGateways, PoNumber: $PoNumber, RecurringProfile: $RecurringProfile, RecurringProfileId: $RecurringProfileId, ShouldSendReminders: $ShouldSendReminders, Status: $Status, Terms: $Terms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing invoice category
#
# POST /api/invoice/updatecategory
export def "invoice-updatecategory post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Entity id (format: int32)
  --Name: string # Category name
]: any -> record<Id: int, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/updatecategory")
  let body = {Id: $Id, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return the unique url to the client's invoice
#
# GET /api/invoice/uri
# operationId: InvoiceApi_Uri
export def "invoice-uri Uri" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Link: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/uri" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all orders for the account
#
# GET /api/order/all
# operationId: OrderApi_All
export def "order-all All" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --queryOptionspage: int # format: int32
  --queryOptionspageSize: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, AfterPaymentDescription: string, CouponCode: string, Currency: record, CurrencyId: int, Description: string, DiscountAmount: float, Id: int, Name: string, Note: string, OrderBillingDetails: record, OrderShippingDetails: record, ProductId: int, Referral: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.page" $queryOptionspage "scalar") (serialize-qp "queryOptions.pageSize" $queryOptionspageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/order/all" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change order shipping details
#
# POST /api/order/changeshippingdetails
# operationId: OrderApi_ChangeShippingDetails
export def "order-changeshippingdetails ChangeShippingDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
  --Address: string # Client street and number
  --CountryId: int # Client country id (format: int32)
  --Email: string # Client email
  --Name: string # Client name
  --PhoneNumber: string # Client phone number
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/order/changeshippingdetails" $qp)
  let body = {Address: $Address, CountryId: $CountryId, Email: $Email, Name: $Name, PhoneNumber: $PhoneNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change order status
#
# POST /api/order/changestatus
# operationId: OrderApi_ChangeStatus
export def "order-changestatus ChangeStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Order Id (format: int32)
  --Reason: string # Reason for status change
  --Status: string@Status-completer-2 # New status of the order
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/order/changestatus")
  let body = {Id: $Id, Reason: $Reason, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing order
#
# POST /api/order/delete
# operationId: OrderApi_Delete
export def "order-delete Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Id of order to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/order/delete")
  let body = {Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return order details
#
# GET /api/order/details
# operationId: OrderApi_Details
export def "order-details Details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<AccessToken: string, AfterPaymentDescription: string, Attachments: table<Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, CouponCode: string, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, CurrencyId: int, Description: string, DiscountAmount: float, Id: int, Items: table<Cost: float, Description: string, ProductItemId: int, Quantity: float, ReferenceId: string, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Name: string, Note: string, OrderBillingDetails: record<Address: string, CountryId: int, Email: string, Name: string, PhoneNumber: string>, OrderShippingDetails: record<Address: string, CountryId: int, Email: string, Name: string, PhoneNumber: string>, ProductId: int, Referral: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/order/details" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an order
#
# POST /api/order/new
# operationId: OrderApi_New
# --Attachments item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Items item shape: {Cost?: float, Description?: string, ProductItemId?: int, Quantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
# --OrderBillingDetails shape: {Address?: string, CountryId?: int, Email?: string, Name?: string, PhoneNumber?: string}
# --OrderShippingDetails shape: {Address?: string, CountryId?: int, Email?: string, Name?: string, PhoneNumber?: string}
export def "order-new New" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --AfterPaymentDescription: string # After payment description
  --Attachments: list # List of Order attachments — item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --CouponCode: string # Coupon to apply in order to get the discount
  --CurrencyId: int # Foreign key Currency (format: int32)
  --Description: string # Product description
  --DiscountAmount: float # Discount amount (format: double)
  --Items: list # List of Order items — item shape: {Cost?: float, Description?: string, ProductItemId?: int, Quantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
  --Name: string # Product alias
  --Note: string # Customer note to seller
  --OrderBillingDetails: record # shape: {Address?: string, CountryId?: int, Email?: string, Name?: string, PhoneNumber?: string}
  --OrderShippingDetails: record # shape: {Address?: string, CountryId?: int, Email?: string, Name?: string, PhoneNumber?: string}
  --ProductId: int # Product id (format: int32)
  --Referral: string # Represent the referral for this order
  --ShippingAmount: float # Cost for shipping the product (format: double)
  --ShippingDescription: string # Client instructions for shipping
  --Status: string@Status-completer-2 # Order status
  --SubTotalAmount: float # Sub total amount (format: double)
  --TaxAmount: float # Tax amount (format: double)
  --TotalAmount: float # Total amount (format: double)
  --WhatHappensNextDescription: string # What happens next description
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/order/new")
  let body = {AfterPaymentDescription: $AfterPaymentDescription, Attachments: $Attachments, CouponCode: $CouponCode, CurrencyId: $CurrencyId, Description: $Description, DiscountAmount: $DiscountAmount, Items: $Items, Name: $Name, Note: $Note, OrderBillingDetails: $OrderBillingDetails, OrderShippingDetails: $OrderShippingDetails, ProductId: $ProductId, Referral: $Referral, ShippingAmount: $ShippingAmount, ShippingDescription: $ShippingDescription, Status: $Status, SubTotalAmount: $SubTotalAmount, TaxAmount: $TaxAmount, TotalAmount: $TotalAmount, WhatHappensNextDescription: $WhatHappensNextDescription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all supported payment gateways (no currencies means all are supported)
#
# GET /api/payment/supported
# operationId: PaymentApi_Supported
export def "payment-supported Supported" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<Name: string, SupportedCurrencies: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/payment/supported")
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a payment link
#
# GET /api/paymentlink/all
# operationId: PaymentLinkApi_All
export def "paymentlink-all All" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --queryOptionspage: int # format: int32
  --queryOptionspageSize: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClientId: int, Currency: record, CurrencyId: int, DiscountAmount: float, Id: int, Invoice: record, Items: list, Number: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, User: record, UserId: int>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.page" $queryOptionspage "scalar") (serialize-qp "queryOptions.pageSize" $queryOptionspageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/paymentlink/all" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an existing payment link
#
# POST /api/paymentlink/delete
# operationId: PaymentLinkApi_Delete
# --Client shape: {Address?: string, ClientCountryId?: int, ClientCurrencyId?: int, CompanyRegistrationNumber?: string, DefaultDueDateInDays?: int, Email?: string, Id?: int, Name?: string, PhoneNumber?: string, UiLanguageId?: int, UserId?: int, Vat?: string}
# --Currency shape: {Code?: string, Id?: int, Name?: string, Symbol?: string, Value?: string}
# --Invoice shape: {AccessToken?: string, Activities?: list, Attachments?: list, ClientId?: int, ClonedFromId?: int, CurrencyId?: int, DiscountAmount?: float, Duedate?: string, EnablePartialPayments?: bool, EstimationId?: int, Id?: int, InvoiceCategoryId?: int, IsDigitallySigned?: bool, IssuedOn?: string, Items?: list, Notes?: string, Number?: string, OrderId?: int, PaymentGateways?: list, PaymentLinkId?: int, Payments?: list, PoNumber?: string, RecurringProfileId?: int, ShouldSendReminders?: bool, Status?: "Draft"|"Paid"|"Unpaid"|"Overdue"|"Void", SubTotalAmount?: float, TaxAmount?: float, Terms?: string, TotalAmount?: float, UserId?: int}
# --Items item shape: {Cost?: float, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, PaymentLinkId?: int, Quantity?: float, SubTotalAmount?: float, Tax?: record, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkType?: record, WorkTypeId?: int}
# --User shape: {ActionNotificationsLastReadOn?: string, Email?: string, ExternalConnections?: list, HasBeenOnboarded?: bool, Id?: int, IsLocked?: bool, IsVerified?: bool, KnowledgeNotificationsLastReadOn?: string, LastSeenOn?: string, Name?: string, Password?: string, PasswordSalt?: string, ReferralPath?: string, ReferredUsers?: int, ReferrerKey?: string, Settings?: record, Status?: "Normal"|"Fraudlent"|"Locked", SubscriptionPlan?: record, Type?: "Anonymous"|"Customer"|"SystemAdministrator"|"Collaborator", Username?: string, VerifiedOn?: string, YearsOfExperience?: "One"|"OneToThree"|"ThreeToFive"|"SixPlus"}
export def "paymentlink-delete Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --AccessToken: string
  --Client: record # shape: {Address?: string, ClientCountryId?: int, ClientCurrencyId?: int, CompanyRegistrationNumber?: string, DefaultDueDateInDays?: int, Email?: string, Id?: int, Name?: string, PhoneNumber?: string, UiLanguageId?: int, UserId?: int, Vat?: string}
  --ClientId: int # format: int32
  --Currency: record # shape: {Code?: string, Id?: int, Name?: string, Symbol?: string, Value?: string}
  --CurrencyId: int # format: int32
  --DiscountAmount: float # format: double
  --Id: int # format: int32
  --Invoice: record # shape: {AccessToken?: string, Activities?: list, Attachments?: list, ClientId?: int, ClonedFromId?: int, CurrencyId?: int, DiscountAmount?: float, Duedate?: string, EnablePartialPayments?: bool, EstimationId?: int, Id?: int, InvoiceCategoryId?: int, IsDigitallySigned?: bool, IssuedOn?: string, Items?: list, Notes?: string, Number?: string, OrderId?: int, PaymentGateways?: list, PaymentLinkId?: int, Payments?: list, PoNumber?: string, RecurringProfileId?: int, ShouldSendReminders?: bool, Status?: "Draft"|"Paid"|"Unpaid"|"Overdue"|"Void", SubTotalAmount?: float, TaxAmount?: float, Terms?: string, TotalAmount?: float, UserId?: int}
  --Items: list # item shape: {Cost?: float, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, PaymentLinkId?: int, Quantity?: float, SubTotalAmount?: float, Tax?: record, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkType?: record, WorkTypeId?: int}
  --Number: string
  --SubTotalAmount: float # format: double
  --TaxAmount: float # format: double
  --TotalAmount: float # format: double
  --User: record # shape: {ActionNotificationsLastReadOn?: string, Email?: string, ExternalConnections?: list, HasBeenOnboarded?: bool, Id?: int, IsLocked?: bool, IsVerified?: bool, KnowledgeNotificationsLastReadOn?: string, LastSeenOn?: string, Name?: string, Password?: string, PasswordSalt?: string, ReferralPath?: string, ReferredUsers?: int, ReferrerKey?: string, Settings?: record, Status?: "Normal"|"Fraudlent"|"Locked", SubscriptionPlan?: record, Type?: "Anonymous"|"Customer"|"SystemAdministrator"|"Collaborator", Username?: string, VerifiedOn?: string, YearsOfExperience?: "One"|"OneToThree"|"ThreeToFive"|"SixPlus"}
  --UserId: int # format: int32
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/paymentlink/delete")
  let body = {AccessToken: $AccessToken, Client: $Client, ClientId: $ClientId, Currency: $Currency, CurrencyId: $CurrencyId, DiscountAmount: $DiscountAmount, Id: $Id, Invoice: $Invoice, Items: $Items, Number: $Number, SubTotalAmount: $SubTotalAmount, TaxAmount: $TaxAmount, TotalAmount: $TotalAmount, User: $User, UserId: $UserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a payment link
#
# POST /api/paymentlink/new
# operationId: PaymentLinkApi_New
# --Client shape: {Address?: string, ClientCountryId?: int, ClientCurrencyId?: int, CompanyRegistrationNumber?: string, DefaultDueDateInDays?: int, Email?: string, Id?: int, Name?: string, PhoneNumber?: string, UiLanguageId?: int, UserId?: int, Vat?: string}
# --Currency shape: {Code?: string, Id?: int, Name?: string, Symbol?: string, Value?: string}
# --Invoice shape: {AccessToken?: string, Activities?: list, Attachments?: list, ClientId?: int, ClonedFromId?: int, CurrencyId?: int, DiscountAmount?: float, Duedate?: string, EnablePartialPayments?: bool, EstimationId?: int, Id?: int, InvoiceCategoryId?: int, IsDigitallySigned?: bool, IssuedOn?: string, Items?: list, Notes?: string, Number?: string, OrderId?: int, PaymentGateways?: list, PaymentLinkId?: int, Payments?: list, PoNumber?: string, RecurringProfileId?: int, ShouldSendReminders?: bool, Status?: "Draft"|"Paid"|"Unpaid"|"Overdue"|"Void", SubTotalAmount?: float, TaxAmount?: float, Terms?: string, TotalAmount?: float, UserId?: int}
# --Items item shape: {Cost?: float, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, PaymentLinkId?: int, Quantity?: float, SubTotalAmount?: float, Tax?: record, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkType?: record, WorkTypeId?: int}
# --User shape: {ActionNotificationsLastReadOn?: string, Email?: string, ExternalConnections?: list, HasBeenOnboarded?: bool, Id?: int, IsLocked?: bool, IsVerified?: bool, KnowledgeNotificationsLastReadOn?: string, LastSeenOn?: string, Name?: string, Password?: string, PasswordSalt?: string, ReferralPath?: string, ReferredUsers?: int, ReferrerKey?: string, Settings?: record, Status?: "Normal"|"Fraudlent"|"Locked", SubscriptionPlan?: record, Type?: "Anonymous"|"Customer"|"SystemAdministrator"|"Collaborator", Username?: string, VerifiedOn?: string, YearsOfExperience?: "One"|"OneToThree"|"ThreeToFive"|"SixPlus"}
export def "paymentlink-new New" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --AccessToken: string
  --Client: record # shape: {Address?: string, ClientCountryId?: int, ClientCurrencyId?: int, CompanyRegistrationNumber?: string, DefaultDueDateInDays?: int, Email?: string, Id?: int, Name?: string, PhoneNumber?: string, UiLanguageId?: int, UserId?: int, Vat?: string}
  --ClientId: int # format: int32
  --Currency: record # shape: {Code?: string, Id?: int, Name?: string, Symbol?: string, Value?: string}
  --CurrencyId: int # format: int32
  --DiscountAmount: float # format: double
  --Id: int # format: int32
  --Invoice: record # shape: {AccessToken?: string, Activities?: list, Attachments?: list, ClientId?: int, ClonedFromId?: int, CurrencyId?: int, DiscountAmount?: float, Duedate?: string, EnablePartialPayments?: bool, EstimationId?: int, Id?: int, InvoiceCategoryId?: int, IsDigitallySigned?: bool, IssuedOn?: string, Items?: list, Notes?: string, Number?: string, OrderId?: int, PaymentGateways?: list, PaymentLinkId?: int, Payments?: list, PoNumber?: string, RecurringProfileId?: int, ShouldSendReminders?: bool, Status?: "Draft"|"Paid"|"Unpaid"|"Overdue"|"Void", SubTotalAmount?: float, TaxAmount?: float, Terms?: string, TotalAmount?: float, UserId?: int}
  --Items: list # item shape: {Cost?: float, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, PaymentLinkId?: int, Quantity?: float, SubTotalAmount?: float, Tax?: record, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkType?: record, WorkTypeId?: int}
  --Number: string
  --SubTotalAmount: float # format: double
  --TaxAmount: float # format: double
  --TotalAmount: float # format: double
  --User: record # shape: {ActionNotificationsLastReadOn?: string, Email?: string, ExternalConnections?: list, HasBeenOnboarded?: bool, Id?: int, IsLocked?: bool, IsVerified?: bool, KnowledgeNotificationsLastReadOn?: string, LastSeenOn?: string, Name?: string, Password?: string, PasswordSalt?: string, ReferralPath?: string, ReferredUsers?: int, ReferrerKey?: string, Settings?: record, Status?: "Normal"|"Fraudlent"|"Locked", SubscriptionPlan?: record, Type?: "Anonymous"|"Customer"|"SystemAdministrator"|"Collaborator", Username?: string, VerifiedOn?: string, YearsOfExperience?: "One"|"OneToThree"|"ThreeToFive"|"SixPlus"}
  --UserId: int # format: int32
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/paymentlink/new")
  let body = {AccessToken: $AccessToken, Client: $Client, ClientId: $ClientId, Currency: $Currency, CurrencyId: $CurrencyId, DiscountAmount: $DiscountAmount, Id: $Id, Invoice: $Invoice, Items: $Items, Number: $Number, SubTotalAmount: $SubTotalAmount, TaxAmount: $TaxAmount, TotalAmount: $TotalAmount, User: $User, UserId: $UserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return the unique url to the client's payment link
#
# GET /api/paymentlink/uri
# operationId: PaymentLinkApi_Uri
export def "paymentlink-uri Uri" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Link: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/paymentlink/uri" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all products for the account
#
# GET /api/product/all
# operationId: ProductApi_All
export def "product-all All" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --queryOptionspage: int # format: int32
  --queryOptionspageSize: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, AfterPaymentDescription: string, ButtonCallToAction: string, Currency: record, CurrencyId: int, Description: string, Id: int, IsFeatured: bool, Name: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.page" $queryOptionspage "scalar") (serialize-qp "queryOptions.pageSize" $queryOptionspageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/product/all" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an existing product
#
# POST /api/product/delete
# operationId: ProductApi_Delete
export def "product-delete Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Id of product to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/product/delete")
  let body = {Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return product details
#
# GET /api/product/details
# operationId: ProductApi_Details
export def "product-details Details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<AccessToken: string, AfterPaymentDescription: string, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, ButtonCallToAction: string, Coupons: table<Code: string, DiscountAmount: float, DiscountPercentage: float, Id: int, ValidUntil: string>, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, CurrencyId: int, Description: string, Discounts: table<DiscountAmount: float, DiscountPercentage: float, Id: int, Name: string, ValidFrom: string, ValidTo: string>, Id: int, IsFeatured: bool, Items: table<Cost: float, Description: string, Id: int, MinimumQuantity: float, ReferenceId: string, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Name: string, PaymentGateways: table<Name: string>, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/product/details" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a product
#
# POST /api/product/new
# operationId: ProductApi_New
# --Attachments item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Coupons item shape: {Code?: string, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, ValidUntil?: string}
# --Discounts item shape: {DiscountAmount?: float, DiscountPercentage?: float, Id?: int, Name?: string, ValidFrom?: string, ValidTo?: string}
# --Items item shape: {Cost?: float, Description?: string, Id?: int, MinimumQuantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
# --PaymentGateways item shape: {Name?: string}
export def "product-new New" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --AfterPaymentDescription: string # After payment description
  --Attachments: list # List of product attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --ButtonCallToAction: string # Default button call to action Ex: Buy now, subscribe, ...
  --Coupons: list # List of product coupons — item shape: {Code?: string, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, ValidUntil?: string}
  --CurrencyId: int # Foreign key Currency (format: int32)
  --Description: string # Product description
  --Discounts: list # List of product discounts — item shape: {DiscountAmount?: float, DiscountPercentage?: float, Id?: int, Name?: string, ValidFrom?: string, ValidTo?: string}
  --IsFeatured: oneof<nothing, bool> # Indicate that the product is set as featured
  --Items: list # List of product items — item shape: {Cost?: float, Description?: string, Id?: int, MinimumQuantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
  --Name: string # Product alias
  --PaymentGateways: list # List of enabled payment gateways for this product — item shape: {Name?: string}
  --ShippingAmount: float # Cost for shipping the product (format: double)
  --ShippingDescription: string # Client instructions for shipping
  --Status: string@Status-completer-3 # Product availability status
  --WhatHappensNextDescription: string # What happens next description
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/product/new")
  let body = {AfterPaymentDescription: $AfterPaymentDescription, Attachments: $Attachments, ButtonCallToAction: $ButtonCallToAction, Coupons: $Coupons, CurrencyId: $CurrencyId, Description: $Description, Discounts: $Discounts, IsFeatured: $IsFeatured, Items: $Items, Name: $Name, PaymentGateways: $PaymentGateways, ShippingAmount: $ShippingAmount, ShippingDescription: $ShippingDescription, Status: $Status, WhatHappensNextDescription: $WhatHappensNextDescription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing product
#
# POST /api/product/update
# operationId: ProductApi_Update
# --Attachments item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Coupons item shape: {Code?: string, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, ValidUntil?: string}
# --Discounts item shape: {DiscountAmount?: float, DiscountPercentage?: float, Id?: int, Name?: string, ValidFrom?: string, ValidTo?: string}
# --Items item shape: {Cost?: float, Description?: string, Id?: int, MinimumQuantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
# --PaymentGateways item shape: {Name?: string}
export def "product-update Update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-auth-key: string
  --x-auth-secret: string
  --AfterPaymentDescription: string # After payment description
  --Attachments: list # List of product attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --ButtonCallToAction: string # Default button call to action Ex: Buy now, subscribe, ...
  --Coupons: list # List of product coupons — item shape: {Code?: string, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, ValidUntil?: string}
  --CurrencyId: int # Foreign key Currency (format: int32)
  --Description: string # Product description
  --Discounts: list # List of product discounts — item shape: {DiscountAmount?: float, DiscountPercentage?: float, Id?: int, Name?: string, ValidFrom?: string, ValidTo?: string}
  --Id: int # Product id (format: int32)
  --IsFeatured: oneof<nothing, bool> # Indicate that the product is set as featured
  --Items: list # List of product items — item shape: {Cost?: float, Description?: string, Id?: int, MinimumQuantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
  --Name: string # Product alias
  --PaymentGateways: list # List of enabled payment gateways for this product — item shape: {Name?: string}
  --ShippingAmount: float # Cost for shipping the product (format: double)
  --ShippingDescription: string # Client instructions for shipping
  --Status: string@Status-completer-3 # Product availability status
  --WhatHappensNextDescription: string # What happens next description
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/product/update")
  let body = {AfterPaymentDescription: $AfterPaymentDescription, Attachments: $Attachments, ButtonCallToAction: $ButtonCallToAction, Coupons: $Coupons, CurrencyId: $CurrencyId, Description: $Description, Discounts: $Discounts, Id: $Id, IsFeatured: $IsFeatured, Items: $Items, Name: $Name, PaymentGateways: $PaymentGateways, ShippingAmount: $ShippingAmount, ShippingDescription: $ShippingDescription, Status: $Status, WhatHappensNextDescription: $WhatHappensNextDescription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all taxes for the account
#
# GET /api/tax/all
# operationId: TaxApi_All
export def "tax-all All" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<CreatedOn: string, Id: int, Name: string, Percentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tax/all")
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an existing tax
#
# POST /api/tax/delete
# operationId: TaxApi_Delete
export def "tax-delete Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Id of tax to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tax/delete")
  let body = {Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a tax
#
# POST /api/tax/new
# operationId: TaxApi_New
export def "tax-new New" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Name: string # Name of the task
  --Percentage: float # Task percentage. Ex: 18% (format: double)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tax/new")
  let body = {Name: $Name, Percentage: $Percentage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing tax
#
# POST /api/tax/update
# operationId: TaxApi_Update
export def "tax-update Update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Entity id (format: int32)
  --Name: string # Name of the task
  --Percentage: float # Task percentage. Ex: 18% (format: double)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tax/update")
  let body = {Id: $Id, Name: $Name, Percentage: $Percentage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all work types for the account
#
# GET /api/worktype/all
# operationId: WorkTypeApi_All
export def "worktype-all All" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<CreatedOn: string, Id: int, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/worktype/all")
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an existing work type
#
# POST /api/worktype/delete
# operationId: WorkTypeApi_Delete
export def "worktype-delete Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Id of work type to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/worktype/delete")
  let body = {Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return work type details
#
# GET /api/worktype/details
# operationId: WorkTypeApi_Details
export def "worktype-details Details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --workTypeId: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<CreatedOn: string, Id: int, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workTypeId" $workTypeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/worktype/details" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a work type
#
# POST /api/worktype/new
# operationId: WorkTypeApi_New
export def "worktype-new New" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --Title: string # Indicates the title of of the work type (Logo design, development...)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/worktype/new")
  let body = {Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all work types for the account that match the query param
#
# GET /api/worktype/search
# operationId: WorkTypeApi_Search
export def "worktype-search Search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --queryOptionsquery: string
  --queryOptionsorderBy: string
  --queryOptionsorder: string@queryOptionsorder-completer
  --queryOptionspage: int # format: int32
  --queryOptionspageSize: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<CreatedOn: string, Id: int, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.query" $queryOptionsquery "scalar") (serialize-qp "queryOptions.orderBy" $queryOptionsorderBy "scalar") (serialize-qp "queryOptions.order" $queryOptionsorder "scalar") (serialize-qp "queryOptions.page" $queryOptionspage "scalar") (serialize-qp "queryOptions.pageSize" $queryOptionspageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/worktype/search" $qp)
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing work type
#
# POST /api/worktype/update
# operationId: WorkTypeApi_Update
export def "worktype-update Update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-auth-key: string
  --x-auth-secret: string
  --Id: int # Entity id (format: int32)
  --Title: string # Indicates the title of of the work type (Logo design, development...)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/worktype/update")
  let body = {Id: $Id, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
