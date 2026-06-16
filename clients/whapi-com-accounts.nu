# Auto-generated client for Accounts API v2.0.0
# Source: https://api.apis.guru/v2/specs/whapi.com/accounts/2.0.0/swagger.json
# Auth: --token flag or $env.ACCOUNTS_API_TOKEN

const BASE_URL = "https://sandbox.whapi.com/v2/accounts"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACCOUNTS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://sandbox.whapi.com/v2/accounts"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get" } } | get name | first)
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

# Retrieves details of a customers account
#
# GET /account
# operationId: getDetails
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --languageAsPerTerritory: string # Defines response field name language, true (default) returns in language defined by territory, false returns in English (default: true)
  --apiKey: string # A unique identifier of your application that is generated by the API portal.
  --apiSecret: string # Another unique identifier for your application.
  --apiTicket: string # Ticket Granting Ticket obtained from a previous request
  --territory: string # Territory from which request originates
]: nothing -> record<accountId: string, accountNum: string, additionalSystemStatuses: string, birthPlace: string, city: string, contactable: bool, country: string, countryCode: string, county: string, currencyCode: string, customerId: string, email: string, fax: string, firstName: string, flags: table<flagName: string, flagReason: string, flagValue: string>, ipAddress: string, language: string, lastLogin: string, lastName: string, mobile: string, nif: string, office: string, partnerContactable: bool, postcode: string, secondLastName: string, status: string, street1: string, street2: string, street3: string, terms_and_conditions: string, timeZone: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "languageAsPerTerritory" $languageAsPerTerritory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account" $qp)
  let extra_headers = {"apiKey": $apiKey, "apiSecret": $apiSecret, "apiTicket": $apiTicket, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a customers account balance
#
# GET /account/balance
# operationId: getBalance
export def "account-balance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --languageAsPerTerritory: string # Defines response field name language, true (default) returns in language defined by territory, false returns in English (default: true)
  --apiKey: string # A unique identifier of your application that is generated by the API portal.
  --apiSecret: string # Another unique identifier for your application.
  --apiTicket: string # Ticket Granting Ticket obtained from a previous request
  --territory: string # Territory from which request originates
]: nothing -> record<availableFunds: float, balance: float, currencyCode: string, withdrawableFunds: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "languageAsPerTerritory" $languageAsPerTerritory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/balance" $qp)
  let extra_headers = {"apiKey": $apiKey, "apiSecret": $apiSecret, "apiTicket": $apiTicket, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets a flag based on name to value provided for the user.
#
# POST /account/flags
# operationId: setAccountFlags
export def "account-flags setAccountFlags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --languageAsPerTerritory: string # Defines response field name language, true (default) returns in language defined by territory, false returns in English (default: true)
  --apiKey: string # A unique identifier of your application that is generated by the API portal.
  --apiSecret: string # Another unique identifier for your application.
  --apiTicket: string # Ticket Granting Ticket obtained from a previous request
  --apiCountryCode: string # A two-character ISO 3166-1-Alpha-2 code representing the country API to use.
  --territory: string # Territory from which request originates
  --body: record
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languageAsPerTerritory" $languageAsPerTerritory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/flags" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey, "apiSecret": $apiSecret, "apiTicket": $apiTicket, "apiCountryCode": $apiCountryCode, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a customer's account payments
#
# GET /account/payments
# operationId: getPayments
export def "account-payments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number to return (Used with pageSize) (default: 1)
  --pageSize: float # Specify the number of results to return per page. (default: 100)
  --dateFrom: string # The FROM datetime from payments to be returned. (yyyy-MM-ddTHH:mm:ss)
  --dateTo: string # The TO datetime for payments to be returned. (yyyy-MM-ddTHH:mm:ss)
  --qp-sort: string # The order the response will be retuned by. i.e. date,desc (default: date,asc)
  --transactionType: string # Allows the user to select with they want to see withdrawls or deposits. If it is omitted from the query both types will be returned
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --languageAsPerTerritory: string # Defines response field name language, true (default) returns in language defined by territory, false returns in English (default: true)
  --apiKey: string # A unique identifier of your application that is generated by the API portal.
  --apiSecret: string # Another unique identifier for your application.
  --apiTicket: string # Ticket Granting Ticket obtained from a previous request
  --territory: string # Territory from which request originates
]: nothing -> record<payments: table<action: string, amount: float, channel: string, commision: float, id: string, ipAddress: string, methodId: string, paymentDateTime: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "transactionType" $transactionType "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "languageAsPerTerritory" $languageAsPerTerritory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/payments" $qp)
  let extra_headers = {"apiKey": $apiKey, "apiSecret": $apiSecret, "apiTicket": $apiTicket, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a customer's plus card details if they exist.
#
# GET /account/plusCard
# operationId: getPlusCardDetails
export def "account-plus-card get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --apiKey: string # A unique identifier of your application that is generated by the API portal.
  --apiSecret: string # Another unique identifier for your application.
  --apiTicket: string # Ticket Granting Ticket obtained from a previous request
]: nothing -> record<card: record<blocked: bool, cardNumber: string>, onlineAccount: record<name: string, onlineAccountNumber: string>, phone: record<phoneNumber: string>, pin: record<attemptsRemaining: float, blocked: bool>, retailAccount: record<selfExcluded: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/account/plusCard" $qp)
  let extra_headers = {"apiKey": $apiKey, "apiSecret": $apiSecret, "apiTicket": $apiTicket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets a customer's plus card as Lost/Stolen
#
# POST /account/plusCard/lostStolen
# operationId: setLostStolen
export def "account-plus-card-lost-stolen setLostStolen" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # A unique identifier of your application that is generated by the API portal.
  --apiSecret: string # Another unique identifier for your application.
  --apiTicket: string # Ticket Granting Ticket obtained from a previous request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/plusCard/lostStolen")
  let extra_headers = {"apiKey": $apiKey, "apiSecret": $apiSecret, "apiTicket": $apiTicket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets a customer's plus card phone number
#
# POST /account/plusCard/phone/{oldPhoneNumber}
# operationId: setPhoneNumber
export def "account-plus-card-phone setPhoneNumber" [
  oldPhoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # A unique identifier of your application that is generated by the API portal.
  --apiSecret: string # Another unique identifier for your application.
  --apiTicket: string # Ticket Granting Ticket obtained from a previous request
  --phoneNumber: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/plusCard/phone/($oldPhoneNumber)")
  let body = {phoneNumber: $phoneNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey, "apiSecret": $apiSecret, "apiTicket": $apiTicket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets a customer's plus card pin
#
# POST /account/plusCard/pin
# operationId: setPin
export def "account-plus-card-pin setPin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # A unique identifier of your application that is generated by the API portal.
  --apiSecret: string # Another unique identifier for your application.
  --apiTicket: string # Ticket Granting Ticket obtained from a previous request
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/plusCard/pin")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey, "apiSecret": $apiSecret, "apiTicket": $apiTicket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a customer's plus card pin
#
# PUT /account/plusCard/pin
# operationId: updatePin
export def "account-plus-card-pin updatePin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # A unique identifier of your application that is generated by the API portal.
  --apiSecret: string # Another unique identifier for your application.
  --apiTicket: string # Ticket Granting Ticket obtained from a previous request
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/plusCard/pin")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey, "apiSecret": $apiSecret, "apiTicket": $apiTicket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
