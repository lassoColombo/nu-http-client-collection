# Auto-generated client for Lifetime ISA v2.0
# Source: https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/lisa-api/2.0/oas/resolved
# Auth: --token flag or $env.LIFETIME_ISA_TOKEN

const BASE_URL = "https://test-api.service.hmrc.gov.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LIFETIME_ISA_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://test-api.service.hmrc.gov.uk" "https://api.service.hmrc.gov.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Accept-completer [] { ["application/vnd.hmrc.2.0+json"] }
def Content-Type-completer [] { ["application/json"] }
def creationReason-completer [] { ["Current year funds transferred" "New" "Previous year funds transferred" "Transferred"] }
def accountClosureReason-completer [] { ["All funds withdrawn" "Cancellation"] }
def eventType-completer [] { ["LISA Investor Death" "LISA Investor Terminal Ill Health"] }
def eventType-completer-1 [] { ["Extension one" "Extension two"] }
def propertyPurchaseResult-completer [] { ["Purchase completed" "Purchase failed"] }
def withdrawalReason-completer [] { ["Regular withdrawal" "Superseded withdrawal"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "lifetime-isa-manager get" } } | get name | first)
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

# Get a list of all available endpoints
#
# GET /lifetime-isa/manager/{lisaManagerReferenceNumber}
# operationId: getListOfAllAvailableEndpoints
export def "lifetime-isa-manager get" [
  lisaManagerReferenceNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
]: nothing -> record<lisaManagerReferenceNumber: string, _links: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a LISA investor
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/investors
# operationId: createLisaInvestor
export def "lifetime-isa-manager-investors createLisaInvestor" [
  lisaManagerReferenceNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  investorNINO: string # The investor’s National Insurance number. (e.g. BC123456D)
  firstName: string # The investor’s first name. (e.g. FirstName)
  lastName: string # The investor’s last name. (e.g. LastName)
  dateOfBirth: string # The investor’s date of birth. This cannot be in the future. (e.g. 1989-04-22)
]: any -> record<status: float, success: bool, data: record<message: string, investorId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/investors")
  let body = {investorNINO: $investorNINO, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or transfer a LISA account
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts
# operationId: createOrTransferLisaAccount
# --transferAccount shape: {transferredFromAccountId: string, transferredFromLMRN: string, transferInDate: string}
export def "lifetime-isa-manager-accounts createOrTransferLisaAccount" [
  lisaManagerReferenceNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  investorId: string # The investor’s ID reference number. (e.g. 1234567890)
  accountId: string # The provider’s own unique reference number for the investor’s LISA account. (e.g. AB9876543210)
  creationReason: string@creationReason-completer # The reason the account was created.
  firstSubscriptionDate: string # The date of the first deposit into the account - if this is a transfer, use the date of deposit into the account managed by the previous provider. This cannot be in the future. (e.g. 2017-04-20)
  --transferAccount: record # If the creationReason is ‘Transferred’, 'Current year funds transferred', or 'Previous year funds transferred', then this is required. — shape: {transferredFromAccountId: string, transferredFromLMRN: string, transferInDate: string}
]: any -> record<status: float, success: bool, data: record<message: string, accountId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts")
  let body = {investorId: $investorId, accountId: $accountId, creationReason: $creationReason, firstSubscriptionDate: $firstSubscriptionDate, transferAccount: $transferAccount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reinstate a LISA account
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/reinstate-account
# operationId: reinstateLisaAccount
export def "lifetime-isa-manager-accounts-reinstate-account reinstateLisaAccount" [
  lisaManagerReferenceNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  accountId: string # The provider’s own unique reference number for the investor’s LISA account. (e.g. AB9876543210)
]: any -> record<status: float, success: bool, data: record<message: string, accountId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/reinstate-account")
  let body = {accountId: $accountId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get account details
#
# GET /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}
# operationId: getAccountDetails
export def "lifetime-isa-manager-accounts get" [
  lisaManagerReferenceNumber: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
]: nothing -> record<investorId: string, accountId: string, creationReason: string, firstSubscriptionDate: string, accountStatus: string, subscriptionStatus: string, accountClosureReason: string, closureDate: string, transferAccount: record<transferredFromAccountId: string, transferredFromLMRN: string, transferInDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close an existing LISA account
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/close-account
# operationId: closeExistingLisaAccount
export def "lifetime-isa-manager-accounts-close-account closeExistingLisaAccount" [
  lisaManagerReferenceNumber: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  accountClosureReason: string@accountClosureReason-completer # The reason the account was closed.
  closureDate: string # The date the account was closed. This cannot be in the future. (e.g. 2017-05-20)
]: any -> record<status: float, success: bool, data: record<message: string, accountId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/close-account")
  let body = {accountClosureReason: $accountClosureReason, closureDate: $closureDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modify date of first subscription of a LISA account
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/update-subscription
# operationId: modifyDateOfFirstSubscriptionOfLisaAccount
export def "lifetime-isa-manager-accounts-update-subscription modifyDateOfFirstSubscriptionOfLisaAccount" [
  lisaManagerReferenceNumber: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  firstSubscriptionDate: string # The date of the first deposit into the account - if this is a transfer, use the date of deposit into the account managed by the previous provider. This cannot be in the future. (e.g. 2017-05-20)
]: any -> record<status: float, success: bool, data: record<code: string, message: string, accountId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/update-subscription")
  let body = {firstSubscriptionDate: $firstSubscriptionDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Report a death or terminal illness
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/events
# operationId: reportDeathOrTerminalIllness
export def "lifetime-isa-manager-accounts-events reportDeathOrTerminalIllness" [
  lisaManagerReferenceNumber: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  eventType: string@eventType-completer # The event that has occurred and triggers eligibility for the bonus payment.
  eventDate: string # e.g. 2017-05-20
]: any -> record<status: float, success: bool, data: record<message: string, lifeEventId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/events")
  let body = {eventType: $eventType, eventDate: $eventDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send an annual return of information
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/events/annual-returns
# operationId: sendAnnualReturnOfInformation
# --supersede shape: {originalLifeEventId: string, originalEventDate: string}
export def "lifetime-isa-manager-accounts-events-annual-returns sendAnnualReturnOfInformation" [
  lisaManagerReferenceNumber: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  eventDate: string # The date the return of information is sent. This cannot be in the future. (e.g. 2018-03-31)
  lisaManagerName: string # The name of the LISA provider. (e.g. Company Name)
  taxYear: int # The tax year for the return of information. You cannot give the current tax year. You can only send a return of information for a previous tax year. Give the year that the tax year ends in. For example, for the 2017 to 2018 tax year give 2018. (format: int32, e.g. 2018)
  marketValueCash: int # The total value of the cash LISA account. Give the value to the nearest whole pound. Do not include decimal places. For example, send 54.56 as 55. If you give a value for marketValueCash, give a value of 0 for marketValueStocksAndShares and annualSubsStocksAndShares. (format: int32, e.g. 1000)
  marketValueStocksAndShares: int # The total value of the stocks and shares LISA account. Give the value to the nearest whole pound. Do not include decimal places. For example, send 54.56 as 55. If you give a value for marketValueStocksAndShares, give a value of 0 for marketValueCash and annualSubsCash. (format: int32, e.g. 1000)
  annualSubsCash: int # The total value of subscriptions that the investor deposited into their cash LISA account during the tax year. Give the value to the nearest whole pound. Do not include decimal places. For example, send 54.56 as 55. If you give a value for annualSubsCash, give a value of 0 for marketValueStocksAndShares and annualSubsStocksAndShares. (format: int32, e.g. 100)
  annualSubsStocksAndShares: int # The total value of subscriptions that the investor deposited into their stocks and shares LISA account during the tax year. Give the value to the nearest whole pound. Do not include decimal places. For example, send 54.56 as 55. If you give a value for annualSubsStocksAndShares, give a value of 0 for marketValueCash and annualSubsCash. (format: int32, e.g. 100)
  --supersede: record # Correct an existing return of information. — shape: {originalLifeEventId: string, originalEventDate: string}
]: any -> record<status: float, success: bool, data: record<message: string, lifeEventId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/events/annual-returns")
  let body = {eventDate: $eventDate, lisaManagerName: $lisaManagerName, taxYear: $taxYear, marketValueCash: $marketValueCash, marketValueStocksAndShares: $marketValueStocksAndShares, annualSubsCash: $annualSubsCash, annualSubsStocksAndShares: $annualSubsStocksAndShares, supersede: $supersede} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request the release of funds to buy a property
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/events/fund-releases
# operationId: requestReleaseOfFundsToBuyProperty
# --propertyDetails shape: {nameOrNumber: string, postalCode: string}
# --supersede shape: {originalLifeEventId: string, originalEventDate: string}
export def "lifetime-isa-manager-accounts-events-fund-releases requestReleaseOfFundsToBuyProperty" [
  lisaManagerReferenceNumber: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  eventDate: string # This is the date of the request to release funds. This cannot be in the future. (e.g. 2017-05-06)
  withdrawalAmount: float # This is the amount that the investor has withdrawn from the LISA account. You can include a value up to 2 decimal places.
  --conveyancerReference: string # This is the reference for the conveyancer involved with the property purchase. (e.g. CR12345-6789)
  --propertyDetails: record # The details of the property that you are requesting funds to buy. — shape: {nameOrNumber: string, postalCode: string}
  --supersede: record # Correct an existing fund release with a new eventDate and withdrawalAmount. — shape: {originalLifeEventId: string, originalEventDate: string}
]: any -> record<status: float, success: bool, data: record<message: string, lifeEventId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/events/fund-releases")
  let body = {eventDate: $eventDate, withdrawalAmount: $withdrawalAmount, conveyancerReference: $conveyancerReference, propertyDetails: $propertyDetails, supersede: $supersede} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request a property purchase extension
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/events/purchase-extensions
# operationId: requestPropertyPurchaseExtension
# --supersede shape: {originalLifeEventId: string, originalEventDate: string}
export def "lifetime-isa-manager-accounts-events-purchase-extensions requestPropertyPurchaseExtension" [
  lisaManagerReferenceNumber: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --fundReleaseId: string # The reference number you get when you report a fund release. Must not be provided when correcting an existing extension. (e.g. 3456789000)
  eventDate: string # The date the extension is requested. This cannot be in the future. (e.g. 2017-05-10)
  eventType: string@eventType-completer-1 # The type of extension.
  --supersede: record # Correct an existing extension. — shape: {originalLifeEventId: string, originalEventDate: string}
]: any -> record<status: float, success: bool, data: record<message: string, lifeEventId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/events/purchase-extensions")
  let body = {fundReleaseId: $fundReleaseId, eventDate: $eventDate, eventType: $eventType, supersede: $supersede} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Report the outcome of a property purchase
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/events/purchase-outcomes
# operationId: reportOutcomeOfPropertyPurchase
# --supersede shape: {originalLifeEventId: string, originalEventDate: string}
export def "lifetime-isa-manager-accounts-events-purchase-outcomes reportOutcomeOfPropertyPurchase" [
  lisaManagerReferenceNumber: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --fundReleaseId: string # The reference number you get when you report a fund release. Must not be provided when correcting an existing purchase outcome. (e.g. 0987654321)
  eventDate: string # The date the outcome of the property purchase was known. This cannot be in the future. (e.g. 2017-05-06)
  propertyPurchaseResult: string@propertyPurchaseResult-completer # Whether a property purchase was completed or failed.
  --propertyPurchaseValue: float # The value of the property that the investor purchased. Only include this information if the purchase was completed. You can include an amount up to 2 decimal places.
  --supersede: record # Correct an existing purchase outcome. — shape: {originalLifeEventId: string, originalEventDate: string}
]: any -> record<status: float, success: bool, data: record<message: string, lifeEventId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/events/purchase-outcomes")
  let body = {fundReleaseId: $fundReleaseId, eventDate: $eventDate, propertyPurchaseResult: $propertyPurchaseResult, propertyPurchaseValue: $propertyPurchaseValue, supersede: $supersede} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# View a life event
#
# GET /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/events/{lifeEventId}
# operationId: viewLifeEvent
export def "lifetime-isa-manager-accounts-events viewLifeEvent" [
  lisaManagerReferenceNumber: string
  accountId: string
  lifeEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
]: nothing -> table<lifeEventId: string, eventType: string, eventDate: string, lisaManagerName: string, taxYear: int, marketValueCash: int, marketValueStocksAndShares: int, annualSubsCash: int, annualSubsStocksAndShares: int, withdrawalAmount: float, conveyancerReference: string, propertyDetails: record<nameOrNumber: string, postalCode: string>, fundReleaseId: string, propertyPurchaseValue: float, propertyPurchaseResult: string, supersede: record<originalLifeEventId: string, originalEventDate: string>, supersededBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/events/($lifeEventId)")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Report a withdrawal charge
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/withdrawal-charges
# operationId: reportWithdrawalCharge
# --supersede shape: {originalTransactionId: string, originalWithdrawalChargeAmount: float, transactionResult: float, reason: "Additional withdrawal"|"Withdrawal reduction"|"Withdrawal refund"}
export def "lifetime-isa-manager-accounts-withdrawal-charges reportWithdrawalCharge" [
  lisaManagerReferenceNumber: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  claimPeriodStartDate: string # This is the start date of the claim period for the withdrawal charge. It must be the sixth day of the month. You cannot enter a date in the future. (e.g. 2018-01-06)
  claimPeriodEndDate: string # This is the end date of the claim period for the withdrawal charge. It must be the fifth day of the month. It has to be the month after the claimPeriodStartDate. (e.g. 2018-02-05)
  withdrawalAmount: float # This is the amount that the investor has withdrawn from the LISA account.  You can include a value up to 2 decimal places.
  withdrawalChargeAmount: float # This is the amount charged for the withdrawal. You can include a value up to 2 decimal places. If there is a charge made during withdrawal, withdrawalChargeAmount and automaticRecoveryAmount must be the same.
  withdrawalChargeAmountYTD: float # This is the total value of withdrawal charges reported to HMRC for the current tax year to date. You can include a value up to 2 decimal places.
  --fundsDeductedDuringWithdrawal: string@bool-completer # This confirms if the investor was charged and funds were deducted at the time of the withdrawal.
  withdrawalReason: string@withdrawalReason-completer # This is used by HMRC to decide how the withdrawal charge is processed.
  --automaticRecoveryAmount: float # This is the amount HMRC can collect from the LISA manager when a withdrawal charge is due from the investor. This cannot be greater than the withdrawalChargeAmount. If there are no funds available, this value must be 0. If there is a charge made during withdrawal, automaticRecoveryAmount and withdrawalChargeAmount must be the same.
  --supersede: record # Correct an existing withdrawal charge. You can request an additional charge, reduce a charge, or refund a charge. — shape: {originalTransactionId: string, originalWithdrawalChargeAmount: float, transactionResult: float, reason: "Additional withdrawal"|"Withdrawal reduction"|"Withdrawal refund"}
]: any -> record<status: float, success: bool, data: record<message: string, transactionId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/withdrawal-charges")
  let body = {claimPeriodStartDate: $claimPeriodStartDate, claimPeriodEndDate: $claimPeriodEndDate, withdrawalAmount: $withdrawalAmount, withdrawalChargeAmount: $withdrawalChargeAmount, withdrawalChargeAmountYTD: $withdrawalChargeAmountYTD, fundsDeductedDuringWithdrawal: $fundsDeductedDuringWithdrawal, withdrawalReason: $withdrawalReason, automaticRecoveryAmount: $automaticRecoveryAmount, supersede: $supersede} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get details of a withdrawal charge
#
# GET /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/withdrawal-charges/{transactionId}
# operationId: getDetailsOfWithdrawalCharge
export def "lifetime-isa-manager-accounts-withdrawal-charges get" [
  lisaManagerReferenceNumber: string
  accountId: string
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
]: nothing -> record<claimPeriodStartDate: string, claimPeriodEndDate: string, automaticRecoveryAmount: float, withdrawalAmount: float, withdrawalChargeAmount: float, withdrawalChargeAmountYTD: float, fundsDeductedDuringWithdrawal: bool, withdrawalReason: string, supersededBy: string, supersede: record<originalTransactionId: string, originalWithdrawalChargeAmount: float, transactionResult: float, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/withdrawal-charges/($transactionId)")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request a bonus payment
#
# POST /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/transactions
# operationId: requestBonusPayment
# --htbTransfer shape: {htbTransferInForPeriod: float, htbTransferTotalYTD: float}
# --inboundPayments shape: {newSubsForPeriod?: float, newSubsYTD: float, totalSubsForPeriod: float, totalSubsYTD: float}
# --bonuses shape: {bonusDueForPeriod: float, totalBonusDueYTD: float, bonusPaidYTD?: float, claimReason: "Life Event"|"Regular Bonus"|"Superseded Bonus"}
# --supersede shape: {automaticRecoveryAmount?: float, originalTransactionId: string, originalBonusDueForPeriod: float, transactionResult: float, reason: "Bonus recovery"|"Additional bonus"}
export def "lifetime-isa-manager-accounts-transactions requestBonusPayment" [
  lisaManagerReferenceNumber: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --lifeEventId: string # The reference number you get when you report a life event. (e.g. 0987654321)
  periodStartDate: string # The first date in the claim period. The periodStartDate must be the 6th day of the month. You cannot enter a date in the future for periodStartDate. (e.g. 2017-05-06)
  periodEndDate: string # The end date of the claim period. The periodEndDate must be the 5th day of the month. It has to be the month after the periodStartDate. (e.g. 2017-06-05)
  --htbTransfer: record # Details about Help to Buy funds. — shape: {htbTransferInForPeriod: float, htbTransferTotalYTD: float}
  inboundPayments: record # Details about qualifying deposits and account balance. — shape: {newSubsForPeriod?: float, newSubsYTD: float, totalSubsForPeriod: float, totalSubsYTD: float}
  bonuses: record # Bonus payment details. — shape: {bonusDueForPeriod: float, totalBonusDueYTD: float, bonusPaidYTD?: float, claimReason: "Life Event"|"Regular Bonus"|"Superseded Bonus"}
  --supersede: record # Correct an existing bonus claim with an additional bonus or a recovery of an overpaid amount. — shape: {automaticRecoveryAmount?: float, originalTransactionId: string, originalBonusDueForPeriod: float, transactionResult: float, reason: "Bonus recovery"|"Additional bonus"}
]: any -> record<status: float, success: bool, data: record<message: string, transactionId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/transactions")
  let body = {lifeEventId: $lifeEventId, periodStartDate: $periodStartDate, periodEndDate: $periodEndDate, htbTransfer: $htbTransfer, inboundPayments: $inboundPayments, bonuses: $bonuses, supersede: $supersede} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get details of a bonus request
#
# GET /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/transactions/{transactionId}
# operationId: getDetailsOfBonusRequest
export def "lifetime-isa-manager-accounts-transactions get" [
  lisaManagerReferenceNumber: string
  accountId: string
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
]: nothing -> record<lifeEventId: string, periodStartDate: string, periodEndDate: string, htbTransfer: record<htbTransferInForPeriod: float, htbTransferTotalYTD: float>, inboundPayments: record<newSubsForPeriod: float, newSubsYTD: float, totalSubsForPeriod: float, totalSubsYTD: float>, bonuses: record<bonusDueForPeriod: float, totalBonusDueYTD: float, bonusPaidYTD: float, claimReason: string>, supersededBy: string, supersede: record<automaticRecoveryAmount: float, originalTransactionId: string, originalBonusDueForPeriod: float, transactionResult: float, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/transactions/($transactionId)")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the payment details for a bonus claim or withdrawal charge
#
# GET /lifetime-isa/manager/{lisaManagerReferenceNumber}/accounts/{accountId}/transactions/{transactionId}/payments
# operationId: getPaymentDetailsForBonusClaimOrWithdrawalCharge
export def "lifetime-isa-manager-accounts-transactions-payments get" [
  lisaManagerReferenceNumber: string
  accountId: string
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
]: nothing -> record<transactionId: string, transactionType: string, paymentDate: string, paymentDueDate: string, paymentStatus: string, paymentReference: string, paymentAmount: float, supersededBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/accounts/($accountId)/transactions/($transactionId)/payments")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all payments and debts in a date range
#
# GET /lifetime-isa/manager/{lisaManagerReferenceNumber}/payments
# operationId: getListOfAllPaymentsAndDebtsInDateRange
export def "lifetime-isa-manager-payments get" [
  lisaManagerReferenceNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # The first date in the claim period you want to search. This must be the 6th day of the month. This cannot be before 6 April 2017. (e.g. 2017-05-06)
  --endDate: string # The last date of the claim period you want to search. This must be the 5th day of the month. This cannot be in the future, before the startDate, or more than a year after the startDate. It must be at least one month after the startDate. (e.g. 2017-06-05)
  --Accept: string@Accept-completer # Specifies the response format and the [version](/api-documentation/docs/reference-guide#versioning) of the API to be used.
  --Authorization: string # An [OAuth 2.0 Bearer Token](/api-documentation/docs/authorisation/user-restricted-endpoints) with appropriate scope. (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
]: nothing -> record<lisaManagerReferenceNumber: string, payments: table<transactionType: string, status: string, paymentAmount: float, paymentReference: string, paymentDate: string, dueDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lifetime-isa/manager/($lisaManagerReferenceNumber)/payments" $qp)
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
