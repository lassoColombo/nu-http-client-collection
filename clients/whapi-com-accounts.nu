# Auto-generated client for Accounts API v2.0.0
# Source: https://api.apis.guru/v2/specs/whapi.com/accounts/2.0.0/swagger.json
# Auth: --token flag or $env.ACCOUNTS_API_TOKEN

const BASE_URL = "https://sandbox.whapi.com/v2/accounts"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ACCOUNTS_API_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
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
  let full_url = (build-url $base "/account" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fields": $fields, "include": $include, "exclude": $exclude, "languageAsPerTerritory": $language_as_per_territory} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/account/balance" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fields": $fields, "include": $include, "exclude": $exclude, "languageAsPerTerritory": $language_as_per_territory} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/account/flags" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket, "apiCountryCode": $api_country_code, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"languageAsPerTerritory": $language_as_per_territory} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/account/payments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket, "territory": $territory} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "dateFrom": $date_from, "dateTo": $date_to, "sort": $qp_sort, "transactionType": $transaction_type, "fields": $fields, "include": $include, "exclude": $exclude, "languageAsPerTerritory": $language_as_per_territory} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/account/plusCard" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fields": $fields, "include": $include, "exclude": $exclude} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/account/plusCard/lostStolen" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
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
  let full_url = (build-url $base ({old_phone_number: (encode-path-segment $old_phone_number)} | format pattern "/account/plusCard/phone/{old_phone_number}") $auth.query)
  let req_body = {"phoneNumber": $phone_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  let full_url = (build-url $base "/account/plusCard/pin" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  let full_url = (build-url $base "/account/plusCard/pin" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}
