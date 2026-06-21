# Auto-generated client for Accounts API v2.0.0
# Source: https://api.apis.guru/v2/specs/whapi.com/accounts/2.0.0/swagger.json
# Auth: --token flag or $env.ACCOUNTS_API_TOKEN

const BASE_URL = "https://sandbox.whapi.com/v2/accounts"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACCOUNTS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://sandbox.whapi.com/v2/accounts"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get-details" } } | get name | first)
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
export def "account get-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --language-as-per-territory: string # Defines response field name language, true (default) returns in language defined by territory, false returns in English (default: true)
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # Ticket Granting Ticket obtained from a previous request
  --territory: string # Territory from which request originates
]: nothing -> record<accountId: string, accountNum: string, additionalSystemStatuses: string, birthPlace: string, city: string, contactable: bool, country: string, countryCode: string, county: string, currencyCode: string, customerId: string, email: string, fax: string, firstName: string, flags: table<flagName: string, flagReason: string, flagValue: string>, ipAddress: string, language: string, lastLogin: string, lastName: string, mobile: string, nif: string, office: string, partnerContactable: bool, postcode: string, secondLastName: string, status: string, street1: string, street2: string, street3: string, terms_and_conditions: string, timeZone: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "languageAsPerTerritory" $language_as_per_territory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "include": $include, "exclude": $exclude, "languageAsPerTerritory": $language_as_per_territory} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --language-as-per-territory: string # Defines response field name language, true (default) returns in language defined by territory, false returns in English (default: true)
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # Ticket Granting Ticket obtained from a previous request
  --territory: string # Territory from which request originates
]: nothing -> record<availableFunds: float, balance: float, currencyCode: string, withdrawableFunds: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "languageAsPerTerritory" $language_as_per_territory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/balance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "include": $include, "exclude": $exclude, "languageAsPerTerritory": $language_as_per_territory} | compact), body: null}
}

# Sets a flag based on name to value provided for the user.
#
# POST /account/flags
# operationId: setAccountFlags
export def "account-flags update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language-as-per-territory: string # Defines response field name language, true (default) returns in language defined by territory, false returns in English (default: true)
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # Ticket Granting Ticket obtained from a previous request
  --api-country-code: string # A two-character ISO 3166-1-Alpha-2 code representing the country API to use.
  --territory: string # Territory from which request originates
  --body: list
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languageAsPerTerritory" $language_as_per_territory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/flags" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket, "apiCountryCode": $api_country_code, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"languageAsPerTerritory": $language_as_per_territory} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number to return (Used with pageSize) (default: 1)
  --page-size: float # Specify the number of results to return per page. (default: 100)
  --date-from: string # The FROM datetime from payments to be returned. (yyyy-MM-ddTHH:mm:ss)
  --date-to: string # The TO datetime for payments to be returned. (yyyy-MM-ddTHH:mm:ss)
  --qp-sort: string # The order the response will be retuned by. i.e. date,desc (default: date,asc)
  --transaction-type: string # Allows the user to select with they want to see withdrawls or deposits. If it is omitted from the query both types will be returned
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --language-as-per-territory: string # Defines response field name language, true (default) returns in language defined by territory, false returns in English (default: true)
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # Ticket Granting Ticket obtained from a previous request
  --territory: string # Territory from which request originates
]: nothing -> record<payments: table<action: string, amount: float, channel: string, commision: float, id: string, ipAddress: string, methodId: string, paymentDateTime: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "dateFrom" $date_from "scalar") (serialize-qp "dateTo" $date_to "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "transactionType" $transaction_type "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "languageAsPerTerritory" $language_as_per_territory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size, "dateFrom": $date_from, "dateTo": $date_to, "sort": $qp_sort, "transactionType": $transaction_type, "fields": $fields, "include": $include, "exclude": $exclude, "languageAsPerTerritory": $language_as_per_territory} | compact), body: null}
}

# Gets a customer's plus card details if they exist.
#
# GET /account/plusCard
# operationId: getPlusCardDetails
export def "account-plus-card get-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # Ticket Granting Ticket obtained from a previous request
]: nothing -> record<card: record<blocked: bool, cardNumber: string>, onlineAccount: record<name: string, onlineAccountNumber: string>, phone: record<phoneNumber: string>, pin: record<attemptsRemaining: float, blocked: bool>, retailAccount: record<selfExcluded: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/account/plusCard" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "include": $include, "exclude": $exclude} | compact), body: null}
}

# Sets a customer's plus card as Lost/Stolen
#
# POST /account/plusCard/lostStolen
# operationId: setLostStolen
export def "account-plus-card-lost-stolen update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # Ticket Granting Ticket obtained from a previous request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/plusCard/lostStolen")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets a customer's plus card phone number
#
# POST /account/plusCard/phone/{oldPhoneNumber}
# operationId: setPhoneNumber
export def "account-plus-card-phone update-number" [
  old_phone_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # Ticket Granting Ticket obtained from a previous request
  --phone-number: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($old_phone_number | is-empty) { error make --unspanned { msg: "path parameter 'oldPhoneNumber' must be non-empty" } }
  let full_url = (build-url $base ({old_phone_number: (encode-path-segment $old_phone_number)} | format pattern "/account/plusCard/phone/{old_phone_number}"))
  let req_body = {"phoneNumber": $phone_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sets a customer's plus card pin
#
# POST /account/plusCard/pin
# operationId: setPin
export def "account-plus-card-pin update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # Ticket Granting Ticket obtained from a previous request
  --body: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/plusCard/pin")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates a customer's plus card pin
#
# PUT /account/plusCard/pin
# operationId: updatePin
export def "account-plus-card-pin update-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # Ticket Granting Ticket obtained from a previous request
  --body: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/plusCard/pin")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
