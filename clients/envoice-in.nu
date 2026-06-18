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
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://www.envoice.in"] }
def auth-scheme-completer [] { ["x-auth-key" "x-auth-secret"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/html" "text/json" "text/xml"] }
def status-completer [] { ["Accepted" "Draft" "Rejected"] }
def status-completer-1 [] { ["Draft" "Overdue" "Paid" "Unpaid" "Void"] }
def status-completer-2 [] { ["Cancelled" "Completed" "Failed" "OnHold" "PendingPayment" "Processing" "Refunded" "Shipped"] }
def status-completer-3 [] { ["Active" "Inactive" "NotAvailable"] }
def query-options-order-completer [] { ["Asc" "Desc" "None"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "client-all list" } } | get name | first)
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
export def "client-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client/all")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Check if the provided client can be deleted
#
# GET /api/client/candelete
# operationId: ClientApi_CanDelete
export def "client-candelete delete-can" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/client/candelete" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete an existing client
#
# POST /api/client/delete
# operationId: ClientApi_Delete
export def "client-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Id of client to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client/delete")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return client details. Activities and invoices included.
#
# GET /api/client/details
# operationId: ClientApi_Details
export def "client-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<AdditionalEmails: table<Email: string>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/client/details" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a client
#
# POST /api/client/new
# operationId: ClientApi_New
# --AdditionalEmails item shape: {Email?: string}
export def "client-new create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --additional-emails: list # Client additional emails contact for CC — item shape: {Email?: string}
  --address: string # Client business address
  --client-country-id: int # Indicates the country where the clients is from (format: int32)
  --client-currency-id: int # Indicates the default system currency used by the user for the client (format: int32)
  --company-registration-number: string # Client's Company Registration Number
  --default-due-date-in-days: int # Client custom payment terms (format: int32)
  --email: string # Client email
  --name: string # Name of the client
  --phone-number: string # Client phone numer
  --ui-language-id: int # Hold a value of the language in which the invoice will be sent (format: int32)
  --vat: string # Client's VAT number
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client/new")
  let req_body = {"AdditionalEmails": $additional_emails, "Address": $address, "ClientCountryId": $client_country_id, "ClientCurrencyId": $client_currency_id, "CompanyRegistrationNumber": $company_registration_number, "DefaultDueDateInDays": $default_due_date_in_days, "Email": $email, "Name": $name, "PhoneNumber": $phone_number, "UiLanguageId": $ui_language_id, "Vat": $vat} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update an existing client
#
# POST /api/client/update
# operationId: ClientApi_Update
# --AdditionalEmails item shape: {Email?: string}
export def "client-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-key: string
  --x-auth-secret: string
  --additional-emails: list # Client additional emails contact for CC — item shape: {Email?: string}
  --address: string # Client business address
  --client-country-id: int # Indicates the country where the clients is from (format: int32)
  --client-currency-id: int # Indicates the default system currency used by the user for the client (format: int32)
  --company-registration-number: string # Client's Company Registration Number
  --default-due-date-in-days: int # Client custom payment terms (format: int32)
  --email: string # Client email
  --id: int # Entity id (format: int32)
  --name: string # Name of the client
  --phone-number: string # Client phone numer
  --ui-language-id: int # Hold a value of the language in which the invoice will be sent (format: int32)
  --vat: string # Client's VAT number
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client/update")
  let req_body = {"AdditionalEmails": $additional_emails, "Address": $address, "ClientCountryId": $client_country_id, "ClientCurrencyId": $client_currency_id, "CompanyRegistrationNumber": $company_registration_number, "DefaultDueDateInDays": $default_due_date_in_days, "Email": $email, "Id": $id, "Name": $name, "PhoneNumber": $phone_number, "UiLanguageId": $ui_language_id, "Vat": $vat} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return all estimation for the account
#
# GET /api/estimation/all
# operationId: EstimationApi_All
export def "estimation-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClonedFromId: int, Currency: record, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Notes: string, Number: string, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.page" $query_options_page "scalar") (serialize-qp "queryOptions.pageSize" $query_options_page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/estimation/all" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Change estimation status
#
# POST /api/estimation/changestatus
# operationId: EstimationApi_ChangeStatus
export def "estimation-changestatus create-change-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Estimation Id (format: int32)
  --status: string@status-completer # New status of the estimation
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/changestatus")
  let req_body = {"Id": $id, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Convert the estimation to an invoice
#
# POST /api/estimation/convert
# operationId: EstimationApi_Convert
export def "estimation-convert create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --body: int
]: any -> record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/convert")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete an existing estimation
#
# POST /api/estimation/delete
# operationId: EstimationApi_Delete
export def "estimation-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Id of estimation to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/delete")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return estimation data
#
# GET /api/estimation/details
# operationId: EstimationApi_Details
export def "estimation-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/estimation/details" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create an estimation
#
# POST /api/estimation/new
# operationId: EstimationApi_New
# --Attachments item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Items item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
# --PaymentGateways item shape: {Name?: string}
export def "estimation-new create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --attachments: list # List of estimation attachments — item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --client-id: int # The client to whom this estimation is assigned (format: int32)
  --cloned-from-id: int # Indicate from which estimation this estimation has been cloned from (format: int32)
  --currency-id: int # Id of the currency for the estimation amounts (format: int32)
  --expires-on: string # Indicates when the estimation will be proclamed as due (format: date-time)
  --issued-on: string # Indicates when the estimation was issued (format: date-time)
  --items: list # List of estimation items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --notes: string # Internal note regarding the estimation
  --number: string # Unique estimation number
  --payment-gateways: list # List of enabled payment gateways for this estimation — item shape: {Name?: string}
  --po-number: string # Unique number generated by the buyer
  --status: string@status-completer # Indicate the status of the estimation (paid/unpaid/overdue)
  --terms: string # Terms of agreement
]: any -> record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/new")
  let req_body = {"Attachments": $attachments, "ClientId": $client_id, "ClonedFromId": $cloned_from_id, "CurrencyId": $currency_id, "ExpiresOn": $expires_on, "IssuedOn": $issued_on, "Items": $items, "Notes": $notes, "Number": $number, "PaymentGateways": $payment_gateways, "PoNumber": $po_number, "Status": $status, "Terms": $terms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Send the provided estimation to the client
#
# POST /api/estimation/sendtoclient
# operationId: EstimationApi_SendToClient
export def "estimation-sendtoclient send-to-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --attach-pdf: oneof<nothing, bool> # Should attach pdf file
  --estimation-id: int # Id of the estimation (format: int32)
  --id: int # Id of the estimation (format: int32)
  --message: string # Message to be embedded in the email
  --send-to-self: oneof<nothing, bool> # Should email copy be send to self
  --subject: string # Subject for the email
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/sendtoclient")
  let req_body = {"AttachPdf": $attach_pdf, "EstimationId": $estimation_id, "Id": $id, "Message": $message, "SendToSelf": $send_to_self, "Subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve the status of the estimation
#
# GET /api/estimation/status
# operationId: EstimationApi_Status
export def "estimation-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/estimation/status" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update an existing estimation
#
# POST /api/estimation/update
# operationId: EstimationApi_Update
# --Attachments item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Items item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Id?: int, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
# --PaymentGateways item shape: {Name?: string}
export def "estimation-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --attachments: list # List of estimation attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --client-id: int # The client to whom this estimation is assigned (format: int32)
  --cloned-from-id: int # Indicate from which estimation this estimation has been cloned from (format: int32)
  --currency-id: int # Id of the currency for the estimation amounts (format: int32)
  --expires-on: string # Indicates when the estimation will be proclamed as due (format: date-time)
  --id: int # estimation id (format: int32)
  --issued-on: string # Indicates when the estimation was issued (format: date-time)
  --items: list # List of estimation items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Id?: int, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --notes: string # Internal note regarding the estimation
  --number: string # Unique estimation number
  --payment-gateways: list # List of enabled payment gateways for this estimation — item shape: {Name?: string}
  --po-number: string # Unique number generated by the buyer
  --status: string@status-completer # Indicate the status of the estimation (paid/unpaid/overdue)
  --terms: string # Terms of agreement
]: any -> record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/estimation/update")
  let req_body = {"Attachments": $attachments, "ClientId": $client_id, "ClonedFromId": $cloned_from_id, "CurrencyId": $currency_id, "ExpiresOn": $expires_on, "Id": $id, "IssuedOn": $issued_on, "Items": $items, "Notes": $notes, "Number": $number, "PaymentGateways": $payment_gateways, "PoNumber": $po_number, "Status": $status, "Terms": $terms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return the unique url to the client's invoice
#
# GET /api/estimation/uri
# operationId: EstimationApi_Uri
export def "estimation-uri get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Link: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/estimation/uri" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Return all of the platform supported countries
#
# GET /api/general/countries
# operationId: GeneralApi_Countries
export def "general-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<Id: int, Name: string, Value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/general/countries")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Return all of the platform supported currencies
#
# GET /api/general/currencies
# operationId: GeneralApi_Currencies
export def "general-currencies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<Code: string, Id: int, Name: string, Symbol: string, Value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/general/currencies")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Return all of the platform supported Date Formats
#
# GET /api/general/dateformats
# operationId: GeneralApi_DateFormats
export def "general-dateformats get-date-formats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/general/dateformats")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Return all of the platform supported UI languages
#
# GET /api/general/uilanguages
# operationId: GeneralApi_UiLanguages
export def "general-uilanguages get-ui-languages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<Id: int, Name: string, UiCulture: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/general/uilanguages")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Return all invoices for the account
#
# GET /api/invoice/all
# operationId: InvoiceApi_All
export def "invoice-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClonedFromId: int, Currency: record, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Notes: string, Number: string, PoNumber: string, RecurringProfile: record, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.page" $query_options_page "scalar") (serialize-qp "queryOptions.pageSize" $query_options_page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/all" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<Id: int, Name: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/allcategories" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Change invoice status
#
# POST /api/invoice/changestatus
# operationId: InvoiceApi_ChangeStatus
export def "invoice-changestatus create-change-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Invoice Id (format: int32)
  --status: string@status-completer-1 # New status of the invoice
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/changestatus")
  let req_body = {"Id": $id, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete an existing invoice
#
# POST /api/invoice/delete
# operationId: InvoiceApi_Delete
export def "invoice-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Id of invoice to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/delete")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete an existing invoice category
#
# POST /api/invoice/deletecategory
export def "invoice-deletecategory create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # format: int32
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/deletecategory")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return invoice data
#
# GET /api/invoice/details
# operationId: InvoiceApi_Details
export def "invoice-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/details" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create an invoice
#
# POST /api/invoice/new
# operationId: InvoiceApi_New
# --Attachments item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Items item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
# --PaymentGateways item shape: {Name?: string}
# --RecurringProfile shape: {DayOfMonth?: int, DayOfWeek?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", DueDateInDays?: int, EndOfRecurrance?: string, Month?: int, RecurrancePattern?: "Daily"|"Weekly"|"Monthly"|"Yearly", RecurranceValue?: int, StartOfRecurrance?: string, Status?: "Pending"|"Active"|"Cancelled"|"Finished", Title?: string}
export def "invoice-new create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --attachments: list # List of invoice attachments — item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --client-id: int # The client to whom this invoice is assigned (format: int32)
  --cloned-from-id: int # Indicate from which invoice this invoice has been cloned from (format: int32)
  --currency-id: int # Id of the currency for the invoice amounts (format: int32)
  --duedate: string # Indicates when the invoice will be proclamed as due (format: date-time)
  --invoice-category-id: int # Hold the id of the invoice category (format: int32)
  --issued-on: string # Indicates when the invoice was issued (format: date-time)
  --items: list # List of invoice items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --notes: string # Internal note regarding the invoice
  --number: string # Unique invoice number
  --payment-gateways: list # List of enabled payment gateways for this invoice — item shape: {Name?: string}
  --po-number: string # Unique number generated by the buyer
  --recurring-profile: record # Definition of invoice recurring profile — shape: {DayOfMonth?: int, DayOfWeek?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", DueDateInDays?: int, EndOfRecurrance?: string, Month?: int, RecurrancePattern?: "Daily"|"Weekly"|"Monthly"|"Yearly", RecurranceValue?: int, StartOfRecurrance?: string, Status?: "Pending"|"Active"|"Cancelled"|"Finished", Title?: string}
  --recurring-profile-id: int # Hold the id of the recurring profile (format: int32)
  --should-send-reminders: oneof<nothing, bool> # Should send email reminders to client?
  --status: string@status-completer-1 # Indicate the status of the invoice (paid/unpaid/overdue)
  --terms: string # Terms of agreement
]: any -> record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/new")
  let req_body = {"Attachments": $attachments, "ClientId": $client_id, "ClonedFromId": $cloned_from_id, "CurrencyId": $currency_id, "Duedate": $duedate, "InvoiceCategoryId": $invoice_category_id, "IssuedOn": $issued_on, "Items": $items, "Notes": $notes, "Number": $number, "PaymentGateways": $payment_gateways, "PoNumber": $po_number, "RecurringProfile": $recurring_profile, "RecurringProfileId": $recurring_profile_id, "ShouldSendReminders": $should_send_reminders, "Status": $status, "Terms": $terms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create an invoice category
#
# POST /api/invoice/newcategory
export def "invoice-newcategory create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --name: string # Category name
]: any -> record<Id: int, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/newcategory")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return the PDF for the invoice
#
# GET /api/invoice/pdf
# operationId: InvoiceApi_Pdf
export def "invoice-pdf get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --signed-version: oneof<nothing, bool>
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Link: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "signedVersion" $signed_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/pdf" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Send the provided invoice to the accountant
#
# POST /api/invoice/sendtoaccountant
# operationId: InvoiceApi_SendToAccountant
export def "invoice-sendtoaccountant send-to-accountant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Id of the invoice (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/sendtoaccountant")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Send the provided invoice to the client
#
# POST /api/invoice/sendtoclient
# operationId: InvoiceApi_SendToClient
export def "invoice-sendtoclient send-to-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --attach-pdf: oneof<nothing, bool> # Should attach pdf file
  --id: int # Id of the invoice (format: int32)
  --invoice-id: int # Id of the invoice (format: int32)
  --message: string # Message to be embedded in the email
  --send-to-self: oneof<nothing, bool> # Should email copy be send to self
  --subject: string # Subject for the email
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/sendtoclient")
  let req_body = {"AttachPdf": $attach_pdf, "Id": $id, "InvoiceId": $invoice_id, "Message": $message, "SendToSelf": $send_to_self, "Subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve the status of the invoice
#
# GET /api/invoice/status
# operationId: InvoiceApi_Status
export def "invoice-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/status" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update an existing invoice
#
# POST /api/invoice/update
# operationId: InvoiceApi_Update
# --Attachments item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Items item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Id?: int, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
# --PaymentGateways item shape: {Name?: string}
# --RecurringProfile shape: {DayOfMonth?: int, DayOfWeek?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", DueDateInDays?: int, EndOfRecurrance?: string, Month?: int, RecurrancePattern?: "Daily"|"Weekly"|"Monthly"|"Yearly", RecurranceValue?: int, StartOfRecurrance?: string, Status?: "Pending"|"Active"|"Cancelled"|"Finished", Title?: string}
export def "invoice-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --attachments: list # List of invoice attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --client-id: int # The client to whom this invoice is assigned (format: int32)
  --cloned-from-id: int # Indicate from which invoice this invoice has been cloned from (format: int32)
  --currency-id: int # Id of the currency for the invoice amounts (format: int32)
  --duedate: string # Indicates when the invoice will be proclamed as due (format: date-time)
  --id: int # Invoice id (format: int32)
  --invoice-category-id: int # Hold the id of the invoice category (format: int32)
  --issued-on: string # Indicates when the invoice was issued (format: date-time)
  --items: list # List of invoice items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Id?: int, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --notes: string # Internal note regarding the invoice
  --number: string # Unique invoice number
  --payment-gateways: list # List of enabled payment gateways for this invoice — item shape: {Name?: string}
  --po-number: string # Unique number generated by the buyer
  --recurring-profile: record # Definition of invoice recurring profile — shape: {DayOfMonth?: int, DayOfWeek?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", DueDateInDays?: int, EndOfRecurrance?: string, Month?: int, RecurrancePattern?: "Daily"|"Weekly"|"Monthly"|"Yearly", RecurranceValue?: int, StartOfRecurrance?: string, Status?: "Pending"|"Active"|"Cancelled"|"Finished", Title?: string}
  --recurring-profile-id: int # Hold the id of the recurring profile (format: int32)
  --should-send-reminders: oneof<nothing, bool> # Should send email reminders to client?
  --status: string@status-completer-1 # Indicate the status of the invoice (paid/unpaid/overdue)
  --terms: string # Terms of agreement
]: any -> record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/update")
  let req_body = {"Attachments": $attachments, "ClientId": $client_id, "ClonedFromId": $cloned_from_id, "CurrencyId": $currency_id, "Duedate": $duedate, "Id": $id, "InvoiceCategoryId": $invoice_category_id, "IssuedOn": $issued_on, "Items": $items, "Notes": $notes, "Number": $number, "PaymentGateways": $payment_gateways, "PoNumber": $po_number, "RecurringProfile": $recurring_profile, "RecurringProfileId": $recurring_profile_id, "ShouldSendReminders": $should_send_reminders, "Status": $status, "Terms": $terms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update an existing invoice category
#
# POST /api/invoice/updatecategory
export def "invoice-updatecategory create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Entity id (format: int32)
  --name: string # Category name
]: any -> record<Id: int, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/invoice/updatecategory")
  let req_body = {"Id": $id, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return the unique url to the client's invoice
#
# GET /api/invoice/uri
# operationId: InvoiceApi_Uri
export def "invoice-uri get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Link: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice/uri" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Return all orders for the account
#
# GET /api/order/all
# operationId: OrderApi_All
export def "order-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, AfterPaymentDescription: string, CouponCode: string, Currency: record, CurrencyId: int, Description: string, DiscountAmount: float, Id: int, Name: string, Note: string, OrderBillingDetails: record, OrderShippingDetails: record, ProductId: int, Referral: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.page" $query_options_page "scalar") (serialize-qp "queryOptions.pageSize" $query_options_page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/order/all" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Change order shipping details
#
# POST /api/order/changeshippingdetails
# operationId: OrderApi_ChangeShippingDetails
export def "order-changeshippingdetails create-change-shipping-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
  --address: string # Client street and number
  --country-id: int # Client country id (format: int32)
  --email: string # Client email
  --name: string # Client name
  --phone-number: string # Client phone number
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $order_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/order/changeshippingdetails" $qp)
  let req_body = {"Address": $address, "CountryId": $country_id, "Email": $email, "Name": $name, "PhoneNumber": $phone_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Change order status
#
# POST /api/order/changestatus
# operationId: OrderApi_ChangeStatus
export def "order-changestatus create-change-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Order Id (format: int32)
  --reason: string # Reason for status change
  --status: string@status-completer-2 # New status of the order
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/order/changestatus")
  let req_body = {"Id": $id, "Reason": $reason, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete an existing order
#
# POST /api/order/delete
# operationId: OrderApi_Delete
export def "order-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Id of order to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/order/delete")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return order details
#
# GET /api/order/details
# operationId: OrderApi_Details
export def "order-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<AccessToken: string, AfterPaymentDescription: string, Attachments: table<Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, CouponCode: string, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, CurrencyId: int, Description: string, DiscountAmount: float, Id: int, Items: table<Cost: float, Description: string, ProductItemId: int, Quantity: float, ReferenceId: string, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Name: string, Note: string, OrderBillingDetails: record<Address: string, CountryId: int, Email: string, Name: string, PhoneNumber: string>, OrderShippingDetails: record<Address: string, CountryId: int, Email: string, Name: string, PhoneNumber: string>, ProductId: int, Referral: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/order/details" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create an order
#
# POST /api/order/new
# operationId: OrderApi_New
# --Attachments item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
# --Items item shape: {Cost?: float, Description?: string, ProductItemId?: int, Quantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
# --OrderBillingDetails shape: {Address?: string, CountryId?: int, Email?: string, Name?: string, PhoneNumber?: string}
# --OrderShippingDetails shape: {Address?: string, CountryId?: int, Email?: string, Name?: string, PhoneNumber?: string}
export def "order-new create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --after-payment-description: string # After payment description
  --attachments: list # List of Order attachments — item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --coupon-code: string # Coupon to apply in order to get the discount
  --currency-id: int # Foreign key Currency (format: int32)
  --description: string # Product description
  --discount-amount: float # Discount amount (format: double)
  --items: list # List of Order items — item shape: {Cost?: float, Description?: string, ProductItemId?: int, Quantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
  --name: string # Product alias
  --note: string # Customer note to seller
  --order-billing-details: record # shape: {Address?: string, CountryId?: int, Email?: string, Name?: string, PhoneNumber?: string}
  --order-shipping-details: record # shape: {Address?: string, CountryId?: int, Email?: string, Name?: string, PhoneNumber?: string}
  --product-id: int # Product id (format: int32)
  --referral: string # Represent the referral for this order
  --shipping-amount: float # Cost for shipping the product (format: double)
  --shipping-description: string # Client instructions for shipping
  --status: string@status-completer-2 # Order status
  --sub-total-amount: float # Sub total amount (format: double)
  --tax-amount: float # Tax amount (format: double)
  --total-amount: float # Total amount (format: double)
  --what-happens-next-description: string # What happens next description
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/order/new")
  let req_body = {"AfterPaymentDescription": $after_payment_description, "Attachments": $attachments, "CouponCode": $coupon_code, "CurrencyId": $currency_id, "Description": $description, "DiscountAmount": $discount_amount, "Items": $items, "Name": $name, "Note": $note, "OrderBillingDetails": $order_billing_details, "OrderShippingDetails": $order_shipping_details, "ProductId": $product_id, "Referral": $referral, "ShippingAmount": $shipping_amount, "ShippingDescription": $shipping_description, "Status": $status, "SubTotalAmount": $sub_total_amount, "TaxAmount": $tax_amount, "TotalAmount": $total_amount, "WhatHappensNextDescription": $what_happens_next_description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return all supported payment gateways (no currencies means all are supported)
#
# GET /api/payment/supported
# operationId: PaymentApi_Supported
export def "payment-supported get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<Name: string, SupportedCurrencies: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/payment/supported")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a payment link
#
# GET /api/paymentlink/all
# operationId: PaymentLinkApi_All
export def "paymentlink-all list-payment-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClientId: int, Currency: record, CurrencyId: int, DiscountAmount: float, Id: int, Invoice: record, Items: list, Number: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, User: record, UserId: int>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.page" $query_options_page "scalar") (serialize-qp "queryOptions.pageSize" $query_options_page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/paymentlink/all" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete an existing payment link
#
# POST /api/paymentlink/delete
# operationId: PaymentLinkApi_Delete
# --Client shape: {Address?: string, ClientCountryId?: int, ClientCurrencyId?: int, CompanyRegistrationNumber?: string, DefaultDueDateInDays?: int, Email?: string, Id?: int, Name?: string, PhoneNumber?: string, UiLanguageId?: int, UserId?: int, Vat?: string}
# --Currency shape: {Code?: string, Id?: int, Name?: string, Symbol?: string, Value?: string}
# --Invoice shape: {AccessToken?: string, Activities?: list, Attachments?: list, ClientId?: int, ClonedFromId?: int, CurrencyId?: int, DiscountAmount?: float, Duedate?: string, EnablePartialPayments?: bool, EstimationId?: int, Id?: int, InvoiceCategoryId?: int, IsDigitallySigned?: bool, IssuedOn?: string, Items?: list, Notes?: string, Number?: string, OrderId?: int, PaymentGateways?: list, PaymentLinkId?: int, Payments?: list, PoNumber?: string, RecurringProfileId?: int, ShouldSendReminders?: bool, ... (6 more fields)}
# --Items item shape: {Cost?: float, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, PaymentLinkId?: int, Quantity?: float, SubTotalAmount?: float, Tax?: record, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkType?: record, WorkTypeId?: int}
# --User shape: {ActionNotificationsLastReadOn?: string, Email?: string, ExternalConnections?: list, HasBeenOnboarded?: bool, Id?: int, IsLocked?: bool, IsVerified?: bool, KnowledgeNotificationsLastReadOn?: string, LastSeenOn?: string, Name?: string, Password?: string, PasswordSalt?: string, ReferralPath?: string, ReferredUsers?: int, ReferrerKey?: string, Settings?: record, Status?: "Normal"|"Fraudlent"|"Locked", SubscriptionPlan?: record, Type?: "Anonymous"|"Customer"|"SystemAdministrator"|"Collaborator", ... (3 more fields)}
export def "paymentlink-delete delete-payment-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --access-token: string
  --client: record # shape: {Address?: string, ClientCountryId?: int, ClientCurrencyId?: int, CompanyRegistrationNumber?: string, DefaultDueDateInDays?: int, Email?: string, Id?: int, Name?: string, PhoneNumber?: string, UiLanguageId?: int, UserId?: int, Vat?: string}
  --client-id: int # format: int32
  --currency: record # shape: {Code?: string, Id?: int, Name?: string, Symbol?: string, Value?: string}
  --currency-id: int # format: int32
  --discount-amount: float # format: double
  --id: int # format: int32
  --invoice: record # shape: {AccessToken?: string, Activities?: list, Attachments?: list, ClientId?: int, ClonedFromId?: int, CurrencyId?: int, DiscountAmount?: float, Duedate?: string, EnablePartialPayments?: bool, EstimationId?: int, Id?: int, InvoiceCategoryId?: int, IsDigitallySigned?: bool, IssuedOn?: string, Items?: list, Notes?: string, Number?: string, OrderId?: int, PaymentGateways?: list, PaymentLinkId?: int, Payments?: list, PoNumber?: string, RecurringProfileId?: int, ShouldSendReminders?: bool, ... (6 more fields)}
  --items: list # item shape: {Cost?: float, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, PaymentLinkId?: int, Quantity?: float, SubTotalAmount?: float, Tax?: record, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkType?: record, WorkTypeId?: int}
  --number: string
  --sub-total-amount: float # format: double
  --tax-amount: float # format: double
  --total-amount: float # format: double
  --user: record # shape: {ActionNotificationsLastReadOn?: string, Email?: string, ExternalConnections?: list, HasBeenOnboarded?: bool, Id?: int, IsLocked?: bool, IsVerified?: bool, KnowledgeNotificationsLastReadOn?: string, LastSeenOn?: string, Name?: string, Password?: string, PasswordSalt?: string, ReferralPath?: string, ReferredUsers?: int, ReferrerKey?: string, Settings?: record, Status?: "Normal"|"Fraudlent"|"Locked", SubscriptionPlan?: record, Type?: "Anonymous"|"Customer"|"SystemAdministrator"|"Collaborator", ... (3 more fields)}
  --user-id: int # format: int32
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/paymentlink/delete")
  let req_body = {"AccessToken": $access_token, "Client": $client, "ClientId": $client_id, "Currency": $currency, "CurrencyId": $currency_id, "DiscountAmount": $discount_amount, "Id": $id, "Invoice": $invoice, "Items": $items, "Number": $number, "SubTotalAmount": $sub_total_amount, "TaxAmount": $tax_amount, "TotalAmount": $total_amount, "User": $user, "UserId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create a payment link
#
# POST /api/paymentlink/new
# operationId: PaymentLinkApi_New
# --Client shape: {Address?: string, ClientCountryId?: int, ClientCurrencyId?: int, CompanyRegistrationNumber?: string, DefaultDueDateInDays?: int, Email?: string, Id?: int, Name?: string, PhoneNumber?: string, UiLanguageId?: int, UserId?: int, Vat?: string}
# --Currency shape: {Code?: string, Id?: int, Name?: string, Symbol?: string, Value?: string}
# --Invoice shape: {AccessToken?: string, Activities?: list, Attachments?: list, ClientId?: int, ClonedFromId?: int, CurrencyId?: int, DiscountAmount?: float, Duedate?: string, EnablePartialPayments?: bool, EstimationId?: int, Id?: int, InvoiceCategoryId?: int, IsDigitallySigned?: bool, IssuedOn?: string, Items?: list, Notes?: string, Number?: string, OrderId?: int, PaymentGateways?: list, PaymentLinkId?: int, Payments?: list, PoNumber?: string, RecurringProfileId?: int, ShouldSendReminders?: bool, ... (6 more fields)}
# --Items item shape: {Cost?: float, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, PaymentLinkId?: int, Quantity?: float, SubTotalAmount?: float, Tax?: record, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkType?: record, WorkTypeId?: int}
# --User shape: {ActionNotificationsLastReadOn?: string, Email?: string, ExternalConnections?: list, HasBeenOnboarded?: bool, Id?: int, IsLocked?: bool, IsVerified?: bool, KnowledgeNotificationsLastReadOn?: string, LastSeenOn?: string, Name?: string, Password?: string, PasswordSalt?: string, ReferralPath?: string, ReferredUsers?: int, ReferrerKey?: string, Settings?: record, Status?: "Normal"|"Fraudlent"|"Locked", SubscriptionPlan?: record, Type?: "Anonymous"|"Customer"|"SystemAdministrator"|"Collaborator", ... (3 more fields)}
export def "paymentlink-new create-payment-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --access-token: string
  --client: record # shape: {Address?: string, ClientCountryId?: int, ClientCurrencyId?: int, CompanyRegistrationNumber?: string, DefaultDueDateInDays?: int, Email?: string, Id?: int, Name?: string, PhoneNumber?: string, UiLanguageId?: int, UserId?: int, Vat?: string}
  --client-id: int # format: int32
  --currency: record # shape: {Code?: string, Id?: int, Name?: string, Symbol?: string, Value?: string}
  --currency-id: int # format: int32
  --discount-amount: float # format: double
  --id: int # format: int32
  --invoice: record # shape: {AccessToken?: string, Activities?: list, Attachments?: list, ClientId?: int, ClonedFromId?: int, CurrencyId?: int, DiscountAmount?: float, Duedate?: string, EnablePartialPayments?: bool, EstimationId?: int, Id?: int, InvoiceCategoryId?: int, IsDigitallySigned?: bool, IssuedOn?: string, Items?: list, Notes?: string, Number?: string, OrderId?: int, PaymentGateways?: list, PaymentLinkId?: int, Payments?: list, PoNumber?: string, RecurringProfileId?: int, ShouldSendReminders?: bool, ... (6 more fields)}
  --items: list # item shape: {Cost?: float, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, PaymentLinkId?: int, Quantity?: float, SubTotalAmount?: float, Tax?: record, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkType?: record, WorkTypeId?: int}
  --number: string
  --sub-total-amount: float # format: double
  --tax-amount: float # format: double
  --total-amount: float # format: double
  --user: record # shape: {ActionNotificationsLastReadOn?: string, Email?: string, ExternalConnections?: list, HasBeenOnboarded?: bool, Id?: int, IsLocked?: bool, IsVerified?: bool, KnowledgeNotificationsLastReadOn?: string, LastSeenOn?: string, Name?: string, Password?: string, PasswordSalt?: string, ReferralPath?: string, ReferredUsers?: int, ReferrerKey?: string, Settings?: record, Status?: "Normal"|"Fraudlent"|"Locked", SubscriptionPlan?: record, Type?: "Anonymous"|"Customer"|"SystemAdministrator"|"Collaborator", ... (3 more fields)}
  --user-id: int # format: int32
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/paymentlink/new")
  let req_body = {"AccessToken": $access_token, "Client": $client, "ClientId": $client_id, "Currency": $currency, "CurrencyId": $currency_id, "DiscountAmount": $discount_amount, "Id": $id, "Invoice": $invoice, "Items": $items, "Number": $number, "SubTotalAmount": $sub_total_amount, "TaxAmount": $tax_amount, "TotalAmount": $total_amount, "User": $user, "UserId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return the unique url to the client's payment link
#
# GET /api/paymentlink/uri
# operationId: PaymentLinkApi_Uri
export def "paymentlink-uri get-payment-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Link: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/paymentlink/uri" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Return all products for the account
#
# GET /api/product/all
# operationId: ProductApi_All
export def "product-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, AfterPaymentDescription: string, ButtonCallToAction: string, Currency: record, CurrencyId: int, Description: string, Id: int, IsFeatured: bool, Name: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.page" $query_options_page "scalar") (serialize-qp "queryOptions.pageSize" $query_options_page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/product/all" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete an existing product
#
# POST /api/product/delete
# operationId: ProductApi_Delete
export def "product-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Id of product to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/product/delete")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return product details
#
# GET /api/product/details
# operationId: ProductApi_Details
export def "product-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<AccessToken: string, AfterPaymentDescription: string, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, ButtonCallToAction: string, Coupons: table<Code: string, DiscountAmount: float, DiscountPercentage: float, Id: int, ValidUntil: string>, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, CurrencyId: int, Description: string, Discounts: table<DiscountAmount: float, DiscountPercentage: float, Id: int, Name: string, ValidFrom: string, ValidTo: string>, Id: int, IsFeatured: bool, Items: table<Cost: float, Description: string, Id: int, MinimumQuantity: float, ReferenceId: string, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Name: string, PaymentGateways: table<Name: string>, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/product/details" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
export def "product-new create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --after-payment-description: string # After payment description
  --attachments: list # List of product attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --button-call-to-action: string # Default button call to action Ex: Buy now, subscribe, ...
  --coupons: list # List of product coupons — item shape: {Code?: string, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, ValidUntil?: string}
  --currency-id: int # Foreign key Currency (format: int32)
  --description: string # Product description
  --discounts: list # List of product discounts — item shape: {DiscountAmount?: float, DiscountPercentage?: float, Id?: int, Name?: string, ValidFrom?: string, ValidTo?: string}
  --is-featured: oneof<nothing, bool> # Indicate that the product is set as featured
  --items: list # List of product items — item shape: {Cost?: float, Description?: string, Id?: int, MinimumQuantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
  --name: string # Product alias
  --payment-gateways: list # List of enabled payment gateways for this product — item shape: {Name?: string}
  --shipping-amount: float # Cost for shipping the product (format: double)
  --shipping-description: string # Client instructions for shipping
  --status: string@status-completer-3 # Product availability status
  --what-happens-next-description: string # What happens next description
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/product/new")
  let req_body = {"AfterPaymentDescription": $after_payment_description, "Attachments": $attachments, "ButtonCallToAction": $button_call_to_action, "Coupons": $coupons, "CurrencyId": $currency_id, "Description": $description, "Discounts": $discounts, "IsFeatured": $is_featured, "Items": $items, "Name": $name, "PaymentGateways": $payment_gateways, "ShippingAmount": $shipping_amount, "ShippingDescription": $shipping_description, "Status": $status, "WhatHappensNextDescription": $what_happens_next_description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
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
export def "product-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-key: string
  --x-auth-secret: string
  --after-payment-description: string # After payment description
  --attachments: list # List of product attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --button-call-to-action: string # Default button call to action Ex: Buy now, subscribe, ...
  --coupons: list # List of product coupons — item shape: {Code?: string, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, ValidUntil?: string}
  --currency-id: int # Foreign key Currency (format: int32)
  --description: string # Product description
  --discounts: list # List of product discounts — item shape: {DiscountAmount?: float, DiscountPercentage?: float, Id?: int, Name?: string, ValidFrom?: string, ValidTo?: string}
  --id: int # Product id (format: int32)
  --is-featured: oneof<nothing, bool> # Indicate that the product is set as featured
  --items: list # List of product items — item shape: {Cost?: float, Description?: string, Id?: int, MinimumQuantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
  --name: string # Product alias
  --payment-gateways: list # List of enabled payment gateways for this product — item shape: {Name?: string}
  --shipping-amount: float # Cost for shipping the product (format: double)
  --shipping-description: string # Client instructions for shipping
  --status: string@status-completer-3 # Product availability status
  --what-happens-next-description: string # What happens next description
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/product/update")
  let req_body = {"AfterPaymentDescription": $after_payment_description, "Attachments": $attachments, "ButtonCallToAction": $button_call_to_action, "Coupons": $coupons, "CurrencyId": $currency_id, "Description": $description, "Discounts": $discounts, "Id": $id, "IsFeatured": $is_featured, "Items": $items, "Name": $name, "PaymentGateways": $payment_gateways, "ShippingAmount": $shipping_amount, "ShippingDescription": $shipping_description, "Status": $status, "WhatHappensNextDescription": $what_happens_next_description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return all taxes for the account
#
# GET /api/tax/all
# operationId: TaxApi_All
export def "tax-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<CreatedOn: string, Id: int, Name: string, Percentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tax/all")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete an existing tax
#
# POST /api/tax/delete
# operationId: TaxApi_Delete
export def "tax-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Id of tax to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tax/delete")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create a tax
#
# POST /api/tax/new
# operationId: TaxApi_New
export def "tax-new create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --name: string # Name of the task
  --percentage: float # Task percentage. Ex: 18% (format: double)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tax/new")
  let req_body = {"Name": $name, "Percentage": $percentage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update an existing tax
#
# POST /api/tax/update
# operationId: TaxApi_Update
export def "tax-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Entity id (format: int32)
  --name: string # Name of the task
  --percentage: float # Task percentage. Ex: 18% (format: double)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tax/update")
  let req_body = {"Id": $id, "Name": $name, "Percentage": $percentage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return all work types for the account
#
# GET /api/worktype/all
# operationId: WorkTypeApi_All
export def "worktype-all list-work-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<CreatedOn: string, Id: int, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/worktype/all")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete an existing work type
#
# POST /api/worktype/delete
# operationId: WorkTypeApi_Delete
export def "worktype-delete delete-work-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Id of work type to be deleted (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/worktype/delete")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return work type details
#
# GET /api/worktype/details
# operationId: WorkTypeApi_Details
export def "worktype-details get-work-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --work-type-id: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> record<CreatedOn: string, Id: int, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workTypeId" $work_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/worktype/details" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a work type
#
# POST /api/worktype/new
# operationId: WorkTypeApi_New
export def "worktype-new create-work-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string
  --x-auth-secret: string
  --title: string # Indicates the title of of the work type (Logo design, development...)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/worktype/new")
  let req_body = {"Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Return all work types for the account that match the query param
#
# GET /api/worktype/search
# operationId: WorkTypeApi_Search
export def "worktype-search list-work-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-query: string
  --query-options-order-by: string
  --query-options-order: string@query-options-order-completer
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string
  --x-auth-secret: string
]: nothing -> table<CreatedOn: string, Id: int, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryOptions.query" $query_options_query "scalar") (serialize-qp "queryOptions.orderBy" $query_options_order_by "scalar") (serialize-qp "queryOptions.order" $query_options_order "scalar") (serialize-qp "queryOptions.page" $query_options_page "scalar") (serialize-qp "queryOptions.pageSize" $query_options_page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/worktype/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update an existing work type
#
# POST /api/worktype/update
# operationId: WorkTypeApi_Update
export def "worktype-update update-work-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-key: string
  --x-auth-secret: string
  --id: int # Entity id (format: int32)
  --title: string # Indicates the title of of the work type (Logo design, development...)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/worktype/update")
  let req_body = {"Id": $id, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-auth-key": $x_auth_key, "x-auth-secret": $x_auth_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
